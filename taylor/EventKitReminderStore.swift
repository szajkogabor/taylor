//
//  EventKitReminderStore.swift
//  taylor
//

import EventKit
import Foundation

@available(macOS 10.15, *)
final class EventKitReminderStore: ReminderStore {

    private let store = EKEventStore()

    private final class AccessResultBox: @unchecked Sendable {
        private let lock = NSLock()
        private var granted: Bool = false
        private var error: Error?

        func set(granted: Bool, error: Error?) {
            lock.lock()
            self.granted = granted
            self.error = error
            lock.unlock()
        }

        func read() -> (Bool, Error?) {
            lock.lock()
            let value = (granted, error)
            lock.unlock()
            return value
        }
    }

    @available(macOS 10.15, *)
    func requestAccess() throws {
        let semaphore = DispatchSemaphore(value: 0)
        let box = AccessResultBox()

        // Use the cross-version API so SwiftPM builds cleanly for macOS < 14 targets.
        store.requestAccess(to: .reminder) { allowed, error in
            box.set(granted: allowed, error: error)
            semaphore.signal()
        }

        semaphore.wait()
        let (granted, callbackError) = box.read()

        if let callbackError {
            throw CLIError.serviceUnavailable(callbackError.localizedDescription)
        }
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
    ) throws -> ReminderItem {
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

    func remove(id: String) throws {
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

    func list(listName: String?, includeCompleted: Bool) throws -> [ReminderItem] {
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

        let semaphore = DispatchSemaphore(value: 0)
        var result: [ReminderItem] = []
        var fetchError: Error?

        store.fetchReminders(matching: predicate) { reminders in
            guard let reminders else {
                fetchError = CLIError.readFailure("Failed to fetch reminders from EventKit.")
                semaphore.signal()
                return
            }

            result = reminders
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
            semaphore.signal()
        }

        semaphore.wait()

        if let fetchError {
            throw fetchError
        }
        return result
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
