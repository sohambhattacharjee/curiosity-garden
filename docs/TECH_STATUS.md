# Technical implementation status

Implemented offline: parent setup, one local profile, PIN-protected settings/reports, grade selection, balanced mixed rounds, independent K–5 adaptation, ten-correct promotion, easier questions after incorrect/unsure responses, delayed missed-question reviews, approved calibration bounds, explanations, score-free recap, persistent foreground session caps and fixed breaks, 90-day detail retention, and local-only storage.

The reading/insights follow-up adds capped larger text, standard/rounded font preferences, question controls visible together, 7/30/90-day report filters, daily time summaries from the update onward, concrete practice facts, PIN changes requiring the current PIN, and a parent content-status summary. Production logic retains the required 95% per-file and aggregate unit coverage floor. Debug and Release builds are required checks.

The separate content PR contains 1,440 original AI-assisted drafts, with 40 per subject/difficulty cell and 36 complete owner-review packets. Structural coverage checks exercise every subject, content level, and selected reading ceiling. All questions remain draft; the labels and answer keys are not human approved. A reviewed bank with sufficient difficulty/reading coverage remains a content release gate.

Before a family-ready release, complete the physical-device, VoiceOver/contrast, installation/update, restart/break, and failure-recovery checks in VALIDATION.md. No maintainer App Store release or monetization is planned; the MIT license is unchanged.
