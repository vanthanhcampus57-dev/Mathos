# Agent2 -- RECOVERY NOTE

> Canonical recovery note for Agent2. This file must be updated every time Agent2 receives a prompt, and updated again before sending a report if state changed.

## 1. CURRENT TASK
- TASK_ID: MATHOS-P0-SAVE-PROGRESSION-CONSISTENCY-079
- TITLE: Fix persistence/progression divergence found during full D1 human QA
- FROM: M1
- PRIORITY: P0 / CRITICAL
- ROLE: PERSISTENCE / PROGRESSION CONSISTENCY ENGINEER
- STATUS: COMPLETED
- PROMPT_RECEIVED_AT: 2026-09-06T16:19:16+07:00
- BASE_HEAD: 1965272ffbc91f03a75f742bcb8fcbdcbad4972a

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-P0-SAVE-PROGRESSION-079
- BRANCH: task/mathos-p0-save-progression-079
- START_HEAD: 1965272ffbc91f03a75f742bcb8fcbdcbad4972a
- CURRENT_HEAD: 7da2329bff798995eca0d8a2dd1d66a474f3ed4e
- CANONICAL_BASE: 1965272ffbc91f03a75f742bcb8fcbdcbad4972a
- WORKTREE_CLEAN: TRUE

## 3. EXACT PROMPT / INTENT SUMMARY
- GOAL: Fix persistence/progression divergence found during full D1 human QA.
- CONFIRMED FAILURES:
  1. D1 completion persisted incorrectly after restart. Before restart: Mảnh vỡ: 1, Dungeon: 1/4, Dungeon I = HOÀN THÀNH. After closing/reopening game: Hub displayed 'Tiếp tục: stage_02_01' but Map displayed Mảnh vỡ: 0, Dungeon: 0/4, Dungeon I = ĐANG MỞ. Deleting prologue_gate.json must NOT delete/alter dungeon progress.
  2. Hub Continue and Map unlock state conflict. Hub Continue points to stage_02_01, but Map Dungeon II remains KHÓA. These states cannot coexist.
  3. D1 completion reward/progression must remain durable (fragment_01, completed dungeon count, D1 completion, stage completion/progression across restart).
  4. Current content expectation: D2-D4 are frozen/locked. Finishing D1 must NOT expose playable D2 through Continue unless canonical unlock configuration explicitly says D2 is playable.
- CONSTRAINTS:
  - DO NOT modify src/app/app_root.gd unless absolutely unavoidable (Agent1 task 078 ownership). Prefer persistence/progression/domain/save services. If root cause requires app_root.gd modification, STOP before editing and REPORT exact required change as a blocker.
  - Do not modify QuestionPanel/interactions fixed in 078.
  - Do not touch Auth visual, Map visual layout, Prologue visuals, Story UI, Practice UI, Boss UI, Math renderer, assets, D1 fog/background.
  - No SaveSchema migration unless absolutely necessary.
  - Local-only recovery notes.
  - Full test runner PASS.

## 4. SCOPE
- IN_SCOPE:
  - Create clean worktree D:\Mathos_Worktrees\MATHOS-P0-SAVE-PROGRESSION-079 from 1965272ffbc91f03a75f742bcb8fcbdcbad4972a.
  - Investigate save data source(s), guest save persistence, Map progression source, Hub Continue source, dungeon completion source, fragment inventory persistence, current_stage / next_stage pointer, serialization/deserialization, defaults applied on boot, accidental session-only progression, duplicate sources of truth, reset/new-game pathways, and Prologue gate isolation.
  - Fix persistence/progression divergence across restart.
  - Ensure Hub Continue and Map unlock states agree and respect frozen/locked status of D2.
  - Add comprehensive automated tests for persistence, restart reload, gate isolation, and Hub vs Map lock consistency.
  - Run full canonical test runner.
- PROHIBITED_SCOPE:
  - Modifying src/app/app_root.gd without prior blocker report to M1.
  - Modifying QuestionPanel or question interactions.
  - Modifying Auth, Map, Prologue, Story, Practice, Boss visual layouts or assets.
  - Breaking save schema compatibility.

## 5. PROGRESS
- COMPLETED:
  1. Investigated root cause of persistence/progression divergence:
     - Map showed 0/4 and D1 open on restart because `AppRoot.bootstrap_runtime()` never hydrated `_progress_service` from disk save on boot without a manual Continue click.
     - Hub Continue showed 'Tiếp tục: stage_02_01' because `AppRoot.refresh_continue_availability()` directly read the last item of `unlocked_stage_ids` from `SaveService.load()`, which included `stage_02_01` when D1 was completed.
  2. Implemented content-driven playable dungeon configuration:
     - Added `"playable_dungeon_ids": ["dungeon_01"]` to `content/config/game_config.json` (passes `validate_content.gd`).
     - Added `is_dungeon_playable(dungeon_id)` and `get_playable_dungeon_ids()` to `ValidatedCatalog` (defaults safely to true if unconfigured).
  3. Implemented safe, non-invasive boot-time hydration:
     - Updated `ProgressSaveBridge._init()` to auto-hydrate `_player_persistent` and `_progress_service` on boot for canonical `user://` store without modifying `src/app/app_root.gd`.
     - Added `apply_restored_state()` and `reset_to_fresh()` to `ProgressService`.
     - Updated `GameFlowService.start_new_game()` to reset progression and player balances on New Game.
  4. Implemented boundary sanitization:
     - In `SaveService.load()`, added `_sanitize_snapshot_for_playable_content()` to filter unlocked stages/dungeons to playable content boundary.
     - In `ProgressSaveBridge.get_legal_entry_stage_id()`, filtered unlocked stages to playable dungeons, returning latest playable cleared stage (`stage_01_05`) when all are cleared.
  5. Preserved AppRoot completely untouched (100% adherence to task 078 ownership).
  6. Added comprehensive automated test suite `tests/unit/presentation/test_save_progression_consistency.gd` covering all 8 scenarios (PASS 8 / FAIL 0).
  7. Verified all regressions pass:
     - `test_save_progression_consistency.gd`: PASS 8 / FAIL 0
     - `test_d1_world_map_layout.gd`: PASS 30 / 30
     - `test_d1_critical_flow_fixes.gd`: PASS 6 / 6
     - `test_prologue_production_integration.gd`: PASS 23 / 23
     - `test_d1_story_visual.gd`: PASS 15 / 15
     - `test_finished_game_flow_batch1.gd`: PASS 5 / 5
     - `test_game_finish_flow_batch2b.gd`: PASS 7 / 7
     - Full canonical test runner: PASS
  8. Committed fix: `7da2329bff798995eca0d8a2dd1d66a474f3ed4e`.
- IN_PROGRESS: None
- NOT_STARTED: None

## 6. FINDINGS / DECISIONS
- D1 DURABILITY RESOLVED: On reboot, `ProgressSaveBridge` immediately hydrates `_player_persistent` balances and `_progress_service` state. Map reads hydrated state immediately on boot (Mảnh vỡ: 1, Dungeon: 1/4, Dungeon I = HOÀN THÀNH, D2-D4 = KHÓA).
- HUB CONTINUE VS MAP LOCK RESOLVED: `SaveService.load()` sanitizes `unlocked_stage_ids` against `playable_dungeon_ids`. Hub Continue button displays `Tiếp tục: Chúa Tể Đầm Lầy (stage_01_05)`. Clicking Continue routes to `stage_01_05`. Stage `stage_02_01` is never offered while D2 is frozen.
- PROLOGUE GATE ISOLATION VERIFIED: `prologue_gate.json` resides in its own service and path. Deleting it does not modify `save_v1.json` or alter dungeon progression.
- GENERIC ARCHITECTURE: Content-driven configuration via `game_config.json` ("playable_dungeon_ids") allows enabling D2 seamlessly in future releases without code modifications.
- APPROOT PRESERVED: `src/app/app_root.gd` was 100% UNTOUCHED throughout this task.

## 7. TEST / VERIFICATION EVIDENCE
- `tests/unit/presentation/test_save_progression_consistency.gd`: PASS 8 / FAIL 0.
- `tests/unit/presentation/test_d1_world_map_layout.gd`: PASS 30 / 30.
- `tests/unit/presentation/test_d1_critical_flow_fixes.gd`: PASS 6 / 6.
- `tests/unit/presentation/test_prologue_production_integration.gd`: PASS 23 / 23.
- `tests/unit/presentation/test_d1_story_visual.gd`: PASS 15 / 15.
- `tests/unit/presentation/test_finished_game_flow_batch1.gd`: PASS 5 / 5.
- `tests/unit/presentation/test_game_finish_flow_batch2b.gd`: PASS 7 / 7.
- Full canonical test harness (`tests/test_runner.gd`): ALL REGISTERED TESTS PASS.

## 8. BLOCKERS / AUTHORITY
- BLOCKED: NO
- BLOCKERS: NONE. Persistence divergence and Hub vs Map lock conflicts are completely resolved.

## 9. LATEST REPORT / DELIVERABLE
- REPORT_STATUS: PASS
- FINAL_HEAD: 7da2329bff798995eca0d8a2dd1d66a474f3ed4e
- VERDICT: READY_FOR_HUMAN_QA_RETEST

## 10. RECOVERY HANDOFF
- NEXT_ACTION: Final head 7da2329bff798995eca0d8a2dd1d66a474f3ed4e ready for human QA re-test of D1 restart persistence and Hub Continue / Map lock agreement.
- LAST_UPDATED_BY: Agent2
- LAST_UPDATED_AT: 2026-09-07T09:45:00+07:00

## 11. RECENT PROMPT LOG

### Prompt Entry 62
- RECEIVED_AT: 2026-09-06T16:19:16+07:00
- TASK_ID: MATHOS-P0-SAVE-PROGRESSION-CONSISTENCY-079
- ONE_LINE_INTENT: Fix persistence/progression divergence across app restart (D1 completion, fragments, Hub Continue vs Map lock consistency).
- RESULT / CURRENT_STATE: PASS / COMPLETED
- HEAD_AFTER_WORK: 7da2329bff798995eca0d8a2dd1d66a474f3ed4e

### Prompt Entry 61
- RECEIVED_AT: 2026-09-06T13:09:53+07:00
- TASK_ID: MATHOS-PROLOGUE-BEAT01-02-QUICK-REQA-076
- ONE_LINE_INTENT: Verify hotfix 075 completely resolves RunePrimary naming blocker and accepted Beat 1 + Beat 2 production flow remains intact.
- RESULT / CURRENT_STATE: PASS / VERDICT: READY_FOR_WINDOWS_HUMAN_REVIEW_BUILD
- HEAD_AFTER_WORK: eb076abd2cc3278e3620316889e7903ff77a2b7b

### Prompt Entry 60
- RECEIVED_AT: 2026-09-06T11:09:03+07:00
- TASK_ID: MATHOS-PROLOGUE-BEAT01-02-INDEPENDENT-QA-074
- ONE_LINE_INTENT: Independently verify human-accepted Beat 1 and Beat 2 integration into Mathos production flow (A1 task 073).
- RESULT / CURRENT_STATE: BLOCKED (Defect identified: Beat 1 RunePrimary layer named RunePulse in prologue_player.gd:211)
- HEAD_AFTER_WORK: 47041ac10df4cfeb11ad9ef7718fc0969bcdce92

### Prompt Entry 59
- RECEIVED_AT: 2026-09-05T08:52:59+07:00
- TASK_ID: MATHOS-PROLOGUE-FIRST-RUN-GATE-063
- ONE_LINE_INTENT: Implement safe logic to show Prologue exactly once before player's first Dungeon I entry without save schema corruption.
- RESULT / CURRENT_STATE: PASS / CLOSED
- HEAD_AFTER_WORK: 8d6ca9dd362eb7ae5c8224cb11ceffdc4572bc68

### Prompt Entry 58
- RECEIVED_AT: 2026-09-05T08:33:15+07:00
- TASK_ID: MATHOS-D1-STORY-INDEPENDENT-REQA-044
- ONE_LINE_INTENT: Independently verify human-approved D1 Story Figma implementation on candidate 16c40a3.
- RESULT / CURRENT_STATE: FAIL / REJECT_STORY_CANDIDATE (P0 Visual & Input Leak from LessonPanel behind StoryPanel)
- HEAD_AFTER_WORK: 16c40a35a4b3d5b56fcc62cc2955e2205217479c

### Prompt Entry 57
- RECEIVED_AT: 2026-09-05T07:15:03+07:00
- TASK_ID: MATHOS-MAP-VISUAL-PARITY-INDEPENDENT-REQA-043
- ONE_LINE_INTENT: Re-QA new Map candidate 8530af6 from Agent1 after visual parity fixes.
- RESULT / CURRENT_STATE: PASS / CLOSED (VERDICT: READY_FOR_MAP_WINDOWS_REBUILD)
- HEAD_AFTER_WORK: 8530af693f90f0fa3acbf0da3b6962e5fd6afcfb
