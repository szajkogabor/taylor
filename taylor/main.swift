//
//  main.swift
//  taylor
//
//  Created by Szajkó Gábor on 2026. 05. 04..
//

import ArgumentParser
import Foundation

struct Taylor: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "taylor",
        abstract: "Blazing fast CLI reminder manager for macOS.",
        discussion: """
            taylor manages your Apple Reminders from the terminal using EventKit.

            Author:     \(Config.author)
            Repository: \(Config.repository)
            License:    \(Config.license)
            """,
        version: Config.version,
        subcommands: [
            Add.self,
            Remove.self,
            List.self,
            Author.self,
        ],
        defaultSubcommand: List.self
    )
}

Taylor.main()
