//
//  Config.swift
//  taylor
//

import Foundation

enum Config {
    static let version = resolvedVersion()
    static let author = "Gabor Szajko <szajkogabor@gmail.com>"
    static let license = "MIT"
    static let repository = "https://github.com/szajkogabor/taylor"

    private static func resolvedVersion() -> String {
        if let described = gitDescribeVersion() {
            return described
        }
        return "0.1.0"
    }

    private static func gitDescribeVersion() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["describe", "--tags", "--first-parent", "--abbrev=8"]
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else {
            return nil
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !output.isEmpty
        else {
            return nil
        }

        return output
    }
}
