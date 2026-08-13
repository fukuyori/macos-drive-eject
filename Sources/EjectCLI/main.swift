import EjectCore
import Foundation

private let helpText = """
使用方法:
  eject                    対話画面を開く
  eject --list | -l        外部ドライブの一覧を表示
  eject --eject <disk>     指定したドライブを取り出す
  eject -e <disk>          同上
  eject --help | -h        このヘルプを表示

<disk> には disk4 または /dev/disk4 のような識別子を指定します。
"""

private func writeStandardOutput(_ text: String) {
    FileHandle.standardOutput.write(Data(text.utf8))
}

private func writeStandardError(_ text: String) {
    FileHandle.standardError.write(Data(text.utf8))
}

private func listDrives(using diskUtility: DiskUtility) throws {
    let drives = try diskUtility.externalDrives()
    guard !drives.isEmpty else {
        writeStandardOutput("マウントされている外部ドライブはありません。\n")
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
    writeStandardOutput("\(drive.displayName) (\(drive.devicePath)) を取り出しました。\n")
}

private enum CommandExecutionError: LocalizedError {
    case driveNotFound(String)
    case driveInUse(String)

    var errorDescription: String? {
        switch self {
        case .driveNotFound(let target):
            return "外部ドライブ \"\(target)\" が見つかりません。--list で識別子を確認してください。"
        case .driveInUse(let name):
            return "\(name) は使用中です。ファイルやアプリを閉じてから再試行してください。"
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

        _ = refreshDrives()

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
                    return
                }
            case .escape:
                return
            case .refresh:
                _ = refreshDrives()
            case .other:
                break
            }
        }
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
            message = "エラー: \(error.localizedDescription)"
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
            message = "\(drive.name) は使用中です。ファイルやアプリを閉じてから再試行してください。"
            return false
        }

        message = "\(drive.name) を取り出しています…"
        terminal.render(screen())

        do {
            try diskUtility.eject(drive)
            message = "\(drive.name) を取り出しました。"
            // diskutil の一覧には、取り出し直後のドライブが短時間残ることがある。
            // 取り出し成功済みの識別子を除外して、画面へ戻さないようにする。
            let refreshed = refreshDrivesKeepingMessage(excluding: drive.identifier)
            return refreshed && drives.isEmpty
        } catch {
            message = "取り出し失敗: \(error.localizedDescription)"
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
            "\u{001B}[1m外部ドライブの取り出し\u{001B}[0m",
            "",
        ]

        if drives.isEmpty {
            lines.append("  マウントされている外部ドライブはありません。")
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
        lines.append("↑/↓ 選択   Enter 取り出し   Esc 終了")
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
        writeStandardOutput(helpText + "\n")
    case .list:
        try listDrives(using: diskUtility)
    case .eject(let target):
        try ejectDrive(target, using: diskUtility)
    }
} catch let error as CommandLineOptionsError {
    writeStandardError("eject: \(error.localizedDescription)\n詳しくは eject --help を実行してください。\n")
    exit(2)
} catch {
    writeStandardError("eject: \(error.localizedDescription)\n")
    exit(EXIT_FAILURE)
}
