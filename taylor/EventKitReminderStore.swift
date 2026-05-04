//
//  EventKitReminderStore.swift
//  taylor
//

import EventKit
import Foundation

final class EventKitReminderStore: ReminderStore {

    private let store = EKEventStore()

    // MARK: - Authorization

    func requestAccess() async throws {
        let granted = try await store.requestFullAccessToReminders()
        if !granted {
            throw CLIError.permissionDenied
        }
    }

    // MARK: - Add

    func add(
        title: String,
        notes: String?,
        dueDate: Date?,
        listName: String?
    ) async throws -> ReminderItem {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes

        if let dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: dueDate
            )
        }

        reminder.calendar = try calendar(named: listName)

        do {
            try store.save(reminder, commit: true)
        } catch {
            throw CLIError.cannotCreate(error.localizedDescription)
        }

        return ReminderItem(
            id: reminder.calendarItemIdentifier,
            title: reminder.title ?? "",
            notes: reminder.notes,
            dueDate: dueDate,
            listName: reminder.calendar?.title ?? "",
            isCompleted: false
        )
    }

    // MARK: - Remove

    func remove(id: String) async throws {
        guard let item = store.calendarItem(withIdentifier: id),
              let reminder = item as? EKReminder
        else {
            throw CLIError.notFound("Reminder with id '\(id)' not found.")
        }
        do {
            try store.remove(reminder, commit: true)
        } catch {
            throw CLIError.unknown(error.localizedDescription)
        }
    }

    // MARK: - List

    func list(listName: String?, includeCompleted: Bool) async throws -> [ReminderItem] {
        let calendars: [EKCalendar]
        if let listName {
            let found = store.calendars(for: .reminder).filter { $0.title == listName }
            if found.isEmpty {
                throw CLIError.configError("Reminders list '\(listName)' not found.")
            }
            calendars = found
        } else {
            calendars = store.calendars(for: .reminder)
        }

        let predicate = store.predicateForReminders(in: calendars)

        return try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                guard let reminders else {
                    continuation.resume(throwing: CLIError.readFailure("Failed to fetch reminders from EventKit."))
                    return
                }
                let items = reminders
                    .filter { includeCompleted || !$0.isCompleted }
                    .map { r -> ReminderItem in
                        let dueDate: Date?
                        if let comps = r.dueDateComponents {
                            dueDate = Calendar.current.date(from: comps)
                        } else {
                            dueDate = nil
                        }
                        return ReminderItem(
                            id: r.calendarItemIdentifier,
                            title: r.title ?? "",
                            notes: r.notes,
                            dueDate: dueDate,
                            listName: r.calendar?.title ?? "",
                            isCompleted: r.isCompleted
                        )
                    }
                continuation.resume(returning: items)
            }
        }
    }

    // MARK: - Private helpers

    private func calendar(named name: String?) throws -> EKCalendar {
        if let name {
            guard let cal = store.calendars(for: .reminder).first(where: { $0.title == name }) else {
                throw CLIError.configError("Reminders list '\(name)' not found.")
            }
            return cal
        }
        guard let cal = store.defaultCalendarForNewReminders() else {
            throw CLIError.serviceUnavailable("No default reminders list is available.")
        }
        return cal
    }
}
