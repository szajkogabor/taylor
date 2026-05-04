//
//  Add.swift
//  taylor
//

import ArgumentParser
import Foundation

struct Add: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Add a new reminder."
    )

    @Argument(help: "Title of the reminder.")
    var title: String

    @Option(name: .long, help: "Additional notes for the reminder.")
    var notes: String?

    @Option(name: .long, help: "Due date/time: \"today\", \"tomorrow\", \"monday 9:00\", \"2026-05-10 14:30\", etc.")
    var due: String?

    @Option(name: .long, help: "Name of the Reminders list to add into (uses default if omitted).")
    var list: String?

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

        let dueComponents: DateComponents?
        do {
            if let due {
                let parser = DateParser()
                dueComponents = try parser.parseDue(due)
            } else {
                dueComponents = nil
            }
        } catch let error as CLIError {
            output.writeError(error.message)
            Foundation.exit(error.exitCode)
        }

        do {
            let reminder = try store.add(
                title: title,
                notes: notes,
                dueComponents: dueComponents,
                listName: list
            )
            output.write("✓ Reminder added.")
            output.write("  ID:    \(reminder.id)")
            output.write("  Title: \(reminder.title)")
            if let due = reminder.dueDate {
                let includesTime = dueComponents?.hour != nil
                output.write("  Due:   \(formatDate(due, includesTime: includesTime))")
            }
            output.write("  List:  \(reminder.listName)")
        } catch let error as CLIError {
            output.writeError(error.message)
            Foundation.exit(error.exitCode)
        } catch {
            output.writeError("Error: \(error.localizedDescription)")
            Foundation.exit(1)
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date, includesTime: Bool = true) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = includesTime ? .short : .none
        return fmt.string(from: date)
    }
}
