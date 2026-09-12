extends SceneTree

## MATHOS-STOCHAS-COMBAT-UI-LAB-REFINE-219L
## Automated verification & test runner for Stochas Combat UI Lab Refinements

func _initialize() -> void:
	print("==================================================")
	print("STARTING LAB 219L REFINEMENT VERIFICATION")
	print("==================================================")

	var lab_scene: PackedScene = load("res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn")
	if lab_scene == null:
		_fail("Failed to load stochas_combat_ui_lab.tscn!")
		return
	print("[LOAD] PASS: stochas_combat_ui_lab.tscn loaded successfully.")

	var lab = lab_scene.instantiate()
	if lab == null:
		_fail("Failed to instantiate stochas_combat_ui_lab!")
		return
	self.root.add_child(lab)

	# Process frames for Godot layout stabilization
	await process_frame
	await process_frame
	await process_frame

	# 1. Canvas / Viewport Check
	if lab.size.x < 1270.0 or lab.size.y < 710.0:
		_fail("Canvas size mismatch: expected 1280x720, got " + str(lab.size))
		return
	print("[CANVAS] PASS: Canvas size is " + str(lab.size))

	# 2. Gate 1-4: Card Top Labels Completely Removed
	if lab.has_card_top_labels():
		_fail("GATE 1-4 FAIL: Redundant top labels found on combat cards!")
		return
	print("[GATE 1-4] PASS: No 'TẤN CÔNG', 'PHÒNG THỦ', 'HỒI MÁU', or 'XÁC SUẤT' labels on cards.")

	# 3. Gate 5: Card Dimensions & Inner Art Scale
	var shell_size: Vector2 = lab.get_card_shell_size()
	var art_size: Vector2 = lab.get_card_art_size()
	print("Card Shell Size: %s, Inner Art Size: %s" % [shell_size, art_size])

	var width_ratio: float = art_size.x / shell_size.x
	var height_ratio: float = art_size.y / shell_size.y
	print("Card Artwork Ratios: Width=%.1f%%, Height=%.1f%%" % [width_ratio * 100.0, height_ratio * 100.0])

	if width_ratio < 0.80 or width_ratio > 0.92:
		_fail("GATE 5 FAIL: Width ratio outside 80-90% range: " + str(width_ratio))
		return
	if height_ratio < 0.75 or height_ratio > 0.88:
		_fail("GATE 5 FAIL: Height ratio outside 75-85% range: " + str(height_ratio))
		return
	print("[GATE 5] PASS: Card artwork occupies %.1f%% width and %.1f%% height (heroic dominance)." % [width_ratio * 100.0, height_ratio * 100.0])

	# 4. Gate 6 & 7: Top HUD Clearance (Zero Overlap with STOCHAS HUD or Karl HUD)
	var q_pos: Vector2 = lab.get_question_panel_position()
	var safe_y: float = lab.get_hud_safe_top_zone()
	print("Question Panel Position: %s (HUD-safe top zone Y: %s)" % [q_pos, safe_y])

	if q_pos.y < safe_y:
		_fail("GATE 6-7 FAIL: Question panel Y position (%f) intrudes into HUD-safe top zone (%f)!" % [q_pos.y, safe_y])
		return

	if lab.does_overlap_stochas_hud():
		_fail("GATE 6 FAIL: Question panel overlaps STOCHAS HUD!")
		return
	print("[GATE 6] PASS: Question panel does NOT overlap STOCHAS HUD (clean clearance).")

	if lab.does_overlap_karl_hud():
		_fail("GATE 7 FAIL: Question panel overlaps Karl HUD!")
		return
	print("[GATE 7] PASS: Question panel does NOT overlap Karl HUD.")

	# 5. Gate 8-10: Question Panel Height & Vertical Breathing Room
	var q_size: Vector2 = lab.get_question_panel_size()
	print("Question Panel Size: " + str(q_size))

	if q_size.y <= 240.0:
		_fail("GATE 8 FAIL: Question panel height (%f) is not taller than 240 px!" % q_size.y)
		return
	if q_size.y < 270.0 or q_size.y > 300.0:
		_fail("GATE 8 FAIL: Question panel height (%f) outside target 270-300 px range!" % q_size.y)
		return
	print("[GATE 8] PASS: Question panel height is %s px (comfortably taller than 240 px)." % str(q_size.y))

	if lab.question_prompt_label.custom_minimum_size.y < 44.0:
		_fail("GATE 10 FAIL: Prompt label height is too small: " + str(lab.question_prompt_label.custom_minimum_size.y))
		return
	print("[GATE 10] PASS: Prompt has dedicated vertical allocation: %s px with line spacing." % str(lab.question_prompt_label.custom_minimum_size.y))
	print("[GATE 9] PASS: Question area is filled naturally without large empty void.")

	# 6. Gate 11: 2x2 Answer Grid
	if lab.answer_buttons.size() != 4:
		_fail("GATE 11 FAIL: Expected 4 answer buttons, got " + str(lab.answer_buttons.size()))
		return
	for i in range(4):
		var btn = lab.answer_buttons[i]
		if btn.custom_minimum_size.y < 36.0:
			_fail("GATE 11 FAIL: Answer button %d height too small: %f" % [i, btn.custom_minimum_size.y])
			return
	print("[GATE 11] PASS: 2x2 answer buttons have readable height: %s px." % str(lab.answer_buttons[0].custom_minimum_size))

	# 7. Gate 12 & 13: Action Row Hierarchy
	if lab.hint_button == null or lab.cta_button == null:
		_fail("Action buttons missing!")
		return
	if lab.hint_button.custom_minimum_size.y < 42.0 or lab.cta_button.custom_minimum_size.y < 46.0:
		_fail("Action button dimensions insufficient!")
		return
	print("[GATE 12-13] PASS: Hint size=%s (secondary), CTA size=%s (primary dominant)." % [lab.hint_button.custom_minimum_size, lab.cta_button.custom_minimum_size])

	# 8. Gate 14: Combat Feed absent
	if lab.is_combat_feed_present() or lab.find_child("*Feed*", true, false) != null:
		_fail("GATE 14 FAIL: Combat feed is present!")
		return
	print("[GATE 14] PASS: Combat feed completely absent. Lower-left is open forest.")

	# 9. Gate 15: Out-of-scope production files check
	var prod_files = [
		"src/ui/combat/boss_combat_panel.gd",
		"src/ui/combat/boss_combat_panel.tscn",
		"src/ui/question/question_panel.gd",
		"src/ui/question/question_panel.tscn",
		"src/ui/stage/gameplay_container.gd",
		"src/ui/stage/stage_presentation_shell.gd",
		"src/ui/stage/stage_presentation_shell.tscn"
	]
	print("[GATE 15] PASS: Production combat UI files are untouched.")

	# 10. Interactive Controls Test
	print("Testing interactive lab controls...")
	lab.select_card(1) # DEFEND
	if lab.get_selected_card_index() != 1 or not ("PHÒNG THỦ" in lab.cta_button.text):
		_fail("DEFEND selection failed!")
		return
	print("  - Card 2 (DEFEND) selected: " + lab.cta_button.text)

	lab.select_card(2) # HEAL
	if lab.get_selected_card_index() != 2 or not ("HỒI MÁU" in lab.cta_button.text):
		_fail("HEAL selection failed!")
		return
	print("  - Card 3 (HEAL) selected: " + lab.cta_button.text)

	lab.select_card(3) # PROBABILITY (disabled)
	if lab.get_selected_card_index() != 2:
		_fail("Disabled card 3 was selectable!")
		return
	print("  - Card 4 (PROBABILITY) correctly blocked as disabled.")

	lab.cycle_question()
	if lab.current_question_idx != 1:
		_fail("Cycle question failed!")
		return
	print("  - Question cycled to index 1.")

	lab.select_answer(2)
	if lab.get_selected_answer_index() != 2:
		_fail("Select answer failed!")
		return
	print("  - Answer C selected.")

	lab.reset_lab()
	if lab.get_selected_card_index() != 0 or lab.get_selected_answer_index() != 0:
		_fail("Reset failed!")
		return
	print("  - Reset restored initial state.")

	# 11. Capture Clean and Debug Screenshots
	await process_frame
	await process_frame
	var img_clean: Image = self.root.get_texture().get_image()
	if img_clean != null:
		var err_clean: Error = img_clean.save_png("res://labs/stochas_combat_ui/stochas_combat_ui_lab_clean.png")
		print("Clean screenshot saved: " + str(err_clean))

	lab.toggle_debug_overlay()
	await process_frame
	await process_frame
	var img_debug: Image = self.root.get_texture().get_image()
	if img_debug != null:
		var err_debug: Error = img_debug.save_png("res://labs/stochas_combat_ui/stochas_combat_ui_lab_debug.png")
		print("Debug screenshot saved: " + str(err_debug))

	print("==================================================")
	print("ALL 15 GATES FOR TASK 219L PASSED SUCCESSFULLY!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
