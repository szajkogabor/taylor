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

    @Option(name: .long, help: "Due date in ISO 8601 format (e.g. 2026-05-10T09:00:00Z).")
    var due: String?

    @Option(name: .long, help: "Name of the Reminders list to add into (uses default if omitted).")
    var list: String?

    func run() throws {
        try runAsyncAndWait { try await self.execute() }
    }

    private func execute() async throws {
        let output = StandardOutput()
        let store = EventKitReminderStore()

        do {
            try await store.requestAccess()
        } catch let error as CLIError {
            output.writeError(error.message)
            Foundation.exit(error.exitCode)
        }

        let dueDate = try parseDueDate(due, output: output)

        do {
            let reminder = try await store.add(
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

    private func parseDueDate(_ raw: String?, output: CLIOutput) throws -> Date? {
        guard let raw else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: raw) { return date }

        // Fallback: without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: raw) { return date }

        output.writeError("Usage error: Cannot parse due date '\(raw)'. Use ISO 8601 format, e.g. 2026-05-10T09:00:00Z")
        Foundation.exit(64)
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}
