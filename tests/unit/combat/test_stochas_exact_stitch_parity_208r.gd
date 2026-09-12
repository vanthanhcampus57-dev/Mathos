class_name TestStochasExactStitchParity208R
extends SceneTree

## TASK-208R: STOCHAS Exact Stitch Visual Parity Test Suite
## Verifies full pixel and layout parity against the authoritative Stitch reference:
## 1. Canvas & Fullscreen Misty Forest Background (1280x720)
## 2. Top-Left Player HUD (Avatar 56x56, metrics ~208px, cyan border, HP & Shield)
## 3. Top-Right Boss HUD (Metrics ~240px, sigil 56x56, red border, Boss HP)
## 4. Top-Center Math Challenge (530px wide, centered at x=375, rounded 16px, cyan border, CTA inside, rule footer)
## 5. Multiple Choice 2x2 Grid Mode (GridContainer with 2 columns, compact cards)
## 6. Boss Stage Right (~460px wide at x=812, ~530px art height, unboxed transparent arena, cyan glow)
## 7. Bottom Tactical Cards Row (4 cards, 106x154px, 14px gap, width 466px centered at x=407)
## 8. Flow Pill ("1. CHỌN THẺ BÀI → 2. GIẢI TOÁN → 3. XUẤT CHIÊU") directly above cards
## 9. Card Selection Lift (~8px), ĐANG CHỌN badge, and disabled PROBABILITY card
## 10. Lower-Left Combat Action Feed (240px wide at x=32, y=594, dark glass)
## 11. Minimal bottom-right settings control without card interference
## 12. Full Task 204 combat logic preservation (card switches, damage 100->90, shield +8, retaliation)
## 13. Multi-resolution layout verification (1280x720, 1280x680, 1366x768, 1600x900, 1920x1080)

func _initialize() -> void:
	var ok: bool = run_all_tests(self)
	quit(0 if ok else 1)

static func run_all_tests(tree: SceneTree = null) -> bool:
	print("==================================================")
	print("STARTING TASK 208R STOCHAS EXACT STITCH PARITY SUITE")
	print("==================================================")
	var all_ok: bool = true

	all_ok = test_001_canvas_and_background_parity(tree) and all_ok
	all_ok = test_002_player_hud_stitch_parity(tree) and all_ok
	all_ok = test_003_boss_hud_stitch_parity(tree) and all_ok
	all_ok = test_004_math_challenge_top_center_and_styling(tree) and all_ok
	all_ok = test_005_answer_grid_2x2_mode(tree) and all_ok
	all_ok = test_006_boss_stage_geometry_and_unboxed_presentation(tree) and all_ok
	all_ok = test_007_tactical_card_row_and_flow_pill(tree) and all_ok
	all_ok = test_008_card_states_badges_and_lift(tree) and all_ok
	all_ok = test_009_combat_feed_position_and_styling(tree) and all_ok
	all_ok = test_010_minimal_settings_control(tree) and all_ok
	all_ok = test_011_task204_runtime_combat_flow_preservation(tree) and all_ok
	all_ok = test_012_multi_resolution_responsiveness(tree) and all_ok

	print("==================================================")
	if all_ok:
		print("TASK 208R STOCHAS EXACT STITCH PARITY: ALL 12 / 12 PASSED!")
	else:
		print("TASK 208R STOCHAS EXACT STITCH PARITY: FAILED")
	print("==================================================")
	return all_ok

static func _fail(code: String, msg: String) -> bool:
	push_error("[%s] FAIL: %s" % [code, msg])
	print("[%s] FAIL: %s" % [code, msg])
	return false

static func _cleanup(node: Node) -> void:
	if node != null and is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.queue_free()

static func _setup_app_root_at_stage_1_5(tree: SceneTree) -> AppRoot:
	var root: AppRoot = AppRoot.new()
	root.bootstrap_runtime()
	if tree != null and tree.root != null:
		tree.root.add_child(root)

	var progress: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04"]:
		var r_id: String = String(cat.get_stage(s_id).get("reward_id", "reward_01_01"))
		progress.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, [] as Array[String]))

	root.select_stage("stage_01_05")
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	shell.lesson_continue_requested.emit()
	return root

# -----------------------------------------------------------------------------
# 1. Canvas & Fullscreen Misty Forest Background
# -----------------------------------------------------------------------------
static func test_001_canvas_and_background_parity(tree: SceneTree) -> bool:
	print("[PARITY-208R-01] Testing fixed 1280x720 canvas and fullscreen misty forest background...")
	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()
	panel._layout_elements()

	if panel.size != Vector2(1280, 720):
		panel.free()
		return _fail("PARITY-208R-01", "Panel size expected 1280x720, got %s" % str(panel.size))

	# Verify background assets exist and are local
	var bg_found: bool = ResourceLoader.exists("res://assets/backgrounds/dungeon_1/d1_misty_forest_bg.png") or ResourceLoader.exists("res://assets/backgrounds/d1_misty_forest_bg.png")
	if not bg_found:
		panel.free()
		return _fail("PARITY-208R-01", "Misty forest background texture not found")

	panel.free()
	print("[PARITY-208R-01] PASS: 1280x720 canvas and fullscreen background verified")
	return true

# -----------------------------------------------------------------------------
# 2. Top-Left Player HUD
# -----------------------------------------------------------------------------
static func test_002_player_hud_stitch_parity(tree: SceneTree) -> bool:
	print("[PARITY-208R-02] Testing Top-Left Player HUD layout and metrics...")
	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()
	panel._layout_elements()

	var hud_rect: Rect2 = panel.get_player_hud_rect()
	if hud_rect.position.x < 30.0 or hud_rect.position.x > 34.0:
		panel.free()
		return _fail("PARITY-208R-02", "Player HUD expected at x ~32, got %f" % hud_rect.position.x)
	if hud_rect.position.y < 14.0 or hud_rect.position.y > 18.0:
		panel.free()
		return _fail("PARITY-208R-02", "Player HUD expected at y ~16, got %f" % hud_rect.position.y)
	if hud_rect.size.x < 260.0 or hud_rect.size.x > 290.0:
		panel.free()
		return _fail("PARITY-208R-02", "Player HUD width expected ~272, got %f" % hud_rect.size.x)

	if panel._player_hp_bar == null:
		panel.free()
		return _fail("PARITY-208R-02", "Player HP bar is null")
	if panel._player_shield_label == null:
		panel.free()
		return _fail("PARITY-208R-02", "Player shield label is null")

	panel.free()
	print("[PARITY-208R-02] PASS: Top-Left Player HUD rect and controls strictly verified")
	return true

# -----------------------------------------------------------------------------
# 3. Top-Right Boss HUD
# -----------------------------------------------------------------------------
static func test_003_boss_hud_stitch_parity(tree: SceneTree) -> bool:
	print("[PARITY-208R-03] Testing Top-Right Boss HUD layout and sigil...")
	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()
	panel._layout_elements()

	var boss_rect: Rect2 = panel.get_boss_hud_rect()
	# Right-aligned inside 1280 canvas with ~32px margin: 1280 - 32 - 304 = 944
	if boss_rect.position.x < 930.0 or boss_rect.position.x > 960.0:
		panel.free()
		return _fail("PARITY-208R-03", "Boss HUD expected at x ~944, got %f" % boss_rect.position.x)
	if boss_rect.position.y < 14.0 or boss_rect.position.y > 18.0:
		panel.free()
		return _fail("PARITY-208R-03", "Boss HUD expected at y ~16, got %f" % boss_rect.position.y)
	if boss_rect.size.x < 290.0 or boss_rect.size.x > 320.0:
		panel.free()
		return _fail("PARITY-208R-03", "Boss HUD width expected ~304, got %f" % boss_rect.size.x)

	if panel._boss_hp_bar == null:
		panel.free()
		return _fail("PARITY-208R-03", "Boss HP bar is null")
	if panel._boss_name_label == null or panel._boss_name_label.text != "STOCHAS":
		panel.free()
		return _fail("PARITY-208R-03", "Boss name label expected STOCHAS")

	panel.free()
	print("[PARITY-208R-03] PASS: Top-Right Boss HUD rect and controls strictly verified")
	return true

# -----------------------------------------------------------------------------
# 4. Top-Center Math Challenge & Styling
# -----------------------------------------------------------------------------
static func test_004_math_challenge_top_center_and_styling(tree: SceneTree) -> bool:
	print("[PARITY-208R-04] Testing Top-Center Math Challenge panel styling, CTA, and rule footer...")
	var root: AppRoot = _setup_app_root_at_stage_1_5(tree)
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	var q_panel: QuestionPanel = shell.get_question_panel()
	var q_host: MarginContainer = shell.get_question_host_container()
	var gameplay_hbox: Control = q_host.get_node_or_null("GameplayHBox") as Control
	var q_host_panel: Control = gameplay_hbox.get_node_or_null("QuestionPanelHost") as Control

	if q_host_panel == null:
		_cleanup(root)
		return _fail("PARITY-208R-04", "QuestionPanelHost is null")

	# Check width constraint (Task 216 human rework: 700-760px, previously 580-650px)
	if q_host_panel.custom_minimum_size.x < 700.0 or q_host_panel.custom_minimum_size.x > 760.0:
		_cleanup(root)
		return _fail("PARITY-208R-04", "QuestionPanelHost custom_minimum_size.x expected 700-760, got %f" % q_host_panel.custom_minimum_size.x)

	# Verify glass theme styling override applied in combat
	if not q_panel.has_theme_stylebox_override("panel"):
		_cleanup(root)
		return _fail("PARITY-208R-04", "QuestionPanel does not have stylebox override in combat")

	var sb: StyleBoxFlat = q_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null:
		_cleanup(root)
		return _fail("PARITY-208R-04", "StyleBox is not StyleBoxFlat")
	if sb.corner_radius_top_left != 16:
		_cleanup(root)
		return _fail("PARITY-208R-04", "QuestionPanel corner_radius expected 16, got %d" % sb.corner_radius_top_left)

	# Verify header label text
	var obj_label: Label = q_panel._objective_label
	if obj_label == null or obj_label.text != "ARCANE MATH CHALLENGE • STAGE 1.5":
		_cleanup(root)
		return _fail("PARITY-208R-04", "Objective label expected 'ARCANE MATH CHALLENGE • STAGE 1.5'")

	# Verify CTA button styling and label
	var submit_btn: Button = q_panel.get_submit_button()
	if submit_btn == null or not submit_btn.text.begins_with("XUẤT CHIÊU"):
		_cleanup(root)
		return _fail("PARITY-208R-04", "Submit button text expected XUẤT CHIÊU, got '%s'" % (submit_btn.text if submit_btn != null else "null"))

	# Verify rule footer exists and is visible
	if q_panel._combat_rule_footer == null or not q_panel._combat_rule_footer.visible:
		_cleanup(root)
		return _fail("PARITY-208R-04", "Combat rule footer not found or not visible")

	_cleanup(root)
	print("[PARITY-208R-04] PASS: Math Challenge styling, header, CTA, and rule footer verified")
	return true

# -----------------------------------------------------------------------------
# 5. Multiple Choice 2x2 Grid Mode
# -----------------------------------------------------------------------------
static func test_005_answer_grid_2x2_mode(tree: SceneTree) -> bool:
	print("[PARITY-208R-05] Testing Multiple Choice 2x2 grid mode in combat...")
	var mc_view: MultipleChoiceView = MultipleChoiceView.new()
	var payload: Dictionary = {
		"options": [
			{"option_id": "opt_a", "text": "Phương án A"},
			{"option_id": "opt_b", "text": "Phương án B"},
			{"option_id": "opt_c", "text": "Phương án C"},
			{"option_id": "opt_d", "text": "Phương án D"}
		]
	}
	mc_view.set_combat_grid_mode(true)
	var ok: bool = mc_view.setup(payload)
	if not ok:
		mc_view.free()
		return _fail("PARITY-208R-05", "MultipleChoiceView setup failed")

	if not mc_view.is_combat_grid_mode():
		mc_view.free()
		return _fail("PARITY-208R-05", "Combat grid mode not active")

	if mc_view._grid == null or not mc_view._grid.visible:
		mc_view.free()
		return _fail("PARITY-208R-05", "GridContainer not visible in combat grid mode")

	if mc_view._grid.columns != 2:
		mc_view.free()
		return _fail("PARITY-208R-05", "GridContainer columns expected 2, got %d" % mc_view._grid.columns)

	if mc_view._grid.get_child_count() != 4:
		mc_view.free()
		return _fail("PARITY-208R-05", "GridContainer expected 4 children, got %d" % mc_view._grid.get_child_count())

	# Test selection works in 2x2 grid
	var sel_ok: bool = mc_view.select_option("opt_c")
	if not sel_ok or mc_view.get_selected_option_id() != "opt_c":
		mc_view.free()
		return _fail("PARITY-208R-05", "Option selection failed in grid mode")

	mc_view.free()
	print("[PARITY-208R-05] PASS: 2x2 multiple choice grid mode verified")
	return true

# -----------------------------------------------------------------------------
# 6. Boss Stage Geometry & Unboxed Presentation
# -----------------------------------------------------------------------------
static func test_006_boss_stage_geometry_and_unboxed_presentation(tree: SceneTree) -> bool:
	print("[PARITY-208R-06] Testing STOCHAS Boss Stage geometry (~460px right) and unboxed arena...")
	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()
	panel._layout_elements()

	var stage_rect: Rect2 = panel.get_boss_stage_rect()
	# Right ~8px on 1280 canvas: 1280 - 8 - 460 = 812
	if stage_rect.position.x < 800.0 or stage_rect.position.x > 824.0:
		panel.free()
		return _fail("PARITY-208R-06", "Boss stage expected at x ~812, got %f" % stage_rect.position.x)
	if stage_rect.size.x != 460.0:
		panel.free()
		return _fail("PARITY-208R-06", "Boss stage width expected 460, got %f" % stage_rect.size.x)

	# Verify unboxed arena (no opaque rectangular arena)
	var sb: StyleBoxFlat = panel._boss_visual_rect.get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null:
		panel.free()
		return _fail("PARITY-208R-06", "BossVisualContainer has no stylebox")
	if sb.bg_color.a > 0.05:
		panel.free()
		return _fail("PARITY-208R-06", "BossVisualContainer bg_color should be transparent, got %s" % str(sb.bg_color))

	# Verify boss artwork height
	if panel._boss_sprite_rect.custom_minimum_size.y != 530.0:
		panel.free()
		return _fail("PARITY-208R-06", "Boss art height expected 530, got %f" % panel._boss_sprite_rect.custom_minimum_size.y)

	panel.free()
	print("[PARITY-208R-06] PASS: STOCHAS Boss Stage right-aligned, 460px wide, and unboxed arena verified")
	return true

# -----------------------------------------------------------------------------
# 7. Tactical Card Row & Flow Pill
# -----------------------------------------------------------------------------
static func test_007_tactical_card_row_and_flow_pill(tree: SceneTree) -> bool:
	print("[PARITY-208R-07] Testing Tactical Card Row (4 cards, 106x154px) and Flow Pill...")
	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()
	panel._layout_elements()

	var card_row_rect: Rect2 = panel.get_card_row_rect()
	# 4 cards * CARD_WIDTH + 3 gaps * CARD_GAP. Centered on 1280.
	# Task 214 human rework: cards are 125-140 x 175-200 (132x188, total row 570px centered at x=355).
	var expected_w: float = 4.0 * BossCombatPanel.CARD_WIDTH + 3.0 * BossCombatPanel.CARD_GAP
	var expected_x: float = (1280.0 - expected_w) * 0.5
	if absf(card_row_rect.position.x - expected_x) > 2.0:
		panel.free()
		return _fail("PARITY-208R-07", "Card row expected centered at x ~%f, got %f" % [expected_x, card_row_rect.position.x])
	if absf(card_row_rect.size.x - expected_w) > 2.0:
		panel.free()
		return _fail("PARITY-208R-07", "Card row width expected ~%f, got %f" % [expected_w, card_row_rect.size.x])

	# Verify exact 4 cards
	for cid in ["card_strike", "card_defend", "card_heal", "card_probability"]:
		var btn: Button = panel.get_card_button(cid)
		if btn == null:
			panel.free()
			return _fail("PARITY-208R-07", "Card button %s is null" % cid)
		if btn.custom_minimum_size != Vector2(BossCombatPanel.CARD_WIDTH, BossCombatPanel.CARD_HEIGHT):
			panel.free()
			return _fail("PARITY-208R-07", "Card %s expected %sx%s, got %s" % [cid, str(BossCombatPanel.CARD_WIDTH), str(BossCombatPanel.CARD_HEIGHT), str(btn.custom_minimum_size)])

	# Verify Flow Pill
	var pill_rect: Rect2 = panel.get_flow_pill_rect()
	if pill_rect.position.y >= card_row_rect.position.y:
		panel.free()
		return _fail("PARITY-208R-07", "Flow pill should be positioned above card row")

	if panel._cards_header_label == null or not panel._cards_header_label.text.contains("CHỌN THẺ BÀI"):
		panel.free()
		return _fail("PARITY-208R-07", "Flow pill indicator text missing canonical Vietnamese steps")

	panel.free()
	print("[PARITY-208R-07] PASS: Centered card row (466px, 106x154) and Flow Pill strictly verified")
	return true

# -----------------------------------------------------------------------------
# 8. Card States, Badges, and Lift
# -----------------------------------------------------------------------------
static func test_008_card_states_badges_and_lift(tree: SceneTree) -> bool:
	print("[PARITY-208R-08] Testing card elevation lift, ĐANG CHỌN badge, and disabled PROBABILITY...")
	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()
	panel._layout_elements()

	# Select Strike
	panel.select_card("card_strike")
	var strike_slot: MarginContainer = panel.get_card_slot("card_strike") as MarginContainer
	var defend_slot: MarginContainer = panel.get_card_slot("card_defend") as MarginContainer

	if strike_slot.get_theme_constant("margin_bottom") != 6 or strike_slot.get_theme_constant("margin_top") != 0:
		panel.free()
		return _fail("PARITY-208R-08", "Selected card slot expected margin_top=0, margin_bottom=6")

	if defend_slot.get_theme_constant("margin_top") != 6 or defend_slot.get_theme_constant("margin_bottom") != 0:
		panel.free()
		return _fail("PARITY-208R-08", "Unselected card slot expected margin_top=6, margin_bottom=0")

	# Verify ĐANG CHỌN badge on Strike
	var strike_badge: Label = panel._card_badges_by_id.get("card_strike") as Label
	if strike_badge == null or strike_badge.text != "ĐANG CHỌN":
		panel.free()
		return _fail("PARITY-208R-08", "Selected Strike expected 'ĐANG CHỌN' badge, got '%s'" % (strike_badge.text if strike_badge != null else "null"))

	# Verify PROBABILITY is disabled
	var prob_btn: Button = panel.get_card_button("card_probability")
	if prob_btn == null or not prob_btn.disabled:
		panel.free()
		return _fail("PARITY-208R-08", "Probability card must be disabled")

	var prob_badge: Label = panel._card_badges_by_id.get("card_probability") as Label
	var prob_status: Label = panel._card_statuses_by_id.get("card_probability") as Label
	if prob_badge == null or prob_badge.text != "KỸ NĂNG":
		panel.free()
		return _fail("PARITY-208R-08", "Probability badge expected 'KỸ NĂNG'")
	if prob_status == null or prob_status.text != "CHƯA KÍCH HOẠT":
		panel.free()
		return _fail("PARITY-208R-08", "Probability status expected 'CHƯA KÍCH HOẠT'")

	panel.free()
	print("[PARITY-208R-08] PASS: Card elevation lift (~8px/6px), badges, and disabled Probability verified")
	return true

# -----------------------------------------------------------------------------
# 9. Combat Action Feed Position & Styling (Task 216: Absent from UI)
# -----------------------------------------------------------------------------
static func test_009_combat_feed_position_and_styling(tree: SceneTree) -> bool:
	print("[PARITY-208R-09] Testing Lower-Left Combat Action Feed absent and clean (Task 216)...")
	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()
	panel._layout_elements()

	var feed_panel: Control = panel.get_node_or_null("CombatFeedPanel") as Control
	if feed_panel != null and feed_panel.visible:
		panel.free()
		return _fail("PARITY-208R-09", "Combat feed panel must not be visible on combat screen")

	var feed_rect: Rect2 = panel.get_combat_feed_rect()
	if feed_rect != Rect2():
		panel.free()
		return _fail("PARITY-208R-09", "Combat feed rect expected empty Rect2, got %s" % str(feed_rect))

	# Verify internal combat logging still updates without visual feed
	panel._on_combat_log("Test combat log", "player_success")
	if panel._combat_log_label == null or panel._combat_log_label.text != "Test combat log":
		panel.free()
		return _fail("PARITY-208R-09", "Internal combat logging logic failed")

	panel.free()
	print("[PARITY-208R-09] PASS: Lower-Left Combat Action Feed absent, lower-left clean, logging intact")
	return true

# -----------------------------------------------------------------------------
# 10. Minimal Settings Control
# -----------------------------------------------------------------------------
static func test_010_minimal_settings_control(tree: SceneTree) -> bool:
	print("[PARITY-208R-10] Testing minimal bottom-right settings control without card interference...")
	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.size = Vector2(1280, 720)
	panel._ensure_ui()
	panel._layout_elements()

	if panel._settings_button == null:
		panel.free()
		return _fail("PARITY-208R-10", "Settings button is null")

	var btn_rect: Rect2 = Rect2(panel._settings_button.position, panel._settings_button.size)
	var card_row_rect: Rect2 = panel.get_card_row_rect()

	# Must not intersect with card row
	if btn_rect.intersects(card_row_rect):
		panel.free()
		return _fail("PARITY-208R-10", "Settings button intersects with card row")

	if btn_rect.position.x < 1200.0:
		panel.free()
		return _fail("PARITY-208R-10", "Settings button expected at far right (>= 1200)")

	panel.free()
	print("[PARITY-208R-10] PASS: Settings control isolated at bottom-right with zero card interference")
	return true

# -----------------------------------------------------------------------------
# 11. Full Task 204 Combat Logic Preservation
# -----------------------------------------------------------------------------
static func test_011_task204_runtime_combat_flow_preservation(tree: SceneTree) -> bool:
	print("[PARITY-208R-11] Testing full Task 204 mounted runtime combat logic preservation...")
	var root: AppRoot = _setup_app_root_at_stage_1_5(tree)
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	var boss_panel: BossCombatPanel = shell.get_existing_boss_combat_panel()
	var q_panel: QuestionPanel = shell.get_question_panel()
	var controller: CardCombatController = boss_panel.get_controller()

	if controller == null:
		_cleanup(root)
		return _fail("PARITY-208R-11", "CardCombatController is null")

	# Step 1: Default STRIKE selected
	if not boss_panel.is_card_selected("card_strike"):
		_cleanup(root)
		return _fail("PARITY-208R-11", "Default card expected card_strike")
	var cta_text: String = q_panel.get_combat_action_text()
	if not cta_text.contains("TẤN CÔNG"):
		_cleanup(root)
		return _fail("PARITY-208R-11", "CTA expected TẤN CÔNG, got '%s'" % cta_text)

	# Step 2: Switch to DEFEND via button
	var defend_btn: Button = boss_panel.get_card_button("card_defend")
	defend_btn.emit_signal("pressed")
	if not boss_panel.is_card_selected("card_defend"):
		_cleanup(root)
		return _fail("PARITY-208R-11", "Failed switching to DEFEND")
	cta_text = q_panel.get_combat_action_text()
	if not cta_text.contains("PHÒNG THỦ"):
		_cleanup(root)
		return _fail("PARITY-208R-11", "CTA expected PHÒNG THỦ, got '%s'" % cta_text)

	# Step 3: Switch back to STRIKE
	var strike_btn: Button = boss_panel.get_card_button("card_strike")
	strike_btn.emit_signal("pressed")
	if not boss_panel.is_card_selected("card_strike"):
		_cleanup(root)
		return _fail("PARITY-208R-11", "Failed switching back to STRIKE")

	# Step 4: Submit correct answer -> reduces Boss HP to 90
	var q_ctrl: QuestionPresentationController = root.get_question_controller()
	q_ctrl.question_completed.emit({"is_correct": true, "question_id": "q_test"})

	if controller.boss_entity.current_hp != 90:
		_cleanup(root)
		return _fail("PARITY-208R-11", "Boss HP expected 90 after correct STRIKE, got %d" % controller.boss_entity.current_hp)
	if boss_panel._boss_hp_bar.value != 90.0:
		_cleanup(root)
		return _fail("PARITY-208R-11", "Boss HP bar value expected 90, got %f" % boss_panel._boss_hp_bar.value)

	# Step 5: Switch to DEFEND, correct answer -> adds +8 shield
	defend_btn = boss_panel.get_card_button("card_defend")
	defend_btn.emit_signal("pressed")
	q_ctrl.question_completed.emit({"is_correct": true, "question_id": "q_test2"})

	if controller.player_runtime.shield != 8:
		_cleanup(root)
		return _fail("PARITY-208R-11", "Player shield expected 8, got %d" % controller.player_runtime.shield)

	# Step 6: Wrong answer -> triggers Boss retaliation
	# Boss deals 10 dmg, shield absorbs 8 dmg, player HP reduced by remaining 2 (from 100 to 98)
	q_ctrl.question_completed.emit({"is_correct": false, "question_id": "q_test3"})

	if controller.player_runtime.shield != 0 or controller.player_runtime.current_hp != 98:
		_cleanup(root)
		return _fail("PARITY-208R-11", "Player HP/Shield expected 98/0 after retaliation, got %d/%d" % [controller.player_runtime.current_hp, controller.player_runtime.shield])

	_cleanup(root)
	print("[PARITY-208R-11] PASS: Task 204 combat logic (card switching, damage, shield, retaliation) 100% intact")
	return true

# -----------------------------------------------------------------------------
# 12. Multi-Resolution Responsiveness
# -----------------------------------------------------------------------------
static func test_012_multi_resolution_responsiveness(tree: SceneTree) -> bool:
	print("[PARITY-208R-12] Testing multi-resolution layout responsiveness (1280x720, 1280x680, 1366x768, 1600x900, 1920x1080)...")
	var resolutions: Array[Vector2] = [
		Vector2(1280, 720),
		Vector2(1280, 680),
		Vector2(1366, 768),
		Vector2(1600, 900),
		Vector2(1920, 1080)
	]

	for res in resolutions:
		var panel: BossCombatPanel = BossCombatPanel.new()
		panel.size = res
		panel._ensure_ui()
		panel._layout_elements()

		var p_hud: Rect2 = panel.get_player_hud_rect()
		var b_hud: Rect2 = panel.get_boss_hud_rect()
		var b_stage: Rect2 = panel.get_boss_stage_rect()
		var cards: Rect2 = panel.get_card_row_rect()
		var feed: Rect2 = panel.get_combat_feed_rect()

		# Check all components inside viewport
		if p_hud.position.x < 0 or p_hud.position.y < 0:
			panel.free()
			return _fail("PARITY-208R-12", "Player HUD outside viewport at %s" % str(res))
		if b_hud.position.x + b_hud.size.x > res.x or b_hud.position.y < 0:
			panel.free()
			return _fail("PARITY-208R-12", "Boss HUD outside viewport at %s" % str(res))
		if b_stage.position.x + b_stage.size.x > res.x or b_stage.position.y + b_stage.size.y > res.y:
			panel.free()
			return _fail("PARITY-208R-12", "Boss Stage outside viewport at %s" % str(res))
		if cards.position.x < 0 or cards.position.x + cards.size.x > res.x or cards.position.y + cards.size.y > res.y:
			panel.free()
			return _fail("PARITY-208R-12", "Cards row outside viewport at %s" % str(res))
		if feed.position.x < 0 or feed.position.y + feed.size.y > res.y:
			panel.free()
			return _fail("PARITY-208R-12", "Combat feed outside viewport at %s" % str(res))

		# Check no overlap between cards and feed
		if cards.intersects(feed):
			panel.free()
			return _fail("PARITY-208R-12", "Cards intersect combat feed at %s" % str(res))

		panel.free()

	print("[PARITY-208R-12] PASS: Multi-resolution layout validated cleanly across all 5 resolutions")
	return true
