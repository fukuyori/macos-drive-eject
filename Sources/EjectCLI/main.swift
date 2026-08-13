import EjectCore
import Foundation

private let localizedText = LocalizedText()

private func writeStandardOutput(_ text: String) {
    FileHandle.standardOutput.write(Data(text.utf8))
}

private func writeStandardError(_ text: String) {
    FileHandle.standardError.write(Data(text.utf8))
}

private func listDrives(using diskUtility: DiskUtility) throws {
    let drives = try diskUtility.externalDrives()
    guard !drives.isEmpty else {
        writeStandardOutput(localizedText.noMountedDrives + "\n")
        return
    }

    let items = drives.map { drive in
        DriveListItem(
            drive: drive,
            isInUse: (try? diskUtility.isInUse(drive)) == true
        )
    }
    for row in DriveListFormatter().rows(for: items) {
        writeStandardOutput(row + "\n")
    }
}

private func ejectDrive(_ target: String, using diskUtility: DiskUtility) throws {
    let drives = try diskUtility.externalDrives()
    guard let drive = drives.first(where: {
        $0.identifier == target || $0.devicePath == target
    }) else {
        throw CommandExecutionError.driveNotFound(target)
    }

    if try diskUtility.isInUse(drive) {
        throw CommandExecutionError.driveInUse(drive.displayName)
    }

    try diskUtility.eject(drive)
    writeStandardOutput(localizedText.ejected(name: drive.displayName, path: drive.devicePath) + "\n")
}

private enum CommandExecutionError: LocalizedError {
    case driveNotFound(String)
    case driveInUse(String)

    var errorDescription: String? {
        switch self {
        case .driveNotFound(let target):
            return localizedText.driveNotFound(target)
        case .driveInUse(let name):
            return localizedText.driveInUse(name)
        }
    }
}

struct EjectApp {
    private let diskUtility = DiskUtility()
    private let terminal = Terminal()
    private var drives: [Drive] = []
    private var usageByIdentifier: [String: Bool] = [:]
    private var selectedIndex = 0
    private var message: String?

    mutating func run() throws {
        try terminal.start()
        defer { terminal.stop() }

        if refreshDrives() && drives.isEmpty {
            finishWithNoMountedDrives()
            return
        }

        while true {
            terminal.render(screen())

            // 入力がなくても定期的に戻り、新規接続や切断を一覧へ反映する。
            switch terminal.readKey(timeoutMilliseconds: 1_000) {
            case .up:
                moveSelection(by: -1)
            case .down:
                moveSelection(by: 1)
            case .enter:
                if ejectSelectedDrive() {
                    finishWithNoMountedDrives()
                    return
                }
            case .escape:
                return
            case .refresh:
                if refreshDrives() && drives.isEmpty {
                    finishWithNoMountedDrives()
                    return
                }
            case .other:
                break
            }
        }
    }

    private func finishWithNoMountedDrives() {
        // 全画面表示を閉じてから、通常のコマンドラインへ結果を残す。
        terminal.stop()
        writeStandardOutput(localizedText.noMountedDrives + "\n")
    }

    @discardableResult
    private mutating func refreshDrives(excluding identifier: String? = nil) -> Bool {
        let selectedIdentifier = drives.indices.contains(selectedIndex)
            ? drives[selectedIndex].identifier
            : nil

        do {
            let refreshedDrives = try diskUtility.externalDrives()
            drives = refreshedDrives.filter { $0.identifier != identifier }
            usageByIdentifier = Dictionary(
                uniqueKeysWithValues: drives.map { drive in
                    (drive.identifier, (try? diskUtility.isInUse(drive)) ?? false)
                }
            )
            if let selectedIdentifier,
               let refreshedIndex = drives.firstIndex(where: {
                   $0.identifier == selectedIdentifier
               }) {
                selectedIndex = refreshedIndex
            } else {
                selectedIndex = min(selectedIndex, max(0, drives.count - 1))
            }
            return true
        } catch {
            drives = []
            usageByIdentifier = [:]
            selectedIndex = 0
            message = "\(localizedText.errorPrefix): \(error.localizedDescription)"
            return false
        }
    }

    private mutating func moveSelection(by offset: Int) {
        guard !drives.isEmpty else { return }
        selectedIndex = (selectedIndex + offset + drives.count) % drives.count
        message = nil
    }

    private mutating func ejectSelectedDrive() -> Bool {
        guard drives.indices.contains(selectedIndex) else { return false }
        let drive = drives[selectedIndex]

        if (try? diskUtility.isInUse(drive)) == true {
            usageByIdentifier[drive.identifier] = true
            message = localizedText.driveInUse(drive.name)
            return false
        }

        message = localizedText.ejecting(name: drive.name)
        terminal.render(screen())

        do {
            try diskUtility.eject(drive)
            message = localizedText.ejected(name: drive.name)
            // diskutil の一覧には、取り出し直後のドライブが短時間残ることがある。
            // 取り出し成功済みの識別子を除外して、画面へ戻さないようにする。
            let refreshed = refreshDrivesKeepingMessage(excluding: drive.identifier)
            return refreshed && drives.isEmpty
        } catch {
            message = "\(localizedText.ejectionFailedPrefix): \(error.localizedDescription)"
            _ = refreshDrivesKeepingMessage()
            return false
        }
    }

    @discardableResult
    private mutating func refreshDrivesKeepingMessage(excluding identifier: String? = nil) -> Bool {
        let currentMessage = message
        let refreshed = refreshDrives(excluding: identifier)
        if message == nil || !drives.isEmpty {
            message = currentMessage
        }
        return refreshed
    }

    private func screen() -> String {
        var lines = [
            "\u{001B}[1m\(localizedText.title)\u{001B}[0m",
            "",
        ]

        if drives.isEmpty {
            lines.append("  \(localizedText.noMountedDrives)")
        } else {
            let items = drives.map { drive in
                DriveListItem(
                    drive: drive,
                    isInUse: usageByIdentifier[drive.identifier] == true
                )
            }
            let rows = DriveListFormatter().rows(for: items)
            for (index, row) in rows.enumerated() {
                let cursor = index == selectedIndex ? "❯" : " "
                let style = index == selectedIndex ? "\u{001B}[7m" : ""
                let reset = index == selectedIndex ? "\u{001B}[0m" : ""
                lines.append("\(cursor) \(style)\(row)\(reset)")
            }
        }

        lines.append("")
        if let message {
            lines.append(message)
            lines.append("")
        }
        lines.append(localizedText.controls)
        return lines.joined(separator: "\r\n")
    }
}

do {
    let command = try CommandLineOptions().parse(Array(CommandLine.arguments.dropFirst()))
    let diskUtility = DiskUtility()

    switch command {
    case .interactive:
        var app = EjectApp()
        try app.run()
    case .help:
        writeStandardOutput(localizedText.help + "\n")
    case .list:
        try listDrives(using: diskUtility)
    case .eject(let target):
        try ejectDrive(target, using: diskUtility)
    }
} catch let error as CommandLineOptionsError {
    writeStandardError("eject: \(error.localizedDescription)\n\(localizedText.runHelp)\n")
    exit(2)
} catch {
    writeStandardError("eject: \(error.localizedDescription)\n")
    exit(EXIT_FAILURE)
}
