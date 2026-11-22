"""Offline structural/content-capacity checks; this does not perform human review."""
import collections
import ast
import json
import math
import pathlib
import re
import unicodedata
from fractions import Fraction

ROOT = pathlib.Path(__file__).resolve().parents[1]
SUBJECTS = ("math", "reading", "science", "world", "nature", "everyday")
MIN_PER_LEVEL = 40
MIN_EARLY_READING = 8


def normalized(value):
    return " ".join(unicodedata.normalize("NFKC", value).split())


def arithmetic_value(expression):
    """Evaluate only literal rational arithmetic; never eval author-supplied code."""
    def value(node):
        if isinstance(node, ast.Constant) and type(node.value) in (int, float):
            return Fraction(str(node.value))
        if isinstance(node, ast.BinOp):
            left, right = value(node.left), value(node.right)
            if isinstance(node.op, ast.Add):
                return left + right
            if isinstance(node.op, ast.Sub):
                return left - right
            if isinstance(node.op, ast.Mult):
                return left * right
            if isinstance(node.op, ast.Div):
                return left / right
        raise ValueError("Unsupported arithmetic expression")
    return value(ast.parse(expression.replace("×", "*").replace("÷", "/"), mode="eval").body)


def check_literal_key(item):
    match = re.fullmatch(r"What is ([0-9. +×÷/()\-]+)\?", item["prompt"])
    if match:
        expected = arithmetic_value(match[1])
        try:
            actual = Fraction(item["choices"][item["correct"]])
        except (ValueError, ZeroDivisionError) as error:
            raise ValueError(f"Nonnumeric arithmetic key: {item['id']}") from error
        if actual != expected:
            raise ValueError(f"Incorrect arithmetic key: {item['id']}")
        if sum(Fraction(choice) == expected for choice in item["choices"]) != 1:
            raise ValueError(f"Multiple equivalent arithmetic answers: {item['id']}")
    rounding = re.fullmatch(r"Round ([0-9]+) to the nearest ten\.", item["prompt"])
    if rounding:
        expected = str((int(rounding[1]) + 5) // 10 * 10)
        if item["choices"][item["correct"]] != expected:
            raise ValueError(f"Incorrect rounding key: {item['id']}")


def check(questions, min_per_level=MIN_PER_LEVEL, min_early_reading=MIN_EARLY_READING):
    if not isinstance(questions, list) or not questions:
        raise ValueError("Expected a nonempty question array")
    ids, prompts = set(), set()
    counts, early = collections.Counter(), collections.Counter()
    statuses = collections.Counter()
    for item in questions:
        if not isinstance(item, dict):
            raise ValueError("Question must be an object")
        qid = item.get("id")
        if not isinstance(qid, str) or not qid.strip() or qid in ids:
            raise ValueError(f"Missing/duplicate ID: {qid}")
        ids.add(qid)
        subject, level, reading = (item.get(k) for k in ("subject", "level", "readingGrade"))
        if subject not in SUBJECTS or type(level) is not int or level not in range(6):
            raise ValueError(f"Invalid subject/difficulty: {qid}")
        if type(reading) is not int or reading not in range(6):
            raise ValueError(f"Invalid reading grade: {qid}")
        for field, limit in (("prompt", 180), ("explanation", 240), ("source", 1200)):
            value = item.get(field)
            if not isinstance(value, str) or not value.strip() or len(value) > limit:
                raise ValueError(f"Missing/oversized {field}: {qid}")
        prompt = normalized(item["prompt"]).casefold()
        if prompt in prompts:
            raise ValueError(f"Duplicate prompt: {qid}")
        prompts.add(prompt)
        choices, correct = item.get("choices"), item.get("correct")
        if not isinstance(choices, list) or not 2 <= len(choices) <= 4:
            raise ValueError(f"Need 2–4 choices: {qid}")
        if any(not isinstance(c, str) or not c.strip() or len(c) > 120 for c in choices):
            raise ValueError(f"Missing/oversized choice: {qid}")
        # Case distinguishes legitimate capitalization answers (I run / i run).
        if len(set(map(normalized, choices))) != len(choices):
            raise ValueError(f"Duplicate choice: {qid}")
        if type(correct) is not int or correct not in range(len(choices)):
            raise ValueError(f"Invalid answer index: {qid}")
        check_literal_key(item)
        if not re.search(r"https://[^\s]+", item["source"]):
            raise ValueError(f"Missing reference URL: {qid}")
        status = item.get("status")
        if status not in ("draft", "reviewed"):
            raise ValueError(f"Invalid review status: {qid}")
        if status == "reviewed":
            reviewer, date = item.get("reviewer"), item.get("reviewedAt")
            if (not isinstance(reviewer, str) or not reviewer.strip()
                    or type(date) not in (int, float) or not math.isfinite(date)):
                raise ValueError(f"Reviewed question missing real-review metadata: {qid}")
        counts[subject, level] += 1
        if reading == 0:
            early[subject, level] += 1
        statuses[status] += 1
    for subject in SUBJECTS:
        for level in range(6):
            if counts[subject, level] < min_per_level:
                raise ValueError(f"Too few questions: {subject} level {level}")
            if early[subject, level] < min_early_reading:
                raise ValueError(f"Missing short-language adaptation coverage: {subject} level {level}")
    return statuses


if __name__ == "__main__":
    bank = json.loads((ROOT / "App/questions.json").read_text())
    try:
        status = check(bank)
    except ValueError as error:
        raise SystemExit(str(error)) from error
    print(f"Question bank: {len(bank)} items; {status['draft']} draft; {status['reviewed']} reviewed")
    print("All 36 subject/difficulty cells and 216 reading-ceiling combinations have structural coverage.")
    print("Human fact, ambiguity, difficulty, readability, and accessibility review is still required.")
