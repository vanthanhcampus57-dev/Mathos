# Agent1 — RECOVERY NOTE

> Canonical recovery note for Agent1. This file is maintained as a complete, authoritative state ledger for Agent1.

## 1. CURRENT TASK
- TASK_ID: MATHOS-MAP-HUMAN-VISUAL-PARITY-HOTFIX-048
- TITLE: Map Human Visual Parity Hotfix
- FROM: M1
- PRIORITY: CRITICAL
- STATUS: READY_FOR_REVIEW
- PROMPT_RECEIVED_AT: 2026-09-05T06:25:13+07:00
- BASE_HEAD: a3349b6791394b198fdfb6cf9098784312765d0f
- ACTIVE_GOAL: Fix ONLY the visual discrepancies found in the real Windows human-review Map screenshot without redesigning the approved visual:
  1. Critical: Remove white fog / white vignette leak along right edge, upper-right near D3, lower edge, and behind D1 panel. Isolate MODE_MAP from D1 gameplay atmospheric effects and restore on mode exit.
  2. Approved Map Readability Overlays: Ensure dark readability overlays only (vertical: bottom ~0.85, top ~0.40; horizontal: left ~0.60, right ~0.50). No white endpoints or bright wash.
  3. Dungeon I Marker Parity: 64x64 reference footprint, rounded-square outer cyan magical frame, dark inner plate, cyan icon/rune treatment, selected cyan glow, gold completion accent ONLY when completed (fresh: ĐANG MỞ; completed: ✓ HOÀN THÀNH). No generic circle.
  4. Dungeon II/III/IV Marker Parity: 44x44 rounded-square plates (radius ~12), D2 violet/indigo + lock, D3 cyan/navy + lock, D4 slate + lock.
  5. Header Parity: Remove invented "← Trở về" row from inside the approved title panel.
  6. Invariants: Keep background artwork, landmark positions, D1 panel placement, fresh/completed semantics, D2-D4 lock logic, D1 entry/replay, Auth untouched, D1 gameplay untouched.
  7. Multi-resolution visual verification: 1280x720, 1600x900, 1920x1080.
  8. Regression tests: Add MAP-026 through MAP-030 (target full baseline: 609 + 5 = 614 tests passing).

## 2. WORKSPACE / GIT
- PROJECT: Mathos
- WORKTREE: D:\Mathos_Worktrees\MATHOS-MAP-PARITY-HOTFIX-048
- BRANCH: hotfix/mathos-map-parity-048
- START_HEAD: a3349b6791394b198fdfb6cf9098784312765d0f
- CURRENT_HEAD: 1f54eebf3c8bf1173ba720c6090658eb7f1553fc
- WORKTREE_CLEAN: TRUE

## 3. EXACT PROMPT / INTENT SUMMARY
- Start from base head a3349b6791394b198fdfb6cf9098784312765d0f.
- Human review result: NOT_ACCEPTED_YET.
- Goal: Fix visual discrepancies in real Windows runtime map:
  - Eliminate white wash/fog leaking in from default Gradient endpoints and StagePresentationShell atmospheric overlays.
  - Fix D1 marker to match approved 64x64 rounded-square magical frame and inner plate.
  - Fix D2-D4 locked markers to match approved 44x44 rounded-square plates with lock icons.
  - Remove "← Trở về" row from header panel.
  - Add regression tests MAP-026..MAP-030. Expected full runner count: 614.
  - Verify visually at 1280x720, 1600x900, 1920x1080.
  - Do NOT build final Windows release yet (source candidate only).

## 4. SCOPE
- IN_SCOPE: src/ui/map/dungeon_stage_map_panel.gd, src/ui/stage/stage_presentation_shell.gd, tests/unit/presentation/test_d1_world_map_layout.gd, tests/test_runner.gd, Agent recovery/Agent1.md.
- OUT_OF_SCOPE / PROHIBITED: Redesigning visuals, generating images, modifying map artwork, modifying gameplay/progression, modifying Auth, unlocking D2-D4, overwriting final release binary.

## 5. PROGRESS
- COMPLETED:
  1. Read Agent RULE.md and Agent1.md.
  2. Created worktree `D:\Mathos_Worktrees\MATHOS-MAP-PARITY-HOTFIX-048` on branch `hotfix/mathos-map-parity-048` from `a3349b6791394b198fdfb6cf9098784312765d0f`.
  3. Pre-task update to Agent1.md in worktree and canonical repo.
  4. Root cause investigation of white fog/wash leak:
     - Discovered that in Godot 4, `Gradient.new()` initializes with default points (offset 0.0 black, offset 1.0 pure white `(1,1,1,1)`). Calling `add_point(1.0, ...)` added a duplicate point without removing point 1, leaving pure opaque white at offset 1.0 on both horizontal overlay (entire right edge / upper-right near D3) and vertical overlay (bottom edge / behind D1 context panel).
     - Fixed by setting `grad_v.offsets` / `grad_v.colors` and `grad_h.offsets` / `grad_h.colors` directly as PackedArrays containing ONLY dark navy colors (`Color(0.02, 0.04, 0.08, ...)`). Verified zero white endpoints.
     - Also ensured `StagePresentationShell`'s `_procedural_fog_container` and `FogOverlayTextureRect` are strictly disabled (`visible = false`) in `ViewMode.MODE_MAP` and restored upon mode exit.
  5. Implemented D1 Marker visual parity:
     - 64x64 footprint with rounded-square outer magical frame (`corner_radius = 16`, NOT circular 32).
     - Dark inner shrine plate (`bg_color = Color(0.04, 0.08, 0.16, 0.94)`).
     - Cyan rune treatment `◈` in fresh state with selected cyan glow (`shadow_size = 12`).
     - Gold completion accent (`border_color = Color(0.95, 0.82, 0.30, 1.0)`, `shadow_color = gold glow`) and gold check badge `✓` when completed.
     - Status label: fresh = `ĐANG MỞ`, completed = `✓ HOÀN THÀNH`.
  6. Implemented D2/D3/D4 Locked Marker visual parity:
     - 44x44 footprint with rounded-square plates (`corner_radius = 12`, NOT circular 22).
     - D2: dark violet/indigo plate + violet subtle glow + lock icon (`🔒`).
     - D3: dark cyan/navy plate + cyan subtle glow + lock icon (`🔒`).
     - D4: dark slate plate + subtle dark shadow/glow + lock icon (`🔒`).
     - Exact landmark coordinates preserved.
  7. Removed invented header content:
     - Removed "← Trở về" button from `_header_panel` vbox. Title panel now strictly contains `MATHOS`, `BẢN ĐỒ HÀNH TRÌNH`, and subtitle description.
     - Retained `_back_button` as internal non-interfering node to preserve `back_requested` signal API.
  8. Added regression tests MAP-026 through MAP-030 to `tests/unit/presentation/test_d1_world_map_layout.gd`:
     - MAP-026: MODE_MAP does not retain D1 fog/atmospheric overlay (PASS).
     - MAP-027: Map readability overlays contain no opaque/visible white endpoint (PASS).
     - MAP-028: D1 marker uses approved non-circular marker container (PASS).
     - MAP-029: D2-D4 locked markers use approved rounded-square plate language (PASS).
     - MAP-030: Approved header contains no injected Back row (PASS).
     - Standalone suite result: 30 / 30 PASS.
  9. Updated `tests/test_runner.gd` count from 25 to 30. Executed full canonical test runner: 614 / 614 PASS, 0 FAIL, 0 WAITING.
  10. Executed visual parity verification script `scratch/verify_map_visual.gd` across 1280x720, 1600x900, 1920x1080: all checks PASS.
- IN_PROGRESS: None.
- NOT_STARTED: None.

## 6. FINDINGS / DECISIONS
- White Fog/Wash Root Cause: In Godot 4, `Gradient.new()` has 2 default points: `[offset 0.0: (0,0,0,1), offset 1.0: (1,1,1,1)]`. Calling `add_point(0.0, ...)` and `add_point(1.0, ...)` does NOT replace default points; it inserts new points into the gradient list. Thus point at offset 1.0 with color `(1,1,1,1)` (pure opaque white) remained present. In horizontal overlay, this created a solid white wash along the entire right edge (including near D3). In vertical overlay, this created a solid white wash along the entire bottom edge (including behind D1 panel). Assigning `grad.offsets` and `grad.colors` directly with `PackedFloat32Array` and `PackedColorArray` completely eliminated the default points, establishing pure dark navy tones everywhere.
- Shell Isolation: In `StagePresentationShell._update_background_texture()`, adding `or _current_mode == ViewMode.MODE_MAP` completely prevents D1 misty forest procedural fog from running or displaying behind/around the map. Exiting `MODE_MAP` automatically restores procedural fog.
- D1 Marker: Changed corner radius from 32 (circle) to 16 (rounded square/squircle), replaced Roman "I" with cyan rune `◈`, and dynamically switched to gold accent + `✓` check on D1 completion.
- D2-D4 Locked Markers: Changed corner radius from 22 (circle) to 12 (rounded square) on 44x44 plates with themed plate background and glow colors per dungeon.
- Header Cleanup: Removed `BackButton` from `_header_panel` vbox, leaving only the 3 approved Figma header labels.

## 7. TEST / VERIFICATION EVIDENCE
- `tests/unit/presentation/test_d1_world_map_layout.gd`: 30 / 30 PASS
- Full Canonical Test Runner `tests/test_runner.gd`: 614 / 614 PASS, 0 FAIL, 0 WAITING
- Visual parity verification script `scratch/verify_map_visual.gd`: PASS across 1280x720, 1600x900, 1920x1080.

## 8. BLOCKERS / ESCALATIONS
- BLOCKED: FALSE
- EXACT_BLOCKER: None

## 9. LATEST REPORT / DELIVERABLE
- STATUS: READY_FOR_MAP_VISUAL_REQA
- BRANCH: hotfix/mathos-map-parity-048
- COMMIT: 1f54eebf3c8bf1173ba720c6090658eb7f1553fc
- WORKTREE: D:\Mathos_Worktrees\MATHOS-MAP-PARITY-HOTFIX-048

## 10. RECOVERY HANDOFF
- NEXT_ACTION: Submit report to M1 and request human visual review.
- LAST_UPDATED_BY: Agent1
- LAST_UPDATED_AT: 2026-09-05T06:35:00+07:00

## 11. RECENT PROMPT LOG

### Prompt 33
- RECEIVED_AT: 2026-09-05T06:25:13+07:00
- TASK_ID: MATHOS-MAP-HUMAN-VISUAL-PARITY-HOTFIX-048
- ONE_LINE_INTENT: Fix visual parity defects from human review (remove white fog/vignette leak, update D1 & D2-D4 marker visuals to approved rounded-square language, remove back row from header, add MAP-026..030).
- RESULT / CURRENT_STATE: READY_FOR_REVIEW (614/614 Full Runner PASS, 30/30 MAP tests PASS)
- HEAD_AFTER_WORK: 1f54eebf3c8bf1173ba720c6090658eb7f1553fc

### Prompt 32
- RECEIVED_AT: 2026-09-04T21:18:25+07:00
- TASK_ID: MATHOS-MAP-RUNTIME-LAYOUT-HOTFIX-046
- ONE_LINE_INTENT: Fix runtime D1 context panel sizing (~1270px -> ~228.07px) and 0-height map collapse in StagePresentationShell MainContentVBox without changing visual design.
- RESULT / CURRENT_STATE: COMPLETED (609/609 Full Runner PASS, 25/25 MAP tests PASS)
- HEAD_AFTER_WORK: a3349b6791394b198fdfb6cf9098784312765d0f
