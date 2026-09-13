# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-LAB-COMBAT-TIMING-FIX-225L
- TITLE: LAB-only interaction timing fix
- FROM: User / LAB Gameplay Flow Correction
- PRIORITY: P0 / LAB GAMEPLAY FLOW CORRECTION
- BASE: 8daf880244c8673c88fd373e12f922618be26f44
- STATUS: DONE
- PROMPT_RECEIVED_AT: 2026-09-13T08:47:00+07:00
- UPDATED_AT: 2026-09-13T08:48:45+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 8daf880244c8673c88fd373e12f922618be26f44
- CURRENT_HEAD: ca9979dafd68807c1b6648c9473e42443a7b9a99
- FINAL_HEAD: ca9979dafd68807c1b6648c9473e42443a7b9a99
- CANONICAL_BASE: 8daf880244c8673c88fd373e12f922618be26f44
- PRODUCTION_SOURCE_CHANGED: NO (0 production files modified)

## 3. EXACT PROMPT / INTENT SUMMARY
- Intent:
  - Implement native Godot animations and state feedback for the STOCHAS boss in the visual LAB (`res://labs/stochas_combat_ui/`) using Tweens, modulation, rotation, scale, and native particle/aura overlays:
    1. IDLE / STAND: Subtle vertical floating (4-8px), subtle breathing scale (0.5-1.5%), cyan/blue aura pulse, loop duration 2.5-4.0s. Boss stays stable and threatening (no floating UI feel).
    2. CAST / ATTACK: Anticipation lean back + aura intensify, forward lunge / scale impulse, cyan/purple flash at hand/staff, triggers -10 HP and Karl HIT state in preview, returns to IDLE (~0.7-1.2s total).
    3. HIT / DAMAGED: Recoil horizontal displacement (8-16px), red/white flash, slight rotational kick (1-2 deg), floating "-10 HP", duration ~0.35-0.65s, returns smoothly to IDLE.
    4. STUN: Freeze/pause idle, short backward stagger, cyan/purple rune ring / stars around head, desaturate/dim, floating "CHOÁNG", duration ~1.0-1.8s, resumes IDLE.
    5. ENRAGED / LOW-HP PREVIEW: Optional toggleable state with crimson/magenta aura pulse, faster breathing, HUD border intensity increase, no layout shift.
  - State priority: STUN > HIT > CAST > ENRAGED > IDLE (no tween conflicts; pause idle during transient states).
  - LAB hotkeys: B (Boss IDLE), V (Boss CAST/ATTACK), N (Boss HIT), M (Boss STUN), L (Boss ENRAGED toggle). Preserve Karl keys (I, C, H, E, S, D).
  - Combat preview wiring:
    - STRIKE executed: Karl CAST -> STOCHAS HIT -> STOCHAS floating -10 HP.
    - Wrong answer: STOCHAS CAST -> Karl HIT -> Karl floating -10 HP.
    - DEFEND: Karl SHIELD (+8 GIÁP).
    - HEAL: Karl HEAL (+15 HP).
  - STRICTLY PROHIBITED:
    - DO NOT generate, edit, or crop any images (no new boss PNGs; use existing `stochas_boss.png`).
    - DO NOT modify production files (`src/ui/combat/`, `src/ui/question/`, `src/ui/stage/`).
    - DO NOT modify approved layout (1:1 bg framing, question 660x270 at 690/155, Karl 300x300 at 50/70 base 650, cards 104x158 at 690, hover panel, HUDs, settings).
    - DO NOT integrate Adaptive AI.
    - DO NOT push.

## 4. LAB ARTIFACTS & FILES
- LAB FILES MODIFIED:
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab.gd`
  - `res://labs/stochas_combat_ui/run_lab_headless.gd`
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab_clean.png`
  - `res://labs/stochas_combat_ui/stochas_combat_ui_lab_debug.png`

## 5. STOCHAS STATE MAPPING & ANIMATION PARAMETERS
- Base Position: Vector2(800.0, 130.0) (Right: 0px, Bottom: 70px, 480x520px)
- Ground Shadow: Size 320x26 at Vector2(880, 642)
- Arcane Aura: Size 480x520 at Vector2(800, 130) with soft border glow (cyan default, crimson in enraged)
- VFX Container: Size 480x520 at Vector2(800, 130)
- States:
  1. IDLE / STAND:
     - Loop duration: 3.2s (1.6s up, 1.6s down)
     - Vertical floating: 6.0 px (SINE ease-in-out)
     - Breathing scale: Vector2(1.008, 0.995)
     - Aura pulse: modulate alpha 0.40 -> 0.85
  2. CAST / ATTACK:
     - Total duration: 0.90s
     - Anticipation (0.30s): lean back (+14px X, -4px Y), tilt +1.5 deg, staff aura intensify, casting spark at hand/staff (85, 175)
     - Attack Release (0.18s): forward lunge (-28px X), scale impulse 1.04, tilt -1.2 deg, projectile fires towards Karl, triggers Karl HIT & -10 HP
     - Hold & Settle (0.42s): return smoothly to base (800, 130), rotation 0, scale 1.0, modulate white, resumes IDLE
  3. HIT / DAMAGED:
     - Total duration: 0.42s
     - Recoil backward: +16px X, -2px Y, rotation -1.5 deg, instant red/white flash modulate (2.2, 0.6, 0.6, 1.0)
     - Floating feedback: -10 HP (accent red)
     - Recovery: settle to base (800, 130), rotation 0, scale 1.0, modulate white, resumes IDLE
  4. STUN:
     - Total duration: 1.40s
     - Idle float paused
     - Stagger: +10px X, +6px Y, rotation +1.2 deg, dim/desaturate modulate (0.65, 0.70, 0.85, 0.90)
     - Overlay: 3 golden head runes/stars (✦) above head at (240, 60)
     - Dizzy sway: oscillating rotation ±1.2 deg (3 half-waves = 0.90s)
     - Floating text: CHOÁNG! (accent gold)
     - Recovery: runes fade out, returns to base, resumes IDLE
  5. ENRAGED / LOW-HP PREVIEW:
     - Toggled via [L]
     - Aura color: crimson/magenta (Color(0.75, 0.12, 0.25, 0.25)) with red glow
     - HUD border: glowing red (Color(1.0, 0.20, 0.25, 0.95))
     - Accelerated breathing: 1.8s loop duration (0.9s up, 0.9s down), 7.5px float, 1.2% breathing
- State Priority: STUN > HIT > CAST > ENRAGED > IDLE (zero tween fighting, clean resume)
- Position Drift: 0.0 px (all tweens explicitly anchor to BOSS_BASE_POS)

## 6. ACCEPTANCE GATES STATUS (MATHOS-STOCHAS-LAB-COMBAT-TIMING-FIX-225L)
- GATE 1 (Initial state clean: has_selected_answer = false, answer_idx = -1, IDLE states): PASS
- GATE 2 (Card selection updates visual highlight, hover detail, and CTA text ONLY; 0 animation): PASS
- GATE 3 (Answer selection updates choice button highlight ONLY; 0 animation): PASS
- GATE 4 (CTA press without answer selected displays floating warning "Chọn đáp án trước", 0 animation): PASS
- GATE 5 (CTA press on disabled card PROBABILITY shows "CHƯA KÍCH HOẠT", 0 animation): PASS
- GATE 6 (Correct answer + STRIKE card triggers Karl CAST -> STOCHAS HIT & -10 HP near STOCHAS): PASS
- GATE 7 (Correct answer + DEFEND card triggers Karl SHIELD & +8 GIÁP barrier VFX): PASS
- GATE 8 (Correct answer + HEAL card triggers Karl HEAL & +15 HP emerald aura VFX): PASS
- GATE 9 (Wrong answer triggers STOCHAS CAST counter-attack -> Karl HIT & -10 HP near Karl; card does not execute): PASS
- GATE 10 (Manual debug hotkeys [I/C/H/E/S/B/V/N/M/L/D] remain fully functional): PASS
- GATE 11 (All 5 Karl states baseline alignment preserved at 650.0 px): PASS
- GATE 12 (Question/card/background layout unchanged): PASS (Question 660x270 at 690/155, Karl 300x300, cards 104x158)
- GATE 13 (Production source untouched & 0 images generated/edited): PASS (0 production files modified)

## 7. RECENT PROMPT LOG
### Prompt entry 49
- RECEIVED_AT: 2026-09-13T03:53:02+07:00
- TASK_ID: MATHOS-STOCHAS-LAB-PROPORTION-223L
- ONE_LINE_INTENT: Refine Question panel height to 660x270 px with expanded internal spacing and increase Karl battlefield sprite to 300x300 px while preserving baseline and Stitch layout.
- RESULT / CURRENT_STATE: DONE (All 14 automated gates PASSED)

### Prompt entry 50
- RECEIVED_AT: 2026-09-13T08:25:43+07:00
- TASK_ID: MATHOS-STOCHAS-BOSS-STATE-ANIMATION-LAB-224L
- ONE_LINE_INTENT: Integrate native Godot Tweens and state animations for STOCHAS (Idle, Cast, Hit, Stun, Enraged) and preview combat chain in LAB.
- RESULT / CURRENT_STATE: DONE (All 14 automated gates PASSED)

### Prompt entry 51
- RECEIVED_AT: 2026-09-13T08:47:00+07:00
- TASK_ID: MATHOS-STOCHAS-LAB-COMBAT-TIMING-FIX-225L
- ONE_LINE_INTENT: Decouple card selection from immediate attack triggers, enforce answer selection check on CTA press, and lock combat execution timing chain.
- RESULT / CURRENT_STATE: DONE (All 13 automated gates PASSED)

