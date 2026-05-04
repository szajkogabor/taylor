//
//  Remove.swift
//  taylor
//

import ArgumentParser
import Foundation

struct Remove: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Remove a reminder by its ID."
    )

    @Argument(help: "The identifier of the reminder to remove (shown by `taylor list`).")
    var id: String

    func run() throws {
        try execute()
    }

    private func execute() throws {
        let output = StandardOutput()
        let store = EventKitReminderStore()

        do {
            try store.requestAccess()
        } catch let error as CLIError {
            output.writeError(error.message)
            Foundation.exit(error.exitCode)
        }

        do {
            try store.remove(id: id)
            output.write("✓ Reminder removed.")
        } catch let error as CLIError {
            output.writeError(error.message)
            Foundation.exit(error.exitCode)
        } catch {
            output.writeError("Error: \(error.localizedDescription)")
            Foundation.exit(1)
        }
    }
}
