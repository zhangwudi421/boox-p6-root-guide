# Artifacts

These files are from the verified BOOX P6 device used for the guide.

Files:

- `p6_boot_a.img.xz`: compressed stock `boot_a` backup.
- `p6_boot_a_magisk.img.xz`: compressed Magisk-patched `boot_a`.
- `p6_services.jar`: stock `/system/framework/services.jar` from the tested firmware.
- `p6-ams-fix-v1.0.zip`: Magisk module generated for the tested firmware.
- `Magisk-v30.7.apk`: Magisk app used with the patched boot in this guide.

Tested firmware:

```text
2025-09-23_16-03_4.1-rel_0923_fc05fc93c
```

SHA256:

```text
fcd8c468a24687d7c772a28dac5c6bd610eaec142616b3e8acf7fe8e99a13f08  p6-ams-fix-v1.0.zip
e0d32d2123532860f97123d927b1bb86c4e08e6fd8a48bfc6b5bee0afae9ebd5  Magisk-v30.7.apk
b2f14fbbc8097456d6eaf2768b3021a3f62c85a7b5e0448b62559f37e32c1b6e  p6_services.jar
19680f61dfbc873e90d936e08cbaaea9a8efa27b590b7cd3427334ee8d72d40e  p6_boot_a.img.xz
6e03dfa43ce703bc7ac9acbfe2e1a16ae3cbbcf921e61579b17660de217b51b3  p6_boot_a_magisk.img.xz
0a64613adee55c49043f83bad1fd8f8f2977730f4b99dcc155db852938095cb9  p6_boot_a.img
e4d4e54a9922dc0c6755c6f7aa6845281f4a2e3164e4b48a77bfcace7b214333  p6_boot_a_magisk.img
```

Decompress boot images:

```bash
xz -dk p6_boot_a.img.xz
xz -dk p6_boot_a_magisk.img.xz
```

Do not flash these files blindly on a different firmware. For OTA-updated devices, extract and patch that firmware's own boot image and `services.jar`.
