# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-KARL-PIXEL-LAB-INTEGRATION-221B
- TITLE: Karl pixel combat-state integration into approved STOCHAS LAB
- FROM: User / Human Visual Lab
- PRIORITY: P0 / HUMAN VISUAL LAB
- BASE: 08fc99f572255ca39e210e854856a54c5b2c9a9f
- STATUS: DONE
- PROMPT_RECEIVED_AT: 2026-09-13T03:06:02+07:00
- UPDATED_AT: 2026-09-13T03:18:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 08fc99f572255ca39e210e854856a54c5b2c9a9f
- CURRENT_HEAD: ecc8f18b5f43e9c54a787f3a935f629aba22194c
- FINAL_HEAD: ecc8f18b5f43e9c54a787f3a935f629aba22194c
- CANONICAL_BASE: 08fc99f572255ca39e210e854856a54c5b2c9a9f
- PRODUCTION_SOURCE_CHANGED: NO (0 production files modified)

## 3. EXACT PROMPT / INTENT SUMMARY
- Intent:
  - Integrate new Karl pixel combat-state assets into the approved STOCHAS LAB (`res://labs/stochas_combat_ui/`).
  - Assets:
    - `res://assets/characters/player/karl/combat_pixel/karl_idle.png`
    - `res://assets/characters/player/karl/combat_pixel/karl_cast.png`
    - `res://assets/characters/player/karl/combat_pixel/karl_hit.png`
    - `res://assets/characters/player/karl/combat_pixel/karl_heal.png`
    - `res://assets/characters/player/karl/combat_pixel/karl_shield.png`
  - Remove old battlefield Karl standee (`karl_portrait.png` in rectangular frame).
  - Battlefield Karl positioning: Left ~55–90px (70px), Bottom ~60–80px (70px), displayed visual height ~190–250px (220px), facing right toward STOCHAS.
  - Ground baseline consistency: All 5 states share the same ground baseline without jumping (exact 650.0 px).
  - LAB state preview controls:
    - `I` = IDLE
    - `C` = CAST
    - `H` = HIT
    - `E` = HEAL
    - `S` = SHIELD
  - Card interaction triggers corresponding state animation + floating combat feedback (+15 HP, +8 GIÁP, -10 HP).
  - STRICTLY PROHIBITED:
    - DO NOT modify production combat UI (`src/ui/combat/`, `src/ui/question/`, `src/ui/stage/`).
    - DO NOT edit or generate images.
    - DO NOT push.

## 4. LAB ARTIFACTS & FILES
- LAB FILES IN SCOPE:
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab.gd`
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn`
  - `res://labs/stochas_combat_ui/run_lab_headless.gd`
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab_clean.png`
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab_debug.png`

## 5. EXACT LAB MEASUREMENTS & STATE MAPPING
- KARL_DISPLAY_SIZE: 220 x 220 px
- KARL_POSITION: Vector2(70, 430) (Left: 70px, Bottom: 70px)
- GROUND_BASELINE: 650.0 px (perfectly preserved across IDLE, CAST, HIT, HEAL, SHIELD)
- ASSETS_MAPPING:
  - IDLE: `res://assets/characters/player/karl/combat_pixel/karl_idle.png` (Offset: +4.5px)
  - CAST: `res://assets/characters/player/karl/combat_pixel/karl_cast.png` (Offset: 0.0px)
  - HIT: `res://assets/characters/player/karl/combat_pixel/karl_hit.png` (Offset: +4.5px)
  - HEAL: `res://assets/characters/player/karl/combat_pixel/karl_heal.png` (Offset: 0.0px)
  - SHIELD: `res://assets/characters/player/karl/combat_pixel/karl_shield.png` (Offset: +2.8px)
- STITCH COMPOSITION PRESERVED:
  - Central Interaction Axis: X = 690.0 px
  - Question Module: Width = 640.0 px, Top = 160.0 px, Height = 210.0 px, Center X = 690.0 px
  - Card Hover Detail: Width = 440.0 px, Height = 42.0 px, Y = 486.0 px, Center X = 690.0 px
  - Card Row: 4 cards (104 x 158 px, gap 14 px), Bottom = 20.0 px, Center X = 690.0 px
  - Boss Entity: 480 x 520 px, Right = 0.0 px, Bottom = 70.0 px

## 6. ACCEPTANCE GATES STATUS (MATHOS-KARL-PIXEL-LAB-INTEGRATION-221B)
- GATE 1 (All 5 Karl PNG assets load): PASS (5/5 loaded)
- GATE 2 (Battlefield standee removed): PASS (pedestal standee removed, pure pixel sprite used)
- GATE 3 (Idle sprite visible): PASS (karl_idle.png, facing right)
- GATE 4 (Cast state visible): PASS (karl_cast.png + hand spark + STOCHAS -10 HP)
- GATE 5 (Hit state visible): PASS (karl_hit.png + red flash + recoil + -10 HP)
- GATE 6 (Heal state visible): PASS (karl_heal.png + emerald aura + +15 HP)
- GATE 7 (Shield state visible): PASS (karl_shield.png + arcane barrier pulse + +8 GIÁP)
- GATE 8 (State swaps preserve ground baseline): PASS (exact 650.0 px across all 5 states)
- GATE 9 (Heal shows +15 HP feedback): PASS
- GATE 10 (Shield shows +8 GIÁP feedback): PASS
- GATE 11 (Hit shows -10 HP feedback): PASS
- GATE 12 (Strike causes STOCHAS -10 HP feedback): PASS
- GATE 13 (LAB Stitch layout remains unchanged): PASS (Center X = 690 axis preserved)
- GATE 14 (Production files unchanged): PASS (0 production files modified)
- GATE 15 (No images generated/edited): PASS (original pixel PNGs used directly)

## 7. RUNTIME LAUNCH COMMAND
- Windowed Interactive:
  `& "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe" --path "D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185" "res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn"`
- Headless Automated Verification:
  `& "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --path "D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185" -s res://labs/stochas_combat_ui/run_lab_headless.gd`

## 8. BLOCKERS & NEXT ACTION
- BLOCKERS: None.
- NEXT ACTION: Present complete report for Human Review with verdict `READY_FOR_KARL_PIXEL_LAB_HUMAN_REVIEW`.

## 9. RECENT PROMPT LOG
### Prompt entry 47
- RECEIVED_AT: 2026-09-13T03:06:02+07:00
- TASK_ID: MATHOS-KARL-PIXEL-LAB-INTEGRATION-221B
- ONE_LINE_INTENT: Integrate 5-state pixel Karl combat sprite and effects into approved STOCHAS LAB with ground baseline preservation and shortcut previews.
- RESULT / CURRENT_STATE: DONE (All 15 verification gates passed, ready for human review)
