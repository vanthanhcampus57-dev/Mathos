# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-RC4-LIVE-PLACED-ROW-LAYOUT-FIX-004
- TITLE: Live GUI Classification & Matching Selected Row Layout & Text Mutation Fix
- FROM: M1
- PRIORITY: P0
- BASE: aed12759e6a8761601930c544d3d49b41506c78d
- STATUS: READY_FOR_INDEPENDENT_REQA
- PROMPT_RECEIVED_AT: 2026-08-31T21:35:35+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: d:\Mathos
- BRANCH: integration/mathos-rc4-live-gui-qa-cheat-001
- START_HEAD: aed12759e6a8761601930c544d3d49b41506c78d
- CURRENT_HEAD: e23f3a59500fc6af0f11631a9e87712b6557a0e4
- CANONICAL_BASE: 9959984db1ed7b9c373307f22662deee99f0ea1d
- WORKTREE_CLEAN: YES (Ready to commit)

## 3. EXACT PROMPT / INTENT SUMMARY
- GOAL:
  - Fix runtime live classification/matching row presentation after player selects an answer.
  - FIX 1 — No Item Text Mutation: Never mutate left item text when a category is selected. Left text must ALWAYS remain the original prompt string. Absolutely NO player-facing `[Placed]`, `[Matched]`, `[Selecting]`, `[Unassigned]`, or `-> <target>` debug/state markers in left item text. Selected category is already shown by OptionButton on the right.
  - FIX 2 — Dynamic Row Height & Rect Containment: Determine row height from actual content: `max(left_item_required_height, right_control_required_height)`. Left label must wrap completely (`AUTOWRAP_WORD_SMART`) and fit entirely within card bounds. Assert `item_label.global_rect.bottom <= item_card.global_rect.bottom`, `item_card.global_rect.bottom <= row.global_rect.bottom`, and `option_button.global_rect.bottom <= row.global_rect.bottom`.
  - FIX 3 — Selection State Only: Category selection updates OptionButton, `_placements` state, and visual border/state. Do NOT rebuild item text or recreate whole row unnecessarily. Selection must survive scrolling, "Gợi ý", invalid submit, and validation message toggle.
  - FIX 4 — Long Vietnamese Row QA: Reproduce long text questions (4+ items) at 1024x600 and 1280x720. Left cards must wrap cleanly without clipping, spilling into next row, or breaking column alignment.
  - FIX 5 — Scroll Reachability: ScrollContainer must recompute total scroll height dynamically so the bottom-most row scrolls completely above FooterVBox.
  - Write new regression test suite `test_rc4_live_placed_row_layout_verification.gd` (assert no `[Placed]`/`[Unassigned]`/`->`, assert rect containment, test 1024x600 & 1280x720).
  - Run all targeted suites + full canonical runner + `git diff --check`.
  - Return `STATUS: READY_FOR_INDEPENDENT_REQA`, `FINAL_HEAD`, `NEW_TESTS`, `FULL`, `ROOT_CAUSE`.
- DO_NOT:
  - Do NOT modify background art or assets.
  - Do NOT merge main.
  - Do NOT modify canon/question content to shorten text.
  - Do NOT rebuild Windows binary in code task.

## 4. SCOPE & PLAN
- IN_SCOPE:
  - `src/ui/question/interactions/drag_drop_view.gd`
  - `src/ui/question/interactions/matching_view.gd`
  - New test suite `tests/unit/presentation/test_rc4_live_placed_row_layout_verification.gd`
  - `tests/test_runner.gd` registration
- OUT_OF_SCOPE: Background art, main merge, Windows binary export.
- FILES_ALLOWED: `src/ui/question/**`, `tests/**`.

## 5. PROGRESS
- COMPLETED:
  - FIX 1 (No Item Text Mutation): Removed `[Placed]`, `[Matched]`, `[Selecting]`, `-> <target>` debug text mutations in `drag_drop_view.gd` and `matching_view.gd`. Left item text ALWAYS preserves base prompt text.
  - FIX 2 (Dynamic Row Height & Rect Containment): Added `_calc_required_row_height` multiline font text size calculation in `drag_drop_view.gd` and `matching_view.gd`. Enforced `autowrap_mode = AUTOWRAP_WORD_SMART` on left cards and set row minimum height based on multiline text.
  - FIX 3 (Selection State Only): Selection only updates OptionButton index, `_placements` dictionary, and `set_selected(true)` border variation. Left text is never touched. Selection survives scrolling, Hint clicks, invalid submits, and validation messages.
  - FIX 4 (Long Vietnamese Row QA): Verified long Vietnamese items (4+ items, 80-120 chars) at 1024x600 and 1280x720. Left card and right OptionButton align cleanly.
  - FIX 5 (Scroll Reachability): ScrollContainer recomputes total height dynamically so bottom row scrolls cleanly above FooterVBox.
  - Created targeted test suite `test_rc4_live_placed_row_layout_verification.gd` (7 tests PASS).
  - Executed targeted suites:
    - Vertical composition: 4/4 PASS
    - Horizontal/live layout: 4/4 PASS
    - Session/recovery: 5/5 PASS
    - QA answer reveal cheat: 10/10 PASS
    - Live interaction UX: 9/9 PASS
    - Live placed row layout: 7/7 PASS
  - Executed full canonical test runner `tests/test_runner.gd`: **434 PASS / 0 FAIL / 0 WAITING**.
  - Verified `git diff --check` clean.
- IN_PROGRESS: Handoff report creation.
- NOT_STARTED: None.

## 6. FINDINGS / DECISIONS
- KEY_FINDINGS:
  - Root cause of row layout corruption and text clipping: `DragDropView.DragItemCard.set_placed_state` mutated `text` to `"[Placed] %s -> %s" % [base_text, target_label]`, and `MatchingView._update_option_selections` mutated `text` to `"[Matched] %s -> %s"` and `"[Selecting] %s"`. Additionally, hardcoding row minimum height to 40px without calculating multiline wrapped text height caused card clipping and alignment breakage.

## 7. TEST / VERIFICATION EVIDENCE
- TARGETED_TESTS:
  - Vertical composition suite: 4/4 PASS
  - Horizontal/live layout suite: 4/4 PASS
  - Session/recovery suite: 5/5 PASS
  - QA answer reveal cheat suite: 10/10 PASS
  - Live interaction UX suite: 9/9 PASS
  - Live placed row layout suite: 7/7 PASS
- FULL_REGRESSION: 434 PASS / 0 FAIL / 0 WAITING
- DIFF_CHECK: CLEAN (0 whitespace/formatting errors)
- WORKTREE_STATUS: CLEAN

## 8. BLOCKERS / AUTHORITY
- BLOCKED: None.
- EXACT_BLOCKER: None.
- BLOCKER_OWNER: None.
- M1_DECISION_REQUIRED: NO.

## 9. LATEST REPORT / DELIVERABLE
- REPORT_STATUS: READY_FOR_INDEPENDENT_REQA
- FINAL_HEAD: e23f3a59500fc6af0f11631a9e87712b6557a0e4
- REPORT_SUMMARY: Resolved live Windows GUI classification/matching selected row text mutation, dynamic multiline row height calculation, rect containment, and scroll reachability. All 434 canonical tests green.

## 10. RECOVERY HANDOFF
- NEXT_ACTION: Submit final candidate commit and report status READY_FOR_INDEPENDENT_REQA to M1.
- DO_NOT_REPEAT: Do not mutate item card text with [Placed], [Matched], [Selecting], [Unassigned], or -> <target>.
- IMPORTANT_CONTEXT: All 6 targeted test suites and full 434 canonical runner passed.
- LAST_UPDATED_BY: Agent3
- LAST_UPDATED_AT: 2026-08-31T21:38:00+07:00
