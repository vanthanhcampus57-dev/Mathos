# Agent1 — RECOVERY NOTE

> Canonical recovery note for Agent1. This file is maintained as a complete, authoritative state ledger for Agent1.

## 1. CURRENT TASK
- TASK_ID: MATHOS-RC4-QA-CHEAT-TYPE-AWARE-ANSWER-REVEAL-FIX-003
- TITLE: Type-Aware and Human-Readable QA Answer Reveal Fix
- FROM: M1
- PRIORITY: P0
- STATUS: READY_FOR_INDEPENDENT_REQA
- PROMPT_RECEIVED_AT: 2026-08-31T23:40:49+07:00
- ACTIVE_GOAL: Make QA answer reveal cheat 100% type-aware and human-readable for all supported interaction types (multiple choice, input, matching, classification/drag_drop). Ensure canonical answer resolution never leaks raw implementation IDs (e.g. `[opt_a]`, internal option/target/item IDs) or serialized DTO structures, and always reflects the CURRENT active question without stale answer retention across transitions.

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: d:\Mathos
- BRANCH: detached HEAD (at a40a7d0dc871b9187a42b3ca4e406d0a3dc23288)
- START_HEAD: 21c6cdc389f5c764301c82d1fb96ce8f52cac619 (Base HEAD)
- CURRENT_HEAD: a40a7d0dc871b9187a42b3ca4e406d0a3dc23288
- CANONICAL_BASE: 48ede1db891e334a04e679bb906cfbebfe3d135c (Release Candidate 1 Base)
- WORKTREE_CLEAN: TRUE

## 3. EXACT PROMPT / INTENT SUMMARY
- GOAL: Make QA answer reveal TYPE-AWARE and HUMAN-READABLE for every supported question type.
- ACCEPTANCE_GATES:
  1. Base commit is 21c6cdc389f5c764301c82d1fb96ce8f52cac619.
  2. Canonical answer resolution for multiple choice / single choice, matching, classification / drag_drop, and input.
  3. Never display raw implementation IDs (e.g. `[opt_a]`, internal option/target/item IDs, or serialized answer_spec structures).
  4. Single-choice: Show human-readable option label/text (e.g. `ĐÁP ÁN ĐÚNG: A. Gieo một con xúc xắc...`).
  5. Classification/matching: Show complete readable mapping with bullet points (`• Item ➔ Category`).
  6. Rebound to CURRENT question with zero stale answer retention across transitions (MCQ ➔ classification, classification ➔ MCQ, question ➔ next question, stage transition).
  7. Reveal remains strictly QA-only (no auto-select, no auto-submit, no evaluator mutation, no progress/reward/save mutation, no normal-mode answer leak).
  8. New regression tests specifically proving option ID resolution to text, complete item-category mappings, complete pair mappings, no stale answers across question switches, and no raw IDs visible.
  9. Do NOT touch assets/backgrounds, do NOT merge main, do NOT build Windows yet.
- DEPENDENCIES: Base commit 21c6cdc389f5c764301c82d1fb96ce8f52cac619.

## 4. SCOPE
- IN_SCOPE: `src/ui/qa/qa_answer_formatter.gd`, `src/ui/qa/qa_answer_reveal_overlay.gd`, `src/app/app_root.gd`, `tests/unit/presentation/test_qa_answer_reveal_cheat.gd`, `tests/test_runner.gd`, `Agent recovery/Agent1.md`.
- OUT_OF_SCOPE: Gameplay evaluators, content definitions, assets, backgrounds.
- FILES_ALLOWED:
  - src/ui/qa/qa_answer_formatter.gd
  - src/ui/qa/qa_answer_reveal_overlay.gd
  - src/app/app_root.gd
  - tests/unit/presentation/test_qa_answer_reveal_cheat.gd
  - tests/test_runner.gd
  - Agent recovery/Agent1.md
- FILES_CHANGED:
  - src/app/app_root.gd
  - src/ui/qa/qa_answer_formatter.gd
  - src/ui/qa/qa_answer_reveal_overlay.gd
  - tests/test_runner.gd
  - tests/unit/presentation/test_qa_answer_reveal_cheat.gd
  - Agent recovery/Agent1.md

## 5. PROGRESS
- COMPLETED:
  - Checked out base commit 21c6cdc389f5c764301c82d1fb96ce8f52cac619
  - Traced root cause of raw `[opt_a]` display and stale question answer retention
  - Added `_qa_overlay.on_question_changed(_current_question_id)` call in `AppRoot._start_next_question_in_stage()`
  - Refactored `QaAnswerRevealOverlay._fetch_and_format_current_answer()` to dynamically inspect `QuestionService.get_active_question()` and `_catalog.get_question(qid)` for full question definition and `answer_spec`
  - Refactored `QaAnswerFormatter`:
    - Resolved `multiple_choice` option IDs (`opt_a`, `opt_b`) to human-readable letter prefixes and option texts (`A. Gieo một con xúc xắc...`)
    - Resolved `matching` item IDs (`item_l1`, `item_r1`) to human-readable left and right item texts (`• Gieo 1 đồng xu cân đối ➔ 2 kết quả`)
    - Resolved `classification` / `drag_drop` item & target IDs (`item_1`, `target_1`) to human-readable item texts and category labels (`• Bốc ngẫu nhiên 1 viên bi ➔ Phép thử ngẫu nhiên`)
  - Added test scenario `QA-CHEAT-013` (type-aware answer reveal across question transitions with zero raw IDs and zero stale data)
  - Updated test runner registration for `RC4 QA Answer Reveal Cheat` suite from 12 to 13 tests
  - Re-ran targeted QA cheat test suite (`test_qa_answer_reveal_cheat.gd`): 13 / 13 PASS
  - Re-ran full canonical test runner (`test_runner.gd`): 437 PASS / 0 FAIL / 0 WAITING
  - Verified `git diff --check`: Exit code 0 (clean)
  - Committed candidate HEAD `a40a7d0dc871b9187a42b3ca4e406d0a3dc23288`
- IN_PROGRESS: None.
- NOT_STARTED: None.

## 6. FINDINGS / DECISIONS
- ROOT_CAUSE:
  1. In `QaAnswerRevealOverlay._fetch_and_format_current_answer()`, when `q_res` from `AppRoot` was checked, `q_def.get("answer_spec")` was checked for dictionary type but was never assigned to `answer_spec`. Additionally, presentation-safe DTO `question` objects strip `answer_spec`. If catalog lookup failed or if dynamic QGen questions were active, `answer_spec` remained empty and `QaAnswerFormatter` fell back to raw ID formatting.
  2. In `AppRoot._start_next_question_in_stage()`, `_qa_overlay.on_question_changed(_current_question_id)` was not invoked when starting a new question. Consequently, `_qa_overlay` retained the stale `_current_question_id` from the previous question.
  3. `QaAnswerFormatter` lacked helper maps to resolve internal item IDs (`item_1`, `target_1`, `item_l1`, `item_r1`) to human-readable text labels (`Bốc ngẫu nhiên 1 viên bi ➔ Phép thử ngẫu nhiên`).
- ARCHITECTURE_DECISIONS:
  - `QaAnswerRevealOverlay` queries `QuestionService.get_active_question()` directly to obtain the unstripped authoritative question dictionary (including `answer_spec` and `interaction_payload`).
  - `QaAnswerFormatter` accepts both `answer_spec` and `question_dict` to build lookup tables mapping internal IDs to human-readable Vietnamese text labels for `multiple_choice`, `matching`, and `drag_drop` / `classification`.

## 7. TEST / VERIFICATION EVIDENCE
- TARGETED_TESTS:
  - `tests/unit/presentation/test_qa_answer_reveal_cheat.gd`: 13 / 13 PASS
- FULL_REGRESSION:
  - `tests/test_runner.gd`: 437 PASS / 0 FAIL / 0 WAITING
- DIFF_CHECK: Clean (`git diff --check` returned 0).

## 8. BLOCKERS / AUTHORITY
- BLOCKED: FALSE
- EXACT_BLOCKER: None
- BLOCKER_OWNER: N/A
- M1_DECISION_REQUIRED: Authorize independent Re-QA / build export.

## 9. LATEST REPORT / DELIVERABLE
- REPORT_STATUS: READY_FOR_INDEPENDENT_REQA
- BASE_HEAD: 21c6cdc389f5c764301c82d1fb96ce8f52cac619
- FINAL_HEAD: a40a7d0dc871b9187a42b3ca4e406d0a3dc23288
- WORKTREE_CLEAN: YES
- QA_CHEAT_TESTS: 13/13 PASS
- FULL: 437 PASS / 0 FAIL / 0 WAITING
- DIFF_CHECK: CLEAN
- FILES_CHANGED:
  - src/app/app_root.gd
  - src/ui/qa/qa_answer_formatter.gd
  - src/ui/qa/qa_answer_reveal_overlay.gd
  - tests/unit/presentation/test_qa_answer_reveal_cheat.gd
  - tests/test_runner.gd
- ROOT_CAUSE: `QaAnswerRevealOverlay` retained stale question IDs on `_start_next_question_in_stage()`, and `QaAnswerFormatter` printed raw internal IDs (`[opt_a]`) due to missing payload lookup maps for item/target texts.

## 10. RECOVERY HANDOFF
- NEXT_ACTION: Independent Re-QA audit or Windows release build export.
- DO_NOT_REPEAT: Do not output raw internal IDs. Always resolve item/target IDs to human-readable text.
- LAST_UPDATED_BY: Agent1
- LAST_UPDATED_AT: 2026-08-31T23:44:20+07:00

## 11. RECENT PROMPT LOG

### Prompt 17
- RECEIVED_AT: 2026-08-31T23:40:49+07:00
- TASK_ID: MATHOS-RC4-QA-CHEAT-TYPE-AWARE-ANSWER-REVEAL-FIX-003
- ONE_LINE_INTENT: Make QA answer reveal type-aware and human-readable for all question types without raw internal IDs into candidate HEAD a40a7d0dc871b9187a42b3ca4e406d0a3dc23288.
- RESULT / CURRENT_STATE: READY_FOR_INDEPENDENT_REQA (13/13 QA Cheat PASS, 437/437 Full Suite PASS, git diff --check clean).
- HEAD_AFTER_WORK: a40a7d0dc871b9187a42b3ca4e406d0a3dc23288
