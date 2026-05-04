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

    @Option(name: .long, help: "Due date: today, tomorrow, monday–sunday, YYYY-MM-DD, or natural date like \"March 5\".")
    var date: String?

    @Option(name: .long, help: "Due time in HH:mm format (e.g. 09:30, 14:00). Defaults to today if --date is omitted.")
    var time: String?

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

        let dueDate: Date?
        do {
            let parser = DateParser()
            dueDate = try parser.combine(dateString: date, timeString: time)
        } catch let error as CLIError {
            output.writeError(error.message)
            Foundation.exit(error.exitCode)
        }

        do {
            let reminder = try store.add(
                title: title,
                notes: notes,
                dueDate: dueDate,
                listName: list
            )
            output.write("✓ Reminder added.")
            output.write("  ID:    \(reminder.id)")
            output.write("  Title: \(reminder.title)")
            if let due = reminder.dueDate {
                output.write("  Due:   \(formatDate(due))")
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

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}
