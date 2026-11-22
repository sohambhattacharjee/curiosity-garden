# Open decisions

These details are not yet approved product requirements. Resolve them through the continuing one-question-at-a-time interview where product preferences matter; document routine implementation choices separately.

## Distribution

- Minimum iOS/iPadOS versions, supported device models, and orientation behavior.
- Development, family installation, and family-build update workflow.

## Learning and content

- Exact subject and category taxonomy, and how to enforce the even school/general-knowledge mix.
- Question-bank size and coverage across subjects, content difficulty, and selected-grade reading needs.
- Original question authorship, fact sources, review ownership, and correction workflow. No completed bank is present yet.
- Difficulty steps within and between grades; handling the lowest and highest available questions.
- How “difficulty calibration” is measured and when it extends or ends a round, while preserving the ten-correct promotion rule.
- Repetition avoidance and the exact timing and frequency of missed-question review in later sessions.
- Correct-answer feedback, and how optional visuals support the text without revealing answers.

## Timing and reports

- Precise handling of parent-area time, interruption, clock changes, device restart, and incomplete rounds.
- Whether a partially completed question resumes after a short interruption or after a mandatory break.
- Parent-report date ranges, summary retention, deletion, and any export controls. Detailed answer history is retained for ninety days.
- How “I'm not sure,” unanswered questions, and incomplete rounds appear in accuracy and history.
- PIN length, forgotten-PIN recovery, and protection against repeated guesses.

## Delivery

- App architecture and local persistence format.
- Build, automated checks, and device-test plan.
- Content accessibility, Dynamic Type, VoiceOver, appearance variants, and contrast verification. The selected MVP excludes an in-app read-aloud feature.

## Implementation follow-up

See [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md) for the documented baseline choices. The owner approved extending rounds only after difficulty changes, with two subsequent answers at each changed subject's new level, bounded by the selected grade maximum. Paired extensions preserve the even mix. The other entries above remain a backlog of product refinements and release verification, not claims that a reviewed bank or accessibility audit exists.
