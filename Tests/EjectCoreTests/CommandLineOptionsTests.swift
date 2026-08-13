import Testing
@testable import EjectCore

struct CommandLineOptionsTests {
    private let parser = CommandLineOptions()

    @Test func noArgumentsStartsInteractiveMode() throws {
        #expect(try parser.parse([]) == .interactive)
    }

    @Test(arguments: [["--help"], ["-h"]])
    func parsesHelp(_ arguments: [String]) throws {
        #expect(try parser.parse(arguments) == .help)
    }

    @Test(arguments: [["--list"], ["-l"]])
    func parsesList(_ arguments: [String]) throws {
        #expect(try parser.parse(arguments) == .list)
    }

    @Test func parsesEjectForms() throws {
        #expect(try parser.parse(["--eject", "disk4"]) == .eject("disk4"))
        #expect(try parser.parse(["-e", "/dev/disk4"]) == .eject("/dev/disk4"))
        #expect(try parser.parse(["--eject=disk4"]) == .eject("disk4"))
    }

    @Test func ejectRequiresTarget() {
        #expect(throws: CommandLineOptionsError.missingEjectTarget) {
            try parser.parse(["--eject"])
        }
        #expect(throws: CommandLineOptionsError.missingEjectTarget) {
            try parser.parse(["--eject="])
        }
    }

    @Test func rejectsUnknownOrExtraArguments() {
        #expect(throws: CommandLineOptionsError.unknownOption("--unknown")) {
            try parser.parse(["--unknown"])
        }
        #expect(throws: CommandLineOptionsError.unexpectedArguments) {
            try parser.parse(["--list", "disk4"])
        }
    }
}
