import Foundation
import ArgumentParser
import TSCBasic

extension AbsolutePath: ExpressibleByArgument {
    /// Will take the argument and if it starts with `/` will make it into an absolute path,
    /// if not it will make it a relative path to the `TSCBasic.localFileSystem.currentWorkingDirectory`
    /// - Parameter argument: the path to the thing you want on disk
    /// - Warning: returns nil if the argument does not exist on disk.
    public init?(argument: String) {
        guard argument.hasPrefix("/"), localFileSystem.exists(.init(argument)) else {
            guard
                let absFilePath = localFileSystem.currentWorkingDirectory?.appending(.init(argument)).pathString,
                localFileSystem.exists(.init(absFilePath)) else {
                return nil
            }
            
            self.init(absFilePath)
            return
        }
        
        self.init(argument)
    }
}
