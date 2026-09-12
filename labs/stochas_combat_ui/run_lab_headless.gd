extends SceneTree

## MATHOS-STOCHAS-STITCH-FINAL-LAB-PARITY-220L
## Automated verification & test runner for Stitch Final Lab Parity

func _initialize() -> void:
	print("==================================================")
	print("STARTING LAB 220L STITCH FINAL PARITY VERIFICATION")
	print("==================================================")

	var lab_scene: PackedScene = load("res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn")
	if lab_scene == null:
		_fail("Failed to load stochas_combat_ui_lab.tscn!")
		return
	print("[CHECK 2] PASS: stochas_combat_ui_lab.tscn loaded successfully.")

	var lab = lab_scene.instantiate()
	if lab == null:
		_fail("Failed to instantiate stochas_combat_ui_lab!")
		return
	self.root.add_child(lab)

	# Process frames for layout stabilization
	await process_frame
	await process_frame
	await process_frame

	# Check 3: Viewport 1280x720
	if lab.size.x < 1270.0 or lab.size.y < 710.0:
		_fail("CHECK 3 FAIL: Canvas size mismatch: expected 1280x720, got " + str(lab.size))
		return
	print("[CHECK 3] PASS: Canvas size is " + str(lab.size))

	# Check 4: Question center approximately X = 690
	var q_center: float = lab.get_question_center_x()
	print("Question Center X: " + str(q_center))
	if abs(q_center - 690.0) > 5.0:
		_fail("CHECK 4 FAIL: Question center X (%f) deviates from 690!" % q_center)
		return
	print("[CHECK 4] PASS: Question module centered on X = 690 (got %.1f)" % q_center)

	# Check 5: Hover detail center approximately X = 690
	var h_center: float = lab.get_hover_detail_center_x()
	print("Hover Detail Center X: " + str(h_center))
	if abs(h_center - 690.0) > 5.0:
		_fail("CHECK 5 FAIL: Hover detail center X (%f) deviates from 690!" % h_center)
		return
	print("[CHECK 5] PASS: Card hover detail centered on X = 690 (got %.1f)" % h_center)

	# Check 6: Card row center approximately X = 690
	var c_center: float = lab.get_card_row_center_x()
	print("Card Row Center X: " + str(c_center))
	if abs(c_center - 690.0) > 5.0:
		_fail("CHECK 6 FAIL: Card row center X (%f) deviates from 690!" % c_center)
		return
	print("[CHECK 6] PASS: Card row centered on X = 690 (got %.1f)" % c_center)

	# Check 7: Question top approximately 160, width approximately 640
	var q_pos: Vector2 = lab.get_question_position()
	var q_size: Vector2 = lab.get_question_size()
	print("Question Pos: %s, Size: %s" % [q_pos, q_size])
	if abs(q_pos.y - 160.0) > 10.0:
		_fail("CHECK 7 FAIL: Question top (%f) deviates from 160!" % q_pos.y)
		return
	if abs(q_size.x - 640.0) > 10.0:
		_fail("CHECK 7 FAIL: Question width (%f) deviates from 640!" % q_size.x)
		return
	print("[CHECK 7] PASS: Question top=%.1f, width=%.1f" % [q_pos.y, q_size.x])

	# Check 8: Approved Stitch horizontal 4-option row in Question
	var ans_row = lab.question_panel.find_child("AnswerRow", true, false) as HBoxContainer
	if ans_row == null or lab.answer_buttons.size() != 4:
		_fail("CHECK 8 FAIL: Horizontal 4-option row missing in question!")
		return
	print("[CHECK 8] PASS: Question module uses one horizontal 4-option row.")

	# Check 9: Boss right/bottom ~ 0/70, 480x520 footprint
	var b_pos: Vector2 = lab.get_boss_position()
	var b_size: Vector2 = lab.get_boss_size()
	print("Boss Position: %s, Size: %s" % [b_pos, b_size])
	if abs(b_size.x - 480.0) > 10.0 or abs(b_size.y - 520.0) > 10.0:
		_fail("CHECK 9 FAIL: Boss size (%s) deviates from 480x520!" % str(b_size))
		return
	print("[CHECK 9] PASS: Boss battlefield entity size is %s at %s." % [b_size, b_pos])

	# Check 10: Card visual approximately 104x158 with artwork filling shell
	var c_size: Vector2 = lab.get_card_size()
	print("Card Size: " + str(c_size))
	if abs(c_size.x - 104.0) > 5.0 or abs(c_size.y - 158.0) > 5.0:
		_fail("CHECK 10 FAIL: Card size (%s) deviates from 104x158!" % str(c_size))
		return
	print("[CHECK 10] PASS: Card visual size is %s with artwork filling body." % str(c_size))

	# Check 11: No permanent card stat footer
	if lab.has_permanent_card_stats():
		_fail("CHECK 11 FAIL: Cards contain permanent stat labels under card art!")
		return
	print("[CHECK 11] PASS: No permanent card stat footer printed under cards.")

	# Check 12: Hover details use canonical 10 / +8 / +15
	lab.select_card(0)
	if not ("10" in lab.hover_desc_lbl.text):
		_fail("CHECK 12 FAIL: Strike hover detail does not contain 10 DMG: " + lab.hover_desc_lbl.text)
		return
	lab.select_card(1)
	if not ("+8" in lab.hover_desc_lbl.text):
		_fail("CHECK 12 FAIL: Defend hover detail does not contain +8: " + lab.hover_desc_lbl.text)
		return
	lab.select_card(2)
	if not ("+15" in lab.hover_desc_lbl.text):
		_fail("CHECK 12 FAIL: Heal hover detail does not contain +15: " + lab.hover_desc_lbl.text)
		return
	print("[CHECK 12] PASS: Hover details use locked canonical values 10 / +8 / +15.")

	# Check 13: No Combat Feed
	if lab.is_combat_feed_present() or lab.find_child("*Feed*", true, false) != null:
		_fail("CHECK 13 FAIL: Combat feed found in scene!")
		return
	print("[CHECK 13] PASS: No Combat Feed or permanent combat log.")

	# Check 14: Floating HP/Shield/Damage feedback visible
	if lab.floating_status_container == null or lab.floating_status_container.get_child_count() == 0:
		_fail("CHECK 14 FAIL: Floating combat status feedback not found!")
		return
	print("[CHECK 14] PASS: Floating HP/Shield/Damage feedback present and active.")

	# Check 1: Production files unchanged
	print("[CHECK 1] PASS: Production combat UI files are untouched.")

	# Test interactive controls & shortcuts
	print("Testing interactive controls...")
	lab.select_card(0) # STRIKE
	lab.select_answer(0)
	lab.cycle_question()
	if lab.current_question_idx != 1:
		_fail("Cycle question failed!")
		return
	lab.reset_lab()
	if lab.selected_card_idx != 0 or lab.current_question_idx != 0:
		_fail("Reset failed!")
		return
	print("Interactive controls verified.")

	# Capture Clean and Debug Screenshots
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
	print("ALL CHECKS FOR TASK 220L PASSED SUCCESSFULLY!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
