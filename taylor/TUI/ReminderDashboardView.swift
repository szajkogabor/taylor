//
//  ReminderDashboardView.swift
//  taylor
//

import Foundation
import SwiftTUI

struct ReminderDashboardView: View {
    let model: ReminderDashboardModel

    var body: some View {
        VStack {
            Text("taylor tui")
            Text("total: \(model.snapshot.total)  overdue: \(model.snapshot.overdue)  today: \(model.snapshot.today)  upcoming: \(model.snapshot.upcoming)  no-due: \(model.snapshot.noDueDate)  completed: \(model.snapshot.completed)")
            Text("")

            ForEach(model.sections) { section in
                VStack {
                    Text("== \(section.title) ==")
                    ForEach(section.rows) { row in
                        Text(row.line)
                    }
                    Text("")
                }
            }

            if model.sections.isEmpty {
                Text("No reminders found.")
                Text("")
            }

            Text("Press Ctrl+C to exit.")
        }
    }
}
