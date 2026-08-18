import XCTest
@testable import AstraPet

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

    func testEveryPetActionHasPresentationMetadata() {
        XCTAssertEqual(PetAction.allCases.count, 4)
        XCTAssertTrue(PetAction.allCases.allSatisfy { !$0.title.isEmpty && !$0.symbol.isEmpty })
    }
}
