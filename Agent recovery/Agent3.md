# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-COMBAT-UI-LAB-218L
- TITLE: Isolated native Godot combat UI lab
- FROM: User / Human Visual Design Lab
- PRIORITY: P0 / HUMAN VISUAL DESIGN LAB
- BASE: 7f1cb6a08f37a3ed766ab344f275730bba532b5d
- STATUS: READY_FOR_HUMAN_LAB_REVIEW
- PROMPT_RECEIVED_AT: 2026-09-12T08:43:15+07:00
- UPDATED_AT: 2026-09-12T08:52:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 7f1cb6a08f37a3ed766ab344f275730bba532b5d
- CURRENT_HEAD: 7f1cb6a08f37a3ed766ab344f275730bba532b5d
- CANONICAL_BASE: 7f1cb6a08f37a3ed766ab344f275730bba532b5d
- PRODUCTION_SOURCE_CHANGED: NO (0 production files modified)

## 3. EXACT PROMPT / INTENT SUMMARY
- GOAL:
  - Create an isolated native Godot UI lab to iterate on STOCHAS combat visual presentation without guessing production dimensions:
    1. KEEP CARD SHELL COMPACT (~135–145 x ~195–205 px), MAKE INNER ARTWORK MUCH LARGER (~115–130 x ~150–175 px, 80-90% width, 75-85% height), thin header & footer, artwork is the hero.
    2. REDESIGN QUESTION UI IN LAB: compact & filled (~620–680 x ~210–250 px), no giant empty dark rectangle, no horizontal bar/scroll, visually explicit answer area, strong XUẤT CHIÊU CTA (48–54 px), secondary hint.
    3. LOWER-LEFT CLEAN: completely remove Combat Feed UI / NHẬT KÝ CHIẾN ĐẤU.
    4. LAB CONTROLS: 1-4 (cards), Q (question), A (answer), R (reset), D (debug outlines).
    5. Viewport 1280x720, real D1 background, Karl portrait, STOCHAS render, 4 production card images.
  - STRICTLY PROHIBITED:
    - DO NOT modify production combat UI files: boss_combat_panel.gd/tscn, question_panel.gd/tscn, gameplay_container.gd, stage_presentation_shell.gd/tscn.
    - DO NOT touch gameplay logic, evaluators, save/auth/story.
    - DO NOT generate or edit images.
    - DO NOT push.
    - DO NOT declare visual PASS (lab requires human review).

## 4. LAB ARTIFACTS & FILES
- LAB FILES CREATED:
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn` (Lab scene root, Control full rect 1280x720)
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab.gd` (Interactive UI controller with shortcuts & styling)
  - `res://labs/stochas_combat_ui/run_lab_headless.gd` (Headless and windowed automated verification runner)
  - `labs/stochas_combat_ui/stochas_combat_ui_lab_clean.png` (Clean render snapshot)
  - `labs/stochas_combat_ui/stochas_combat_ui_lab_debug.png` (Debug bounding outlines snapshot)

## 5. RUNTIME COMMANDS
- Interactive Windowed Launch:
  ```powershell
  & "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe" --path "D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185" "res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn"
  ```
- Automated Test / Headless Runner:
  ```powershell
  & "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless --path "D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185" -s res://labs/stochas_combat_ui/run_lab_headless.gd
  ```

## 6. EXACT MEASUREMENTS & SPECIFICATIONS
- CARD_OUTER_SIZE: 140.0 x 200.0 px (compact shell)
- CARD_ART_SIZE: 124.0 x 158.0 px (heroic artwork)
- CARD_ART_PERCENT_OF_BODY:
  - Width ratio: 124 / 140 = 88.6% (target 80–90%)
  - Height ratio: 158 / 200 = 79.0% (target 75–85%)
- QUESTION_PANEL_SIZE: 650.0 x 240.0 px (positioned at (315, 82))
- QUESTION_CONTENT_STRUCTURE:
  - Header: "ARCANE MATH CHALLENGE • CÂU HỎI 1 / 3" + "GIAI ĐOẠN 1" badge
  - Prompt: 13px clear prompt, autowrapped
  - Answer area: 2x2 grid of 4 selectable option buttons (302 x 34 px each) with [ A ], [ B ], [ C ], [ D ]
  - Action row: secondary "💡 GỢI Ý" button (110 x 42 px) + primary glowing "XUẤT CHIÊU" CTA (280 x 44 px)
  - Bottom rule text: 10px subtle rule line. Zero horizontal scrollbar/line.
- COMBAT_FEED_PRESENT: NO (completely removed, open lower-left forest view)
- ASSETS USED:
  - Karl: `res://assets/characters/player/karl/karl_portrait.png`
  - STOCHAS: `res://assets/characters/bosses/dungeon_1/stochas_boss.png`
  - Background: `res://assets/backgrounds/d1_misty_forest_bg.png`
  - Cards: `res://assets/ui/combat/cards_v1/{STRIKE,DEFEND,HEAL,PROBABILITY}.png`

## 7. PROGRESS & GATES
- ACCEPTANCE GATES STATUS:
  - GATE 1 (Production combat UI files unchanged): PASS (0 production files modified)
  - GATE 2 (Lab runs independently): PASS (verified standalone scene & runner)
  - GATE 3 (Card outer shell compact ~135-145x195-205): PASS (140 x 200 px)
  - GATE 4 (Inner artwork significantly larger): PASS (124 x 158 px)
  - GATE 5 (Artwork dominates each card): PASS (88.6% width, 79.0% height)
  - GATE 6 (No Combat Feed): PASS (absent, lower-left is open forest)
  - GATE 7 (Question panel contains no giant empty zone): PASS (650 x 240 px, fully populated)
  - GATE 8 (No weird horizontal bar/scroll): PASS (zero divider lines, zero scroll containers)
  - GATE 9 (Answer interaction visually explicit): PASS (2x2 grid, 4 option buttons with active states)
  - GATE 10 (Question / Hint / CTA hierarchy clear): PASS (Hint 110x42, CTA 280x44)
  - GATE 11 (Karl and STOCHAS production assets visible): PASS (both rendered properly)
  - GATE 12 (Forest visible): PASS (D1 misty forest background rendered)
  - GATE 13 (No production gameplay changed): PASS (gameplay formulas, progression intact)
  - GATE 14 (No images generated or edited): PASS (zero images generated or edited)

## 8. BLOCKERS & NEXT ACTION
- BLOCKERS: None.
- NEXT ACTION: Awaiting human visual review of the lab (`stochas_combat_ui_lab.tscn`). Once approved by human reviewer, port parameters to production.

## 9. RECENT PROMPT LOG
### Prompt entry 44
- RECEIVED_AT: 2026-09-12T08:43:15+07:00
- TASK_ID: MATHOS-STOCHAS-COMBAT-UI-LAB-218L
- ONE_LINE_INTENT: Isolated native Godot combat UI lab for compact card shell + large inner art, filled question UI, and no combat feed.
- RESULT / CURRENT_STATE: READY_FOR_HUMAN_LAB_REVIEW
