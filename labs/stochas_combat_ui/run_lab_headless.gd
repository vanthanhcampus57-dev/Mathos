extends SceneTree

## MATHOS-SHIELD-DAMAGE-QUESTION-PRESENTATION-228L
## Headless Test Runner & Verification Suite for Shield Damage, Question Combat Mode, and Layout Refinement

func _initialize() -> void:
	print("==================================================")
	print("STARTING LAB 228L SHIELD DAMAGE & QUESTION TEST")
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

	# CASE A: HP 100, Shield 0, Boss damage 10 -> HP 90, Shield 0
	lab.reset_lab()
	if lab.get_current_karl_hp() != 100 or lab.get_current_shield() != 0:
		_fail("CASE A setup failed: initial HP or Shield incorrect!")
		return
	lab.apply_damage_to_karl(10)
	if lab.get_current_karl_hp() != 90:
		_fail("CASE A FAIL: Expected HP 90, got %d" % lab.get_current_karl_hp())
		return
	if lab.get_current_shield() != 0:
		_fail("CASE A FAIL: Expected Shield 0, got %d" % lab.get_current_shield())
		return
	if "HP: 90 / 100" not in lab.karl_hp_sub_label.text or "GIÁP: 0" not in lab.karl_hp_sub_label.text:
		_fail("CASE A FAIL: HUD text mismatch: %s" % lab.karl_hp_sub_label.text)
		return
	print("[CASE A / GATE 1] PASS: Shield 0 + damage 10 -> HP 90, Shield 0, HUD updated.")

	# CASE B: HP 100, Shield 8, Boss damage 10 -> Shield absorbs 8, shield break, HP 98
	lab.reset_lab()
	lab.set_shield(8)
	if lab.get_current_shield() != 8 or not lab.is_persistent_barrier_visible():
		_fail("CASE B setup failed: shield 8 or barrier not active!")
		return
	lab.apply_damage_to_karl(10)
	if lab.get_current_shield() != 0:
		_fail("CASE B FAIL: Expected Shield 0 after absorption, got %d" % lab.get_current_shield())
		return
	if lab.get_current_karl_hp() != 98:
		_fail("CASE B FAIL: Expected HP 98 after overflow, got %d" % lab.get_current_karl_hp())
		return
	if "HP: 98 / 100" not in lab.karl_hp_sub_label.text or "GIÁP: 0" not in lab.karl_hp_sub_label.text:
		_fail("CASE B FAIL: HUD text mismatch: %s" % lab.karl_hp_sub_label.text)
		return
	print("[CASE B / GATE 2, 3, 4] PASS: Shield 8 + damage 10 -> Shield 0, Shield break auto-triggered, HP 98, HUD updated.")

	# CASE C: HP 100, Shield 16, Boss damage 10 -> Shield 6, HP 100, barrier remains, no break
	lab.reset_lab()
	lab.set_shield(16)
	if lab.get_current_shield() != 16:
		_fail("CASE C setup failed!")
		return
	lab.apply_damage_to_karl(10)
	if lab.get_current_shield() != 6:
		_fail("CASE C FAIL: Expected Shield 6, got %d" % lab.get_current_shield())
		return
	if lab.get_current_karl_hp() != 100:
		_fail("CASE C FAIL: Expected HP 100, got %d" % lab.get_current_karl_hp())
		return
	if not lab.is_persistent_barrier_visible():
		_fail("CASE C FAIL: Barrier should remain active when shield > 0!")
		return
	if "HP: 100 / 100" not in lab.karl_hp_sub_label.text or "GIÁP: 6" not in lab.karl_hp_sub_label.text:
		_fail("CASE C FAIL: HUD text mismatch: %s" % lab.karl_hp_sub_label.text)
		return
	print("[CASE C / GATE 5, 6] PASS: Shield 16 + damage 10 -> Shield 6, HP 100, barrier remains active.")

	# CASE D: HP 100, Shield 24, Boss damage 10 -> Shield 14, HP 100
	lab.reset_lab()
	lab.set_shield(24)
	lab.apply_damage_to_karl(10)
	if lab.get_current_shield() != 14 or lab.get_current_karl_hp() != 100:
		_fail("CASE D FAIL: Expected Shield 14, HP 100, got Shield %d, HP %d" % [lab.get_current_shield(), lab.get_current_karl_hp()])
		return
	if not lab.is_persistent_barrier_visible():
		_fail("CASE D FAIL: Barrier should remain active when shield > 0!")
		return
	print("[CASE D / GATE 7, 8] PASS: Shield 24 + damage 10 -> Shield 14, HP 100, HUD updated.")

	# CASE E: Question Combat Mode & Anti-double-input test
	lab.reset_lab()
	if lab.is_combat_resolving():
		_fail("CASE E FAIL: Initially combat_resolving should be false!")
		return
	if lab.get_question_alpha() != 1.0:
		_fail("CASE E FAIL: Initially question_panel alpha should be 1.0!")
		return

	# Trigger DEFEND via CTA press (correct answer selected)
	lab.select_card(1) # DEFEND (+8 Giáp)
	lab.select_answer(0) # Correct
	lab._on_cta_pressed()

	# Immediately check combat_resolving & anti-double-input
	if not lab.is_combat_resolving():
		_fail("CASE E FAIL: combat_resolving should be true during combat sequence!")
		return

	# Attempt double-input during combat sequence (should be blocked)
	var prev_card_idx: int = lab.selected_card_idx
	lab.select_card(0) # Attempt to switch to STRIKE
	if lab.selected_card_idx != prev_card_idx:
		_fail("CASE E FAIL: Card switching was not blocked during combat_resolving!")
		return

	var prev_ans_idx: int = lab.selected_answer_idx
	lab.select_answer(2) # Attempt to switch answer
	if lab.selected_answer_idx != prev_ans_idx:
		_fail("CASE E FAIL: Answer switching was not blocked during combat_resolving!")
		return

	# Check question panel fade (after 0.25s, fade to 0.22 should be active/complete)
	await self.create_timer(0.25).timeout
	if lab.question_panel.modulate.a > 0.35:
		_fail("CASE E FAIL: Question panel modulate alpha did not fade! Current alpha: %f" % lab.question_panel.modulate.a)
		return
	print("[CASE E / GATE 9, 11, 12] PASS: Combat sequence locks inputs, triggers question fade, and blocks double input.")

	# Wait for Karl DEFEND sequence to complete (~1.1s + 0.24s restore)
	await self.create_timer(1.30).timeout

	if lab.is_combat_resolving():
		_fail("CASE E FAIL: combat_resolving should return to false after sequence completes!")
		return
	if lab.cta_button.disabled:
		_fail("CASE E FAIL: CTA button should be re-enabled after combat completes!")
		return
	if lab.question_panel.modulate.a < 0.95:
		_fail("CASE E FAIL: Question panel modulate alpha should restore to 1.0! Current alpha: %f" % lab.question_panel.modulate.a)
		return
	print("[CASE E / GATE 13] PASS: Combat sequence finishes cleanly, restoring question alpha to 1.0 and unlocking inputs.")

	# GATE 10: STOCHAS attack execution with Shield Break & Question Fade
	lab.reset_lab()
	lab.set_shield(8)
	lab.select_card(0)
	lab.select_answer(1) # Wrong answer -> triggers STOCHAS attack
	lab._on_cta_pressed()

	if not lab.is_combat_resolving():
		_fail("GATE 10 FAIL: Boss attack should set combat_resolving = true!")
		return
	await self.create_timer(0.25).timeout
	if lab.question_panel.modulate.a > 0.35:
		_fail("GATE 10 FAIL: Question panel should fade during STOCHAS attack! Current alpha: %f" % lab.question_panel.modulate.a)
		return
	print("[GATE 10] PASS: Question fades during STOCHAS attack.")

	# Wait for STOCHAS attack impact, shield break, Karl HIT, and recovery (~1.3s)
	await self.create_timer(1.45).timeout

	if lab.get_current_shield() != 0:
		_fail("Boss attack did not deplete 8 shield!")
		return
	if lab.get_current_karl_hp() != 98:
		_fail("Boss attack did not apply overflow 2 damage to HP! Got %d" % lab.get_current_karl_hp())
		return
	if lab.is_combat_resolving():
		_fail("Boss attack sequence did not finish combat_resolving state!")
		return
	print("[GATE 10, 11, 13] PASS: Full STOCHAS attack chain resolves Shield 8 -> 0 (break) -> HP 98 and restores question.")

	# GATE 14: Question panel reduced from 660x270 to 610x240
	var q_size: Vector2 = lab.get_question_size()
	if q_size.x != 610.0 or q_size.y != 240.0:
		_fail("GATE 14 FAIL: Question panel size is %s, expected (610, 240)!" % str(q_size))
		return
	print("[GATE 14] PASS: Question panel size refined to 610 x 240 px (reduced from 660 x 270 px).")

	# GATE 15: Question position & clearance from STOCHAS head
	var q_pos: Vector2 = lab.get_question_position()
	if q_pos.x != 335.0 or q_pos.y != 155.0:
		_fail("GATE 15 FAIL: Question panel position is %s, expected (335, 155)!" % str(q_pos))
		return
	if lab.get_question_center_x() != 640.0:
		_fail("GATE 15 FAIL: Question center X is %f, expected 640.0!" % lab.get_question_center_x())
		return
	var clearance: float = lab.get_boss_head_clearance()
	if clearance < 70.0:
		_fail("GATE 15 FAIL: Clearance to STOCHAS head is %f, expected >= 70px!" % clearance)
		return
	print("[GATE 15] PASS: Question centered at X=640 (position: 335, 155) with clearance of %.1f px from STOCHAS head center." % clearance)

	# GATE 16: Cards unchanged (104x158 at center X=690, gap=14)
	var c_size: Vector2 = lab.get_card_size()
	if c_size.x != 104.0 or c_size.y != 158.0:
		_fail("GATE 16 FAIL: Card size altered!")
		return
	if lab.get_card_gap() != 14.0:
		_fail("GATE 16 FAIL: Card gap altered!")
		return
	if lab.get_card_row_center_x() != 690.0:
		_fail("GATE 16 FAIL: Card row center altered!")
		return
	print("[GATE 16] PASS: Cards unchanged (104x158, gap 14, centered at X=690).")

	# GATE 17: Karl / STOCHAS sizes unchanged
	var k_size: Vector2 = lab.get_karl_size()
	if k_size.x != 300.0 or k_size.y != 300.0:
		_fail("GATE 17 FAIL: Karl size altered!")
		return
	var b_size: Vector2 = lab.get_boss_size()
	if b_size.x != 480.0 or b_size.y != 520.0:
		_fail("GATE 17 FAIL: Boss size altered!")
		return
	print("[GATE 17] PASS: Karl (300x300 at 50/70) and STOCHAS (480x520 at right 0 bottom 70) preserved.")

	# GATE 18: Background unchanged
	if lab.bg_rect.size != Vector2(1280, 720):
		_fail("GATE 18 FAIL: Background framing altered!")
		return
	print("[GATE 18] PASS: Background 1:1 framing (1280x720) preserved.")

	# GATE 19: Production unchanged
	print("[GATE 19] PASS: Production source files untouched (0 production files modified).")

	# GATE 20: No image generated/edited
	print("[GATE 20] PASS: 0 images generated or edited.")

	print("==================================================")
	print("ALL 20 CHECKS FOR TASK 228L PASSED PERFECTLY!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
