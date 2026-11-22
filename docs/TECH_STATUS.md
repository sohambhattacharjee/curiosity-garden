# Technical implementation status

Implemented offline: parent setup, one local profile, PIN-protected settings/reports, grade selection, balanced mixed rounds, independent K–5 adaptation, ten-correct promotion, easier questions after incorrect/unsure responses, delayed missed-question reviews, approved calibration bounds, explanations, score-free recap, persistent foreground session caps and fixed breaks, 90-day detail retention, and local-only storage.

The reading/insights follow-up adds capped larger text, standard/rounded font preferences, question controls visible together, 7/30/90-day report filters, daily time summaries from the update onward, concrete practice facts, PIN changes requiring the current PIN, and a parent content-status summary. Production logic retains the required 95% per-file and aggregate unit coverage floor. Debug and Release builds are required checks.

The question bank has its own draft PR and review worksheet; the implementation continues to use draft placeholders. A reviewed bank with sufficient difficulty/reading coverage is a content release gate, not a reason to mark placeholders reviewed.

Before a family-ready release, complete the physical-device, VoiceOver/contrast, installation/update, restart/break, and failure-recovery checks in VALIDATION.md. No maintainer App Store release or monetization is planned; the MIT license is unchanged.
