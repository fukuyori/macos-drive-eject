# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-08-18

### Fixed

- Hid unmounted partitions and APFS helper volumes such as Preboot, Recovery, Update, and VM from drive display names.
- Collapsed paired macOS System/Data volumes to the user-facing System volume name, preventing long rows and wrapped highlights.

### Changed

- Updated the default release and PKG version to `0.2.1`.

## [0.2.0] - 2026-08-18

### Changed

- Prevented drives marked as in use from being selected or highlighted.
- Updated arrow-key navigation to skip drives that are in use and wrap between selectable drives.
- Removed the highlight when every mounted drive is in use.
- Updated the default release and PKG version to `0.2.0`.

### Added

- Added selection-navigation tests for mixed and all-in-use drive lists.

## [0.1.1] - 2026-08-13

### Added

- Added automatic message localization based on the preferred macOS language.
- Added English, Japanese, Simplified Chinese, Spanish, and French translations for the interactive interface, command-line help, statuses, warnings, and errors.
- Added the `EJECT_LANG` environment variable for explicitly selecting a language.
- Added localization and language-detection tests.

### Changed

- Localized the in-use and not-in-use labels while preserving terminal column alignment.
- Updated the default release and PKG version to `0.1.1`.

## [0.1.0] - 2026-08-13

### Added

- Added an interactive terminal interface with arrow-key selection, Enter-to-eject, and Escape-to-quit controls.
- Added automatic refresh when external drives are mounted, unmounted, connected, or disconnected.
- Added aligned columns for drive names, usage status, capacity, and device identifiers.
- Added external physical-drive detection through `diskutil`, including APFS volume and physical-device name resolution.
- Added open-file detection with `lsof` and conservative handling when usage cannot be determined.
- Added safe whole-drive ejection without forced unmounting and post-ejection unmount verification.
- Added automatic exit when no mounted external drives remain.
- Added `--help`/`-h`, `--list`/`-l`, and `--eject`/`-e` command-line options.
- Added release-build automation that creates `dist/eject`.
- Added Developer ID signing, PKG generation, notarization submission, ticket stapling, and Gatekeeper validation automation.
- Added English and Japanese documentation.
- Added unit tests for disk parsing, APFS mapping, drive formatting, command-line parsing, and ejection verification.

[Unreleased]: https://github.com/fukuyori/macos-drive-eject/compare/0.2.1...HEAD
[0.2.1]: https://github.com/fukuyori/macos-drive-eject/compare/ac8abc7...0.2.1
[0.2.0]: https://github.com/fukuyori/macos-drive-eject/compare/541fbf6...ac8abc7
[0.1.1]: https://github.com/fukuyori/macos-drive-eject/compare/1fbf7b4...541fbf6
[0.1.0]: https://github.com/fukuyori/macos-drive-eject/commits/1fbf7b4
