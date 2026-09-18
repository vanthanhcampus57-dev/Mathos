# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-ULTIMATE-RELEASE-FINAL-TUNING-RELOCK-240K3
- TITLE: Relock New Human Final Approved Ultimate Release Transforms into Debug LAB
- FROM: User / P0 HUMAN FINAL VISUAL RELOCK
- PRIORITY: P0 / HUMAN FINAL VISUAL RELOCK
- BASE: 00000ebeb48c4730c73e0b2098b74d880321ceae
- STATUS: READY_FOR_FINAL_HUMAN_RELEASE_REVIEW
- PROMPT_RECEIVED_AT: 2026-09-18T16:37:56+07:00
- UPDATED_AT: 2026-09-18T16:51:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 00000ebeb48c4730c73e0b2098b74d880321ceae
- CURRENT_HEAD: f8f66e36e5e8df71a9f6448343d02a26e5884afc
- FINAL_HEAD: f8f66e36e5e8df71a9f6448343d02a26e5884afc
- CANONICAL_BASE: 00000ebeb48c4730c73e0b2098b74d880321ceae
- PRODUCTION_SOURCE_CHANGED: NO (res://src/ completely untouched)
- COMBAT_LAB_CHANGED: NO (res://labs/stochas_combat_ui/ completely untouched)
- ASSET_BYTES_EDITED: NO (PNG hashes 100% unchanged)

## 3. GOAL & REQUIREMENTS
- Relock exact NEW Human-Approved ULTIMATE_RELEASE transforms into Animation Debug LAB (supersedes 240K2):
  - F01: scale = 1.1512, x = 190.63, y = 11.22
  - F02: scale = 1.2852, x = 192.18, y = 38.38
  - F03: scale = 1.3829, x = 193.08, y = 36.92
  - F04: scale = 1.1775, x = 193.08, y = 53.28
  - F05: scale = 1.3067, x = 194.54, y = 45.64
  - F06: scale = 1.2652, x = 194.54, y = 41.28
  - F07: scale = 1.2673, x = 197.44, y = 37.65
  - F08: scale = 1.2531, x = 195.99, y = 39.83
- Startup Behavior:
  - Fresh launch MUST use committed NEW HUMAN FINAL Release transforms from source (FINAL_RELEASE_TRANSFORMS).
  - Do NOT silently auto-load stale user://stochas_ultimate_release_tuning.json on fresh startup.
- Reset Behavior:
  - RESET FRAME: restore selected Release frame to its NEW HUMAN FINAL value.
  - RESET ALL: restore F01..F08 to NEW HUMAN FINAL values.
- Copy Tuning Values:
  - Output exact NEW active values in F01..F08 format.
- Strictly Preserve:
  - Release playback sequence (F01..F08, 0.10s/frame, ~0.80s, HOLD F08 on LOOP OFF, wrap to F01 on LOOP ON).
  - Release ghost mapping (F01->Charge F06, F02..F08->Release F0(x-1) with NEW FINAL transform of referenced Release frame).
  - Charge: ABSOLUTE LOCK (100% untouched).
- Prohibited Scope:
  - DO NOT edit PNG images.
  - DO NOT touch production code (
es://src/).
  - DO NOT touch Combat LAB (
es://labs/stochas_combat_ui/).
  - DO NOT push to remote.

## 4. ACCEPTANCE GATES
- GATE 1: Fresh launch defaults to exact NEW HUMAN-approved final transforms F01..F08 without reading user:// JSON. [PASS]
- GATE 2: RESET FRAME and RESET ALL restore exact NEW HUMAN-approved final transforms F01..F08. [PASS]
- GATE 3: COPY TUNING VALUES outputs exact NEW approved F01..F08 transforms in default state. [PASS]
- GATE 4: Reference ghost for F02..F08 applies NEW final approved transform of reference frame F0(x-1). [PASS]
- GATE 5: Release playback sequence & timing 100% preserved (0.10s/frame, hold F08 on LOOP OFF, wrap F01 on LOOP ON). [PASS]
- GATE 6: ULTIMATE_CHARGE sequence, transforms, flash, and tuner 100% preserved. [PASS]
- GATE 7: Headless test runner updated with Task 240K3 assertions and passes 100%. [PASS]
- GATE 8: Combat LAB regression suite passes 100%. [PASS]

## 5. RECENT PROMPT LOG
- 2026-09-18 16:37 [MATHOS-STOCHAS-ULTIMATE-RELEASE-FINAL-TUNING-RELOCK-240K3]: Human provided NEW authoritative Release transforms F01..F08 (F01: 1.1512/190.63/11.22, F02: 1.2852/192.18/38.38, F03: 1.3829/193.08/36.92, F04: 1.1775/193.08/53.28, F05: 1.3067/194.54/45.64, F06: 1.2652/194.54/41.28, F07: 1.2673/197.44/37.65, F08: 1.2531/195.99/39.83). Supersedes 240K2 values. Replaced in source, updated runner test suite, verified clean local commit f8f66e36e5e8df71a9f6448343d02a26e5884afc.
