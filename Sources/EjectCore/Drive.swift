import Foundation

public struct Drive: Equatable, Sendable {
    public let identifier: String
    public let name: String
    public let volumeNames: [String]
    public let volumeIdentifiers: [String]
    public let mountPoints: [String]
    public let size: UInt64

    public init(
        identifier: String,
        name: String,
        volumeNames: [String],
        volumeIdentifiers: [String] = [],
        mountPoints: [String] = [],
        size: UInt64
    ) {
        self.identifier = identifier
        self.name = name
        self.volumeNames = volumeNames
        self.volumeIdentifiers = volumeIdentifiers
        self.mountPoints = mountPoints
        self.size = size
    }

    public var devicePath: String {
        "/dev/\(identifier)"
    }

    /// Finderや通常のアプリから利用できるボリュームがあるか。
    public var isMounted: Bool {
        !mountPoints.isEmpty
    }

    public var displayName: String {
        let volumes = volumeNames.filter {
            !$0.isEmpty && $0.caseInsensitiveCompare(name) != .orderedSame
        }
        guard !volumes.isEmpty else { return name }
        return "\(volumes.joined(separator: ", ")) - \(name)"
    }

    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: size), countStyle: .file)
    }
}
