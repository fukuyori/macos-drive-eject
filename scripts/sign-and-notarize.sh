#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"

TEAM_ID="${TEAM_ID:-Q6GG27UYG5}"
NOTARY_PROFILE="${NOTARY_PROFILE:-notarytool}"
APPLICATION_SIGNING_IDENTITY="${APPLICATION_SIGNING_IDENTITY:-Developer ID Application: Noriaki Fukuyori ($TEAM_ID)}"
INSTALLER_SIGNING_IDENTITY="${INSTALLER_SIGNING_IDENTITY:-Developer ID Installer: Noriaki Fukuyori ($TEAM_ID)}"
CODE_SIGN_IDENTIFIER="${CODE_SIGN_IDENTIFIER:-com.fukuyori.eject}"
PACKAGE_IDENTIFIER="${PACKAGE_IDENTIFIER:-com.fukuyori.eject.pkg}"
NOTARY_TIMEOUT="${NOTARY_TIMEOUT:-30m}"
RELEASE_VERSION="0.1.1"
VERSION_WAS_SET=false
PREPARE_ONLY=false

usage() {
    echo "使用方法:"
    echo "  $0 [--prepare-only] [VERSION]"
    echo
    echo "例:"
    echo "  $0 0.1.1"
    echo "  $0 --prepare-only 0.1.1"
    echo
    echo "--prepare-only は署名とPKG作成まで行い、Appleへ提出しません。"
    echo
    echo "環境変数で既定値を変更できます:"
    echo "  TEAM_ID=$TEAM_ID"
    echo "  NOTARY_PROFILE=$NOTARY_PROFILE"
    echo "  APPLICATION_SIGNING_IDENTITY=$APPLICATION_SIGNING_IDENTITY"
    echo "  INSTALLER_SIGNING_IDENTITY=$INSTALLER_SIGNING_IDENTITY"
    echo "  CODE_SIGN_IDENTIFIER=$CODE_SIGN_IDENTIFIER"
    echo "  PACKAGE_IDENTIFIER=$PACKAGE_IDENTIFIER"
    echo "  NOTARY_TIMEOUT=$NOTARY_TIMEOUT"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prepare-only)
            PREPARE_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -* )
            echo "エラー: 不明なオプションです: $1" >&2
            usage >&2
            exit 2
            ;;
        *)
            if [[ "$VERSION_WAS_SET" == true ]]; then
                echo "エラー: VERSIONは1つだけ指定できます。" >&2
                exit 2
            fi
            RELEASE_VERSION="$1"
            VERSION_WAS_SET=true
            shift
            ;;
    esac
done

if [[ ! "$RELEASE_VERSION" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]; then
    echo "エラー: VERSIONに使用できない文字が含まれています: $RELEASE_VERSION" >&2
    exit 2
fi

ARCHITECTURE="$(/usr/bin/uname -m)"
ARTIFACT_NAME="eject-$RELEASE_VERSION-macos-$ARCHITECTURE"
FINAL_PKG="$DIST_DIR/$ARTIFACT_NAME.pkg"
PREPARED_PKG="$DIST_DIR/$ARTIFACT_NAME-prepared.pkg"
RESPONSE_FILE="$DIST_DIR/$ARTIFACT_NAME-notarization.plist"
LOG_FILE="$DIST_DIR/$ARTIFACT_NAME-notarization.json"

WORK_DIR="$(/usr/bin/mktemp -d "/tmp/eject-notarize.XXXXXX")"
cleanup() {
    if [[ -n "${WORK_DIR:-}" && "$WORK_DIR" == /tmp/eject-notarize.* ]]; then
        /bin/rm -rf -- "$WORK_DIR"
    fi
}
trap cleanup EXIT INT TERM

PAYLOAD_ROOT="$WORK_DIR/payload"
WORK_PKG="$WORK_DIR/$ARTIFACT_NAME.pkg"
WORK_RESPONSE="$WORK_DIR/notarization.plist"
SIGNED_EXECUTABLE="$DIST_DIR/eject"

echo "[1/8] 署名証明書と公証プロファイルを確認します"
if ! /usr/bin/security find-identity -v -p codesigning \
    | /usr/bin/grep -Fq "\"$APPLICATION_SIGNING_IDENTITY\""; then
    echo "エラー: Developer ID Application証明書が見つかりません。" >&2
    echo "必要な証明書: $APPLICATION_SIGNING_IDENTITY" >&2
    exit 1
fi

if ! /usr/bin/security find-identity -v -p basic \
    | /usr/bin/grep -Fq "\"$INSTALLER_SIGNING_IDENTITY\""; then
    echo "エラー: Developer ID Installer証明書が見つかりません。" >&2
    echo "必要な証明書: $INSTALLER_SIGNING_IDENTITY" >&2
    exit 1
fi

if [[ "$PREPARE_ONLY" == false ]]; then
    if ! /usr/bin/xcrun notarytool history \
        --keychain-profile "$NOTARY_PROFILE" \
        --output-format json >/dev/null; then
        echo "エラー: Keychainプロファイル '$NOTARY_PROFILE' を利用できません。" >&2
        exit 1
    fi
fi

echo "[2/8] Releaseビルドを作成します"
"$SCRIPT_DIR/build-release.sh"

echo "[3/8] 実行ファイルへDeveloper ID署名を行います"
/usr/bin/codesign \
    --force \
    --sign "$APPLICATION_SIGNING_IDENTITY" \
    --identifier "$CODE_SIGN_IDENTIFIER" \
    --options runtime \
    --timestamp \
    "$SIGNED_EXECUTABLE"

/usr/bin/codesign --verify --strict --verbose=2 "$SIGNED_EXECUTABLE"

echo "[4/8] /usr/local/bin/eject を配置するPKGを作成します"
/bin/mkdir -p "$PAYLOAD_ROOT/usr/local/bin"
/usr/bin/install -m 755 "$SIGNED_EXECUTABLE" "$PAYLOAD_ROOT/usr/local/bin/eject"

/usr/bin/pkgbuild \
    --root "$PAYLOAD_ROOT" \
    --install-location / \
    --identifier "$PACKAGE_IDENTIFIER" \
    --version "$RELEASE_VERSION" \
    --ownership recommended \
    --sign "$INSTALLER_SIGNING_IDENTITY" \
    "$WORK_PKG"

echo "[5/8] PKGの署名とインストール先を検証します"
/usr/sbin/pkgutil --check-signature "$WORK_PKG"
if ! /usr/sbin/pkgutil --payload-files "$WORK_PKG" \
    | /usr/bin/grep -Fxq './usr/local/bin/eject'; then
    echo "エラー: PKG内に /usr/local/bin/eject がありません。" >&2
    exit 1
fi

if [[ "$PREPARE_ONLY" == true ]]; then
    /usr/bin/install -m 644 "$WORK_PKG" "$PREPARED_PKG"
    echo "[6/8] --prepare-only のためAppleへの提出を省略しました"
    echo "署名済み提出前PKG: $PREPARED_PKG"
    exit 0
fi

echo "[6/8] Appleの公証サービスへ提出し、完了を待ちます"
set +e
/usr/bin/xcrun notarytool submit "$WORK_PKG" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait \
    --timeout "$NOTARY_TIMEOUT" \
    --output-format plist \
    > "$WORK_RESPONSE"
NOTARY_EXIT_CODE=$?
set -e

/usr/bin/install -m 644 "$WORK_RESPONSE" "$RESPONSE_FILE"
SUBMISSION_ID="$(/usr/libexec/PlistBuddy -c 'Print :id' "$WORK_RESPONSE" 2>/dev/null || true)"
NOTARY_STATUS="$(/usr/libexec/PlistBuddy -c 'Print :status' "$WORK_RESPONSE" 2>/dev/null || true)"

if [[ -n "$SUBMISSION_ID" ]]; then
    if ! /usr/bin/xcrun notarytool log "$SUBMISSION_ID" \
        --keychain-profile "$NOTARY_PROFILE" \
        "$LOG_FILE"; then
        echo "警告: 公証ログを取得できませんでした。" >&2
    fi
fi

if [[ $NOTARY_EXIT_CODE -ne 0 || "$NOTARY_STATUS" != "Accepted" ]]; then
    echo "エラー: 公証が承認されませんでした。status=${NOTARY_STATUS:-不明}" >&2
    echo "応答: $RESPONSE_FILE" >&2
    [[ -f "$LOG_FILE" ]] && echo "ログ: $LOG_FILE" >&2
    exit 1
fi

echo "[7/8] 公証チケットをPKGへ添付します"
/usr/bin/xcrun stapler staple "$WORK_PKG"
/usr/bin/xcrun stapler validate "$WORK_PKG"

echo "[8/8] 最終成果物を検証して配置します"
/usr/sbin/spctl --assess \
    --type install \
    --verbose=2 \
    "$WORK_PKG"
/usr/sbin/pkgutil --check-signature "$WORK_PKG"
/usr/bin/install -m 644 "$WORK_PKG" "$FINAL_PKG"

echo
echo "署名・公証が完了しました。"
echo "提出ID:     $SUBMISSION_ID"
echo "配布用PKG:  $FINAL_PKG"
echo "公証応答:   $RESPONSE_FILE"
[[ -f "$LOG_FILE" ]] && echo "公証ログ:   $LOG_FILE"
