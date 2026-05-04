//
//  DateParser.swift
//  taylor
//

import Foundation

/// Parses natural language date/time strings into `Date` values.
///
/// Supports:
/// - Keywords: "today", "tomorrow", "yesterday"
/// - Weekday names: "monday"–"sunday" (resolves to next occurrence)
/// - Formal dates via NSDataDetector: "March 5", "3/12/2026", "May 10, 2026 at 3pm", etc.
/// - Explicit `--time` in HH:mm format combined with the resolved date.
struct DateParser {

    private let calendar: Calendar
    private let now: Date

    init(calendar: Calendar = .current, now: Date = Date()) {
        self.calendar = calendar
        self.now = now
    }

    /// Parse a `--date` string into a `Date` (at midnight unless combined with `--time`).
    /// Returns `nil` only if `raw` is `nil`. Throws on unparseable input.
    func parseDate(_ raw: String) throws -> Date {
        let lowered = raw.trimmingCharacters(in: .whitespaces).lowercased()

        // 1) Keywords
        if let date = parseKeyword(lowered) {
            return date
        }

        // 2) Weekday name
        if let date = parseWeekday(lowered) {
            return date
        }

        // 3) YYYY-MM-DD explicit format
        if let date = parseISO(raw) {
            return date
        }

        // 4) NSDataDetector for everything else ("March 5", "3/12/2026", "May 10 2026", etc.)
        if let date = parseWithDataDetector(raw) {
            return date
        }

        throw CLIError.usageError("Cannot parse date '\(raw)'. Try: today, tomorrow, monday, 2026-05-10, \"March 5\", etc.")
    }

    /// Parse a `--time` string in HH:mm format.
    func parseTime(_ raw: String) throws -> (hour: Int, minute: Int) {
        let parts = raw.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute)
        else {
            throw CLIError.usageError("Cannot parse time '\(raw)'. Use HH:mm format, e.g. 09:30, 14:00.")
        }
        return (hour, minute)
    }

    /// Parse a free-form `--due` string into `DateComponents`.
    ///
    /// Accepts strings like "today", "tomorrow 9:00", "monday 14:30", "2026-05-10", etc.
    /// A trailing `H:mm` or `HH:mm` is extracted as the time; the remainder is parsed as the date.
    /// When no time is present only year/month/day components are set (date-only reminder).
    func parseDue(_ raw: String) throws -> DateComponents {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)

        // Detect trailing time pattern: optional whitespace then H:mm or HH:mm at end
        let timePattern = #"\s+(\d{1,2}):(\d{2})\s*$"#
        if let regex = try? NSRegularExpression(pattern: timePattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let matchRange = Range(match.range, in: trimmed) {

            let timeStr = String(trimmed[matchRange]).trimmingCharacters(in: .whitespaces)
            let dateStr = String(trimmed[..<matchRange.lowerBound]).trimmingCharacters(in: .whitespaces)

            let baseDate: Date = dateStr.isEmpty
                ? calendar.startOfDay(for: now)
                : try parseDate(dateStr)

            let (hour, minute) = try parseTime(timeStr)
            var comps = calendar.dateComponents([.year, .month, .day], from: baseDate)
            comps.hour = hour
            comps.minute = minute
            comps.second = 0
            return comps
        }

        // No time keyword or explicit time — try parseDate which uses NSDataDetector as fallback.
        // Preserve time components if NSDataDetector detected them (non-midnight result).
        let baseDate = try parseDate(trimmed)
        let hour = calendar.component(.hour, from: baseDate)
        let minute = calendar.component(.minute, from: baseDate)
        var comps = calendar.dateComponents([.year, .month, .day], from: baseDate)
        if hour != 0 || minute != 0 {
            comps.hour = hour
            comps.minute = minute
            comps.second = 0
        }
        return comps
    }

    /// Combine a date and optional time into a single `Date`.
    /// - If only date: returns start of that day.
    /// - If only time: returns today at that time.
    /// - If both: returns the given date at the given time.
    func combine(dateString: String?, timeString: String?) throws -> Date? {
        guard dateString != nil || timeString != nil else { return nil }

        let baseDate: Date
        if let dateString {
            baseDate = try parseDate(dateString)
        } else {
            baseDate = calendar.startOfDay(for: now)
        }

        guard let timeString else {
            return calendar.startOfDay(for: baseDate)
        }

        let (hour, minute) = try parseTime(timeString)
        let dayStart = calendar.startOfDay(for: baseDate)
        guard let result = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dayStart) else {
            throw CLIError.usageError("Cannot combine date and time into a valid date.")
        }
        return result
    }

    // MARK: - Private

    private func parseKeyword(_ lowered: String) -> Date? {
        switch lowered {
        case "today":
            return calendar.startOfDay(for: now)
        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        case "yesterday":
            return calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))
        default:
            return nil
        }
    }

    private static let weekdayMap: [String: Int] = [
        "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
        "thursday": 5, "friday": 6, "saturday": 7
    ]

    private func parseWeekday(_ lowered: String) -> Date? {
        guard let targetWeekday = Self.weekdayMap[lowered] else { return nil }
        let todayWeekday = calendar.component(.weekday, from: now)
        var daysAhead = targetWeekday - todayWeekday
        if daysAhead <= 0 { daysAhead += 7 }
        return calendar.date(byAdding: .day, value: daysAhead, to: calendar.startOfDay(for: now))
    }

    private func parseISO(_ raw: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        return formatter.date(from: raw)
    }

    private func parseWithDataDetector(_ raw: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let range = NSRange(raw.startIndex..., in: raw)
        let match = detector.firstMatch(in: raw, options: [], range: range)
        return match?.date
    }
}
