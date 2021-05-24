import XCTest
import class Foundation.Bundle

final class crop_scaleTests: XCTestCase {
    func test_executable() throws {
        guard #available(macOS 10.13, *) else {
            return
        }
        
        // Mac Catalyst won't have `Process`, but it is supported for executables.
        #if !targetEnvironment(macCatalyst)
        
        let fooBinary = productsDirectory.appendingPathComponent("crop-scale")
        
        let process = Process()
        process.executableURL = fooBinary
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        XCTAssertNotNil(output)
        #endif
    }
    
    /// Returns path to the built products directory.
    var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }
}
