# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-ACTION-ULTIMATE-DAMAGE-LAB-233L
- TITLE: Boss Action System + per-spell damage + Ultimate Challenge + Karl Dodge + tactical activation presentation
- FROM: User / P0 HUMAN COMBAT LAB
- PRIORITY: P0 / HUMAN COMBAT LAB
- BASE: f7877882eea265fe845cb1315f8aa22a8315003c
- STATUS: READY_FOR_REVIEW
- PROMPT_RECEIVED_AT: 2026-09-14T14:22:21+07:00
- UPDATED_AT: 2026-09-14T14:31:50+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: f7877882eea265fe845cb1315f8aa22a8315003c
- CURRENT_HEAD: 00398d51e5eff8e565ba80db5338a129900b41e8
- FINAL_HEAD: 00398d51e5eff8e565ba80db5338a129900b41e8
- CANONICAL_BASE: f7877882eea265fe845cb1315f8aa22a8315003c
- PRODUCTION_SOURCE_CHANGED: NO (LAB only: res://labs/stochas_combat_ui/)

## 3. BOSS ACTION SYSTEM & DAMAGE CONTRACT
- Boss Damage Table:
  - ARCANE_BOLT: 8 damage
  - PROBABILITY_ORB: 10 damage
  - VOID_RIFT: 12 damage
  - ARCANE_SWEEP: 14 damage
  - CHAOS_VERDICT_ULTIMATE: 24 damage
- Centralized Damage Resolution: All damage routes through apply_damage_to_karl(amount), resolving against Shield first, then HP overflow, auto-triggering shield break VFX on depletion.
- Boss Action States:
  - BOSS_IDLE
  - BOSS_CAST_BOLT (~0.50s anticipation & snap, cyan flash)
  - BOSS_CAST_ORB (~0.60s slow staff raise & float, cyan/gold aura pulse)
  - BOSS_CAST_RIFT (~0.30s arm raise, lateral lean, purple dim, hold stance during ground detonation)
  - BOSS_CAST_SWEEP (~0.65s windup twist & rotation, broad release into crescent sweep)
  - BOSS_ULTIMATE_CHARGE (2.4s charge, scale ~1.10, aura intensification, telegraph warning banner)
  - BOSS_ULTIMATE_RELEASE (0.75-0.85s beam/vortex release, applies 24 damage or MISS/NÉ on dodge)
  - BOSS_HIT
  - BOSS_STUN
  - BOSS_ENRAGED
- Deterministic Weighted Spell Selection:
  - Normal Weights: Arcane Bolt 40%, Probability Orb 30%, Void Rift 20%, Arcane Sweep 10%
  - Enraged Weights: Arcane Bolt 15%, Probability Orb 25%, Void Rift 30%, Arcane Sweep 30%

## 4. ULTIMATE METER & CHAOS VERDICT CHALLENGE
- Meter Capacity: 0 / 4. Increments +1 on every completed normal question (regardless of correct/wrong).
- Exceptions: 0 for Đổi Câu, Probability Draw, Tactical Hand actions, debug interactions, cancelled questions.
- Queueing: At 4/4, meter resets to 0 and queues Chaos Verdict (starts immediately after active combat finishes).
- Phase 1 Telegraph (2.4s): Hides normal question, base card row, and tactical tray. Boss scales to 1.10 with purple aura, dim overlay, and displays STOCHAS CHAOS VERDICT - ĐẠI PHÉP ĐANG ĐƯỢC NIỆM.
- Phase 2 Challenge: 8.0-second countdown timer. Compact question challenge with CTA PHÁ GIẢI ĐẠI PHÉP.
- Success Flow: Correct answer in time -> Karl enters KARL_DODGE -> STOCHAS releases ultimate -> MISS / NÉ! (0 damage) -> exact baseline restored -> normal UI restored.
- Failure Flow: Wrong answer or timeout -> BOSS_ULTIMATE_RELEASE -> apply_damage_to_karl(24) -> respects Shield -> HP overflow -> normal UI restored.
- Tactical Cards in Ultimate:
  - LOẠI TRỪ: disables 1 wrong answer in challenge.
  - THÊM GIỜ: grants +3.0s to Ultimate timer (respects 12.0s cap).
  - ĐỔI CÂU: blocked with warning feedback.
  - CHOÁNG: arms for next retaliation, does not cancel Ultimate.
  - CRITICAL: persists for next strike.
  - BẢO HỘ: grants +6 shield up to 24 cap.

## 5. KARL DODGE, SKILL CAST & TACTICAL PRESENTATION
- Karl Dodge (KARL_DODGE): lateral displacement (-50px), squash/stretch (0.85, 1.15), cyan afterimage ghost, ~0.65s duration, exact baseline return (50, 350).
- Karl Skill Cast (KARL_SKILL_CAST): scale pulse (1.05), glow, hand spark. Triggered on Probability, Choáng, Critical, Bảo Hộ (shorter gesture for utility cards).
- Probability Pre-Draw: 0.50s pre-draw animation (KARL_SKILL_CAST + question fade) before opening modal.
- Tactical Pick Mode: Mouse-following cursor placeholder (HandCursorNode), card hover-lift (-12px), click pulse, and animated card intake to hand.
- Asset Hooks Prepared:
  - ASSET_KARL_DODGE_SEQUENCE: karl_dodge_sequence.png (Placeholder active)
  - ASSET_KARL_SKILL_CAST_SEQUENCE: karl_skill_cast_sequence.png (Placeholder active)
  - ASSET_KARL_CARD_HAND_CURSOR: karl_card_hand_cursor.png (Placeholder active)
  - ASSET_STOCHAS_ULTIMATE_SEQUENCE: stochas_ultimate_sequence.png (Placeholder active)
  - ASSET_TACTICAL_ATLAS: tactical_cards_v1_atlas.png (Placeholder active)

## 6. TEST EVIDENCE & VERIFICATION
- Test Runner: labs/stochas_combat_ui/run_lab_headless.gd
- Command: & "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless -s labs/stochas_combat_ui/run_lab_headless.gd
- Results:
  - Asset Intake: A1 (PASS), A2 (PASS), A3-A5 (PASS)
  - Karl Projectile: K1 (PASS), K2 (PASS), K3 (PASS), K4 (PASS), K5 (PASS)
  - Boss Spells & Damage: GATE 1 (PASS), GATE 2 (PASS), GATE 3 (PASS), GATE 4 (PASS), GATE 5 (PASS)
  - Cases A-D: CASE A (PASS: 8 dmg -> HP 92), CASE B (PASS: 10 dmg -> HP 98), CASE C (PASS: 12 dmg -> Shield 4, HP 100), CASE D (PASS: 14 dmg -> HP 94)
  - Ultimate & Meter: GATE 6 (PASS), GATE 7 (PASS), GATE 8 (PASS), GATE 9-10 (PASS), GATE 11 (PASS), GATE 12 (PASS)
  - Ultimate Resolution: CASE E / GATE 13, 17 (PASS: Dodge -> 0 dmg), GATE 18 (PASS: UI restored), CASE F / GATE 14, 16 (PASS: 24 dmg -> HP 84), GATE 15 (PASS: Timeout -> 24 dmg), CASE G (PASS: Perfect play triggers ultimate)
  - Probability & Tactical: GATE 19 (PASS), GATE 20 (PASS), GATE 21 (PASS), GATE 22 (PASS), T1 (PASS), T3 / Part K (PASS), T9-T10 (PASS), T11-T12 (PASS)
  - Integrity: GATE 23 (PASS: 0 images generated/edited), GATE 24 (PASS: 0 production files modified)
  - Total Checks: ALL 24 GATES AND CASES A-G PASSED PERFECTLY (Exit code 0).

## 7. RECENT PROMPT LOG
### Prompt entry 57
- RECEIVED_AT: 2026-09-14T14:22:21+07:00
- TASK_ID: MATHOS-STOCHAS-ACTION-ULTIMATE-DAMAGE-LAB-233L
- ONE_LINE_INTENT: Boss Action System + per-spell damage + Ultimate Challenge + Karl Dodge + tactical activation presentation.
- RESULT / CURRENT_STATE: READY_FOR_REVIEW (All 24 gates and cases A-G passing, committed locally).

## 8. NEXT ACTION & LAUNCH COMMAND
- Launch interactive LAB for human visual review of Boss Action & Ultimate System:
  & "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --path . labs/stochas_combat_ui/stochas_combat_ui_lab.tscn
- Local commit only: 00398d51e5eff8e565ba80db5338a129900b41e8.
- Do not push to remote repository.
