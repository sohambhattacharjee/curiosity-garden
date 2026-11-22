# Content review and release gate

`App/questions.json` contains 96 original **draft development fixtures**, not a reviewed bank or validated K–5 curriculum. Difficulty and reading grades are provisional; all currently have a permissive reading-grade placeholder. Some early readers need adult assistance. Do not claim that running fixtures establishes educational quality.

Debug builds display a persistent draft banner and may use drafts. Release builds select only `reviewed` items with a nonempty reviewer and review date. With no eligible reviewed content, play ends with an explicit content-unavailable message. There is no UI toggle to unlock drafts in Release.

For each question contribution, supply a stable ID, subject, content level, reading grade, 2–4 unique choices, one correct index, short explanation, factual sources, and licensing provenance. Keep status `draft` through authoring and correction. A human content reviewer should check facts against reliable primary references, ambiguity, selected-grade readability, inclusive wording, distractors, and accessibility. Record reviewer identity and ISO-8601 review date (JSON dates currently encode as seconds since 2001-01-01, matching Foundation Codable); update the source field with actual references and provenance before setting `reviewed`. Never self-label unreviewed AI-assisted text as reviewed.

Corrections use the content issue template and a pull request. Keep IDs stable when correcting wording; use a new ID for a materially different question. Report history snapshots preserve the wording and review status seen when answered. No third-party content is bundled; retain required notices if that changes. A family-ready Release requires enough reviewed material at every subject, content level, and reading ceiling to support mixed rounds and later reviews.

The owner will review the bank in its dedicated content PR. Use the [pending review worksheet](QUESTION_BANK_REVIEW.md); the current questions remain placeholders until individually approved.
