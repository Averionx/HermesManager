#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
DMG_ROOT="$DIST_DIR/dmg-root"
APP_NAME="HermesManager"
VOLUME_NAME="HermesManager Installer"
APP_BUNDLE="$APP_NAME.app"
FINAL_DMG="$DIST_DIR/HermesManager-macOS.dmg"
BUILD_ROOT="/tmp/hermesmanager-spm-build"
BACKGROUND_DIR="$DMG_ROOT/.background"
BACKGROUND_PNG="$BACKGROUND_DIR/hermesmanager-dmg-background.png"
BACKGROUND_TIFF="$BACKGROUND_DIR/hermesmanager-dmg-background.tiff"
PROJECT_BACKGROUND="$ROOT_DIR/docs/assets/dmg-background.tiff"
APP_ICON="$ROOT_DIR/HermesManager.app/Contents/Resources/AppIcon.icns"
DMGBUILD_PYTHON="$ROOT_DIR/.build/dmgbuild-venv/bin/python"

cd "$ROOT_DIR"

detach_existing_installer_volumes() {
  while IFS= read -r line; do
    local mount_path
    mount_path="$(printf '%s\n' "$line" | awk 'index($0, "/Volumes/HermesManager Installer") {idx=index($0, "/Volumes/HermesManager Installer"); print substr($0, idx)}')"
    if [[ -n "${mount_path:-}" ]]; then
      hdiutil detach "$mount_path" -quiet || true
    fi
  done < <(hdiutil info)
}

refuse_private_payload() {
  local target="$1"

  if find "$target" -path "*/.hermes/*" -o -path "*/.openhuman/*" -o -path "*/.openclaw/*" | grep -q .; then
    echo "Refusing to package: private Hermes/OpenHuman/OpenClaw data was found in $target" >&2
    exit 1
  fi

  if find "$target" -name "local-secrets.js" | grep -q .; then
    echo "Refusing to package: local version-console secrets were found in $target" >&2
    exit 1
  fi

  while IFS= read -r -d '' file; do
    if strings "$file" 2>/dev/null | grep -E "$HOME|/Users/[^/]+/(Desktop|Documents|Downloads)|github_pat_|ghp_[A-Za-z0-9_]+|local-secrets|OPENAI_API_KEY|ANTHROPIC_API_KEY|GITHUB_TOKEN" >/dev/null; then
      echo "Refusing to package: private local data was found in $file" >&2
      exit 1
    fi
  done < <(find "$target" -type f -print0)
}

clean_bundle_metadata() {
  local target="$1"

  find "$target" \( -name ".DS_Store" -o -name "._*" \) -delete
  dot_clean -m "$target" >/dev/null 2>&1 || true
  xattr -cr "$target" >/dev/null 2>&1 || true
  find "$target" -exec xattr -d com.apple.FinderInfo {} \; >/dev/null 2>&1 || true
  find "$target" -exec xattr -d com.apple.fileprovider.fpfs#P {} \; >/dev/null 2>&1 || true
}

copy_dmg_background() {
  local source="$1"
  local destination="$2"

  python3 - "$source" "$destination" <<'PY'
import shutil
import sys

shutil.copyfile(sys.argv[1], sys.argv[2])
PY
}

detach_existing_installer_volumes

rm -rf "$BUILD_ROOT"
swift build -c release --scratch-path "$BUILD_ROOT" \
  -Xswiftc -file-prefix-map -Xswiftc "$ROOT_DIR=HermesManager" \
  -Xswiftc -debug-prefix-map -Xswiftc "$ROOT_DIR=HermesManager" \
  -Xswiftc -file-prefix-map -Xswiftc "$BUILD_ROOT=HermesManagerBuild" \
  -Xswiftc -debug-prefix-map -Xswiftc "$BUILD_ROOT=HermesManagerBuild"
BUILD_BIN_DIR="$(swift build -c release --scratch-path "$BUILD_ROOT" --show-bin-path)"

rm -rf "$DIST_DIR"
mkdir -p "$DMG_ROOT/$APP_BUNDLE/Contents/MacOS" "$DMG_ROOT/$APP_BUNDLE/Contents/Resources" "$BACKGROUND_DIR"

cp "$ROOT_DIR/HermesManager.app/Contents/Info.plist" "$DMG_ROOT/$APP_BUNDLE/Contents/Info.plist"
cp "$BUILD_BIN_DIR/HermesManager" "$DMG_ROOT/$APP_BUNDLE/Contents/MacOS/HermesManager"
strip -S "$DMG_ROOT/$APP_BUNDLE/Contents/MacOS/HermesManager" || true
cp "$APP_ICON" "$DMG_ROOT/$APP_BUNDLE/Contents/Resources/AppIcon.icns"
if [[ -f "$ROOT_DIR/Sources/Resources/HermesSidebarMark.png" ]]; then
  cp "$ROOT_DIR/Sources/Resources/HermesSidebarMark.png" "$DMG_ROOT/$APP_BUNDLE/Contents/Resources/HermesSidebarMark.png"
fi
while IFS= read -r bundle_dir; do
  cp -R "$bundle_dir" "$DMG_ROOT/$APP_BUNDLE/Contents/Resources/"
done < <(find "$BUILD_BIN_DIR" -maxdepth 1 -type d -name "*HermesManager*.bundle")
chmod +x "$DMG_ROOT/$APP_BUNDLE/Contents/MacOS/HermesManager"

clean_bundle_metadata "$DMG_ROOT/$APP_BUNDLE"
codesign --force --deep --sign - "$DMG_ROOT/$APP_BUNDLE"
refuse_private_payload "$DMG_ROOT/$APP_BUNDLE"

if [[ -f "$PROJECT_BACKGROUND" ]]; then
  copy_dmg_background "$PROJECT_BACKGROUND" "$BACKGROUND_TIFF"
else
  python3 - "$BACKGROUND_TIFF" <<'PY'
from pathlib import Path
from PIL import Image, ImageDraw
import sys

out = Path(sys.argv[1])
out.parent.mkdir(parents=True, exist_ok=True)
w, h = 1320, 844
img = Image.new("RGB", (w, h), (3, 7, 8))
draw = ImageDraw.Draw(img, "RGBA")
for cx, cy, color, radius in [
    (260, 200, (18, 200, 145), 520),
    (960, 290, (35, 205, 225), 560),
    (660, 760, (18, 240, 210), 360),
]:
    for r in range(radius, 0, -12):
        alpha = int(48 * (1 - r / radius) ** 2)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(*color, alpha))
for x in range(-200, w + 200, 90):
    draw.line((x, 0, x + 360, h), fill=(255, 255, 255, 10), width=1)
draw.text((72, 64), "Drag HermesManager to Applications", fill=(230, 245, 240))
img.save(out)
PY
fi

xattr -c "$BACKGROUND_TIFF" >/dev/null 2>&1 || true

if [[ ! -x "$DMGBUILD_PYTHON" ]]; then
  /usr/bin/python3 -m venv "$ROOT_DIR/.build/dmgbuild-venv"
  "$DMGBUILD_PYTHON" -m pip install --upgrade pip >/dev/null
  "$DMGBUILD_PYTHON" -m pip install dmgbuild >/dev/null
fi

"$DMGBUILD_PYTHON" - <<'PY'
from pathlib import Path

import dmgbuild.core

core_path = Path(dmgbuild.core.__file__)
text = core_path.read_text()
if "Bookmark.for_file(path_in_image)" in text:
    text = text.replace("from mac_alias import Alias, Bookmark", "from mac_alias import Alias")
    text = text.replace("        background_bmk = None\n\n", "")
    text = text.replace("            background_bmk = Bookmark.for_file(path_in_image)\n\n", "")
    text = text.replace("                if background_bmk:\n                    d[\".\"][\"pBBk\"] = background_bmk\n", "")
    core_path.write_text(text)
PY

detach_existing_installer_volumes
"$DMGBUILD_PYTHON" -m dmgbuild \
  -s "$ROOT_DIR/scripts/dmgbuild-settings.py" \
  -D "app_path=$DMG_ROOT/$APP_BUNDLE" \
  -D "background_path=$BACKGROUND_TIFF" \
  -D "volume_icon=$APP_ICON" \
  "$VOLUME_NAME" \
  "$FINAL_DMG" >/dev/null

hdiutil verify "$FINAL_DMG" >/dev/null
codesign --force --sign - "$FINAL_DMG" >/dev/null 2>&1 || true

echo "$FINAL_DMG"
