#!/usr/bin/env python3
"""Fail closed if any production logic file is missing or below 95% line coverage."""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
# The only exception is declarative SwiftUI presentation. Keep business logic in
# instrumented sources; adding exclusions or reducing thresholds requires review.
UI_ONLY = ROOT / "App/CuriosityGardenApp.swift"
MINIMUM = 95.0


def check(report_path):
    report = json.loads(pathlib.Path(report_path).read_text())
    expected = {p.resolve() for folder in (ROOT / "Sources", ROOT / "App") for p in folder.rglob("*.swift") if p != UI_ONLY}
    summaries = {}
    for unit in report["data"]:
        for item in unit["files"]:
            path = pathlib.Path(item["filename"]).resolve()
            if path in expected:
                if path in summaries:
                    raise ValueError(f"Duplicate coverage entry for {path}")
                summaries[path] = item["summary"]["lines"]
    failures = []
    covered = total = 0
    for path in sorted(expected):
        summary = summaries.get(path)
        if summary is None:
            failures.append(f"Missing instrumentation: {path.relative_to(ROOT)}")
            continue
        count, hit = summary["count"], summary["covered"]
        if count <= 0 or hit < 0 or hit > count:
            failures.append(f"Invalid line counts: {path.relative_to(ROOT)}")
            continue
        percent = 100 * hit / count
        print(f"{path.relative_to(ROOT)}: {hit}/{count} ({percent:.2f}%)")
        covered += hit
        total += count
        if percent < MINIMUM:
            failures.append(f"Below {MINIMUM}%: {path.relative_to(ROOT)} ({percent:.2f}%)")
    aggregate = 100 * covered / total if total else 0
    print(f"Production logic total: {covered}/{total} ({aggregate:.2f}%)")
    if not expected or aggregate < MINIMUM:
        failures.append(f"Overall coverage must reach {MINIMUM}%")
    if failures:
        raise ValueError("\n".join(failures))


if __name__ == "__main__":
    try:
        if len(sys.argv) != 2:
            raise ValueError("Usage: python3 scripts/check_coverage.py COVERAGE.json")
        check(sys.argv[1])
    except (KeyError, OSError, ValueError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
