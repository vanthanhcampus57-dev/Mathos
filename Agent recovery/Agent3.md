# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-PROBABILITY-GACHA-VFX-LAB-INTEGRATION-232L
- TITLE: WAD2 asset intake + Probability Gacha V1 + Karl projectile + STOCHAS multi-spell LAB integration
- FROM: User / P0 HUMAN COMBAT LAB
- PRIORITY: P0 / HUMAN COMBAT LAB
- BASE: eb9767df49b8bbe638031b49a4605e856c084ab5
- STATUS: READY_FOR_REVIEW
- PROMPT_RECEIVED_AT: 2026-09-13T14:07:31+07:00
- UPDATED_AT: 2026-09-13T14:19:15+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: eb9767df49b8bbe638031b49a4605e856c084ab5
- CURRENT_HEAD: 6598b9a8391f71947f1f4613763edb95069f12f4
- FINAL_HEAD: 6598b9a8391f71947f1f4613763edb95069f12f4
- CANONICAL_BASE: eb9767df49b8bbe638031b49a4605e856c084ab5
- PRODUCTION_SOURCE_CHANGED: NO (LAB only: res://labs/stochas_combat_ui/ and res://assets/vfx/combat/)

## 3. ASSET INTAKE & VALIDATION
- ZIP Source: `C:\Users\Admin\Downloads\MATHOS_WAD2_229C_COMBAT_VFX_FINAL.zip` (Found: YES)
- Staging Location: `D:\Mathos\Agent recovery\WAD2 Packages\MATHOS_WAD2_229C_COMBAT_VFX_FINAL.zip` (Untouched copy, 1,174,491 bytes)
- Project Deployed Assets (`res://assets/vfx/combat/`):
  1. `karl_arcane_projectile.png` (608x231, RGBA, SHA256: `cb4f5b2bdc7ea860618e44541fdecf4e87dd08fcd3618c471108315ff7f1ddb2`)
  2. `stochas_arcane_bolt.png` (679x300, RGBA, SHA256: `3b340ac92b0b1c7a5272f82030c163c49caef6f4de12613e9dc674d5ed1fb80f`)
  3. `stochas_probability_orb.png` (419x390, RGBA, SHA256: `a65db32a39f846e57636bdb7be14aa2b59c47d1466dfab7df5c7d2e27530ba23`)
  4. `stochas_void_rift.png` (475x547, RGBA, SHA256: `0c4f0a49b2934b1ddf40ddea3f568cf577e7161db5ed259c83a07d71a753537e`)
  5. `stochas_arcane_sweep.png` (546x402, RGBA, SHA256: `6e03b20119fda2e37d849e3b7361fd51764e625e3249fcdc583c83b02d06a563`)
- Asset Validation: PASS (Exactly 5 PNGs + MANIFEST.md, alpha channel present on all 5, 0 hash conflicts, 0 images generated/edited).

## 4. ARCHITECTURE & IMPLEMENTATION DETAILS

### 4.1 Karl Arcane Projectile
- Origin: Karl casting hand at `Vector2(268, 432)` (`karl_arcane_projectile.png`).
- Travel: Left-to-right toward STOCHAS `Vector2(950, 350)` over `0.45s` (`TRANS_QUAD`, `EASE_IN`).
- Impact: Native particle spark spawns at impact point, STOCHAS executes HIT reaction with recoil and floating damage text.
- Damage: Exactly 10 base damage; if `is_critical_armed == true`, deals exactly 15 damage and resets critical flag. Damage is applied strictly on impact.
- Recovery: Karl returns to IDLE and question restores alpha after hit animation concludes (~0.90s total).

### 4.2 STOCHAS Multi-Spells
- 4 Presentation Spells:
  - Arcane Bolt (`stochas_arcane_bolt.png`): Travels right-to-left in `0.50s` to Karl.
  - Probability Orb (`stochas_probability_orb.png`): Pulses/orbits near boss for `0.35s`, arcs to Karl in `0.55s`.
  - Void Rift (`stochas_void_rift.png`): Opens on battlefield ground near Karl `Vector2(220, 470)`, expands over `0.60s`, detonates, collapses in `0.30s`.
  - Arcane Sweep (`stochas_arcane_sweep.png`): Manifests wide crescent, sweeps right-to-left in `0.65s`, fades out in `0.20s`.
- Damage Integration: All 4 spells route strictly to `apply_damage_to_karl(10)`.
- Shield-First Resolution: Shield absorbs incoming damage first, triggers automatic shield-break VFX if depleted, overflows remainder to HP.
- Question Combat Fade: Question panel remains faded at `modulate:a = 0.22` with inputs locked for the entire duration of all spell animations.
- Selection: Deterministic seeded RNG `boss_spell_rng.randi_range(0, 3)` selects spell on wrong answer.
- Debug Hotkeys: F1 (Arcane Bolt), F2 (Probability Orb), F3 (Void Rift), F4 (Arcane Sweep).

### 4.3 Probability Meter & Gacha V1 Engine
- Meter: Capacity 3 charges (`0/3` to `3/3`). Answering correctly grants `+1` charge; wrong answer grants `+0`; tactical question reroll grants `+0`.
- Card 4 Indicator: Displays `0/3`, `1/3`, `2/3`, or `SẴN SÀNG` (READY). Clicking before ready shows feedback `XÁC SUẤT X/3` without consuming action.
- Draw Overlay: Native centered modal dialog (`680x380`). Fades question behind it. Presents 3 mutually distinct cards ($Card_1 \neq Card_2 \neq Card_3$).
- Weighted Odds: 70% Common / 30% Rare.
- Pity Engine: If 2 consecutive draws show zero Rare cards, the 3rd draw guarantees at least 1 Rare card in slot 1.
- Draw Resolution: Consumes 3 charges (`3 -> 0`). Normal turn is NOT consumed.

### 4.4 Tactical Hand & The Six Cards
- Tactical Hand Tray: Clean UI container at `Vector2(24, 96)` (below Karl HUD at `(24, 20)`, size `(300, 52)`), capacity 3 cards.
- Full Hand Overflow: Invokes Replace/Discard modal allowing player to replace any of the 3 held cards or discard the new card.
- Six Cards:
  1. `LOẠI TRỪ` (COMMON): Eliminates 1 incorrect option button; never eliminates correct option; prevents elimination if only 2 choices remain.
  2. `ĐỔI CÂU` (COMMON): Fetches clean replacement question with timer reset; 0 boss retaliation, 0 damage, 0 meter gain.
  3. `THÊM GIỜ` (COMMON): Grants +15.0s to question timer; respects 90.0s cap.
  4. `CHOÁNG` (RARE): Arms stun for active question. If answered correctly, boss enters STUN state and receives 1 stun charge that cancels the NEXT boss retaliation. If answered incorrectly, card is lost with 0 stun and boss retaliates normally.
  5. `CRITICAL` (RARE): Arms next successful STRIKE for 15 total damage (+5 bonus). Persists through DEFEND, HEAL, and failed Strike attempts.
  6. `BẢO HỘ` (RARE): Instantly grants +6 Shield via `set_shield()`; enforces 24 max shield cap; does not consume turn.

### 4.5 AI Event Signals
Exposed on `stochas_combat_ui_lab.gd`:
- `probability_charge_changed(current: int, max_val: int)`
- `probability_ready()`
- `probability_draw_started()`
- `probability_cards_revealed(cards: Array)`
- `tactical_card_selected(card_id: String, slot: int)`
- `tactical_card_used(card_id: String)`
- `stun_armed()`
- `stun_triggered()`
- `critical_armed()`
- `critical_triggered(damage: int)`
- `aegis_triggered(shield_gain: int)`

## 5. TEST EVIDENCE & VERIFICATION
- Test Runner: `labs/stochas_combat_ui/run_lab_headless.gd`
- Command: `& "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --headless -s labs/stochas_combat_ui/run_lab_headless.gd`
- Results:
  - Asset Intake: A1 (PASS), A2 (PASS), A3-A5 (PASS)
  - Karl Projectile: K1 (PASS), K2 (PASS), K3 (PASS), K4 (PASS), K5 (PASS)
  - Boss Spells: B1 (PASS), B2 (PASS), B3 (PASS), B4 (PASS), B5 (PASS), B6 (PASS), B7 (PASS)
  - Probability System: P1 (PASS), P2 (PASS), P3 (PASS), P4 (PASS), P5 (PASS), P6-P8 (PASS), P9 (PASS), P10 (PASS)
  - Tactical Cards: T1 (PASS), T2 (PASS), T3 (PASS), T4 (PASS), T5 (PASS), T6 (PASS), T7 (PASS), T8 (PASS), T9 (PASS), T10 (PASS), T11 (PASS), T12 (PASS)
  - Regression Gates: R1-R3 (PASS), R4 (PASS), R5 (PASS), R6 (PASS), R7 (PASS), R8 (PASS), R9 (PASS), R10 (PASS)
  - Total Checks: 49/49 PASSED (Exit code 0).

## 6. RECENT PROMPT LOG
### Prompt entry 56
- RECEIVED_AT: 2026-09-13T14:07:31+07:00
- TASK_ID: MATHOS-PROBABILITY-GACHA-VFX-LAB-INTEGRATION-232L
- ONE_LINE_INTENT: WAD2 asset intake + Probability Gacha V1 + Karl projectile + STOCHAS multi-spell LAB integration.
- RESULT / CURRENT_STATE: READY_FOR_REVIEW (All 49 test gates passing, final HEAD committed locally).

## 7. NEXT ACTION
- Await human visual review and verification of Probability Gacha and Combat VFX in LAB:
  `& "D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe" --path . labs/stochas_combat_ui/stochas_combat_ui_lab.tscn`
- Do not push to remote repository.
