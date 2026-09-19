# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-ULTIMATE-PRODUCTION-PORT-241A
- TITLE: Port Approved Stochas Ultimate Animation into Actual Production Combat Flow
- FROM: User / P0 PRODUCTION INTEGRATION
- PRIORITY: P0 / PRODUCTION INTEGRATION
- BASE: b73413a0268cb1be6ed25c3716014721c3647a40 (advanced from expected base f8f66e3 via Agent3.md amend)
- STATUS: READY_FOR_INDEPENDENT_A4_REGRESSION
- PROMPT_RECEIVED_AT: 2026-09-19T08:19:56+07:00
- UPDATED_AT: 2026-09-19T08:41:30+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: b73413a0268cb1be6ed25c3716014721c3647a40
- CURRENT_HEAD: 8da76bb9d658ef691082d91f66a88baaf27f09da
- FINAL_HEAD: 8da76bb9d658ef691082d91f66a88baaf27f09da
- CANONICAL_BASE: b73413a0268cb1be6ed25c3716014721c3647a40
- PRODUCTION_SOURCE_CHANGED: YES (src/gameplay/combat/card_combat_controller.gd, src/ui/combat/boss_combat_panel.gd)
- COMBAT_LAB_CHANGED: YES (labs/stochas_combat_ui/stochas_combat_ui_lab.gd)
- ASSET_BYTES_EDITED: NO (100% SHA256 bit-identical hash preservation)

## 3. GOAL & REQUIREMENTS
- Port locked Stochas Ultimate Animation (Charge + Release) from Animation Debug LAB into production combat flow.
- Visuals locked:
  - ULTIMATE_CHARGE: IDLE -> large cyan/white entry flash -> F03 -> F04 -> F05 -> F06 (F01/F02 never shown).
  - ULTIMATE_RELEASE: F01 -> F02 -> F03 -> F04 -> F05 (PEAK) -> F06 -> F07 -> F08.
  - Transforms: exact approved transforms from Task 239S (Charge) and Task 240K3 (Release).
- Direction: Screen-Left (<- towards Karl).
- Gameplay Contract:
  - Meter: 0/4 (+1 only after normal question).
  - Charge phase: 2.4 seconds.
  - Challenge phase: 8.0 seconds.
  - Challenge outcome: Correct -> Karl Dodge (0 dmg); Wrong/Timeout -> 24 dmg. Damage ordering: shield -> HP.
  - Normal attack damage: Bolt 8, Orb 10, Rift 12, Sweep 14, Ultimate 24.
- Assets:
  - Production must NOT load from res://labs/.
  - Copy approved PNG assets to production location without byte alteration (hashes preserved).
- Architecture:
  - Preserve existing production hooks/state machine.
  - Do NOT invent a new gameplay state machine.
  - Animation durations (0.80s charge visual, 0.80s release visual) do NOT replace gameplay timers (2.4s charge, 8s challenge).

## 4. ACCEPTANCE GATES
- GATE 1: Discovered production architecture documented (visual owner: BossCombatPanel, controller: CardCombatController). [PASS]
- GATE 2: Approved PNG assets organized in production path with bit-identical hashes (8 release frames copied, SHA256 100% match). [PASS]
- GATE 3: Production Ultimate Charge visual integrates entry flash + F03..F06 within 2.4s charge phase. [PASS]
- GATE 4: Production Ultimate Release visual plays F01..F08 facing screen-left with peak at F05. [PASS]
- GATE 5: Old production Ultimate visual completely absent (no 1-frame flash, 8-frame strip retired). [PASS]
- GATE 6: Gameplay contract preserved (2.4s charge, 8s challenge, Dodge 0 dmg / Fail 24 dmg, shield->HP). [PASS]
- GATE 7: Animation Debug LAB passes regression test 100%. [PASS]
- GATE 8: Combat LAB passes regression test 100%. [PASS]
- GATE 9: Production test suite passes 100% (5/5 on test_stochas_ultimate_production_port_241a.gd, 14/14 on test_stage_1_5_boss_combat.gd). [PASS]
- GATE 10: Local commit created, no push, no image edits. [PASS]

## 5. FILES CHANGED
- `assets/characters/bosses/dungeon_1/stochas_ultimate_release/stochas_ultimate_release_f01..f08.png` [NEW] - 8 canonical release frames.
- `src/gameplay/combat/card_combat_controller.gd` [MODIFIED] - Ultimate meter (0/4), charge/challenge triggers, 24 dmg shield->HP, Dodge 0 dmg.
- `src/ui/combat/boss_combat_panel.gd` [MODIFIED] - Production ultimate playback (entry flash, F03..F06 charge, F01..F08 release with F05 peak), safe dynamic texture loading, exact locked transforms.
- `labs/stochas_combat_ui/stochas_combat_ui_lab.gd` [MODIFIED] - Unified combat lab with approved charge & release frames, entry flash, and transforms.
- `tests/unit/combat/test_stochas_ultimate_production_port_241a.gd` [NEW] - Dedicated verification suite for Task 241A.
- `Agent recovery/Agent3.md` [MODIFIED] - Canonical recovery note updated.

## 6. TEST EVIDENCE
1. `tests/unit/combat/test_stochas_ultimate_production_port_241a.gd`: 5 / 5 PASSED
   - GATE 2: Production asset placement and bit-identical hashes
   - GATE 6: CardCombatController ultimate contracts & mechanics
   - GATE 3, 4: Authoritative Charge and Release transforms
   - GATE 1, 3, 4: BossCombatPanel playback lifecycle and signals
   - GATE 5: Clean separation, zero res://labs/ in production source
2. `labs/stochas_combat_ui/run_lab_headless.gd`: 16 / 16 GATES PASSED
3. `labs/stochas_animation_debug/run_animation_debug_headless.gd`: ALL GATES PASSED
4. `tests/unit/combat/test_stage_1_5_boss_combat.gd`: 14 / 14 PASSED
5. `tests/unit/combat/test_combat_cards_visual_parity_172.gd`: 13 / 13 PASSED
6. `tests/unit/combat/test_stage_boss_lifecycle_080.gd`: 8 / 8 PASSED
7. `tests/unit/combat/test_stochas_actual_runtime_layout_211.gd`: 17 / 17 PASSED
8. `tests/unit/combat/test_stochas_exact_stitch_parity_208r.gd`: 12 / 12 PASSED
9. `tests/unit/combat/test_stochas_real_runtime_interaction_204.gd`: 6 / 6 PASSED
10. `tests/unit/combat/test_stochas_runtime_human_flow_196.gd`: 15 / 15 PASSED

## 7. RECENT PROMPT LOG
- 2026-09-19 08:19 [MATHOS-STOCHAS-ULTIMATE-PRODUCTION-PORT-241A]: Port visually approved Stochas Ultimate animation into actual production combat flow. Preserved gameplay contracts, bit-identical assets, exact transforms. Began architectural discovery.
- 2026-09-19 08:41 [MATHOS-STOCHAS-ULTIMATE-PRODUCTION-PORT-241A]: Completed porting approved Stochas Ultimate animation into BossCombatPanel and CardCombatController. Synced Combat LAB, created dedicated test suite, verified zero regressions across 10 test suites. Ready for review.
