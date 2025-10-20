#!/usr/bin/env python3
"""
Utility helpers to stretch Allen standalone runs without external inputs.

It generates:
  * Allen/build/mdf_repeat.lst – a text file with repeated references to the
    bundled MiniBrunel MDF so the same events can be replayed many times.
  * Allen/input/detector_configuration/magfield.bin – a minimal zero-field grid
    that satisfies Allen's non-event data updater when the real field map is
    not available (e.g. CVMFS offline).
"""

from __future__ import annotations

import argparse
import struct
from pathlib import Path


DEFAULT_BUILD_DIR = Path("Allen/build")
DEFAULT_MDF = Path("Allen/input/minbias/mdf/MiniBrunel_2018_MinBias_FTv4_DIGI_retinacluster_v1.mdf")
DEFAULT_MAGFIELD = Path("Allen/input/detector_configuration/magfield.bin")
DEFAULT_REPEAT_FILE = Path("mdf_repeat.lst")


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument(
    "--build-dir",
    type=Path,
    default=DEFAULT_BUILD_DIR,
    help="Location of the Allen build directory (default: %(default)s)",
  )
  parser.add_argument(
    "--mdf-path",
    type=Path,
    default=DEFAULT_MDF,
    help="Path to the MDF file to repeat (default: %(default)s)",
  )
  parser.add_argument(
    "--repeat-count",
    type=int,
    default=20,
    help="Number of times the MDF path should be repeated (default: %(default)s)",
  )
  parser.add_argument(
    "--repeat-file",
    type=Path,
    default=DEFAULT_REPEAT_FILE,
    help="Name of the repeat list file relative to the build directory (default: %(default)s)",
  )
  parser.add_argument(
    "--magfield-path",
    type=Path,
    default=DEFAULT_MAGFIELD,
    help="Destination for the generated zero-field magfield binary (default: %(default)s)",
  )
  parser.add_argument(
    "--force",
    action="store_true",
    help="Overwrite existing repeat lists and magfield file if present.",
  )
  return parser.parse_args()


def write_repeat_file(build_dir: Path, repeat_file: Path, mdf_path: Path, repeat_count: int, force: bool) -> Path:
  if repeat_count <= 0:
    raise ValueError("repeat-count must be positive")

  if not mdf_path.is_file():
    raise FileNotFoundError(f"MDF file not found: {mdf_path}")

  build_dir.mkdir(parents=True, exist_ok=True)
  target = build_dir / repeat_file

  if target.exists() and not force:
    print(f"[skip] Repeat list exists at {target}. Use --force to overwrite.")
    return target

  with target.open("w", encoding="utf-8") as handle:
    for _ in range(repeat_count):
      handle.write(str(mdf_path) + "\n")

  print(f"[ok] Wrote repeat list with {repeat_count} entries to {target}")
  return target


def write_zero_magfield(path: Path, force: bool) -> Path | None:
  if path.exists() and not force:
    print(f"[skip] magfield already present at {path}. Use --force to overwrite.")
    return None

  path.parent.mkdir(parents=True, exist_ok=True)

  header = struct.pack("<4f", 1.0, 1.0, 1.0, 0.0)  # invDx, invDy, invDz, padding
  header += struct.pack("<4i", 1, 1, 1, 0)  # grid dimensions
  header += struct.pack("<4f", 0.0, 0.0, 0.0, 0.0)  # min coordinates + padding
  body = struct.pack("<4f", 0.0, 0.0, 0.0, 0.0)  # single zero-field cell

  with path.open("wb") as handle:
    handle.write(header)
    handle.write(body)

  print(f"[ok] Wrote synthetic magfield to {path}")
  return path


def main() -> None:
  args = parse_args()

  write_repeat_file(args.build_dir, args.repeat_file, args.mdf_path, args.repeat_count, args.force)
  created = write_zero_magfield(args.magfield_path, args.force)

  if created is None:
    print("[info] Existing magfield preserved.")
  else:
    print("[warn] Synthetic magfield contains no physics information; replace with the real field map for validation runs.")


if __name__ == "__main__":
  main()
