# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-ULTIMATE-RELEASE-FINAL-TUNING-LOCK-240K2
- TITLE: Bake Human Final Approved Ultimate Release Transforms into Debug LAB
- FROM: User / P0 HUMAN FINAL VISUAL LOCK
- PRIORITY: P0 / HUMAN FINAL VISUAL LOCK
- BASE: 04dfcd2fbbef1f82c1e556bc86116d383daf6a07
- STATUS: READY_FOR_FINAL_HUMAN_RELEASE_REVIEW
- PROMPT_RECEIVED_AT: 2026-09-18T15:43:45+07:00
- UPDATED_AT: 2026-09-18T15:56:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 04dfcd2fbbef1f82c1e556bc86116d383daf6a07
- CURRENT_HEAD: 4870d8d754ac8a2ab7f9def8678374cc96240b3b
- FINAL_HEAD: 4870d8d754ac8a2ab7f9def8678374cc96240b3b
- CANONICAL_BASE: 04dfcd2fbbef1f82c1e556bc86116d383daf6a07
- PRODUCTION_SOURCE_CHANGED: NO (res://src/ completely untouched)
- COMBAT_LAB_CHANGED: NO (res://labs/stochas_combat_ui/ completely untouched)
- ASSET_BYTES_EDITED: NO (PNG hashes 100% unchanged)

## 3. GOAL & REQUIREMENTS
- Bake exact Human-Approved ULTIMATE_RELEASE transforms into Animation Debug LAB:
  - F01: scale = 0.9807, x = 179.00, y = 49.00
  - F02: scale = 1.0000, x = 182.00, y = 50.00
  - F03: scale = 1.1089, x = 180.00, y = 50.00
  - F04: scale = 0.9423, x = 180.00, y = 62.00
  - F05: scale = 1.0037, x = 180.00, y = 50.00
  - F06: scale = 1.0000, x = 180.00, y = 50.00
  - F07: scale = 1.0000, x = 180.00, y = 50.00
  - F08: scale = 1.0000, x = 180.00, y = 50.00
- Startup Behavior:
  - Fresh launch MUST use committed HUMAN FINAL Release transforms from source (FINAL_RELEASE_TRANSFORMS).
  - Do NOT silently auto-load stale user://stochas_ultimate_release_tuning.json on fresh startup.
- Reset Behavior:
  - RESET FRAME: restore selected Release frame to its HUMAN FINAL value.
  - RESET ALL: restore F01..F08 to HUMAN FINAL values.
- Copy Tuning Values:
  - Output exact active values in F01..F08 format.
- Strictly Preserve:
  - Release playback sequence (F01..F08, 0.10s/frame, ~0.80s, HOLD F08 on LOOP OFF, wrap to F01 on LOOP ON).
  - Release ghost mapping (F01->Charge F06, F02..F08->Release F0(x-1) with FINAL transform of referenced Release frame).
  - Charge: ABSOLUTE LOCK (100% untouched).
- Prohibited Scope:
  - DO NOT edit PNG images.
  - DO NOT touch production code (
es://src/).
  - DO NOT touch Combat LAB (
es://labs/stochas_combat_ui/).
  - DO NOT push to remote.

## 4. ACCEPTANCE GATES
- GATE 1: Fresh launch defaults to exact HUMAN-approved final transforms F01..F08 without reading user:// JSON. [PASS]
- GATE 2: RESET FRAME and RESET ALL restore exact HUMAN-approved final transforms F01..F08. [PASS]
- GATE 3: COPY TUNING VALUES outputs exact approved F01..F08 transforms in default state. [PASS]
- GATE 4: Reference ghost for F02..F08 applies final approved transform of reference frame F0(x-1). [PASS]
- GATE 5: Release playback sequence & timing 100% preserved (0.10s/frame, hold F08 on LOOP OFF, wrap F01 on LOOP ON). [PASS]
- GATE 6: ULTIMATE_CHARGE sequence, transforms, flash, and tuner 100% preserved. [PASS]
- GATE 7: Headless test runner updated with Task 240K2 assertions and passes 100%. [PASS]
- GATE 8: Combat LAB regression suite passes 100%. [PASS]

## 5. RECENT PROMPT LOG
- 2026-09-18 15:43 [MATHOS-STOCHAS-ULTIMATE-RELEASE-FINAL-TUNING-LOCK-240K2]: Human approved authoritative Release transforms F01..F08 (F01: 0.9807/179/49, F02: 1.0000/182/50, F03: 1.1089/180/50, F04: 0.9423/180/62, F05: 1.0037/180/50, F06..F08: 1.0000/180/50). Baked into source, startup defaults to source final values without auto-loading user JSON, updated resets, updated ghost reference transform, updated runner test suite, verified clean local commit 4870d8d754ac8a2ab7f9def8678374cc96240b3b.
