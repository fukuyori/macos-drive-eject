#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/dist"
OUTPUT_FILE="$OUTPUT_DIR/eject"

echo "[1/4] Releaseビルドを開始します"
cd "$PROJECT_DIR"
/usr/bin/env swift build -c release

echo "[2/4] 実行ファイルを配置します"
BIN_DIR="$(/usr/bin/env swift build -c release --show-bin-path)"
/bin/mkdir -p "$OUTPUT_DIR"
/usr/bin/install -m 755 "$BIN_DIR/eject" "$OUTPUT_FILE"

echo "[3/4] 実行ファイルを確認します"
/bin/test -x "$OUTPUT_FILE"
"$OUTPUT_FILE" --help >/dev/null

echo "[4/4] ビルドが完了しました"
/usr/bin/file "$OUTPUT_FILE"
echo "実行ファイル: $OUTPUT_FILE"
echo "実行方法:     $OUTPUT_FILE"
