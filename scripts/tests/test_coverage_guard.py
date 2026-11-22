import contextlib
import importlib.util
import io
import json
import pathlib
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("coverage_guard", pathlib.Path(__file__).parents[1] / "check_coverage.py")
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)


class CoverageGuardTests(unittest.TestCase):
    def report(self):
        files = sorted(p for folder in (guard.ROOT / "Sources", guard.ROOT / "App") for p in folder.rglob("*.swift") if p != guard.UI_ONLY)
        return {"data": [{"files": [{"filename": str(path), "summary": {"lines": {"count": 100, "covered": 95}}} for path in files]}]}

    def check(self, report):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "coverage.json"
            path.write_text(json.dumps(report))
            with contextlib.redirect_stdout(io.StringIO()):
                guard.check(path)

    def test_exact_threshold_passes(self):
        self.check(self.report())

    def test_high_total_does_not_hide_one_undercovered_file(self):
        report = self.report()
        for file in report["data"][0]["files"]:
            file["summary"]["lines"]["covered"] = 100
        report["data"][0]["files"][0]["summary"]["lines"]["covered"] = 94
        with self.assertRaises(ValueError):
            self.check(report)

    def test_missing_production_file_fails(self):
        report = self.report(); report["data"][0]["files"].pop()
        with self.assertRaises(ValueError):
            self.check(report)

    def test_empty_instrumentation_fails(self):
        with self.assertRaises(ValueError):
            self.check({"data": []})

    def test_duplicate_entries_fail(self):
        report = self.report(); report["data"][0]["files"].append(report["data"][0]["files"][0])
        with self.assertRaises(ValueError):
            self.check(report)

    def test_invalid_counts_fail(self):
        report = self.report(); report["data"][0]["files"][0]["summary"]["lines"] = {"covered": 0, "count": 0}
        with self.assertRaises(ValueError):
            self.check(report)
