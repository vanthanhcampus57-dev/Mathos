class_name TestD1WorldMapLayout
extends SceneTree

## Dedicated Verification Suite for Human-Approved MATHOS World Map Layout
## Validates MAP-001 through MAP-015 according to TASK-045 specification.

const DungeonStageMapPanelClass = preload("res://src/ui/map/dungeon_stage_map_panel.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func run_all_tests() -> bool:
	print("==========================================")
	print("D1 WORLD MAP LAYOUT VERIFICATION (MAP-001..015)")
	print("==========================================")
	var pass_count: int = 0

	if test_map_001_root_geometry(): pass_count += 1
	if test_map_002_approved_artwork_loaded(): pass_count += 1
	if test_map_003_header_placement_and_content(): pass_count += 1
	if test_map_004_hud_placement_and_progression(): pass_count += 1
	if test_map_005_d1_marker_placement_and_style(): pass_count += 1
	if test_map_006_d2_marker_placement_and_style(): pass_count += 1
	if test_map_007_d3_marker_placement_and_style(): pass_count += 1
	if test_map_008_d4_marker_placement_and_style(): pass_count += 1
	if test_map_009_d2_d4_locked(): pass_count += 1
	if test_map_010_d1_context_panel_placement_and_content(): pass_count += 1
	if test_map_011_d1_action_uses_canonical_entry_flow(): pass_count += 1
	if test_map_012_no_debug_or_internal_labels(): pass_count += 1
	if test_map_013_no_dominant_duplicate_route(): pass_count += 1
	if test_map_014_1600x900_landmark_stability(): pass_count += 1
	if test_map_015_1920x1080_landmark_stability(): pass_count += 1

	print("==========================================")
	print("D1 WORLD MAP LAYOUT SUMMARY: %d / 15 passed" % pass_count)
	print("==========================================")
	return pass_count == 15

static func _create_panel(p_size: Vector2 = Vector2(1280, 720)) -> DungeonStageMapPanel:
	var panel: DungeonStageMapPanel = DungeonStageMapPanelClass.new()
	panel.size = p_size
	panel._ready()
	panel._update_responsive_layout()
	return panel

static func test_map_001_root_geometry() -> bool:
	print("[MAP-001] Verifying root 1280x720 reference geometry...")
	var panel: DungeonStageMapPanel = _create_panel(Vector2(1280, 720))
	if panel.size != Vector2(1280, 720):
		print("[MAP-001] FAIL: Expected size 1280x720, got %s" % str(panel.size))
		panel.free()
		return false
	if not panel.clip_contents:
		print("[MAP-001] FAIL: clip_contents should be true")
		panel.free()
		return false
	panel.free()
	print("[MAP-001] PASS")
	return true

static func test_map_002_approved_artwork_loaded() -> bool:
	print("[MAP-002] Verifying approved background artwork loaded...")
	var panel: DungeonStageMapPanel = _create_panel()
	if panel._bg_texture_rect == null or panel._bg_texture_rect.texture == null:
		print("[MAP-002] FAIL: Background TextureRect or texture is null")
		panel.free()
		return false
	if panel._bg_texture_rect.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
		print("[MAP-002] FAIL: expand_mode must be EXPAND_IGNORE_SIZE")
		panel.free()
		return false
	if panel._bg_texture_rect.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
		print("[MAP-002] FAIL: stretch_mode must be STRETCH_KEEP_ASPECT_COVERED")
		panel.free()
		return false
	panel.free()
	print("[MAP-002] PASS")
	return true

static func test_map_003_header_placement_and_content() -> bool:
	print("[MAP-003] Verifying header placement and content hierarchy...")
	var panel: DungeonStageMapPanel = _create_panel()
	if panel._header_panel == null:
		print("[MAP-003] FAIL: Header panel is null")
		panel.free()
		return false
	if panel._header_panel.position != Vector2(40, 28):
		print("[MAP-003] FAIL: Header position expected (40, 28), got %s" % str(panel._header_panel.position))
		panel.free()
		return false
	if panel._title_label == null or not panel._title_label.text.contains("BẢN ĐỒ HÀNH TRÌNH"):
		print("[MAP-003] FAIL: Title label missing or incorrect")
		panel.free()
		return false
	if panel._world_label == null or not panel._world_label.text.contains("MATHOS"):
		print("[MAP-003] FAIL: World label missing MATHOS")
		panel.free()
		return false
	panel.free()
	print("[MAP-003] PASS")
	return true

static func test_map_004_hud_placement_and_progression() -> bool:
	print("[MAP-004] Verifying HUD placement and real progression values...")
	var panel: DungeonStageMapPanel = _create_panel()
	# In 1280x720: right=40, top=28, w=289.69 -> x = 950.31, y = 28
	var expected_x: float = 1280.0 - 40.0 - 289.69
	if absf(panel._hud_panel.position.x - expected_x) > 1.0 or absf(panel._hud_panel.position.y - 28.0) > 1.0:
		print("[MAP-004] FAIL: HUD position expected (%f, 28), got %s" % [expected_x, str(panel._hud_panel.position)])
		panel.free()
		return false
	# Default state: D1 cleared in full demo
	panel.set_map_data({
		"completed_stages": ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04", "stage_01_05"],
		"unlocked_stages": ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04", "stage_01_05"],
		"current_stage_id": "stage_01_05"
	})
	if not panel._hud_fragment_label.text.contains("1"):
		print("[MAP-004] FAIL: HUD fragment count should be 1")
		panel.free()
		return false
	if not panel._hud_dungeon_label.text.contains("1/4"):
		print("[MAP-004] FAIL: HUD dungeon count should be 1/4")
		panel.free()
		return false
	panel.free()
	print("[MAP-004] PASS")
	return true

static func test_map_005_d1_marker_placement_and_style() -> bool:
	print("[MAP-005] Verifying D1 marker placement and style...")
	var panel: DungeonStageMapPanel = _create_panel()
	if absf(panel._d1_marker_group.position.x - 147.19) > 1.0 or absf(panel._d1_marker_group.position.y - 420.0) > 1.0:
		print("[MAP-005] FAIL: D1 marker pos expected (147.19, 420.0), got %s" % str(panel._d1_marker_group.position))
		panel.free()
		return false
	if panel._d1_marker_button == null:
		print("[MAP-005] FAIL: D1 marker button is null")
		panel.free()
		return false
	panel.free()
	print("[MAP-005] PASS")
	return true

static func test_map_006_d2_marker_placement_and_style() -> bool:
	print("[MAP-006] Verifying D2 marker placement and violet locked style...")
	var panel: DungeonStageMapPanel = _create_panel()
	if absf(panel._d2_marker_group.position.x - 595.94) > 1.0 or absf(panel._d2_marker_group.position.y - 311.88) > 1.0:
		print("[MAP-006] FAIL: D2 marker pos expected (595.94, 311.88), got %s" % str(panel._d2_marker_group.position))
		panel.free()
		return false
	if absf(panel._d2_marker_group.modulate.a - 0.75) > 0.05:
		print("[MAP-006] FAIL: D2 opacity expected ~0.75, got %f" % panel._d2_marker_group.modulate.a)
		panel.free()
		return false
	panel.free()
	print("[MAP-006] PASS")
	return true

static func test_map_007_d3_marker_placement_and_style() -> bool:
	print("[MAP-007] Verifying D3 marker placement and cyan locked style...")
	var panel: DungeonStageMapPanel = _create_panel()
	if absf(panel._d3_marker_group.position.x - 927.66) > 1.0 or absf(panel._d3_marker_group.position.y - 186.88) > 1.0:
		print("[MAP-007] FAIL: D3 marker pos expected (927.66, 186.88), got %s" % str(panel._d3_marker_group.position))
		panel.free()
		return false
	if absf(panel._d3_marker_group.modulate.a - 0.75) > 0.05:
		print("[MAP-007] FAIL: D3 opacity expected ~0.75, got %f" % panel._d3_marker_group.modulate.a)
		panel.free()
		return false
	panel.free()
	print("[MAP-007] PASS")
	return true

static func test_map_008_d4_marker_placement_and_style() -> bool:
	print("[MAP-008] Verifying D4 marker placement and slate locked style...")
	var panel: DungeonStageMapPanel = _create_panel()
	if absf(panel._d4_marker_group.position.x - 358.85) > 1.0 or absf(panel._d4_marker_group.position.y - 116.88) > 1.0:
		print("[MAP-008] FAIL: D4 marker pos expected (358.85, 116.88), got %s" % str(panel._d4_marker_group.position))
		panel.free()
		return false
	if absf(panel._d4_marker_group.modulate.a - 0.65) > 0.05:
		print("[MAP-008] FAIL: D4 opacity expected ~0.65, got %f" % panel._d4_marker_group.modulate.a)
		panel.free()
		return false
	panel.free()
	print("[MAP-008] PASS")
	return true

static func test_map_009_d2_d4_locked() -> bool:
	print("[MAP-009] Verifying D2-D4 cannot be selected or entered...")
	var panel: DungeonStageMapPanel = _create_panel()
	var selected_stages: Array[String] = []
	panel.stage_selected.connect(func(sid: String) -> void: selected_stages.append(sid))

	panel._on_stage_button_pressed("stage_02_01")
	panel._on_stage_button_pressed("stage_03_01")
	panel._on_stage_button_pressed("stage_04_01")

	if not selected_stages.is_empty():
		print("[MAP-009] FAIL: Locked dungeons emitted stage_selected!")
		panel.free()
		return false
	panel.free()
	print("[MAP-009] PASS")
	return true

static func test_map_010_d1_context_panel_placement_and_content() -> bool:
	print("[MAP-010] Verifying D1 context panel placement and content...")
	var panel: DungeonStageMapPanel = _create_panel()
	var expected_x: float = 1280.0 - 40.0 - 350.0
	var expected_y: float = 720.0 - 32.0 - 228.07
	if absf(panel._d1_context_panel.position.x - expected_x) > 1.0 or absf(panel._d1_context_panel.position.y - expected_y) > 1.0:
		print("[MAP-010] FAIL: D1 context panel pos expected (%f, %f), got %s" % [expected_x, expected_y, str(panel._d1_context_panel.position)])
		panel.free()
		return false
	if not panel._d1_panel_title_label.text.contains("KHU RỪNG SƯƠNG MÙ"):
		print("[MAP-010] FAIL: Dungeon name incorrect")
		panel.free()
		return false
	if panel._d1_action_button == null:
		print("[MAP-010] FAIL: Action button is null")
		panel.free()
		return false
	panel.free()
	print("[MAP-010] PASS")
	return true

static func test_map_011_d1_action_uses_canonical_entry_flow() -> bool:
	print("[MAP-011] Verifying D1 action button triggers canonical D1 entry...")
	var panel: DungeonStageMapPanel = _create_panel()
	var selected_stages: Array[String] = []
	panel.stage_selected.connect(func(sid: String) -> void: selected_stages.append(sid))

	panel._on_d1_action_pressed()
	if selected_stages.size() != 1 or selected_stages[0] != "stage_01_01":
		print("[MAP-011] FAIL: Expected stage_01_01 emission, got %s" % str(selected_stages))
		panel.free()
		return false
	panel.free()
	print("[MAP-011] PASS")
	return true

static func test_map_012_no_debug_or_internal_labels() -> bool:
	print("[MAP-012] Verifying zero debug / internal labels visible on map presentation...")
	var panel: DungeonStageMapPanel = _create_panel()
	# Check all visible labels in visual layer
	for node in panel._visual_layer.find_children("", "Label", true, false):
		var lbl: Label = node as Label
		var txt: String = lbl.text.to_lower()
		if txt.contains("stage_02") or txt.contains("stage_03") or txt.contains("stage_04") or txt.contains("debug") or txt.contains("internal"):
			print("[MAP-012] FAIL: Debug label found: %s" % lbl.text)
			panel.free()
			return false
	panel.free()
	print("[MAP-012] PASS")
	return true

static func test_map_013_no_dominant_duplicate_route() -> bool:
	print("[MAP-013] Verifying no dominant duplicate flowchart route...")
	var panel: DungeonStageMapPanel = _create_panel()
	var line_nodes: Array[Node] = panel.find_children("", "Line2D", true, false)
	if not line_nodes.is_empty():
		print("[MAP-013] FAIL: Unexpected Line2D duplicate route found")
		panel.free()
		return false
	panel.free()
	print("[MAP-013] PASS")
	return true

static func test_map_014_1600x900_landmark_stability() -> bool:
	print("[MAP-014] Verifying 1600x900 landmark position stability without drift...")
	var panel: DungeonStageMapPanel = _create_panel(Vector2(1600, 900))
	var s: float = 1600.0 / 1280.0 # 1.25
	var expected_d1_pos: Vector2 = Vector2(147.19 * s, 420.0 * s)
	var expected_d2_pos: Vector2 = Vector2(595.94 * s, 311.88 * s)
	var expected_d3_pos: Vector2 = Vector2(927.66 * s, 186.88 * s)
	var expected_d4_pos: Vector2 = Vector2(358.85 * s, 116.88 * s)

	if panel._d1_marker_group.position.distance_to(expected_d1_pos) > 1.5:
		print("[MAP-014] FAIL: D1 drift at 1600x900. Expected %s, got %s" % [str(expected_d1_pos), str(panel._d1_marker_group.position)])
		panel.free()
		return false
	if panel._d2_marker_group.position.distance_to(expected_d2_pos) > 1.5:
		print("[MAP-014] FAIL: D2 drift at 1600x900")
		panel.free()
		return false
	if panel._d3_marker_group.position.distance_to(expected_d3_pos) > 1.5:
		print("[MAP-014] FAIL: D3 drift at 1600x900")
		panel.free()
		return false
	if panel._d4_marker_group.position.distance_to(expected_d4_pos) > 1.5:
		print("[MAP-014] FAIL: D4 drift at 1600x900")
		panel.free()
		return false

	panel.free()
	print("[MAP-014] PASS")
	return true

static func test_map_015_1920x1080_landmark_stability() -> bool:
	print("[MAP-015] Verifying 1920x1080 landmark position stability without drift...")
	var panel: DungeonStageMapPanel = _create_panel(Vector2(1920, 1080))
	var s: float = 1920.0 / 1280.0 # 1.5
	var expected_d1_pos: Vector2 = Vector2(147.19 * s, 420.0 * s)
	var expected_d2_pos: Vector2 = Vector2(595.94 * s, 311.88 * s)
	var expected_d3_pos: Vector2 = Vector2(927.66 * s, 186.88 * s)
	var expected_d4_pos: Vector2 = Vector2(358.85 * s, 116.88 * s)

	if panel._d1_marker_group.position.distance_to(expected_d1_pos) > 1.5:
		print("[MAP-015] FAIL: D1 drift at 1920x1080. Expected %s, got %s" % [str(expected_d1_pos), str(panel._d1_marker_group.position)])
		panel.free()
		return false
	if panel._d2_marker_group.position.distance_to(expected_d2_pos) > 1.5:
		print("[MAP-015] FAIL: D2 drift at 1920x1080")
		panel.free()
		return false
	if panel._d3_marker_group.position.distance_to(expected_d3_pos) > 1.5:
		print("[MAP-015] FAIL: D3 drift at 1920x1080")
		panel.free()
		return false
	if panel._d4_marker_group.position.distance_to(expected_d4_pos) > 1.5:
		print("[MAP-015] FAIL: D4 drift at 1920x1080")
		panel.free()
		return false

	panel.free()
	print("[MAP-015] PASS")
	return true
