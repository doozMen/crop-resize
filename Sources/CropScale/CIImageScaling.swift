import Foundation
import AppKit

let sharedContext = CIContext(options: [.useSoftwareRenderer : false])

// Technique #4
func scaled(image: NSImage, scale: CGFloat, aspectRatio: CGFloat) throws -> NSImage {
    var rect = CGRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
        throw CropError.internalError(message: #function)
    }
    let ciImage = CIImage(cgImage: cgImage)
    let filter = CIFilter(name: "CILanczosScaleTransform")
    filter?.setValue(ciImage, forKey: kCIInputImageKey)
    filter?.setValue(scale, forKey: kCIInputScaleKey)
    filter?.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
    
    guard let outputCIImage = filter?.outputImage,
          let outputCGImage = sharedContext.createCGImage(outputCIImage,
                                                          from: outputCIImage.extent)
    else {
        throw CropError.internalError(message: #function)
    }
    return NSImage(
        cgImage: outputCGImage,
        size: .init(width: rect.width * scale, height: rect.height * scale)
    )
}
