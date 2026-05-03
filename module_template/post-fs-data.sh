#!/system/bin/sh
# Keep stale compiled artifacts from being reused after services.jar overlay.
rm -f /data/dalvik-cache/arm64/system@framework@services.jar@classes.dex 2>/dev/null
rm -f /data/dalvik-cache/arm64/system@framework@services.jar@classes.vdex 2>/dev/null
rm -f /data/dalvik-cache/arm/system@framework@services.jar@classes.dex 2>/dev/null
rm -f /data/dalvik-cache/arm/system@framework@services.jar@classes.vdex 2>/dev/null

