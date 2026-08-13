import Testing
@testable import EjectCore

struct EjectionVerifierTests {
    @Test func succeedsAsSoonAsDriveDisconnects() throws {
        var checks = 0
        let verifier = EjectionVerifier(maximumAttempts: 5, pollingInterval: 0)

        let result = try verifier.waitUntilDisconnected {
            checks += 1
            return checks < 3
        }

        #expect(result)
        #expect(checks == 3)
    }

    @Test func failsAfterMaximumAttempts() throws {
        var checks = 0
        let verifier = EjectionVerifier(maximumAttempts: 4, pollingInterval: 0)

        let result = try verifier.waitUntilDisconnected {
            checks += 1
            return true
        }

        #expect(!result)
        #expect(checks == 4)
    }

    @Test func propagatesCheckErrors() {
        enum CheckError: Error { case failed }
        let verifier = EjectionVerifier(maximumAttempts: 2, pollingInterval: 0)

        #expect(throws: CheckError.failed) {
            try verifier.waitUntilDisconnected {
                throw CheckError.failed
            }
        }
    }
}
