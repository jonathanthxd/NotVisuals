#!/usr/bin/env python3
"""Check licensing notices and block official builds with unresolved known imports.

A passing automated check is NOT proof of copyright ownership or legal compliance.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = Path("docs/RIGHTS_STATUS.json")
REQUIRED = (
    "LICENSE", "LICENSE-CODE", "LICENSE-ASSETS.md", "LICENSING.md",
    "THIRD_PARTY_LICENSES.md", "TRADEMARKS.md", "docs/RIGHTS_STATUS.json",
)
EVIDENCE_FIELDS = ("author", "origin_url", "license_or_permission", "evidence_url", "reviewed_by")


def check(root: Path = ROOT, *, release: bool = False) -> list[str]:
    """Return known unresolved rights in this checkout, or reject a release."""
    missing = [name for name in REQUIRED if not (root / name).is_file()]
    if missing:
        raise SystemExit("License notices missing: " + ", ".join(missing))

    try:
        manifest = json.loads((root / MANIFEST).read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise SystemExit(f"Invalid rights manifest: {exc}") from exc
    if manifest.get("schema_version") != 1 or not isinstance(manifest.get("items"), list):
        raise SystemExit("Invalid rights manifest schema")

    blockers: list[str] = []
    seen: set[str] = set()
    for item in manifest["items"]:
        if not isinstance(item, dict):
            raise SystemExit("Invalid rights manifest item")
        name = item.get("id")
        patterns = item.get("paths")
        status = item.get("status")
        if not isinstance(name, str) or not name or name in seen:
            raise SystemExit(f"Duplicate/invalid rights item: {name!r}")
        seen.add(name)
        if not isinstance(patterns, list) or not patterns or not all(isinstance(p, str) for p in patterns):
            raise SystemExit(f"Invalid rights file patterns for {name}")
        if status not in ("pending", "cleared", "removed"):
            raise SystemExit(f"Invalid clearance status for {name}: {status!r}")
        matched = sorted(set(path.relative_to(root).as_posix()
                             for pattern in patterns for path in root.glob(pattern) if path.is_file()))
        if not matched:
            continue
        if status == "removed":
            blockers.append(f"{name}: marked removed, but {len(matched)} matching file(s) still exist")
        elif status != "cleared":
            blockers.append(f"{name}: permission pending for {len(matched)} matching file(s)")
        else:
            absent = [field for field in EVIDENCE_FIELDS
                      if not isinstance(item.get(field), str) or not item[field].strip()]
            if absent:
                blockers.append(f"{name}: clearance record missing {', '.join(absent)}")

    if blockers and release:
        raise SystemExit(
            "BLOCKED: official release contains material with unverified rights:\n- "
            + "\n- ".join(blockers)
            + "\nResolve provenance, credit and permission (or remove/replace the material); "
              "then update docs/RIGHTS_STATUS.json and THIRD_PARTY_LICENSES.md. "
              "See https://github.com/jonathanthxd/NotVisuals/issues/2"
        )
    for item in blockers:
        print("LICENSING WARNING (developer build only): " + item)
    print("License files and rights manifest verified."
          + (" Release preflight passed; human verification still required." if release else ""))
    return blockers


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release", action="store_true",
                        help="Reject official packaging while known third-party rights are pending")
    args = parser.parse_args()
    check(release=args.release)
