# Curiosity Garden — confirmed MVP requirements

This document records product decisions from the requirements interview. It describes planned behavior; it does not claim that these features have been implemented or validated. Remaining choices are tracked in [OPEN_DECISIONS.md](OPEN_DECISIONS.md).

## Purpose and scope

- An educational trivia game for children in kindergarten through grade 5.
- Support both iPhone and iPad, with large, readable text and easy-to-tap answer choices.
- Maintainer builds are for the owner's family, with no monetization.
- Public, open-source GitHub project named `curiosity-garden`, licensed under MIT.
- No maintainer App Store release is planned.
- Others may adapt and publish their own versions under MIT, including on the App Store.
- Acknowledgment, a repository link, and a GitHub star are friendly, optional requests. They add no license conditions.
- The experience should support healthy stopping rather than encourage prolonged or compulsive play.

## Setup and parent access

- One child profile per device.
- A parent chooses the starting grade during setup.
- A separate, parent-created PIN protects grade changes, settings, and reports.
- Parent reports are outside the child's play experience.
- The selected grade determines the session cap, round maximum, and reading expectations. Subject difficulty can evolve separately.

## Questions and content

- An even mix of school subjects and general knowledge.
- Questions remain mixed across subjects and categories, including when one subject needs easier questions.
- School subjects follow general U.S. grade-level expectations, without targeting a particular state's curriculum.
- Every question offers two, three, or four answer choices. The question's content and difficulty determine the number of choices.
- A reviewed question bank is bundled with the app and works offline. New content arrives through app updates for the MVP.
- Missed questions and questions marked “I'm not sure” return occasionally in later sessions, mixed with fresh questions.
- No runtime AI question generation or downloadable content service in the MVP.
- No built-in read-aloud for the MVP. Some early readers may need adult assistance.
- Simple educational visuals, such as shapes, counting objects, and basic diagrams, appear when they help explain a question.
- Individual questions have no time limit. Only the overall session cap applies.

## Adaptive difficulty

- Track each subject's difficulty independently.
- Start from the parent-selected grade; each subject can adapt across the full K–5 range.
- Keep wording readable for the selected grade as subject content changes.
- After ten consecutive correct answers in a subject, increase that subject's difficulty quietly.
- Answers in other subjects do not affect a subject's correct-answer streak.
- Preserve subject streaks across rounds and sessions.
- An incorrect answer leads to an easier next question in that subject and breaks that subject's correct-answer streak.
- Include an “I'm not sure” button. It reveals the correct answer and explanation, resets the subject's correct-answer streak, and makes its next question easier.
- Give children no indication that difficulty has changed.
- The size of a difficulty step, level boundaries, and behavior at the K and grade-5 limits still require specification.

## Feedback and rounds

- After an incorrect answer, show the correct answer and a short explanation.
- Wait for the child to tap “Next” before continuing after this feedback.
- A normally completed round has at least ten questions.
- Extend a round only for difficulty calibration, when the app is still establishing appropriate difficulty.
- Additional questions are bounded by the following limits, based on the selected grade:

| Selected grade | Minimum questions | Maximum questions |
| --- | ---: | ---: |
| K–2 | 10 | 15 |
| 3–5 | 10 | 20 |

- The session cap takes precedence and can end a round before its normal minimum.
- End a round with a gentle recap of one or two facts from that round, without a score.
- The precise calibration and round-ending algorithm remains open. The ten-correct promotion rule remains a separate requirement.

## Session limits and breaks

Use these fixed session caps for the MVP. Parent customization of the caps is outside the MVP.

| Selected grade | Maximum foreground session time |
| --- | ---: |
| K | 20 minutes |
| 1 | 25 minutes |
| 2 | 30 minutes |
| 3 | 40 minutes |
| 4 | 50 minutes |
| 5 | 60 minutes |

- The session timer spans rounds; starting another round does not reset it.
- Count foreground time on child-facing screens. Time away from the app pauses the allowance.
- Reopening the app within thirty minutes resumes the remaining allowance.
- Thirty uninterrupted minutes away from play starts a fresh session, including when the child stopped before reaching the cap.
- Reaching the session cap ends play and requires a thirty-minute break.
- The MVP uses a fixed break without a parent override.
- The time cap is firm and can end an in-progress round.
- Daily allowances are left to parents' use of iOS Screen Time; the app's own limit is per session.
- Session accounting must survive app closure so reopening cannot create a fresh allowance before the required break.
- Keep the ending calm, without prompts to keep playing.

## Parent reports and storage

- Provide a simple overview, with optional question-by-question history.
- The overview includes accuracy by subject, difficulty trends, areas to practice, and time spent.
- Question-level detail includes the question, the child's answer, the correct answer, and the date.
- Retain detailed answer history for ninety days. Saved subject difficulty and streaks continue across sessions.
- Keep reports behind the parent PIN and outside child-facing play screens.
- Store the profile, learning history, and reports locally on the device.
- No account, internet connection, or cross-device synchronization is required for the MVP.
- iPhone and iPad maintain separate profiles, learning histories, session timers, and reports.
- Keep actual child progress and reports outside the public repository.

## Visual direction

A minimal cream-and-sage interface, with muted blue accents and dark text.

| Role | Color | Hex |
| --- | --- | --- |
| Background | Warm cream | `#FAF7F0` |
| Question card | White | `#FFFFFF` |
| Answer buttons | Soft sage | `#E3EFE7` |
| Secondary accent | Mist blue | `#E7EDF8` |
| Primary action | Deep green | `#356653` |
| Text | Dark charcoal | `#24343A` |

- Use readable typography and generous spacing.
- Pair answer-state colors with words or icons.
- The proposed dark text on cream, sage, and blue, and white text on deep green, exceed a 4.5:1 calculated contrast ratio. This is a palette check, not a completed UI accessibility audit.
- Accessibility behavior and appearance variants must be checked in the implemented interface.
