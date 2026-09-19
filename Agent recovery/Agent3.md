# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-PRODUCTION-UI-PARITY-HOTFIX-241C
- TITLE: Restore Production Combat UI Parity Around Stochas Ultimate
- FROM: User / P0 HUMAN PRODUCTION BLOCKER
- PRIORITY: P0 / HUMAN PRODUCTION BLOCKER
- BASE: 9c6c65790258ac7c1821cddf2133e3df8e286ce0 (parent 56267393a3121089eac144720970cb5696cca65c)
- STATUS: COMPLETED
- PROMPT_RECEIVED_AT: 2026-09-19T10:08:04+07:00
- UPDATED_AT: 2026-09-19T10:30:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 9c6c65790258ac7c1821cddf2133e3df8e286ce0
- CURRENT_HEAD: PENDING_LOCAL_COMMIT
- FINAL_HEAD: PENDING_LOCAL_COMMIT
- CANONICAL_BASE: 9c6c65790258ac7c1821cddf2133e3df8e286ce0
- PRODUCTION_SOURCE_CHANGED: YES (src/ui/combat/boss_combat_panel.gd, src/ui/question/question_panel.gd, src/ui/stage/gameplay_container.gd)
- COMBAT_LAB_CHANGED: NO
- ASSET_BYTES_EDITED: NO (PNG hashes must be 100% preserved)

## 3. GOAL & REQUIREMENTS
- Fix production combat screen parity regressions observed by human in full game:
  1. Karl character missing from battlefield (HUD was present top-left, but Karl character sprite was absent).
  2. Question UI broken / incomplete (question text appeared, but answer/input area was squashed to 13px due to footer rows).
  3. Card UI wrong presentation (oversized 160x225 placeholder cards taking up 36% of screen instead of approved 106x154 Stitch cards).
- ABSOLUTE RULE: DO NOT REDESIGN. Recover and restore already designed / previously approved UI from repo/history.
- LOCK: Ultimate animation (Charge F03..F06 with entry flash, Release F01..F08 peak at F05) MUST REMAIN 100% UNCHANGED.
- LOCK: Gameplay contract (0/4 meter, 2.4s charge, 8s challenge, Dodge 0 dmg / Fail 24 dmg shield->HP).
- ZERO image generation, editing, or byte changes.
- Local commit only, DO NOT PUSH.

## 4. ACCEPTANCE GATES
- GATE 1: Root cause analysis of Karl, Question, and Card UI identified via repo archaeology. [PASS]
- GATE 2: Karl character restored to battlefield with correct side (left 50px, bottom 70px, 300x300 px, nearest filter, dodge/cast/shield/heal/hit state animations). [PASS]
- GATE 3: Question/answer UI restored: SubmitButton + HintButton arranged side-by-side in ActionHBox, InteractionScrollContainer expanded to >90px, all options visible and clickable. [PASS]
- GATE 4: Approved card UI restored: 106x154 px, ~14px gap, 466px centered row matching approved Stitch reference. [PASS]
- GATE 5: Stochas Ultimate Charge & Release visuals and transforms 100% preserved. [PASS]
- GATE 6: Gameplay contract preserved (0/4 meter, 2.4s charge, 8s challenge, Dodge 0 dmg / Fail 24 dmg). [PASS]
- GATE 7: All test suites pass (dedicated 241C, 241A, stage 1.5, parity tests, layout 211, human flow 196, labs). [PASS]
- GATE 8: Local commit created, no push, no image edits. [PASS]

## 5. FILES CHANGED
- `src/ui/combat/boss_combat_panel.gd` [MODIFIED] - Restored 106x154 card dimensions, gap 14px, centered row 466px; integrated Karl battlefield entity (300x300, nearest filter, baseline offsets, state machine with cast/shield/heal/hit/dodge, hooked to combat log & ultimate peak resolution).
- `src/ui/question/question_panel.gd` [MODIFIED] - Optimized combat layout: SubmitButton placed side-by-side with HintButton inside ActionHBox, compact combat rule footer (22px), minimum interaction scroll height (92px), corner radius 16px.
- `src/ui/stage/gameplay_container.gd` [MODIFIED] - Adjusted target height to 310px (within approved 280..330px boundary) to eliminate answer option squashing.
- `tests/unit/combat/test_stochas_real_runtime_interaction_204.gd` [MODIFIED] - Updated card dimension assertion to accept approved Stitch dimensions (106x154).
- `tests/unit/combat/test_stochas_production_ui_parity_hotfix_241c.gd` [NEW] - Dedicated test suite verifying Karl presence & state machine, unclipped question answer area, 106x154 card row, and ultimate reaction.
- `Agent recovery/Agent3.md` [MODIFIED] - Canonical recovery note updated.

## 6. TEST EVIDENCE
1. `tests/unit/combat/test_stochas_production_ui_parity_hotfix_241c.gd`: 4 / 4 PASSED
   - GATE 1: Karl battlefield entity (300x300 at (50, 350), nearest filter, state machine intact)
   - GATE 2: QuestionPanel compact footer and unclipped answer area
   - GATE 3: Tactical Card row (106x154, gap 14, centered at bottom with flow pill)
   - GATE 4: Stochas Ultimate transforms and Karl reaction integration
2. `tests/unit/combat/test_stochas_ultimate_production_port_241a.gd`: 5 / 5 PASSED
3. `tests/unit/combat/test_stage_1_5_boss_combat.gd`: 14 / 14 PASSED
4. `tests/unit/combat/test_combat_cards_visual_parity_172.gd`: 13 / 13 PASSED
5. `tests/unit/combat/test_stochas_actual_runtime_layout_211.gd`: 17 / 17 PASSED
6. `tests/unit/combat/test_stochas_exact_stitch_parity_208r.gd`: 12 / 12 PASSED
7. `tests/unit/combat/test_stochas_real_runtime_interaction_204.gd`: 6 / 6 PASSED
8. `tests/unit/combat/test_stochas_runtime_human_flow_196.gd`: 15 / 15 PASSED
9. `labs/stochas_combat_ui/run_lab_headless.gd`: 16 / 16 PASSED
10. `labs/stochas_animation_debug/run_animation_debug_headless.gd`: ALL GATES PASSED

## 7. RECENT PROMPT LOG
- 2026-09-19 10:08 [MATHOS-STOCHAS-PRODUCTION-UI-PARITY-HOTFIX-241C]: P0 blocker report from human testing full game: Karl missing from battlefield, question answer area broken/empty, card UI does not match approved design. Began root cause archaeology.
- 2026-09-19 10:30 [MATHOS-STOCHAS-PRODUCTION-UI-PARITY-HOTFIX-241C]: Resolved all 3 regressions without redesign: restored Karl battlefield entity (300x300, pixel art filter, combat animations), restructured question panel combat footer (SubmitButton side-by-side with HintButton, expanded scroll area from 13px to 124px), and restored approved 106x154 Stitch cards. All 10 test suites passed cleanly.
