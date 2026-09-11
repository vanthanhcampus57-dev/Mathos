# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-HUMAN-RUNTIME-LAYOUT-ROOT-FIX-211
- TITLE: Actual mounted runtime layout forensic + root-cause fix
- FROM: User / Human Visual Blocker
- PRIORITY: P0 / HUMAN VISUAL BLOCKER
- BASE: 43a68d6ec45d32b273aaeb6611884b24f5430a05
- STATUS: COMPLETED
- PROMPT_RECEIVED_AT: 2026-09-11T13:00:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 43a68d6ec45d32b273aaeb6611884b24f5430a05
- CURRENT_HEAD: c26f13a20865c9eb5b20f434ae0ee93e6d40e816
- CANONICAL_BASE: 43a68d6ec45d32b273aaeb6611884b24f5430a05
- WORKTREE_CLEAN: TRUE

## 3. EXACT PROMPT / INTENT SUMMARY
- GOAL:
  - Eliminate all 9 human-reported exported runtime defects for STOCHAS combat screen:
    1. Huge dark translucent panel covering entire viewport.
    2. Background excessively dimmed.
    3. STOCHAS displaced to the left / buried behind overlay.
    4. Combat feed at top-left instead of bottom-left.
    5. Math Challenge behaving like modal popup centered over everything.
    6. Card row buried/dimmed inside giant overlay.
    7. Settings icon appearing around central cards instead of bottom-right.
    8. HUDs dimmed together with scene.
    9. Final screen failing to match authoritative Stitch composition (1280x720).
  - Strict preservation of Task 204 combat logic (card switching, answer resolution, damage, shield, retaliation).
  - Zero git push. Zero image generation or editing.

## 4. SCOPE & PLAN
- IN_SCOPE:
  - Root cause 1: BossCombatPanel extending PanelContainer caused direct children (including CombatFeedPanel) to be forced into full viewport (1280x720) with 88% opaque background, dimming the entire screen. Fix: convert BossCombatPanel to Control in .gd and .tscn.
  - Root cause 2: Autowrap labels with custom_minimum_size.x = 0 in QuestionPanel and PauseMenuOverlay blew up vertical height to 2354px and 1557px, throwing layout off by thousands of pixels and turning Math Challenge into a modal. Fix: define proper horizontal min sizes and unwrap objective label.
  - Root cause 3: Presentation shell VBoxContainer, MarginContainers (MainBody, QuestionHostContainer, QuestionPanelHost) margins causing 16px inset offsets in fullscreen boss mode. Fix: override margins to 0 in boss mode, ensure full 1280x720 canvas propagation.
  - Root cause 4: BottomCenterContainer positioning offset from assuming 466px width instead of actual 594px. Fix: compute exact centered position from actual combined minimum width.
- OUT_OF_SCOPE:
  - No git push. No image generation or asset modification.

## 5. PROGRESS
- COMPLETED:
  - All 4 root causes diagnosed via real mounted SceneTree inspection.
  - All 9 human runtime defects resolved.
  - Implemented `tests/unit/combat/test_stochas_actual_runtime_layout_211.gd` (13/13 PASS).
  - Ran `tests/unit/combat/test_stochas_real_runtime_interaction_204.gd` (6/6 PASS).
  - Ran `tests/unit/combat/test_stochas_exact_stitch_parity_208r.gd` (12/12 PASS).
  - Ran `tests/unit/combat/test_stochas_runtime_human_flow_196.gd` (15/15 PASS).
  - Ran canonical `tests/test_runner.gd` (All test suites passed).

## 6. FINDINGS / DECISIONS
- ROOT_CAUSES:
  1. PanelContainer child expansion: `BossCombatPanel` extended `PanelContainer`, which calls `fit_child_in_rect(c, rect)` on all direct children. Direct child `CombatFeedPanel` was forced from (240, 110) to (1280, 720) with an 88% dark background, causing defects 1, 2, 6, and 8.
  2. Word smart wrap blowout: Autowrap on labels with custom_minimum_size.x = 0 caused 2000+ px vertical expansion, displacing STOCHAS and turning question panel into a modal (defects 3, 5).
  3. Container margins: 16px default Theme margins on MarginContainers prevented full 1280x720 canvas coverage.
  4. Flow pill width offset: Flow step indicator inside BottomCenterContainer expanded container to 594px while position was calculated for 466px.
- RESOLUTIONS:
  - Changed BossCombatPanel root node and script to `Control`.
  - Added explicit horizontal min sizes (460px) and disabled unnecessary autowrap on single-line labels.
  - Overrode margins to 0 on `MainBody`, `QuestionHostContainer`, and `QuestionPanelHost` in boss combat mode.
  - Sized and centered `BottomCenterContainer` from actual combined width.

## 7. TEST / VERIFICATION EVIDENCE
- `tests/unit/combat/test_stochas_actual_runtime_layout_211.gd`: 13 / 13 PASS
- `tests/unit/combat/test_stochas_real_runtime_interaction_204.gd`: 6 / 6 PASS
- `tests/unit/combat/test_stochas_exact_stitch_parity_208r.gd`: 12 / 12 PASS
- `tests/unit/combat/test_stochas_runtime_human_flow_196.gd`: 15 / 15 PASS
- Full canonical test runner (`tests/test_runner.gd`): PASS (exit code 0)

## 8. BLOCKERS / AUTHORITY
- BLOCKED: None.
- EXACT_BLOCKER: None.
- BLOCKER_OWNER: None.
- M1_DECISION_REQUIRED: NO.

## 9. LATEST REPORT / DELIVERABLE
- REPORT_STATUS: READY_FOR_HUMAN_VERIFICATION
- FINAL_HEAD: c26f13a20865c9eb5b20f434ae0ee93e6d40e816
- REPORT_SUMMARY: Clean mounted runtime layout root-cause fix eliminating all 9 human defects with 100% preservation of Task 204 combat logic and all existing test suites passing.

## 10. RECOVERY HANDOFF
- NEXT_ACTION: Commit locally and provide human report.
- DO_NOT_REPEAT: Do not push to remote. Do not modify or generate raster assets.
- IMPORTANT_CONTEXT: BASE_HEAD is 43a68d6ec45d32b273aaeb6611884b24f5430a05.
- LAST_UPDATED_BY: Agent3
- LAST_UPDATED_AT: 2026-09-11T13:56:00+07:00
