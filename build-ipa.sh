#!/bin/bash
# macOS 上一键出未签名 ipa
set -e
cd "$(dirname "$0")"

command -v xcodegen >/dev/null 2>&1 || { echo "安装 xcodegen…"; brew install xcodegen; }

xcodegen generate
xcodebuild -project oz.xcodeproj -scheme oz \
  -sdk iphoneos -configuration Release \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  -derivedDataPath build | tail -20

rm -rf Payload oz-unsigned.ipa
mkdir Payload
cp -R build/Build/Products/Release-iphoneos/oz.app Payload/
zip -qry oz-unsigned.ipa Payload

echo
echo "✅ 生成 oz-unsigned.ipa  $(du -h oz-unsigned.ipa | cut -f1)"
echo "下一步：用 Sideloadly / 爱思助手 / AltStore 签名安装（需要 Apple ID）"
