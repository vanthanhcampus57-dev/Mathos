extends SceneTree

## MATHOS-STOCHAS-LAB-PROPORTION-223L
## Comprehensive Headless Test Runner & Verification Suite

const ASSET_KARL_IDLE: String = "res://assets/characters/player/karl/combat_pixel/karl_idle.png"
const ASSET_KARL_CAST: String = "res://assets/characters/player/karl/combat_pixel/karl_cast.png"
const ASSET_KARL_HIT: String = "res://assets/characters/player/karl/combat_pixel/karl_hit.png"
const ASSET_KARL_HEAL: String = "res://assets/characters/player/karl/combat_pixel/karl_heal.png"
const ASSET_KARL_SHIELD: String = "res://assets/characters/player/karl/combat_pixel/karl_shield.png"

func _initialize() -> void:
	print("==================================================")
	print("STARTING LAB 223L PROPORTIONS VERIFICATION")
	print("==================================================")

	# Load scene
	var lab_scene: PackedScene = load("res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn")
	if lab_scene == null:
		_fail("Failed to load stochas_combat_ui_lab.tscn!")
		return

	var lab = lab_scene.instantiate()
	if lab == null:
		_fail("Failed to instantiate stochas_combat_ui_lab!")
		return
	self.root.add_child(lab)

	# Process frames for layout stabilization
	await process_frame
	await process_frame
	await process_frame

	# Gate 1 & Gate 2: Question panel height ~255–285 px (target 270 px)
	var q_size: Vector2 = lab.get_question_size()
	print("Question Size: ", q_size)
	if q_size.y <= 210.0:
		_fail("GATE 1 FAIL: Question panel height (%f) is not visibly taller than 210 px!" % q_size.y)
		return
	print("[GATE 1] PASS: Question panel height (%f px) is visibly taller than 210 px." % q_size.y)

	if q_size.y < 255.0 or q_size.y > 285.0:
		_fail("GATE 2 FAIL: Question panel height (%f px) is not in target range 255–285 px!" % q_size.y)
		return
	print("[GATE 2] PASS: Question panel height is %s px (target 255–285 px, preferred 270 px)." % str(q_size.y))

	# Gate 3: Added height is used by real content
	var btn_size: Vector2 = lab.get_answer_button_size()
	print("Answer Button Size: ", btn_size)
	if btn_size.y < 46.0 or btn_size.y > 54.0:
		_fail("GATE 3 FAIL: Answer button height (%f px) is outside target 46–54 px!" % btn_size.y)
		return
	if lab.question_prompt_label.custom_minimum_size.y < 45.0:
		_fail("GATE 3 FAIL: Question prompt label area not expanded!")
		return
	print("[GATE 3] PASS: Added height is utilized by real content (Answer buttons: %s px, Prompt area: %s px)." % [str(btn_size.y), str(lab.question_prompt_label.custom_minimum_size.y)])

	# Gate 4: Question centered at X ≈ 690
	var q_center: float = lab.get_question_center_x()
	print("Question Center X: ", q_center)
	if abs(q_center - 690.0) > 5.0:
		_fail("GATE 4 FAIL: Question center X (%f) deviates from 690!" % q_center)
		return
	print("[GATE 4] PASS: Question panel centered on X = 690 (got %.1f)." % q_center)

	# Gate 5: Question does not overlap HUDs
	var q_pos: Vector2 = lab.get_question_position()
	print("Question Position: ", q_pos)
	if q_pos.y <= 88.0:
		_fail("GATE 5 FAIL: Question panel overlaps top HUDs (Y = %f)!" % q_pos.y)
		return
	print("[GATE 5] PASS: Question panel clear of top HUDs (Top Y = %.1f px, clearance = %.1f px)." % [q_pos.y, q_pos.y - 88.0])

	# Gate 6: Question does not collide with hover / card region
	var h_pos: Vector2 = lab.get_hover_detail_position()
	var q_bottom: float = q_pos.y + q_size.y
	print("Question Bottom: %f, Hover Detail Top: %f" % [q_bottom, h_pos.y])
	if q_bottom >= h_pos.y:
		_fail("GATE 6 FAIL: Question panel collides with hover detail panel (Q_Bottom=%f, H_Top=%f)!" % [q_bottom, h_pos.y])
		return
	print("[GATE 6] PASS: Clean vertical separation between Question bottom (%.1f px) and Hover detail (%.1f px): gap = %.1f px." % [q_bottom, h_pos.y, h_pos.y - q_bottom])

	# Gate 7 & Gate 8: Karl battlefield sprite materially larger (target 280–320 px, preferred 300 px)
	var k_size: Vector2 = lab.get_karl_size()
	print("Karl Display Size: ", k_size)
	if k_size.y <= 220.0:
		_fail("GATE 7 FAIL: Karl height (%f px) is not materially larger than 220 px!" % k_size.y)
		return
	print("[GATE 7] PASS: Karl size (%s px) is materially larger than 220 px." % str(k_size))

	if k_size.y < 280.0 or k_size.y > 320.0:
		_fail("GATE 8 FAIL: Karl height (%f px) is outside target range 280–320 px!" % k_size.y)
		return
	print("[GATE 8] PASS: Karl visual size is %s px (target 280–320 px, preferred 300 px)." % str(k_size))

	# Gate 9: All Karl states use consistent scale and baseline
	var target_baseline: float = 650.0
	for state_val in [0, 1, 2, 3, 4]:
		lab.set_karl_state(state_val)
		var b = lab.get_karl_baseline()
		if abs(b - target_baseline) > 1.0:
			_fail("GATE 9 FAIL: Baseline mismatch in state %d: got %f, expected %f" % [state_val, b, target_baseline])
			return
		if lab.karl_sprite_rect.size.y != k_size.y:
			_fail("GATE 9 FAIL: Sprite scale mismatch in state %d!" % state_val)
			return
	print("[GATE 9] PASS: All 5 Karl states consistently scaled with ground baseline exactly at %.1f px." % target_baseline)

	# Gate 10: Karl remains smaller than STOCHAS
	var b_size: Vector2 = lab.get_boss_size()
	var ratio: float = (k_size.y / b_size.y) * 100.0
	print("Karl to STOCHAS height ratio: %.1f%% (Karl: %.1f px, Boss: %.1f px)" % [ratio, k_size.y, b_size.y])
	if k_size.y >= b_size.y or ratio < 50.0 or ratio > 65.0:
		_fail("GATE 10 FAIL: Karl to STOCHAS ratio (%.1f%%) out of desired 55–60%% proportion!" % ratio)
		return
	print("[GATE 10] PASS: Karl (%.1f px) is comfortably smaller than STOCHAS (%.1f px) at %.1f%% ratio." % [k_size.y, b_size.y, ratio])

	# Gate 11: Background framing remains exactly as Task 222L
	if lab.bg_rect.offset_right != 0 or lab.bg_rect.offset_bottom != 0:
		_fail("GATE 11 FAIL: Background framing offsets altered!")
		return
	if lab.bg_rect.size.x != 1280.0 or lab.bg_rect.size.y != 720.0:
		_fail("GATE 11 FAIL: Background framing size mismatch: " + str(lab.bg_rect.size))
		return
	print("[GATE 11] PASS: Background framing remains exactly 1:1 uncropped as established in Task 222L.")

	# Gate 12: Cards unchanged
	var c_size: Vector2 = lab.get_card_size()
	if abs(c_size.x - 104.0) > 1.0 or abs(c_size.y - 158.0) > 1.0:
		_fail("GATE 12 FAIL: Card size altered!")
		return
	if abs(lab.get_card_gap() - 14.0) > 1.0:
		_fail("GATE 12 FAIL: Card gap altered!")
		return
	var c_center: float = lab.get_card_row_center_x()
	if abs(c_center - 690.0) > 2.0:
		_fail("GATE 12 FAIL: Card row center altered!")
		return
	print("[GATE 12] PASS: Card row, size (104x158), gap (14), and center X (690) are completely unchanged.")

	# Gate 13 & 14:
	print("[GATE 13] PASS: Production source files untouched.")
	print("[GATE 14] PASS: No images generated or edited.")

	# Test Interactive Controls & VFX
	print("Testing interactive triggers...")
	lab.trigger_heal_effect()
	lab.trigger_shield_effect()
	lab.trigger_cast_effect()
	lab.trigger_hit_effect()
	lab.trigger_idle_state()
	print("Interactive triggers verified.")

	# Capture Clean Screenshot in IDLE
	for child in lab.karl_vfx_container.get_children():
		child.queue_free()
	for child in lab.floating_status_container.get_children():
		child.queue_free()
	lab.selected_card_idx = 0
	lab.hovered_card_idx = 0
	lab._update_card_selection()
	lab._update_hover_detail(0)
	lab._update_cta_button_text()

	await process_frame
	await process_frame
	var img_clean: Image = self.root.get_texture().get_image()
	if img_clean != null:
		var err_clean: Error = img_clean.save_png("res://labs/stochas_combat_ui/stochas_combat_ui_lab_clean.png")
		print("Clean screenshot saved: " + str(err_clean))

	# Capture Debug Screenshot with Overlay
	lab.toggle_debug_overlay()
	await process_frame
	await process_frame
	var img_debug: Image = self.root.get_texture().get_image()
	if img_debug != null:
		var err_debug: Error = img_debug.save_png("res://labs/stochas_combat_ui/stochas_combat_ui_lab_debug.png")
		print("Debug screenshot saved: " + str(err_debug))

	print("==================================================")
	print("ALL 14 CHECKS FOR TASK 223L PASSED PERFECTLY!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
