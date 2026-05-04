//
//  Author.swift
//  taylor
//

import ArgumentParser

struct Author: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Print the author of taylor."
    )

    func run() {
        let output = StandardOutput()
        output.write("Author:     \(Config.author)")
        output.write("Repository: \(Config.repository)")
        output.write("License:    \(Config.license)")
    }
}
