import Testing
@testable import EjectCore

struct DriveSelectionNavigatorTests {
    private let navigator = DriveSelectionNavigator()

    @Test func selectsFirstUnusedDrive() {
        #expect(navigator.firstSelectableIndex(usage: [true, false, false]) == 1)
    }

    @Test func returnsNoSelectionWhenEveryDriveIsInUse() {
        #expect(navigator.firstSelectableIndex(usage: [true, true]) == nil)
        #expect(navigator.movedSelection(current: nil, by: 1, usage: [true, true]) == nil)
    }

    @Test func skipsInUseDrivesInBothDirections() {
        let usage = [false, true, false, true]

        #expect(navigator.movedSelection(current: 0, by: 1, usage: usage) == 2)
        #expect(navigator.movedSelection(current: 2, by: 1, usage: usage) == 0)
        #expect(navigator.movedSelection(current: 0, by: -1, usage: usage) == 2)
    }

    @Test func replacesSelectionThatBecameInUse() {
        #expect(navigator.normalizedSelection(current: 1, usage: [false, true, false]) == 0)
        #expect(navigator.normalizedSelection(current: 2, usage: [false, true, false]) == 2)
    }
}
