import Testing
@testable import EjectCore

struct DriveListFormatterTests {
    @Test func alignsColumnsForDifferentNameAndSizeLengths() {
        let items = [
            DriveListItem(
                drive: Drive(
                    identifier: "disk4",
                    name: "CT1000P5SSD8",
                    volumeNames: ["UGREEN"],
                    size: 1_000_204_886_016
                ),
                isInUse: false
            ),
            DriveListItem(
                drive: Drive(
                    identifier: "disk6",
                    name: "ESD-EHA",
                    volumeNames: ["ESD-EHA"],
                    size: 64_000_000_000
                ),
                isInUse: true
            ),
        ]

        let rows = DriveListFormatter().rows(for: items, language: .japanese)

        #expect(rows == [
            "UGREEN - CT1000P5SSD8  [未使用]  [1 TB]   /dev/disk4",
            "ESD-EHA                [使用中]  [64 GB]  /dev/disk6",
        ])
    }

    @Test func accountsForWideJapaneseCharacters() {
        let formatter = DriveListFormatter()
        #expect(formatter.terminalWidth("外部SSD") == 7)
        #expect(formatter.terminalWidth("UGREEN") == 6)
    }
}
