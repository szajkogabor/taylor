import Foundation
import XCTest
@testable import taylor

final class ReminderDashboardModelTests: XCTestCase {

    func testSectionsAreBucketedAndOrdered() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let calendar = Calendar(identifier: .gregorian)

        let reminders: [ReminderItem] = [
            ReminderItem(
                id: "1",
                title: "Tomorrow",
                notes: nil,
                dueDate: now.addingTimeInterval(86_400),
                listName: "Personal",
                isCompleted: false
            ),
            ReminderItem(
                id: "2",
                title: "Already late",
                notes: nil,
                dueDate: now.addingTimeInterval(-60),
                listName: "Work",
                isCompleted: false
            ),
            ReminderItem(
                id: "3",
                title: "No deadline",
                notes: nil,
                dueDate: nil,
                listName: "Personal",
                isCompleted: false
            ),
            ReminderItem(
                id: "4",
                title: "Done task",
                notes: nil,
                dueDate: now.addingTimeInterval(-3600),
                listName: "Work",
                isCompleted: true
            )
        ]

        let model = ReminderDashboardModel(reminders: reminders, includeCompleted: true, now: now, calendar: calendar)

        XCTAssertEqual(model.snapshot.total, 4)
        XCTAssertEqual(model.snapshot.overdue, 1)
        XCTAssertEqual(model.snapshot.upcoming, 1)
        XCTAssertEqual(model.snapshot.noDueDate, 1)
        XCTAssertEqual(model.snapshot.completed, 1)

        XCTAssertEqual(model.sections.map(\.bucket), [.overdue, .upcoming, .noDueDate, .completed])
    }

    func testListSortingIsDueDateThenTitle() {
        let now = Date(timeIntervalSince1970: 3_000_000)

        let reminders: [ReminderItem] = [
            ReminderItem(id: "b", title: "Zulu", notes: nil, dueDate: now, listName: "L", isCompleted: false),
            ReminderItem(id: "a", title: "Alpha", notes: nil, dueDate: now, listName: "L", isCompleted: false),
            ReminderItem(id: "c", title: "No due", notes: nil, dueDate: nil, listName: "L", isCompleted: false),
            ReminderItem(id: "d", title: "Earlier", notes: nil, dueDate: now.addingTimeInterval(-3600), listName: "L", isCompleted: false)
        ]

        let sorted = reminders.sortedByDueDateThenTitle()
        XCTAssertEqual(sorted.map(\.id), ["d", "a", "b", "c"])
    }
}
