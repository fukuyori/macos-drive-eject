import Foundation

public enum CLICommand: Equatable, Sendable {
    case interactive
    case help
    case list
    case eject(String)
}

public enum CommandLineOptionsError: LocalizedError, Equatable {
    case unknownOption(String)
    case missingEjectTarget
    case unexpectedArguments

    public var errorDescription: String? {
        let text = LocalizedText()
        switch self {
        case .unknownOption(let option):
            return text.unknownOption(option)
        case .missingEjectTarget:
            return text.missingEjectTarget
        case .unexpectedArguments:
            return text.unexpectedArguments
        }
    }
}

public struct CommandLineOptions {
    public init() {}

    public func parse(_ arguments: [String]) throws -> CLICommand {
        guard let first = arguments.first else { return .interactive }

        switch first {
        case "--help", "-h":
            guard arguments.count == 1 else {
                throw CommandLineOptionsError.unexpectedArguments
            }
            return .help

        case "--list", "-l":
            guard arguments.count == 1 else {
                throw CommandLineOptionsError.unexpectedArguments
            }
            return .list

        case "--eject", "-e":
            guard arguments.count >= 2, !arguments[1].isEmpty else {
                throw CommandLineOptionsError.missingEjectTarget
            }
            guard arguments.count == 2 else {
                throw CommandLineOptionsError.unexpectedArguments
            }
            return .eject(arguments[1])

        default:
            if first.hasPrefix("--eject=") {
                guard arguments.count == 1 else {
                    throw CommandLineOptionsError.unexpectedArguments
                }
                let target = String(first.dropFirst("--eject=".count))
                guard !target.isEmpty else {
                    throw CommandLineOptionsError.missingEjectTarget
                }
                return .eject(target)
            }
            throw CommandLineOptionsError.unknownOption(first)
        }
    }
}
