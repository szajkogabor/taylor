//
//  ReminderItem.swift
//  taylor
//

import Foundation

/// A platform-agnostic reminder value returned from any ReminderStore.
struct ReminderItem {
    /// Stable identifier (EventKit calendarItemIdentifier or mock value in tests).
    let id: String
    let title: String
    let notes: String?
    /// nil means no due date is set.
    let dueDate: Date?
    /// Name of the Reminders list / calendar this item belongs to.
    let listName: String
    let isCompleted: Bool
}
