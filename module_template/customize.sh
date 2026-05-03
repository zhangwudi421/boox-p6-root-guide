#!/system/bin/sh
ui_print "=========================================="
ui_print "  BOOX P6 AMS Fix"
ui_print "  Firmware: 2025-09-23 OS 4.1"
ui_print "  Patch: services.jar classes.dex 0x2b2ef4"
ui_print "  Clearing dalvik cache..."
rm -f /data/dalvik-cache/arm64/system@framework@services.jar@classes.dex 2>/dev/null
rm -f /data/dalvik-cache/arm64/system@framework@services.jar@classes.vdex 2>/dev/null
rm -f /data/dalvik-cache/arm/system@framework@services.jar@classes.dex 2>/dev/null
rm -f /data/dalvik-cache/arm/system@framework@services.jar@classes.vdex 2>/dev/null
ui_print "  Done. Reboot to apply."
ui_print "=========================================="

