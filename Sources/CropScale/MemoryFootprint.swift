import Foundation
import ArgumentParser
import TSCBasic
import ImageIO

/// set by running the command
private var memoryFootprintLimit: UInt64!
let megabyteCoefficient: UInt64 = 1000000

/// Lists the memory useages of the files provided
struct MemoryFootprint: ParsableCommand {
    static var configuration: CommandConfiguration = .init(subcommands: [Dir.self, List.self])
    
    @Argument(help: "limit in mega bytes", transform: { return  (UInt64($0) ?? 0 ) *  megabyteCoefficient } )
    var limit: UInt64
    
    func validate() throws {
        memoryFootprintLimit = self.limit
    }
    
    struct Dir: ParsableCommand {
        @Argument
        var directory: AbsolutePath
        
        func run() throws {
            let paths = try localFileSystem
                .getDirectoryContents(directory)
                .map { AbsolutePath($0, relativeTo: directory) }
            print(try filter(paths, above: memoryFootprintLimit))
        }
    }
    
    struct List: ParsableCommand {
        @Argument(
            parsing: ArgumentArrayParsingStrategy.remaining,
            help: #"add an absolute path in a list "/absolutePath/yourImage.png" or relative "relativePath/yourImage.jpg""#
        )
        var absOrRelativeFiles: [AbsolutePath]
        
        func run() throws {
            print(try filter(absOrRelativeFiles, above: memoryFootprintLimit))
        }
    }
}

/// Files above the `memoryFootprintLimit` which can be set using `MemoryFootprint` command.
/// - Parameter files: the list of files to inspect
/// - Throws: `CropError`
/// - Returns: the list of files that should be inspected, and the others
func filter(_ files: [AbsolutePath], above limit: UInt64) throws
-> (
    [
        (absPath: AbsolutePath, info: FileInfo)],
        others: [(absPath: AbsolutePath, info: FileInfo, size: CGSize)
    ]
) {
    var toFilter = [(absPath: AbsolutePath, info: FileInfo)]()
    var others = [(absPath: AbsolutePath, info: FileInfo, size: CGSize)]()
    
    try files
        .filter { $0.isImage }
        .map {(absPath: $0, info: try  localFileSystem.getFileInfo($0)) }
        .forEach {
            guard $0.info.size >= limit else {
                others.append((absPath: $0.absPath, info: $0.info, size: try getSizeImage(url: $0.absPath)))
                return
            }
            toFilter.append($0)
            return
        }
    
    guard cropResizeVerbose else {
        return (toFilter, others: others)
    }
    
    print("Files >= \(limit / megabyteCoefficient)Mb")
    print(
        toFilter
            .map { "\($0.absPath.prettyPath()), \($0.info.size)" }
            .joined(separator: "\n")
    )
    
    return (toFilter, others: others)
}


func getSizeImage(url: AbsolutePath) throws -> CGSize {
    guard
        let imageSource = CGImageSourceCreateWithURL(url.asURL as CFURL, nil),
        let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [NSString: Any]
    else {
        throw CropError.internalError(message: #function)
    }

    let width: CGFloat = CGFloat(Float(truncating: imageProperties[kCGImagePropertyPixelWidth] as! CFNumber))
    let height: CGFloat = CGFloat(Float(truncating: imageProperties[kCGImagePropertyPixelHeight] as! CFNumber))
    
    return CGSize(width: width, height: height)
}
