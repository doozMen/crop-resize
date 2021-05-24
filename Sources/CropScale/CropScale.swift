import Foundation
import ArgumentParser

var cropResizeVerbose = false

public struct CropScale: ParsableCommand {
    public static var configuration: CommandConfiguration = .init(
        subcommands: [
            Crop.self,
            Scale.self,
            MemoryFootprint.self
        ]
    )
    
    @Option
    var verbose: Bool = false
    
    public init() {}
    
    public func validate() throws {
        cropResizeVerbose = self.verbose
    }
}
