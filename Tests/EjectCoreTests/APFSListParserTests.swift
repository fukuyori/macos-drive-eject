import Foundation
import Testing
@testable import EjectCore

struct APFSListParserTests {
    @Test func associatesVolumesWithTheirPhysicalWholeDisk() throws {
        let propertyList: [String: Any] = [
            "Containers": [[
                "PhysicalStores": [["DeviceIdentifier": "disk4s1"]],
                "Volumes": [[
                    "DeviceIdentifier": "disk5s2",
                    "Name": "UGREEN",
                    "Roles": ["Backup"]
                ]]
            ]]
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: propertyList,
            format: .xml,
            options: 0
        )

        let result = APFSListParser().volumesByPhysicalDisk(from: data)

        #expect(result["disk4"] == [
            APFSVolumeReference(
                identifier: "disk5s2",
                name: "UGREEN",
                roles: ["Backup"]
            )
        ])
    }

    @Test func hidesHelperAndPairedDataVolumes() {
        let references = [
            APFSVolumeReference(identifier: "disk5s1", name: "ExternalMac", roles: ["System"]),
            APFSVolumeReference(identifier: "disk5s2", name: "ExternalMac - Data", roles: ["Data"]),
            APFSVolumeReference(identifier: "disk5s3", name: "Preboot", roles: ["Preboot"]),
            APFSVolumeReference(identifier: "disk5s4", name: "Recovery", roles: ["Recovery"]),
            APFSVolumeReference(identifier: "disk5s5", name: "Update", roles: ["Update"]),
            APFSVolumeReference(identifier: "disk5s6", name: "VM", roles: ["VM"]),
        ]

        let displayed = references.filter {
            $0.shouldDisplay(hasMountedSystemVolume: true)
        }

        #expect(displayed.map(\.name) == ["ExternalMac"])
    }

    @Test func keepsNormalAndBackupVolumes() {
        let normal = APFSVolumeReference(identifier: "disk5s1", name: "DATA", roles: [])
        let backup = APFSVolumeReference(identifier: "disk5s2", name: "UGREEN", roles: ["Backup"])

        #expect(normal.shouldDisplay(hasMountedSystemVolume: false))
        #expect(backup.shouldDisplay(hasMountedSystemVolume: false))
    }

    @Test func usesSystemNameWhenOnlyPairedDataVolumeIsMounted() {
        let system = APFSVolumeReference(
            identifier: "disk5s1",
            name: "ExternalMac",
            roles: ["System"]
        )
        let data = APFSVolumeReference(
            identifier: "disk5s2",
            name: "ExternalMac - Data",
            roles: ["Data"]
        )

        #expect(data.userFacingName(systemVolumes: [system]) == "ExternalMac")
    }
}
