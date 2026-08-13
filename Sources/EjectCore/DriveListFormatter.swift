import Foundation

public struct DriveListItem: Equatable, Sendable {
    public let drive: Drive
    public let isInUse: Bool

    public init(drive: Drive, isInUse: Bool) {
        self.drive = drive
        self.isInUse = isInUse
    }
}

public struct DriveListFormatter {
    public init() {}

    public func rows(
        for items: [DriveListItem],
        language: AppLanguage = .current
    ) -> [String] {
        guard !items.isEmpty else { return [] }

        let text = LocalizedText(language: language)
        let names = items.map { $0.drive.displayName }
        let usages = items.map {
            "[\($0.isInUse ? text.inUseLabel : text.notInUseLabel)]"
        }
        let sizes = items.map { "[\($0.drive.formattedSize)]" }
        let nameWidth = names.map(terminalWidth).max() ?? 0
        let usageWidth = usages.map(terminalWidth).max() ?? 0
        let sizeWidth = sizes.map(terminalWidth).max() ?? 0

        return items.indices.map { index in
            [
                padded(names[index], to: nameWidth),
                padded(usages[index], to: usageWidth),
                padded(sizes[index], to: sizeWidth),
                items[index].drive.devicePath,
            ].joined(separator: "  ")
        }
    }

    public func terminalWidth(_ string: String) -> Int {
        string.unicodeScalars.reduce(into: 0) { width, scalar in
            let category = scalar.properties.generalCategory
            if category == .nonspacingMark || category == .enclosingMark || category == .format {
                return
            }
            width += isWide(scalar.value) ? 2 : 1
        }
    }

    private func padded(_ string: String, to width: Int) -> String {
        string + String(repeating: " ", count: max(0, width - terminalWidth(string)))
    }

    private func isWide(_ value: UInt32) -> Bool {
        switch value {
        case 0x1100...0x115F,
             0x2329...0x232A,
             0x2E80...0x303E,
             0x3040...0xA4CF,
             0xAC00...0xD7A3,
             0xF900...0xFAFF,
             0xFE10...0xFE19,
             0xFE30...0xFE6F,
             0xFF00...0xFF60,
             0xFFE0...0xFFE6,
             0x1F300...0x1FAFF,
             0x20000...0x3FFFD:
            return true
        default:
            return false
        }
    }
}
