//
//  List.swift
//  taylor
//

import ArgumentParser
import Foundation

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List reminders."
    )

    @Option(name: .long, help: "Filter by Reminders list name.")
    var list: String?

    @Flag(name: .long, help: "Include completed reminders.")
    var all: Bool = false

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

        do {
            let reminders = try await store.list(listName: list, includeCompleted: all)
            let sorted = reminders.sortedByDueDateThenTitle()
            render(sorted, output: output)
        } catch let error as CLIError {
            output.writeError(error.message)
            Foundation.exit(error.exitCode)
        } catch {
            output.writeError("Error: \(error.localizedDescription)")
            Foundation.exit(1)
        }
    }

    private func render(_ reminders: [ReminderItem], output: CLIOutput) {
        if reminders.isEmpty {
            output.write("No reminders found.")
            return
        }

        let now = Date()
        let dateFmt = DateFormatter()
        dateFmt.dateStyle = .medium
        dateFmt.timeStyle = .short

        // Calculate column widths for aligned output
        let titleWidth = max(5, reminders.map(\.title.count).max() ?? 5)
        let listWidth  = max(4, reminders.map(\.listName.count).max() ?? 4)

        let header = formatRow(
            status: " ",
            due: "DUE",
            list: "LIST",
            title: "TITLE",
            titleWidth: titleWidth,
            listWidth: listWidth
        )
        let separator = String(repeating: "─", count: header.count)

        output.write(separator)
        output.write(header)
        output.write(separator)

        for r in reminders {
            let dueStr: String
            var overdue = false
            if let dueDate = r.dueDate {
                dueStr = dateFmt.string(from: dueDate)
                overdue = dueDate < now && !r.isCompleted
            } else {
                dueStr = "—"
            }

            let statusMark: String
            if r.isCompleted {
                statusMark = "✓"
            } else if overdue {
                statusMark = "!"
            } else {
                statusMark = " "
            }

            let row = formatRow(
                status: statusMark,
                due: dueStr,
                list: r.listName,
                title: r.title,
                titleWidth: titleWidth,
                listWidth: listWidth
            )
            output.write(row)
            // Show id on the next line, indented, so it's easy to copy for `remove`
            // output.write("  id: \(r.id)")
        }

        output.write(separator)
        output.write("\(reminders.count) reminder(s)")
    }

    private func formatRow(
        status: String,
        due: String,
        list: String,
        title: String,
        titleWidth: Int,
        listWidth: Int
    ) -> String {
        let dueColWidth = 22
        let paddedDue   = due.padding(toLength: dueColWidth, withPad: " ", startingAt: 0)
        let paddedList  = list.padding(toLength: listWidth,  withPad: " ", startingAt: 0)
        let paddedTitle = title.padding(toLength: titleWidth, withPad: " ", startingAt: 0)
        return "\(status)  \(paddedDue)  \(paddedList)  \(paddedTitle)"
    }
}
