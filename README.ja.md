# eject

[English](README.md) | 日本語

`eject` は、macOSのターミナル上で外部ドライブを安全に取り出すためのアプリケーションです。対話形式のドライブ選択画面に加え、シェルスクリプトから利用できるコマンドも提供します。

## 必要環境

- macOS 13以降
- XcodeまたはCommand Line Toolsに含まれるSwift 6

## 対話モード

引数を付けずに実行します。

```sh
swift run eject
```

操作方法：

- `↑` / `↓`：ドライブを選択
- `Enter`：選択中のドライブを取り出す
- `Esc`：終了

ドライブ一覧は自動的に更新されるため、起動後の接続、マウント、切断、アンマウントも画面へ反映されます。複数ドライブがある場合は各項目を列ごとに揃えて表示します。最後のドライブを正常に取り出すと、アプリケーションは自動的に終了します。

## コマンドライン操作

```sh
# ヘルプを表示
eject --help
eject -h

# マウント中の外部ドライブを一覧表示
eject --list
eject -l

# diskutilの識別子を指定して取り出す
eject --eject disk4
eject -e /dev/disk4
```

引数を付けずに `eject` を実行すると対話画面を開きます。対象ドライブの識別子は `--list` または `-l` で確認できます。

## ドライブ検出と取り出しの仕組み

`diskutil list external physical` が返す外部物理ドライブから、少なくとも1つの通常ボリュームがマウントされているドライブだけを表示します。取り出し済みのドライブは、ケーブルや物理コントローラーが接続されたままでも表示しません。

各ドライブには `使用中` または `未使用` を表示します。マウントされたボリューム上のファイルを開いているプロセスがあるか、`lsof` で確認します。使用中の場合は取り出しを中止し、ファイルやアプリケーションを閉じるよう案内します。

取り出しはドライブ全体に対して `diskutil eject` を実行します。強制取り出しは使用しません。コマンドの成功後は、対象ドライブに属する全ボリュームがアンマウントされたことを最大10秒確認します。確認できない場合は成功扱いにせず、安全を確認するまで物理的に取り外さないよう警告します。

## Releaseビルド

未署名のRelease実行ファイルを作成します。

```sh
./scripts/build-release.sh
./dist/eject --help
```

実行ファイルは `dist/eject` に作成されます。

## 電子署名と公証

Developer ID Application証明書、Developer ID Installer証明書、`notarytool` のKeychainプロファイルを設定済みの場合は、次を実行します。

```sh
./scripts/sign-and-notarize.sh 0.1.0
```

Releaseビルド、実行ファイルの署名、PKGの作成と署名、Appleへの提出、公証完了待ち、公証ログ取得、チケット添付、Gatekeeperによる最終検証まで行います。

Appleへ提出せず、署名済みPKGの作成と検証だけを行う場合：

```sh
./scripts/sign-and-notarize.sh --prepare-only 0.1.0
```

既定の署名設定：

- Team ID：`Q6GG27UYG5`
- Application署名：`Developer ID Application: Noriaki Fukuyori (Q6GG27UYG5)`
- Installer署名：`Developer ID Installer: Noriaki Fukuyori (Q6GG27UYG5)`
- Keychainプロファイル：`notarytool`
- 署名識別子：`com.fukuyori.eject`
- PKG識別子：`com.fukuyori.eject.pkg`

PKGは実行ファイルを `/usr/local/bin/eject` にインストールします。認証情報やパスワードはスクリプトや成果物へ保存しません。公証済みPKGは `dist/eject-<version>-macos-<architecture>.pkg` に作成されます。
