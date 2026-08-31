# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-RC4-LIVE-INTERACTION-UX-FIX-003
- TITLE: Live GUI Classification & Matching UX / Layout / Validation Fix
- FROM: M1
- PRIORITY: P0
- BASE: e27d732045cec5920ba61ae800dbf6487b30fdbc
- STATUS: READY_FOR_LIVE_GUI_REQA
- PROMPT_RECEIVED_AT: 2026-08-31T20:55:54+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: d:\Mathos
- BRANCH: integration/mathos-rc4-live-gui-qa-cheat-001
- START_HEAD: e27d732045cec5920ba61ae800dbf6487b30fdbc
- CURRENT_HEAD: PENDING_COMMIT
- CANONICAL_BASE: 9959984db1ed7b9c373307f22662deee99f0ea1d
- WORKTREE_CLEAN: YES (Ready to commit)

## 3. EXACT PROMPT / INTENT SUMMARY
- GOAL:
  - Fix runtime real-world UI layout, validation text, selection persistence, and valid submit flow for classification & matching questions observed during live Windows GUI playtesting at 1280x720 and 1024x600.
  - FIX 1 — Footer zero-overlap: Ensure QuestionPanel hierarchy enforces Header -> InteractionScrollContainer (flex remaining height) -> Dedicated Footer (outside scroll: ValidationMessage, Hint, Submit). Footer must NOT overlay answer rows. Validation message must NOT float over interaction rows. ScrollContainer must stop before footer. Last row must scroll completely above footer. 1024x600 & 1280x720 required viewports.
  - FIX 2 — Validation UX: Replace raw internal error key `"must_place_all requires every item exactly once"` with player-facing localized Vietnamese text: `"Hãy phân loại tất cả các mục trước khi xác nhận."`. Invalid submit must NOT advance, reset selections, flash layout, create duplicate controls, and must keep reasonable focus.
  - FIX 3 — Selection persistence audit: OptionButton selection (category choice) must persist across scrolling, pressing "Gợi ý", and invalid submits. Must not rebuild widgets or reset selection.
  - FIX 4 — Valid submit path: When all items are validly classified, pressing "Xác nhận" must run evaluator, show feedback, prevent soft-locks, and advance stage/question progression.
  - Write new regression test suite covering all required cases.
  - Run targeted test suites and full canonical runner.
  - Clean `git diff --check`.
  - Return `STATUS: READY_FOR_LIVE_GUI_REQA`.
- DO_NOT:
  - Do NOT modify background art or assets.
  - Do NOT merge main.
  - Do NOT modify canon/question content to avoid bugs.
  - Do NOT rebuild Windows binary in code task.

## 4. SCOPE & PLAN
- IN_SCOPE:
  - `src/ui/question/question_panel.tscn`, `question_panel.gd`
  - `src/ui/question/interactions/drag_drop_view.gd`, `matching_view.gd`
  - Validation error string localization in `question_panel.gd`
  - New test suite `tests/unit/presentation/test_rc4_live_interaction_ux_verification.gd`
  - `tests/test_runner.gd` registration
- OUT_OF_SCOPE: Background art, main merge, Windows binary export.
- FILES_ALLOWED: `src/ui/question/**`, `src/education/question/**`, `tests/**`.

## 5. PROGRESS
- COMPLETED:
  - FIX 1 (Footer zero-overlap): Dedicated `FooterVBox` (`VBoxContainer`, `size_flags_vertical = SIZE_SHRINK_END`) placed outside `InteractionScrollContainer`. Fixed `_ensure_ui_built()` node reparenting check in `question_panel.gd` so views remain inside `InteractionScrollContainer`. Added dynamic `custom_minimum_size.y` calculation in `drag_drop_view.gd` and `matching_view.gd`.
  - FIX 2 (Validation UX): Localized internal validation diagnostic keys (`"must_place_all requires every item exactly once"`, `"matching payload"`, `"input payload"`) to player-facing Vietnamese text (`"Hãy phân loại tất cả các mục trước khi xác nhận."`). Raw internal error key logged to console (`push_warning`) and completely hidden from player UI.
  - FIX 3 (Selection Persistence): Fixed `_ensure_ui_built` parent check so `OptionButton` selections survive scrolling, "Gợi ý" hint clicks, and invalid submits.
  - FIX 4 (Valid Submit Path): Evaluated completed classification payloads cleanly, showing correct feedback and allowing stage progression.
  - Created targeted test suite `test_rc4_live_interaction_ux_verification.gd` (9 tests PASS).
  - Executed targeted suites:
    - Vertical composition: 4/4 PASS
    - Horizontal/live layout: 4/4 PASS
    - Session/recovery: 5/5 PASS
    - QA answer reveal cheat: 10/10 PASS
    - Live interaction UX & composition: 9/9 PASS
  - Executed full canonical test runner `tests/test_runner.gd`: **427 PASS / 0 FAIL / 0 WAITING**.
  - Verified `git diff --check` clean.
- IN_PROGRESS: Handoff report creation.
- NOT_STARTED: None.

## 6. FINDINGS / DECISIONS
- KEY_FINDINGS:
  - Root cause of interaction view reparenting and footer floating in `question_panel.gd`: `_ensure_ui_built()` checked if `_active_interaction_view.get_parent() != _interaction_container` (`MarginContainer`) instead of `get_interaction_scroll_container()` (`ScrollContainer`), which caused views to be yanked out of `ScrollContainer` during hint clicks and `on_submission_failed`, overlapping the footer controls.

## 7. TEST / VERIFICATION EVIDENCE
- TARGETED_TESTS:
  - Vertical composition suite: 4/4 PASS
  - Horizontal/live layout suite: 4/4 PASS
  - Session/recovery suite: 5/5 PASS
  - QA answer reveal cheat suite: 10/10 PASS
  - Live interaction UX suite: 9/9 PASS
- FULL_REGRESSION: 427 PASS / 0 FAIL / 0 WAITING
- DIFF_CHECK: CLEAN (0 whitespace/formatting errors)
- WORKTREE_STATUS: CLEAN

## 8. BLOCKERS / AUTHORITY
- BLOCKED: None.
- EXACT_BLOCKER: None.
- BLOCKER_OWNER: None.
- M1_DECISION_REQUIRED: NO.

## 9. LATEST REPORT / DELIVERABLE
- REPORT_STATUS: READY_FOR_LIVE_GUI_REQA
- FINAL_HEAD: PENDING_COMMIT
- REPORT_SUMMARY: Resolved live Windows GUI classification/matching UX defects (footer zero-overlap, localized Vietnamese validation text, selection persistence, and valid submit flow). All 427 canonical tests green.

## 10. RECOVERY HANDOFF
- NEXT_ACTION: Submit final candidate commit and report status READY_FOR_LIVE_GUI_REQA to M1.
- DO_NOT_REPEAT: Do not check parent against MarginContainer instead of ScrollContainer when verifying UI hierarchy.
- IMPORTANT_CONTEXT: All 5 targeted test suites and full 427 canonical runner passed.
- LAST_UPDATED_BY: Agent3
- LAST_UPDATED_AT: 2026-08-31T21:03:34+07:00
