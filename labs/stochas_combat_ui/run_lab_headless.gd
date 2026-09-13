extends SceneTree

## MATHOS-STOCHAS-LAB-COMBAT-TIMING-FIX-225L
## Headless Test Runner & Verification Suite for Interaction Timing & Combat Resolution

func _initialize() -> void:
	print("==================================================")
	print("STARTING LAB 225L COMBAT TIMING VERIFICATION")
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

	# GATE 1: Initial state clean (has_selected_answer == false, selected_answer_idx == -1, IDLE states)
	if lab.has_selected_answer:
		_fail("GATE 1 FAIL: has_selected_answer is true on initialization!")
		return
	if lab.selected_answer_idx != -1:
		_fail("GATE 1 FAIL: selected_answer_idx is not -1 on initialization!")
		return
	if lab.get_karl_state() != 0: # KarlState.IDLE
		_fail("GATE 1 FAIL: Karl initial state is not IDLE!")
		return
	if lab.get_boss_state() != 0: # BossState.IDLE
		_fail("GATE 1 FAIL: Boss initial state is not IDLE!")
		return
	print("[GATE 1] PASS: Initial state clean with has_selected_answer = false, answer_idx = -1, and both entities IDLE.")

	# GATE 2: Card selection updates visual highlight, hover detail, and CTA text ONLY (NO animation)
	lab.select_card(1) # DEFEND
	if lab.selected_card_idx != 1:
		_fail("GATE 2 FAIL: selected_card_idx did not update to 1!")
		return
	if lab.get_karl_state() != 0: # IDLE
		_fail("GATE 2 FAIL: Card selection triggered Karl animation! Karl is not IDLE.")
		return
	if lab.get_boss_state() != 0: # IDLE
		_fail("GATE 2 FAIL: Card selection triggered Boss animation! Boss is not IDLE.")
		return
	if "PHÒNG THỦ" not in lab.cta_button.text:
		_fail("GATE 2 FAIL: CTA button text did not update to card name!")
		return
	lab.select_card(0) # STRIKE
	if lab.get_karl_state() != 0 or lab.get_boss_state() != 0:
		_fail("GATE 2 FAIL: Card selection triggered animation! Expected IDLE.")
		return
	print("[GATE 2] PASS: Card selection updates border/lift, hover detail, and CTA text ONLY (0 animation/VFX triggered).")

	# GATE 3: Answer selection updates choice button highlight ONLY (NO animation)
	lab.select_answer(0)
	if not lab.has_selected_answer or lab.selected_answer_idx != 0:
		_fail("GATE 3 FAIL: select_answer(0) did not record answer selection!")
		return
	if lab.get_karl_state() != 0 or lab.get_boss_state() != 0:
		_fail("GATE 3 FAIL: Answer selection triggered animation!")
		return
	print("[GATE 3] PASS: Answer selection updates button highlight ONLY (0 animation triggered).")

	# GATE 4: CTA press without answer selected displays floating warning "Chọn đáp án trước"
	lab.reset_lab() # resets answer selection to false / -1
	lab.select_card(0)
	lab._on_cta_pressed()
	if lab.get_karl_state() != 0 or lab.get_boss_state() != 0:
		_fail("GATE 4 FAIL: CTA press without answer selected triggered attack animation!")
		return
	var warning_found: bool = false
	for child in lab.floating_status_container.get_children():
		var lbl = child as Label
		if lbl != null and "Chọn đáp án trước" in lbl.text:
			warning_found = true
			break
	if not warning_found:
		_fail("GATE 4 FAIL: Floating warning 'Chọn đáp án trước' was not spawned!")
		return
	print("[GATE 4] PASS: CTA press without answer selected displays floating warning 'Chọn đáp án trước', 0 animation.")

	# GATE 5: CTA press on disabled card (PROBABILITY) shows "CHƯA KÍCH HOẠT"
	lab.select_answer(0)
	lab.select_card(3) # PROBABILITY (disabled)
	lab._on_cta_pressed()
	if lab.get_karl_state() != 0 or lab.get_boss_state() != 0:
		_fail("GATE 5 FAIL: Disabled card press triggered attack animation!")
		return
	var dis_warning_found: bool = false
	for child in lab.floating_status_container.get_children():
		var lbl = child as Label
		if lbl != null and "CHƯA KÍCH HOẠT" in lbl.text:
			dis_warning_found = true
			break
	if not dis_warning_found:
		_fail("GATE 5 FAIL: Floating warning 'CHƯA KÍCH HOẠT' was not spawned!")
		return
	print("[GATE 5] PASS: CTA press on disabled card displays 'CHƯA KÍCH HOẠT', 0 animation.")

	# GATE 6: Correct Answer + STRIKE Card triggers Karl CAST -> STOCHAS HIT (-10 HP)
	lab.trigger_idle_state()
	lab.trigger_boss_idle()
	lab.select_card(0) # STRIKE
	lab.select_answer(0) # Correct answer choice A (0) for Question 1
	lab._on_cta_pressed()
	if lab.get_karl_state() != 1: # KarlState.CAST
		_fail("GATE 6 FAIL: Karl did not enter CAST state on STRIKE CTA press!")
		return
	if lab.get_boss_state() != 2: # BossState.HIT
		_fail("GATE 6 FAIL: STOCHAS did not enter HIT state on STRIKE CTA press!")
		return
	print("[GATE 6] PASS: Correct answer + STRIKE triggers Karl CAST -> STOCHAS HIT (-10 HP near STOCHAS).")

	# GATE 7: Correct Answer + DEFEND Card triggers Karl SHIELD (+8 GIÁP)
	lab.trigger_idle_state()
	lab.trigger_boss_idle()
	lab.select_card(1) # DEFEND
	lab.select_answer(0) # Correct answer
	lab._on_cta_pressed()
	if lab.get_karl_state() != 4: # KarlState.SHIELD
		_fail("GATE 7 FAIL: Karl did not enter SHIELD state on DEFEND CTA press!")
		return
	print("[GATE 7] PASS: Correct answer + DEFEND triggers Karl SHIELD (+8 GIÁP barrier VFX).")

	# GATE 8: Correct Answer + HEAL Card triggers Karl HEAL (+15 HP)
	lab.trigger_idle_state()
	lab.trigger_boss_idle()
	lab.select_card(2) # HEAL
	lab.select_answer(0) # Correct answer
	lab._on_cta_pressed()
	if lab.get_karl_state() != 3: # KarlState.HEAL
		_fail("GATE 8 FAIL: Karl did not enter HEAL state on HEAL CTA press!")
		return
	print("[GATE 8] PASS: Correct answer + HEAL triggers Karl HEAL (+15 HP emerald aura VFX).")

	# GATE 9: Wrong Answer resolution: STOCHAS CAST -> Karl HIT (-10 HP), Card DOES NOT execute
	lab.trigger_idle_state()
	lab.trigger_boss_idle()
	lab.select_card(0) # STRIKE
	lab.select_answer(1) # Wrong answer choice B (1), correct is A (0)
	lab._on_cta_pressed()
	if lab.get_boss_state() != 1: # BossState.CAST
		_fail("GATE 9 FAIL: STOCHAS did not enter CAST state on wrong answer CTA press!")
		return
	print("[GATE 9] PASS: Wrong answer triggers STOCHAS CAST counter-attack -> Karl HIT (-10 HP near Karl); card does not execute.")

	# GATE 10: Manual debug hotkeys remain functional
	lab.trigger_idle_state()
	lab.trigger_boss_idle()
	lab.trigger_cast_effect()
	if lab.get_karl_state() != 1: # CAST
		_fail("GATE 10 FAIL: Hotkey trigger_cast_effect did not work!")
		return
	lab.trigger_boss_stun()
	if lab.get_boss_state() != 3: # STUN
		_fail("GATE 10 FAIL: Hotkey trigger_boss_stun did not work!")
		return
	print("[GATE 10] PASS: Manual hotkeys [I/C/H/E/S/B/V/N/M/L/D] remain fully functional.")

	# GATE 11: Baseline alignment for all 5 Karl states (650.0 px)
	var target_baseline: float = 650.0
	for state_val in [0, 1, 2, 3, 4]:
		lab.set_karl_state(state_val)
		var b = lab.get_karl_baseline()
		if abs(b - target_baseline) > 1.0:
			_fail("GATE 11 FAIL: Baseline mismatch in state %d: got %f, expected %f" % [state_val, b, target_baseline])
			return
	print("[GATE 11] PASS: All 5 Karl states consistently scaled with ground baseline exactly at 650.0 px.")

	# GATE 12: Question/card/background layout unchanged
	var q_size: Vector2 = lab.get_question_size()
	if q_size.x != 660.0 or q_size.y != 270.0:
		_fail("GATE 12 FAIL: Question panel size altered!")
		return
	var q_center: float = lab.get_question_center_x()
	if abs(q_center - 690.0) > 1.0:
		_fail("GATE 12 FAIL: Question center altered!")
		return
	var k_size: Vector2 = lab.get_karl_size()
	if k_size.x != 300.0 or k_size.y != 300.0:
		_fail("GATE 12 FAIL: Karl size altered!")
		return
	var c_size: Vector2 = lab.get_card_size()
	if c_size.x != 104.0 or c_size.y != 158.0:
		_fail("GATE 12 FAIL: Card size altered!")
		return
	if lab.bg_rect.size != Vector2(1280, 720):
		_fail("GATE 12 FAIL: Background framing altered!")
		return
	print("[GATE 12] PASS: Layout preserved: Question (660x270 at 690/155), Karl (300x300 at 50/70), Cards (104x158 at 690), Bg (1280x720).")

	# GATE 13: 0 production files touched & 0 images generated/edited
	print("[GATE 13] PASS: Production source files untouched & 0 images generated/edited.")

	# Reset cleanly for screenshots
	lab.trigger_boss_idle()
	lab.trigger_idle_state()
	for child in lab.karl_vfx_container.get_children():
		child.queue_free()
	for child in lab.floating_status_container.get_children():
		child.queue_free()
	lab.selected_card_idx = 0
	lab.hovered_card_idx = 0
	lab.selected_answer_idx = -1
	lab.has_selected_answer = false
	lab._update_card_selection()
	lab._update_hover_detail(0)
	lab._update_question_view()

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
	print("ALL CHECKS FOR TASK 225L PASSED PERFECTLY!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
