# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-LAB-PROPORTION-223L
- TITLE: LAB-only proportion refinement
- FROM: User / Human Visual Lab
- PRIORITY: P0 / HUMAN VISUAL LAB
- BASE: 080d7a1ef58be9a296e67c7326aeea07a6384baa
- STATUS: DONE
- PROMPT_RECEIVED_AT: 2026-09-13T03:53:02+07:00
- UPDATED_AT: 2026-09-13T04:02:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 080d7a1ef58be9a296e67c7326aeea07a6384baa
- CURRENT_HEAD: 7b6f3758fc043e18162633dfe196f38e0b060891
- FINAL_HEAD: 7b6f3758fc043e18162633dfe196f38e0b060891
- CANONICAL_BASE: 080d7a1ef58be9a296e67c7326aeea07a6384baa
- PRODUCTION_SOURCE_CHANGED: NO (0 production files modified)

## 3. EXACT PROMPT / INTENT SUMMARY
- Intent:
  - Refine two main visual proportions in LAB based on human feedback:
    1. QUESTION PANEL: Enlarged from 640x210 px to 660x270 px (Center X = 690 px, Top = 155 px). Utilized added height with larger prompt area (628x48 px, font 13), taller answer buttons (150x48 px), taller action buttons (44 px), and clean margins (16, 14, 16, 12).
    2. KARL BATTLEFIELD SPRITE: Enlarged from 220x220 px to 300x300 px (Left = 50 px, Bottom = 70 px). Maintained 57.7% ratio to STOCHAS (520 px). Preserved common ground baseline at 650.0 px across all 5 states (idle, cast, hit, heal, shield) using calibrated per-state offsets.
  - Preserve:
    - 1:1 background framing from Task 222L (1280x720, KEEP_ASPECT_COVERED)
    - STOCHAS size (480 x 520 px) & position (Right: 0, Bottom: 70)
    - Top HUDs (Karl at 20,16 size 260x72; Boss at 1000,16 size 260x72)
    - Card design, size (104 x 158 px), gap (14 px), row alignment at Center X = 690 px
    - Hover detail panel at Center X = 690 px, Y = 486 px
    - Settings button, floating feedback, locked combat values (10 / +8 / +15 / -10)
  - STRICTLY PROHIBITED:
    - DO NOT modify production files (`src/ui/combat/`, `src/ui/question/`, `src/ui/stage/`).
    - DO NOT generate, edit, or crop images.
    - DO NOT push.

## 4. LAB ARTIFACTS & FILES
- LAB FILES MODIFIED:
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab.gd`
  - `res://labs/stochas_combat_ui/run_lab_headless.gd`
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab_clean.png`
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab_debug.png`

## 5. EXACT MEASUREMENTS & LAYOUT
- Canvas Size: 1280 x 720 px
- Interaction Axis: Center X = 690.0 px
- Background: 1280 x 720 px, EXPAND_IGNORE_SIZE, STRETCH_KEEP_ASPECT_COVERED
- Top HUDs: Bottom at Y = 88.0 px
- Question Panel:
  - Size: 660.0 x 270.0 px (Position: 360.0, 155.0)
  - Center X: 690.0 px
  - Top Clearance to HUD: 67.0 px (155.0 - 88.0)
  - Bottom Clearance to Hover: 61.0 px (486.0 - 425.0)
  - Prompt Area: 628.0 x 48.0 px, font size 13
  - Answer Buttons: 4 buttons, 150.0 x 48.0 px min size (layout: 151.0 x 48.0 px), gap 8 px
  - Action Row: Hint button 104.0 x 44.0 px, CTA button 280.0 x 44.0 px
  - Helper Label: 20.0 px height, font size 10
  - Content Margins: Left 16, Top 14, Right 16, Bottom 12
- Karl Battlefield Entity:
  - Size: 300.0 x 300.0 px (Position: 50.0, 350.0)
  - Left: 50.0 px, Bottom: 70.0 px
  - Ground Baseline: 650.0 px (350.0 + 300.0)
  - Ground Shadow: 210.0 x 22.0 px at local (45.0, 282.0)
  - Barrier VFX: 270.0 x 270.0 px
  - Emerald Aura: 260.0 x 270.0 px
  - Casting Spark: 28.0 x 28.0 px at local (218.0, 105.0)
  - Floating Feedback: Centered at (200.0, 330.0)
  - Clearance to Question Panel: 10.0 px container clearance, ~23.9 px visible pixel clearance
  - Proportion to STOCHAS (520 px): 57.7%
  - Calibrated baseline offsets: IDLE (+6.2px), CAST (0.0px), HIT (+6.2px), HEAL (0.0px), SHIELD (+3.8px)
- STOCHAS Boss Entity:
  - Size: 480.0 x 520.0 px (Position: 800.0, 130.0)
  - Right: 0.0 px, Bottom: 70.0 px
- Hover Detail:
  - Size: 590.0 x 42.0 px, Y = 486.0 px, Center X = 690.0 px
- Card Row:
  - 4 cards, each 104.0 x 158.0 px, gap 14 px, Center X = 690.0 px, Y = 542.0 px

## 6. ACCEPTANCE GATES STATUS (MATHOS-STOCHAS-LAB-PROPORTION-223L)
- GATE 1 (Question panel visibly taller than 210 px): PASS (270 px)
- GATE 2 (Question panel target ~255–285 px high): PASS (270 px)
- GATE 3 (Added height used by real content, not empty space): PASS (prompt 48px, answers 48px, CTA 44px)
- GATE 4 (Question still centered at X≈690): PASS (690.0 px exact)
- GATE 5 (Question does not overlap HUDs): PASS (67.0 px clearance)
- GATE 6 (Question does not collide with hover/card row): PASS (61.0 px clearance)
- GATE 7 (Karl materially larger than 220 px): PASS (300 x 300 px)
- GATE 8 (Karl target ~280–320 px visual height): PASS (300 px)
- GATE 9 (All Karl states use consistent scale/baseline): PASS (all 5 states aligned to baseline 650.0 px)
- GATE 10 (Karl remains smaller than STOCHAS): PASS (300 px vs 520 px, ratio 57.7%)
- GATE 11 (Background framing remains exactly as Task 222L): PASS (1280x720, KEEP_ASPECT_COVERED)
- GATE 12 (Cards unchanged): PASS (104x158 px, gap 14 px, centered at 690 px)
- GATE 13 (Production unchanged): PASS (0 production files modified)
- GATE 14 (No image generation/editing): PASS (no external tools or edits)

## 7. RECENT PROMPT LOG
### Prompt entry 49
- RECEIVED_AT: 2026-09-13T03:53:02+07:00
- TASK_ID: MATHOS-STOCHAS-LAB-PROPORTION-223L
- ONE_LINE_INTENT: Refine Question panel height to 660x270 px with expanded internal spacing and increase Karl battlefield sprite to 300x300 px while preserving baseline and Stitch layout.
- RESULT / CURRENT_STATE: DONE (All 14 automated gates PASSED)
