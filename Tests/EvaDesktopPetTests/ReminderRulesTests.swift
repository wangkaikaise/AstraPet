import XCTest
@testable import EvaDesktopPet

final class ReminderRulesTests: XCTestCase {
    func testAcceptsValidReminder() {
        XCTAssertTrue(ReminderRules.isValid(title: "喝水", hour: 9, minute: 30))
    }

    func testRejectsBlankTitle() {
        XCTAssertFalse(ReminderRules.isValid(title: "  \n", hour: 9, minute: 30))
    }

    func testRejectsInvalidTime() {
        XCTAssertFalse(ReminderRules.isValid(title: "喝水", hour: 24, minute: 0))
        XCTAssertFalse(ReminderRules.isValid(title: "喝水", hour: 8, minute: 60))
    }

    func testReminderTimeTextIsZeroPadded() {
        XCTAssertEqual(PetReminder(title: "站起来", hour: 7, minute: 5).timeText, "07:05")
    }

    func testIntervalReminderPresentationAndValidation() {
        let reminder = PetReminder(
            title: "喝水", hour: 9, minute: 0, schedule: .interval, intervalMinutes: 45
        )
        XCTAssertEqual(reminder.timeText, "每 45 分钟")
        XCTAssertTrue(ReminderRules.isValidInterval(title: "喝水", minutes: 15))
        XCTAssertFalse(ReminderRules.isValidInterval(title: "喝水", minutes: 10))
    }

    func testOlderReminderJSONMigratesToDailySchedule() throws {
        let json = #"{"id":"D9525624-BC24-4C38-B279-22802234C329","title":"休息","hour":10,"minute":5,"isEnabled":true}"#.data(using: .utf8)!
        let reminder = try JSONDecoder().decode(PetReminder.self, from: json)
        XCTAssertEqual(reminder.schedule, .daily)
        XCTAssertEqual(reminder.timeText, "10:05")
    }

    func testEveryPetActionHasPresentationMetadata() {
        XCTAssertEqual(PetAction.allCases.count, 4)
        XCTAssertTrue(PetAction.allCases.allSatisfy { !$0.title.isEmpty && !$0.symbol.isEmpty })
    }

    func testMoodCycleReturnsToBeginning() {
        var mood = PetMood.cheerful
        for _ in PetMood.allCases { mood = mood.next }
        XCTAssertEqual(mood, .cheerful)
    }

    func testThirtyMinuteMoodInterval() {
        XCTAssertEqual(MoodInterval.thirtyMinutes.rawValue, 30 * 60)
    }

    func testShieldStylesHavePresentationTitles() {
        XCTAssertEqual(ShieldStyle.allCases.count, 3)
        XCTAssertTrue(ShieldStyle.allCases.allSatisfy { !$0.title.isEmpty })
    }

    func testMetricsRefreshIntervalsStayLowFrequency() {
        XCTAssertEqual(MetricsRefreshInterval.allCases.map(\.rawValue), [2, 5, 10])
    }
}
