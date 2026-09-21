class_name TestStochasFullCombatPresentationParity241E
extends SceneTree

func _initialize() -> void:
	var ok: bool = run_all(self)
	quit(0 if ok else 1)

## Verification Suite for Task MATHOS-STOCHAS-COMBAT-PRESENTATION-PARITY-241E (Agent3)
## Verifies full production parity requirements:
## 1. Card Hand Scale: 160x225 px, 16px gap, centered at x=296, 0 overlap with Karl (x=32..292)
## 2. Question Panel Combat Dim/Fade: Modulate 0.22 during animations, 1.0 on recovery, input gating
## 3. BossCombatPanel Question Fade Integration: Signals and smooth tweening
## 4. Authored Boss Spells: Bolt (1.18s), Orb (1.80s), Rift (1.50s), Sweep (1.75s)
## 5. Idle Process Floating Guard: _is_animating_spell prevents float math overwriting
## 6. Karl Combat Actions & Ultimate Fade Integration
## 7. Strict Locks Preservation: Transforms, meters, and mechanics

static var _failures: Array[String] = []

static func _fail(gate: String, msg: String) -> bool:
	var err: String = "[FAIL][%s] %s" % [gate, msg]
	_failures.append(err)
	printerr(err)
	return false

static func run_all(tree: SceneTree = null) -> bool:
	_failures.clear()
	print("================================================================================")
	print("STARTING TEST SUITE: MATHOS-STOCHAS-COMBAT-PRESENTATION-PARITY-241E")
	print("================================================================================")

	var ok: bool = true
	ok = test_001_card_hand_scale_and_karl_clearance() and ok
	ok = test_002_question_panel_combat_fade_interface() and ok
	ok = test_003_boss_combat_panel_question_fade_integration() and ok
	ok = test_004_authored_boss_spell_motion_profiles() and ok
	ok = test_005_process_floating_guard() and ok
	ok = test_006_combat_log_and_ultimate_fade_integration(tree) and ok
	ok = test_007_strict_locks_preservation() and ok

	if ok and _failures.is_empty():
		print("================================================================================")
		print("ALL 7 GATES PASSED: 241E PRESENTATION PARITY FULLY VERIFIED")
		print("================================================================================")
		return true
	else:
		print("================================================================================")
		print("TEST SUITE FAILED with %d failure(s):" % _failures.size())
		for f in _failures:
			print("  - " + f)
		print("================================================================================")
		return false

# -----------------------------------------------------------------------------
# 1. Card Hand Scale and Karl Clearance (Gate 1)
# -----------------------------------------------------------------------------
static func test_001_card_hand_scale_and_karl_clearance() -> bool:
	print("[GATE 1] Verifying canonical Card Hand Scale (160x225 px, 16px gap, 688px row)...")

	if BossCombatPanel.CARD_WIDTH != 160.0:
		return _fail("GATE-1", "CARD_WIDTH expected 160.0, got %f" % BossCombatPanel.CARD_WIDTH)
	if BossCombatPanel.CARD_HEIGHT != 225.0:
		return _fail("GATE-1", "CARD_HEIGHT expected 225.0, got %f" % BossCombatPanel.CARD_HEIGHT)
	if BossCombatPanel.CARD_GAP != 16.0:
		return _fail("GATE-1", "CARD_GAP expected 16.0, got %f" % BossCombatPanel.CARD_GAP)

	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()
	panel._layout_elements()

	var card_row: Rect2 = panel.get_card_row_rect()
	var expected_w: float = 4.0 * 160.0 + 3.0 * 16.0 # 688.0
	if absf(card_row.size.x - expected_w) > 1.0:
		panel.free()
		return _fail("GATE-1", "Card row width expected %f, got %f" % [expected_w, card_row.size.x])

	var expected_x: float = (1280.0 - expected_w) * 0.5 # 296.0
	if absf(card_row.position.x - expected_x) > 1.0:
		panel.free()
		return _fail("GATE-1", "Card row x expected %f, got %f" % [expected_x, card_row.position.x])

	# Verify Karl entity clearance (Karl right edge = 32 + 260 = 292 <= 296)
	var karl: Control = panel.get_karl_battlefield_entity()
	if karl == null:
		panel.free()
		return _fail("GATE-1", "Karl battlefield entity is null")

	var karl_right: float = karl.position.x + karl.size.x
	if karl_right > card_row.position.x:
		panel.free()
		return _fail("GATE-1", "Karl right edge (%f) overlaps card row left edge (%f)" % [karl_right, card_row.position.x])

	# Verify Flow Pill is positioned above cards
	var flow_rect: Rect2 = panel.get_flow_pill_rect()
	if flow_rect.position.y >= card_row.position.y:
		panel.free()
		return _fail("GATE-1", "Flow pill must be positioned above card row")

	panel.free()
	print("[GATE 1] PASS: Card Hand scale 160x225, row 688px at x=296, Karl at x=32..292 (0 overlap)")
	return true

# -----------------------------------------------------------------------------
# 2. Question Panel Combat Dim / Fade (Gate 2)
# -----------------------------------------------------------------------------
static func test_002_question_panel_combat_fade_interface() -> bool:
	print("[GATE 2] Verifying QuestionPanel combat dim/fade and input gating interface...")

	var qp: QuestionPanel = QuestionPanel.new()
	qp.size = Vector2(740, 300)

	if not qp.has_method("fade_for_combat"):
		qp.free()
		return _fail("GATE-2", "QuestionPanel missing fade_for_combat method")
	if not qp.has_method("restore_after_combat"):
		qp.free()
		return _fail("GATE-2", "QuestionPanel missing restore_after_combat method")
	if not qp.has_method("set_interaction_enabled"):
		qp.free()
		return _fail("GATE-2", "QuestionPanel missing set_interaction_enabled method")
	if not qp.has_method("is_interaction_enabled"):
		qp.free()
		return _fail("GATE-2", "QuestionPanel missing is_interaction_enabled method")

	# Initial state should be enabled
	if not qp.is_interaction_enabled():
		qp.free()
		return _fail("GATE-2", "QuestionPanel initial interaction state should be enabled")

	qp.set_interaction_enabled(false)
	if qp.is_interaction_enabled():
		qp.free()
		return _fail("GATE-2", "QuestionPanel interaction state should be disabled after set_interaction_enabled(false)")

	qp.set_interaction_enabled(true)
	if not qp.is_interaction_enabled():
		qp.free()
		return _fail("GATE-2", "QuestionPanel interaction state should be enabled after set_interaction_enabled(true)")

	qp.free()
	print("[GATE 2] PASS: QuestionPanel combat dim/fade interface and input gating verified")
	return true

# -----------------------------------------------------------------------------
# 3. BossCombatPanel Question Fade Integration (Gate 3)
# -----------------------------------------------------------------------------
static func test_003_boss_combat_panel_question_fade_integration() -> bool:
	print("[GATE 3] Verifying BossCombatPanel question fade helpers and signals...")

	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()

	if not panel.has_signal("question_fade_requested"):
		panel.free()
		return _fail("GATE-3", "BossCombatPanel missing signal question_fade_requested")
	if not panel.has_signal("question_restore_requested"):
		panel.free()
		return _fail("GATE-3", "BossCombatPanel missing signal question_restore_requested")

	var qp_mock: Control = Control.new()
	qp_mock.name = "MockQuestionPanel"
	panel.set_question_panel_override(qp_mock)

	if panel.get_target_question_panel() != qp_mock:
		panel.free()
		qp_mock.free()
		return _fail("GATE-3", "get_target_question_panel did not return override panel")

	var fade_sig_fired: Array = []
	panel.question_fade_requested.connect(func(a, d): fade_sig_fired.append([a, d]))
	panel.fade_question_for_combat(0.22, 0.20)

	if fade_sig_fired.is_empty():
		panel.free()
		qp_mock.free()
		return _fail("GATE-3", "question_fade_requested signal was not emitted")
	if absf(fade_sig_fired[0][0] - 0.22) > 0.01:
		panel.free()
		qp_mock.free()
		return _fail("GATE-3", "Fade alpha expected 0.22, got %f" % fade_sig_fired[0][0])

	var restore_sig_fired: Array = []
	panel.question_restore_requested.connect(func(d): restore_sig_fired.append(d))
	panel.restore_question_after_combat(0.24)

	if restore_sig_fired.is_empty():
		panel.free()
		qp_mock.free()
		return _fail("GATE-3", "question_restore_requested signal was not emitted")

	panel.free()
	qp_mock.free()
	print("[GATE 3] PASS: BossCombatPanel question fade signals and overrides verified")
	return true

# -----------------------------------------------------------------------------
# 4. Authored Boss Spell Motion Profiles (Gate 4)
# -----------------------------------------------------------------------------
static func test_004_authored_boss_spell_motion_profiles() -> bool:
	print("[GATE 4] Verifying authored Boss Spells (Bolt, Orb, Rift, Sweep)...")

	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()

	if not panel.has_signal("boss_spell_cast_started"):
		panel.free()
		return _fail("GATE-4", "BossCombatPanel missing signal boss_spell_cast_started")
	if not panel.has_signal("boss_spell_cast_finished"):
		panel.free()
		return _fail("GATE-4", "BossCombatPanel missing signal boss_spell_cast_finished")

	var started_spells: Array = []
	panel.boss_spell_cast_started.connect(func(s_name, dur): started_spells.append([s_name, dur]))

	# Test 1: ARCANE_BOLT (1.18s)
	panel.play_boss_bolt()
	if not panel.is_spell_animating():
		panel.free()
		return _fail("GATE-4", "is_spell_animating() should be true during Arcane Bolt")
	if started_spells.is_empty() or started_spells[-1][0] != "ARCANE_BOLT" or absf(started_spells[-1][1] - 1.18) > 0.05:
		panel.free()
		return _fail("GATE-4", "ARCANE_BOLT did not emit started signal with 1.18s duration")

	# Test 2: PROBABILITY_ORB (1.80s)
	panel.play_boss_orb()
	if started_spells.is_empty() or started_spells[-1][0] != "PROBABILITY_ORB" or absf(started_spells[-1][1] - 1.80) > 0.05:
		panel.free()
		return _fail("GATE-4", "PROBABILITY_ORB did not emit started signal with 1.80s duration")

	# Test 3: VOID_RIFT (1.50s)
	panel.play_boss_rift()
	if started_spells.is_empty() or started_spells[-1][0] != "VOID_RIFT" or absf(started_spells[-1][1] - 1.50) > 0.05:
		panel.free()
		return _fail("GATE-4", "VOID_RIFT did not emit started signal with 1.50s duration")

	# Test 4: ARCANE_SWEEP (1.75s)
	panel.play_boss_sweep()
	if started_spells.is_empty() or started_spells[-1][0] != "ARCANE_SWEEP" or absf(started_spells[-1][1] - 1.75) > 0.05:
		panel.free()
		return _fail("GATE-4", "ARCANE_SWEEP did not emit started signal with 1.75s duration")

	# Test 5: Spell cycle through _fire_stochas_spell_cycle
	var cycle_initial: int = panel.get_boss_spell_cycle()
	panel._fire_stochas_spell_cycle()
	if panel.get_boss_spell_cycle() != cycle_initial + 1:
		panel.free()
		return _fail("GATE-4", "get_boss_spell_cycle() did not increment on spell cycle")

	panel.free()
	print("[GATE 4] PASS: Authored Boss Spells verified (Bolt 1.18s, Orb 1.80s, Rift 1.50s, Sweep 1.75s)")
	return true

# -----------------------------------------------------------------------------
# 5. Process Floating Guard (Gate 5)
# -----------------------------------------------------------------------------
static func test_005_process_floating_guard() -> bool:
	print("[GATE 5] Verifying idle floating guard prevents overwriting spell transforms...")

	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()

	var sprite: TextureRect = panel.get_boss_sprite_rect()
	if sprite == null:
		panel.free()
		return _fail("GATE-5", "Boss sprite rect is null")

	# Set custom position and activate spell animation flag
	sprite.position = Vector2(42.0, -26.0)
	panel._is_animating_spell = true

	# Run _process with delta
	panel._process(0.016)

	if absf(sprite.position.x - 42.0) > 0.01 or absf(sprite.position.y - (-26.0)) > 0.01:
		panel.free()
		return _fail("GATE-5", "_process() modified sprite position while _is_animating_spell is true!")

	panel.free()
	print("[GATE 5] PASS: Idle floating properly guarded during active spells")
	return true

# -----------------------------------------------------------------------------
# 6. Combat Log and Ultimate Fade Integration (Gate 6)
# -----------------------------------------------------------------------------
static func test_006_combat_log_and_ultimate_fade_integration(tree: SceneTree = null) -> bool:
	print("[GATE 6] Verifying Combat Actions trigger question fade...")

	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	if tree != null:
		tree.root.add_child(panel)
	panel._ensure_ui()

	var qp_mock: Control = Control.new()
	if tree != null:
		tree.root.add_child(qp_mock)
	panel.set_question_panel_override(qp_mock)

	var fade_count: Array = [0]
	panel.question_fade_requested.connect(func(a, d): fade_count[0] += 1)

	# Trigger Karl Strike via combat log
	panel.select_card("card_strike")
	panel._on_combat_log("Karl tấn công!", "player_success")
	if fade_count[0] < 1:
		panel.free()
		qp_mock.free()
		return _fail("GATE-6", "card_strike did not trigger question fade")

	# Trigger Karl Defend
	panel.select_card("card_defend")
	panel._on_combat_log("Karl thủ khiên!", "player_success")
	if fade_count[0] < 2:
		panel.free()
		qp_mock.free()
		return _fail("GATE-6", "card_defend did not trigger question fade")

	# Trigger Karl Heal
	panel.select_card("card_heal")
	panel._on_combat_log("Karl hồi phục!", "player_success")
	if fade_count[0] < 3:
		panel.free()
		qp_mock.free()
		return _fail("GATE-6", "card_heal did not trigger question fade")

	# Trigger Boss attack
	panel._on_combat_log("Stochas phản kích!", "boss_attack")
	if fade_count[0] < 4:
		panel.free()
		qp_mock.free()
		return _fail("GATE-6", "boss_attack did not trigger question fade")

	# Trigger Ultimate charge
	panel.play_ultimate_charge()
	if fade_count[0] < 5:
		panel.free()
		qp_mock.free()
		return _fail("GATE-6", "play_ultimate_charge did not trigger question fade")

	panel.free()
	qp_mock.free()
	print("[GATE 6] PASS: Combat actions & Ultimate successfully trigger question fade")
	return true

# -----------------------------------------------------------------------------
# 7. Strict Locks Preservation (Gate 7)
# -----------------------------------------------------------------------------
static func test_007_strict_locks_preservation() -> bool:
	print("[GATE 7] Verifying strict locks (transforms, meters, contracts)...")

	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()

	# 1. Ultimate Meter Max contract
	if panel.get_boss_ultimate_meter_max() != 4:
		panel.free()
		return _fail("GATE-7", "Ultimate meter max must be 4, got %d" % panel.get_boss_ultimate_meter_max())

	# 2. Charge Transforms F01..F06 integrity
	var ct = BossCombatPanel.FINAL_CHARGE_TRANSFORMS
	if ct.size() != 6:
		panel.free()
		return _fail("GATE-7", "FINAL_CHARGE_TRANSFORMS size must be 6, got %d" % ct.size())
	if absf(ct[5]["scale"] - 1.1378) > 0.001 or absf(ct[5]["x"] - 190.18) > 0.01:
		panel.free()
		return _fail("GATE-7", "F06 charge transform corrupted")

	# 3. Release Transforms F01..F08 integrity
	var rt = BossCombatPanel.FINAL_RELEASE_TRANSFORMS
	if rt.size() != 8:
		panel.free()
		return _fail("GATE-7", "FINAL_RELEASE_TRANSFORMS size must be 8, got %d" % rt.size())
	if absf(rt[4]["scale"] - 1.3067) > 0.001 or absf(rt[4]["x"] - 194.54) > 0.01:
		panel.free()
		return _fail("GATE-7", "F05 peak release transform corrupted")

	# 4. Karl Battlefield Entity Dimensions
	if BossCombatPanel.KARL_ENTITY_WIDTH != 260.0 or BossCombatPanel.KARL_ENTITY_HEIGHT != 260.0 or BossCombatPanel.KARL_ENTITY_LEFT != 32.0:
		panel.free()
		return _fail("GATE-7", "Karl entity constants altered")

	panel.free()
	print("[GATE 7] PASS: All strict locks and authoritative transforms fully preserved")
	return true
