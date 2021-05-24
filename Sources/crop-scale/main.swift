import ArgumentParser

var cropResizeVerbose = false

struct CropResize: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        subcommands: [
            Crop.self,
            Scale.self,
            MemoryFootprint.self
        ]
    )
    
    @Option
    var verbose: Bool = false

    func validate() throws {
        cropResizeVerbose = self.verbose
    }
}

CropResize.main()
