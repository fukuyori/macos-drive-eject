import Foundation

public enum AppLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case japanese = "ja"
    case chinese = "zh"
    case spanish = "es"
    case french = "fr"

    public static var current: AppLanguage {
        detect()
    }

    public static func detect(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> AppLanguage {
        if let override = environment["EJECT_LANG"],
           let language = language(from: override) {
            return language
        }

        for identifier in preferredLanguages {
            if let language = language(from: identifier) {
                return language
            }
        }

        for key in ["LC_ALL", "LC_MESSAGES", "LANG"] {
            if let identifier = environment[key],
               let language = language(from: identifier) {
                return language
            }
        }
        return .english
    }

    private static func language(from identifier: String) -> AppLanguage? {
        let normalized = identifier
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
        return allCases.first { language in
            normalized == language.rawValue || normalized.hasPrefix(language.rawValue + "-")
        }
    }
}

public struct LocalizedText: Sendable {
    public let language: AppLanguage

    public init(language: AppLanguage = .current) {
        self.language = language
    }

    public var help: String {
        switch language {
        case .english:
            return """
            Usage:
              eject                    Open the interactive interface
              eject --list | -l        List mounted external drives
              eject --eject <disk>     Eject the specified drive
              eject -e <disk>          Same as above
              eject --help | -h        Show this help

            Specify <disk> as an identifier such as disk4 or /dev/disk4.
            """
        case .japanese:
            return """
            使用方法:
              eject                    対話画面を開く
              eject --list | -l        外部ドライブの一覧を表示
              eject --eject <disk>     指定したドライブを取り出す
              eject -e <disk>          同上
              eject --help | -h        このヘルプを表示

            <disk> には disk4 または /dev/disk4 のような識別子を指定します。
            """
        case .chinese:
            return """
            用法:
              eject                    打开交互界面
              eject --list | -l        列出已挂载的外部驱动器
              eject --eject <disk>     弹出指定的驱动器
              eject -e <disk>          同上
              eject --help | -h        显示此帮助

            <disk> 请指定为 disk4 或 /dev/disk4 等标识符。
            """
        case .spanish:
            return """
            Uso:
              eject                    Abrir la interfaz interactiva
              eject --list | -l        Mostrar unidades externas montadas
              eject --eject <disk>     Expulsar la unidad especificada
              eject -e <disk>          Igual que la opción anterior
              eject --help | -h        Mostrar esta ayuda

            Especifique <disk> con un identificador como disk4 o /dev/disk4.
            """
        case .french:
            return """
            Utilisation :
              eject                    Ouvrir l’interface interactive
              eject --list | -l        Lister les disques externes montés
              eject --eject <disk>     Éjecter le disque indiqué
              eject -e <disk>          Identique à l’option précédente
              eject --help | -h        Afficher cette aide

            Indiquez <disk> avec un identifiant tel que disk4 ou /dev/disk4.
            """
        }
    }

    public var noMountedDrives: String {
        switch language {
        case .english: "No external drives are mounted."
        case .japanese: "マウントされている外部ドライブはありません。"
        case .chinese: "没有已挂载的外部驱动器。"
        case .spanish: "No hay unidades externas montadas."
        case .french: "Aucun disque externe n’est monté."
        }
    }

    public var title: String {
        switch language {
        case .english: "Eject External Drive"
        case .japanese: "外部ドライブの取り出し"
        case .chinese: "弹出外部驱动器"
        case .spanish: "Expulsar unidad externa"
        case .french: "Éjecter un disque externe"
        }
    }

    public var controls: String {
        switch language {
        case .english: "↑/↓ Select   Enter Eject   Esc Quit"
        case .japanese: "↑/↓ 選択   Enter 取り出し   Esc 終了"
        case .chinese: "↑/↓ 选择   Enter 弹出   Esc 退出"
        case .spanish: "↑/↓ Seleccionar   Enter Expulsar   Esc Salir"
        case .french: "↑/↓ Sélectionner   Entrée Éjecter   Échap Quitter"
        }
    }

    public var inUseLabel: String {
        switch language {
        case .english: "In use"
        case .japanese: "使用中"
        case .chinese: "使用中"
        case .spanish: "En uso"
        case .french: "Utilisé"
        }
    }

    public var notInUseLabel: String {
        switch language {
        case .english: "Not in use"
        case .japanese: "未使用"
        case .chinese: "未使用"
        case .spanish: "Sin uso"
        case .french: "Non utilisé"
        }
    }

    public var errorPrefix: String {
        switch language {
        case .english: "Error"
        case .japanese: "エラー"
        case .chinese: "错误"
        case .spanish: "Error"
        case .french: "Erreur"
        }
    }

    public var ejectionFailedPrefix: String {
        switch language {
        case .english: "Ejection failed"
        case .japanese: "取り出し失敗"
        case .chinese: "弹出失败"
        case .spanish: "Error al expulsar"
        case .french: "Échec de l’éjection"
        }
    }

    public var runHelp: String {
        switch language {
        case .english: "Run eject --help for more information."
        case .japanese: "詳しくは eject --help を実行してください。"
        case .chinese: "请运行 eject --help 查看详细信息。"
        case .spanish: "Ejecute eject --help para obtener más información."
        case .french: "Exécutez eject --help pour plus d’informations."
        }
    }

    public func ejected(name: String, path: String? = nil) -> String {
        let target = path.map { "\(name) (\($0))" } ?? name
        switch language {
        case .english: return "Ejected \(target)."
        case .japanese: return "\(target) を取り出しました。"
        case .chinese: return "已弹出 \(target)。"
        case .spanish: return "Se expulsó \(target)."
        case .french: return "\(target) a été éjecté."
        }
    }

    public func ejecting(name: String) -> String {
        switch language {
        case .english: return "Ejecting \(name)…"
        case .japanese: return "\(name) を取り出しています…"
        case .chinese: return "正在弹出 \(name)…"
        case .spanish: return "Expulsando \(name)…"
        case .french: return "Éjection de \(name)…"
        }
    }

    public func driveInUse(_ name: String) -> String {
        switch language {
        case .english: return "\(name) is in use. Close any files or apps using it and try again."
        case .japanese: return "\(name) は使用中です。ファイルやアプリを閉じてから再試行してください。"
        case .chinese: return "\(name) 正在使用中。请关闭相关文件或应用后重试。"
        case .spanish: return "\(name) está en uso. Cierre los archivos o las aplicaciones que lo utilicen e inténtelo de nuevo."
        case .french: return "\(name) est utilisé. Fermez les fichiers ou applications concernés, puis réessayez."
        }
    }

    public func driveNotFound(_ target: String) -> String {
        switch language {
        case .english: return "External drive \"\(target)\" was not found. Use --list to check its identifier."
        case .japanese: return "外部ドライブ \"\(target)\" が見つかりません。--list で識別子を確認してください。"
        case .chinese: return "找不到外部驱动器“\(target)”。请使用 --list 检查标识符。"
        case .spanish: return "No se encontró la unidad externa \"\(target)\". Use --list para comprobar su identificador."
        case .french: return "Le disque externe « \(target) » est introuvable. Utilisez --list pour vérifier son identifiant."
        }
    }

    public func unknownOption(_ option: String) -> String {
        switch language {
        case .english: return "Unknown option: \(option)"
        case .japanese: return "不明なオプションです: \(option)"
        case .chinese: return "未知选项：\(option)"
        case .spanish: return "Opción desconocida: \(option)"
        case .french: return "Option inconnue : \(option)"
        }
    }

    public var missingEjectTarget: String {
        switch language {
        case .english: "Specify a drive identifier after --eject or -e."
        case .japanese: "--eject または -e の後にドライブ識別子を指定してください。"
        case .chinese: "请在 --eject 或 -e 后指定驱动器标识符。"
        case .spanish: "Especifique un identificador de unidad después de --eject o -e."
        case .french: "Indiquez un identifiant de disque après --eject ou -e."
        }
    }

    public var unexpectedArguments: String {
        switch language {
        case .english: "Some arguments cannot be used together."
        case .japanese: "同時に指定できない引数が含まれています。"
        case .chinese: "包含不能同时使用的参数。"
        case .spanish: "Algunos argumentos no se pueden usar juntos."
        case .french: "Certains arguments ne peuvent pas être utilisés ensemble."
        }
    }

    public var terminalNotInteractive: String {
        switch language {
        case .english: "Run this command from an interactive terminal."
        case .japanese: "対話型のターミナルから起動してください。"
        case .chinese: "请从交互式终端运行此命令。"
        case .spanish: "Ejecute este comando desde un terminal interactivo."
        case .french: "Exécutez cette commande depuis un terminal interactif."
        }
    }

    public var terminalReadFailed: String {
        switch language {
        case .english: "Unable to read the terminal settings."
        case .japanese: "ターミナル設定を読み取れませんでした。"
        case .chinese: "无法读取终端设置。"
        case .spanish: "No se pudo leer la configuración del terminal."
        case .french: "Impossible de lire les réglages du terminal."
        }
    }

    public var terminalRawModeFailed: String {
        switch language {
        case .english: "Unable to enable terminal key input mode."
        case .japanese: "ターミナルをキー入力モードへ切り替えられませんでした。"
        case .chinese: "无法启用终端按键输入模式。"
        case .spanish: "No se pudo activar el modo de entrada de teclas del terminal."
        case .french: "Impossible d’activer le mode de saisie clavier du terminal."
        }
    }

    public func invalidDriveIdentifier(_ identifier: String) -> String {
        switch language {
        case .english: return "Invalid drive identifier: \(identifier)"
        case .japanese: return "不正なドライブ識別子です: \(identifier)"
        case .chinese: return "驱动器标识符无效：\(identifier)"
        case .spanish: return "Identificador de unidad no válido: \(identifier)"
        case .french: return "Identifiant de disque non valide : \(identifier)"
        }
    }

    public func ejectionCouldNotBeVerified(_ identifier: String) -> String {
        switch language {
        case .english:
            return "The eject command completed, but not all volumes on \(identifier) were confirmed as unmounted within 10 seconds. Do not physically disconnect it until it is safe."
        case .japanese:
            return "取り出しコマンドは完了しましたが、\(identifier) の全ボリュームがアンマウントされたことを10秒以内に確認できませんでした。安全を確認するまで物理的に取り外さないでください。"
        case .chinese:
            return "弹出命令已完成，但无法在10秒内确认 \(identifier) 的所有卷均已卸载。确认安全之前，请勿断开物理连接。"
        case .spanish:
            return "El comando de expulsión terminó, pero no se pudo confirmar en 10 segundos que todos los volúmenes de \(identifier) estuvieran desmontados. No lo desconecte físicamente hasta que sea seguro."
        case .french:
            return "La commande d’éjection est terminée, mais le démontage de tous les volumes de \(identifier) n’a pas pu être confirmé dans les 10 secondes. Ne le débranchez pas physiquement avant de vous être assuré que cela est sans danger."
        }
    }

    public var diskutilFailed: String {
        switch language {
        case .english: "diskutil failed."
        case .japanese: "diskutil の実行に失敗しました。"
        case .chinese: "diskutil 执行失败。"
        case .spanish: "La ejecución de diskutil falló."
        case .french: "L’exécution de diskutil a échoué."
        }
    }

    public var diskListParsingFailed: String {
        switch language {
        case .english: "Unable to parse the drive information returned by diskutil."
        case .japanese: "diskutil から受け取ったドライブ情報を解析できませんでした。"
        case .chinese: "无法解析 diskutil 返回的驱动器信息。"
        case .spanish: "No se pudo analizar la información de las unidades devuelta por diskutil."
        case .french: "Impossible d’analyser les informations de disque renvoyées par diskutil."
        }
    }
}
