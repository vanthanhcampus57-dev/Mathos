class_name TestPrologueBeat03Production
extends SceneTree

## Production Verification Test Suite for MATHOS-PROLOGUE-BEAT03-BEAT04-HANDOFF-HOTFIX-095.
## Covers:
## PROLOGUE-B3-001: Beat 3 & Beat 4 subtree instantiation and initial hierarchy state.
## PROLOGUE-B3-002: All 9 canonical source assets resolve and load cleanly.
## PROLOGUE-B3-003: Authoritative Beat 3 layout JSON applies exact transform values.
## PROLOGUE-B3-004: Exactly 4 fragment nodes exist with stable IDs (Fragment01..04).
## PROLOGUE-B3-005: Beat 2 -> Beat 3 transition emits beat_transitioned(2, 3) exactly once.
## PROLOGUE-B3-006: Beat 2 human layout is strictly preserved during and after transition to Beat 3.
## PROLOGUE-B3-007: 5-Phase choreography simulation (Intact -> Corruption -> Crack -> Burst -> 4 Fragments).
## PROLOGUE-B3-008: Beat 3 natural completion advances to Beat 4, emitting beat_transitioned(3, 4), NOT emitting prologue_completed(), NOT entering D1 Story, and preserving fragment handoff.
## PROLOGUE-B3-009: Skip from Beat 3 routes directly to D1 Story.
## PROLOGUE-B3-010: Exactly 3 player controls and zero debug/Lab UI leaks.

const AppRootClass = preload("res://src/app/app_root.gd")
const ProloguePlayerClass = preload("res://src/ui/prologue/prologue_player.gd")
const PrologueGateServiceClass = preload("res://src/gameplay/prologue/prologue_gate_service.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func run_all_tests() -> bool:
	print("==================================================")
	print("STARTING PROLOGUE BEAT 3 PRODUCTION TEST SUITE")
	print("==================================================")

	var tests: Array[Callable] = [
		Callable(TestPrologueBeat03Production, "test_b3_001_beat3_structure_instantiation"),
		Callable(TestPrologueBeat03Production, "test_b3_002_all_source_assets_loaded"),
		Callable(TestPrologueBeat03Production, "test_b3_003_layout_applies_exact_values"),
		Callable(TestPrologueBeat03Production, "test_b3_004_four_fragment_stable_ids"),
		Callable(TestPrologueBeat03Production, "test_b3_005_beat2_to_beat3_progression"),
		Callable(TestPrologueBeat03Production, "test_b3_006_beat2_layout_preserved_on_transition"),
		Callable(TestPrologueBeat03Production, "test_b3_007_five_phase_choreography_simulation"),
		Callable(TestPrologueBeat03Production, "test_b3_008_beat3_natural_completion_advances_to_beat4"),
		Callable(TestPrologueBeat03Production, "test_b3_009_skip_from_beat3_to_d1_story"),
		Callable(TestPrologueBeat03Production, "test_b3_010_zero_gameplay_ui_leaks_and_controls")
	]

	var pass_count: int = 0
	for t in tests:
		if bool(t.call()):
			pass_count += 1

	print("==================================================")
	print("PROLOGUE BEAT 3 SUMMARY: %d / %d passed" % [pass_count, tests.size()])
	print("==================================================")
	return pass_count == tests.size()

static func _create_app_with_isolated_gate(test_id: String) -> Node:
	var app: Node = AppRootClass.new()
	var custom_gate_path: String = "user://test_prologue_b3_gate_%s.json" % test_id
	if FileAccess.file_exists(custom_gate_path):
		DirAccess.remove_absolute(custom_gate_path)
	var gate = PrologueGateServiceClass.new(custom_gate_path)
	app.call("set_prologue_gate", gate)
	return app

static func _cleanup_app(app: Node, test_id: String) -> void:
	if app != null:
		var custom_gate_path: String = "user://test_prologue_b3_gate_%s.json" % test_id
		if FileAccess.file_exists(custom_gate_path):
			DirAccess.remove_absolute(custom_gate_path)
		app.free()

# PROLOGUE-B3-001: Beat 3 & Beat 4 subtree instantiation and initial hierarchy state.
static func test_b3_001_beat3_structure_instantiation() -> bool:
	print("[PROLOGUE-B3-001] Verifying Beat 3 & Beat 4 root node instantiation...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var b3_root: Control = player.get_node_or_null("CanvasContainer/Beat03Root") as Control
	if b3_root == null:
		print("[PROLOGUE-B3-001] FAIL: Beat03Root not found in CanvasContainer")
		player.free()
		return false

	var b4_root: Control = player.get_node_or_null("CanvasContainer/Beat04Root") as Control
	if b4_root == null:
		print("[PROLOGUE-B3-001] FAIL: Beat04Root not found in CanvasContainer")
		player.free()
		return false

	if b3_root.size != Vector2(1280, 720) or b4_root.size != Vector2(1280, 720):
		print("[PROLOGUE-B3-001] FAIL: Root size mismatch")
		player.free()
		return false

	if b3_root.visible != false or b3_root.modulate.a != 0.0:
		print("[PROLOGUE-B3-001] FAIL: Beat03Root should be initially hidden with modulate.a = 0.0")
		player.free()
		return false

	player.free()
	print("[PROLOGUE-B3-001] PASS")
	return true

# PROLOGUE-B3-002: All 9 canonical source assets resolve and load cleanly.
static func test_b3_002_all_source_assets_loaded() -> bool:
	print("[PROLOGUE-B3-002] Verifying all 9 canonical source assets resolve and load...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var expected_layers: Array[String] = [
		"Background", "Vignette",
		"OrderStoneIntact", "OrderStoneCorruption", "OrderStoneCracked",
		"OrderStoneEnergyBurst", "OrderStoneDebris",
		"Fragment01", "Fragment02", "Fragment03", "Fragment04"
	]

	for l_name in expected_layers:
		var node: Control = player.call("get_layer_node", 3, l_name)
		if node == null:
			print("[PROLOGUE-B3-002] FAIL: Beat 3 layer node missing: %s" % l_name)
			player.free()
			return false

		if node is TextureRect:
			var tr: TextureRect = node as TextureRect
			if tr.texture == null:
				print("[PROLOGUE-B3-002] FAIL: TextureRect has null texture for layer: %s" % l_name)
				player.free()
				return false

	player.free()
	print("[PROLOGUE-B3-002] PASS: All 9 source textures + background/vignette loaded cleanly")
	return true

# PROLOGUE-B3-003: Authoritative Beat 3 layout JSON applies exact transform values.
static func test_b3_003_layout_applies_exact_values() -> bool:
	print("[PROLOGUE-B3-003] Verifying Beat 3 layout JSON applies exact transforms...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var intact: Control = player.call("get_layer_node", 3, "OrderStoneIntact")
	if intact == null:
		print("[PROLOGUE-B3-003] FAIL: OrderStoneIntact not found")
		player.free()
		return false

	if absf(intact.position.x - 13.0) > 0.1 or absf(intact.position.y - (-267.0)) > 0.1:
		print("[PROLOGUE-B3-003] FAIL: OrderStoneIntact position mismatch: %s" % str(intact.position))
		player.free()
		return false

	if absf(intact.scale.x - 0.52) > 0.01 or absf(intact.scale.y - 0.52) > 0.01:
		print("[PROLOGUE-B3-003] FAIL: OrderStoneIntact scale mismatch: %s" % str(intact.scale))
		player.free()
		return false

	player.free()
	print("[PROLOGUE-B3-003] PASS: Exact layout position (13.0, -267.0) and scale (0.52, 0.52) verified")
	return true

# PROLOGUE-B3-004: Exactly 4 fragment nodes exist with stable IDs (Fragment01..04).
static func test_b3_004_four_fragment_stable_ids() -> bool:
	print("[PROLOGUE-B3-004] Verifying exactly 4 fragment nodes with stable IDs...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var frag_ids: Array[String] = ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]
	for fid in frag_ids:
		var node: Control = player.call("get_fragment_node", fid)
		if node == null:
			print("[PROLOGUE-B3-004] FAIL: get_fragment_node returned null for %s" % fid)
			player.free()
			return false
		if node.name != fid:
			print("[PROLOGUE-B3-004] FAIL: Fragment node name mismatch: %s vs %s" % [node.name, fid])
			player.free()
			return false

	var all_frags: Array[Control] = player.call("get_fragment_nodes")
	if all_frags.size() != 4:
		print("[PROLOGUE-B3-004] FAIL: get_fragment_nodes returned %d items, expected 4" % all_frags.size())
		player.free()
		return false

	player.free()
	print("[PROLOGUE-B3-004] PASS: Exactly 4 fragment nodes verified with stable IDs")
	return true

# PROLOGUE-B3-005: Beat 2 -> Beat 3 transition emits beat_transitioned(2, 3) exactly once.
static func test_b3_005_beat2_to_beat3_progression() -> bool:
	print("[PROLOGUE-B3-005] Verifying Beat 2 -> Beat 3 progression and idempotency...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.call("set_speed_scale", 100.0)
	player.call("start_prologue")
	player.call("advance_to_beat2")

	var transitions: Array[Dictionary] = []
	player.connect("beat_transitioned", func(f, t): transitions.append({"from": f, "to": t}))

	player.call("advance_to_beat3")
	if int(player.call("get_current_beat")) != 3:
		print("[PROLOGUE-B3-005] FAIL: Expected current beat 3, got %d" % int(player.call("get_current_beat")))
		player.free()
		return false

	if transitions.size() != 1 or transitions[0]["from"] != 2 or transitions[0]["to"] != 3:
		print("[PROLOGUE-B3-005] FAIL: Transition signal mismatch: %s" % str(transitions))
		player.free()
		return false

	# Second call must be idempotent
	player.call("advance_to_beat3")
	if transitions.size() != 1:
		print("[PROLOGUE-B3-005] FAIL: advance_to_beat3 is not idempotent, got %d signals" % transitions.size())
		player.free()
		return false

	player.free()
	print("[PROLOGUE-B3-005] PASS: Beat 2 -> Beat 3 transition signal (2, 3) verified exactly once")
	return true

# PROLOGUE-B3-006: Beat 2 human layout is strictly preserved during and after transition to Beat 3.
static func test_b3_006_beat2_layout_preserved_on_transition() -> bool:
	print("[PROLOGUE-B3-006] Verifying Beat 2 human layout preserved during Beat 3 advance...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.call("set_speed_scale", 100.0)
	player.call("start_prologue")
	player.call("advance_to_beat2")

	var wisp2: Control = player.call("get_layer_node", 2, "CorruptionWisp02")
	var p01: Control = player.call("get_projectile_root_node", "Projectile01")

	player.call("advance_to_beat3")

	if absf(wisp2.position.x - 548.35) > 1.0 or absf(wisp2.position.y - 30.88) > 1.0:
		print("[PROLOGUE-B3-006] FAIL: CorruptionWisp02 layout corrupted: %s" % str(wisp2.position))
		player.free()
		return false

	if absf(p01.position.x - 954.79) > 1.0:
		print("[PROLOGUE-B3-006] FAIL: Projectile01 root layout corrupted: %s" % str(p01.position))
		player.free()
		return false

	player.free()
	print("[PROLOGUE-B3-006] PASS: Beat 2 human layout values remain strictly intact")
	return true

# PROLOGUE-B3-007: 5-Phase choreography simulation (Intact -> Corruption -> Crack -> Burst -> 4 Fragments).
static func test_b3_007_five_phase_choreography_simulation() -> bool:
	print("[PROLOGUE-B3-007] Verifying 5-phase choreography simulation...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.call("set_speed_scale", 1.0) # Real-time simulation
	player.call("start_prologue")
	player.call("advance_to_beat2")
	player.call("advance_to_beat3")

	var intact: TextureRect = player.call("get_layer_node", 3, "OrderStoneIntact") as TextureRect
	var corrupt: TextureRect = player.call("get_layer_node", 3, "OrderStoneCorruption") as TextureRect
	var cracked: TextureRect = player.call("get_layer_node", 3, "OrderStoneCracked") as TextureRect
	var burst: TextureRect = player.call("get_layer_node", 3, "OrderStoneEnergyBurst") as TextureRect
	var frag1: TextureRect = player.call("get_fragment_node", "Fragment01") as TextureRect
	var frag2: TextureRect = player.call("get_fragment_node", "Fragment02") as TextureRect
	var frag3: TextureRect = player.call("get_fragment_node", "Fragment03") as TextureRect
	var frag4: TextureRect = player.call("get_fragment_node", "Fragment04") as TextureRect

	# Phase 1: t = 0.5s (INTACT)
	player.set("_playback_time", 0.5)
	player.call("_process_beat03", 0.016)
	if not intact.visible or corrupt.visible or cracked.visible or frag1.visible:
		print("[PROLOGUE-B3-007] FAIL: Phase 1 state invalid (Intact should be only visible stone)")
		player.free()
		return false

	# Phase 2: t = 2.2s (CORRUPTION)
	player.set("_playback_time", 2.2)
	player.call("_process_beat03", 0.016)
	if not corrupt.visible or corrupt.modulate.a <= 0.1:
		print("[PROLOGUE-B3-007] FAIL: Phase 2 corruption should be visible with positive alpha")
		player.free()
		return false

	# Phase 3: t = 3.8s (CRACK)
	player.set("_playback_time", 3.8)
	player.call("_process_beat03", 0.016)
	if not cracked.visible or cracked.modulate.a <= 0.5:
		print("[PROLOGUE-B3-007] FAIL: Phase 3 cracked stone should be dominant")
		player.free()
		return false

	# Phase 4: t = 4.6s (BURST)
	player.set("_playback_time", 4.6)
	player.call("_process_beat03", 0.016)
	if not burst.visible or burst.modulate.a <= 0.5:
		print("[PROLOGUE-B3-007] FAIL: Phase 4 burst FX should be visible with high alpha")
		player.free()
		return false

	# Phase 5: t = 6.5s (FOUR FRAGMENTS)
	player.set("_playback_time", 6.5)
	player.call("_process_beat03", 0.016)
	var all_frags_visible: bool = frag1.visible and frag2.visible and frag3.visible and frag4.visible
	if not all_frags_visible:
		print("[PROLOGUE-B3-007] FAIL: Phase 5 all 4 fragments must be visible")
		player.free()
		return false

	var base_pos: Vector2 = Vector2(13.0, -267.0)
	if not (frag1.position.x < base_pos.x and frag1.position.y < base_pos.y):
		print("[PROLOGUE-B3-007] FAIL: Fragment01 not in NW quadrant: %s" % str(frag1.position))
		player.free()
		return false
	if not (frag2.position.x > base_pos.x and frag2.position.y < base_pos.y):
		print("[PROLOGUE-B3-007] FAIL: Fragment02 not in NE quadrant: %s" % str(frag2.position))
		player.free()
		return false
	if not (frag3.position.x < base_pos.x and frag3.position.y > base_pos.y):
		print("[PROLOGUE-B3-007] FAIL: Fragment03 not in SW quadrant: %s" % str(frag3.position))
		player.free()
		return false
	if not (frag4.position.x > base_pos.x and frag4.position.y > base_pos.y):
		print("[PROLOGUE-B3-007] FAIL: Fragment04 not in SE quadrant: %s" % str(frag4.position))
		player.free()
		return false

	player.free()
	print("[PROLOGUE-B3-007] PASS: All 5 phases (Intact, Corruption, Crack, Burst, 4 Fragments) verified cleanly")
	return true

# PROLOGUE-B3-008: Beat 3 natural completion advances to Beat 4, emitting beat_transitioned(3, 4), NOT emitting prologue_completed(), NOT entering D1 Story, and preserving fragment handoff.
static func test_b3_008_beat3_natural_completion_advances_to_beat4() -> bool:
	print("[PROLOGUE-B3-008] Verifying Beat 3 natural completion advances to Beat 4 without premature Story entry...")
	var app: Node = _create_app_with_isolated_gate("b3_008")
	app._ready()
	app.call("start_new_game")

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	if shell == null:
		print("[PROLOGUE-B3-008] FAIL: StagePresentationShell not found")
		_cleanup_app(app, "b3_008")
		return false

	var player: Control = shell.call("get_prologue_player")
	player.call("advance_to_beat2")
	player.call("advance_to_beat3")

	var transitions: Array[Dictionary] = []
	var completed_emitted: Array[bool] = [false]

	player.connect("beat_transitioned", func(f, t): transitions.append({"from": f, "to": t}))
	player.connect("prologue_completed", func(): completed_emitted[0] = true)

	# Simulate time reaching Beat 3 completion
	player.set("_speed_scale", 100.0)
	player.set("_playback_time", 7.1)
	player.call("_process", 0.016)

	# 1. Verify current beat is Beat 4
	if int(player.call("get_current_beat")) != 4:
		print("[PROLOGUE-B3-008] FAIL: Expected active beat 4 after Beat 3 natural completion, got %d" % int(player.call("get_current_beat")))
		_cleanup_app(app, "b3_008")
		return false

	# 2. Verify beat_transitioned(3, 4) emitted exactly once
	if transitions.size() != 1 or transitions[0]["from"] != 3 or transitions[0]["to"] != 4:
		print("[PROLOGUE-B3-008] FAIL: Expected beat_transitioned(3, 4) signal, got %s" % str(transitions))
		_cleanup_app(app, "b3_008")
		return false

	# 3. Verify prologue_completed() was NOT emitted
	if completed_emitted[0]:
		print("[PROLOGUE-B3-008] FAIL: prologue_completed() was prematurely emitted at Beat 3 exit!")
		_cleanup_app(app, "b3_008")
		return false

	# 4. Verify shell view mode remains MODE_PROLOGUE (9), NOT MODE_STORY (7)
	var view_mode: int = int(shell.call("get_view_mode"))
	if view_mode != 9:
		print("[PROLOGUE-B3-008] FAIL: Expected ViewMode.MODE_PROLOGUE (9), got %d" % view_mode)
		_cleanup_app(app, "b3_008")
		return false

	# 5. Verify all 4 fragment nodes remain available for Beat 4 handoff
	var frags: Array[Control] = player.call("get_fragment_nodes")
	if frags.size() != 4:
		print("[PROLOGUE-B3-008] FAIL: Expected 4 fragment nodes available at Beat 4 entry, got %d" % frags.size())
		_cleanup_app(app, "b3_008")
		return false

	# 6. Verify Beat 3 root is hidden / cleaned up after transition
	var b3_root: Control = player.get_node_or_null("CanvasContainer/Beat03Root") as Control
	if b3_root != null and b3_root.visible:
		print("[PROLOGUE-B3-008] FAIL: Beat03Root should be hidden after transition to Beat 4")
		_cleanup_app(app, "b3_008")
		return false

	_cleanup_app(app, "b3_008")
	print("[PROLOGUE-B3-008] PASS: Beat 3 -> Beat 4 transition verified, zero premature Story routing, fragment handoff intact")
	return true

# PROLOGUE-B3-009: Skip from Beat 3 routes directly to D1 Story.
static func test_b3_009_skip_from_beat3_to_d1_story() -> bool:
	print("[PROLOGUE-B3-009] Verifying Skip from Beat 3 routes directly to D1 Story...")
	var app: Node = _create_app_with_isolated_gate("b3_009")
	app._ready()
	app.call("start_new_game")

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	var player: Control = shell.call("get_prologue_player")
	player.call("advance_to_beat2")
	player.call("advance_to_beat3")

	var controls: Array[Button] = player.call("get_player_controls")
	var skip_btn: Button = null
	for b in controls:
		if b.name == "SkipBtn":
			skip_btn = b
			break

	if skip_btn == null:
		print("[PROLOGUE-B3-009] FAIL: SkipBtn not found")
		_cleanup_app(app, "b3_009")
		return false

	skip_btn.emit_signal("pressed")

	var view_mode: int = int(shell.call("get_view_mode"))
	if view_mode != 7:
		print("[PROLOGUE-B3-009] FAIL: Expected MODE_STORY (7), got %d" % view_mode)
		_cleanup_app(app, "b3_009")
		return false

	if player.visible:
		print("[PROLOGUE-B3-009] FAIL: ProloguePlayer should be hidden after skip")
		_cleanup_app(app, "b3_009")
		return false

	_cleanup_app(app, "b3_009")
	print("[PROLOGUE-B3-009] PASS: Skip button from Beat 3 transitioned directly to D1 Story")
	return true

# PROLOGUE-B3-010: Exactly 3 player controls and zero debug/Lab UI leaks.
static func test_b3_010_zero_gameplay_ui_leaks_and_controls() -> bool:
	print("[PROLOGUE-B3-010] Verifying exactly 3 player controls and zero Lab leaks...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var controls: Array[Button] = player.call("get_player_controls")
	if controls.size() != 3:
		print("[PROLOGUE-B3-010] FAIL: Expected exactly 3 player controls, got %d" % controls.size())
		player.free()
		return false

	var c_names: Array[String] = []
	for b in controls:
		c_names.append(b.name)
	c_names.sort()

	var expected_c: Array[String] = ["SettingsBtn", "SkipBtn", "VolumeBtn"]
	if c_names != expected_c:
		print("[PROLOGUE-B3-010] FAIL: Player controls mismatch: %s" % str(c_names))
		player.free()
		return false

	var forbidden: Array[String] = ["Timeline", "Gizmo", "TransformInspector", "LayerList", "BeatNumber"]
	for f in forbidden:
		if player.find_child(f, true, false) != null:
			print("[PROLOGUE-B3-010] FAIL: Forbidden debug element found: %s" % f)
			player.free()
			return false

	player.free()
	print("[PROLOGUE-B3-010] PASS: Controls strictly 3, zero debug/Lab leaks")
	return true
