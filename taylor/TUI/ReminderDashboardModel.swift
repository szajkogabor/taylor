//
//  ReminderDashboardModel.swift
//  taylor
//

import Foundation

struct ReminderSnapshot {
    let total: Int
    let overdue: Int
    let today: Int
    let upcoming: Int
    let noDueDate: Int
    let completed: Int
}

enum ReminderBucket: Int, CaseIterable {
    case overdue
    case today
    case upcoming
    case noDueDate
    case completed

    var title: String {
        switch self {
        case .overdue: return "Overdue"
        case .today: return "Due Today"
        case .upcoming: return "Upcoming"
        case .noDueDate: return "No Due Date"
        case .completed: return "Completed"
        }
    }
}

struct ReminderRowModel: Identifiable {
    let id: String
    let title: String
    let listName: String
    let dueText: String
    let bucket: ReminderBucket
    let isCompleted: Bool
    let isOverdue: Bool

    var line: String {
        let flag: String
        if isCompleted {
            flag = "[x]"
        } else if isOverdue {
            flag = "[!]"
        } else {
            flag = "[ ]"
        }
        return "\(flag) \(title)  (\(listName))  due: \(dueText)"
    }
}

struct ReminderSectionModel: Identifiable {
    let bucket: ReminderBucket
    let rows: [ReminderRowModel]

    var id: Int { bucket.rawValue }
    var title: String { bucket.title }
}

/// Rich projection for TUI rendering that groups reminders into meaningful sections
/// and computes compact board statistics.
struct ReminderDashboardModel {
    let generatedAt: Date
    let snapshot: ReminderSnapshot
    let sections: [ReminderSectionModel]

    init(reminders: [ReminderItem], includeCompleted: Bool, now: Date = Date(), calendar: Calendar = .current) {
        let sorted = reminders.sortedByDueDateThenTitle()

        var overdueCount = 0
        var todayCount = 0
        var upcomingCount = 0
        var noDueCount = 0
        var completedCount = 0

        var grouped: [ReminderBucket: [ReminderRowModel]] = [:]

        for reminder in sorted {
            if reminder.isCompleted {
                completedCount += 1
                if includeCompleted {
                    let row = ReminderRowModel(
                        id: reminder.id,
                        title: reminder.title,
                        listName: reminder.listName,
                        dueText: Self.dueText(for: reminder.dueDate),
                        bucket: .completed,
                        isCompleted: true,
                        isOverdue: false
                    )
                    grouped[.completed, default: []].append(row)
                }
                continue
            }

            if let due = reminder.dueDate {
                if due < now {
                    overdueCount += 1
                    grouped[.overdue, default: []].append(
                        ReminderRowModel(
                            id: reminder.id,
                            title: reminder.title,
                            listName: reminder.listName,
                            dueText: Self.dueText(for: due),
                            bucket: .overdue,
                            isCompleted: false,
                            isOverdue: true
                        )
                    )
                } else if calendar.isDateInToday(due) {
                    todayCount += 1
                    grouped[.today, default: []].append(
                        ReminderRowModel(
                            id: reminder.id,
                            title: reminder.title,
                            listName: reminder.listName,
                            dueText: Self.dueText(for: due),
                            bucket: .today,
                            isCompleted: false,
                            isOverdue: false
                        )
                    )
                } else {
                    upcomingCount += 1
                    grouped[.upcoming, default: []].append(
                        ReminderRowModel(
                            id: reminder.id,
                            title: reminder.title,
                            listName: reminder.listName,
                            dueText: Self.dueText(for: due),
                            bucket: .upcoming,
                            isCompleted: false,
                            isOverdue: false
                        )
                    )
                }
            } else {
                noDueCount += 1
                grouped[.noDueDate, default: []].append(
                    ReminderRowModel(
                        id: reminder.id,
                        title: reminder.title,
                        listName: reminder.listName,
                        dueText: "-",
                        bucket: .noDueDate,
                        isCompleted: false,
                        isOverdue: false
                    )
                )
            }
        }

        self.generatedAt = now
        self.snapshot = ReminderSnapshot(
            total: reminders.count,
            overdue: overdueCount,
            today: todayCount,
            upcoming: upcomingCount,
            noDueDate: noDueCount,
            completed: completedCount
        )
        self.sections = ReminderBucket
            .allCases
            .compactMap { bucket in
                guard let rows = grouped[bucket], !rows.isEmpty else { return nil }
                return ReminderSectionModel(bucket: bucket, rows: rows)
            }
    }

    private static func dueText(for date: Date?) -> String {
        guard let date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
