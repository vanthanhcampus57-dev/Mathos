# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-ULTIMATE-RELEASE-TUNER-BINDING-FIX-240K1
- TITLE: Fix Tuner UI & Data Binding for ULTIMATE_RELEASE F01..F08
- FROM: User / P0 HUMAN REVIEW UI BLOCKER
- PRIORITY: P0 / HUMAN REVIEW UI BLOCKER
- BASE: b9c646c5ca4be37222550c6c298bf74d4443f8da
- STATUS: READY_FOR_HUMAN_RELEASE_TUNING
- PROMPT_RECEIVED_AT: 2026-09-18T01:32:55+07:00
- UPDATED_AT: 2026-09-18T01:41:10+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: b9c646c5ca4be37222550c6c298bf74d4443f8da
- CURRENT_HEAD: 04dfcd2fbbef1f82c1e556bc86116d383daf6a07
- FINAL_HEAD: 04dfcd2fbbef1f82c1e556bc86116d383daf6a07
- CANONICAL_BASE: b9c646c5ca4be37222550c6c298bf74d4443f8da
- PRODUCTION_SOURCE_CHANGED: NO (res://src/ completely untouched)
- COMBAT_LAB_CHANGED: NO (res://labs/stochas_combat_ui/ completely untouched)
- ASSET_BYTES_EDITED: NO (PNG hashes 100% unchanged)

## 3. GOAL & REQUIREMENTS
- Fix Tuner UI & Data Binding for ULTIMATE_RELEASE:
  - Header: dynamic switching between ULTIMATE_CHARGE FRAME TUNER and ULTIMATE_RELEASE FRAME TUNER.
  - Tuner Buttons: show F01..F08 when Release selected, F03..F06 when Charge selected.
  - Live Current Frame Sync: highlight active tuner frame button as animation plays or steps.
  - Separate Release Transform Data: 8 independent transforms initialized to neutral baseline (scale = 1.0, x = 180.0, y = 50.0).
  - Separate JSON storage: user://stochas_ultimate_release_tuning.json.
  - Save/Reload/Reset/Copy controls operate state-specifically (Release vs Charge).
  - Gizmo drag & corner resize bind to active selected Release frame when in Release state.
- Strictly Preserve:
  - Release playback: F01->F08 (0.10s/frame, ~0.80s, LOOP OFF hold F08, LOOP ON F08->F01).
  - Charge: F03->F06 sequence, entry flash, transforms, timing, tuner, ghost.
- Prohibited Scope:
  - DO NOT edit PNG images.
  - DO NOT touch production code (
es://src/).
  - DO NOT touch Combat LAB (
es://labs/stochas_combat_ui/).
  - DO NOT push to remote.

## 4. ACCEPTANCE GATES
- GATE 1: ULTIMATE_RELEASE state displays ULTIMATE_RELEASE FRAME TUNER header. [PASS]
- GATE 2: Release tuner shows 8 buttons F01..F08. [PASS]
- GATE 3: Selecting Release F01..F08 previews frame, updates ghost, numeric display, and gizmo. [PASS]
- GATE 4: Runtime playback automatically highlights current frame button (F01..F08 for Release, F03..F06 for Charge). [PASS]
- GATE 5: Release transforms stored independently in user://stochas_ultimate_release_tuning.json. [PASS]
- GATE 6: Gizmo drag/resize modifies selected Release frame transform live. [PASS]
- GATE 7: COPY TUNING VALUES outputs F01..F08 for Release, F03..F06 for Charge. [PASS]
- GATE 8: Switching between Charge and Release cleanly swaps tuner UI & data without cross-binding. [PASS]
- GATE 9: Charge tuner, transforms, flash, and playback 100% preserved. [PASS]
- GATE 10: Headless test runner updated and passes 100%. [PASS]
- GATE 11: Combat LAB regression tests pass 100%. [PASS]

## 5. RECENT PROMPT LOG
- 2026-09-18 01:32 [MATHOS-STOCHAS-ULTIMATE-RELEASE-TUNER-BINDING-FIX-240K1]: Human requested fix for Tuner UI & data binding when ULTIMATE_RELEASE is selected (dedicated Release tuner F01..F08, separate transform table, separate JSON config, live frame sync, gizmo binding, copy/save/reload/reset controls). Completed implementation, headless test runner pass, combat lab regression pass, and local commit 04dfcd2fbbef1f82c1e556bc86116d383daf6a07.
