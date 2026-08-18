import Foundation
import Testing
@testable import EjectCore

struct DiskListParserTests {
    @Test func parsesWholeExternalDisksAndNestedVolumes() throws {
        let propertyList: [String: Any] = [
            "AllDisksAndPartitions": [
                [
                    "DeviceIdentifier": "disk4",
                    "MediaName": "Portable SSD",
                    "Size": 1_000_204_886_016 as UInt64,
                    "Partitions": [
                        [
                            "DeviceIdentifier": "disk4s1",
                            "VolumeName": "WORK",
                            "MountPoint": "/Volumes/WORK"
                        ],
                        [
                            "DeviceIdentifier": "disk4s2",
                            "APFSVolumes": [
                                [
                                    "DeviceIdentifier": "disk5s1",
                                    "VolumeName": "DATA",
                                    "MountPoint": "/Volumes/DATA"
                                ]
                            ]
                        ]
                    ]
                ],
                [
                    "DeviceIdentifier": "disk12",
                    "IORegistryEntryName": "USB Flash Disk",
                    "Size": 64_000_000_000 as UInt64,
                    "Partitions": []
                ]
            ]
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: propertyList,
            format: .xml,
            options: 0
        )

        let drives = try DiskListParser().parse(data)

        #expect(drives.count == 2)
        #expect(drives[0].identifier == "disk4")
        #expect(drives[0].name == "Portable SSD")
        #expect(drives[0].volumeNames == ["WORK", "DATA"])
        #expect(drives[0].volumeIdentifiers == ["disk4s1", "disk4s2", "disk5s1"])
        #expect(drives[0].mountPoints == ["/Volumes/WORK", "/Volumes/DATA"])
        #expect(drives[1].identifier == "disk12")
        #expect(drives[1].name == "USB Flash Disk")
    }

    @Test func rejectsUnexpectedTopLevelStructure() throws {
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["Unexpected": []],
            format: .xml,
            options: 0
        )

        #expect(throws: DiskListParserError.self) {
            try DiskListParser().parse(data)
        }
    }

    @Test func omitsNamesOfUnmountedPartitions() throws {
        let propertyList: [String: Any] = [
            "AllDisksAndPartitions": [[
                "DeviceIdentifier": "disk4",
                "Size": 1_000_000,
                "Partitions": [
                    ["DeviceIdentifier": "disk4s1", "VolumeName": "EFI"],
                    [
                        "DeviceIdentifier": "disk4s2",
                        "VolumeName": "VISIBLE",
                        "MountPoint": "/Volumes/VISIBLE"
                    ]
                ]
            ]]
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: propertyList,
            format: .xml,
            options: 0
        )

        #expect(try DiskListParser().parse(data)[0].volumeNames == ["VISIBLE"])
    }
}
