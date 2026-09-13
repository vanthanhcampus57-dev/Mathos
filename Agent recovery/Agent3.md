# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-SHIELD-DAMAGE-QUESTION-PRESENTATION-228L
- TITLE: LAB combat-state + animation presentation correction
- FROM: User / HUMAN COMBAT LAB
- PRIORITY: P0 / HUMAN COMBAT LAB
- BASE: 851865a552be488917e6c286e7290588e8e60660
- STATUS: DONE
- PROMPT_RECEIVED_AT: 2026-09-13T12:19:59+07:00
- UPDATED_AT: 2026-09-13T12:26:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 851865a552be488917e6c286e7290588e8e60660
- CURRENT_HEAD: 16a0a698a8ed03d9a3d5d3190fd36f2273ff02b2
- FINAL_HEAD: 16a0a698a8ed03d9a3d5d3190fd36f2273ff02b2
- CANONICAL_BASE: 851865a552be488917e6c286e7290588e8e60660
- PRODUCTION_SOURCE_CHANGED: NO (0 production files modified)

## 3. EXACT PROMPT / INTENT SUMMARY
- Intent:
  - Part A (Real Shield Damage Flow): Incoming boss damage (10) resolves against Shield first, then HP overflow. Centralized via `apply_damage_to_karl(amount)`: if shield > 0, absorbs up to shield amount, decreases shield via `set_shield()`, triggers `break_shield()` if depleted, overflow damage hits Karl HP and Karl enters HIT state. Floating feedback reflects shield loss and/or HP loss and "VỠ KHIÊN!".
  - Part B (Question Combat Mode): During combat animation execution (Karl STRIKE, DEFEND, HEAL, STOCHAS CAST/attack, STOCHAS HIT, shield break, STUN), fade Question panel to ~0.22 alpha (duration 0.20s) and disable inputs (anti-double input `combat_resolving = true`). Restore opacity (1.0) and inputs after the full chained sequence completes.
  - Part C (Question Panel Layout Refinement): Reduce Question panel from 660x270 to compact 610x240 px, shift left to center X=640.0 (pos: 335, 155) so it has 95 px clearance from STOCHAS head center (eliminating overlap with STOCHAS head/staff/silhouette). Internal composition adjusted compactly.
  - STRICTLY PROHIBITED:
    - DO NOT modify production (`src/ui/combat/`, `src/ui/question/`, `src/ui/stage/`).
    - DO NOT generate, edit, or crop any images (no PNG edits).
    - DO NOT change Card layout (104x158 at center X=690), Karl layout (300x300 at 50/70), STOCHAS layout (480x520 at right 0 bottom 70), background, or locked card values.
    - DO NOT implement Adaptive AI or push.

## 4. LAB ARTIFACTS & FILES
- LAB FILES MODIFIED:
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab.gd`
  - `res://labs/stochas_combat_ui/run_lab_headless.gd`

## 5. SHIELD DAMAGE FLOW, HP/SHIELD MATH & QUESTION ANIMATION
- Shield damage resolution order: SHIELD -> HP overflow.
- Centralized damage API: `apply_damage_to_karl(amount: int)`
- Case A (Shield 0, incoming 10): HP 90, Shield 0, floating "-10 HP", Karl enters HIT state.
- Case B (Shield 8, incoming 10): Shield absorbs 8, auto-break VFX + "VỠ KHIÊN!", HP 98 (-2 HP overflow), Karl enters HIT state.
- Case C (Shield 16, incoming 10): Shield absorbs 10 -> Shield 6, HP 100, barrier remains active, no break, Karl stays IDLE.
- Case D (Shield 24, incoming 10): Shield absorbs 10 -> Shield 14, HP 100, barrier remains active, no break.
- Case E (Chained combat presentation): Question fades to alpha 0.22 (0.20s fade out) on skill start; input locked (`combat_resolving = true`) blocking cards, answers, CTA; restores to alpha 1.0 (0.24s fade in) and unlocks inputs once full sequence completes.
- Layout measurements:
  - Question size: 610 x 240 px (reduced from 660 x 270 px)
  - Question position: Vector2(335, 155)
  - Question center X: 640.0 px
  - Clearance from STOCHAS head center: 95.0 px
- Launch command: `& "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless -s labs/stochas_combat_ui/run_lab_headless.gd`
- Blockers: None
- Next Action: Standby for human visual review of shield damage and question presentation.

## 6. ACCEPTANCE GATES STATUS (MATHOS-SHIELD-DAMAGE-QUESTION-PRESENTATION-228L)
- GATE 1 (Boss damage checks Shield before HP): PASS
- GATE 2 (Shield 8 + incoming 10 -> Shield 0, HP -2): PASS
- GATE 3 (Shield break automatically triggers on depletion): PASS
- GATE 4 (No [K] required for combat shield break): PASS
- GATE 5 (Shield 16 + incoming 10 -> Shield 6, HP unchanged): PASS
- GATE 6 (Barrier remains when Shield > 0): PASS
- GATE 7 (Barrier breaks only when Shield reaches 0): PASS
- GATE 8 (HUD HP/GIÁP updates correctly): PASS
- GATE 9 (Question fades/hides during Karl skill animation): PASS
- GATE 10 (Question fades/hides during STOCHAS attack): PASS
- GATE 11 (Question remains faded for full chained sequence): PASS
- GATE 12 (Input locked while combat_resolving=true): PASS
- GATE 13 (Question restores after sequence completes): PASS
- GATE 14 (Question panel reduced from 660x270): PASS (610 x 240 px)
- GATE 15 (Question no longer covers STOCHAS head): PASS (95 px clearance)
- GATE 16 (Cards unchanged): PASS (104x158, gap 14, center X=690)
- GATE 17 (Karl/STOCHAS sizes unchanged): PASS (Karl 300x300, STOCHAS 480x520)
- GATE 18 (Background unchanged): PASS (1280x720 1:1 framing)
- GATE 19 (Production unchanged): PASS (0 production files modified)
- GATE 20 (No image generated/edited): PASS (0 images generated or edited)

## 7. RECENT PROMPT LOG
### Prompt entry 54
- RECEIVED_AT: 2026-09-13T12:19:59+07:00
- TASK_ID: MATHOS-SHIELD-DAMAGE-QUESTION-PRESENTATION-228L
- ONE_LINE_INTENT: Correct shield damage flow (Shield first -> HP overflow), question combat fade (~0.22 alpha during execution) with input lock, and refine question panel size/position (610x240, shifted left) to eliminate STOCHAS head overlap.
- RESULT / CURRENT_STATE: DONE (All 20 automated gates PASSED)
