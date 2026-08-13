import Testing
@testable import EjectCore

struct LocalizationTests {
    @Test(arguments: [
        ("en", AppLanguage.english),
        ("ja-JP", AppLanguage.japanese),
        ("zh_CN.UTF-8", AppLanguage.chinese),
        ("es-ES", AppLanguage.spanish),
        ("fr_FR", AppLanguage.french),
    ])
    func explicitLanguageOverride(identifier: String, expected: AppLanguage) {
        #expect(AppLanguage.detect(
            environment: ["EJECT_LANG": identifier],
            preferredLanguages: ["de-DE"]
        ) == expected)
    }

    @Test func followsMacOSPreferredLanguage() {
        #expect(AppLanguage.detect(
            environment: [:],
            preferredLanguages: ["fr-FR", "en-US"]
        ) == .french)
    }

    @Test func unsupportedLanguageFallsBackToEnglish() {
        #expect(AppLanguage.detect(
            environment: [:],
            preferredLanguages: ["de-DE"]
        ) == .english)
    }

    @Test func providesNoDriveMessageInEverySupportedLanguage() {
        #expect(LocalizedText(language: .english).noMountedDrives == "No external drives are mounted.")
        #expect(LocalizedText(language: .japanese).noMountedDrives == "マウントされている外部ドライブはありません。")
        #expect(LocalizedText(language: .chinese).noMountedDrives == "没有已挂载的外部驱动器。")
        #expect(LocalizedText(language: .spanish).noMountedDrives == "No hay unidades externas montadas.")
        #expect(LocalizedText(language: .french).noMountedDrives == "Aucun disque externe n’est monté.")
    }

    @Test func everyLanguageHasHelpAndStatusLabels() {
        for language in AppLanguage.allCases {
            let text = LocalizedText(language: language)
            #expect(text.help.contains("--eject"))
            #expect(!text.inUseLabel.isEmpty)
            #expect(!text.notInUseLabel.isEmpty)
            #expect(!text.controls.isEmpty)
        }
    }
}
