//
//  Crop.swift
//  crop
//
//  Created by Eneko Alonso on 2/17/18.
//

import AppKit
import ArgumentParser
import TSCUtility
import TSCBasic

private var cropResizeWidth: Int?
private var cropResizeHeight: Int?
private var cropResizeOutputDirectory: AbsolutePath!
private var cropResizeScale: Int!

enum CropError: LocalizedError {
    case internalError(message: String)
    
    var errorDescription: String? {
        switch self {
            case let .internalError(message):
                return message
        }
    }
}

struct Crop: ParsableCommand {
    static var configuration: CommandConfiguration = .init(subcommands: [List.self, Dir.self], defaultSubcommand: List.self)
    
    @Option
    var width: Int
    @Option
    var height: Int
    @Option(help: "by default takes the working directory")
    var outputDirectory: AbsolutePath?
    
    func validate() throws {
        cropResizeWidth = width
        cropResizeHeight = height
        
        cropResizeOutputDirectory = outputDirectory
    }
    
    struct Dir: ParsableCommand {
        @Argument(help: "all image files (png/jpg) will be cropped")
        var directory: AbsolutePath
        
        func run() throws {
            var cropList = List()
            cropList.absOrRelativeFiles = try imagePaths(in: directory)
            try cropList.run()
        }
        
        func validate() throws {
            cropResizeOutputDirectory = try getOutputDirectory(
                type: "\(Crop.self)",
                backup: directory
            )
        }
    }
    
    struct List: ParsableCommand {
        static var configuration: CommandConfiguration = .init(
            abstract: "Images provides are cropped to the provided width/height and will overwrite any files with the same name in the output directory"
        )
        @Argument(
            parsing: ArgumentArrayParsingStrategy.remaining,
            help: #"add an absolute path in a list "/absolutePath/yourImage.png" or relative "relativePath/yourImage.jpg""#
        )
        var absOrRelativeFiles: [AbsolutePath]
        
        func run() throws {
            let size = CGSize(width: cropResizeWidth!, height: cropResizeHeight!)
            try absOrRelativeFiles.forEach {
                let image = try loadImage($0)
                let resized = try cropImage(image: image, size: size)
                try save(image: resized, basename: $0.basename)
            }
        }
        
        func validate() throws {
            cropResizeOutputDirectory = try getOutputDirectory(
                type: "\(Crop.self)",
                backup: localFileSystem.currentWorkingDirectory
            )
        }
    }
    
}

struct Scale: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        subcommands: [List.self, Dir.self, ReduceMemoryFootprint.self],
        defaultSubcommand: List.self
    )
    
    
    @Option(help: "by default takes the working directory")
    var outputDirectory: AbsolutePath?
    
    func validate() throws {
        cropResizeOutputDirectory = outputDirectory
    }
    
    struct Dir: ParsableCommand {
        @Argument(help: "all image files (png/jpg) will be resized")
        var directory: AbsolutePath
        @Option(help: "percentage to scale")
        var scale: Int
        func run() throws {
            let paths = try imagePaths(in: directory)
                .map { ($0, ratio: CGFloat(cropResizeScale)) }
            
            try scaleFiles(paths)
        }
        
        func validate() throws {
            cropResizeScale = scale
            cropResizeOutputDirectory = try getOutputDirectory(
                type: "\(Crop.self)",
                backup: directory
            )
        }
    }
    
    struct List: ParsableCommand {
        static var configuration: CommandConfiguration = .init(
            abstract: "Images provides are cropped to the provided width/height and will overwrite any files with the same name in the output directory"
        )
        @Argument(
            parsing: ArgumentArrayParsingStrategy.remaining,
            help: #"add an absolute path in a list "/absolutePath/yourImage.png" or relative "relativePath/yourImage.jpg""#
        )
        var absOrRelativeFiles: [AbsolutePath]
        @Option(help: "percentage to scale")
        var scale: Int
        
        func run() throws {
            try scaleFiles(absOrRelativeFiles.map {($0, ratio: CGFloat(cropResizeScale) )})
        }
        func validate() throws {
            cropResizeScale = scale
            cropResizeOutputDirectory = try getOutputDirectory(
                type: "\(Crop.self)",
                backup: localFileSystem.currentWorkingDirectory
            )
        }
    }
    
    struct ReduceMemoryFootprint: ParsableCommand {
        @Argument(help: "all image files (png/jpg) will be resized")
        var directory: AbsolutePath
        @Option(help: "limit in mega bytes", transform: { return  (UInt64($0) ?? 0 ) *  megabyteCoefficient } )
        var limitMb: UInt64
        @Option(help: "one of the sides (width or height) should be at least this size in pixels.")
        var minimumSide: Int?
        
        func validate() throws {
            cropResizeOutputDirectory = try getOutputDirectory(type: "\(Scale.self)", backup: directory)
        }
        
        func run() throws {
            let paths = try filter(
                try imagePaths(in: directory),
                above: limitMb
            )
            
            var others = paths.others
            print("""
                🏞 Found \(paths.0.count) to scale down, \(paths.others.count) ok for memory
                \(paths.0.map { "- \($0.absPath.prettyPath())" }.joined(separator: "\n"))
                
                Others
                \(paths.others.map { "- \($0.absPath.prettyPath())" }.joined(separator: "\n"))
                """)
            let memoryTooBigPathsAndRatios: [(AbsolutePath, ratio: CGFloat)] = paths.0
                .map {
                    let size = CGFloat($0.info.size)
                    let ratio = CGFloat(limitMb) / size
                    return ($0.absPath, ratio: ratio)
                }
            try scaleFiles(memoryTooBigPathsAndRatios)
            
            if let minimumSide = minimumSide {
                let min = CGFloat(minimumSide)
                let toScaleUp = others
                    .filter { $0.size.width < min || $0.size.height < min }
                
                if !toScaleUp.isEmpty {
                    let scaleUpPaths = toScaleUp.map { $0.absPath }
                    others = others
                        .filter { other in !scaleUpPaths.contains(other.absPath) }
                    
                    let ratioPaths: [(AbsolutePath, ratio: CGFloat)] = toScaleUp
                        .map {
                            let ratio: CGFloat = $0.size.width < min ? min / $0.size.width : min / $0.size.height
                            return ($0.absPath, ratio: ratio)
                        }
                    try scaleFiles(ratioPaths)
                }
            }
            
            // add all the files that where not to big/small to new folder too
            try others
                .forEach {
                    try localFileSystem.copy(from: $0.absPath, to: .init($0.absPath.basename, relativeTo: cropResizeOutputDirectory))
                }
        }
        
    }
}

private func scaleFiles(_ files: [(AbsolutePath, ratio: CGFloat)]) throws {
    try files.forEach {
        let image = try loadImage($0.0)
        let resized = try scaled(image: image, scale: $0.ratio, aspectRatio: 1)
        try save(image: resized, basename: $0.0.basename)
    }
}

private func resizedSize(width: Int?, height: Int?, image: NSImage) throws -> CGSize {
    let originalSize = image.size

    if let width = width {
        let ratio = image.size.width / CGFloat(width)
        let newHeight = Int(ratio * originalSize.height)
        return CGSize(width: width, height: newHeight)
    } else if let height = height {
        let ratio = image.size.height / CGFloat(height)
        let newWidth = Int(ratio * originalSize.height)
        return CGSize(width: newWidth, height: height)
    } else if let width = width, let height = height {
        return CGSize(width: width, height: height)
    } else {
        throw CropError.internalError(message: "You should provide a width or a height, both cannot be empty")
    }
}

private func imagePaths(in directory: AbsolutePath) throws -> [AbsolutePath] {
    return try localFileSystem
        .getDirectoryContents(directory)
        .map { AbsolutePath($0, relativeTo: directory) }
        .filter { $0.isImage }
}
private func loadImage(_ absolutePath: AbsolutePath) throws -> NSImage {
    guard let image = NSImage(contentsOf: absolutePath.asURL) else {
        throw CropError.internalError(message: "Could not load image from: \(absolutePath.pathString)")
    }
    return image
}

private func cropImage(image: NSImage, size: CGSize) throws -> NSImage {
    print("🏙  Original image size: \(image.size.sizeString)")
    guard let cropped = image.crop(to: size) else {
        throw CropError.internalError(message: "Failed to resize image.")
    }
    print("🏙  Cropped image size: \(cropped.size.sizeString)")
    return cropped
}

private func save(image: NSImage, basename: String) throws {
    guard let data = basename.hasSuffix("png") ? image.pngRepresentation : image.jpgRepresentation else {
        throw CropError.internalError(message: "Failed to get image data.")
    }
    let url = cropResizeOutputDirectory!.appending(.init(basename)).asURL
    try data.write(to: url)
    print("📁 Resized image saved to: \(url.path)")
}

private func getOutputDirectory(type: String, backup: AbsolutePath?) throws -> AbsolutePath {
    guard cropResizeOutputDirectory == nil else {
        return cropResizeOutputDirectory
    }
    
    guard
        let dirPath = backup?.appending(.init("\(type)Output")) else {
        throw CropError.internalError(message: "Should at least have one file to crop")
    }
    try localFileSystem.createDirectory(dirPath)
    
    return dirPath
}

extension CGSize {
    var sizeString: String {
        return "\(Int(width))x\(Int(height))"
    }
}

extension AbsolutePath {
    var isImage: Bool {
        self.extension == "jpg" || self.extension == "jpeg" || self.extension == "png"
    }
}
