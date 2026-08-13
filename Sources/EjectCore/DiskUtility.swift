import Foundation

public enum DiskUtilityError: LocalizedError {
    case commandFailed(String)
    case invalidIdentifier(String)
    case ejectionCouldNotBeVerified(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message
        case .invalidIdentifier(let identifier):
            return "不正なドライブ識別子です: \(identifier)"
        case .ejectionCouldNotBeVerified(let identifier):
            return "取り出しコマンドは完了しましたが、\(identifier) の全ボリュームがアンマウントされたことを10秒以内に確認できませんでした。安全を確認するまで物理的に取り外さないでください。"
        }
    }
}

public struct DiskUtility {
    private let executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")

    public init() {}

    public func externalDrives() throws -> [Drive] {
        let result = try run(arguments: ["list", "-plist", "external", "physical"])
        guard result.status == 0 else {
            throw DiskUtilityError.commandFailed(errorMessage(from: result))
        }

        let drives = try DiskListParser().parse(result.stdout).map(enrichWithDiskInfo)
        return enrichWithAPFSVolumes(drives).filter(\.isMounted)
    }

    private func enrichWithDiskInfo(_ drive: Drive) -> Drive {
        guard let result = try? run(arguments: ["info", "-plist", drive.identifier]),
              result.status == 0,
              let name = DiskInfoParser().driveName(from: result.stdout) else {
            return drive
        }

        return Drive(
            identifier: drive.identifier,
            name: name,
            volumeNames: drive.volumeNames,
            volumeIdentifiers: drive.volumeIdentifiers,
            mountPoints: drive.mountPoints,
            size: drive.size
        )
    }

    private func enrichWithAPFSVolumes(_ drives: [Drive]) -> [Drive] {
        guard let result = try? run(arguments: ["apfs", "list", "-plist"]),
              result.status == 0 else {
            return drives
        }

        let referencesByDisk = APFSListParser().volumesByPhysicalDisk(from: result.stdout)
        return drives.map { drive in
            guard let references = referencesByDisk[drive.identifier] else { return drive }

            var volumeNames = drive.volumeNames
            var volumeIdentifiers = drive.volumeIdentifiers
            var mountPoints = drive.mountPoints
            for reference in references {
                if !volumeNames.contains(reference.name) {
                    volumeNames.append(reference.name)
                }
                if !volumeIdentifiers.contains(reference.identifier) {
                    volumeIdentifiers.append(reference.identifier)
                }

                guard let info = try? run(arguments: ["info", "-plist", reference.identifier]),
                      info.status == 0,
                      let mountPoint = DiskInfoParser().mountPoint(from: info.stdout),
                      !mountPoints.contains(mountPoint) else { continue }
                mountPoints.append(mountPoint)
            }

            return Drive(
                identifier: drive.identifier,
                name: drive.name,
                volumeNames: volumeNames,
                volumeIdentifiers: volumeIdentifiers,
                mountPoints: mountPoints,
                size: drive.size
            )
        }
    }

    public func eject(_ drive: Drive) throws {
        guard drive.identifier.range(of: #"^disk[0-9]+$"#, options: .regularExpression) != nil else {
            throw DiskUtilityError.invalidIdentifier(drive.identifier)
        }

        let result = try run(arguments: ["eject", drive.devicePath])
        guard result.status == 0 else {
            throw DiskUtilityError.commandFailed(errorMessage(from: result))
        }

        let unmounted = try EjectionVerifier().waitUntilDisconnected {
            try drive.volumeIdentifiers.contains { identifier in
                try isVolumeMounted(identifier)
            }
        }
        guard unmounted else {
            throw DiskUtilityError.ejectionCouldNotBeVerified(drive.identifier)
        }
    }

    /// マウント中のファイルシステムで、いずれかのプロセスがファイルを
    /// 開いているかを確認する。アンマウント済みなら false を返す。
    public func isInUse(_ drive: Drive) throws -> Bool {
        for mountPoint in drive.mountPoints {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
            process.arguments = ["-nP", "-t", "+f", "--", mountPoint]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            try process.run()

            let deadline = Date().addingTimeInterval(2)
            while process.isRunning && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.05)
            }

            // 使用状況を時間内に判定できない場合は、安全側へ倒して
            // 「使用中」と扱う。一覧取得を無期限には待たせない。
            if process.isRunning {
                process.terminate()
                return true
            }

            // lsof は該当するオープンファイルがある場合に 0 を返す。
            if process.terminationStatus == 0 {
                return true
            }
        }
        return false
    }

    private func errorMessage(from result: CommandResult) -> String {
        let stderr = String(decoding: result.stderr, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        let stdout = String(decoding: result.stdout, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return [stderr, stdout].first { !$0.isEmpty } ?? "diskutil の実行に失敗しました。"
    }

    private func isVolumeMounted(_ identifier: String) throws -> Bool {
        let result = try run(arguments: ["info", "-plist", identifier])
        // 取り出しによって識別子自体が消えていれば、未マウントとして扱う。
        guard result.status == 0 else { return false }
        return DiskInfoParser().mountPoint(from: result.stdout) != nil
    }

    private func run(arguments: [String]) throws -> CommandResult {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        return CommandResult(
            status: process.terminationStatus,
            stdout: stdout.fileHandleForReading.readDataToEndOfFile(),
            stderr: stderr.fileHandleForReading.readDataToEndOfFile()
        )
    }
}

private struct CommandResult {
    let status: Int32
    let stdout: Data
    let stderr: Data
}
