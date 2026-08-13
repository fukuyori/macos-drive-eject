import Foundation
import Testing
@testable import EjectCore

struct DiskInfoParserTests {
    @Test func readsMediaName() throws {
        let data = try propertyListData([
            "MediaName": "CT1000P5SSD8",
            "DeviceModel": "Fallback Model",
            "IORegistryEntryName": "Fallback Media"
        ])

        #expect(DiskInfoParser().driveName(from: data) == "CT1000P5SSD8")
    }

    @Test func fallsBackToDeviceModelAndTrimsWhitespace() throws {
        let data = try propertyListData([
            "MediaName": "",
            "DeviceModel": "  External SSD  ",
            "IORegistryEntryName": "Fallback Media"
        ])

        #expect(DiskInfoParser().driveName(from: data) == "External SSD")
    }

    @Test func returnsNilWhenNoNameExists() throws {
        let data = try propertyListData(["DeviceIdentifier": "disk4"])
        #expect(DiskInfoParser().driveName(from: data) == nil)
        #expect(DiskInfoParser().driveName(from: Data("invalid".utf8)) == nil)
    }

    @Test func readsNonemptyMountPoint() throws {
        let data = try propertyListData(["MountPoint": "/Volumes/UGREEN"])
        #expect(DiskInfoParser().mountPoint(from: data) == "/Volumes/UGREEN")

        let unmounted = try propertyListData(["MountPoint": ""])
        #expect(DiskInfoParser().mountPoint(from: unmounted) == nil)
    }

    private func propertyListData(_ dictionary: [String: Any]) throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: dictionary,
            format: .xml,
            options: 0
        )
    }
}
