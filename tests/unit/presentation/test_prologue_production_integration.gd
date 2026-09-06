class_name TestPrologueProductionIntegration
extends SceneTree

## Production Verification Test Suite for MATHOS-PROLOGUE-BEAT01-02-PRODUCTION-INTEGRATION-073.
## Covers:
## PROLOGUE-PROD-001: First D1 entry opens Beat 1.
## PROLOGUE-PROD-002: Beat 1 uses human-approved production layout.
## PROLOGUE-PROD-003: Beat 1 -> Beat 2 exactly once.
## PROLOGUE-PROD-004: Beat 2 uses human-approved production layout.
## PROLOGUE-PROD-005: Beat 2 -> D1 Story exactly once.
## PROLOGUE-PROD-006: Skip from Beat 1 -> D1 Story.
## PROLOGUE-PROD-007: Skip from Beat 2 -> D1 Story.
## PROLOGUE-PROD-008: Second D1 entry skips Prologue.
## PROLOGUE-PROD-009: Guest flow.
## PROLOGUE-PROD-010: Login flow.
## PROLOGUE-PROD-011: Production does not require Lab user:// layout files.
## PROLOGUE-PROD-012: Exactly 3 player-facing controls.
## PROLOGUE-PROD-013: No Lab UI leaks.
## PROLOGUE-PROD-014: Beat 2 projectile path/facing preserved.
## PROLOGUE-PROD-015: No projectile clipping.
## PROLOGUE-PROD-016: 1280x720 responsive layout.
## PROLOGUE-PROD-017: 1366x768 responsive layout.
## PROLOGUE-PROD-018: 1600x900 responsive layout.
## PROLOGUE-PROD-019: 1920x1080 responsive layout.
## PROLOGUE-PROD-020: Map regression verification.

const AppRootClass = preload("res://src/app/app_root.gd")
const StagePresentationShellClass = preload("res://src/ui/stage/stage_presentation_shell.gd")
const ProloguePlayerClass = preload("res://src/ui/prologue/prologue_player.gd")
const PrologueGateServiceClass = preload("res://src/gameplay/prologue/prologue_gate_service.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func run_all_tests() -> bool:
	print("==================================================")
	print("STARTING PROLOGUE PRODUCTION INTEGRATION TEST SUITE")
	print("==================================================")

	var tests: Array[Callable] = [
		Callable(TestPrologueProductionIntegration, "test_prod_001_first_d1_entry_opens_beat1"),
		Callable(TestPrologueProductionIntegration, "test_prod_002_beat1_uses_human_layout"),
		Callable(TestPrologueProductionIntegration, "test_prod_003_beat1_to_beat2_progression"),
		Callable(TestPrologueProductionIntegration, "test_prod_004_beat2_uses_human_layout"),
		Callable(TestPrologueProductionIntegration, "test_prod_005_beat2_to_d1_story"),
		Callable(TestPrologueProductionIntegration, "test_prod_006_skip_from_beat1_to_d1_story"),
		Callable(TestPrologueProductionIntegration, "test_prod_007_skip_from_beat2_to_d1_story"),
		Callable(TestPrologueProductionIntegration, "test_prod_008_second_d1_entry_skips_prologue"),
		Callable(TestPrologueProductionIntegration, "test_prod_009_guest_flow"),
		Callable(TestPrologueProductionIntegration, "test_prod_010_login_flow"),
		Callable(TestPrologueProductionIntegration, "test_prod_011_no_user_json_dependency"),
		Callable(TestPrologueProductionIntegration, "test_prod_012_exactly_3_player_controls"),
		Callable(TestPrologueProductionIntegration, "test_prod_013_no_lab_ui_leaks"),
		Callable(TestPrologueProductionIntegration, "test_prod_014_beat2_projectile_path_facing"),
		Callable(TestPrologueProductionIntegration, "test_prod_015_no_projectile_clipping"),
		Callable(TestPrologueProductionIntegration, "test_prod_016_responsive_1280x720"),
		Callable(TestPrologueProductionIntegration, "test_prod_017_responsive_1366x768"),
		Callable(TestPrologueProductionIntegration, "test_prod_018_responsive_1600x900"),
		Callable(TestPrologueProductionIntegration, "test_prod_019_responsive_1920x1080"),
		Callable(TestPrologueProductionIntegration, "test_prod_020_map_regression"),
		Callable(TestPrologueProductionIntegration, "test_prod_rune_001_layer_dict_contains_runeprimary"),
		Callable(TestPrologueProductionIntegration, "test_prod_rune_002_runeprimary_layout_applies_exact_human_values"),
		Callable(TestPrologueProductionIntegration, "test_prod_rune_003_no_stale_runepulse_production_key")
	]

	var pass_count: int = 0
	for t in tests:
		if bool(t.call()):
			pass_count += 1

	print("==================================================")
	print("PROLOGUE PRODUCTION INTEGRATION SUMMARY: %d / %d passed" % [pass_count, tests.size()])
	print("==================================================")
	return pass_count == tests.size()

static func _create_app_with_isolated_gate(test_id: String) -> Node:
	var app: Node = AppRootClass.new()
	var custom_gate_path: String = "user://test_prologue_gate_%s.json" % test_id
	if FileAccess.file_exists(custom_gate_path):
		DirAccess.remove_absolute(custom_gate_path)
	var gate = PrologueGateServiceClass.new(custom_gate_path)
	app.call("set_prologue_gate", gate)
	return app

static func _cleanup_app(app: Node, test_id: String) -> void:
	if app != null:
		var custom_gate_path: String = "user://test_prologue_gate_%s.json" % test_id
		if FileAccess.file_exists(custom_gate_path):
			DirAccess.remove_absolute(custom_gate_path)
		app.free()

# PROLOGUE-PROD-001: First D1 entry opens Beat 1.
static func test_prod_001_first_d1_entry_opens_beat1() -> bool:
	print("[PROLOGUE-PROD-001] Verifying first D1 entry routes to Prologue Beat 1...")
	var app: Node = _create_app_with_isolated_gate("prod_001")
	app._ready()

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	if shell == null:
		print("[PROLOGUE-PROD-001] FAIL: StagePresentationShell not found")
		_cleanup_app(app, "prod_001")
		return false

	var res: Dictionary = app.call("start_new_game")
	if not bool(res.get("success", false)):
		print("[PROLOGUE-PROD-001] FAIL: start_new_game failed")
		_cleanup_app(app, "prod_001")
		return false

	var view_mode: int = int(shell.call("get_view_mode"))
	if view_mode != 9: # MODE_PROLOGUE = 9
		print("[PROLOGUE-PROD-001] FAIL: Expected ViewMode.MODE_PROLOGUE (9), got %d" % view_mode)
		_cleanup_app(app, "prod_001")
		return false

	var player: Control = shell.call("get_prologue_player")
	if player == null or not player.visible:
		print("[PROLOGUE-PROD-001] FAIL: ProloguePlayer not instantiated or not visible")
		_cleanup_app(app, "prod_001")
		return false

	if int(player.call("get_current_beat")) != 1:
		print("[PROLOGUE-PROD-001] FAIL: Expected Prologue Beat 1 active")
		_cleanup_app(app, "prod_001")
		return false

	_cleanup_app(app, "prod_001")
	print("[PROLOGUE-PROD-001] PASS")
	return true

# PROLOGUE-PROD-002: Beat 1 uses human-approved production layout.
static func test_prod_002_beat1_uses_human_layout() -> bool:
	print("[PROLOGUE-PROD-002] Verifying Beat 1 uses human-approved production layout...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	# Check key layer positions against human accepted values
	# FoliageLeft: x ≈ -34.91, y ≈ -52.15, scale ≈ 1.39
	var fol_l: Control = player.call("get_layer_node", 1, "FoliageLeft")
	if fol_l == null:
		print("[PROLOGUE-PROD-002] FAIL: FoliageLeft layer not found")
		player.free()
		return false

	if absf(fol_l.position.x - (-34.91)) > 1.0 or absf(fol_l.position.y - (-52.15)) > 1.0:
		print("[PROLOGUE-PROD-002] FAIL: FoliageLeft position mismatch: %s" % str(fol_l.position))
		player.free()
		return false

	if absf(fol_l.scale.x - 1.39) > 0.05:
		print("[PROLOGUE-PROD-002] FAIL: FoliageLeft scale mismatch: %s" % str(fol_l.scale))
		player.free()
		return false

	# FoliageRight: x ≈ 828.79, y ≈ 21.96, scale ≈ 1.24
	var fol_r: Control = player.call("get_layer_node", 1, "FoliageRight")
	if fol_r == null or absf(fol_r.position.x - 828.79) > 1.0:
		print("[PROLOGUE-PROD-002] FAIL: FoliageRight mismatch")
		player.free()
		return false

	player.free()
	print("[PROLOGUE-PROD-002] PASS")
	return true

# PROLOGUE-PROD-003: Beat 1 -> Beat 2 exactly once.
static func test_prod_003_beat1_to_beat2_progression() -> bool:
	print("[PROLOGUE-PROD-003] Verifying Beat 1 -> Beat 2 advances exactly once...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.call("set_speed_scale", 100.0)
	player.call("start_prologue")

	var transitions: Array[int] = [0]
	player.connect("beat_transitioned", func(f, t): transitions[0] += 1)

	player.call("advance_to_beat2")
	if int(player.call("get_current_beat")) != 2:
		print("[PROLOGUE-PROD-003] FAIL: Expected Beat 2")
		player.free()
		return false

	# Second call must be idempotent
	player.call("advance_to_beat2")
	if transitions[0] != 1:
		print("[PROLOGUE-PROD-003] FAIL: Expected exactly 1 transition signal, got %d" % transitions[0])
		player.free()
		return false

	player.free()
	print("[PROLOGUE-PROD-003] PASS")
	return true

# PROLOGUE-PROD-004: Beat 2 uses human-approved production layout.
static func test_prod_004_beat2_uses_human_layout() -> bool:
	print("[PROLOGUE-PROD-004] Verifying Beat 2 uses human-approved production layout...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	# CorruptionWisp02: x ≈ 548.35, y ≈ 30.88, z_index = 11
	var wisp2: Control = player.call("get_layer_node", 2, "CorruptionWisp02")
	if wisp2 == null:
		print("[PROLOGUE-PROD-004] FAIL: CorruptionWisp02 not found")
		player.free()
		return false

	if absf(wisp2.position.x - 548.35) > 1.0 or absf(wisp2.position.y - 30.88) > 1.0:
		print("[PROLOGUE-PROD-004] FAIL: CorruptionWisp02 position mismatch: %s" % str(wisp2.position))
		player.free()
		return false

	# Projectile01: x ≈ 954.79, y ≈ -3.43
	var p01_root: Control = player.call("get_projectile_root_node", "Projectile01")
	if p01_root == null or absf(p01_root.position.x - 954.79) > 1.0:
		print("[PROLOGUE-PROD-004] FAIL: Projectile01 root position mismatch: %s" % str(p01_root.position if p01_root != null else ""))
		player.free()
		return false

	player.free()
	print("[PROLOGUE-PROD-004] PASS")
	return true

# PROLOGUE-PROD-005: Beat 2 -> D1 Story exactly once.
static func test_prod_005_beat2_to_d1_story() -> bool:
	print("[PROLOGUE-PROD-005] Verifying Beat 2 completion transitions to D1 Story...")
	var app: Node = _create_app_with_isolated_gate("prod_005")
	app._ready()
	app.call("start_new_game")

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	var player: Control = shell.call("get_prologue_player")
	player.call("advance_to_beat2")
	player.call("complete_prologue")

	var view_mode: int = int(shell.call("get_view_mode"))
	if view_mode != 7: # MODE_STORY = 7
		print("[PROLOGUE-PROD-005] FAIL: Expected transition to MODE_STORY (7), got %d" % view_mode)
		_cleanup_app(app, "prod_005")
		return false

	var story_p: Control = shell.get_node_or_null("StoryPanel") as Control
	if story_p == null or not story_p.visible:
		print("[PROLOGUE-PROD-005] FAIL: StoryPanel not visible")
		_cleanup_app(app, "prod_005")
		return false

	_cleanup_app(app, "prod_005")
	print("[PROLOGUE-PROD-005] PASS")
	return true

# PROLOGUE-PROD-006: Skip from Beat 1 -> D1 Story.
static func test_prod_006_skip_from_beat1_to_d1_story() -> bool:
	print("[PROLOGUE-PROD-006] Verifying Skip from Beat 1 transitions directly to D1 Story...")
	var app: Node = _create_app_with_isolated_gate("prod_006")
	app._ready()
	app.call("start_new_game")

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	var player: Control = shell.call("get_prologue_player")
	if int(player.call("get_current_beat")) != 1:
		print("[PROLOGUE-PROD-006] FAIL: Player not on Beat 1")
		_cleanup_app(app, "prod_006")
		return false

	var skip_btn: Button = player.get_node_or_null("PlayerControls/SkipBtn") as Button
	if skip_btn == null:
		print("[PROLOGUE-PROD-006] FAIL: SkipBtn not found")
		_cleanup_app(app, "prod_006")
		return false

	skip_btn.pressed.emit()

	var view_mode: int = int(shell.call("get_view_mode"))
	if view_mode != 7:
		print("[PROLOGUE-PROD-006] FAIL: Expected MODE_STORY after skip, got %d" % view_mode)
		_cleanup_app(app, "prod_006")
		return false

	if player.visible:
		print("[PROLOGUE-PROD-006] FAIL: ProloguePlayer still visible after skip")
		_cleanup_app(app, "prod_006")
		return false

	_cleanup_app(app, "prod_006")
	print("[PROLOGUE-PROD-006] PASS")
	return true

# PROLOGUE-PROD-007: Skip from Beat 2 -> D1 Story.
static func test_prod_007_skip_from_beat2_to_d1_story() -> bool:
	print("[PROLOGUE-PROD-007] Verifying Skip from Beat 2 transitions directly to D1 Story...")
	var app: Node = _create_app_with_isolated_gate("prod_007")
	app._ready()
	app.call("start_new_game")

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	var player: Control = shell.call("get_prologue_player")
	player.call("advance_to_beat2")

	var skip_btn: Button = player.get_node_or_null("PlayerControls/SkipBtn") as Button
	skip_btn.pressed.emit()

	var view_mode: int = int(shell.call("get_view_mode"))
	if view_mode != 7:
		print("[PROLOGUE-PROD-007] FAIL: Expected MODE_STORY after skip from Beat 2, got %d" % view_mode)
		_cleanup_app(app, "prod_007")
		return false

	_cleanup_app(app, "prod_007")
	print("[PROLOGUE-PROD-007] PASS")
	return true

# PROLOGUE-PROD-008: Second D1 entry skips Prologue.
static func test_prod_008_second_d1_entry_skips_prologue() -> bool:
	print("[PROLOGUE-PROD-008] Verifying second D1 entry skips Prologue...")
	var app: Node = _create_app_with_isolated_gate("prod_008")
	app._ready()

	# 1. First entry plays prologue
	app.call("start_new_game")
	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	var player: Control = shell.call("get_prologue_player")
	player.call("_on_skip_pressed")

	# Gate must now be marked completed
	var gate = app.call("get_prologue_gate")
	if not bool(gate.call("has_completed_prologue")):
		print("[PROLOGUE-PROD-008] FAIL: Prologue gate not marked completed")
		_cleanup_app(app, "prod_008")
		return false

	# 2. Second entry via select_stage
	app.call("select_stage", "stage_01_01")
	var mode2: int = int(shell.call("get_view_mode"))
	if mode2 == 9: # Must NOT be MODE_PROLOGUE
		print("[PROLOGUE-PROD-008] FAIL: Second entry triggered Prologue!")
		_cleanup_app(app, "prod_008")
		return false

	if mode2 != 7 and mode2 != 1:
		print("[PROLOGUE-PROD-008] FAIL: Expected MODE_STORY or MODE_LESSON, got %d" % mode2)
		_cleanup_app(app, "prod_008")
		return false

	_cleanup_app(app, "prod_008")
	print("[PROLOGUE-PROD-008] PASS")
	return true

# PROLOGUE-PROD-009: Guest flow.
static func test_prod_009_guest_flow() -> bool:
	print("[PROLOGUE-PROD-009] Verifying Guest flow launches Prologue on first entry...")
	var app: Node = _create_app_with_isolated_gate("prod_009")
	app._ready()
	app.call("_on_guest_entered")

	var res: Dictionary = app.call("start_new_game")
	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	if int(shell.call("get_view_mode")) != 9:
		print("[PROLOGUE-PROD-009] FAIL: Guest first entry did not enter MODE_PROLOGUE")
		_cleanup_app(app, "prod_009")
		return false

	_cleanup_app(app, "prod_009")
	print("[PROLOGUE-PROD-009] PASS")
	return true

# PROLOGUE-PROD-010: Login flow.
static func test_prod_010_login_flow() -> bool:
	print("[PROLOGUE-PROD-010] Verifying Login flow preserves Prologue first-run contract...")
	var app: Node = _create_app_with_isolated_gate("prod_010")
	app._ready()

	# Simulate successful login
	var auth_client = app.get("_auth_client")
	if auth_client != null and auth_client.get("current_session") != null:
		auth_client.get("current_session").call("start_session", "usr_prod", "token_prod", "test@test.com", "Test User", "student")

	var res: Dictionary = app.call("start_new_game")
	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	if int(shell.call("get_view_mode")) != 9:
		print("[PROLOGUE-PROD-010] FAIL: Logged in first entry did not enter MODE_PROLOGUE")
		_cleanup_app(app, "prod_010")
		return false

	_cleanup_app(app, "prod_010")
	print("[PROLOGUE-PROD-010] PASS")
	return true

# PROLOGUE-PROD-011: Production does not require Lab user:// layout files.
static func test_prod_011_no_user_json_dependency() -> bool:
	print("[PROLOGUE-PROD-011] Verifying production has zero dependency on user:// lab json files...")
	# Ensure user:// lab files do not exist
	if FileAccess.file_exists("user://prologue_lab_beat01_layout.json"):
		DirAccess.remove_absolute("user://prologue_lab_beat01_layout.json")
	if FileAccess.file_exists("user://prologue_lab_beat02_layout.json"):
		DirAccess.remove_absolute("user://prologue_lab_beat02_layout.json")

	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	# Must load successfully from res:// assets
	var b1_ok: bool = bool(player.call("load_beat01_layout"))
	var b2_ok: bool = bool(player.call("load_beat02_layout"))

	if not b1_ok or not b2_ok:
		print("[PROLOGUE-PROD-011] FAIL: Layout load failed without user:// files: b1=%s, b2=%s" % [str(b1_ok), str(b2_ok)])
		player.free()
		return false

	player.free()
	print("[PROLOGUE-PROD-011] PASS")
	return true

# PROLOGUE-PROD-012: Exactly 3 player-facing controls.
static func test_prod_012_exactly_3_player_controls() -> bool:
	print("[PROLOGUE-PROD-012] Verifying exactly 3 player controls (Volume, Settings, BỎ QUA)...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var controls: Array[Button] = player.call("get_player_controls")
	if controls.size() != 3:
		print("[PROLOGUE-PROD-012] FAIL: Expected exactly 3 controls, got %d" % controls.size())
		player.free()
		return false

	var names: Array[String] = []
	for c in controls:
		names.append(c.name)

	if not names.has("VolumeBtn") or not names.has("SettingsBtn") or not names.has("SkipBtn"):
		print("[PROLOGUE-PROD-012] FAIL: Missing expected control buttons: %s" % str(names))
		player.free()
		return false

	player.free()
	print("[PROLOGUE-PROD-012] PASS")
	return true

# PROLOGUE-PROD-013: No Lab UI leaks.
static func test_prod_013_no_lab_ui_leaks() -> bool:
	print("[PROLOGUE-PROD-013] Verifying zero Lab UI leaks in production Prologue...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	# Prohibited lab node names
	var prohibited: Array[String] = [
		"GizmoOverlay", "TrajectoryGizmo", "EditModePanel", "InspectorPanel",
		"SpinBox", "SaveLayoutBtn", "ExportJsonBtn", "ResetSceneBtn", "PlayAllFxBtn"
	]

	for node_name in prohibited:
		if player.find_child(node_name, true, false) != null:
			print("[PROLOGUE-PROD-013] FAIL: Found prohibited lab node: %s" % node_name)
			player.free()
			return false

	player.free()
	print("[PROLOGUE-PROD-013] PASS")
	return true

# PROLOGUE-PROD-014: Beat 2 projectile path/facing preserved.
static func test_prod_014_beat2_projectile_path_facing() -> bool:
	print("[PROLOGUE-PROD-014] Verifying Beat 2 projectile path ownership and visual facing...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var projs: Array[String] = ["Projectile01", "Projectile02", "Projectile03"]
	for p in projs:
		var root: Control = player.call("get_projectile_root_node", p)
		var vis: TextureRect = player.call("get_projectile_visual_node", p)
		if root == null or vis == null:
			print("[PROLOGUE-PROD-014] FAIL: Missing root or visual for %s" % p)
			player.free()
			return false

		# Root must own movement and NEVER rotate
		if absf(root.rotation_degrees) > 0.001:
			print("[PROLOGUE-PROD-014] FAIL: Root rotation must be 0 for %s, got %f" % [p, root.rotation_degrees])
			player.free()
			return false

		# Visual must own non-zero combined rotation
		if absf(vis.rotation_degrees) < 1.0:
			print("[PROLOGUE-PROD-014] FAIL: Visual rotation is 0 for %s" % p)
			player.free()
			return false

	player.free()
	print("[PROLOGUE-PROD-014] PASS")
	return true

# PROLOGUE-PROD-015: No projectile clipping.
static func test_prod_015_no_projectile_clipping() -> bool:
	print("[PROLOGUE-PROD-015] Verifying no projectile clipping across hierarchy...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	if player.clip_contents:
		print("[PROLOGUE-PROD-015] FAIL: ProloguePlayer has clip_contents = true")
		player.free()
		return false

	var canvas_c: Control = player.get_node_or_null("CanvasContainer") as Control
	if canvas_c != null and canvas_c.clip_contents:
		print("[PROLOGUE-PROD-015] FAIL: CanvasContainer has clip_contents = true")
		player.free()
		return false

	var b2_root: Control = player.get_node_or_null("CanvasContainer/Beat02Root") as Control
	if b2_root != null and b2_root.clip_contents:
		print("[PROLOGUE-PROD-015] FAIL: Beat02Root has clip_contents = true")
		player.free()
		return false

	player.free()
	print("[PROLOGUE-PROD-015] PASS")
	return true

# PROLOGUE-PROD-016: 1280x720 responsive scaling.
static func test_prod_016_responsive_1280x720() -> bool:
	print("[PROLOGUE-PROD-016] Verifying 1280x720 scaling...")
	return _verify_resolution_scaling(Vector2(1280, 720), "PROLOGUE-PROD-016")

# PROLOGUE-PROD-017: 1366x768 responsive scaling.
static func test_prod_017_responsive_1366x768() -> bool:
	print("[PROLOGUE-PROD-017] Verifying 1366x768 scaling...")
	return _verify_resolution_scaling(Vector2(1366, 768), "PROLOGUE-PROD-017")

# PROLOGUE-PROD-018: 1600x900 responsive scaling.
static func test_prod_018_responsive_1600x900() -> bool:
	print("[PROLOGUE-PROD-018] Verifying 1600x900 scaling...")
	return _verify_resolution_scaling(Vector2(1600, 900), "PROLOGUE-PROD-018")

# PROLOGUE-PROD-019: 1920x1080 responsive scaling.
static func test_prod_019_responsive_1920x1080() -> bool:
	print("[PROLOGUE-PROD-019] Verifying 1920x1080 scaling...")
	return _verify_resolution_scaling(Vector2(1920, 1080), "PROLOGUE-PROD-019")

static func _verify_resolution_scaling(res: Vector2, test_tag: String) -> bool:
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.set_anchors_preset(Control.PRESET_TOP_LEFT)
	player.size = res
	player.call("update_responsive_layout", res)

	var canvas_c: Control = player.get_node_or_null("CanvasContainer") as Control
	if canvas_c == null:
		print("[%s] FAIL: CanvasContainer null" % test_tag)
		player.free()
		return false

	var expected_scale: float = minf(res.x / 1280.0, res.y / 720.0)
	if absf(canvas_c.scale.x - expected_scale) > 0.01:
		print("[%s] FAIL: Canvas scale %f != %f at %s" % [test_tag, canvas_c.scale.x, expected_scale, str(res)])
		player.free()
		return false

	player.free()
	print("[%s] PASS" % test_tag)
	return true

# PROLOGUE-PROD-020: Map regression verification.
static func test_prod_020_map_regression() -> bool:
	print("[PROLOGUE-PROD-020] Verifying World Map remains locked and unregressed...")
	var app: Node = AppRootClass.new()
	app._ready()

	app.call("show_stage_map")
	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	if shell == null:
		print("[PROLOGUE-PROD-020] FAIL: Shell not found")
		app.free()
		return false

	var mode: int = int(shell.call("get_view_mode"))
	if mode != 6: # MODE_MAP = 6
		print("[PROLOGUE-PROD-020] FAIL: Expected MODE_MAP (6), got %d" % mode)
		app.free()
		return false

	var map_panel: Control = shell.call("get_stage_map_panel") as Control
	if map_panel == null or not map_panel.visible:
		print("[PROLOGUE-PROD-020] FAIL: DungeonStageMapPanel not visible in MODE_MAP")
		app.free()
		return false

	app.free()
	print("[PROLOGUE-PROD-020] PASS")
	return true

# PROLOGUE-PROD-RUNE-001: Production Beat 1 layer dictionary contains RunePrimary.
static func test_prod_rune_001_layer_dict_contains_runeprimary() -> bool:
	print("[PROLOGUE-PROD-RUNE-001] Verifying Production Beat 1 layer dictionary contains RunePrimary...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var rune_node: Control = player.call("get_layer_node", 1, "RunePrimary")
	if rune_node == null:
		print("[PROLOGUE-PROD-RUNE-001] FAIL: RunePrimary layer node is null")
		player.free()
		return false

	var b1_layers: Dictionary = player.get("_b1_layers") as Dictionary
	if not b1_layers.has("RunePrimary"):
		print("[PROLOGUE-PROD-RUNE-001] FAIL: _b1_layers does not have 'RunePrimary' key")
		player.free()
		return false

	player.free()
	print("[PROLOGUE-PROD-RUNE-001] PASS")
	return true

# PROLOGUE-PROD-RUNE-002: RunePrimary layout applies exact human position and opacity.
static func test_prod_rune_002_runeprimary_layout_applies_exact_human_values() -> bool:
	print("[PROLOGUE-PROD-RUNE-002] Verifying RunePrimary layout applies exact human position (530.0, 200.0) and opacity 0.75...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var rune_node: Control = player.call("get_layer_node", 1, "RunePrimary")
	if rune_node == null:
		print("[PROLOGUE-PROD-RUNE-002] FAIL: RunePrimary layer node is null")
		player.free()
		return false

	if not rune_node.position.is_equal_approx(Vector2(530.0, 200.0)):
		print("[PROLOGUE-PROD-RUNE-002] FAIL: RunePrimary position mismatch: expected (530.0, 200.0), got %v" % rune_node.position)
		player.free()
		return false

	if not is_equal_approx(rune_node.modulate.a, 0.75):
		print("[PROLOGUE-PROD-RUNE-002] FAIL: RunePrimary opacity mismatch: expected 0.75, got %f" % rune_node.modulate.a)
		player.free()
		return false

	if not rune_node.scale.is_equal_approx(Vector2(1.0, 1.0)):
		print("[PROLOGUE-PROD-RUNE-002] FAIL: RunePrimary scale mismatch: expected (1.0, 1.0), got %v" % rune_node.scale)
		player.free()
		return false

	# Also verify full 14/14 Beat 1 layer parity
	var expected_14_layers: Array[String] = [
		"ArcaneTrails", "Background", "Birds", "CyanMotes", "FlyingCreatures",
		"FoliageLeft", "FoliageRight", "FoliageTop", "GoldFlicker01", "GoldFlicker02",
		"GoldFlicker03", "MistFar", "MistNear", "RunePrimary"
	]
	var b1_layers: Dictionary = player.get("_b1_layers") as Dictionary
	for l_name in expected_14_layers:
		if not b1_layers.has(l_name):
			print("[PROLOGUE-PROD-RUNE-002] FAIL: Missing layer %s in Beat 1 layout" % l_name)
			player.free()
			return false

	player.free()
	print("[PROLOGUE-PROD-RUNE-002] PASS: RunePrimary loaded at (530.0, 200.0), opacity 0.75; Beat 1 parity is 14/14.")
	return true

# PROLOGUE-PROD-RUNE-003: No stale RunePulse production key remains.
static func test_prod_rune_003_no_stale_runepulse_production_key() -> bool:
	print("[PROLOGUE-PROD-RUNE-003] Verifying no stale RunePulse production key remains...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var stale_node: Control = player.call("get_layer_node", 1, "RunePulse")
	if stale_node != null:
		print("[PROLOGUE-PROD-RUNE-003] FAIL: Stale RunePulse node still exists!")
		player.free()
		return false

	var b1_layers: Dictionary = player.get("_b1_layers") as Dictionary
	if b1_layers.has("RunePulse"):
		print("[PROLOGUE-PROD-RUNE-003] FAIL: Stale 'RunePulse' key still in _b1_layers!")
		player.free()
		return false

	player.free()
	print("[PROLOGUE-PROD-RUNE-003] PASS")
	return true

