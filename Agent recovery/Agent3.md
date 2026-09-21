# Agent3 — RECOVERY NOTE

> Canonical recovery note for Agent3. This file must be updated every time Agent3 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-FULL-COMBAT-CARD-ULTIMATE-KARL-SKILL-RESTORE-241F
- TITLE: Restore Full-Bleed Card Art, Gameplay Ultimate Trigger, and Karl Probability/Random Skill Flow
- FROM: User / P0 HUMAN PRODUCTION BLOCKER
- PRIORITY: P0 / HUMAN PRODUCTION BLOCKER
- BASE: 3568e876c749e26a70b79cb13c6432bca658985b
- STATUS: COMPLETED
- PROMPT_RECEIVED_AT: 2026-09-22T01:20:00+07:00
- UPDATED_AT: 2026-09-22T01:50:00+07:00

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-STORY-PARITY-FIX-185
- BRANCH: task/mathos-story-parity-fix-185
- START_HEAD: 21e41976825b5999e4555e68e31de8eab37102a3
- CURRENT_HEAD: 21e41976825b5999e4555e68e31de8eab37102a3
- FINAL_HEAD: PENDING_COMMIT
- CANONICAL_BASE: 3568e876c749e26a70b79cb13c6432bca658985b
- PRODUCTION_SOURCE_CHANGED: YES (`src/gameplay/combat/card_combat_controller.gd`, `src/ui/combat/boss_combat_panel.gd`, `tests/unit/combat/test_stochas_full_combat_card_ultimate_karl_skill_restore_241f.gd`)
- COMBAT_LAB_CHANGED: NO
- ASSET_BYTES_EDITED: NO (PNG hashes are 100% preserved; 0 bytes edited)
- KARL_ULTIMATE_EXISTING: NO (Karl has no ultimate; restored canonical Probability Gacha V1 System with Tactical Draft and 6 tactical abilities)

## 3. GOAL & REQUIREMENTS
- Recover and restore full combat presentation & gameplay flow based on exact human runtime verdict:
  "Card vẫn chưa tràn viền, không có ultimate, không có random skill các thứ của Karl"
  1. Card Art Full-Bleed: Artwork fills card face edge-to-edge underneath/inside the decorative border (`PRESET_FULL_RECT`, `STRETCH_KEEP_ASPECT_COVERED`) with rounded clipping preserved (`clip_contents = true`), zero internal margin, floating badges/status overlays on top. Zero PNG edits.
  2. Stochas Ultimate Gameplay Trigger: Traced authoritative runtime chain (normal question -> meter +1 -> 4/4 threshold -> ultimate queued -> charge 2.4s -> 8s challenge -> release F01..F08 peak F05 -> resolution: Dodge 0 dmg / Hit 24 dmg). Fixed missing connection in `boss_combat_panel.gd` and wired trigger in `restore_question_after_combat()`.
  3. Karl Probability/Random Skill Recovery: Restored canonical Task 232L Probability Gacha V1 System:
     - Card 4 ("XÁC SUẤT") requires 3 charges (PROBABILITY_METER_MAX = 3, +1 per correct answer).
     - Locked while < 3 charges with "CHƯA KÍCH HOẠT" and progress counter "%d/3".
     - Unlocks at 3 charges with "SẴN SÀNG".
     - Clicking it consumes 3 charges and opens `_probability_draw_modal` drafting 3 cards from canonical `TACTICAL_CARDS` with atlas textures from `tactical_cards_v1_atlas.png`.
     - Tactical cards added to `TacticalHandTray` (max 3) and can be activated for game-changing effects: Eliminate wrong answer, Reroll question, Add 15s time (+3s in ultimate), Arm Stun charge, Arm +5 DMG Critical, or Grant +6 Shield.
- ABSOLUTE RULE: DO NOT REDESIGN GAMEPLAY. DO NOT INVENT NEW KARL SKILLS. DO NOT INVENT A KARL ULTIMATE IF NONE EXISTS.
- ZERO image generation or editing. Local commit only, DO NOT PUSH.

## 4. ACCEPTANCE GATES
- GATE 1: Archaeological investigation of card art full-bleed layout, Stochas ultimate trigger pipeline in production, and Karl Probability/Random skill implementation. [PASSED]
- GATE 2: Card art full-bleed layout implemented with proper border-over-art layering, STRETCH_KEEP_ASPECT_COVERED, and clip_contents = true across all 4 cards. [PASSED]
- GATE 3: Stochas Ultimate production trigger connected and verified: 4/4 meter leads to full Charge (2.4s) -> 8s Challenge -> Release F01..F08 in actual gameplay. [PASSED]
- GATE 4: Karl Probability / random skill flow restored with canonical availability (3 charges), disabled "CHƯA KÍCH HOẠT" state, tactical draft modal, and 6 tactical abilities. [PASSED]
- GATE 5: Question fade and full authored boss cast timings (Bolt 1.18s, Orb 1.80s, Rift 1.50s, Sweep 1.75s) 100% preserved. [PASSED]
- GATE 6: Automated test suites (including new 241F test suite) passing 100%. [PASSED]
- GATE 7: Local commit created, no push, no image byte edits. [PASSED]

## 5. RECENT PROMPT LOG
- 2026-09-19 10:53 [MATHOS-STOCHAS-FULL-COMBAT-VISUAL-PARITY-241D]: P0 blocker report: question panel too short/compressed, cards too small, combat VFX missing.
- 2026-09-21 23:46 [MATHOS-STOCHAS-COMBAT-PRESENTATION-PARITY-241E]: P0 human verdict rejection: "Card vẫn nhỏ, không mờ question khi thi triển animation, các animation của boss bị cắt giảm nhiều". Restored canonical card size (160x225), question combat fade, and full authored boss animations.
- 2026-09-22 01:20 [MATHOS-FULL-COMBAT-CARD-ULTIMATE-KARL-SKILL-RESTORE-241F]: P0 human verdict rejection: "Card vẫn chưa tràn viền, không có ultimate, không có random skill các thứ của Karl". Restoring full-bleed card art, gameplay ultimate trigger, and Karl probability/random skill flow.
