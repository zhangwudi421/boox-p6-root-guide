#!/usr/bin/env python3
import argparse
import hashlib
import shutil
import struct
import zipfile
import zlib
from pathlib import Path


PATCH_OFFSET = 0x002B2EF4
EXPECTED = bytes.fromhex("38 01 33 00")
PATCHED = bytes.fromhex("38 01 3f 00")
ZIP_DATE = (2008, 1, 1, 0, 0, 0)


def patch_dex(dex: bytes) -> bytes:
    data = bytearray(dex)
    actual = bytes(data[PATCH_OFFSET - 2:PATCH_OFFSET + 2])
    if actual == PATCHED:
        return bytes(data)
    if actual != EXPECTED:
        raise SystemExit(
            f"unexpected bytes near patch point: {actual.hex(' ')}; "
            f"expected {EXPECTED.hex(' ')}"
        )

    data[PATCH_OFFSET] = 0x3F
    data[12:32] = hashlib.sha1(data[32:]).digest()
    data[8:12] = struct.pack("<I", zlib.adler32(data[12:]) & 0xFFFFFFFF)
    return bytes(data)


def build_module(services_jar: Path, template_dir: Path, output_zip: Path, work_dir: Path) -> None:
    if work_dir.exists():
        shutil.rmtree(work_dir)
    (work_dir / "system/framework").mkdir(parents=True)

    for name in ("module.prop", "customize.sh", "post-fs-data.sh"):
        shutil.copy2(template_dir / name, work_dir / name)

    patched_jar = work_dir / "system/framework/services.jar"
    with zipfile.ZipFile(services_jar, "r") as zin:
        classes = patch_dex(zin.read("classes.dex"))
        with zipfile.ZipFile(patched_jar, "w") as zout:
            for info in zin.infolist():
                data = classes if info.filename == "classes.dex" else zin.read(info.filename)
                out_info = zipfile.ZipInfo(info.filename, info.date_time)
                out_info.compress_type = info.compress_type
                out_info.external_attr = info.external_attr
                out_info.comment = info.comment
                out_info.extra = info.extra
                zout.writestr(out_info, data)

    if output_zip.exists():
        output_zip.unlink()
    with zipfile.ZipFile(output_zip, "w", compression=zipfile.ZIP_DEFLATED) as zout:
        for path in sorted(work_dir.rglob("*")):
            if path.is_file():
                arcname = path.relative_to(work_dir).as_posix()
                info = zipfile.ZipInfo(arcname, ZIP_DATE)
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = (0o755 if path.name.endswith(".sh") else 0o644) << 16
                zout.writestr(info, path.read_bytes())

    print(f"module: {output_zip}")
    print(f"patched services.jar sha256: {hashlib.sha256(patched_jar.read_bytes()).hexdigest()}")
    print(f"module zip sha256: {hashlib.sha256(output_zip.read_bytes()).hexdigest()}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build BOOX P6 AMS Magisk fix module.")
    parser.add_argument("services_jar", type=Path, help="services.jar pulled from this BOOX P6 firmware")
    parser.add_argument("-o", "--output", type=Path, default=Path("p6-ams-fix-v1.0.zip"))
    parser.add_argument("--template", type=Path, default=Path("module_template"))
    parser.add_argument("--work-dir", type=Path, default=Path("build/p6-ams-fix"))
    args = parser.parse_args()
    build_module(args.services_jar, args.template, args.output, args.work_dir)


if __name__ == "__main__":
    main()
