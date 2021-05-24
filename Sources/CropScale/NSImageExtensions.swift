//
//  NSImageExtensions.swift
//  crop
//
//  Created by Eneko Alonso on 2/17/18.
//

import AppKit
import CoreGraphics

extension NSImage {

    var jpgRepresentation: Data? {
        guard let tiff = tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return tiffData.representation(using: .jpeg, properties: [:])
    }

    var pngRepresentation: Data? {
        guard let tiff = tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return tiffData.representation(using: .png, properties: [:])
    }

    // MARK: Resizing
    /// Resize the image to the given size.
    ///
    /// - Parameter size: The size to resize the image to.
    /// - Returns: The resized image.
    func resize(to targetSize: CGSize) -> NSImage? {
        let frame = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        guard let representation = bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        let image = NSImage(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })
        return image
    }

    /// Copy the image and resize it to the supplied size, while maintaining it's
    /// original aspect ratio.
    ///
    /// - Parameter size: The target size of the image.
    /// - Returns: The resized image.
    func resizeMaintainingAspectRatio(to targetSize: CGSize) -> NSImage? {
        let widthRatio  = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = max(widthRatio, heightRatio)
        let newSize = CGSize(width: floor(size.width * ratio), height: floor(size.height * ratio))
        return resize(to: newSize)
    }

    // MARK: Cropping
    /// Resize the image, to nearly fit the supplied cropping size
    /// and return a cropped copy the image.
    ///
    /// - Parameter size: The size of the new image.
    /// - Returns: The cropped image.
    func crop(to targetSize: CGSize) -> NSImage? {
        // Resize the current image, while preserving the aspect ratio.
        guard let resized = resizeMaintainingAspectRatio(to: targetSize) else {
            return nil
        }

        // Get some points to center the cropping area.
        let x = floor((resized.size.width - targetSize.width) / 2)
        let y = floor((resized.size.height - targetSize.height) / 2)

        // Create the cropping frame.
        let frame = CGRect(origin: CGPoint(x: x, y: y), size: targetSize)

        // Get the best representation of the image for the given cropping frame.
        guard let representation = resized.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }

        // Create a new image with the new size
        let cropped = NSImage(size: targetSize)
        cropped.lockFocus()
        defer { cropped.unlockFocus() }

        let outputFrame = CGRect(origin: CGPoint(x: 0, y: 0), size: targetSize)

        guard representation.draw(in: outputFrame, from: frame, operation: .copy, fraction: 1.0, respectFlipped: false, hints: [:]) else {
            return nil
        }
        return cropped
    }
}
