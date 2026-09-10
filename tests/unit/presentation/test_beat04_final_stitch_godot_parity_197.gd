class_name TestBeat04FinalStitchGodotParity197
extends SceneTree

## Comprehensive 23-point verification suite for:
## TASK-MATHOS-BEAT04-FINAL-STITCH-GODOT-PARITY-197
## Validates full parity with human-approved Stitch Beat4 frame:
## 1. Exact background path (beat04_fractured_realm_bg.png)
## 2. Four regional landmark assets loaded
## 3. D4 is in Top-Left quadrant
## 4. D3 is in Top-Right quadrant
## 5. D1 is in Bottom-Left quadrant
## 6. D2 is in Bottom-Right quadrant
## 7. Fragment I start top-left
## 8. Fragment II start top-right
## 9. Fragment IV start bottom-left
## 10. Fragment III start bottom-right
## 11. Fragment I arrives at D1
## 12. Fragment II arrives at D2
## 13. Fragment III arrives at D3
## 14. Fragment IV arrives at D4
## 15. Fragment display footprint ~155x155
## 16. Narration zero-intersection with D1/D2
## 17. Narration zero-intersection with fragments
## 18. Top-right controls inside viewport
## 19. Right margin >= 24px
## 20. Background aspect preserved
## 21. Beat 4 -> Story handoff
## 22. Task 195 Story parity preserved
## 23. Zero remote URLs

const ProloguePlayerClass = preload("res://src/ui/prologue/prologue_player.gd")
const SanctumNexusHubClass = preload("res://src/ui/hub/sanctum_nexus_hub.gd")
const StoryPanelClass = preload("res://src/ui/story/story_panel.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func _create_node(node: Node, p_size: Vector2 = Vector2(1280, 720)) -> Node:
	if node is Control:
		var c: Control = node as Control
		c.set_anchors_preset(Control.PRESET_TOP_LEFT)
		c.size = p_size
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(node)
	if not node.is_node_ready():
		node._ready()
	return node

static func _remove_node(node: Node) -> void:
	if node != null:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()

static func run_all_tests() -> bool:
	print("==================================================")
	print("STARTING TASK 197 BEAT 4 FINAL STITCH PARITY SUITE")
	print("==================================================")

	var tests: Array[Callable] = [
		Callable(TestBeat04FinalStitchGodotParity197, "test_01_background_path_and_loaded"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_02_four_dungeon_landmark_assets_loaded"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_03_d4_top_left_quadrant"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_04_d3_top_right_quadrant"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_05_d1_bottom_left_quadrant"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_06_d2_bottom_right_quadrant"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_07_fragment_i_start_top_left"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_08_fragment_ii_start_top_right"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_09_fragment_iv_start_bottom_left"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_10_fragment_iii_start_bottom_right"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_11_fragment_i_arrives_at_d1"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_12_fragment_ii_arrives_at_d2"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_13_fragment_iii_arrives_at_d3"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_14_fragment_iv_arrives_at_d4"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_15_fragment_footprint_155x155"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_16_narration_zero_intersection_d1_d2"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_17_narration_zero_intersection_fragments"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_18_top_right_controls_inside_viewport"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_19_top_right_controls_right_margin_ge_24"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_20_background_aspect_preserved"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_21_beat4_handoff_and_completion"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_22_task195_story_parity_preserved"),
		Callable(TestBeat04FinalStitchGodotParity197, "test_23_zero_remote_urls")
	]

	var pass_count: int = 0
	for t in tests:
		if bool(t.call()):
			pass_count += 1

	print("==================================================")
	print("TASK 197 VERIFICATION SUMMARY: %d / %d passed" % [pass_count, tests.size()])
	print("==================================================")
	return pass_count == tests.size()

# 1. Exact background path (beat04_fractured_realm_bg.png)
static func test_01_background_path_and_loaded() -> bool:
	print("[PARITY-197-01] Testing exact background path...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var bg: TextureRect = player.call("get_layer_node", 4, "Background") as TextureRect
	if bg == null or bg.texture == null:
		print("[PARITY-197-01] FAIL: Background node or texture is null")
		player.free()
		return false
	if not bg.texture.resource_path.ends_with("beat04_fractured_realm_bg.png"):
		print("[PARITY-197-01] FAIL: Background path mismatch: %s" % bg.texture.resource_path)
		player.free()
		return false
	if not FileAccess.file_exists("res://assets/prologue/beat_04/beat04_fractured_realm_bg.png"):
		print("[PARITY-197-01] FAIL: Background file missing on disk")
		player.free()
		return false
	player.free()
	print("[PARITY-197-01] PASS: Exact background loaded and verified")
	return true

# 2. Four regional landmark assets loaded
static func test_02_four_dungeon_landmark_assets_loaded() -> bool:
	print("[PARITY-197-02] Testing four regional landmark assets...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var landmarks: Dictionary = player.call("get_landmark_paths")
	var expected_files: Dictionary = {
		"D1": "wad2_beat04_d1_forest_landmark.png",
		"D2": "wad2_beat04_d2_swamp_landmark.png",
		"D3": "wad2_beat04_d3_palace_landmark.png",
		"D4": "wad2_beat04_d4_tower_landmark.png"
	}
	for region in expected_files.keys():
		if not landmarks.has(region):
			print("[PARITY-197-02] FAIL: Missing landmark entry for %s" % region)
			player.free()
			return false
		var path: String = landmarks[region]
		if not path.ends_with(expected_files[region]):
			print("[PARITY-197-02] FAIL: Path mismatch for %s: %s" % [region, path])
			player.free()
			return false
		var node: TextureRect = player.call("get_landmark_node", region)
		if node == null or node.texture == null:
			print("[PARITY-197-02] FAIL: TextureRect or texture missing for %s" % region)
			player.free()
			return false
	player.free()
	print("[PARITY-197-02] PASS: All 4 regional landmark assets loaded cleanly")
	return true

# 3. D4 is in Top-Left quadrant
static func test_03_d4_top_left_quadrant() -> bool:
	print("[PARITY-197-03] Testing D4 in Top-Left quadrant...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var d4: Control = player.call("get_destination_node", "Destination04")
	if d4 == null:
		print("[PARITY-197-03] FAIL: D4 node missing")
		player.free()
		return false
	if d4.position.x >= 640.0 or d4.position.y >= 360.0:
		print("[PARITY-197-03] FAIL: D4 not in top-left: %s" % str(d4.position))
		player.free()
		return false
	if absf(d4.position.x - 200.0) > 1.0 or absf(d4.position.y - 185.0) > 1.0:
		print("[PARITY-197-03] FAIL: D4 position altered from canonical (200, 185): %s" % str(d4.position))
		player.free()
		return false
	player.free()
	print("[PARITY-197-03] PASS: D4 verified at Top-Left (200, 185)")
	return true

# 4. D3 is in Top-Right quadrant
static func test_04_d3_top_right_quadrant() -> bool:
	print("[PARITY-197-04] Testing D3 in Top-Right quadrant...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var d3: Control = player.call("get_destination_node", "Destination03")
	if d3 == null:
		print("[PARITY-197-04] FAIL: D3 node missing")
		player.free()
		return false
	if d3.position.x <= 640.0 or d3.position.y >= 360.0:
		print("[PARITY-197-04] FAIL: D3 not in top-right: %s" % str(d3.position))
		player.free()
		return false
	if absf(d3.position.x - 940.0) > 1.0 or absf(d3.position.y - 185.0) > 1.0:
		print("[PARITY-197-04] FAIL: D3 position altered from canonical (940, 185): %s" % str(d3.position))
		player.free()
		return false
	player.free()
	print("[PARITY-197-04] PASS: D3 verified at Top-Right (940, 185)")
	return true

# 5. D1 is in Bottom-Left quadrant
static func test_05_d1_bottom_left_quadrant() -> bool:
	print("[PARITY-197-05] Testing D1 in Bottom-Left quadrant...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var d1: Control = player.call("get_destination_node", "Destination01")
	if d1 == null:
		print("[PARITY-197-05] FAIL: D1 node missing")
		player.free()
		return false
	if d1.position.x >= 640.0 or d1.position.y <= 360.0:
		print("[PARITY-197-05] FAIL: D1 not in bottom-left: %s" % str(d1.position))
		player.free()
		return false
	if absf(d1.position.x - 200.0) > 1.0 or absf(d1.position.y - 520.0) > 1.0:
		print("[PARITY-197-05] FAIL: D1 position altered from canonical (200, 520): %s" % str(d1.position))
		player.free()
		return false
	player.free()
	print("[PARITY-197-05] PASS: D1 verified at Bottom-Left (200, 520)")
	return true

# 6. D2 is in Bottom-Right quadrant
static func test_06_d2_bottom_right_quadrant() -> bool:
	print("[PARITY-197-06] Testing D2 in Bottom-Right quadrant...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var d2: Control = player.call("get_destination_node", "Destination02")
	if d2 == null:
		print("[PARITY-197-06] FAIL: D2 node missing")
		player.free()
		return false
	if d2.position.x <= 640.0 or d2.position.y <= 360.0:
		print("[PARITY-197-06] FAIL: D2 not in bottom-right: %s" % str(d2.position))
		player.free()
		return false
	if absf(d2.position.x - 1080.0) > 1.0 or absf(d2.position.y - 520.0) > 1.0:
		print("[PARITY-197-06] FAIL: D2 position altered from canonical (1080, 520): %s" % str(d2.position))
		player.free()
		return false
	player.free()
	print("[PARITY-197-06] PASS: D2 verified at Bottom-Right (1080, 520)")
	return true

# 7. Fragment I start top-left
static func test_07_fragment_i_start_top_left() -> bool:
	print("[PARITY-197-07] Testing Fragment I start position...")
	var player: Control = ProloguePlayerClass.new()
	var spec: Dictionary = player.call("get_trajectory_spec", "Fragment01")
	var start_pos: Vector2 = spec.get("start", Vector2.ZERO)
	if start_pos.x >= 640.0 or start_pos.y >= 360.0:
		print("[PARITY-197-07] FAIL: Fragment 1 start not top-left of center: %s" % str(start_pos))
		player.free()
		return false
	if absf(start_pos.x - 575.0) > 1.0 or absf(start_pos.y - 295.0) > 1.0:
		print("[PARITY-197-07] FAIL: Fragment 1 start altered: %s" % str(start_pos))
		player.free()
		return false
	player.free()
	print("[PARITY-197-07] PASS: Fragment I start verified at Top-Left of cluster (575, 295)")
	return true

# 8. Fragment II start top-right
static func test_08_fragment_ii_start_top_right() -> bool:
	print("[PARITY-197-08] Testing Fragment II start position...")
	var player: Control = ProloguePlayerClass.new()
	var spec: Dictionary = player.call("get_trajectory_spec", "Fragment02")
	var start_pos: Vector2 = spec.get("start", Vector2.ZERO)
	if start_pos.x <= 640.0 or start_pos.y >= 360.0:
		print("[PARITY-197-08] FAIL: Fragment 2 start not top-right of center: %s" % str(start_pos))
		player.free()
		return false
	if absf(start_pos.x - 705.0) > 1.0 or absf(start_pos.y - 295.0) > 1.0:
		print("[PARITY-197-08] FAIL: Fragment 2 start altered: %s" % str(start_pos))
		player.free()
		return false
	player.free()
	print("[PARITY-197-08] PASS: Fragment II start verified at Top-Right of cluster (705, 295)")
	return true

# 9. Fragment IV start bottom-left
static func test_09_fragment_iv_start_bottom_left() -> bool:
	print("[PARITY-197-09] Testing Fragment IV start position...")
	var player: Control = ProloguePlayerClass.new()
	var spec: Dictionary = player.call("get_trajectory_spec", "Fragment04")
	var start_pos: Vector2 = spec.get("start", Vector2.ZERO)
	if start_pos.x >= 640.0 or start_pos.y <= 360.0:
		print("[PARITY-197-09] FAIL: Fragment 4 start not bottom-left of center: %s" % str(start_pos))
		player.free()
		return false
	if absf(start_pos.x - 575.0) > 1.0 or absf(start_pos.y - 425.0) > 1.0:
		print("[PARITY-197-09] FAIL: Fragment 4 start altered: %s" % str(start_pos))
		player.free()
		return false
	player.free()
	print("[PARITY-197-09] PASS: Fragment IV start verified at Bottom-Left of cluster (575, 425)")
	return true

# 10. Fragment III start bottom-right
static func test_10_fragment_iii_start_bottom_right() -> bool:
	print("[PARITY-197-10] Testing Fragment III start position...")
	var player: Control = ProloguePlayerClass.new()
	var spec: Dictionary = player.call("get_trajectory_spec", "Fragment03")
	var start_pos: Vector2 = spec.get("start", Vector2.ZERO)
	if start_pos.x <= 640.0 or start_pos.y <= 360.0:
		print("[PARITY-197-10] FAIL: Fragment 3 start not bottom-right of center: %s" % str(start_pos))
		player.free()
		return false
	if absf(start_pos.x - 705.0) > 1.0 or absf(start_pos.y - 425.0) > 1.0:
		print("[PARITY-197-10] FAIL: Fragment 3 start altered: %s" % str(start_pos))
		player.free()
		return false
	player.free()
	print("[PARITY-197-10] PASS: Fragment III start verified at Bottom-Right of cluster (705, 425)")
	return true

# 11. Fragment I arrives at D1
static func test_11_fragment_i_arrives_at_d1() -> bool:
	print("[PARITY-197-11] Testing Fragment I arrives at D1...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.set("_speed_scale", 1.0)
	player.set("_playback_time", 11.0)
	player.call("_process_beat04", 0.016)

	var f1: Control = player.call("get_fragment_node", "Fragment01", 4)
	var d1: Control = player.call("get_destination_node", "Destination01")
	var f1_center: Vector2 = f1.position + f1.pivot_offset
	var dist: float = f1_center.distance_to(d1.position)
	if dist > 2.0:
		print("[PARITY-197-11] FAIL: Fragment 1 center distance to D1: %f (center: %s vs %s)" % [dist, str(f1_center), str(d1.position)])
		player.free()
		return false
	player.free()
	print("[PARITY-197-11] PASS: Fragment I correctly arrives at D1")
	return true

# 12. Fragment II arrives at D2
static func test_12_fragment_ii_arrives_at_d2() -> bool:
	print("[PARITY-197-12] Testing Fragment II arrives at D2...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.set("_speed_scale", 1.0)
	player.set("_playback_time", 11.0)
	player.call("_process_beat04", 0.016)

	var f2: Control = player.call("get_fragment_node", "Fragment02", 4)
	var d2: Control = player.call("get_destination_node", "Destination02")
	var f2_center: Vector2 = f2.position + f2.pivot_offset
	var dist: float = f2_center.distance_to(d2.position)
	if dist > 2.0:
		print("[PARITY-197-12] FAIL: Fragment 2 center distance to D2: %f (center: %s vs %s)" % [dist, str(f2_center), str(d2.position)])
		player.free()
		return false
	player.free()
	print("[PARITY-197-12] PASS: Fragment II correctly arrives at D2")
	return true

# 13. Fragment III arrives at D3
static func test_13_fragment_iii_arrives_at_d3() -> bool:
	print("[PARITY-197-13] Testing Fragment III arrives at D3...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.set("_speed_scale", 1.0)
	player.set("_playback_time", 11.0)
	player.call("_process_beat04", 0.016)

	var f3: Control = player.call("get_fragment_node", "Fragment03", 4)
	var d3: Control = player.call("get_destination_node", "Destination03")
	var f3_center: Vector2 = f3.position + f3.pivot_offset
	var dist: float = f3_center.distance_to(d3.position)
	if dist > 2.0:
		print("[PARITY-197-13] FAIL: Fragment 3 center distance to D3: %f (center: %s vs %s)" % [dist, str(f3_center), str(d3.position)])
		player.free()
		return false
	player.free()
	print("[PARITY-197-13] PASS: Fragment III correctly arrives at D3")
	return true

# 14. Fragment IV arrives at D4
static func test_14_fragment_iv_arrives_at_d4() -> bool:
	print("[PARITY-197-14] Testing Fragment IV arrives at D4...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.set("_speed_scale", 1.0)
	player.set("_playback_time", 11.0)
	player.call("_process_beat04", 0.016)

	var f4: Control = player.call("get_fragment_node", "Fragment04", 4)
	var d4: Control = player.call("get_destination_node", "Destination04")
	var f4_center: Vector2 = f4.position + f4.pivot_offset
	var dist: float = f4_center.distance_to(d4.position)
	if dist > 2.0:
		print("[PARITY-197-14] FAIL: Fragment 4 center distance to D4: %f (center: %s vs %s)" % [dist, str(f4_center), str(d4.position)])
		player.free()
		return false
	player.free()
	print("[PARITY-197-14] PASS: Fragment IV correctly arrives at D4")
	return true

# 15. Fragment display footprint ~155x155
static func test_15_fragment_footprint_155x155() -> bool:
	print("[PARITY-197-15] Testing fragment display footprint...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
		var f_node: Control = player.call("get_fragment_node", fid, 4)
		var display_w: float = f_node.size.x * f_node.scale.x
		var display_h: float = f_node.size.y * f_node.scale.y
		if display_w < 140.0 or display_w > 170.0 or display_h < 140.0 or display_h > 170.0:
			print("[PARITY-197-15] FAIL: %s display footprint not ~155x155: %fx%f" % [fid, display_w, display_h])
			player.free()
			return false
	player.free()
	print("[PARITY-197-15] PASS: Fragment display footprint ~155x155 verified")
	return true

# 16. Narration zero-intersection with D1/D2
static func test_16_narration_zero_intersection_d1_d2() -> bool:
	print("[PARITY-197-16] Testing narration zero intersection with D1/D2...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var narr_rect: Rect2 = player.call("get_b4_narration_safe_rect")
	var d1_rect: Rect2 = player.call("get_b4_destination_visual_rect", "Destination01")
	var d2_rect: Rect2 = player.call("get_b4_destination_visual_rect", "Destination02")

	if narr_rect.intersects(d1_rect):
		print("[PARITY-197-16] FAIL: Narration intersects D1: %s vs %s" % [str(narr_rect), str(d1_rect)])
		player.free()
		return false
	if narr_rect.intersects(d2_rect):
		print("[PARITY-197-16] FAIL: Narration intersects D2: %s vs %s" % [str(narr_rect), str(d2_rect)])
		player.free()
		return false
	player.free()
	print("[PARITY-197-16] PASS: Zero intersection between Narration and D1/D2")
	return true

# 17. Narration zero-intersection with fragments along entire flight
static func test_17_narration_zero_intersection_fragments() -> bool:
	print("[PARITY-197-17] Testing narration zero intersection along flight path...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.set("_speed_scale", 1.0)

	var narr_safe: Rect2 = player.call("get_b4_narration_safe_rect")

	# Sample across the entire flight period (0.0s to 12.0s in 0.1s steps)
	var t: float = 0.0
	while t <= 12.0:
		player.set("_playback_time", t)
		player.call("_process_beat04", 0.016)
		for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
			var core_rect: Rect2 = player.call("get_b4_fragment_core_rect", fid)
			if narr_safe.intersects(core_rect):
				print("[PARITY-197-17] FAIL: %s intersects narration safe rect at t=%f: %s vs %s" % [fid, t, str(core_rect), str(narr_safe)])
				player.free()
				return false
		t += 0.1

	player.free()
	print("[PARITY-197-17] PASS: Zero intersection between fragments and narration along entire flight")
	return true

# 18. Top-right controls inside viewport
static func test_18_top_right_controls_inside_viewport() -> bool:
	print("[PARITY-197-18] Testing top-right controls inside viewport...")
	var player: Control = _create_node(ProloguePlayerClass.new(), Vector2(1280, 720)) as Control
	player.update_responsive_layout(Vector2(1280, 720))

	var tr_box: Control = player.find_child("TopRightHBox", true, false) as Control
	var skip_btn: Control = player.find_child("SkipBtn", true, false) as Control
	if tr_box == null or skip_btn == null:
		print("[PARITY-197-18] FAIL: TopRightHBox or SkipBtn node missing")
		_remove_node(player)
		return false

	var vp_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1280, 720))
	var box_rect: Rect2 = Rect2(tr_box.position, tr_box.size)
	var skip_rect: Rect2 = Rect2(skip_btn.position, skip_btn.size)

	if not vp_rect.encloses(box_rect):
		print("[PARITY-197-18] FAIL: TopRightHBox outside viewport: %s" % str(box_rect))
		_remove_node(player)
		return false
	if not vp_rect.encloses(skip_rect):
		print("[PARITY-197-18] FAIL: SkipBtn outside viewport: %s" % str(skip_rect))
		_remove_node(player)
		return false

	_remove_node(player)
	print("[PARITY-197-18] PASS: Top-right controls cleanly inside 1280x720 viewport")
	return true

# 19. Right margin >= 24px
static func test_19_top_right_controls_right_margin_ge_24() -> bool:
	print("[PARITY-197-19] Testing top-right controls right margin >= 24px...")
	for res in [Vector2(1280, 720), Vector2(1280, 680)]:
		var player: Control = _create_node(ProloguePlayerClass.new(), res) as Control
		player.update_responsive_layout(res)

		var tr_box: Control = player.find_child("TopRightHBox", true, false) as Control
		var skip_btn: Control = player.find_child("SkipBtn", true, false) as Control

		var box_margin: float = res.x - (tr_box.position.x + tr_box.size.x)
		var skip_margin: float = res.x - (skip_btn.position.x + skip_btn.size.x)

		if box_margin < 23.99:
			print("[PARITY-197-19] FAIL: TopRightHBox right margin %f < 24px at %s" % [box_margin, str(res)])
			_remove_node(player)
			return false
		if skip_margin < 23.99:
			print("[PARITY-197-19] FAIL: SkipBtn right margin %f < 24px at %s" % [skip_margin, str(res)])
			_remove_node(player)
			return false

		_remove_node(player)

	print("[PARITY-197-19] PASS: Right margin >= 24px verified across resolutions")
	return true

# 20. Background aspect preserved
static func test_20_background_aspect_preserved() -> bool:
	print("[PARITY-197-20] Testing background aspect ratio preservation...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var bg: TextureRect = player.call("get_layer_node", 4, "Background") as TextureRect
	if bg.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
		print("[PARITY-197-20] FAIL: expand_mode is not EXPAND_IGNORE_SIZE")
		player.free()
		return false
	if bg.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
		print("[PARITY-197-20] FAIL: stretch_mode is not STRETCH_KEEP_ASPECT_COVERED")
		player.free()
		return false
	if bg.size.x < 1280.0 or bg.size.y < 720.0:
		print("[PARITY-197-20] FAIL: Background size does not cover viewport: %s" % str(bg.size))
		player.free()
		return false
	player.free()
	print("[PARITY-197-20] PASS: Background aspect ratio preserved with KEEP_ASPECT_COVERED")
	return true

# 21. Beat 4 -> Story handoff
static func test_21_beat4_handoff_and_completion() -> bool:
	print("[PARITY-197-21] Testing Beat 4 completion & skip handoff...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.call("set_speed_scale", 100.0)
	player.call("start_prologue")
	player.call("advance_to_beat2")
	player.call("advance_to_beat3")
	player.call("advance_to_beat4")

	var completed_emissions: Array[int] = [0]
	player.connect("prologue_completed", func(): completed_emissions[0] += 1)

	player.call("complete_prologue")
	if completed_emissions[0] != 1:
		print("[PARITY-197-21] FAIL: Expected 1 emission of prologue_completed, got %d" % completed_emissions[0])
		player.free()
		return false
	player.free()
	print("[PARITY-197-21] PASS: Beat 4 handoff and completion signal verified")
	return true

# 22. Task 195 Story parity preserved
static func test_22_task195_story_parity_preserved() -> bool:
	print("[PARITY-195-22] Testing Task 195 Story parity...")
	var scene: PackedScene = load("res://src/ui/story/story_panel.tscn") as PackedScene
	var panel: StoryPanel = null
	if scene != null:
		panel = scene.instantiate() as StoryPanel
	else:
		panel = StoryPanel.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(panel)
	if not panel.is_node_ready():
		panel._ready()

	var char_slot: Control = panel.get_character_slot()
	var dial_panel: Control = panel.get_dialogue_panel()

	if char_slot.custom_minimum_size.x != 340.0:
		print("[PARITY-197-22] FAIL: Character slot width mismatch: %f" % char_slot.custom_minimum_size.x)
		if panel.get_parent() != null:
			panel.get_parent().remove_child(panel)
		panel.free()
		return false

	if dial_panel.custom_minimum_size.x < 840.0:
		print("[PARITY-197-22] FAIL: DialoguePanel width too small: %f" % dial_panel.custom_minimum_size.x)
		if panel.get_parent() != null:
			panel.get_parent().remove_child(panel)
		panel.free()
		return false

	if panel.get_parent() != null:
		panel.get_parent().remove_child(panel)
	panel.free()

	# Check Karl portrait in SanctumNexusHub
	var hub: Control = SanctumNexusHubClass.new()
	if tree != null and tree.root != null:
		tree.root.add_child(hub)
	if not hub.is_node_ready():
		hub._ready()

	var avatar: TextureRect = hub.find_child("PlayerAvatar", true, false) as TextureRect
	var emblem_tex: Texture2D = load("res://assets/branding/mathos_logo_emblem.png") as Texture2D
	if avatar == null or avatar.texture == null or avatar.texture == emblem_tex:
		print("[PARITY-197-22] FAIL: Karl portrait in hub failed to load")
		if hub.get_parent() != null:
			hub.get_parent().remove_child(hub)
		hub.free()
		return false

	if hub.get_parent() != null:
		hub.get_parent().remove_child(hub)
	hub.free()
	print("[PARITY-197-22] PASS: Task 195 Story and Hub parity strictly intact")
	return true

# 23. Zero remote URLs
static func test_23_zero_remote_urls() -> bool:
	print("[PARITY-197-23] Testing zero remote URLs in modified code and layout...")
	var files_to_check: Array[String] = [
		"res://src/ui/prologue/prologue_player.gd",
		"res://assets/prologue/beat_04/layout/prologue_beat04_layout.json"
	]
	for path in files_to_check:
		var fa: FileAccess = FileAccess.open(path, FileAccess.READ)
		if fa == null:
			print("[PARITY-197-23] FAIL: Could not open %s" % path)
			return false
		var text: String = fa.get_as_text()
		fa.close()
		if text.contains("http://") or text.contains("https://"):
			print("[PARITY-197-23] FAIL: File contains remote URL: %s" % path)
			return false

	print("[PARITY-197-23] PASS: Zero remote URLs verified")
	return true
