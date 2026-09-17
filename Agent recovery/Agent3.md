# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-ULTIMATE-RELEASE-WIP-LAB-INTEGRATE-240K
- TITLE: Integrate NEW HUMAN-APPROVED ULTIMATE_RELEASE F01..F08 into STOCHAS Animation Debug LAB
- FROM: User / P0
- PRIORITY: P0
- BASE: 11c3f335f0192172635444af1c33b3b07dbdd392
- STATUS: READY_FOR_HUMAN_RELEASE_PLAYBACK_REVIEW
- PROMPT_RECEIVED_AT: 2026-09-17T22:55:42+07:00
- UPDATED_AT: 2026-09-17T22:58:30+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 11c3f335f0192172635444af1c33b3b07dbdd392
- CURRENT_HEAD: PENDING_LOCAL_COMMIT
- FINAL_HEAD: PENDING_LOCAL_COMMIT
- CANONICAL_BASE: 11c3f335f0192172635444af1c33b3b07dbdd392
- PRODUCTION_SOURCE_CHANGED: NO (res://src/ completely untouched)
- COMBAT_LAB_CHANGED: NO (res://labs/stochas_combat_ui/ completely untouched)
- ASSET_BYTES_EDITED: NO (PNG hashes 100% unchanged)

## 3. GOAL & REQUIREMENTS
- Integrate new ULTIMATE_RELEASE WIP frames (F01..F08 from `res://labs/stochas_animation_debug/assets/ultimate_release_wip/`).
- Playback:
  - F01 -> F02 -> F03 -> F04 -> F05 -> F06 -> F07 -> F08
  - Default frame duration: 0.10s / frame at 1.00x speed (~0.80s total).
  - LOOP OFF: hold F08.
  - LOOP ON: F08 -> F01.
  - Old release atlas art MUST NEVER appear.
- Minimal Release Review UI:
  - UI Header / Label showing available release frames (8/8).
  - Direct frame buttons: F01..F08.
  - RELOAD RELEASE WIP button (Shortcut: J) to rescan/reload PNGs.
- Frame Stepping:
  - PREV/NEXT steps F01..F08.
  - LOOP OFF: F01 PREV holds F01, F08 NEXT holds F08.
  - LOOP ON: F01 PREV -> F08, F08 NEXT -> F01.
- Reference Ghost Mapping:
  - F01 -> approved ULTIMATE_CHARGE F06
  - F02..F08 -> Release F0(x-1)
- Strictly Preserve Charge:
  - ULTIMATE_CHARGE is HUMAN FINAL LOCKED. Keep untouched!
- Prohibited Scope:
  - DO NOT edit PNGs, resize PNGs, crop PNGs, or generate images.
  - DO NOT touch production code (`res://src/`).
  - DO NOT touch Combat LAB (`res://labs/stochas_combat_ui/`).
  - DO NOT push to remote.

## 4. ACCEPTANCE GATES
- GATE 1: Discovered 8 release WIP frames (F01..F08).
- GATE 2: Clicking ULTIMATE_RELEASE plays F01 -> F08 (~0.80s at 0.10s/frame).
- GATE 3: Old release atlas art never appears.
- GATE 4: LOOP OFF holds F08.
- GATE 5: LOOP ON wraps F08 -> F01.
- GATE 6: Frame stepping PREV/NEXT navigates F01..F08 with proper loop bounds.
- GATE 7: RELOAD RELEASE WIP button (Shortcut: J) rescans and reloads PNGs.
- GATE 8: Ghost reference mapping F01->Charge F06, F02..F08->Release F0(x-1).
- GATE 9: Charge animation, transforms, flash, timing, and tuner strictly preserved.
- GATE 10: Headless test runner updated and passes 100%.
- GATE 11: Combat LAB regression test suite passes 100%.
- GATE 12: PNG asset bytes unchanged.

## 5. RECENT PROMPT LOG
- 2026-09-17 22:55 [MATHOS-STOCHAS-ULTIMATE-RELEASE-WIP-LAB-INTEGRATE-240K]: User requested integration of new ULTIMATE_RELEASE F01..F08 WIP frames into Animation Debug LAB with 0.10s frame duration, reload button (J), frame stepping, ghost mapping, and strict preservation of ULTIMATE_CHARGE. Started implementation.
