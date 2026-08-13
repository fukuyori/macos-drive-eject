import Testing
@testable import EjectCore

struct DriveTests {
    @Test func displaysVolumeNameBeforePhysicalDriveName() {
        let drive = Drive(
            identifier: "disk4",
            name: "CT1000P5SSD8",
            volumeNames: ["UGREEN"],
            size: 1_000_204_886_016
        )

        #expect(drive.displayName == "UGREEN - CT1000P5SSD8")
    }

    @Test func doesNotRepeatIdenticalVolumeAndDriveNames() {
        let drive = Drive(
            identifier: "disk6",
            name: "ESD-EHA",
            volumeNames: ["ESD-EHA"],
            size: 1_000_204_886_016
        )

        #expect(drive.displayName == "ESD-EHA")
    }

    @Test func mountedStateRequiresAMountPoint() {
        let mounted = Drive(
            identifier: "disk4",
            name: "SSD",
            volumeNames: ["DATA"],
            mountPoints: ["/Volumes/DATA"],
            size: 1_000
        )
        let ejected = Drive(
            identifier: "disk4",
            name: "SSD",
            volumeNames: ["DATA"],
            mountPoints: [],
            size: 1_000
        )

        #expect(mounted.isMounted)
        #expect(!ejected.isMounted)
    }
}
