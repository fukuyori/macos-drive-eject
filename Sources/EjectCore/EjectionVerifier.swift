import Foundation

struct EjectionVerifier {
    let maximumAttempts: Int
    let pollingInterval: TimeInterval

    init(maximumAttempts: Int = 41, pollingInterval: TimeInterval = 0.25) {
        precondition(maximumAttempts > 0)
        precondition(pollingInterval >= 0)
        self.maximumAttempts = maximumAttempts
        self.pollingInterval = pollingInterval
    }

    func waitUntilDisconnected(
        isConnected: () throws -> Bool
    ) throws -> Bool {
        for attempt in 0..<maximumAttempts {
            if try !isConnected() {
                return true
            }

            if attempt < maximumAttempts - 1, pollingInterval > 0 {
                Thread.sleep(forTimeInterval: pollingInterval)
            }
        }
        return false
    }
}
