# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-COMBAT-UI-LAB-REFINE-219L
- TITLE: Isolated native Godot combat UI lab refinement
- FROM: User / Human Visual Design Lab
- PRIORITY: P0 / HUMAN VISUAL DESIGN LAB
- BASE: ee3df312607279aa7ef011662f8313e23b6fa277
- STATUS: READY_FOR_HUMAN_LAB_REVIEW
- PROMPT_RECEIVED_AT: 2026-09-12T21:34:47+07:00
- UPDATED_AT: 2026-09-12T21:40:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: ee3df312607279aa7ef011662f8313e23b6fa277
- CURRENT_HEAD: ee3df312607279aa7ef011662f8313e23b6fa277
- CANONICAL_BASE: ee3df312607279aa7ef011662f8313e23b6fa277
- PRODUCTION_SOURCE_CHANGED: NO (0 production files modified)

## 3. EXACT PROMPT / INTENT SUMMARY
- REASON FOR TASK 219L:
  1. REMOVE visible top text labels above every combat card (TẤN CÔNG, PHÒNG THỦ, HỒI MÁU, XÁC SUẤT). Card art already identifies card.
  2. Question panel must NOT overlap/intrude into STOCHAS HUD area (top ~90-110 px is HUD-safe zone). Top edge must start below HUD band (Y ~115–130). Must not overlap Karl HUD either.
  3. Question panel feels vertically cramped: expand height from 240 px to ~270–300 px (target 660 x 285 px). Fill added height with breathing room, larger prompt line spacing, slightly taller answer buttons (36–42 px), clear button padding. No giant empty black zone.
  4. Lower-left remains open (no combat feed).
  5. DO NOT touch production files (`src/ui/combat/boss_combat_panel.*`, `src/ui/question/question_panel.*`, `src/ui/stage/*`).
  6. DO NOT touch gameplay logic, evaluators, save/auth/story.
  7. DO NOT generate or edit images.
  8. DO NOT push.

## 4. LAB ARTIFACTS & FILES
- LAB FILES CHANGED:
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab.gd`
  - `res://labs/stochas_combat_ui/run_lab_headless.gd`
  - `labs/stochas_combat_ui/stochas_combat_ui_lab_clean.png`
  - `labs/stochas_combat_ui/stochas_combat_ui_lab_debug.png`

## 5. EXACT MEASUREMENTS & SPECIFICATIONS
- CARD_TOP_LABELS_REMOVED: YES
- CARD_OUTER_SIZE: 140.0 x 200.0 px
- CARD_ART_SIZE: 124.0 x 166.0 px
- CARD_ART_WIDTH_RATIO: 88.6% (124 / 140)
- CARD_ART_HEIGHT_RATIO: 83.0% (166 / 200)
- QUESTION_OLD_SIZE: 650 x 240 px
- QUESTION_NEW_SIZE: 660 x 285 px
- QUESTION_POSITION: (310.0, 120.0) px
- HUD_SAFE_TOP_ZONE: 110.0 px (Top HUD bounds Y: 18–90)
- BOSS_HUD_OVERLAP: NO (Clearance = 30 px vertically below STOCHAS HUD bottom at Y=90)
- KARL_HUD_OVERLAP: NO (Clearance = 30 px vertically below Karl HUD bottom at Y=90)
- ANSWER_BUTTON_SIZE: 305.0 x 38.0 px (2x2 grid, comfortable click target)
- HINT_BUTTON_SIZE: 115.0 x 44.0 px (secondary hierarchy)
- CTA_SIZE: 290.0 x 48.0 px (primary glowing hierarchy)
- COMBAT_FEED_PRESENT: NO (open lower-left forest view)

## 6. RUNTIME COMMANDS
- Interactive Windowed Launch:
  ```powershell
  & "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe" --path "D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185" "res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn"
  ```
- Automated Test / Headless Runner:
  ```powershell
  & "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path "D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185" -s res://labs/stochas_combat_ui/run_lab_headless.gd
  ```

## 7. ACCEPTANCE GATES STATUS (MATHOS-STOCHAS-COMBAT-UI-LAB-REFINE-219L)
- GATE 1 (No TẤN CÔNG text above STRIKE card): PASS
- GATE 2 (No PHÒNG THỦ text above DEFEND card): PASS
- GATE 3 (No HỒI MÁU text above HEAL card): PASS
- GATE 4 (No XÁC SUẤT text above PROBABILITY card): PASS
- GATE 5 (Card art remains approximately 80–90% card width): PASS (88.6% width, 83.0% height)
- GATE 6 (Question panel does NOT overlap STOCHAS HUD): PASS (Y=120 > Y=90, clearance 30px)
- GATE 7 (Question panel does NOT overlap Karl HUD): PASS (Y=120 > Y=90, clearance 30px)
- GATE 8 (Question panel is visibly taller than 240 px): PASS (285.0 px)
- GATE 9 (Question area does NOT become a giant empty rectangle): PASS (content fills area)
- GATE 10 (Prompt has enough vertical space): PASS (48.0 px, line spacing 4px)
- GATE 11 (2x2 answer area remains clear): PASS (4 buttons 305x38 px)
- GATE 12 (Hint remains secondary): PASS (115x44 px)
- GATE 13 (XUẤT CHIÊU remains primary): PASS (290x48 px glowing)
- GATE 14 (Combat Feed remains absent): PASS (zero combat feed)
- GATE 15 (Production combat UI remains untouched): PASS (zero production files modified)

## 8. BLOCKERS & NEXT ACTION
- BLOCKERS: None.
- NEXT ACTION: Awaiting human visual review of refined lab candidate.

## 9. RECENT PROMPT LOG
### Prompt entry 45
- RECEIVED_AT: 2026-09-12T21:34:47+07:00
- TASK_ID: MATHOS-STOCHAS-COMBAT-UI-LAB-REFINE-219L
- ONE_LINE_INTENT: Refine combat UI lab by removing card top labels, ensuring question panel sits below HUD band without overlap, and increasing question panel height to ~285 px with proper vertical breathing room.
- RESULT / CURRENT_STATE: READY_FOR_HUMAN_LAB_REVIEW
