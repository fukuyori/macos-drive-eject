# eject

English | [日本語](README.ja.md)

`eject` is a terminal application for safely ejecting external drives on macOS. It provides an interactive drive selector as well as commands suitable for shell scripts.

## Requirements

- macOS 13 or later
- Swift 6 via Xcode or the Command Line Tools

## Interactive mode

Run the application without arguments:

```sh
swift run eject
```

Controls:

- `↑` / `↓`: Select a drive
- `Enter`: Eject the selected drive
- `Esc`: Quit

The drive list refreshes automatically, so drives connected, mounted, disconnected, or unmounted after launch are reflected in the interface. Columns remain aligned when multiple drives are shown. Drives marked as in use cannot be selected or highlighted, and arrow-key navigation skips them. If every drive is in use, no row is highlighted. If no mounted external drive exists at launch, or if every drive later becomes unmounted, the application prints `マウントされている外部ドライブはありません。` and exits. This also applies after the last drive is successfully ejected.

## Command-line usage

```sh
# Show help
eject --help
eject -h

# List mounted external drives
eject --list
eject -l

# Eject a drive by its diskutil identifier
eject --eject disk4
eject -e /dev/disk4
```

Running `eject` without arguments opens the interactive interface. Use `--list` or `-l` to find the identifier of a drive.

## Languages

Messages automatically follow the preferred language configured in macOS. English, Japanese, Simplified Chinese, Spanish, and French are supported. Unsupported languages fall back to English.

To select a language explicitly for a single command, set `EJECT_LANG`:

```sh
EJECT_LANG=en eject --help
EJECT_LANG=ja eject --list
EJECT_LANG=zh eject --list
EJECT_LANG=es eject --help
EJECT_LANG=fr eject --help
```

## How drive detection and ejection work

The application starts with the physical external drives returned by `diskutil list external physical`, then shows only drives with at least one normally mounted volume. A drive that has already been ejected is not shown even if its cable and physical controller remain connected.

Each drive is marked as either `[使用中]` (in use) or `[未使用]` (not in use). The application uses `lsof` to detect processes with open files on its mounted volumes. If a drive is in use, ejection is stopped and the user is asked to close the relevant files or applications.

Ejection is performed against the whole drive with `diskutil eject`. The application does not use forced ejection. After the command succeeds, it waits up to 10 seconds for every volume belonging to the drive to become unmounted. If this cannot be verified, the operation is not reported as successful and the user is warned not to disconnect the drive physically.

## Release build

Create an unsigned release executable:

```sh
./scripts/build-release.sh
./dist/eject --help
```

The executable is written to `dist/eject`.

## Code signing and notarization

If the Developer ID Application certificate, Developer ID Installer certificate, and `notarytool` Keychain profile are configured, run:

```sh
./scripts/sign-and-notarize.sh 0.2.0
```

The script performs the release build, signs the executable, creates and signs a PKG installer, submits it to Apple's notary service, waits for acceptance, downloads the notarization log, staples the ticket, and performs final Gatekeeper validation.

To create and validate a signed PKG without submitting it to Apple:

```sh
./scripts/sign-and-notarize.sh --prepare-only 0.2.0
```

Default signing configuration:

- Team ID: `Q6GG27UYG5`
- Application identity: `Developer ID Application: Noriaki Fukuyori (Q6GG27UYG5)`
- Installer identity: `Developer ID Installer: Noriaki Fukuyori (Q6GG27UYG5)`
- Keychain profile: `notarytool`
- Code-signing identifier: `com.fukuyori.eject`
- Package identifier: `com.fukuyori.eject.pkg`

The PKG installs the executable at `/usr/local/bin/eject`. Credentials and passwords are never stored in the script or its artifacts. The notarized package is written to `dist/eject-<version>-macos-<architecture>.pkg`.
