# Question format

The offline bank is `App/questions.json`. Questions have:

- A stable `id`, `subject`, content `level` (0–5), and `readingGrade` (0–5).
- A `prompt`, 2–4 distinct `choices`, a zero-based `correct` index, and a short `explanation`.
- `source` references/provenance and `status`: `draft` or `reviewed`.

Debug accepts drafts. Release requires `reviewed`, a nonempty `reviewer`, and `reviewedAt`. These fields describe a completed review; drafts leave review metadata unset. JSON dates use seconds since 2001-01-01 UTC, matching Foundation Codable.

Run `python3 scripts/check_question_bank.py` after content changes. It checks structure, keys, references, and subject/difficulty/reading-ceiling capacity. It does not establish factual accuracy or reading suitability.

Keep IDs for wording corrections; assign a new ID to a materially different question. Saved history preserves the question originally shown. Retain applicable licensing notices for contributed content.
