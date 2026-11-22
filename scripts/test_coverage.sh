#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# A fresh instrumentation directory avoids stale counters from older runs.
coverage_scratch="$(mktemp -d "${TMPDIR:-/tmp}/curiosity-coverage.XXXXXX")"
trap 'rm -rf "$coverage_scratch"' EXIT
swift test --enable-code-coverage --scratch-path "$coverage_scratch"
coverage_report="$(swift test --show-codecov-path --scratch-path "$coverage_scratch")"
python3 scripts/check_coverage.py "$coverage_report"
