import Foundation

public struct DiskInfoParser {
    public init() {}

    public func driveName(from data: Data) -> String? {
        guard let dictionary = dictionary(from: data) else {
            return nil
        }

        for key in ["MediaName", "DeviceModel", "IORegistryEntryName"] {
            guard let value = dictionary[key] as? String else { continue }
            let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                return name
            }
        }
        return nil
    }

    public func mountPoint(from data: Data) -> String? {
        guard let mountPoint = dictionary(from: data)?["MountPoint"] as? String else {
            return nil
        }
        let value = mountPoint.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func dictionary(from data: Data) -> [String: Any]? {
        guard let value = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) else { return nil }
        return value as? [String: Any]
    }
}
