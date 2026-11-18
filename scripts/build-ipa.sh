#!/usr/bin/env bash
# 在 macOS 上生成未签名 IPA： ./scripts/build-ipa.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/CodeArtsMobile"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "未找到 xcodegen，正在通过 Homebrew 安装..."
  brew install xcodegen
fi

echo "==> 生成 Xcode 工程"
xcodegen generate

echo "==> 编译 Release（不签名）"
xcodebuild \
  -project CodeArtsMobile.xcodeproj \
  -scheme CodeArtsMobile \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  -quiet \
  build

APP_PATH="$(find build/Build/Products/Release-iphoneos -maxdepth 1 -name '*.app' -print -quit)"
if [[ -z "$APP_PATH" ]]; then
  echo "错误：未找到 .app 产物" >&2
  exit 1
fi

echo "==> 打包 Payload"
rm -rf Payload CodeArtsMobile-unsigned.ipa
mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -qry CodeArtsMobile-unsigned.ipa Payload

echo "==> 完成"
ls -lh CodeArtsMobile-unsigned.ipa
shasum -a 256 CodeArtsMobile-unsigned.ipa
echo
echo "产物：$ROOT/CodeArtsMobile/CodeArtsMobile-unsigned.ipa"
echo "安装：用 AltStore / Sideloadly 以你自己的 Apple ID 自签后再装到 iPhone。"