import copy
import importlib.util
import pathlib
import unittest

spec = importlib.util.spec_from_file_location("bank_guard", pathlib.Path(__file__).parents[1] / "check_question_bank.py")
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)


class QuestionBankGuardTests(unittest.TestCase):
    def bank(self):
        return [dict(id=f"{subject}-{level}", subject=subject, level=level, readingGrade=0,
                     prompt=f"Question {subject} {level}?", choices=["A", "B"], correct=0,
                     explanation="Original example.", source="Reference: https://example.org/fact", status="draft")
                for subject in guard.SUBJECTS for level in range(6)]

    def check(self, bank):
        return guard.check(bank, min_per_level=1, min_early_reading=1)

    def test_complete_grid_passes_without_promoting_drafts(self):
        bank = self.bank(); before = copy.deepcopy(bank)
        self.assertEqual(self.check(bank), {"draft": 36})
        self.assertEqual(bank, before)

    def test_missing_difficulty_or_early_reading_fails(self):
        bank = self.bank(); bank.pop()
        with self.assertRaisesRegex(ValueError, "Too few"):
            self.check(bank)
        bank = self.bank(); bank[-1]["readingGrade"] = 1
        with self.assertRaisesRegex(ValueError, "short-language"):
            self.check(bank)

    def test_duplicate_ids_and_normalized_prompts_fail(self):
        for field in ("id", "prompt"):
            bank = self.bank(); bank[1][field] = bank[0][field]
            with self.assertRaisesRegex(ValueError, "[Dd]uplicate"):
                self.check(bank)
        bank = self.bank(); bank[1]["prompt"] = "  " + bank[0]["prompt"].upper() + "  "
        with self.assertRaisesRegex(ValueError, "Duplicate prompt"):
            self.check(bank)

    def test_bad_choices_and_indices_fail(self):
        for value in (["A"], ["A"] * 5, ["A", " A "], ["A", ""], ["A", 3]):
            bank = self.bank(); bank[0]["choices"] = value
            with self.assertRaises(ValueError):
                self.check(bank)
        for value in (True, -1, 2, "0"):
            bank = self.bank(); bank[0]["correct"] = value
            with self.assertRaises(ValueError):
                self.check(bank)

    def test_capitalization_choices_remain_distinct(self):
        bank = self.bank(); bank[0]["choices"] = ["I run", "i run"]
        self.check(bank)

    def test_arithmetic_keys_use_exact_fractions_and_operator_precedence(self):
        bank = self.bank()
        for prompt, answer in (("What is 1/2 + 1/3?", "5/6"), ("What is 2 ÷ (1/3)?", "6"),
                               ("What is 3 + 2 × 4?", "11"), ("What is 2.25 + 3.40?", "113/20"),
                               ("Round 145 to the nearest ten.", "150")):
            bank[0].update(prompt=prompt, choices=[answer, "0"], correct=0)
            self.check(bank)
            bank[0]["correct"] = 1
            with self.assertRaisesRegex(ValueError, "key"):
                self.check(bank)
        with self.assertRaises(ValueError):
            guard.arithmetic_value("__import__('os').getcwd()")
        bank[0].update(prompt="What is 1/4 + 1/4?", choices=["1/2", "0.5"], correct=0)
        with self.assertRaisesRegex(ValueError, "equivalent"):
            self.check(bank)

    def test_invalid_grades_sources_and_status_fail(self):
        for field, value in (("subject", "unknown"), ("level", True), ("level", 6),
                             ("readingGrade", -1), ("source", "unverified"), ("status", "approved"),
                             ("prompt", ""), ("explanation", "x" * 241)):
            bank = self.bank(); bank[0][field] = value
            with self.assertRaises(ValueError):
                self.check(bank)

    def test_reviewed_requires_metadata_and_is_not_inferred(self):
        bank = self.bank(); bank[0]["status"] = "reviewed"
        with self.assertRaisesRegex(ValueError, "metadata"):
            self.check(bank)
        bank[0].update(reviewer="Synthetic unit-test reviewer", reviewedAt=800000000)
        self.assertEqual(self.check(bank), {"draft": 35, "reviewed": 1})
        for invalid in (None, "today", True, float("nan"), float("inf")):
            bank[0]["reviewedAt"] = invalid
            with self.assertRaises(ValueError):
                self.check(bank)

    def test_non_array_or_empty_fails(self):
        for value in (None, {}, [], ["question"]):
            with self.assertRaises(ValueError):
                self.check(value)
