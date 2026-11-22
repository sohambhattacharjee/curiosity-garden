# Question-bank owner review

The bank contains **1,440 original AI-assisted draft questions**: 40 in each of six subjects at each of six K–5 difficulty levels. Soham Bhattacharjee is the human reviewer. **0 questions are reviewed or Release eligible.** This PR remains separate from the technical implementation.

Each subject/level has ten skill or topic families with four related exercises per family. These are 1,440 individual items, not 1,440 distinct curriculum objectives. Numerical and scenario variations deliberately provide practice within a skill. No copyrighted question bank, passages, or images were imported. Original wording is contributed under the repository's MIT license.

## Review packets

Every packet contains 40 complete questions, all choices, the answer key, a short explanation, a primary-reference lead, the topic, and the proposed reading target. Each item remains **draft**. The checkboxes are review notes; changing a checkbox does not make an item Release eligible.

| Subject | K difficulty | 1 | 2 | 3 | 4 | 5 | Total |
| --- | --- | --- | --- | --- | --- | --- | ---: |
| Math | [40](question-bank/math-0.md) | [40](question-bank/math-1.md) | [40](question-bank/math-2.md) | [40](question-bank/math-3.md) | [40](question-bank/math-4.md) | [40](question-bank/math-5.md) | 240 |
| Reading | [40](question-bank/reading-0.md) | [40](question-bank/reading-1.md) | [40](question-bank/reading-2.md) | [40](question-bank/reading-3.md) | [40](question-bank/reading-4.md) | [40](question-bank/reading-5.md) | 240 |
| Science | [40](question-bank/science-0.md) | [40](question-bank/science-1.md) | [40](question-bank/science-2.md) | [40](question-bank/science-3.md) | [40](question-bank/science-4.md) | [40](question-bank/science-5.md) | 240 |
| World | [40](question-bank/world-0.md) | [40](question-bank/world-1.md) | [40](question-bank/world-2.md) | [40](question-bank/world-3.md) | [40](question-bank/world-4.md) | [40](question-bank/world-5.md) | 240 |
| Nature | [40](question-bank/nature-0.md) | [40](question-bank/nature-1.md) | [40](question-bank/nature-2.md) | [40](question-bank/nature-3.md) | [40](question-bank/nature-4.md) | [40](question-bank/nature-5.md) | 240 |
| Everyday | [40](question-bank/everyday-0.md) | [40](question-bank/everyday-1.md) | [40](question-bank/everyday-2.md) | [40](question-bank/everyday-3.md) | [40](question-bank/everyday-4.md) | [40](question-bank/everyday-5.md) | 240 |

## Review criteria

1. Verify the key and explanation against the linked primary reference or a more specific reliable reference. The reference leads support the topic; a link is not evidence that every generated statement has been independently verified. Fictional micro-stories, maps, measurements, prices, and trial results are explicitly constructed exercises.
2. Check that exactly one choice answers the question. Check distractor plausibility, grammar, cultural assumptions, units, and the explanation. Related exercises must not collapse into identical prompts.
3. Review difficulty separately from reading demands. Levels are proposed K–5 content bands, not a validated curriculum or a claim of complete standards coverage. School topics were informed by Common Core math/language and NGSS progressions; general-knowledge bands are editorial choices.
4. Review every `readingGrade`. These are provisional wording targets, **not measured reading scores**. K means a short shared-reading candidate; adult help may still be needed. The MVP has no built-in read-aloud. Eight or more short-language candidates per subject/level let the existing picker find harder content at a lower reading ceiling, but this numerical coverage does not certify K readability. Reword or replace unsuitable candidates before approval; do not keep an inaccurate low reading label to satisfy a test.
5. Check the actual iPhone/iPad screens at the largest in-app text setting, including explanation, every choice, I'm not sure, and Next. Check VoiceOver order and pronunciation, especially symbols, fractions, coordinates, degrees, and abbreviations. Automated length limits are not a layout/accessibility audit.
6. Confirm original wording or compatible rights and update the `source` field with the exact references actually used. Only after actual owner review, set `status` to `reviewed`, add `reviewer: "Soham Bhattacharjee"`, and set `reviewedAt` to the real review time. Foundation JSON dates use seconds since 2001-01-01 UTC; record a readable review date in the review notes too. Never invent review metadata in advance.
7. Re-run the bank audit, unit coverage gate, and required builds. Enough **reviewed** content, not just drafts, must cover the selected reading ceilings and mixed rounds before a family-ready Release. Debug shows the draft banner; Release continues to exclude drafts.

## Structural reading-ceiling coverage

Each row shows the number eligible at the **K reading ceiling**, grouped by content difficulty. Counts at every higher ceiling are at least these values. All 216 subject × difficulty × selected-grade ceiling combinations are exercised by tests; this is a capacity check, not a human readability approval.

| Subject | K difficulty | 1 | 2 | 3 | 4 | 5 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Math | 40 | 36 | 32 | 24 | 24 | 32 |
| Reading | 40 | 40 | 8 | 8 | 8 | 8 |
| Science | 40 | 24 | 8 | 8 | 8 | 8 |
| World | 40 | 24 | 8 | 12 | 8 | 8 |
| Nature | 40 | 16 | 8 | 8 | 8 | 8 |
| Everyday | 40 | 28 | 8 | 8 | 8 | 8 |

## IDs and corrections

The former 96 development fixtures used IDs such as `math-0-000`. Those IDs are retired, not reassigned to materially different questions. The new bank uses `cg-v1-{subject}-{level}-{number}`. Keep these new IDs stable for wording corrections; use a new ID for a materially different question. Existing answer-history snapshots keep the content originally shown.

See [content policy](CONTENT_REVIEW.md), [primary reference leads and topic map](QUESTION_BANK_SOURCES.md), and [validation](VALIDATION.md). No app flow, timing, adaptation, PIN, or review-gate implementation is changed in this PR.
