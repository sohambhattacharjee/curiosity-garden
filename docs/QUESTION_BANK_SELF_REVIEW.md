# Critical author self-review — 2026-11-22

This is an author self-review of the content PR and its review workflow. It is not an independent human content approval. The automated checks cover all 1,440 items. The targeted manual pass focused on arithmetic ambiguity, plant structures, astronomical claims, provisional reading targets, and whether review packets faithfully show the bundled questions.

## Findings addressed

| Finding | Correction |
| --- | --- |
| `cg-v1-nature-4-002` called rose projections true thorns. | Changed the wording to **prickles**, clarified the common loose usage, and linked the [Smithsonian rose reference](https://gardens.si.edu/wp-content/uploads/2021/03/rose-modern.pdf). |
| Four level-1 day/night questions treated the daily cycle as universal; four level-5 examples lacked a location qualification. | Added distinct examples, an explicit polar-day question, and a qualification for the ordinary daily cycle. Retired level-1 IDs ending `008`, `018`, `028`, and `038`; the replacement tasks use `cg-v1-science-1-041` through `044`. Linked [NASA's explanation of day/night and polar exceptions](https://www.nasa.gov/learning-resources/for-kids-and-students/what-is-earth/). |
| The review packets could become stale after a JSON edit, leaving reviewers with an obsolete answer key or explanation. | Added a required CI check comparing every packet entry with the JSON. Tests prove it rejects drift in prompts, choices, keys, explanations, reading targets, status, sources, and packet placement, as well as missing or duplicate entries. Owner notes remain editable. |

Earlier authoring checks also corrected ambiguous unit-fraction division notation, a place-value prompt with a repeated digit, and a mass-conservation question that omitted the bag's mass from its initial total. Exact arithmetic-key checks and the complete review packets preserve those corrections.

## Checks and limits

- The bank contains exactly 1,440 distinct prompts and stable IDs, with 40 items per subject/difficulty cell. Each cell has ten related skill/topic families with four exercises per family.
- Choices, keys, reference leads, honest review status, and length bounds pass the offline audit. Eight or more provisional short-language candidates exist at each subject/difficulty cell. That numerical floor does not establish K readability.
- Integration tests cover all selected-grade reading ceilings, exact-level selection, maximum round capacity, the even school/general mix, and within-round uniqueness.
- The unit coverage requirement remains 95% overall and per production logic file. No adaptation, timer, PIN, or draft-release gate implementation is changed.
- Human verification of every fact/key, grade placement, reading demand, distractor, source/provenance, screen fit, and VoiceOver behavior is still outstanding. A link or a passing test is not content approval. Some generated distractors and related exercises may need pedagogical revision.

I found no remaining mechanical blocker to opening human review after the corrections. The PR can be marked ready for review while **all 1,440 questions remain draft**. This does not make the content family-release ready and does not authorize merging it before the owner's content review.

Start with the [36 review packets](QUESTION_BANK_REVIEW.md). Keep the JSON and packets synchronized while making corrections; record actual review metadata only after a question is approved.
