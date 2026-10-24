#!/usr/bin/env python3
"""16 KB page-size check for native libraries (PRF-MOB-002).

Fails unless the APK has at least one 64-bit (arm64-v8a, x86_64) native library and every such library
is an ELF64 file whose LOAD segments are aligned to >= 16 KB, as Google Play requires for apps targeting
Android 15+ on 16 KB page devices. 32-bit ABIs are not covered by that rule. The zip alignment of the
release package (zipalign -P 16 / AGP) is not checked here: the gate builds a debug APK only.
Usage: python3 scripts/check-16kb-pages.py --apk <path>
"""
import argparse
import struct
import sys
import zipfile
from pathlib import Path

ABIS = ("lib/arm64-v8a/", "lib/x86_64/")
PT_LOAD = 1
PAGE = 16 * 1024


def load_alignments(elf):
    """Alignments of the LOAD segments of a little-endian ELF64 file; ValueError if it is not one."""
    if elf[:5] != b"\x7fELF\x02":
        raise ValueError("not an ELF64 file")
    phoff = struct.unpack_from("<Q", elf, 0x20)[0]
    phentsize, phnum = struct.unpack_from("<HH", elf, 0x36)
    alignments = []
    for index in range(phnum):
        entry = phoff + index * phentsize
        if struct.unpack_from("<I", elf, entry)[0] == PT_LOAD:
            alignments.append(struct.unpack_from("<Q", elf, entry + 0x30)[0])
    if not alignments:
        raise ValueError("no LOAD segment")
    return alignments


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", type=Path, required=True)
    args = parser.parse_args()
    errors, checked = [], 0
    try:
        with zipfile.ZipFile(args.apk) as apk:
            for name in apk.namelist():
                if not (name.startswith(ABIS) and name.endswith(".so")):
                    continue
                checked += 1
                try:
                    smallest = min(load_alignments(apk.read(name)))
                except (ValueError, struct.error) as error:
                    errors.append(f"{name}: {error}")
                    continue
                if smallest < PAGE:
                    errors.append(f"{name}: LOAD segment aligned to {smallest} bytes (needs >= {PAGE})")
    except (OSError, zipfile.BadZipFile) as error:
        errors.append(f"cannot read {args.apk}: {error}")
    if not checked and not errors:
        errors.append("no 64-bit native library found (expected lib/arm64-v8a or lib/x86_64)")
    for error in errors:
        print(f"FAIL: {error}", file=sys.stderr)
    if errors:
        return 1
    print(f"PASS: {checked} 64-bit native libraries have LOAD segments aligned to >= 16 KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
