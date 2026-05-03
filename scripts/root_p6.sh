#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EDL_DIR="$ROOT_DIR/edl"
ARTIFACTS_DIR="$ROOT_DIR/artifacts"
BUILD_DIR="$ROOT_DIR/build"
LOADER="Loaders/lenovo_motorola/0000000000000000_bdaf51b59ba21d8a_fhprg.bin"
EXPECTED_BUILD="2025-09-23_16-03_4.1-rel_0923_fc05fc93c"
PATCHED_BOOT_XZ="$ARTIFACTS_DIR/p6_boot_a_magisk.img.xz"
PATCHED_BOOT="$BUILD_DIR/p6_boot_a_magisk.img"
MAGISK_APK="$ARTIFACTS_DIR/Magisk-v30.7.apk"
AMS_MODULE="$ARTIFACTS_DIR/p6-ams-fix-v1.0.zip"

YES=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) YES=1 ;;
    --force) FORCE=1 ;;
    *) echo "unknown argument: $arg" >&2; exit 1 ;;
  esac
done

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing command: $1" >&2
    exit 1
  fi
}

adb_prop() {
  adb shell getprop "$1" 2>/dev/null | tr -d '\r'
}

wait_for_adb_shell() {
  echo "waiting for Android to come back online..."
  for _ in $(seq 1 120); do
    if adb shell getprop sys.boot_completed >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "timed out waiting for adb shell" >&2
  exit 1
}

need_cmd adb
need_cmd python
need_cmd xz

if [ ! -f "$EDL_DIR/edl.py" ]; then
  "$ROOT_DIR/scripts/setup_edl.sh"
fi

if [ ! -f "$EDL_DIR/$LOADER" ]; then
  echo "EDL loader not found: $EDL_DIR/$LOADER" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"
xz -dkc "$PATCHED_BOOT_XZ" > "$PATCHED_BOOT"

MODEL="$(adb_prop ro.product.model)"
BUILD="$(adb_prop ro.build.display.id)"
SLOT="$(adb_prop ro.boot.slot_suffix)"
UNLOCKED="$(adb_prop ro.boot.vbmeta.device_state)"

echo "model: $MODEL"
echo "build: $BUILD"
echo "slot: $SLOT"
echo "vbmeta state: $UNLOCKED"

if [ "$MODEL" != "P6" ]; then
  echo "this script only targets BOOX P6" >&2
  exit 1
fi

if [ "$SLOT" != "_a" ]; then
  echo "this verified artifact is for boot_a, but current slot is $SLOT" >&2
  exit 1
fi

if [ "$BUILD" != "$EXPECTED_BUILD" ] && [ "$FORCE" -ne 1 ]; then
  echo "build mismatch. expected: $EXPECTED_BUILD" >&2
  echo "use --force only if you know this boot image matches your firmware" >&2
  exit 1
fi

if [ "$YES" -ne 1 ]; then
  echo
  echo "This will reboot to EDL and write artifacts/p6_boot_a_magisk.img.xz to boot_a."
  read -r -p "Continue? Type YES: " answer
  if [ "$answer" != "YES" ]; then
    echo "aborted"
    exit 1
  fi
fi

adb reboot edl
sleep 5

(
  cd "$EDL_DIR"
  python edl.py w boot_a "$PATCHED_BOOT" --memory=ufs --vid=0x05c6 --pid=0x9008 --loader="$LOADER"
  python edl.py reset --vid=0x05c6 --pid=0x9008 --loader="$LOADER" || true
)

wait_for_adb_shell

adb install -r "$MAGISK_APK"
adb push "$AMS_MODULE" /sdcard/Download/p6-ams-fix-v1.0.zip

echo "If the device asks for shell root permission, approve it on the phone."
adb shell su -c 'magisk --install-module /sdcard/Download/p6-ams-fix-v1.0.zip'
adb reboot

echo "Done. After reboot, verify with:"
echo "  adb shell su -c id"
