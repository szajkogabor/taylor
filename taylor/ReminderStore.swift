//
//  ReminderStore.swift
//  taylor
//

import Foundation

/// Protocol that decouples command handlers from EventKit so they are unit-testable
/// with a fake implementation.
protocol ReminderStore {
    /// Request authorization. Throws CLIError.permissionDenied if access is not granted.
    func requestAccess() throws

    /// Create a new reminder and return the saved item.
    func add(
        title: String,
        notes: String?,
        dueComponents: DateComponents?,
        listName: String?
    ) throws -> ReminderItem

    /// Permanently delete the reminder with the given identifier.
    func remove(id: String) throws

    /// Fetch reminders, optionally filtered to a specific list.
    /// - Parameters:
    ///   - listName: If non-nil, only return reminders from this list.
    ///   - includeCompleted: When false (default), only incomplete reminders are returned.
    func list(
        listName: String?,
        includeCompleted: Bool
    ) throws -> [ReminderItem]
}

extension ReminderStore {
    // Convenience default: exclude completed reminders.
    func list(listName: String? = nil) throws -> [ReminderItem] {
        try list(listName: listName, includeCompleted: false)
    }
}

// MARK: - Sorting helpers

extension [ReminderItem] {
    /// Deterministic sort: due date ascending (nil last), then title case-insensitive ascending.
    func sortedByDueDateThenTitle() -> [ReminderItem] {
        sorted { a, b in
            switch (a.dueDate, b.dueDate) {
            case let (d1?, d2?):
                if d1 != d2 { return d1 < d2 }
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                break
            }
            // Tie-break: title (case-insensitive), then id for full stability.
            let titleCmp = a.title.localizedCaseInsensitiveCompare(b.title)
            if titleCmp != .orderedSame {
                return titleCmp == .orderedAscending
            }
            return a.id < b.id
        }
    }
}
