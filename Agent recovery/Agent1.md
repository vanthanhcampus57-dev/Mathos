# Agent1 — RECOVERY NOTE

> Canonical recovery note for Agent1. This file is maintained as a complete, authoritative state ledger for Agent1.

## 1. CURRENT TASK
- TASK_ID: MATHOS-MAP-RUNTIME-LAYOUT-HOTFIX-046
- TITLE: Map Runtime Layout Hotfix
- FROM: M1
- PRIORITY: CRITICAL
- STATUS: COMPLETED
- PROMPT_RECEIVED_AT: 2026-09-04T21:18:25+07:00
- BASE_HEAD: 95ee75e4ed184198df9af3af4ca8f36952f67997
- ACTIVE_GOAL: Fix the two independently reproduced runtime layout failures in the new Figma World Map implementation (Defect 1: D1 context panel size.y ~1270px offscreen CTA; Defect 2: Map panel collapsing to height 0 inside StagePresentationShell MainContentVBox) without redesigning the approved visual.

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-MAP-RUNTIME-HOTFIX-046
- BRANCH: hotfix/mathos-map-runtime-046
- START_HEAD: 95ee75e4ed184198df9af3af4ca8f36952f67997
- CURRENT_HEAD: 95ee75e4ed184198df9af3af4ca8f36952f67997
- WORKTREE_CLEAN: TRUE

## 3. EXACT PROMPT / INTENT SUMMARY
- Start from base head 95ee75e4ed184198df9af3af4ca8f36952f67997.
- Defect 1: Fix D1 context panel layout order and sizing so height resolves to reference ~228.07px at (right=40, bottom=32, w=350, h=228.07) -> top-left ~ (890, 459.93) with CTA ~ (300, 44) fully visible and clickable.
- Defect 2: Fix Map panel collapsing to height 0 inside StagePresentationShell MainContentVBox. Set size_flags_vertical = Control.SIZE_EXPAND_FILL, appropriate horizontal expansion, container contract, and ensure StagePresentationShell allocates vertical space.
- Approved visual remains untouched: d1_world_map_bg.jpg, Header (40, 28, 408.32, 111.5), HUD (right 40, top 28, 289.69, 42), D1-D4 markers, D1 panel.
- Add regression tests MAP-016 through MAP-025 covering actual runtime container integration, shell integration, AppRoot -> Hub -> Map flow, and multi-resolution.
- Verify fresh save vs completed save state semantics, D2-D4 locked, canonical D1 entry.
- Canonical test runner expected new total: 599 + 10 = 609 tests.
- Do not build Windows binary yet.

## 4. SCOPE
- IN_SCOPE: src/ui/map/dungeon_stage_map_panel.gd, src/ui/stage/stage_presentation_shell.gd, tests/unit/presentation/test_d1_world_map_layout.gd, tests/test_runner.gd, Agent recovery/Agent1.md.
- OUT_OF_SCOPE / PROHIBITED: Redesigning visuals, changing artwork, touching Auth, modifying D1 gameplay progression/combat, unlocking D2-D4, generating images, building Windows package.

## 5. PROGRESS
- COMPLETED:
  1. Read Agent RULE.md and Agent1.md.
  2. Created worktree `D:\Mathos_Worktrees\MATHOS-MAP-RUNTIME-HOTFIX-046` on branch `hotfix/mathos-map-runtime-046` from `95ee75e4ed184198df9af3af4ca8f36952f67997`.
  3. Pre-task update to Agent1.md in worktree and canonical repo.
  4. Reproduced Defect 1 (`_d1_context_panel.size.y` becoming 1270.0 px due to DescriptionLabel autowrap at 1px) and Defect 2 (`DungeonStageMapPanel` size becoming (2504, 0) / (1224, 0) inside MainContentVBox due to missing SIZE_EXPAND flags).
  5. Implemented Defect 1 fix in `src/ui/map/dungeon_stage_map_panel.gd`:
     - Configured `_d1_panel_body_label` with `custom_minimum_size = Vector2(300, 0)`, `size_flags_horizontal = Control.SIZE_EXPAND_FILL`, `size_flags_vertical = Control.SIZE_SHRINK_BEGIN`.
     - In `_update_responsive_layout()`, set position before size and called `reset_size()` so panel height conforms to reference 228.07 px.
     - Added robust `_load_texture_safe()` helper for background artwork texture loading.
  6. Implemented Defect 2 fix in `src/ui/stage/stage_presentation_shell.gd` and `src/ui/map/dungeon_stage_map_panel.gd`:
     - Added `size_flags_horizontal = Control.SIZE_EXPAND_FILL` and `size_flags_vertical = Control.SIZE_EXPAND_FILL` on `DungeonStageMapPanel` in `_ready()` and in shell instantiation.
     - Set `custom_minimum_size = Vector2(1280, 720)` on `DungeonStageMapPanel` and shell subcomponent creation.
     - Adjusted `MainBody` margins to 0 and panel stylebox override to `StyleBoxEmpty` in `MODE_MAP`, cleanly restoring 16px margins and theme stylebox on map exit.
     - Added `NOTIFICATION_RESIZED` handler to `StagePresentationShell` to forward viewport resizes to `_stage_map_panel`.
  7. Added regression tests `MAP-016` through `MAP-025` to `tests/unit/presentation/test_d1_world_map_layout.gd`:
     - MAP-016: D1 context panel size.y strictly bounded near ~228 px (<= 250 px, not ~1270 px).
     - MAP-017: D1 CTA button fully inside 1280x720 viewport (pos + size within bounds).
     - MAP-018: D1 CTA button is clickable and interactive (mouse_filter, not disabled, visible).
     - MAP-019: StagePresentationShell integration allocates size > 0 for Map panel.
     - MAP-020: DungeonStageMapPanel container flags have SIZE_EXPAND_FILL horizontal and vertical.
     - MAP-021: AppRoot -> Hub -> Map flow renders World Map with bounds >= 1200x600.
     - MAP-022: Map root visible rect intersects viewport substantially (area >= 1200x600).
     - MAP-023: 1280x720 geometry inspection verifies panel + CTA fully visible.
     - MAP-024: 1600x900 shell-integrated Map visible and non-zero size.
     - MAP-025: 1920x1080 shell-integrated Map visible and non-zero size.
  8. Updated `tests/test_runner.gd` count from 15 to 25 for "D1 World Map Layout QA".
  9. Executed full canonical test runner: 609 / 609 PASS (599 previous + 10 new regression tests).
- IN_PROGRESS: None.
- NOT_STARTED: None.

## 6. FINDINGS / DECISIONS
- Defect 1 Root Cause: `DescriptionLabel` had `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` without an explicit width constraint and with `size_flags_vertical = Control.SIZE_EXPAND_FILL`. During initial layout calculation at width 1px, Godot wrapped the text into over 70 lines, requiring 1117 px of height. Together with top row (17px), title (28px), button (44px), margins (40px), and spacing, the minimum size became 1270 px, pushing CTA to Y ≈ 1665-1693 px. Setting `custom_minimum_size = Vector2(300, 0)` and `size_flags_vertical = Control.SIZE_SHRINK_BEGIN` completely eliminated the 1px autowrap bug, locking panel height strictly at reference 228.07 px.
- Defect 2 Root Cause: A Control child inside a Container (like `VBoxContainer`) ignores `anchor_right` and `anchor_bottom`. Without `SIZE_EXPAND`, the VBoxContainer allocated 0 height to `DungeonStageMapPanel`, and `clip_contents = true` rendered all child controls invisible. Setting `SIZE_EXPAND_FILL` both horizontally and vertically, setting `custom_minimum_size = Vector2(1280, 720)`, and eliminating shell margins in `MODE_MAP` allows the map to seamlessly fill 1280x720 (or larger viewports like 1600x900 and 1920x1080) edge-to-edge.

## 7. TEST / VERIFICATION EVIDENCE
- `tests/unit/presentation/test_d1_world_map_layout.gd`: 25 / 25 PASS
- Full Canonical Test Runner `tests/test_runner.gd`: 609 / 609 PASS, 0 FAIL, 0 WAITING
- Live AppRoot Flow test: Map panel visible at (1280, 720), D1 rect at (890, 459.93, 350, 228.07), CTA global pos at (914, 585.93, 302, 44), fully inside 1280x720 screen.

## 8. BLOCKERS / ESCALATIONS
- BLOCKED: FALSE
- EXACT_BLOCKER: None

## 9. LATEST REPORT / DELIVERABLE
- STATUS: COMPLETED
- BRANCH: hotfix/mathos-map-runtime-046
- WORKTREE: D:\Mathos_Worktrees\MATHOS-MAP-RUNTIME-HOTFIX-046

## 10. RECOVERY HANDOFF
- NEXT_ACTION: Commit hotfix branch, prepare report for M1 / Agent2 QA.
