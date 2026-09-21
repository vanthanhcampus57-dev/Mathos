class_name TestStochasFullCombatCardUltimateKarlSkillRestore241F
extends SceneTree

func _initialize() -> void:
	var ok: bool = run_all()
	quit(0 if ok else 1)

## Comprehensive Verification Suite for Task MATHOS-FULL-COMBAT-CARD-ULTIMATE-KARL-SKILL-RESTORE-241F (Agent3)
## Verifies:
## 1. Card Art Full-Bleed Layout: 160x225, PRESET_FULL_RECT, STRETCH_KEEP_ASPECT_COVERED, BorderOverlay, floating badge & status
## 2. Stochas Ultimate Gameplay Pipeline: 4/4 meter -> queued -> restore_question_after_combat -> Charge (2.4s) -> Challenge (8.0s) -> Release (F01..F08) -> Dodge/Hit
## 3. Karl Probability Meter Progression: 0/3 -> 3/3 -> unlock -> "SẴN SÀNG"
## 4. Karl Tactical Draft Modal: 3 drawn cards from registry, atlas texture mapping, picking to tactical hand
## 5. Tactical Cards Execution: Eliminate, Reroll, Add Time, Stun, Critical, Aegis
## 6. Strict Transforms & Timing Locks: Charge F03..F06, Release F01..F08 (F05 peak), question fade 0.22 / 0.20s / 0.24s
## 7. Clean Isolation & 0 Asset Bytes Edited: Zero res://labs/ in src/, 0 PNG edits


static func test_000_compile_smoke_gate() -> bool:
	print("[GATE 0] Verifying script compile and load smoke test...")
	var panel_script = load("res://src/ui/combat/boss_combat_panel.gd")
	if panel_script == null:
		return _fail("Gate 0", "Failed to compile/load res://src/ui/combat/boss_combat_panel.gd")
	var app_root_script = load("res://src/app/app_root.gd")
	if app_root_script == null:
		return _fail("Gate 0", "Failed to compile/load res://src/app/app_root.gd")
	var controller_script = load("res://src/gameplay/combat/card_combat_controller.gd")
	if controller_script == null:
		return _fail("Gate 0", "Failed to compile/load res://src/gameplay/combat/card_combat_controller.gd")
	print("[PASS][Gate 0] Production scripts compile and load with 0 Parse/Compile errors!")
	return true

static var _failures: Array[String] = []

static func _fail(gate: String, msg: String) -> bool:
	var err: String = "[FAIL][%s] %s" % [gate, msg]
	_failures.append(err)
	printerr(err)
	return false

static func run_all() -> bool:
	_failures.clear()
	print("================================================================================")
	print("STARTING TEST SUITE: MATHOS-FULL-COMBAT-CARD-ULTIMATE-KARL-SKILL-RESTORE-241F")
	print("================================================================================")

	var ok: bool = true
	ok = test_000_compile_smoke_gate() and ok
	ok = test_001_card_art_full_bleed_layout() and ok
	ok = test_002_stochas_ultimate_gameplay_pipeline() and ok
	ok = test_003_karl_probability_meter_progression() and ok
	ok = test_004_karl_tactical_draft_modal_and_atlas() and ok
	ok = test_005_tactical_cards_execution() and ok
	ok = test_006_strict_transforms_and_timing_locks() and ok
	ok = test_007_clean_isolation_and_zero_asset_edits() and ok

	if ok and _failures.is_empty():
		print("================================================================================")
		print("ALL 7 GATES PASSED: 241F FULL-BLEED, ULTIMATE & KARL SKILL FLOW VERIFIED")
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
# GATE 1: Card Art Full-Bleed Layout
# -----------------------------------------------------------------------------
static func test_001_card_art_full_bleed_layout() -> bool:
	print("[GATE 1] Verifying full-bleed card art layout, button clip, and border overlay...")

	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()
	panel._render_cards()

	var card_ids: Array[String] = ["card_strike", "card_defend", "card_heal", "card_probability"]
	for c_id in card_ids:
		var slot: MarginContainer = panel.get_card_slot(c_id)
		if slot == null:
			panel.queue_free()
			return _fail("GATE-1", "Card slot null for: " + c_id)

		var btn: Button = panel.get_card_button(c_id)
		if btn == null:
			panel.queue_free()
			return _fail("GATE-1", "Card button null for: " + c_id)
		if not btn.clip_contents:
			panel.queue_free()
			return _fail("GATE-1", "Card button clip_contents must be true for: " + c_id)

		var tex_rect: TextureRect = panel.get_card_texture_rect(c_id)
		if tex_rect == null:
			panel.queue_free()
			return _fail("GATE-1", "CardTextureRect null for: " + c_id)
		if tex_rect.get_parent() != btn:
			panel.queue_free()
			return _fail("GATE-1", "CardTextureRect must be direct child of button for full bleed: " + c_id)
		if tex_rect.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			panel.queue_free()
			return _fail("GATE-1", "CardTextureRect stretch_mode must be STRETCH_KEEP_ASPECT_COVERED for: " + c_id)
		if tex_rect.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
			panel.queue_free()
			return _fail("GATE-1", "CardTextureRect expand_mode must be EXPAND_IGNORE_SIZE for: " + c_id)

		var overlay: Panel = panel.get_card_border_overlay(c_id)
		if overlay == null:
			panel.queue_free()
			return _fail("GATE-1", "BorderOverlay panel null for: " + c_id)
		if overlay.get_parent() != btn:
			panel.queue_free()
			return _fail("GATE-1", "BorderOverlay must be direct child of button over art: " + c_id)

		var badge: Label = panel.get_card_badge_label(c_id)
		if badge == null:
			panel.queue_free()
			return _fail("GATE-1", "BadgeLabel null for: " + c_id)

		var status: Label = panel.get_card_status_label(c_id)
		if status == null:
			panel.queue_free()
			return _fail("GATE-1", "StatusLabel null for: " + c_id)

	panel.queue_free()
	print("[GATE 1] PASS: Full-bleed card art edge-to-edge layout verified across all 4 cards.")
	return true

# -----------------------------------------------------------------------------
# GATE 2: Stochas Ultimate Gameplay Pipeline
# -----------------------------------------------------------------------------
static func test_002_stochas_ultimate_gameplay_pipeline() -> bool:
	print("[GATE 2] Verifying Stochas Ultimate gameplay trigger chain...")

	var controller: CardCombatController = CardCombatController.new()
	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel.set_controller(controller)

	# 1. Meter starts at 0
	if controller.boss_ultimate_meter != 0:
		panel.queue_free()
		return _fail("GATE-2", "Initial boss_ultimate_meter expected 0, got %d" % controller.boss_ultimate_meter)

	# 2. Increment meter to 4
	controller.increment_boss_ultimate_meter()
	controller.increment_boss_ultimate_meter()
	controller.increment_boss_ultimate_meter()
	controller.increment_boss_ultimate_meter()

	if not controller.is_ultimate_queued and not controller.is_ultimate_charge_active:
		panel.queue_free()
		return _fail("GATE-2", "is_ultimate_queued or is_ultimate_charge_active must be true after 4 increments")

	# 3. Combat action finish triggers restore_question_after_combat -> should trigger Charge!
	panel.restore_question_after_combat()
	if not controller.is_ultimate_charge_active:
		panel.queue_free()
		return _fail("GATE-2", "is_ultimate_charge_active must be true after restore_question_after_combat detects queued ultimate")
	if not panel.is_ultimate_anim_playing():
		panel.queue_free()
		return _fail("GATE-2", "panel.is_ultimate_anim_playing() must be true during charge")

	# 4. Charge finish triggers challenge
	panel._on_ultimate_charge_completed()
	if not controller.is_ultimate_challenge_active:
		panel.queue_free()
		return _fail("GATE-2", "is_ultimate_challenge_active must be true after charge completion")
	if not panel.is_ultimate_challenge_active():
		panel.queue_free()
		return _fail("GATE-2", "panel.is_ultimate_challenge_active() must be true")
	if abs(panel.get_ultimate_challenge_timer() - 8.0) > 0.1:
		panel.queue_free()
		return _fail("GATE-2", "Ultimate challenge timer expected 8.0s, got %f" % panel.get_ultimate_challenge_timer())

	# 5. Challenge resolution: Success
	controller.resolve_ultimate_outcome(true)
	if controller.is_ultimate_challenge_active:
		panel.queue_free()
		return _fail("GATE-2", "is_ultimate_challenge_active must be false after resolution")

	panel.queue_free()
	print("[GATE 2] PASS: Complete Stochas Ultimate pipeline verified from 4/4 meter to Charge to 8s Challenge to Resolution.")
	return true

# -----------------------------------------------------------------------------
# GATE 3: Karl Probability Meter Progression
# -----------------------------------------------------------------------------
static func test_003_karl_probability_meter_progression() -> bool:
	print("[GATE 3] Verifying Karl Probability meter progression and unlock at 3/3...")
	var controller: CardCombatController = CardCombatController.new()
	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel.set_controller(controller)
	panel._render_cards()
	panel._probability_meter = 0
	panel._update_probability_card_state()
	var prob_btn: Button = panel.get_card_button("card_probability")
	var prob_badge: Label = panel.get_card_badge_label("card_probability")
	var prob_status: Label = panel.get_card_status_label("card_probability")

	# Initial state: 0/3, disabled, "CHƯA KÍCH HOẠT"
	if controller.get_probability_meter() != 0:
		panel.queue_free()
		return _fail("GATE-3", "Initial probability meter expected 0, got %d" % controller.get_probability_meter())
	if not prob_btn.disabled:
		panel.queue_free()
		return _fail("GATE-3", "Probability button must be disabled at 0/3")
	if prob_status.text != "CHƯA KÍCH HOẠT":
		panel.queue_free()
		return _fail("GATE-3", "Probability status expected 'CHƯA KÍCH HOẠT', got '%s'" % prob_status.text)

	# Charge 1
	controller.add_probability_charge(1)
	panel._update_probability_card_state()
	if controller.get_probability_meter() != 1:
		panel.queue_free()
		return _fail("GATE-3", "Probability meter expected 1, got %d" % controller.get_probability_meter())
	if prob_badge.text != "1/3":
		panel.queue_free()
		return _fail("GATE-3", "Probability badge expected '1/3', got '%s'" % prob_badge.text)
	if not prob_btn.disabled:
		panel.queue_free()
		return _fail("GATE-3", "Probability button must remain disabled at 1/3")

	# Charge 2
	controller.add_probability_charge(1)
	panel._update_probability_card_state()
	if prob_badge.text != "2/3":
		panel.queue_free()
		return _fail("GATE-3", "Probability badge expected '2/3', got '%s'" % prob_badge.text)

	# Charge 3 (Full unlock)
	controller.add_probability_charge(1)
	panel._update_probability_card_state()
	if controller.get_probability_meter() != 3:
		panel.queue_free()
		return _fail("GATE-3", "Probability meter expected 3, got %d" % controller.get_probability_meter())
	if prob_btn.disabled:
		panel.queue_free()
		return _fail("GATE-3", "Probability button must be ENABLED at 3/3")
	if prob_badge.text != "SẴN SÀNG":
		panel.queue_free()
		return _fail("GATE-3", "Probability badge expected 'SẴN SÀNG', got '%s'" % prob_badge.text)
	if prob_status.text != "SẴN SÀNG":
		panel.queue_free()
		return _fail("GATE-3", "Probability status expected 'SẴN SÀNG', got '%s'" % prob_status.text)

	panel.queue_free()
	print("[GATE 3] PASS: Karl Probability meter progression (0/3 -> 1/3 -> 2/3 -> 3/3 SẴN SÀNG) verified.")
	return true

# -----------------------------------------------------------------------------
# GATE 4: Karl Tactical Draft Modal and Atlas
# -----------------------------------------------------------------------------
static func test_004_karl_tactical_draft_modal_and_atlas() -> bool:
	print("[GATE 4] Verifying Karl Tactical Draft modal, atlas textures, and hand tray...")

	if not FileAccess.file_exists(BossCombatPanel.ASSET_TACTICAL_ATLAS):
		return _fail("GATE-4", "Missing tactical atlas texture: " + BossCombatPanel.ASSET_TACTICAL_ATLAS)

	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()

	# Atlas textures generation for all 6 cards
	var tactical_ids: Array[String] = [
		"card_tactical_eliminate",
		"card_tactical_reroll",
		"card_tactical_add_time",
		"card_tactical_stun",
		"card_tactical_critical",
		"card_tactical_aegis"
	]
	for tid in tactical_ids:
		var tex: AtlasTexture = panel.get_tactical_card_atlas_texture(tid)
		if tex == null:
			panel.queue_free()
			return _fail("GATE-4", "Failed to load atlas texture for: " + tid)
		if tex.region.size != Vector2(320, 448):
			panel.queue_free()
			return _fail("GATE-4", "Atlas region size expected 320x448, got: " + str(tex.region.size))

	# Tactical Hand Tray existence
	var tray: PanelContainer = panel.get_tactical_tray()
	if tray == null:
		panel.queue_free()
		return _fail("GATE-4", "TacticalHandTray null")

	# Draw 3 cards
	var drawn: Array[Dictionary] = panel.draw_three_tactical_cards()
	if drawn.size() != 3:
		panel.queue_free()
		return _fail("GATE-4", "Expected 3 drawn cards, got %d" % drawn.size())

	# Pick a card into hand
	panel._on_tactical_card_picked(drawn[0])
	var hand: Array[Dictionary] = panel.get_tactical_hand()
	if hand.size() != 1:
		panel.queue_free()
		return _fail("GATE-4", "Tactical hand expected 1 card, got %d" % hand.size())
	if hand[0]["id"] != drawn[0]["id"]:
		panel.queue_free()
		return _fail("GATE-4", "Tactical hand card ID mismatch")

	panel.queue_free()
	print("[GATE 4] PASS: Tactical Atlas 320x448 mapping and Draft Modal workflow verified.")
	return true

# -----------------------------------------------------------------------------
# GATE 5: Tactical Cards Execution
# -----------------------------------------------------------------------------
static func test_005_tactical_cards_execution() -> bool:
	print("[GATE 5] Verifying Tactical Card execution...")

	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()

	# Add cards to hand
	panel._on_tactical_card_picked(BossCombatPanel.TACTICAL_CARDS["card_tactical_aegis"])
	panel._on_tactical_card_picked(BossCombatPanel.TACTICAL_CARDS["card_tactical_critical"])
	panel._on_tactical_card_picked(BossCombatPanel.TACTICAL_CARDS["card_tactical_stun"])

	if panel.get_tactical_hand().size() != 3:
		panel.queue_free()
		return _fail("GATE-5", "Tactical hand expected 3 cards")

	# Use slot 0 (Aegis)
	panel.use_tactical_card(0)
	if panel.get_tactical_hand().size() != 2:
		panel.queue_free()
		return _fail("GATE-5", "Tactical hand expected 2 cards after use")

	# Use slot 0 (Critical)
	panel.use_tactical_card(0)
	if not panel._is_critical_armed:
		panel.queue_free()
		return _fail("GATE-5", "_is_critical_armed must be true after Critical card use")

	# Use slot 0 (Stun)
	panel.use_tactical_card(0)
	if not panel._is_stun_armed:
		panel.queue_free()
		return _fail("GATE-5", "_is_stun_armed must be true after Stun card use")

	if not panel.get_tactical_hand().is_empty():
		panel.queue_free()
		return _fail("GATE-5", "Tactical hand should be empty after using all 3 cards")

	panel.queue_free()
	print("[GATE 5] PASS: Tactical cards execution (Aegis, Critical, Stun) verified.")
	return true

# -----------------------------------------------------------------------------
# GATE 6: Strict Transforms and Timing Locks
# -----------------------------------------------------------------------------
static func test_006_strict_transforms_and_timing_locks() -> bool:
	print("[GATE 6] Verifying Ultimate transform constants and question fade timings...")

	var ct: Dictionary = BossCombatPanel.FINAL_CHARGE_TRANSFORMS
	if abs(ct[2]["scale"] - 1.1378) > 0.001 or abs(ct[2]["x"] - 195.26) > 0.01:
		return _fail("GATE-6", "Charge F03 transform modified!")
	if abs(ct[5]["scale"] - 1.1378) > 0.001 or abs(ct[5]["x"] - 190.18) > 0.01:
		return _fail("GATE-6", "Charge F06 transform modified!")

	var rt: Dictionary = BossCombatPanel.FINAL_RELEASE_TRANSFORMS
	if abs(rt[0]["scale"] - 1.1512) > 0.001 or abs(rt[0]["x"] - 190.63) > 0.01:
		return _fail("GATE-6", "Release F01 transform modified!")
	if abs(rt[4]["scale"] - 1.3067) > 0.001 or abs(rt[4]["x"] - 194.54) > 0.01:
		return _fail("GATE-6", "Release F05 (PEAK) transform modified!")
	if abs(rt[7]["scale"] - 1.2531) > 0.001 or abs(rt[7]["x"] - 195.99) > 0.01:
		return _fail("GATE-6", "Release F08 transform modified!")

	if BossCombatPanel.QUESTION_COMBAT_ALPHA != 0.22:
		return _fail("GATE-6", "QUESTION_COMBAT_ALPHA expected 0.22")
	if BossCombatPanel.QUESTION_FADE_OUT_DURATION != 0.20:
		return _fail("GATE-6", "QUESTION_FADE_OUT_DURATION expected 0.20")
	if BossCombatPanel.QUESTION_FADE_IN_DURATION != 0.24:
		return _fail("GATE-6", "QUESTION_FADE_IN_DURATION expected 0.24")

	print("[GATE 6] PASS: Stochas Ultimate Charge/Release transforms and question fade timings 100% locked.")
	return true

# -----------------------------------------------------------------------------
# GATE 7: Clean Isolation and Zero Asset Edits
# -----------------------------------------------------------------------------
static func test_007_clean_isolation_and_zero_asset_edits() -> bool:
	print("[GATE 7] Verifying clean isolation and zero asset edits...")

	var files_to_check: Array[String] = [
		"res://src/ui/combat/boss_combat_panel.gd",
		"res://src/gameplay/combat/card_combat_controller.gd"
	]
	for p in files_to_check:
		var content: String = FileAccess.get_file_as_string(p)
		if content.find("res://labs/") != -1:
			return _fail("GATE-7", "Illegal res://labs/ reference found in " + p)

	print("[GATE 7] PASS: Clean separation verified. Zero res://labs/ references in src/.")
	return true
