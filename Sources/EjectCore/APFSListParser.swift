import Foundation

struct APFSVolumeReference: Equatable, Sendable {
    let identifier: String
    let name: String
    let roles: [String]

    var isSystemVolume: Bool {
        roles.contains { $0.caseInsensitiveCompare("System") == .orderedSame }
    }

    var isDataVolume: Bool {
        roles.contains { $0.caseInsensitiveCompare("Data") == .orderedSame }
    }

    func userFacingName(systemVolumes: [APFSVolumeReference]) -> String {
        guard isDataVolume else { return name }

        return systemVolumes.first { systemVolume in
            name.caseInsensitiveCompare("\(systemVolume.name) - Data") == .orderedSame
        }?.name ?? name
    }

    func shouldDisplay(hasMountedSystemVolume: Bool) -> Bool {
        let normalizedRoles = Set(roles.map { $0.lowercased() })
        let hiddenRoles: Set<String> = [
            "preboot", "recovery", "update", "vm", "xart", "hardware"
        ]

        if !normalizedRoles.isDisjoint(with: hiddenRoles) {
            return false
        }
        if hasMountedSystemVolume && isDataVolume {
            return false
        }
        return true
    }
}

struct APFSListParser {
    func volumesByPhysicalDisk(from data: Data) -> [String: [APFSVolumeReference]] {
        guard let value = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ), let root = value as? [String: Any],
           let containers = root["Containers"] as? [[String: Any]] else {
            return [:]
        }

        var result: [String: [APFSVolumeReference]] = [:]
        for container in containers {
            let physicalDisks = wholeDiskIdentifiers(from: container)
            let volumes = volumeReferences(from: container)
            for disk in physicalDisks where !volumes.isEmpty {
                result[disk, default: []].append(contentsOf: volumes)
            }
        }
        return result
    }

    private func wholeDiskIdentifiers(from container: [String: Any]) -> Set<String> {
        guard let stores = container["PhysicalStores"] as? [[String: Any]] else {
            return []
        }

        return Set(stores.compactMap { store in
            guard let identifier = store["DeviceIdentifier"] as? String,
                  let range = identifier.range(
                    of: #"^disk[0-9]+"#,
                    options: .regularExpression
                  ) else { return nil }
            return String(identifier[range])
        })
    }

    private func volumeReferences(from container: [String: Any]) -> [APFSVolumeReference] {
        guard let volumes = container["Volumes"] as? [[String: Any]] else {
            return []
        }

        return volumes.compactMap { volume in
            guard let identifier = volume["DeviceIdentifier"] as? String,
                  let name = volume["Name"] as? String,
                  !name.isEmpty else { return nil }
            return APFSVolumeReference(
                identifier: identifier,
                name: name,
                roles: volume["Roles"] as? [String] ?? []
            )
        }
    }
}
