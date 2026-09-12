extends SceneTree

## MATHOS-STOCHAS-COMBAT-UI-LAB-218L
## Headless verification & test runner for Stochas Combat UI Lab

func _initialize() -> void:
	print("==================================================")
	print("STARTING LAB 218L HEADLESS VERIFICATION")
	print("==================================================")

	var lab_scene: PackedScene = load("res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn")
	if lab_scene == null:
		_fail("Failed to load stochas_combat_ui_lab.tscn!")
		return
	print("[GATE 2] PASS: stochas_combat_ui_lab.tscn loaded successfully.")

	var lab = lab_scene.instantiate()
	if lab == null:
		_fail("Failed to instantiate stochas_combat_ui_lab!")
		return
	self.root.add_child(lab)

	# Process frames for Godot layout stabilization
	await process_frame
	await process_frame
	await process_frame

	# 1. Verify Viewport / Canvas
	if lab.size.x < 1270.0 or lab.size.y < 710.0:
		_fail("Canvas size mismatch: expected 1280x720, got " + str(lab.size))
		return
	print("[CANVAS] PASS: Canvas size is " + str(lab.size))

	# 2. Verify Real Assets & Nodes
	var bg: TextureRect = lab.get_node_or_null("Background") as TextureRect
	if bg == null or bg.texture == null:
		_fail("Background TextureRect missing or has no texture!")
		return
	print("[GATE 12] PASS: D1 Misty forest background loaded: " + str(bg.texture.resource_path))

	var boss: TextureRect = lab.get_node_or_null("StochasBossRender") as TextureRect
	if boss == null or boss.texture == null:
		_fail("STOCHAS Boss render missing or has no texture!")
		return
	print("[GATE 11] PASS: STOCHAS boss render loaded: " + str(boss.texture.resource_path))

	var karl_port: TextureRect = lab.karl_portrait_rect
	if karl_port == null or karl_port.texture == null:
		_fail("Karl portrait missing or has no texture!")
		return
	print("[GATE 11] PASS: Karl portrait loaded: " + str(karl_port.texture.resource_path))

	# 3. Verify Card Dimensions and Inner Artwork
	var shell_size: Vector2 = lab.get_card_shell_size()
	var art_size: Vector2 = lab.get_card_art_size()
	print("Card Shell Size: %s, Inner Art Size: %s" % [shell_size, art_size])

	# Check Gate 3: Card outer shell compact (~135-145 x ~195-205)
	if shell_size.x < 130.0 or shell_size.x > 150.0 or shell_size.y < 190.0 or shell_size.y > 210.0:
		_fail("GATE 3 FAIL: Card shell size not compact: " + str(shell_size))
		return
	print("[GATE 3] PASS: Card outer shell is compact: " + str(shell_size))

	# Check Gate 4: Inner artwork significantly larger (~115-130 x ~150-175)
	if art_size.x < 115.0 or art_size.x > 135.0 or art_size.y < 145.0 or art_size.y > 180.0:
		_fail("GATE 4 FAIL: Inner artwork dimensions outside target: " + str(art_size))
		return
	print("[GATE 4] PASS: Inner artwork is large and heroic: " + str(art_size))

	# Check Gate 5: Artwork dominates card body (80-90% width, 75-85% height)
	var width_ratio: float = art_size.x / shell_size.x
	var height_ratio: float = art_size.y / shell_size.y
	print("Card Artwork Ratios: Width=%.1f%%, Height=%.1f%%" % [width_ratio * 100.0, height_ratio * 100.0])
	if width_ratio < 0.78 or width_ratio > 0.95:
		_fail("GATE 5 FAIL: Width ratio outside 80-90% range: " + str(width_ratio))
		return
	if height_ratio < 0.72 or height_ratio > 0.88:
		_fail("GATE 5 FAIL: Height ratio outside 75-85% range: " + str(height_ratio))
		return
	print("[GATE 5] PASS: Artwork dominates card body (Width: %.1f%%, Height: %.1f%%)" % [width_ratio * 100.0, height_ratio * 100.0])

	# 4. Verify Combat Feed completely absent
	if lab.is_combat_feed_present():
		_fail("GATE 6 FAIL: Combat feed is reported present!")
		return
	var feed_node = lab.find_child("*Feed*", true, false)
	if feed_node != null:
		_fail("GATE 6 FAIL: Found feed node in lab: " + feed_node.name)
		return
	print("[GATE 6] PASS: Combat Feed is completely absent. Lower-left is open forest.")

	# 5. Verify Question Panel Footprint & Structure
	var q_size: Vector2 = lab.get_question_panel_size()
	print("Question Panel Size: " + str(q_size))
	if q_size.x < 600.0 or q_size.x > 700.0 or q_size.y < 200.0 or q_size.y > 270.0:
		_fail("GATE 7 FAIL: Question panel size outside 620-680 x 210-250 range: " + str(q_size))
		return
	print("[GATE 7] PASS: Question panel footprint is tight and filled: " + str(q_size))

	# Gate 8: No weird horizontal bar/scroll
	var scroll = lab.find_child("*Scroll*", true, false)
	if scroll != null:
		_fail("GATE 8 FAIL: Found ScrollContainer in Question Panel!")
		return
	print("[GATE 8] PASS: No horizontal bar or scrollbar present.")

	# Gate 9: Answer interaction visually explicit (2x2 grid with 4 options)
	if lab.answer_buttons.size() != 4:
		_fail("GATE 9 FAIL: Expected 4 answer buttons, got " + str(lab.answer_buttons.size()))
		return
	for i in range(4):
		if lab.answer_buttons[i].text.is_empty():
			_fail("GATE 9 FAIL: Answer button %d text is empty!" % i)
			return
	print("[GATE 9] PASS: Answer interaction is visually explicit with 4 options.")

	# Gate 10: Question / Hint / CTA hierarchy is clear
	if lab.hint_button == null or lab.cta_button == null:
		_fail("GATE 10 FAIL: Hint or CTA button missing!")
		return
	print("[GATE 10] PASS: Hierarchy clear. Hint button size: %s, CTA button size: %s" % [lab.hint_button.custom_minimum_size, lab.cta_button.custom_minimum_size])

	# 6. Test Interactive Lab Controls
	print("Testing interactive lab controls...")
	# Select DEFEND (index 1)
	lab.select_card(1)
	if lab.get_selected_card_index() != 1:
		_fail("Failed to select DEFEND card!")
		return
	if not ("PHÒNG THỦ" in lab.cta_button.text):
		_fail("CTA text did not update for DEFEND: " + lab.cta_button.text)
		return
	print("  - Card 2 (DEFEND) selected: CTA = " + lab.cta_button.text)

	# Select HEAL (index 2)
	lab.select_card(2)
	if lab.get_selected_card_index() != 2:
		_fail("Failed to select HEAL card!")
		return
	if not ("HỒI MÁU" in lab.cta_button.text):
		_fail("CTA text did not update for HEAL: " + lab.cta_button.text)
		return
	print("  - Card 3 (HEAL) selected: CTA = " + lab.cta_button.text)

	# Attempt select PROBABILITY (disabled, index 3) -> should not change selection
	lab.select_card(3)
	if lab.get_selected_card_index() != 2:
		_fail("Disabled card 3 was selectable!")
		return
	print("  - Card 4 (PROBABILITY) correctly blocked as disabled.")

	# Answer selection
	lab.select_answer(1)
	if lab.get_selected_answer_index() != 1:
		_fail("Failed to select answer 1!")
		return
	print("  - Answer B selected.")

	# Question cycle
	lab.cycle_question()
	if lab.current_question_idx != 1:
		_fail("Failed to cycle question!")
		return
	print("  - Question cycled to index 1: " + lab.question_stage_label.text)

	# Reset
	lab.reset_lab()
	if lab.get_selected_card_index() != 0 or lab.get_selected_answer_index() != 0 or lab.current_question_idx != 0:
		_fail("Reset failed to restore initial state!")
		return
	print("  - Reset restored initial state.")

	# Capture clean screenshot to disk for visual verification
	await process_frame
	await process_frame
	var img_clean: Image = self.root.get_texture().get_image()
	if img_clean != null:
		var err_clean: Error = img_clean.save_png("res://labs/stochas_combat_ui/stochas_combat_ui_lab_clean.png")
		print("Clean screenshot saved: " + str(err_clean))

	# Debug overlay toggle
	lab.toggle_debug_overlay()
	if not lab.debug_overlay.visible:
		_fail("Debug overlay did not become visible!")
		return
	print("  - Debug overlay toggle working.")

	# Capture debug screenshot to disk
	await process_frame
	await process_frame
	var img_debug: Image = self.root.get_texture().get_image()
	if img_debug != null:
		var err_debug: Error = img_debug.save_png("res://labs/stochas_combat_ui/stochas_combat_ui_lab_debug.png")
		print("Debug screenshot saved: " + str(err_debug))

	print("==================================================")
	print("ALL LAB 218L CHECKS PASSED SUCCESSFULLY!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
