import Foundation

public enum DiskListParserError: LocalizedError {
    case invalidPropertyList

    public var errorDescription: String? {
        switch self {
        case .invalidPropertyList:
            return LocalizedText().diskListParsingFailed
        }
    }
}

public struct DiskListParser {
    public init() {}

    public func parse(_ data: Data) throws -> [Drive] {
        let value = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let root = value as? [String: Any],
              let disks = root["AllDisksAndPartitions"] as? [[String: Any]] else {
            throw DiskListParserError.invalidPropertyList
        }

        return disks.compactMap(parseWholeDisk).sorted {
            $0.identifier.localizedStandardCompare($1.identifier) == .orderedAscending
        }
    }

    private func parseWholeDisk(_ dictionary: [String: Any]) -> Drive? {
        guard let identifier = dictionary["DeviceIdentifier"] as? String,
              identifier.range(of: #"^disk[0-9]+$"#, options: .regularExpression) != nil else {
            return nil
        }

        let name = firstNonemptyString(
            dictionary["MediaName"],
            dictionary["IORegistryEntryName"],
            dictionary["DeviceIdentifier"]
        ) ?? identifier
        let size = unsignedInteger(dictionary["Size"]) ?? 0
        let volumeNames = collectVolumeNames(from: dictionary)
        let volumeIdentifiers = collectVolumeIdentifiers(from: dictionary)
        let mountPoints = collectMountPoints(from: dictionary)

        return Drive(
            identifier: identifier,
            name: name,
            volumeNames: volumeNames,
            volumeIdentifiers: volumeIdentifiers,
            mountPoints: mountPoints,
            size: size
        )
    }

    private func collectVolumeNames(from dictionary: [String: Any]) -> [String] {
        var names: [String] = []

        func visit(_ value: Any) {
            if let item = value as? [String: Any] {
                if let name = item["VolumeName"] as? String,
                   !name.isEmpty,
                   !names.contains(name) {
                    names.append(name)
                }
                if let partitions = item["Partitions"] as? [[String: Any]] {
                    partitions.forEach(visit)
                }
                if let apfsVolumes = item["APFSVolumes"] as? [[String: Any]] {
                    apfsVolumes.forEach(visit)
                }
            }
        }

        visit(dictionary)
        return names
    }

    private func collectMountPoints(from dictionary: [String: Any]) -> [String] {
        var mountPoints: [String] = []

        func visit(_ value: Any) {
            if let item = value as? [String: Any] {
                if let mountPoint = item["MountPoint"] as? String,
                   !mountPoint.isEmpty,
                   !mountPoints.contains(mountPoint) {
                    mountPoints.append(mountPoint)
                }
                if let partitions = item["Partitions"] as? [[String: Any]] {
                    partitions.forEach(visit)
                }
                if let apfsVolumes = item["APFSVolumes"] as? [[String: Any]] {
                    apfsVolumes.forEach(visit)
                }
            }
        }

        visit(dictionary)
        return mountPoints
    }

    private func collectVolumeIdentifiers(from dictionary: [String: Any]) -> [String] {
        var identifiers: [String] = []

        func visit(_ value: Any, isWholeDisk: Bool = false) {
            if let item = value as? [String: Any] {
                if !isWholeDisk,
                   let identifier = item["DeviceIdentifier"] as? String,
                   !identifiers.contains(identifier) {
                    identifiers.append(identifier)
                }
                if let partitions = item["Partitions"] as? [[String: Any]] {
                    partitions.forEach { visit($0) }
                }
                if let apfsVolumes = item["APFSVolumes"] as? [[String: Any]] {
                    apfsVolumes.forEach { visit($0) }
                }
            }
        }

        visit(dictionary, isWholeDisk: true)
        return identifiers
    }

    private func firstNonemptyString(_ values: Any?...) -> String? {
        values.lazy.compactMap { $0 as? String }.first { !$0.isEmpty }
    }

    private func unsignedInteger(_ value: Any?) -> UInt64? {
        switch value {
        case let number as NSNumber:
            return number.uint64Value
        case let integer as UInt64:
            return integer
        case let integer as Int where integer >= 0:
            return UInt64(integer)
        default:
            return nil
        }
    }
}
