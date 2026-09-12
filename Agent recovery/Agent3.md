# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-STITCH-FINAL-LAB-PARITY-220L
- TITLE: Native Godot LAB parity implementation from approved final Stitch
- FROM: User / Human-Approved Visual Reference
- PRIORITY: P0 / HUMAN-APPROVED VISUAL REFERENCE
- BASE: 32760bed31744861ad48aa3cd84ec75654764e94
- STATUS: READY_FOR_FINAL_STITCH_LAB_HUMAN_REVIEW
- PROMPT_RECEIVED_AT: 2026-09-13T00:53:32+07:00
- UPDATED_AT: 2026-09-13T00:58:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 32760bed31744861ad48aa3cd84ec75654764e94
- CURRENT_HEAD: 32760bed31744861ad48aa3cd84ec75654764e94
- CANONICAL_BASE: 32760bed31744861ad48aa3cd84ec75654764e94
- PRODUCTION_SOURCE_CHANGED: NO (0 production files modified)

## 3. EXACT PROMPT / INTENT SUMMARY
- Intent: Implement native Godot LAB parity with the human-approved final Stitch visual composition.
- Viewport: 1280 x 720
- Composition Axis: Shared Center X = 690px for Question, Card Hover Detail, and Card Row.
- Locked Mathos combat numbers: Strike = 10, Defend = +8, Heal = +15, Wrong = -10.
- Question Module: 640x210 at (370, 160), 1 horizontal 4-option row.
- Hover Detail: 440x42 at (470, 486), dynamic card stats on hover/selection.
- Card Row: 4 cards at 104x158 at (461, 542), 14px gap. No permanent stat footer.
- Boss Entity: 480x520 at (800, 130), looming and raised.
- Karl Entity: Framed standee at (70, 465), Left 70px, Bottom 75px.
- Floating combat feedback: +8 GIÁP, +15 HP, -10 HP, CRITICAL!
- Zero Combat Feed. Zero production modifications.

## 4. LAB ARTIFACTS & FILES
- LAB FILES CHANGED:
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab.gd`
  - `res://labs/stochas_combat_ui/run_lab_headless.gd`
  - `labs/stochas_combat_ui/stochas_combat_ui_lab_clean.png`
  - `labs/stochas_combat_ui/stochas_combat_ui_lab_debug.png`

## 5. EXACT MEASUREMENTS & SPECIFICATIONS
- HUMAN_STITCH_REFERENCE: APPROVED
- VIEWPORT: 1280x720
- CENTER_INTERACTION_X: 690.0 px
- QUESTION_POSITION: (370.0, 160.0) px
- QUESTION_SIZE: 640.0 x 210.0 px
- HOVER_DETAIL_POSITION: (470.0, 486.0) px
- HOVER_DETAIL_SIZE: 440.0 x 42.0 px
- CARD_ROW_POSITION: (461.0, 542.0) px
- CARD_SIZE: 104.0 x 158.0 px
- CARD_GAP: 14.0 px
- BOSS_POSITION: (800.0, 130.0) px
- BOSS_SIZE: 480.0 x 520.0 px
- KARL_BATTLEFIELD_ASSET: `res://assets/characters/player/karl/karl_portrait.png`
- KARL_PIXEL_ASSET_REQUIRED_FROM_WAD2: YES
- FLOATING_STATUS_IMPLEMENTED: YES
- PERMANENT_CARD_STATS: NO
- COMBAT_FEED: NO
- COMBAT_VALUES_USED: 10 / +8 / +15 / -10
- REMOTE_ASSETS_USED: NO
- HTML_CSS_USED: NO
- IMAGE_GENERATED: NO
- IMAGE_EDITED: NO
- PRODUCTION_SOURCE_CHANGED: NO
- PUSHED: NO

## 6. RUNTIME COMMANDS
- Interactive Windowed Launch:
  ```powershell
  & "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe" --path "D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185" "res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn"
  ```
- Automated Test / Headless Runner:
  ```powershell
  & "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path "D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185" -s res://labs/stochas_combat_ui/run_lab_headless.gd
  ```

## 7. PROGRESS & GATES
- All 16 checks passed cleanly in automated verification runner.
- Existing regression test suite passed cleanly (17/17).

## 8. BLOCKERS & NEXT ACTION
- BLOCKERS: None.
- NEXT ACTION: Awaiting human visual review of native Godot Stitch-parity LAB.
