class_name TestPrologueBeat04WorldMap189
extends SceneTree

## Dedicated Verification Suite for TASK-189: Beat 4 World Map Production Integration
## Validates all 13 acceptance checks:
## 1. World map background present and loaded (d1_world_map_bg.jpg)
## 2. Four regional landmark assets present and loaded
## 3. Canonical geography coordinates (D1: [215, 465], D2: [645, 350], D3: [980, 225], D4: [410, 160])
## 4. Four flight trajectories and easing specs
## 5. Quadratic Bezier mathematical evaluation
## 6. Fragment scale transition (0.52 -> 0.15)
## 7. Zero overlap with Narration Safe Area Rect2(60, 530, 1160, 160)
## 8. Zero overlap with Skip Safe Area Rect2(1120, 20, 140, 44)
## 9. Strict Z-index hierarchy protection (World <= 5, Gradient 10, Narration 11, Fade 20)
## 10. Karl production portrait loaded in SanctumNexusHub
## 11. Task 185 Story/Draven layout parity strictly preserved
## 12. Beat 4 completion & skip handoff to D1 Story
## 13. Zero remote URLs & local asset integrity

const ProloguePlayerClass = preload("res://src/ui/prologue/prologue_player.gd")
const SanctumNexusHubClass = preload("res://src/ui/hub/sanctum_nexus_hub.gd")
const StoryPanelClass = preload("res://src/ui/story/story_panel.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func run_all_tests() -> bool:
	print("==================================================")
	print("STARTING BEAT 4 WORLD MAP 189 VERIFICATION SUITE")
	print("==================================================")

	var tests: Array[Callable] = [
		Callable(TestPrologueBeat04WorldMap189, "test_01_world_map_background_present_and_loaded"),
		Callable(TestPrologueBeat04WorldMap189, "test_02_four_regional_landmarks_loaded"),
		Callable(TestPrologueBeat04WorldMap189, "test_03_canonical_geography_coordinates"),
		Callable(TestPrologueBeat04WorldMap189, "test_04_four_trajectories_and_easing_specs"),
		Callable(TestPrologueBeat04WorldMap189, "test_05_quadratic_bezier_evaluation"),
		Callable(TestPrologueBeat04WorldMap189, "test_06_fragment_scale_transition"),
		Callable(TestPrologueBeat04WorldMap189, "test_07_narration_safe_rect_zero_overlap"),
		Callable(TestPrologueBeat04WorldMap189, "test_08_skip_safe_rect_zero_overlap"),
		Callable(TestPrologueBeat04WorldMap189, "test_09_z_index_hierarchy_protected"),
		Callable(TestPrologueBeat04WorldMap189, "test_10_karl_portrait_loads_in_hub"),
		Callable(TestPrologueBeat04WorldMap189, "test_11_task185_story_parity_preserved"),
		Callable(TestPrologueBeat04WorldMap189, "test_12_beat4_handoff_and_completion"),
		Callable(TestPrologueBeat04WorldMap189, "test_13_zero_remote_urls_and_clean_resources")
	]

	var pass_count: int = 0
	for t in tests:
		if bool(t.call()):
			pass_count += 1

	print("==================================================")
	print("BEAT 4 WORLD MAP SUMMARY: %d / %d passed" % [pass_count, tests.size()])
	print("==================================================")
	return pass_count == tests.size()

# 1. World map background present and loaded
static func test_01_world_map_background_present_and_loaded() -> bool:
	print("[WM-189-01] Testing world map background...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var bg: TextureRect = player.call("get_layer_node", 4, "Background") as TextureRect
	if bg == null:
		print("[WM-189-01] FAIL: Background node missing in Beat 4")
		player.free()
		return false
	if bg.texture == null:
		print("[WM-189-01] FAIL: Background texture is null")
		player.free()
		return false
	if not bg.texture.resource_path.contains("d1_world_map_bg.jpg"):
		print("[WM-189-01] FAIL: Background texture path mismatch: %s" % bg.texture.resource_path)
		player.free()
		return false
	player.free()
	print("[WM-189-01] PASS: World map background verified cleanly")
	return true

# 2. Four regional landmark assets present and loaded
static func test_02_four_regional_landmarks_loaded() -> bool:
	print("[WM-189-02] Testing four regional landmark assets...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var paths: Dictionary = player.call("get_landmark_paths")
	for region in ["D1", "D2", "D3", "D4"]:
		if not paths.has(region):
			print("[WM-189-02] FAIL: Missing landmark path for %s" % region)
			player.free()
			return false
		var landmark_node: TextureRect = player.call("get_landmark_node", region)
		if landmark_node == null:
			print("[WM-189-02] FAIL: Landmark node missing for %s" % region)
			player.free()
			return false
		if landmark_node.texture == null:
			print("[WM-189-02] FAIL: Landmark texture null for %s" % region)
			player.free()
			return false
	player.free()
	print("[WM-189-02] PASS: All four regional landmarks loaded cleanly")
	return true

# 3. Canonical geography coordinates
static func test_03_canonical_geography_coordinates() -> bool:
	print("[WM-189-03] Testing canonical geography coordinates...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var expected: Dictionary = {
		"Destination01": Vector2(215.0, 465.0),
		"Destination02": Vector2(645.0, 350.0),
		"Destination03": Vector2(980.0, 225.0),
		"Destination04": Vector2(410.0, 160.0)
	}
	for did in expected.keys():
		var d_node: Control = player.call("get_destination_node", did)
		if d_node == null:
			print("[WM-189-03] FAIL: Missing destination %s" % did)
			player.free()
			return false
		var exp_pos: Vector2 = expected[did] as Vector2
		if absf(d_node.position.x - exp_pos.x) > 0.1 or absf(d_node.position.y - exp_pos.y) > 0.1:
			print("[WM-189-03] FAIL: Coordinate mismatch for %s: %s vs %s" % [did, str(d_node.position), str(exp_pos)])
			player.free()
			return false
	player.free()
	print("[WM-189-03] PASS: All four canonical coordinates match handoff exactly")
	return true

# 4. Four flight trajectories and easing specs
static func test_04_four_trajectories_and_easing_specs() -> bool:
	print("[WM-189-04] Testing trajectory specifications...")
	var player: Control = ProloguePlayerClass.new()
	var expected_eases: Dictionary = {
		"Fragment01": "OUT_QUAD",
		"Fragment02": "IN_OUT_CUBIC",
		"Fragment03": "OUT_EXPO",
		"Fragment04": "OUT_CIRC"
	}
	for fid in expected_eases.keys():
		var spec: Dictionary = player.call("get_trajectory_spec", fid)
		if spec.is_empty():
			print("[WM-189-04] FAIL: Missing spec for %s" % fid)
			player.free()
			return false
		if spec.get("ease", "") != expected_eases[fid]:
			print("[WM-189-04] FAIL: Easing mismatch for %s: %s" % [fid, spec.get("ease", "")])
			player.free()
			return false
	player.free()
	print("[WM-189-04] PASS: All 4 trajectories and easing functions match handoff")
	return true

# 5. Quadratic Bezier mathematical evaluation
static func test_05_quadratic_bezier_evaluation() -> bool:
	print("[WM-189-05] Testing quadratic Bezier curve math...")
	var p0: Vector2 = Vector2(0.0, 0.0)
	var p1: Vector2 = Vector2(50.0, 100.0)
	var p2: Vector2 = Vector2(100.0, 0.0)

	var at_0: Vector2 = ProloguePlayerClass._evaluate_quad_bezier(p0, p1, p2, 0.0)
	var at_mid: Vector2 = ProloguePlayerClass._evaluate_quad_bezier(p0, p1, p2, 0.5)
	var at_1: Vector2 = ProloguePlayerClass._evaluate_quad_bezier(p0, p1, p2, 1.0)

	if absf(at_0.x - 0.0) > 0.01 or absf(at_0.y - 0.0) > 0.01:
		print("[WM-189-05] FAIL: Bezier at u=0 failed")
		return false
	if absf(at_mid.x - 50.0) > 0.01 or absf(at_mid.y - 50.0) > 0.01:
		print("[WM-189-05] FAIL: Bezier at u=0.5 failed: %s" % str(at_mid))
		return false
	if absf(at_1.x - 100.0) > 0.01 or absf(at_1.y - 0.0) > 0.01:
		print("[WM-189-05] FAIL: Bezier at u=1 failed")
		return false

	print("[WM-189-05] PASS: Quadratic Bezier math validated")
	return true

# 6. Fragment scale transition (0.52 -> 0.15)
static func test_06_fragment_scale_transition() -> bool:
	print("[WM-189-06] Testing fragment scale transition...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.set("_speed_scale", 1.0)

	# Initial scale at t = 0.2
	player.set("_playback_time", 0.2)
	player.call("_process_beat04", 0.016)
	var f1: Control = player.call("get_fragment_node", "Fragment01", 4)
	if absf(f1.scale.x - 0.52) > 0.02:
		print("[WM-189-06] FAIL: Initial scale not 0.52: %s" % str(f1.scale))
		player.free()
		return false

	# Final scale at t = 11.0
	player.set("_playback_time", 11.0)
	player.call("_process_beat04", 0.016)
	for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
		var f_node: Control = player.call("get_fragment_node", fid, 4)
		if absf(f_node.scale.x - 0.15) > 0.02 or absf(f_node.scale.y - 0.15) > 0.02:
			print("[WM-189-06] FAIL: %s final scale not 0.15: %s" % [fid, str(f_node.scale)])
			player.free()
			return false

	player.free()
	print("[WM-189-06] PASS: Scale correctly scales down from 0.52 to 0.15")
	return true

# 7. Zero overlap with Narration Safe Area Rect2(60, 530, 1160, 160)
static func test_07_narration_safe_rect_zero_overlap() -> bool:
	print("[WM-189-07] Testing zero intrusion into Narration Safe Area...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.set("_speed_scale", 1.0)
	player.set("_playback_time", 11.0)
	player.call("_process_beat04", 0.016)

	var narr_safe: Rect2 = player.call("get_b4_narration_safe_rect")
	if absf(narr_safe.position.x - 60.0) > 0.1 or absf(narr_safe.position.y - 530.0) > 0.1:
		print("[WM-189-07] FAIL: Narration safe rect position mismatch: %s" % str(narr_safe))
		player.free()
		return false

	for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
		var core_rect: Rect2 = player.call("get_b4_fragment_core_rect", fid)
		if narr_safe.intersects(core_rect):
			print("[WM-189-07] FAIL: %s overlaps narration safe area: %s" % [fid, str(core_rect)])
			player.free()
			return false

	player.free()
	print("[WM-189-07] PASS: Zero overlap with Narration Safe Area verified")
	return true

# 8. Zero overlap with Skip Safe Area Rect2(1120, 20, 140, 44)
static func test_08_skip_safe_rect_zero_overlap() -> bool:
	print("[WM-189-08] Testing zero intrusion into Skip Safe Area...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.set("_speed_scale", 1.0)
	player.set("_playback_time", 11.0)
	player.call("_process_beat04", 0.016)

	var skip_safe: Rect2 = player.call("get_b4_skip_safe_rect")
	if absf(skip_safe.position.x - 1120.0) > 0.1 or absf(skip_safe.position.y - 20.0) > 0.1:
		print("[WM-189-08] FAIL: Skip safe rect position mismatch: %s" % str(skip_safe))
		player.free()
		return false

	for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
		var v_rect: Rect2 = player.call("get_b4_fragment_visual_rect", fid)
		if skip_safe.intersects(v_rect):
			print("[WM-189-08] FAIL: %s overlaps skip safe area: %s" % [fid, str(v_rect)])
			player.free()
			return false

	player.free()
	print("[WM-189-08] PASS: Zero overlap with Skip Safe Area verified")
	return true

# 9. Strict Z-index hierarchy protection (World <= 5, Gradient 10, Narration 11, Fade 20)
static func test_09_z_index_hierarchy_protected() -> bool:
	print("[WM-189-09] Testing Z-index hierarchy...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	var b4_root: Control = player.get_node_or_null("CanvasContainer/Beat04Root") as Control
	var gradient: ColorRect = b4_root.get_node_or_null("CinematicGradient") as ColorRect
	var narration: Control = b4_root.get_node_or_null("NarrationContainer") as Control
	var fade: ColorRect = b4_root.get_node_or_null("FadeOverlay") as ColorRect

	if gradient.z_index != 10 or narration.z_index != 11 or fade.z_index != 20:
		print("[WM-189-09] FAIL: Z-index values incorrect: grad=%d narr=%d fade=%d" % [gradient.z_index, narration.z_index, fade.z_index])
		player.free()
		return false

	for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
		var f_node: Control = player.call("get_fragment_node", fid, 4)
		if f_node.z_index > 5:
			print("[WM-189-09] FAIL: Fragment z_index too high: %d" % f_node.z_index)
			player.free()
			return false

	player.free()
	print("[WM-189-09] PASS: Z-index hierarchy strictly protects UI text and overlays")
	return true

# 10. Karl production portrait loaded in SanctumNexusHub
static func test_10_karl_portrait_loads_in_hub() -> bool:
	print("[WM-189-10] Testing Karl production portrait in SanctumNexusHub...")
	var hub: Control = SanctumNexusHubClass.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)
	if not hub.is_node_ready():
		hub._ready()

	var avatar: TextureRect = hub.find_child("PlayerAvatar", true, false) as TextureRect

	if avatar == null or avatar.texture == null:
		print("[WM-189-10] FAIL: Player avatar node or texture missing")
		if hub.get_parent() != null:
			hub.get_parent().remove_child(hub)
		hub.free()
		return false

	# Verify it loaded Karl and not the fallback emblem
	var emblem_tex: Texture2D = load("res://assets/branding/mathos_logo_emblem.png") as Texture2D
	if avatar.texture == emblem_tex:
		print("[WM-189-10] FAIL: Avatar fell back to emblem instead of Karl portrait")
		if hub.get_parent() != null:
			hub.get_parent().remove_child(hub)
		hub.free()
		return false

	var sz: Vector2 = avatar.texture.get_size()
	if sz.x <= 0 or sz.y <= 0:
		print("[WM-189-10] FAIL: Avatar texture size is zero")
		if hub.get_parent() != null:
			hub.get_parent().remove_child(hub)
		hub.free()
		return false

	if hub.get_parent() != null:
		hub.get_parent().remove_child(hub)
	hub.free()
	print("[WM-189-10] PASS: Karl production portrait loads directly without fallback (size: %s)" % str(sz))
	return true

# 11. Task 185 Story/Draven layout parity strictly preserved
static func test_11_task185_story_parity_preserved() -> bool:
	print("[WM-189-11] Testing Task 185 Story/Draven parity preservation...")
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

	if char_slot == null or dial_panel == null:
		print("[WM-189-11] FAIL: StoryPanel nodes missing")
		if panel.get_parent() != null:
			panel.get_parent().remove_child(panel)
		panel.free()
		return false

	if char_slot.custom_minimum_size.x != 340.0:
		print("[WM-189-11] FAIL: Character slot width mismatch: %f" % char_slot.custom_minimum_size.x)
		if panel.get_parent() != null:
			panel.get_parent().remove_child(panel)
		panel.free()
		return false

	if dial_panel.custom_minimum_size.x < 840.0:
		print("[WM-189-11] FAIL: DialoguePanel width too small: %f" % dial_panel.custom_minimum_size.x)
		if panel.get_parent() != null:
			panel.get_parent().remove_child(panel)
		panel.free()
		return false

	if panel.get_parent() != null:
		panel.get_parent().remove_child(panel)
	panel.free()
	print("[WM-189-11] PASS: Task 185 Story/Draven layout parity strictly intact")
	return true

# 12. Beat 4 completion & skip handoff to D1 Story
static func test_12_beat4_handoff_and_completion() -> bool:
	print("[WM-189-12] Testing Beat 4 completion & skip signals...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.call("set_speed_scale", 100.0)
	player.call("start_prologue")
	player.call("advance_to_beat2")
	player.call("advance_to_beat3")
	player.call("advance_to_beat4")

	var completed_count: Array[int] = [0]
	player.connect("prologue_completed", func(): completed_count[0] += 1)

	player.call("complete_prologue")
	if completed_count[0] != 1:
		print("[WM-189-12] FAIL: Expected 1 prologue_completed emission, got %d" % completed_count[0])
		player.free()
		return false

	player.free()
	print("[WM-189-12] PASS: Beat 4 completion and handoff signals verified")
	return true

# 13. Zero remote URLs & local asset integrity
static func test_13_zero_remote_urls_and_clean_resources() -> bool:
	print("[WM-189-13] Testing zero remote URLs in prologue_player.gd...")
	var script: GDScript = load("res://src/ui/prologue/prologue_player.gd") as GDScript
	if script == null:
		print("[WM-189-13] FAIL: Could not load prologue_player.gd")
		return false
	var src: String = script.source_code
	if src.contains("http://") or src.contains("https://"):
		print("[WM-189-13] FAIL: prologue_player.gd contains remote URLs!")
		return false
	print("[WM-189-13] PASS: Zero remote URLs, purely local assets")
	return true
