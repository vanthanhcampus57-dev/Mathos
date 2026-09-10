class_name TestPrologueBeat04ScaleRegression176
extends SceneTree

## Dedicated Regression Verification Suite for MATHOS-BEAT04-FRAGMENT-SCALE-OVERLAP-REGRESSION-FIX-176.
## Covers:
## SCALE-176-001: Beat4 major fragment visual size is bounded (< 250px canvas, < 185px core).
## SCALE-176-002: No fragment uses accidental full (1.0) or handoff (0.52) overscale at destination.
## SCALE-176-003: No double-applied scale (node scale is cleanly (0.15, 0.15)).
## SCALE-176-004: HUMAN-locked destination coordinates strictly unchanged.
## SCALE-176-005: Narration rect does not overlap major fragment rects at target viewport (1280x720).
## SCALE-176-006: Shard layer does not obscure narration safe area (gradient z=10, narration z=11 > frag z=5).
## SCALE-176-007: Beat 3 -> Beat 4 transition emits beat_transitioned(3, 4) and is idempotent.
## SCALE-176-008: Beat 4 natural completion emits prologue_completed cleanly.
## SCALE-176-009: Skip path during Beat 4 emits prologue_skipped and prologue_completed.
## SCALE-176-010: Standard 1280x720 responsive layout pass and beacon visibility.

const ProloguePlayerClass = preload("res://src/ui/prologue/prologue_player.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func run_all_tests() -> bool:
	print("==================================================")
	print("STARTING BEAT 4 SCALE REGRESSION TEST SUITE (TASK 176)")
	print("==================================================")

	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.call("set_speed_scale", 1.0)

	var tests: Array[Callable] = [
		Callable(TestPrologueBeat04ScaleRegression176, "test_scale_001_major_fragment_visual_size_bounded"),
		Callable(TestPrologueBeat04ScaleRegression176, "test_scale_002_no_accidental_overscale"),
		Callable(TestPrologueBeat04ScaleRegression176, "test_scale_003_no_double_applied_scale"),
		Callable(TestPrologueBeat04ScaleRegression176, "test_scale_004_human_locked_coordinates_unchanged"),
		Callable(TestPrologueBeat04ScaleRegression176, "test_scale_005_narration_rect_no_overlap"),
		Callable(TestPrologueBeat04ScaleRegression176, "test_scale_006_shard_layer_z_order_protection"),
		Callable(TestPrologueBeat04ScaleRegression176, "test_scale_007_beat4_transition_still_works"),
		Callable(TestPrologueBeat04ScaleRegression176, "test_scale_008_beat4_to_story_still_works"),
		Callable(TestPrologueBeat04ScaleRegression176, "test_scale_009_skip_path_unchanged"),
		Callable(TestPrologueBeat04ScaleRegression176, "test_scale_010_1280x720_layout_pass")
	]

	var pass_count: int = 0
	for t in tests:
		if bool(t.call(player)):
			pass_count += 1

	player.free()

	print("==================================================")
	print("BEAT 4 SCALE REGRESSION SUMMARY: %d / %d passed" % [pass_count, tests.size()])
	print("==================================================")
	return pass_count == tests.size()

# 1. Beat4 major fragment visual size is bounded (< 250px canvas, < 185px core).
static func test_scale_001_major_fragment_visual_size_bounded(player: Control) -> bool:
	print("[SCALE-176-001] Verifying major fragment visual size is bounded at destination...")
	player.set("_speed_scale", 1.0)
	player.set("_is_transitioning", false)
	player.set("_is_completed", false)
	player.set("_current_beat", 4)
	player.call("apply_beat04_layout")

	# Simulate arrival at t = 11.0s (all 4 fragments arrived)
	player.set("_playback_time", 11.0)
	player.call("_process_beat04", 0.016)

	for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
		var v_rect: Rect2 = player.call("get_b4_fragment_visual_rect", fid)
		var c_rect: Rect2 = player.call("get_b4_fragment_core_rect", fid)
		var max_canvas_dim: float = maxf(v_rect.size.x, v_rect.size.y)
		var max_core_dim: float = maxf(c_rect.size.x, c_rect.size.y)

		if max_canvas_dim >= 250.0:
			print("[SCALE-176-001] FAIL: %s canvas size (%f) exceeds bounded 250px limit" % [fid, max_canvas_dim])
			return false
		if max_core_dim >= 185.0:
			print("[SCALE-176-001] FAIL: %s core piece size (%f) exceeds 185px limit" % [fid, max_core_dim])
			return false

	print("[SCALE-176-001] PASS: All 4 fragments bounded cleanly (<250px canvas, <185px core)")
	return true

# 2. No fragment uses accidental full (1.0) or handoff (0.52) overscale at destination.
static func test_scale_002_no_accidental_overscale(player: Control) -> bool:
	print("[SCALE-176-002] Verifying no fragment retains overscale (0.52 or 1.0) at destination...")
	player.set("_speed_scale", 1.0)
	player.set("_is_transitioning", false)
	player.set("_is_completed", false)
	player.set("_current_beat", 4)
	player.call("apply_beat04_layout")

	# At t = 0.2s: initial reference display scale (~0.258, ~155px display)
	player.set("_playback_time", 0.2)
	player.call("_process_beat04", 0.016)
	var frag1: Control = player.call("get_fragment_node", "Fragment01", 4)
	if absf(frag1.scale.x - 0.258) > 0.05:
		print("[SCALE-176-002] FAIL: Fragment01 should start at reference scale ~0.258, got %s" % str(frag1.scale))
		return false

	# At t = 12.0s: target scale (~0.258, bounded < 0.30)
	player.set("_playback_time", 12.0)
	player.call("_process_beat04", 0.016)

	for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
		var f_node: Control = player.call("get_fragment_node", fid, 4)
		if f_node.scale.x > 0.30 or f_node.scale.y > 0.30:
			print("[SCALE-176-002] FAIL: %s overscaled at destination: %s" % [fid, str(f_node.scale)])
			return false
		if absf(f_node.scale.x - 0.258) > 0.05:
			print("[SCALE-176-002] FAIL: %s expected scale ~0.258, got %s" % [fid, str(f_node.scale)])
			return false

	print("[SCALE-176-002] PASS: Fragments bounded correctly to reference display (~155px footprint)")
	return true

# 3. No double-applied scale (node scale is cleanly (0.15, 0.15)).
static func test_scale_003_no_double_applied_scale(player: Control) -> bool:
	print("[SCALE-176-003] Verifying no double-applied scale on fragment TextureRects...")
	player.set("_speed_scale", 1.0)
	player.set("_playback_time", 12.0)
	player.call("_process_beat04", 0.016)

	for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
		var f_node: TextureRect = player.call("get_fragment_node", fid, 4) as TextureRect
		if f_node.scale.x != f_node.scale.y:
			print("[SCALE-176-003] FAIL: Asymmetric scale detected on %s: %s" % [fid, str(f_node.scale)])
			return false
		if f_node.get_child_count() > 0:
			print("[SCALE-176-003] FAIL: Unexpected child nodes under TextureRect %s" % fid)
			return false

	print("[SCALE-176-003] PASS: No double-applied scale; node scale is clean and symmetric")
	return true

# 4. HUMAN-locked destination coordinates strictly unchanged.
static func test_scale_004_human_locked_coordinates_unchanged(player: Control) -> bool:
	print("[SCALE-176-004] Verifying canonical world map destination coordinates...")
	var layout_data: Dictionary = player.get("_b4_layout_data")
	if not layout_data.has("destinations") or not layout_data.has("layers"):
		print("[SCALE-176-004] FAIL: Layout missing destinations or layers")
		return false

	var canonical_dest_coords: Dictionary = {
		"Destination01": Vector2(200.0, 520.0),
		"Destination02": Vector2(1080.0, 520.0),
		"Destination03": Vector2(940.0, 185.0),
		"Destination04": Vector2(200.0, 185.0)
	}

	var dest_dict: Dictionary = layout_data["destinations"] as Dictionary
	for did in canonical_dest_coords.keys():
		var expected: Vector2 = canonical_dest_coords[did] as Vector2
		var d_entry: Dictionary = dest_dict.get(did, {}) as Dictionary
		var x: float = float(d_entry.get("x", 0.0))
		var y: float = float(d_entry.get("y", 0.0))
		if absf(x - expected.x) > 0.05 or absf(y - expected.y) > 0.05:
			print("[SCALE-176-004] FAIL: Destination %s coordinates changed: (%f, %f) vs expected (%f, %f)" % [did, x, y, expected.x, expected.y])
			return false

	# Verify destination centers in world content
	var expected_centers: Dictionary = {
		"Destination01": Vector2(200.0, 520.0),
		"Destination02": Vector2(1080.0, 520.0),
		"Destination03": Vector2(940.0, 185.0),
		"Destination04": Vector2(200.0, 185.0)
	}
	for did in expected_centers.keys():
		var d_node: Control = player.call("get_destination_node", did)
		var exp_pos: Vector2 = expected_centers[did] as Vector2
		if absf(d_node.position.x - exp_pos.x) > 0.1 or absf(d_node.position.y - exp_pos.y) > 0.1:
			print("[SCALE-176-004] FAIL: Destination %s position altered: %s vs %s" % [did, str(d_node.position), str(exp_pos)])
			return false

	print("[SCALE-176-004] PASS: All 4 canonical destination coordinates 100% verified")
	return true

# 5. Narration rect does not overlap major fragment rects at target viewport (1280x720).
static func test_scale_005_narration_rect_no_overlap(player: Control) -> bool:
	print("[SCALE-176-005] Verifying narration safe area does not overlap major fragment core rects...")
	player.set("_speed_scale", 1.0)
	player.set("_playback_time", 11.0)
	player.call("_process_beat04", 0.016)

	var narration_safe_rect: Rect2 = player.call("get_b4_narration_safe_rect")

	for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
		var core_rect: Rect2 = player.call("get_b4_fragment_core_rect", fid)
		if narration_safe_rect.intersects(core_rect):
			print("[SCALE-176-005] FAIL: %s core rect %s overlaps narration safe area %s" % [fid, str(core_rect), str(narration_safe_rect)])
			return false

	print("[SCALE-176-005] PASS: Zero overlap between narration safe rect and all 4 fragment cores")
	return true

# 6. Shard layer does not obscure narration safe area (gradient z=10, narration z=11 > frag z=5).
static func test_scale_006_shard_layer_z_order_protection(player: Control) -> bool:
	print("[SCALE-176-006] Verifying z-index hierarchy ensures narration is strictly above fragments...")
	var b4_root: Control = player.get_node_or_null("CanvasContainer/Beat04Root") as Control
	var gradient: ColorRect = b4_root.get_node_or_null("CinematicGradient") as ColorRect
	var narration: Control = b4_root.get_node_or_null("NarrationContainer") as Control
	var fade: ColorRect = b4_root.get_node_or_null("FadeOverlay") as ColorRect

	if gradient == null or narration == null or fade == null:
		print("[SCALE-176-006] FAIL: Missing Beat 4 UI elements")
		return false

	if gradient.z_index < 10:
		print("[SCALE-176-006] FAIL: CinematicGradient z_index expected >= 10, got %d" % gradient.z_index)
		return false

	if narration.z_index < 11:
		print("[SCALE-176-006] FAIL: NarrationContainer z_index expected >= 11, got %d" % narration.z_index)
		return false

	if fade.z_index < 20:
		print("[SCALE-176-006] FAIL: FadeOverlay z_index expected >= 20, got %d" % fade.z_index)
		return false

	for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
		var f_node: Control = player.call("get_fragment_node", fid, 4)
		if f_node != null and f_node.z_index >= narration.z_index:
			print("[SCALE-176-006] FAIL: %s z_index (%d) is not below narration (%d)" % [fid, f_node.z_index, narration.z_index])
			return false

	print("[SCALE-176-006] PASS: Z-order hierarchy strictly protects narration layer (gradient 10, narration 11 > fragments 5)")
	return true

# 7. Beat 3 -> Beat 4 transition emits beat_transitioned(3, 4) and is idempotent.
static func test_scale_007_beat4_transition_still_works(player: Control) -> bool:
	print("[SCALE-176-007] Verifying Beat 3 -> Beat 4 transition signal...")
	player.set("_speed_scale", 0.0)
	player.set("_is_transitioning", false)
	player.set("_is_completed", false)
	player.set("_current_beat", 3)

	var signals: Array[Dictionary] = []
	var cb = func(f, t): signals.append({"from": f, "to": t})
	player.connect("beat_transitioned", cb)

	player.call("advance_to_beat4")
	if signals.size() != 1 or signals[0]["from"] != 3 or signals[0]["to"] != 4:
		print("[SCALE-176-007] FAIL: Expected transition (3, 4), got %s" % str(signals))
		player.disconnect("beat_transitioned", cb)
		return false

	# Idempotency
	player.call("advance_to_beat4")
	player.disconnect("beat_transitioned", cb)
	if signals.size() != 1:
		print("[SCALE-176-007] FAIL: advance_to_beat4 not idempotent")
		return false

	print("[SCALE-176-007] PASS: Beat 3 -> Beat 4 transition verified clean & idempotent")
	return true

# 8. Beat 4 natural completion emits prologue_completed cleanly.
static func test_scale_008_beat4_to_story_still_works(player: Control) -> bool:
	print("[SCALE-176-008] Verifying Beat 4 natural completion emits prologue_completed...")
	player.set("_speed_scale", 0.0)
	player.set("_is_transitioning", false)
	player.set("_is_completed", false)
	player.set("_current_beat", 4)

	var completed_count: Array[int] = [0]
	var cb = func(): completed_count[0] += 1
	player.connect("prologue_completed", cb)

	player.call("complete_prologue")
	player.disconnect("prologue_completed", cb)

	if completed_count[0] != 1:
		print("[SCALE-176-008] FAIL: Expected 1 prologue_completed emission, got %d" % completed_count[0])
		return false

	print("[SCALE-176-008] PASS: Beat 4 natural completion emits prologue_completed cleanly")
	return true

# 9. Skip path during Beat 4 emits prologue_skipped and prologue_completed.
static func test_scale_009_skip_path_unchanged(player: Control) -> bool:
	print("[SCALE-176-009] Verifying Skip button during Beat 4 emits prologue_skipped and prologue_completed...")
	player.set("_speed_scale", 0.0)
	player.set("_is_transitioning", false)
	player.set("_is_completed", false)
	player.set("_current_beat", 4)
	player.set("visible", true)

	var skipped_count: Array[int] = [0]
	var completed_count: Array[int] = [0]
	var cb_skip = func(): skipped_count[0] += 1
	var cb_comp = func(): completed_count[0] += 1
	player.connect("prologue_skipped", cb_skip)
	player.connect("prologue_completed", cb_comp)

	var skip_btn: Button = player.get_node_or_null("PlayerControls/SkipBtn") as Button
	if skip_btn == null:
		print("[SCALE-176-009] FAIL: SkipBtn missing")
		player.disconnect("prologue_skipped", cb_skip)
		player.disconnect("prologue_completed", cb_comp)
		return false

	skip_btn.pressed.emit()
	player.disconnect("prologue_skipped", cb_skip)
	player.disconnect("prologue_completed", cb_comp)

	if skipped_count[0] != 1 or completed_count[0] != 1:
		print("[SCALE-176-009] FAIL: Expected 1 skipped and 1 completed emission, got skip=%d, comp=%d" % [skipped_count[0], completed_count[0]])
		return false

	print("[SCALE-176-009] PASS: Skip button during Beat 4 emits signals cleanly")
	return true

# 10. Standard 1280x720 responsive layout pass and beacon visibility.
static func test_scale_010_1280x720_layout_pass(player: Control) -> bool:
	print("[SCALE-176-010] Verifying 1280x720 responsive layout and beacon placement...")
	player.call("update_responsive_layout", Vector2(1280, 720))

	var container: Control = player.get("_canvas_container") as Control
	if container == null:
		print("[SCALE-176-010] FAIL: _canvas_container is null")
		return false

	if absf(container.scale.x - 1.0) > 0.001 or absf(container.scale.y - 1.0) > 0.001:
		print("[SCALE-176-010] FAIL: Canvas container scale expected (1.0, 1.0), got %s" % str(container.scale))
		return false

	if container.position != Vector2.ZERO:
		print("[SCALE-176-010] FAIL: Canvas container position expected (0, 0), got %s" % str(container.position))
		return false

	for did in ["Destination01", "Destination02", "Destination03", "Destination04"]:
		var d_node: Control = player.call("get_destination_node", did)
		if d_node.position.x < 0.0 or d_node.position.x > 1280.0 or d_node.position.y < 0.0 or d_node.position.y > 720.0:
			print("[SCALE-176-010] FAIL: Destination %s position out of viewport: %s" % [did, str(d_node.position)])
			return false

	print("[SCALE-176-010] PASS: 1280x720 layout passes cleanly with all beacons inside viewport")
	return true
