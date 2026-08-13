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
                    "Name": "UGREEN"
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
            APFSVolumeReference(identifier: "disk5s2", name: "UGREEN")
        ])
    }
}
