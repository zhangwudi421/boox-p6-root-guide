# BOOX P6 小白马 Root 与 Magisk 管理器修复教程

本文记录 BOOX P6 小白马在 BOOX OS 4.1 上通过 EDL 提取 boot、Magisk 修补、EDL 写回，并修复 Magisk 管理器打不开的问题。

当前验证设备：

- 设备：BOOX P6 小白马
- 系统版本：`2025-09-23_16-03_4.1-rel_0923_fc05fc93c`
- 当前槽位：`_a`
- bootloader 状态：默认已解锁，本机验证为已解锁
- Root 结果：`adb shell su -c id` 返回 `uid=0(root)`
- Magisk App 修复结果：`com.topjohnwu.magisk/.ui.MainActivity` 可正常进入主界面

## 风险说明

Root、EDL 写分区、替换 framework 都有变砖风险。开始前至少保留原始 boot 备份，并确认自己能进入 EDL。

本教程里的 AMS 修复模块只适用于当前这台 P6 的当前固件。不要直接把别的设备、别的固件的 `services.jar` 拿来覆盖，否则可能开不了机。

## 快速开始

如果设备系统版本和本文验证版本一致，可以直接 clone 本仓库后运行脚本：

```bash
git clone https://github.com/zhangwudi421/boox-p6-root-guide.git
cd boox-p6-root-guide
./scripts/root_p6.sh
```

脚本会做这些事：

- 校验设备型号、系统版本和当前槽位。
- 自动 clone [bkerler/edl](https://github.com/bkerler/edl) 并安装依赖。
- 解压本仓库 `artifacts/` 里的 Magisk 修补 boot。
- 通过 EDL 写入 `boot_a`。
- 安装 Magisk App。
- 安装 P6 专用 AMS 修复模块。

脚本只默认支持：

```text
2025-09-23_16-03_4.1-rel_0923_fc05fc93c
```

如果你的系统版本不同，不要直接运行 `--force`，先按后文重新提取并修补当前固件自己的 boot 和 `services.jar`。

## 运行环境

脚本主要在 macOS 上验证。Linux 也可以使用，但需要自行处理 USB 权限。Windows 建议使用 WSL2 配合 Windows 侧 ADB/USB 转发，或者直接按手动步骤操作。

电脑侧需要提前安装：

- `git`
- `adb`
- `python`
- `pip`
- `xz`
- `libusb`

macOS 可以参考：

```bash
brew install android-platform-tools python xz libusb
```

Linux 需要安装发行版对应的软件包，并配置 Qualcomm 9008/ADB 的 udev 权限。常见包名包括：

```bash
sudo apt install git adb python3 python3-pip xz-utils libusb-1.0-0
```

运行前确认：

```bash
adb devices
python --version
pip --version
xz --version
```

设备侧需要：

- 打开 USB 调试。
- 允许当前电脑的 ADB 授权。
- 系统版本为 `2025-09-23_16-03_4.1-rel_0923_fc05fc93c`。
- 当前槽位为 `_a`。

## 准备工具

电脑侧需要：

- `adb`
- `fastboot`
- Python 3
- [bkerler/edl](https://github.com/bkerler/edl)
- [Magisk](https://github.com/topjohnwu/Magisk) APK

如果想手动准备 EDL 工具，可以放在本文同级工作目录下：

```bash
git clone https://github.com/bkerler/edl.git
python -m pip install -r edl/requirements.txt
```

后续命令默认目录结构如下：

```text
workdir/
  edl/
  p6_boot_a.img
  p6_boot_a_magisk.img
```

本次使用的关键文件：

- 原始 boot：`p6_boot_a.img`
- Magisk 修补 boot：`p6_boot_a_magisk.img`
- P6 原始 services：`p6_services.jar`
- P6 AMS 修复模块：用本仓库 `scripts/build_p6_ams_fix.py` 从本机 `p6_services.jar` 生成 `p6-ams-fix-v1.0.zip`
- Magisk APK：`artifacts/Magisk-v30.7.apk`
- 可写入的 EDL loader：

```text
edl/Loaders/lenovo_motorola/0000000000000000_bdaf51b59ba21d8a_fhprg.bin
```

## 一、确认设备状态

连接手机并打开 USB 调试：

```bash
adb devices
adb shell getprop ro.build.display.id
adb shell getprop ro.boot.slot_suffix
adb shell getprop ro.boot.flash.locked
adb shell getprop ro.boot.vbmeta.device_state
```

本机实测：

```text
ro.build.display.id = 2025-09-23_16-03_4.1-rel_0923_fc05fc93c
ro.boot.slot_suffix = _a
ro.boot.flash.locked = 0
ro.boot.vbmeta.device_state = unlocked
```

## 二、进入 EDL 并读取 boot

进入 EDL：

```bash
adb reboot edl
```

进入 `edl` 目录后读取当前槽位 boot：

```bash
cd edl
python edl.py r boot_a ../p6_boot_a.img --memory=ufs --vid=0x05c6 --pid=0x9008 --loader=Loaders/lenovo_motorola/0000000000000000_bdaf51b59ba21d8a_fhprg.bin
```

建议同时读取 `boot_b` 备份：

```bash
python edl.py r boot_b ../p6_boot_b.img --memory=ufs --vid=0x05c6 --pid=0x9008 --loader=Loaders/lenovo_motorola/0000000000000000_bdaf51b59ba21d8a_fhprg.bin
```

备份完成后重启：

```bash
python edl.py reset --vid=0x05c6 --pid=0x9008 --loader=Loaders/lenovo_motorola/0000000000000000_bdaf51b59ba21d8a_fhprg.bin
```

## 三、用 Magisk 修补 boot

安装 Magisk APK：

```bash
adb install -r Magisk-v30.7.apk
```

把原始 boot 放到手机：

```bash
adb push p6_boot_a.img /sdcard/Download/p6_boot_a.img
```

可以直接在 Magisk App 内选择 `p6_boot_a.img` 修补。若 Magisk App 打不开，也可以把 APK 内的 `boot_patch.sh` 和 arm64 工具解出来后命令行修补：

```bash
adb shell 'cd /data/local/tmp/magisk_patch && KEEPVERITY=true KEEPFORCEENCRYPT=true PATCHVBMETAFLAG=false sh boot_patch.sh /sdcard/Download/p6_boot_a.img'
adb pull /data/local/tmp/magisk_patch/new-boot.img p6_boot_a_magisk.img
```

## 四、写回修补后的 boot

普通 fastboot 在这台机子上不能写 boot：

```text
fastboot flash boot_a p6_boot_a_magisk.img
FAILED (remote: 'unknown command')
```

所以继续使用 EDL 写回：

```bash
adb reboot edl
cd edl
python edl.py w boot_a ../p6_boot_a_magisk.img --memory=ufs --vid=0x05c6 --pid=0x9008 --loader=Loaders/lenovo_motorola/0000000000000000_bdaf51b59ba21d8a_fhprg.bin
```

建议写完后立刻读回校验：

```bash
python edl.py r boot_a ../p6_boot_a_after_write.img --memory=ufs --vid=0x05c6 --pid=0x9008 --loader=Loaders/lenovo_motorola/0000000000000000_bdaf51b59ba21d8a_fhprg.bin
shasum -a 256 ../p6_boot_a_magisk.img ../p6_boot_a_after_write.img
```

两个 SHA256 一致才说明写入成功。

重启：

```bash
python edl.py reset --vid=0x05c6 --pid=0x9008 --loader=Loaders/lenovo_motorola/0000000000000000_bdaf51b59ba21d8a_fhprg.bin
```

验证 root：

```bash
adb shell magisk -v
adb shell su -c id
```

成功时应看到类似：

```text
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0
```

## 五、修复 Magisk 管理器打不开

BOOX OS 4.1 上，Magisk root 本身正常，但 Magisk App 可能卡启动页或打不开。参考 [dynamicfire/boox-ams-fix](https://github.com/dynamicfire/boox-ams-fix) 的分析，原因是文石改过 `services.jar` 里的 `ActivityManagerService.addPackageDependency()`，当 root 进程不在 PidMap 中时会空指针崩溃。

不要直接安装参考仓库的 zip。参考仓库模块内置的是其他设备固件的 `services.jar`，和 P6 当前固件不一致。

正确做法是：拉出 P6 自己的 `/system/framework/services.jar`，只对它自己的 `classes.dex` 做同样逻辑的单字节补丁，再封装成 Magisk 模块。

### 1. 拉出 P6 自己的 services.jar

```bash
adb shell cp /system/framework/services.jar /sdcard/Download/p6_services.jar
adb pull /sdcard/Download/p6_services.jar p6_services.jar
```

### 2. 定位补丁点

[dynamicfire/boox-ams-fix](https://github.com/dynamicfire/boox-ams-fix) 的 P6 Pro 模块补丁点是 `0x002b2f14` 附近。当前 P6 固件同一逻辑位置前移了 `0x20` 字节，实际需要修改的是：

```text
classes.dex offset: 0x002b2ef4
before: 38 01 33 00
after:  38 01 3f 00
```

也就是把 `if-eqz` 的跳转目标从文石 WebView 统计代码改到 `return-void`，避免 `ProcessRecord == null` 时继续访问 `info.packageName`。

修改 DEX 后必须重算：

- DEX SHA-1 signature
- DEX Adler32 checksum

### 3. 生成 P6 专用 Magisk 模块

模块结构：

```text
p6-ams-fix/
  module.prop
  customize.sh
  post-fs-data.sh
  system/framework/services.jar
```

其中 `system/framework/services.jar` 是 P6 自己的 `services.jar` 补丁版。

使用本仓库脚本生成：

```bash
python3 scripts/build_p6_ams_fix.py p6_services.jar -o p6-ams-fix-v1.0.zip
```

### 4. 命令行安装模块

因为 Magisk App 可能打不开，用命令行安装：

```bash
adb push p6-ams-fix-v1.0.zip /sdcard/Download/p6-ams-fix-v1.0.zip
adb shell su -c 'magisk --install-module /sdcard/Download/p6-ams-fix-v1.0.zip'
adb reboot
```

验证模块：

```bash
adb shell su -c 'ls -l /data/adb/modules/p6-ams-fix'
adb shell su -c id
```

启动 Magisk App：

```bash
adb shell am start -n com.topjohnwu.magisk/.ui.MainActivity
adb shell pidof com.topjohnwu.magisk
adb shell dumpsys activity top
```

成功时 `dumpsys activity top` 里能看到：

```text
ACTIVITY com.topjohnwu.magisk/.ui.MainActivity
mResumed=true
```

## 六、恢复方法

如果只是卸载 AMS 修复模块：

```bash
adb shell su -c 'rm -rf /data/adb/modules/p6-ams-fix'
adb reboot
```

如果要恢复原始 boot，进入 EDL 后写回备份：

```bash
cd edl
python edl.py w boot_a ../p6_boot_a.img --memory=ufs --vid=0x05c6 --pid=0x9008 --loader=Loaders/lenovo_motorola/0000000000000000_bdaf51b59ba21d8a_fhprg.bin
python edl.py reset --vid=0x05c6 --pid=0x9008 --loader=Loaders/lenovo_motorola/0000000000000000_bdaf51b59ba21d8a_fhprg.bin
```

## 七、OTA 注意事项

OTA 可能覆盖当前槽位 boot，也可能切换到另一个槽位。升级后 root 可能消失，Magisk 模块也可能需要重新安装或重新生成。

升级前建议：

1. 记录当前槽位。
2. 备份两个槽位的 boot。
3. OTA 后确认新槽位。
4. 读取新槽位 boot。
5. 用 Magisk 修补新 boot。
6. 用 EDL 写回新槽位。
7. 重新基于新系统的 `services.jar` 生成 AMS 修复模块。

## 参考

- 本仓库已附带验证设备的关键二进制文件，见 [`artifacts/`](artifacts/)。
- [dynamicfire/boox-ams-fix](https://github.com/dynamicfire/boox-ams-fix)
- [bkerler/edl](https://github.com/bkerler/edl)
- [topjohnwu/Magisk](https://github.com/topjohnwu/Magisk)
