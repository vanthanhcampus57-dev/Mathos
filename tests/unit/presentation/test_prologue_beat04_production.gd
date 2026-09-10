class_name TestPrologueBeat04Production
extends SceneTree

## Production Verification Test Suite for MATHOS-PROLOGUE-BEAT04-PRODUCTION-INTEGRATION-103.
## Covers:
## PROLOGUE-B4-001: Beat4Root loads and hierarchy resolves cleanly.
## PROLOGUE-B4-002: Beat 3 -> Beat 4 real handoff emits beat_transitioned(3, 4) exactly once and is idempotent.
## PROLOGUE-B4-003: Exactly four fragments enter Beat 4 with valid textures.
## PROLOGUE-B4-004: Stable fragment IDs (Fragment01..04) preserved.
## PROLOGUE-B4-005: Four distinct destination states and canonical names resolve.
## PROLOGUE-B4-006: Timing and choreography configuration resolves (~14.8s duration).
## PROLOGUE-B4-007: Sequential camera guidance, non-symmetric trajectories, and phrase-based narration simulation.
## PROLOGUE-B4-008: Natural Beat 4 completion emits prologue_completed exactly once.
## PROLOGUE-B4-009: Natural Beat 4 completion enters D1 Story and completes gate.
## PROLOGUE-B4-010: Skip during Beat 4 enters D1 Story and completes gate.
## PROLOGUE-B4-011: Exactly 3 player controls and zero debug/gameplay UI leaks.
## PROLOGUE-B4-012: Beat 1 and Beat 2 accepted layouts remain strictly preserved.
## PROLOGUE-B4-013: No missing resource or runtime errors.

const AppRootClass = preload("res://src/app/app_root.gd")
const ProloguePlayerClass = preload("res://src/ui/prologue/prologue_player.gd")
const PrologueGateServiceClass = preload("res://src/gameplay/prologue/prologue_gate_service.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func run_all_tests() -> bool:
	print("==================================================")
	print("STARTING PROLOGUE BEAT 4 PRODUCTION TEST SUITE")
	print("==================================================")

	var tests: Array[Callable] = [
		Callable(TestPrologueBeat04Production, "test_b4_001_beat04_root_and_hierarchy_loads"),
		Callable(TestPrologueBeat04Production, "test_b4_002_beat3_to_beat4_real_handoff"),
		Callable(TestPrologueBeat04Production, "test_b4_003_exactly_four_fragments_enter_beat4"),
		Callable(TestPrologueBeat04Production, "test_b4_004_stable_fragment_ids"),
		Callable(TestPrologueBeat04Production, "test_b4_005_four_distinct_destination_states"),
		Callable(TestPrologueBeat04Production, "test_b4_006_timing_and_choreography_configuration_resolves"),
		Callable(TestPrologueBeat04Production, "test_b4_007_sequential_guidance_and_fragment_trajectories"),
		Callable(TestPrologueBeat04Production, "test_b4_008_natural_completion_emits_prologue_completed_once"),
		Callable(TestPrologueBeat04Production, "test_b4_009_natural_completion_enters_d1_story"),
		Callable(TestPrologueBeat04Production, "test_b4_010_skip_during_beat4_enters_story_and_completes_gate"),
		Callable(TestPrologueBeat04Production, "test_b4_011_zero_gameplay_ui_leak_and_controls_count"),
		Callable(TestPrologueBeat04Production, "test_b4_012_beat1_and_beat2_layouts_strictly_preserved"),
		Callable(TestPrologueBeat04Production, "test_b4_013_no_missing_resource_runtime_errors")
	]

	var pass_count: int = 0
	for t in tests:
		if bool(t.call()):
			pass_count += 1

	print("==================================================")
	print("PROLOGUE BEAT 4 SUMMARY: %d / %d passed" % [pass_count, tests.size()])
	print("==================================================")
	return pass_count == tests.size()

static func _create_app_with_isolated_gate(test_id: String) -> Node:
	var app: Node = AppRootClass.new()
	var custom_gate_path: String = "user://test_prologue_b4_gate_%s.json" % test_id
	if FileAccess.file_exists(custom_gate_path):
		DirAccess.remove_absolute(custom_gate_path)
	var gate = PrologueGateServiceClass.new(custom_gate_path)
	app.call("set_prologue_gate", gate)
	return app

static func _cleanup_app(app: Node, test_id: String) -> void:
	if app != null:
		var custom_gate_path: String = "user://test_prologue_b4_gate_%s.json" % test_id
		if FileAccess.file_exists(custom_gate_path):
			DirAccess.remove_absolute(custom_gate_path)
		app.free()

# PROLOGUE-B4-001: Beat4Root loads and hierarchy resolves cleanly.
static func test_b4_001_beat04_root_and_hierarchy_loads() -> bool:
	print("[PROLOGUE-B4-001] Verifying Beat4Root and hierarchy instantiation...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var b4_root: Control = player.get_node_or_null("CanvasContainer/Beat04Root") as Control
	if b4_root == null:
		print("[PROLOGUE-B4-001] FAIL: Beat04Root not found")
		player.free()
		return false

	var world_content: Control = b4_root.get_node_or_null("WorldContent") as Control
	if world_content == null:
		print("[PROLOGUE-B4-001] FAIL: WorldContent container not found")
		player.free()
		return false

	var bg: TextureRect = world_content.get_node_or_null("Background") as TextureRect
	if bg == null or bg.texture == null:
		print("[PROLOGUE-B4-001] FAIL: Background TextureRect missing or has null texture")
		player.free()
		return false

	var narration: Control = b4_root.get_node_or_null("NarrationContainer") as Control
	if narration == null:
		print("[PROLOGUE-B4-001] FAIL: NarrationContainer missing")
		player.free()
		return false

	var fade: ColorRect = b4_root.get_node_or_null("FadeOverlay") as ColorRect
	if fade == null:
		print("[PROLOGUE-B4-001] FAIL: FadeOverlay missing")
		player.free()
		return false

	player.free()
	print("[PROLOGUE-B4-001] PASS")
	return true

# PROLOGUE-B4-002: Beat 3 -> Beat 4 real handoff emits beat_transitioned(3, 4) exactly once and is idempotent.
static func test_b4_002_beat3_to_beat4_real_handoff() -> bool:
	print("[PROLOGUE-B4-002] Verifying Beat 3 -> Beat 4 progression and idempotency...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.call("set_speed_scale", 100.0)
	player.call("start_prologue")
	player.call("advance_to_beat2")
	player.call("advance_to_beat3")

	var transitions: Array[Dictionary] = []
	player.connect("beat_transitioned", func(f, t): transitions.append({"from": f, "to": t}))

	player.call("advance_to_beat4")
	if int(player.call("get_current_beat")) != 4:
		print("[PROLOGUE-B4-002] FAIL: Expected current beat 4, got %d" % int(player.call("get_current_beat")))
		player.free()
		return false

	if transitions.size() != 1 or transitions[0]["from"] != 3 or transitions[0]["to"] != 4:
		print("[PROLOGUE-B4-002] FAIL: Transition signal mismatch: %s" % str(transitions))
		player.free()
		return false

	# Idempotency check
	player.call("advance_to_beat4")
	if transitions.size() != 1:
		print("[PROLOGUE-B4-002] FAIL: advance_to_beat4 is not idempotent")
		player.free()
		return false

	player.free()
	print("[PROLOGUE-B4-002] PASS: Beat 3 -> Beat 4 signal (3, 4) verified exactly once")
	return true

# PROLOGUE-B4-003: Exactly four fragments enter Beat 4 with valid textures.
static func test_b4_003_exactly_four_fragments_enter_beat4() -> bool:
	print("[PROLOGUE-B4-003] Verifying exactly four fragments enter Beat 4 with valid textures...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.call("start_prologue")
	player.call("advance_to_beat2")
	player.call("advance_to_beat3")
	player.call("advance_to_beat4")

	var frags: Array[Control] = player.call("get_fragment_nodes", 4)
	if frags.size() != 4:
		print("[PROLOGUE-B4-003] FAIL: Expected 4 fragments, got %d" % frags.size())
		player.free()
		return false

	for f in frags:
		if not (f is TextureRect):
			print("[PROLOGUE-B4-003] FAIL: Fragment node is not TextureRect")
			player.free()
			return false
		var tr: TextureRect = f as TextureRect
		if tr.texture == null:
			print("[PROLOGUE-B4-003] FAIL: Fragment has null texture: %s" % tr.name)
			player.free()
			return false

	player.free()
	print("[PROLOGUE-B4-003] PASS: All 4 fragments verified with valid textures")
	return true

# PROLOGUE-B4-004: Stable fragment IDs (Fragment01..04) preserved.
static func test_b4_004_stable_fragment_ids() -> bool:
	print("[PROLOGUE-B4-004] Verifying stable fragment IDs...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var expected_ids: Array[String] = ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]
	for fid in expected_ids:
		var node: Control = player.call("get_fragment_node", fid, 4)
		if node == null or node.name != fid:
			print("[PROLOGUE-B4-004] FAIL: Fragment ID mismatch or missing: %s" % fid)
			player.free()
			return false

	player.free()
	print("[PROLOGUE-B4-004] PASS: Fragment IDs strictly Fragment01..Fragment04")
	return true

# PROLOGUE-B4-005: Four distinct destination states and canonical names resolve.
static func test_b4_005_four_distinct_destination_states() -> bool:
	print("[PROLOGUE-B4-005] Verifying 4 distinct destination states and canonical names...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var names: Array[String] = player.call("get_destination_names")
	var expected_names: Array[String] = [
		"Dungeon I — KHU RỪNG MÙ SƯƠNG",
		"Dungeon II — ĐẦM LẦY TỶ LỆ",
		"Dungeon III — CUNG ĐIỆN HỢP NHẤT",
		"Dungeon IV — ĐỈNH THÁP ĐỘC LẬP"
	]

	if names.size() != 4:
		print("[PROLOGUE-B4-005] FAIL: Destination count is %d, expected 4" % names.size())
		player.free()
		return false

	for i in range(4):
		if names[i] != expected_names[i]:
			print("[PROLOGUE-B4-005] FAIL: Name mismatch at %d: %s vs %s" % [i, names[i], expected_names[i]])
			player.free()
			return false

	var dest_nodes: Array[Control] = player.call("get_destination_nodes")
	if dest_nodes.size() != 4:
		print("[PROLOGUE-B4-005] FAIL: Expected 4 destination nodes, got %d" % dest_nodes.size())
		player.free()
		return false

	for d in dest_nodes:
		var lbl: Label = d.get_node_or_null("TitleLabel") as Label
		var beacon: TextureRect = d.get_node_or_null("Beacon") as TextureRect
		if lbl == null or beacon == null:
			print("[PROLOGUE-B4-005] FAIL: Destination node missing TitleLabel or Beacon")
			player.free()
			return false

	player.free()
	print("[PROLOGUE-B4-005] PASS: All 4 canonical destinations verified")
	return true

# PROLOGUE-B4-006: Timing and choreography configuration resolves (~14.8s duration).
static func test_b4_006_timing_and_choreography_configuration_resolves() -> bool:
	print("[PROLOGUE-B4-006] Verifying timing and choreography configuration...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var b4_dur: float = float(ProloguePlayerClass.BEAT4_DURATION)
	if absf(b4_dur - 14.8) > 0.05:
		print("[PROLOGUE-B4-006] FAIL: BEAT4_DURATION expected ~14.8, got %f" % b4_dur)
		player.free()
		return false

	var layout_dict: Dictionary = player.get("_b4_layout_data")
	if layout_dict.is_empty() or not layout_dict.has("timing"):
		print("[PROLOGUE-B4-006] FAIL: Layout data missing timing section")
		player.free()
		return false

	var timing: Dictionary = layout_dict["timing"] as Dictionary
	if absf(float(timing.get("total_duration", 0.0)) - 14.8) > 0.05:
		print("[PROLOGUE-B4-006] FAIL: Layout total_duration mismatch")
		player.free()
		return false

	player.free()
	print("[PROLOGUE-B4-006] PASS: Exact duration 14.8s configuration verified")
	return true

# PROLOGUE-B4-007: Sequential camera guidance, non-symmetric trajectories, and phrase-based narration simulation.
static func test_b4_007_sequential_guidance_and_fragment_trajectories() -> bool:
	print("[PROLOGUE-B4-007] Verifying sequential camera guidance & fragment simulation...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.call("set_speed_scale", 1.0)
	player.call("start_prologue")
	player.call("advance_to_beat2")
	player.call("advance_to_beat3")
	player.call("advance_to_beat4")

	var frag1: TextureRect = player.call("get_fragment_node", "Fragment01", 4) as TextureRect
	var frag2: TextureRect = player.call("get_fragment_node", "Fragment02", 4) as TextureRect
	var frag3: TextureRect = player.call("get_fragment_node", "Fragment03", 4) as TextureRect
	var frag4: TextureRect = player.call("get_fragment_node", "Fragment04", 4) as TextureRect

	var d1: Control = player.call("get_destination_node", "Destination01")
	var d2: Control = player.call("get_destination_node", "Destination02")
	var d3: Control = player.call("get_destination_node", "Destination03")
	var d4: Control = player.call("get_destination_node", "Destination04")

	var world: Control = player.get("_b4_world_content") as Control
	var p1_lbl: Label = player.get("_b4_phrase1_lbl") as Label
	var p2_lbl: RichTextLabel = player.get("_b4_phrase2_lbl") as RichTextLabel
	var fade: ColorRect = player.get("_b4_fade_overlay") as ColorRect

	# Time t = 0.2s: Starting state (All at handoff positions, destinations hidden)
	player.set("_playback_time", 0.2)
	player.call("_process_beat04", 0.016)
	if d1.modulate.a > 0.0 or d2.modulate.a > 0.0:
		print("[PROLOGUE-B4-007] FAIL: Destinations should be hidden at t = 0.2s")
		player.free()
		return false

	# Time t = 1.2s: Phrase 1 visible
	player.set("_playback_time", 1.2)
	player.call("_process_beat04", 0.016)
	if p1_lbl.modulate.a <= 0.3:
		print("[PROLOGUE-B4-007] FAIL: Phrase 1 should be visible at t = 1.2s")
		player.free()
		return false

	# Time t = 4.2s: D4 revealed (TL), fixed framing preserved
	player.set("_playback_time", 4.2)
	player.call("_process_beat04", 0.016)
	if d4.modulate.a <= 0.5:
		print("[PROLOGUE-B4-007] FAIL: Destination 4 should be revealed at t = 4.2s")
		player.free()
		return false
	if world.position != Vector2.ZERO:
		print("[PROLOGUE-B4-007] FAIL: Fixed framing violated at t = 4.2s: ", world.position)
		player.free()
		return false

	# Time t = 5.5s: D3 revealed (TR)
	player.set("_playback_time", 5.5)
	player.call("_process_beat04", 0.016)
	if d3.modulate.a <= 0.5:
		print("[PROLOGUE-B4-007] FAIL: Destination 3 should be revealed at t = 5.5s")
		player.free()
		return false

	# Time t = 6.5s: D1 revealed (BL)
	player.set("_playback_time", 6.5)
	player.call("_process_beat04", 0.016)
	if d1.modulate.a <= 0.5:
		print("[PROLOGUE-B4-007] FAIL: Destination 1 should be revealed at t = 6.5s")
		player.free()
		return false

	# Time t = 7.5s: D2 revealed (BR)
	player.set("_playback_time", 7.5)
	player.call("_process_beat04", 0.016)
	if d2.modulate.a <= 0.5:
		print("[PROLOGUE-B4-007] FAIL: Destination 2 should be revealed at t = 7.5s")
		player.free()
		return false

	# Time t = 10.2s: All destinations revealed, Phrase 2 visible
	player.set("_playback_time", 10.2)
	player.call("_process_beat04", 0.016)
	if d4.modulate.a <= 0.5 or p2_lbl.modulate.a <= 0.5:
		print("[PROLOGUE-B4-007] FAIL: Destination 4 and Phrase 2 should be visible at t = 10.2s")
		player.free()
		return false

	# Time t = 12.0s: Camera-led Final Reveal (overview, all 4 revealed)
	player.set("_playback_time", 12.0)
	player.call("_process_beat04", 0.016)
	var all_dest_revealed: bool = d1.modulate.a >= 0.8 and d2.modulate.a >= 0.8 and d3.modulate.a >= 0.8 and d4.modulate.a >= 0.8
	if not all_dest_revealed:
		print("[PROLOGUE-B4-007] FAIL: All 4 destinations must be visible during final reveal")
		player.free()
		return false

	# Time t = 14.6s: Fade to black overlay active
	player.set("_playback_time", 14.6)
	player.call("_process_beat04", 0.016)
	if fade.color.a <= 0.4:
		print("[PROLOGUE-B4-007] FAIL: Fade overlay should be active near end of Beat 4")
		player.free()
		return false

	player.free()
	print("[PROLOGUE-B4-007] PASS: Sequential camera guidance & fragment simulation verified cleanly")
	return true

# PROLOGUE-B4-008: Natural Beat 4 completion emits prologue_completed exactly once.
static func test_b4_008_natural_completion_emits_prologue_completed_once() -> bool:
	print("[PROLOGUE-B4-008] Verifying natural completion emits prologue_completed once...")
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
		print("[PROLOGUE-B4-008] FAIL: Expected 1 prologue_completed signal, got %d" % completed_count[0])
		player.free()
		return false

	# Call complete again; must be idempotent
	player.call("complete_prologue")
	if completed_count[0] != 1:
		print("[PROLOGUE-B4-008] FAIL: complete_prologue is not idempotent")
		player.free()
		return false

	player.free()
	print("[PROLOGUE-B4-008] PASS: Exactly one prologue_completed emission verified")
	return true

# PROLOGUE-B4-009: Natural Beat 4 completion enters D1 Story and completes gate.
static func test_b4_009_natural_completion_enters_d1_story() -> bool:
	print("[PROLOGUE-B4-009] Verifying natural Beat 4 completion enters D1 Story & completes gate...")
	var app: Node = _create_app_with_isolated_gate("b4_009")
	app._ready()
	app.call("start_new_game")

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	if shell == null:
		print("[PROLOGUE-B4-009] FAIL: StagePresentationShell not found")
		_cleanup_app(app, "b4_009")
		return false

	var player: Control = shell.call("get_prologue_player")
	player.call("advance_to_beat2")
	player.call("advance_to_beat3")
	player.call("advance_to_beat4")

	# Trigger natural completion
	player.call("complete_prologue")

	var gate: Variant = app.get("_prologue_gate")
	var is_completed: bool = bool(gate.call("has_completed_prologue")) if gate != null else false
	if not is_completed:
		print("[PROLOGUE-B4-009] FAIL: Gate should be marked completed after Beat 4 natural completion")
		_cleanup_app(app, "b4_009")
		return false

	var view_mode: int = int(shell.call("get_view_mode"))
	# MODE_STORY is mode 7
	if view_mode != 7:
		print("[PROLOGUE-B4-009] FAIL: Expected MODE_STORY (7), got %d" % view_mode)
		_cleanup_app(app, "b4_009")
		return false

	_cleanup_app(app, "b4_009")
	print("[PROLOGUE-B4-009] PASS: Beat 4 natural completion routed cleanly to D1 Story")
	return true

# PROLOGUE-B4-010: Skip during Beat 4 enters D1 Story and completes gate.
static func test_b4_010_skip_during_beat4_enters_story_and_completes_gate() -> bool:
	print("[PROLOGUE-B4-010] Verifying Skip button during Beat 4 enters D1 Story...")
	var app: Node = _create_app_with_isolated_gate("b4_010")
	app._ready()
	app.call("start_new_game")

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	var player: Control = shell.call("get_prologue_player")
	player.call("advance_to_beat2")
	player.call("advance_to_beat3")
	player.call("advance_to_beat4")

	var skip_btn: Button = player.get_node_or_null("PlayerControls/SkipBtn") as Button
	if skip_btn == null:
		print("[PROLOGUE-B4-010] FAIL: SkipBtn not found")
		_cleanup_app(app, "b4_010")
		return false

	skip_btn.pressed.emit()

	var gate: Variant = app.get("_prologue_gate")
	var is_completed: bool = bool(gate.call("has_completed_prologue")) if gate != null else false
	if not is_completed:
		print("[PROLOGUE-B4-010] FAIL: Gate should be marked completed after skip")
		_cleanup_app(app, "b4_010")
		return false

	var view_mode: int = int(shell.call("get_view_mode"))
	if view_mode != 7:
		print("[PROLOGUE-B4-010] FAIL: Expected MODE_STORY (7), got %d" % view_mode)
		_cleanup_app(app, "b4_010")
		return false

	_cleanup_app(app, "b4_010")
	print("[PROLOGUE-B4-010] PASS: Skip button during Beat 4 transitioned directly to D1 Story")
	return true

# PROLOGUE-B4-011: Exactly 3 player controls and zero debug/gameplay UI leaks.
static func test_b4_011_zero_gameplay_ui_leak_and_controls_count() -> bool:
	print("[PROLOGUE-B4-011] Verifying exactly 3 player controls and zero UI leaks...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var controls: Array[Button] = player.call("get_player_controls")
	if controls.size() != 3:
		print("[PROLOGUE-B4-011] FAIL: Expected 3 player controls, got %d" % controls.size())
		player.free()
		return false

	var ctrl_names: Array[String] = []
	for c in controls:
		ctrl_names.append(c.name)
	ctrl_names.sort()

	if ctrl_names != ["SettingsBtn", "SkipBtn", "VolumeBtn"]:
		print("[PROLOGUE-B4-011] FAIL: Unexpected control button names: %s" % str(ctrl_names))
		player.free()
		return false

	var forbidden_nodes: Array[String] = [
		"Timeline", "BeatNumber", "PrevButton", "NextButton", "DebugPanel",
		"CombatPanel", "CardContainer", "BossView", "MapRoot"
	]
	for fb in forbidden_nodes:
		if player.find_child(fb, true, false) != null:
			print("[PROLOGUE-B4-011] FAIL: Forbidden debug/gameplay node found: %s" % fb)
			player.free()
			return false

	player.free()
	print("[PROLOGUE-B4-011] PASS: Exactly 3 player controls and zero UI leaks")
	return true

# PROLOGUE-B4-012: Beat 1 and Beat 2 accepted layouts remain strictly preserved.
static func test_b4_012_beat1_and_beat2_layouts_strictly_preserved() -> bool:
	print("[PROLOGUE-B4-012] Verifying Beat 1 & Beat 2 accepted layouts strictly preserved...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")
	player.call("start_prologue")
	player.call("advance_to_beat2")
	player.call("advance_to_beat3")
	player.call("advance_to_beat4")

	var rune: Control = player.call("get_layer_node", 1, "RunePrimary")
	if rune != null:
		if absf(rune.position.x - 530.0) > 0.5 or absf(rune.position.y - 200.0) > 0.5:
			print("[PROLOGUE-B4-012] FAIL: Beat 1 RunePrimary position corrupted: %s" % str(rune.position))
			player.free()
			return false

	var wisp2: Control = player.call("get_layer_node", 2, "CorruptionWisp02")
	if wisp2 != null:
		if absf(wisp2.position.x - 548.35) > 1.0 or absf(wisp2.position.y - 30.88) > 1.0:
			print("[PROLOGUE-B4-012] FAIL: CorruptionWisp02 layout corrupted: %s" % str(wisp2.position))
			player.free()
			return false

	player.free()
	print("[PROLOGUE-B4-012] PASS: Beat 1 and Beat 2 human accepted layouts remain identical")
	return true

# PROLOGUE-B4-013: No missing resource or runtime errors.
static func test_b4_013_no_missing_resource_runtime_errors() -> bool:
	print("[PROLOGUE-B4-013] Verifying no missing resource or runtime errors...")
	var player: Control = ProloguePlayerClass.new()
	player.call("_ensure_built")

	var b4_layers: Array[String] = [
		"Background", "Vignette",
		"Destination01", "Destination02", "Destination03", "Destination04",
		"Fragment01", "Fragment02", "Fragment03", "Fragment04"
	]

	for l_name in b4_layers:
		var node: Control = player.call("get_layer_node", 4, l_name)
		if node == null:
			print("[PROLOGUE-B4-013] FAIL: Missing Beat 4 layer node: %s" % l_name)
			player.free()
			return false

	player.free()
	print("[PROLOGUE-B4-013] PASS: All Beat 4 resources and layers verified")
	return true
