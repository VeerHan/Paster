#!/usr/bin/env bash
# Paster 发布打包脚本：构建 Universal Binary + 生成 DMG
set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"
BUILD_DIR="$ROOT/build"
DIST_DIR="$ROOT/dist"
SCHEME="macPaste"
APP_NAME="Paster"
VERSION=$(grep -m1 "MARKETING_VERSION" Paster.xcodeproj/project.pbxproj | sed 's/.*= //;s/;//;s/ *$//' || echo "1.0.0")
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_VOLUME_NAME="${APP_NAME} ${VERSION}"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# ── 1. 构建 Universal Binary (arm64 + x86_64) ──
echo "→ 构建 arm64..."
xcodebuild -scheme "$SCHEME" -configuration Release \
  -derivedDataPath "${BUILD_DIR}-arm64" \
  -arch arm64 \
  ONLY_ACTIVE_ARCH=NO \
  clean build -quiet

echo "→ 构建 x86_64..."
xcodebuild -scheme "$SCHEME" -configuration Release \
  -derivedDataPath "${BUILD_DIR}-x86_64" \
  -arch x86_64 \
  ONLY_ACTIVE_ARCH=NO \
  clean build -quiet

ARM_APP="${BUILD_DIR}-arm64/Build/Products/Release/${APP_NAME}.app"
X86_APP="${BUILD_DIR}-x86_64/Build/Products/Release/${APP_NAME}.app"
ARM_BIN="${ARM_APP}/Contents/MacOS/${APP_NAME}"
X86_BIN="${X86_APP}/Contents/MacOS/${APP_NAME}"

echo "→ 合并为 Universal Binary..."
cp -R "$ARM_APP" "$DIST_DIR/"
lipo -create "$ARM_BIN" "$X86_BIN" -output "$DIST_DIR/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

echo "→ 验证架构..."
file "$DIST_DIR/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

# ── 2. 创建 DMG ──
echo "→ 创建 DMG..."
DMG_TEMP="$DIST_DIR/temp.dmg"
DMG_FINAL="$DIST_DIR/$DMG_NAME"

# 创建临时可写 DMG
hdiutil create -srcfolder "$DIST_DIR/${APP_NAME}.app" \
  -volname "$DMG_VOLUME_NAME" \
  -fs HFS+ \
  -format UDRW \
  -size 200m \
  "$DMG_TEMP" -quiet

# 挂载临时 DMG 并添加 Applications 快捷方式
MOUNT_DIR=$(hdiutil attach "$DMG_TEMP" -readwrite -noverify -noautoopen | grep "/Volumes/" | tail -1 | awk -F'\t' '{print $NF}')
ln -s /Applications "$MOUNT_DIR/Applications"

# 设置 DMG 窗口样式（Finder 打开后的外观）
echo '
   tell application "Finder"
     tell disk "'"$DMG_VOLUME_NAME"'"
       open
       set current view of container window to icon view
       set toolbar visible of container window to false
       set statusbar visible of container window to false
       set the bounds of container window to {400, 150, 900, 430}
       set viewOptions to the icon view options of container window
       set arrangement of viewOptions to not arranged
       set icon size of viewOptions to 80
       set position of item "'"$APP_NAME"'.app" of container window to {120, 130}
       set position of item "Applications" of container window to {380, 130}
       close
       open
       update without registering applications
       delay 1
       close
     end tell
   end tell
' | osascript || true

# 卸载
hdiutil detach "$MOUNT_DIR" -quiet

# 压缩为最终只读 DMG
hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL" -quiet
rm -f "$DMG_TEMP"

# 清理中间构建目录
rm -rf "${BUILD_DIR}-arm64" "${BUILD_DIR}-x86_64"

echo ""
echo "══════════════════════════════════════════"
echo "  打包完成！"
echo "══════════════════════════════════════════"
echo ""
echo "  DMG:  $DMG_FINAL"
echo "  大小: $(du -h "$DMG_FINAL" | cut -f1)"
echo ""
echo "  支持系统: macOS 13.0 (Ventura) 及以上"
echo "  支持芯片: Apple Silicon (M1/M2/M3/M4) + Intel"
echo ""
echo "  发给对方后，双击 DMG → 把 Paster 拖到 Applications 即可。"
echo "══════════════════════════════════════════"
