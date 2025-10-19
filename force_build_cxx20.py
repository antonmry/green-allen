#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

PATTERNS = (
    ("-std=c++17", "-std=c++20"),
    ("-std=gnu++17", "-std=gnu++20"),
    ("c++17", "c++20"),
)


def patch_file(path: Path, dry_run: bool) -> bool:
    try:
        data = path.read_text()
    except (UnicodeDecodeError, OSError):
        return False

    original = data
    for old, new in PATTERNS:
        data = data.replace(old, new)

    if data == original:
        return False

    if dry_run:
        return True

    path.write_text(data)
    return True


def main() -> None:
    parser = argparse.ArgumentParser(description="Force build artefacts to use C++20")
    parser.add_argument("build_dir", nargs="?", default="Allen/build", help="CMake build directory")
    parser.add_argument("--dry-run", action="store_true", dest="dry_run", help="Report files without modifying")
    args = parser.parse_args()

    build_dir = Path(args.build_dir).resolve()
    if not build_dir.exists():
        parser.error(f"build directory '{build_dir}' does not exist")

    if not build_dir.is_dir():
        parser.error(f"'{build_dir}' is not a directory")

    changed = 0
    scanned = 0
    for path in build_dir.rglob("*"):
        if not path.is_file():
            continue
        scanned += 1
        if patch_file(path, dry_run=args.dry_run):
            changed += 1

    status = "would update" if args.dry_run else "updated"
    print(f"Scanned {scanned} files under {build_dir}")
    print(f"{status} {changed} files to C++20")


if __name__ == "__main__":
    main()
