import Darwin
import EjectCore
import Foundation

enum Key {
    case up
    case down
    case enter
    case escape
    case refresh
    case other
}

enum TerminalError: LocalizedError {
    case notInteractive
    case couldNotReadSettings
    case couldNotEnableRawMode

    var errorDescription: String? {
        let text = LocalizedText()
        switch self {
        case .notInteractive:
            return text.terminalNotInteractive
        case .couldNotReadSettings:
            return text.terminalReadFailed
        case .couldNotEnableRawMode:
            return text.terminalRawModeFailed
        }
    }
}

final class Terminal {
    private var originalSettings = termios()
    private var isRawModeEnabled = false

    func start() throws {
        guard isatty(STDIN_FILENO) == 1, isatty(STDOUT_FILENO) == 1 else {
            throw TerminalError.notInteractive
        }
        guard tcgetattr(STDIN_FILENO, &originalSettings) == 0 else {
            throw TerminalError.couldNotReadSettings
        }

        var raw = originalSettings
        // ISIG も無効にし、Control-C を通常の入力として受け取る。
        // これにより終了経路が必ず stop() を通り、端末設定が元へ戻る。
        raw.c_lflag &= ~tcflag_t(ICANON | ECHO | ISIG)
        raw.c_cc.16 = 1 // VMIN
        raw.c_cc.17 = 0 // VTIME

        guard tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == 0 else {
            throw TerminalError.couldNotEnableRawMode
        }
        isRawModeEnabled = true
        write("\u{001B}[?1049h\u{001B}[?25l")
    }

    func stop() {
        guard isRawModeEnabled else { return }
        write("\u{001B}[0m\u{001B}[?25h\u{001B}[?1049l")
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalSettings)
        isRawModeEnabled = false
    }

    func render(_ content: String) {
        write("\u{001B}[H\u{001B}[2J" + content)
    }

    func readKey(timeoutMilliseconds: Int32? = nil) -> Key {
        if let timeoutMilliseconds,
           !hasInput(timeoutMilliseconds: timeoutMilliseconds) {
            return .refresh
        }

        guard let first = readByte() else { return .escape }

        switch first {
        case 10, 13:
            return .enter
        case 3, 27:
            if first == 3 { return .escape }
            guard hasInput(timeoutMilliseconds: 40), let second = readByte() else {
                return .escape
            }
            guard second == 91,
                  hasInput(timeoutMilliseconds: 40),
                  let third = readByte() else {
                return .other
            }
            if third == 65 { return .up }
            if third == 66 { return .down }
            return .other
        default:
            return .other
        }
    }

    private func readByte() -> UInt8? {
        var byte: UInt8 = 0
        return Darwin.read(STDIN_FILENO, &byte, 1) == 1 ? byte : nil
    }

    private func hasInput(timeoutMilliseconds: Int32) -> Bool {
        var descriptor = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
        return poll(&descriptor, 1, timeoutMilliseconds) > 0
    }

    private func write(_ string: String) {
        FileHandle.standardOutput.write(Data(string.utf8))
    }

    deinit {
        stop()
    }
}
