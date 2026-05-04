//
//  TUI.swift
//  taylor
//

import ArgumentParser
import Foundation
import SwiftTUI

struct TUI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Open the interactive terminal dashboard."
    )

    @Option(name: .long, help: "Filter by Reminders list name.")
    var list: String?

    @Flag(name: .long, help: "Include completed reminders in the dashboard.")
    var all: Bool = false

    func run() throws {
        let output = StandardOutput()
        let store = EventKitReminderStore()

        do {
            try store.requestAccess()
            let reminders = try store.list(listName: list, includeCompleted: all)
            let model = ReminderDashboardModel(reminders: reminders, includeCompleted: all)
            Application(rootView: ReminderDashboardView(model: model)).start()
        } catch let error as CLIError {
            output.writeError(error.message)
            Foundation.exit(error.exitCode)
        } catch {
            output.writeError("Error: \(error.localizedDescription)")
            Foundation.exit(1)
        }
    }
}
