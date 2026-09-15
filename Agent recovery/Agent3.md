# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-ULTIMATE-CHARGE-START-F03-BIGGER-FLASH-239U
- TITLE: Update active ULTIMATE_CHARGE sequence to F03->F06 (~0.80s), larger entry flash bloom, and F03 reference mapping
- FROM: User / P0 HUMAN VISUAL POLISH
- PRIORITY: P0 / HUMAN VISUAL POLISH
- BASE: d23d41ebabb0b69b414b3bd1880e1d5f8e27b7e2
- STATUS: READY_FOR_HUMAN_TRANSITION_REVIEW
- PROMPT_RECEIVED_AT: 2026-09-15T16:35:22+07:00
- UPDATED_AT: 2026-09-15T16:41:30+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: d23d41ebabb0b69b414b3bd1880e1d5f8e27b7e2
- CURRENT_HEAD: PENDING_LOCAL_COMMIT
- FINAL_HEAD: PENDING_LOCAL_COMMIT
- CANONICAL_BASE: d23d41ebabb0b69b414b3bd1880e1d5f8e27b7e2
- PRODUCTION_SOURCE_CHANGED: NO (res://src/ completely untouched)
- COMBAT_LAB_CHANGED: NO (res://labs/stochas_combat_ui/ completely untouched)
- ASSET_BYTES_EDITED: NO (PNG hashes 100% unchanged)

## 3. GOAL & REQUIREMENTS
- Active Frame Sequence:
  - Remove F01 and F02 from active ULTIMATE_CHARGE playback.
  - Active sequence: F03 -> F04 -> F05 -> F06 (4 frames * 0.20s = ~0.80s visual duration at 1.00x speed).
  - DO NOT delete or edit F01/F02 PNG assets.
- Entry Flash Tuning:
  - Increase bloom size (approx 1.5x - 1.8x larger area: 680x680px size, scaling up to 1.25x peak expansion).
  - Transition: IDLE -> LARGE FLASH -> peak bloom (at ~0.06s) switches directly to F03 -> bloom fades out (0.06s-0.15s).
  - F01 and F02 are NEVER displayed during entry flash or active playback.
- Loop & Frame Stepping & Tuner:
  - LOOP OFF: F03 -> F04 -> F05 -> F06 -> HOLD F06.
  - LOOP ON: F06 -> F03 wrap (NO entry flash on loop wrap).
  - Frame stepping & tuner buttons: show F03, F04, F05, F06.
  - Reference mapping: F03 -> CANONICAL IDLE, F04 -> F03, F05 -> F04, F06 -> F05.
- Locked Transforms (F03..F06):
  - F03: scale = 1.1378, x = 195.26, y = 25.20
  - F04: scale = 1.1378, x = 208.35, y = 35.37
  - F05: scale = 1.1378, x = 214.89, y = 25.20
  - F06: scale = 1.1378, x = 190.18, y = 14.30
- Prohibited Scope:
  - DO NOT edit PNG images, regenerate assets, or touch production code (`res://src/`).
  - DO NOT touch combat LAB (`res://labs/stochas_combat_ui/`).
  - DO NOT push to remote.

## 4. ACCEPTANCE GATES
- GATE 1: IDLE -> large flash -> F03.
- GATE 2: F01 never appears.
- GATE 3: F02 never appears.
- GATE 4: Flash area visibly larger than 239T.
- GATE 5: Flash hides IDLE -> F03 cut.
- GATE 6: Active playback: F03 -> F04 -> F05 -> F06.
- GATE 7: Active visual duration ~= 0.80s.
- GATE 8: LOOP OFF holds F06.
- GATE 9: LOOP ON wraps F06 -> F03.
- GATE 10: Loop wrap has NO flash.
- GATE 11: Frame-step contains only F03..F06.
- GATE 12: F03 reference ghost = canonical IDLE.
- GATE 13: F04 reference = F03.
- GATE 14: F05 reference = F04.
- GATE 15: F06 reference = F05.
- GATE 16: Locked F03..F06 transforms unchanged.
- GATE 17: PNG hashes unchanged.
- GATE 18: Combat LAB regression PASS.

## 5. RECENT PROMPT LOG
- 2026-09-15 16:35 [MATHOS-STOCHAS-ULTIMATE-CHARGE-START-F03-BIGGER-FLASH-239U]: Human requested active sequence change to F03->F06 (~0.80s), larger entry flash bloom, and F03->IDLE reference ghost mapping. Started implementation.
