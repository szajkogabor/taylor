//
//  DateParserTests.swift
//  taylorTests
//

import XCTest
@testable import taylor

final class DateParserTests: XCTestCase {

    // Fixed reference: Monday, May 4, 2026 at midnight in the test timezone
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }
    private var referenceDate: Date {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 5
        comps.day = 4
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return calendar.date(from: comps)!
    }

    private func makeParser() -> DateParser {
        DateParser(calendar: calendar, now: referenceDate)
    }

    // MARK: - Keywords

    func testParseToday() throws {
        let date = try makeParser().parseDate("today")
        XCTAssertEqual(date, calendar.startOfDay(for: referenceDate))
    }

    func testParseTodayCaseInsensitive() throws {
        let date = try makeParser().parseDate("Today")
        XCTAssertEqual(date, calendar.startOfDay(for: referenceDate))
    }

    func testParseTomorrow() throws {
        let date = try makeParser().parseDate("tomorrow")
        let expected = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: referenceDate))!
        XCTAssertEqual(date, expected)
    }

    func testParseYesterday() throws {
        let date = try makeParser().parseDate("yesterday")
        let expected = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: referenceDate))!
        XCTAssertEqual(date, expected)
    }

    // MARK: - Weekdays

    func testParseMonday() throws {
        // May 4, 2026 is a Monday (weekday=2 in gregorian). "monday" should resolve to next Monday = May 11.
        let date = try makeParser().parseDate("monday")
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 5)
        XCTAssertEqual(comps.day, 11) // next monday, not today
    }

    func testParseFriday() throws {
        let date = try makeParser().parseDate("friday")
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 5)
        XCTAssertEqual(comps.day, 8)
    }

    func testParseSunday() throws {
        // May 4 2026 is Monday in UTC with gregorian calendar starting on Sunday.
        // Actually let me verify: 2026-05-04 is a Monday.
        // Sunday = weekday 1. Current = Monday (2). daysAhead = 1 - 2 = -1 + 7 = 6. May 10.
        let date = try makeParser().parseDate("sunday")
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(comps.day, 10)
    }

    // MARK: - ISO date

    func testParseISODate() throws {
        let date = try makeParser().parseDate("2026-12-25")
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 12)
        XCTAssertEqual(comps.day, 25)
    }

    // MARK: - NSDataDetector fallback

    func testParseFormalDate() throws {
        let date = try makeParser().parseDate("March 5, 2026")
        let comps = calendar.dateComponents([.month, .day], from: date)
        XCTAssertEqual(comps.month, 3)
        XCTAssertEqual(comps.day, 5)
    }

    // MARK: - Invalid input

    func testParseInvalidThrows() {
        XCTAssertThrowsError(try makeParser().parseDate("not-a-date-at-all"))
    }

    // MARK: - Time parsing

    func testParseValidTime() throws {
        let (h, m) = try makeParser().parseTime("09:30")
        XCTAssertEqual(h, 9)
        XCTAssertEqual(m, 30)
    }

    func testParseTimeInvalidFormat() {
        XCTAssertThrowsError(try makeParser().parseTime("9am"))
    }

    func testParseTimeOutOfRange() {
        XCTAssertThrowsError(try makeParser().parseTime("25:00"))
    }

    // MARK: - Combine

    func testCombineDateAndTime() throws {
        let parser = makeParser()
        let date = try parser.combine(dateString: "tomorrow", timeString: "14:30")!
        // "tomorrow" from May 4 = May 5, at 14:30
        let tomorrowAt1430 = calendar.date(from: DateComponents(year: 2026, month: 5, day: 5, hour: 14, minute: 30, second: 0))!
        XCTAssertEqual(date, tomorrowAt1430)
    }

    func testCombineDateOnly() throws {
        let parser = makeParser()
        let date = try parser.combine(dateString: "tomorrow", timeString: nil)!
        let tomorrowMidnight = calendar.date(from: DateComponents(year: 2026, month: 5, day: 5, hour: 0, minute: 0, second: 0))!
        XCTAssertEqual(date, tomorrowMidnight)
    }

    func testCombineTimeOnly() throws {
        let parser = makeParser()
        let date = try parser.combine(dateString: nil, timeString: "10:00")!
        let todayAt10 = calendar.date(from: DateComponents(year: 2026, month: 5, day: 4, hour: 10, minute: 0, second: 0))!
        XCTAssertEqual(date, todayAt10)
    }

    func testCombineNeitherReturnsNil() throws {
        let date = try makeParser().combine(dateString: nil, timeString: nil)
        XCTAssertNil(date)
    }
}
