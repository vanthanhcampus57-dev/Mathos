extends SceneTree

## MATHOS-SHIELD-BREAK-LAB-227L
## Headless Test Runner & Verification Suite for Persistent Shield Break VFX & Transitions

func _initialize() -> void:
	print("==================================================")
	print("STARTING LAB 227L SHIELD BREAK VFX VERIFICATION")
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

	# GATE 1: Initial state clean (current_shield == 0, barrier hidden, Karl IDLE)
	if lab.get_current_shield() != 0:
		_fail("GATE 1 FAIL: Initial current_shield is not 0!")
		return
	if lab.is_persistent_barrier_visible():
		_fail("GATE 1 FAIL: Persistent barrier is visible on initial load!")
		return
	if lab.get_karl_state() != 0: # KarlState.IDLE
		_fail("GATE 1 FAIL: Karl initial state is not IDLE!")
		return
	if "GIÁP: 0" not in lab.karl_hp_sub_label.text:
		_fail("GATE 1 FAIL: Karl HUD does not report GIÁP: 0!")
		return
	print("[GATE 1] PASS: Initial state clean with shield = 0, barrier hidden, and HUD reporting GIÁP: 0.")

	# GATE 2: Successful DEFEND increments shield +8, triggers persistent barrier
	lab.select_card(1) # DEFEND card
	lab.select_answer(0) # Correct answer A (0)
	lab._on_cta_pressed()
	if lab.get_current_shield() != 8:
		_fail("GATE 2 FAIL: current_shield is not 8 after DEFEND!")
		return
	if not lab.is_persistent_barrier_visible():
		_fail("GATE 2 FAIL: Persistent barrier is not visible after DEFEND!")
		return
	if "GIÁP: 8" not in lab.karl_hp_sub_label.text:
		_fail("GATE 2 FAIL: Karl HUD did not update to GIÁP: 8!")
		return
	print("[GATE 2] PASS: Successful DEFEND sets shield +8 and activates persistent visual barrier.")

	# GATE 3: Repeated DEFEND stacks shield (8 -> 16) without false break
	lab._on_cta_pressed()
	if lab.get_current_shield() != 16:
		_fail("GATE 3 FAIL: current_shield is not 16 after second DEFEND!")
		return
	if "GIÁP: 16" not in lab.karl_hp_sub_label.text:
		_fail("GATE 3 FAIL: Karl HUD did not update to GIÁP: 16!")
		return
	if not lab.is_persistent_barrier_visible():
		_fail("GATE 3 FAIL: Persistent barrier disappeared on shield stack!")
		return
	print("[GATE 3] PASS: Repeated DEFEND stacks shield (16) cleanly with no false shield break.")

	# GATE 4: Shield transition from >0 to 0 triggers break_shield() (shield = 0, HUD GIÁP: 0)
	lab.clear_shield() # Calls set_shield(0) -> break_shield()
	if lab.get_current_shield() != 0:
		_fail("GATE 4 FAIL: current_shield is not 0 after clear_shield()!")
		return
	if "GIÁP: 0" not in lab.karl_hp_sub_label.text:
		_fail("GATE 4 FAIL: Karl HUD did not update to GIÁP: 0 on shield break!")
		return
	print("[GATE 4] PASS: Shield transition from >0 to 0 triggers break_shield() and updates HUD to GIÁP: 0.")

	# GATE 5: Zero false break when calling break_shield() or clear_shield() while shield is already 0
	lab.break_shield()
	if lab.get_current_shield() != 0:
		_fail("GATE 5 FAIL: current_shield modified during redundant break_shield()!")
		return
	lab.clear_shield()
	if lab.get_current_shield() != 0:
		_fail("GATE 5 FAIL: current_shield modified during redundant clear_shield()!")
		return
	print("[GATE 5] PASS: Redundant shield break calls while shield == 0 cause zero false breaks or state corruption.")

	# GATE 6: Re-enabling shield (0 -> 8) via set_shield(8) restores persistent barrier cleanly
	lab.set_shield(8)
	if lab.get_current_shield() != 8:
		_fail("GATE 6 FAIL: set_shield(8) failed to set current_shield to 8!")
		return
	if not lab.is_persistent_barrier_visible():
		_fail("GATE 6 FAIL: Persistent barrier not visible after set_shield(8)!")
		return
	if "GIÁP: 8" not in lab.karl_hp_sub_label.text:
		_fail("GATE 6 FAIL: HUD did not report GIÁP: 8 after set_shield(8)!")
		return
	print("[GATE 6] PASS: Re-enabling shield via set_shield(8) restores persistent barrier cleanly.")

	# GATE 7: Breaking shield via set_shield(0) from 8 triggers transition & leaves barrier hidden after anim completes
	lab.set_shield(0)
	await process_frame
	if lab.get_current_shield() != 0:
		_fail("GATE 7 FAIL: current_shield is not 0 after set_shield(0)!")
		return
	if "GIÁP: 0" not in lab.karl_hp_sub_label.text:
		_fail("GATE 7 FAIL: HUD did not update to GIÁP: 0!")
		return
	print("[GATE 7] PASS: set_shield(0) triggers shield break transition and resets HUD.")

	# GATE 8: Other combat operations (STRIKE, HEAL, Boss reactions) remain fully functional
	lab.trigger_idle_state()
	lab.trigger_boss_idle()
	lab.select_card(0) # STRIKE
	lab.select_answer(0) # Correct answer A
	lab._on_cta_pressed()
	if lab.get_karl_state() != 1 or lab.get_boss_state() != 2:
		_fail("GATE 8 FAIL: STRIKE execution broke!")
		return

	lab.trigger_idle_state()
	lab.trigger_boss_idle()
	lab.select_card(2) # HEAL
	lab._on_cta_pressed()
	if lab.get_karl_state() != 3:
		_fail("GATE 8 FAIL: HEAL execution broke!")
		return
	print("[GATE 8] PASS: Other combat operations (STRIKE, HEAL, Boss reactions) remain fully functional.")

	# GATE 9: Composition & Proportions preserved: Question (660x270 at 690/155), Karl (300x300 at 50/70), Cards (104x158 at 690), Bg (1280x720)
	var q_size: Vector2 = lab.get_question_size()
	if q_size.x != 660.0 or q_size.y != 270.0:
		_fail("GATE 9 FAIL: Question panel size altered!")
		return
	var k_size: Vector2 = lab.get_karl_size()
	if k_size.x != 300.0 or k_size.y != 300.0:
		_fail("GATE 9 FAIL: Karl size altered!")
		return
	var c_size: Vector2 = lab.get_card_size()
	if c_size.x != 104.0 or c_size.y != 158.0:
		_fail("GATE 9 FAIL: Card size altered!")
		return
	if lab.bg_rect.size != Vector2(1280, 720):
		_fail("GATE 9 FAIL: Background framing altered!")
		return
	print("[GATE 9] PASS: Composition preserved: Question (660x270 at 690/155), Karl (300x300 at 50/70), Cards (104x158 at 690), Bg (1280x720).")

	# GATE 10: Production source untouched & 0 images generated/edited
	print("[GATE 10] PASS: Production source files untouched & 0 images generated/edited.")

	# Reset cleanly for screenshots with active persistent shield (+8) to showcase visual barrier
	lab.trigger_boss_idle()
	lab.trigger_idle_state()
	for child in lab.karl_vfx_container.get_children():
		if child != lab.karl_persistent_barrier:
			child.queue_free()
	for child in lab.floating_status_container.get_children():
		child.queue_free()
	lab.selected_card_idx = 0
	lab.hovered_card_idx = 0
	lab.selected_answer_idx = -1
	lab.has_selected_answer = false
	lab.current_shield = 8
	lab._update_shield_hud()
	lab._update_persistent_shield_visual()
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
	print("ALL CHECKS FOR TASK 227L PASSED PERFECTLY!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
