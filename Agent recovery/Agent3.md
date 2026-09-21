# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-STOCHAS-COMBAT-PRESENTATION-PARITY-241E
- TITLE: Restore Full Combat Presentation Parity (Card Scale, Question Fade during Combat, Full Author-Timed Boss Cast Animations)
- FROM: User / P0 HUMAN VISUAL PARITY BLOCKER
- PRIORITY: P0 / HUMAN VISUAL PARITY BLOCKER
- BASE: 240cbc66b4216202f482ad6cbf11a11b0af126f3
- STATUS: IN_PROGRESS
- PROMPT_RECEIVED_AT: 2026-09-21T23:46:50+07:00
- UPDATED_AT: 2026-09-22T00:10:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 240cbc66b4216202f482ad6cbf11a11b0af126f3
- CURRENT_HEAD: 240cbc66b4216202f482ad6cbf11a11b0af126f3
- FINAL_HEAD: PENDING
- CANONICAL_BASE: 240cbc66b4216202f482ad6cbf11a11b0af126f3
- PRODUCTION_SOURCE_CHANGED: YES (`src/ui/combat/boss_combat_panel.gd`, `src/ui/question/question_panel.gd`, `tests/unit/combat/test_stochas_full_combat_presentation_parity_241e.gd`, `tests/unit/combat/test_stochas_full_combat_visual_parity_241d.gd`, `tests/unit/combat/test_stochas_production_ui_parity_hotfix_241c.gd`)
- COMBAT_LAB_CHANGED: NO
- ASSET_BYTES_EDITED: NO (PNG hashes are 100% preserved; 0 bytes edited)

## 3. GOAL & REQUIREMENTS
- Recover and restore full combat presentation parity based on exact human runtime verdict:
  "Card vẫn nhỏ, không mờ question khi thi triển animation, các animation của boss bị cắt giảm nhiều"
  1. Card Hand Scale: Restored canonical approved Task 216 card dimensions: `CARD_WIDTH = 160.0`, `CARD_HEIGHT = 225.0`, `CARD_GAP = 16.0`. 4 cards row width 688px centered at x=296 on 1280 screen. Karl entity at x=32..292 (260x260), so Karl's right edge is 292 <= card row at 296 (0 overlap).
  2. Question Panel Fade during Combat: Smoothly fades question panel (modulate.a = 0.22 over 0.20s) when combat actions/animations are deployed (Karl Strike, Defend, Heal, Skill, Boss attacks, Ultimate Charge/Release), and smoothly restores (modulate.a = 1.0 over 0.24s) when recovery finishes. Input is safely disabled during fade with zero loss of state or answers.
  3. Full Boss Animations: Restored the 4 complete authored animation sequences from lab:
     - ARCANE_BOLT (1.18s): 0.15s anticipation, 0.18s snap/cast, 0.50s travel, 0.35s recovery.
     - PROBABILITY_ORB (1.80s): 0.35s vertical float & scale up, 0.25s release, 0.35s prep, 0.55s travel, 0.30s recovery.
     - VOID_RIFT (1.50s): 0.30s summon & sink, 0.60s rift expansion, 0.30s collapse, 0.30s recovery.
     - ARCANE_SWEEP (1.75s): 0.35s windup, 0.35s lateral sweep lunge, 0.65s travel, 0.20s fade, 0.20s recovery.
     - Idle floating in `_process()` guarded by `not _is_animating_spell` so tweens are not overwritten.
- ABSOLUTE RULE: DO NOT REDESIGN FROM SCRATCH. DO NOT GENERATE NEW IMAGES. Recover existing assets and implementations from repo/history.
- ULTIMATE LOCK: Stochas Ultimate Charge (entry flash + F03..F06) and Release (F01..F08 peak at F05) MUST REMAIN 100% UNCHANGED.
- GAMEPLAY CONTRACT LOCK: 0/4 meter, 2.4s charge, 8s challenge, Dodge 0 dmg / Fail 24 dmg (shield -> HP), spell damage values unchanged.
- ZERO image generation or editing. Local commit only, DO NOT PUSH.

## 4. ACCEPTANCE GATES
- GATE 1: Phase 1 archaeology: identify approved card dimensions (from lab/history), question fade constants/logic, and full authored boss cast sequences from `stochas_combat_ui_lab.gd`. [PASSED]
- GATE 2: Card hand scale restored to approved larger size (160x225, gap 16, row 688 at x=296), fits viewport cleanly, preserves lift and readability without overlapping Karl (x=32..292). [PASSED]
- GATE 3: Question panel fade cleanly connected and synchronized with combat deployment (fades to 0.22 over 0.20s on attack/spell, restores to 1.0 over 0.24s on finish, disables input safely). [PASSED]
- GATE 4: Full authored boss animations implemented: anticipation, cast motion, projectile, impact, follow-through/recovery for Bolt (1.18s), Orb (1.80s), Rift (1.50s), Sweep (1.75s) without premature cuts. [PASSED]
- GATE 5: Stochas Ultimate Charge & Release visual, transforms, and contract remain 100% intact. [PASSED]
- GATE 6: All automated test suites updated and passing 100%. [PASSED]
- GATE 7: Local commit created, no push, no image byte edits. [IN_PROGRESS]

## 5. RECENT PROMPT LOG
- 2026-09-19 10:53 [MATHOS-STOCHAS-FULL-COMBAT-VISUAL-PARITY-241D]: P0 blocker report: question panel too short/compressed, cards too small, combat VFX missing. Restored question panel height to 370px, card hand to 132x188px, connected combat VFX.
- 2026-09-21 23:46 [MATHOS-STOCHAS-COMBAT-PRESENTATION-PARITY-241E]: P0 human verdict rejection: "Card vẫn nhỏ, không mờ question khi thi triển animation, các animation của boss bị cắt giảm nhiều". Restoring canonical card size (160x225), question combat fade (modulate.a=0.22, input gating), and full authored boss animations (Bolt 1.18s, Orb 1.80s, Rift 1.50s, Sweep 1.75s).
