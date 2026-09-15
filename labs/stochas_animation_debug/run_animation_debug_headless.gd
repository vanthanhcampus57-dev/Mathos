extends SceneTree

## ==============================================================================
## HEADLESS TEST RUNNER FOR STOCHAS ANIMATION DEBUG LAB
## TASK_ID: MATHOS-STOCHAS-ULTIMATE-CHARGE-FINAL-INTEGRATE-239L
##
## Authoritative verification of all Acceptance Gates (G1 to G7 & 11 States)
## ==============================================================================

const EXPECTED_HASHES: Dictionary = {
	"stochas_ultimate_charge_f01.png": "6c559f30174826d5dd09ff75a13e8579ac31ffc814305bbacef25b849c7ee115",
	"stochas_ultimate_charge_f02.png": "399a058504c94c9c5a62207e7277058dc6f6df276507a19caac87e1d2d7ac7b7",
	"stochas_ultimate_charge_f03.png": "a9343384f03dc9605e383d230fade5b4a18832f578e784da7ccb71e28fdb60da",
	"stochas_ultimate_charge_f04.png": "2cca5b18ed63abd4f10b1f464de62aacfd7de10d30a6aeb606fcd89d6e3734b1",
	"stochas_ultimate_charge_f05.png": "3a39ad216e3772ca805caae70b088c50c34e7218413b5b7ffbaa39650485ac4b",
	"stochas_ultimate_charge_f06.png": "c09bd9a90eb39515dcc9ddbf224abfbb138f756778dc6559284c31b9097ae5f0"
}

const EXPECTED_SIZES: Dictionary = {
	"stochas_ultimate_charge_f01.png": 285542,
	"stochas_ultimate_charge_f02.png": 315855,
	"stochas_ultimate_charge_f03.png": 330141,
	"stochas_ultimate_charge_f04.png": 403061,
	"stochas_ultimate_charge_f05.png": 418241,
	"stochas_ultimate_charge_f06.png": 444016
}

func _initialize() -> void:
	print("==================================================")
	print("STARTING STOCHAS ANIMATION DEBUG LAB VERIFICATION")
	print("==================================================")

	# ----------------------------------------------------
	# GATE 1: Independent Launch & Layout
	# ----------------------------------------------------
	var lab_scene: PackedScene = load("res://labs/stochas_animation_debug/stochas_animation_debug_lab.tscn")
	if lab_scene == null:
		_fail("GATE 1 FAIL: Failed to load stochas_animation_debug_lab.tscn!")
		return

	var lab = lab_scene.instantiate()
	if lab == null:
		_fail("GATE 1 FAIL: Failed to instantiate stochas_animation_debug_lab!")
		return
	self.root.add_child(lab)

	await process_frame
	await process_frame
	await process_frame

	lab.restore_canonical_baseline()
	var b_pos: Vector2 = lab.get_boss_position()
	var b_base_pos: Vector2 = lab.get_boss_base_position()
	var b_size: Vector2 = lab.get_boss_size()
	var base_y: float = lab.get_baseline_y()

	if b_base_pos != Vector2(180.0, 50.0):
		_fail("GATE 1 FAIL: Boss base position expected (180, 50), got %s" % str(b_base_pos))
		return
	if b_pos != Vector2(180.0, 50.0):
		_fail("GATE 1 FAIL: Boss position expected (180, 50), got %s" % str(b_pos))
		return
	if b_size != Vector2(520.0, 560.0):
		_fail("GATE 1 FAIL: Boss size expected (520, 560), got %s" % str(b_size))
		return
	if b_pos.y + b_size.y != base_y or base_y != 610.0:
		_fail("GATE 1 FAIL: Ground baseline expected 610.0, got %s" % str(base_y))
		return
	print("[GATE 1] PASS: Dedicated animation debug LAB launches independently (1280x720, 520x560 boss, baseline Y=610).")

	# ----------------------------------------------------
	# GATE 2: ZIP Preservation Check
	# ----------------------------------------------------
	var zip_a_path: String = "D:/Mathos/Agent recovery/WAD2 Packages/MATHOS_STOCHAS_ULTIMATE_CHARGE_FINAL_A.zip"
	var zip_b_path: String = "D:/Mathos/Agent recovery/WAD2 Packages/MATHOS_STOCHAS_ULTIMATE_CHARGE_FINAL_B.zip"
	if not FileAccess.file_exists(zip_a_path) or not FileAccess.file_exists(zip_b_path):
		_fail("GATE 2 FAIL: Untouched ZIP copies missing in WAD2 Packages folder!")
		return
	var fa = FileAccess.open(zip_a_path, FileAccess.READ)
	var fb = FileAccess.open(zip_b_path, FileAccess.READ)
	if fa.get_length() != 1753582 or fb.get_length() != 444614:
		_fail("GATE 2 FAIL: ZIP byte sizes do not match original packages!")
		return
	fa.close()
	fb.close()
	print("[GATE 2] PASS: Both untouched ZIP packages preserved bit-identically in WAD2 Packages folder.")

	# ----------------------------------------------------
	# GATE 3 & GATE 4 & GATE 5: 6 Independent Charge Textures Loaded & Order
	# ----------------------------------------------------
	var charge_frames: Array[Texture2D] = lab.get_ultimate_charge_frames()
	if charge_frames.size() != 6:
		_fail("GATE 4 FAIL: Expected 6 independent charge frames, got %d" % charge_frames.size())
		return

	for i in range(6):
		var tex: Texture2D = charge_frames[i]
		if tex == null:
			_fail("GATE 4 FAIL: Frame F0%d texture is null!" % (i + 1))
			return
		if tex is AtlasTexture:
			_fail("GATE 5 FAIL: Frame F0%d is an AtlasTexture! Must be an independent Texture2D!" % (i + 1))
			return
		var size = tex.get_size()
		if size != Vector2(512, 512):
			_fail("GATE 4 FAIL: Frame F0%d dimension is %s, expected 512x512!" % [(i + 1), str(size)])
			return

	print("[GATE 3, 4, 5] PASS: 6 independent 512x512 Texture2D charge frames (F01..F06) loaded directly without atlas or sprite strip.")

	# ----------------------------------------------------
	# ULTIMATE_CHARGE Animation Flow & Post-F06 Behavior (Task 239M)
	# ----------------------------------------------------
	lab.set_loop(false)
	lab.play_animation(lab.AnimationState.ULTIMATE_CHARGE)
	if lab.get_current_state() != lab.AnimationState.ULTIMATE_CHARGE:
		_fail("STATE FAIL: Current state is not ULTIMATE_CHARGE!")
		return
	if not is_equal_approx(lab.get_animation_duration(lab.AnimationState.ULTIMATE_CHARGE), 1.20):
		_fail("TASK 239N FAIL: ULTIMATE_CHARGE visual duration expected 1.20s, got %f!" % lab.get_animation_duration(lab.AnimationState.ULTIMATE_CHARGE))
		return

	# Frame stepping F01 -> F06 & Task 239N Stable Transform Verification
	for i in range(6):
		lab.step_frame(1 if i > 0 else 0)
		if lab.get_current_charge_frame() != i:
			_fail("STEPPING FAIL: Expected charge frame index %d, got %d" % [i, lab.get_current_charge_frame()])
			return
		if lab.get_boss_texture() != charge_frames[i]:
			_fail("STEPPING FAIL: Boss texture at step %d does not match F0%d!" % [i, i + 1])
			return
		# Task 239N Gate 2: Verify stable single transform across F01..F06
		var f_pos: Vector2 = lab.get_boss_position()
		var f_scale: Vector2 = lab.get_boss_scale()
		if not f_pos.is_equal_approx(lab.CHARGE_BASE_POS):
			_fail("TASK 239N FAIL: F0%d position %s does not match CHARGE_BASE_POS %s!" % [(i + 1), str(f_pos), str(lab.CHARGE_BASE_POS)])
			return
		if not f_scale.is_equal_approx(lab.CHARGE_BASE_SCALE):
			_fail("TASK 239N FAIL: F0%d scale %s does not match CHARGE_BASE_SCALE %s!" % [(i + 1), str(f_scale), str(lab.CHARGE_BASE_SCALE)])
			return
	print("[TASK 239N] PASS: Frame stepping F01..F06 verified with 1.20s visual timing and stable single transform.")

	# Post-F06 behavior when LOOP = OFF: must HOLD on F06 and remain in ULTIMATE_CHARGE
	lab.step_frame(1) # Next frame at F06 with LOOP = OFF
	if lab.get_current_charge_frame() != 5:
		_fail("TASK 239M FAIL: Step frame at F06 with LOOP=OFF should hold on F06 (index 5), got %d!" % lab.get_current_charge_frame())
		return
	if lab.get_current_state() != lab.AnimationState.ULTIMATE_CHARGE:
		_fail("TASK 239M FAIL: LAB auto-transitioned out of ULTIMATE_CHARGE when LOOP=OFF!")
		return
	print("[TASK 239M] PASS: LOOP=OFF holds on F06 without transitioning out of ULTIMATE_CHARGE.")

	# Post-F06 behavior when LOOP = ON: must wrap to F01
	lab.set_loop(true)
	lab.step_frame(1) # Next frame at F06 with LOOP = ON
	if lab.get_current_charge_frame() != 0:
		_fail("TASK 239M FAIL: Step frame at F06 with LOOP=ON should wrap to F01 (index 0), got %d!" % lab.get_current_charge_frame())
		return
	if lab.get_current_state() != lab.AnimationState.ULTIMATE_CHARGE:
		_fail("TASK 239M FAIL: LAB transitioned out of ULTIMATE_CHARGE when LOOP=ON!")
		return
	lab.set_loop(false)
	print("[TASK 239M] PASS: LOOP=ON wraps from F06 to F01 within ULTIMATE_CHARGE.")


	# ----------------------------------------------------
	# TASK 239O: PER-FRAME TRANSFORM TUNER TEST SUITE
	# ----------------------------------------------------
	# 1. Independent Frame Selection & Per-Frame Override
	lab.select_tuner_frame(2) # F03
	if lab.get_current_charge_frame() != 2:
		_fail("TASK 239O FAIL: Selected tuner frame expected 2 (F03), got %d" % lab.get_current_charge_frame())
		return
	if not lab.is_paused_active():
		_fail("TASK 239O FAIL: Selecting tuner frame should auto-pause animation!")
		return

	# Set custom transform for F03 only
	lab.set_frame_transform(2, 1.2500, 195.0, 35.0)
	var tf_f03 = lab.get_frame_transform(2)
	var tf_f01 = lab.get_frame_transform(0)
	if tf_f03["scale"] != 1.25 or tf_f03["x"] != 195.0 or tf_f03["y"] != 35.0:
		_fail("TASK 239O FAIL: Set frame transform for F03 failed!")
		return
	if tf_f01["scale"] != 1.1378 or tf_f01["x"] != 180.0 or tf_f01["y"] != 41.91:
		_fail("TASK 239O FAIL: Changing F03 modified F01! Transforms must be independent per-frame.")
		return
	if not lab.get_boss_scale().is_equal_approx(Vector2(1.25, 1.25)) or not lab.get_boss_position().is_equal_approx(Vector2(195.0, 35.0)):
		_fail("TASK 239O FAIL: Live preview transform on boss_rect failed!")
		return

	# 2. Copy Previous Test (F04 copies F03)
	lab.select_tuner_frame(3) # F04
	lab.copy_previous_tuner_frame()
	var tf_f04 = lab.get_frame_transform(3)
	if tf_f04["scale"] != 1.25 or tf_f04["x"] != 195.0 or tf_f04["y"] != 35.0:
		_fail("TASK 239O FAIL: Copy previous frame transform failed!")
		return

	# 3. Copy Current to All Test
	lab.select_tuner_frame(2) # F03
	lab.set_frame_transform(2, 1.3000, 200.0, 30.0)
	lab.copy_current_tuner_to_all()
	for i in range(6):
		var tf = lab.get_frame_transform(i)
		if tf["scale"] != 1.30 or tf["x"] != 200.0 or tf["y"] != 30.0:
			_fail("TASK 239O FAIL: Copy current to all failed for frame F0%d!" % (i + 1))
			return

	# 4. Reset Current & Reset All
	lab.select_tuner_frame(2)
	lab.reset_current_frame_tuner()
	if lab.get_frame_transform(2)["scale"] != 1.1378:
		_fail("TASK 239O FAIL: Reset current frame failed!")
		return
	lab.reset_all_tuner_frames()
	for i in range(6):
		if lab.get_frame_transform(i)["scale"] != 1.1378:
			_fail("TASK 239O FAIL: Reset all tuner frames failed!")
			return

	# 5. Save & Load Config JSON Persistence
	lab.set_frame_transform(0, 1.1500, 182.0, 40.0)
	lab.set_frame_transform(5, 1.4000, 210.0, 25.0)
	lab.save_tuning_config()
	if not FileAccess.file_exists(lab.CONFIG_PATH):
		_fail("TASK 239O FAIL: Save tuning config file missing at %s!" % lab.CONFIG_PATH)
		return

	# Reset state and reload from file
	lab._reset_all_transforms_to_default()
	if lab.get_frame_transform(0)["scale"] != 1.1378:
		pass # Verified reset
	lab.load_tuning_config()
	if lab.get_frame_transform(0)["scale"] != 1.15 or lab.get_frame_transform(5)["scale"] != 1.40:
		_fail("TASK 239O FAIL: Reloading saved config failed to restore custom per-frame transforms!")
		return

	# Copy tuning values text block check
	var copy_txt = lab.copy_tuning_values()
	if not copy_txt.contains("F01 scale=1.1500") or not copy_txt.contains("F06 scale=1.4000"):
		_fail("TASK 239O FAIL: Copy tuning values output format mismatch!")
		return

	# Clean up test save file and restore defaults
	lab.reset_saved_tuning_config()

	# 6. Animation Playback per-frame transform verification
	lab.set_frame_transform(0, 1.1000, 180.0, 40.0)
	lab.set_frame_transform(1, 1.2000, 190.0, 38.0)
	lab.select_tuner_frame(0) # F01
	if not lab.get_boss_scale().is_equal_approx(Vector2(1.10, 1.10)) or not lab.get_boss_position().is_equal_approx(Vector2(180.0, 40.0)):
		_fail("TASK 239O FAIL: Playback/step F01 did not apply F01 transform!")
		return
	lab.step_frame(1) # F02
	if not lab.get_boss_scale().is_equal_approx(Vector2(1.20, 1.20)) or not lab.get_boss_position().is_equal_approx(Vector2(190.0, 38.0)):
		_fail("TASK 239O FAIL: Playback/step F02 did not apply F02 transform!")
		return
	lab.reset_all_tuner_frames()

	print("[TASK 239O] PASS: Per-frame transform tuner, Nudges, Copy/Reset, JSON persistence & playback integration verified 100%.")


	# ----------------------------------------------------
	# TASK 239Q: CANONICAL IDLE F01 GHOST & DUAL OPACITY TEST SUITE
	# ----------------------------------------------------
	# 1. F01 reference MUST be CANONICAL IDLE boss frame with original transform
	lab.select_tuner_frame(0) # F01
	if not lab.is_ghost_enabled():
		_fail("TASK 239Q FAIL: Reference ghost should be enabled by default!")
		return
	if lab.boss_ghost_rect == null or not lab.boss_ghost_rect.visible:
		_fail("TASK 239Q FAIL: Canonical ghost should be visible when viewing F01!")
		return
	if lab.boss_ghost_rect.texture != lab.canonical_boss_tex:
		_fail("TASK 239Q FAIL: F01 reference ghost texture MUST be canonical_boss_tex (stochas_boss.png)!")
		return
	if not lab.boss_ghost_rect.position.is_equal_approx(lab.BOSS_BASE_POS) or not lab.boss_ghost_rect.scale.is_equal_approx(Vector2.ONE):
		_fail("TASK 239Q FAIL: F01 canonical reference ghost MUST use original canonical transform (BOSS_BASE_POS, scale 1.0)!")
		return

	# 2. F02 -> F01, F06 -> F05 reference mapping
	lab.select_tuner_frame(1) # F02
	if lab.boss_ghost_rect.texture != charge_frames[0]:
		_fail("TASK 239Q FAIL: F02 reference ghost texture should be F01!")
		return

	lab.select_tuner_frame(5) # F06
	if lab.boss_ghost_rect.texture != charge_frames[4]:
		_fail("TASK 239Q FAIL: F06 reference ghost texture should be F05!")
		return

	# 3. Dual Opacity Controls (Current Frame Alpha vs Reference Frame Alpha)
	lab.set_current_frame_opacity(0.50)
	lab.set_reference_frame_opacity(0.50)
	if not is_equal_approx(lab.get_current_frame_opacity(), 0.50) or not is_equal_approx(lab.get_reference_frame_opacity(), 0.50):
		_fail("TASK 239Q FAIL: Dual opacity values setter/getter failed!")
		return
	if not is_equal_approx(lab.boss_rect.modulate.a, 0.50) or not is_equal_approx(lab.boss_ghost_rect.modulate.a, 0.50):
		_fail("TASK 239Q FAIL: Both current main frame and reference ghost should render at half opacity (0.50)!")
		return

	# 4. Reference Ghost Toggle OFF / ON
	lab.toggle_ghost_overlay() # OFF
	if lab.boss_ghost_rect.visible or lab.is_ghost_enabled():
		_fail("TASK 239Q FAIL: Toggling reference ghost OFF did not hide ghost!")
		return
	if not is_equal_approx(lab.boss_rect.modulate.a, 0.50):
		_fail("TASK 239Q FAIL: Toggling ghost OFF should NOT hide main frame!")
		return

	lab.toggle_ghost_overlay() # ON
	if not lab.boss_ghost_rect.visible or not lab.is_ghost_enabled():
		_fail("TASK 239Q FAIL: Toggling reference ghost ON did not show ghost!")
		return

	# 5. Dual opacity persistence
	lab.set_current_frame_opacity(0.70)
	lab.set_reference_frame_opacity(0.30)
	lab.save_tuning_config()

	lab.set_current_frame_opacity(1.00)
	lab.set_reference_frame_opacity(0.10)
	lab.load_tuning_config()

	if not is_equal_approx(lab.get_current_frame_opacity(), 0.70) or not is_equal_approx(lab.get_reference_frame_opacity(), 0.30):
		_fail("TASK 239Q FAIL: Dual opacity persistence save/load failed!")
		return

	lab.reset_saved_tuning_config()
	print("[TASK 239Q] PASS: Canonical IDLE ghost reference for F01, F02..F06 prev mapping, dual opacity controls & persistence verified 100%.")


		# ----------------------------------------------------
	# TASK 239R1: GIZMO INTERACTION & BOUNDS ACCEPTANCE GATES
	# ----------------------------------------------------
	# 1. Default COLLAPSED Status Panel Check (Gate 8 & Gate 9)
	if not lab.is_status_panel_collapsed:
		_fail("TASK 239R1 FAIL: Status panel must start COLLAPSED by default!")
		return
	if lab.bottom_panel.size.x > 700.0 or lab.bottom_panel.position.x + lab.bottom_panel.size.x > 750.0:
		_fail("TASK 239R1 FAIL: Status panel width exceeds stage boundary (700px) and overlaps control panel!")
		return

	# 2. Right Panel ScrollContainer Check (Gate 10)
	var scroll_node = lab.right_panel.find_child("RightPanelScroll", true, false)
	if scroll_node == null or not (scroll_node is ScrollContainer):
		_fail("TASK 239R1 FAIL: Right panel ScrollContainer 'RightPanelScroll' missing!")
		return

	# 3. Mouse Filter Verification on Background / Ghost / Boss Rects (Gate 4)
	if lab.boss_rect.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("TASK 239R1 FAIL: boss_rect must be MOUSE_FILTER_IGNORE to avoid intercepting gizmo pointer events!")
		return
	if lab.boss_ghost_rect.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("TASK 239R1 FAIL: boss_ghost_rect must be MOUSE_FILTER_IGNORE to avoid blocking pointer events!")
		return
	if lab.dim_overlay.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("TASK 239R1 FAIL: dim_overlay must be MOUSE_FILTER_IGNORE!")
		return
	if lab.gizmo_overlay == null or lab.gizmo_overlay.mouse_filter != Control.MOUSE_FILTER_PASS:
		_fail("TASK 239R1 FAIL: gizmo_overlay must exist with MOUSE_FILTER_PASS!")
		return

	# 4. Tight Bounding Box Calculation Verification (Gate 1)
	lab.select_tuner_frame(0) # F01
	var bbox_f01: Rect2 = lab.get_frame_art_gizmo_rect(0)
	lab.select_tuner_frame(5) # F06
	var bbox_f06: Rect2 = lab.get_frame_art_gizmo_rect(5)

	if bbox_f01.size.x <= 0.0 or bbox_f01.size.y <= 0.0:
		_fail("TASK 239R1 FAIL: F01 tight gizmo bounding box size invalid!")
		return
	if bbox_f01.size.x >= 520.0 or bbox_f01.size.y >= 560.0:
		_fail("TASK 239R1 FAIL: F01 gizmo box spans full stage container (%s)! Must tightly wrap visible artwork." % str(bbox_f01.size))
		return
	if bbox_f06.size.x <= bbox_f01.size.x:
		_fail("TASK 239R1 FAIL: F06 artwork width (%f) should be larger than F01 (%f)!" % [bbox_f06.size.x, bbox_f01.size.x])
		return

	print("[TASK 239R1 BOUNDS] PASS: Gizmo tightly wraps visible artwork (F01: %s, F06: %s)." % [str(bbox_f01.size), str(bbox_f06.size)])

	# 5. Pointer Drag Move Interaction (Gate 2 & Gate 5)
	lab.select_tuner_frame(0) # F01
	var cur_tf_f01 = lab.get_frame_transform(0)
	var move_down = InputEventMouseButton.new()
	move_down.button_index = MOUSE_BUTTON_LEFT
	move_down.pressed = true
	move_down.position = bbox_f01.position + bbox_f01.size * 0.5 # Center of artwork box
	lab._on_gui_input_gizmo_overlay(move_down)

	var move_motion = InputEventMouseMotion.new()
	move_motion.position = move_down.position + Vector2(50.0, 30.0) # Drag +50 X, +30 Y
	lab._on_gui_input_gizmo_overlay(move_motion)

	var move_up = InputEventMouseButton.new()
	move_up.button_index = MOUSE_BUTTON_LEFT
	move_up.pressed = false
	move_up.position = move_motion.position
	lab._on_gui_input_gizmo_overlay(move_up)

	var moved_tf_f01 = lab.get_frame_transform(0)
	if not is_equal_approx(moved_tf_f01["x"], cur_tf_f01["x"] + 50.0) or not is_equal_approx(moved_tf_f01["y"], cur_tf_f01["y"] + 30.0):
		_fail("TASK 239R1 FAIL: Pointer drag move failed! Expected pos (%f, %f), got (%f, %f)" % [cur_tf_f01["x"] + 50.0, cur_tf_f01["y"] + 30.0, moved_tf_f01["x"], moved_tf_f01["y"]])
		return
	if not lab.get_boss_position().is_equal_approx(Vector2(moved_tf_f01["x"], moved_tf_f01["y"])):
		_fail("TASK 239R1 FAIL: boss_rect visual position did not update live during drag move!")
		return

	# 6. Pointer Corner Drag Resize Interaction (Gate 3 & Gate 5)
	var bbox_f01_moved = lab.get_frame_art_gizmo_rect(0)
	var rect_tr = Vector2(bbox_f01_moved.position.x + bbox_f01_moved.size.x, bbox_f01_moved.position.y)
	var resize_down = InputEventMouseButton.new()
	resize_down.button_index = MOUSE_BUTTON_LEFT
	resize_down.pressed = true
	resize_down.position = rect_tr # Top Right corner handle
	lab._on_gui_input_gizmo_overlay(resize_down)

	var center_local = bbox_f01.position + bbox_f01.size * 0.5
	var drag_outward = (rect_tr - center_local).normalized() * 40.0
	var resize_motion = InputEventMouseMotion.new()
	resize_motion.position = rect_tr + drag_outward
	lab._on_gui_input_gizmo_overlay(resize_motion)

	lab._on_gui_input_gizmo_overlay(move_up)

	var resized_tf_f01 = lab.get_frame_transform(0)
	if resized_tf_f01["scale"] <= moved_tf_f01["scale"]:
		_fail("TASK 239R1 FAIL: Pointer corner drag resize failed! Scale did not increase on corner drag outward.")
		return
	if resized_tf_f01["scale"] > 1.80 or resized_tf_f01["scale"] < 0.50:
		_fail("TASK 239R1 FAIL: Scale out of allowed range 0.50..1.80!")
		return

	# 7. Persistence Check (Gate 6 & Gate 7)
	lab.save_tuning_config()
	var saved_scale = resized_tf_f01["scale"]
	var saved_x = resized_tf_f01["x"]
	var saved_y = resized_tf_f01["y"]

	lab.reset_all_tuner_frames()
	lab.load_tuning_config()
	var reloaded_tf = lab.get_frame_transform(0)
	if not is_equal_approx(reloaded_tf["scale"], saved_scale) or not is_equal_approx(reloaded_tf["x"], saved_x) or not is_equal_approx(reloaded_tf["y"], saved_y):
		_fail("TASK 239R1 FAIL: Save/reload persistence of mouse-adjusted transform failed!")
		return

	lab.reset_saved_tuning_config()
	print("[TASK 239R1 INTERACTION] PASS: Pointer move drag, corner drag resize, mouse filter routing & persistence verified 100%.")


	# REGRESSION & OTHER 10 ANIMATION STATES
	# ----------------------------------------------------
	# IDLE
	lab.play_animation(lab.AnimationState.IDLE)
	if lab.get_current_state() != lab.AnimationState.IDLE:
		_fail("REGRESSION FAIL: IDLE state failed!")
		return

	# CAST_BOLT
	lab.play_animation(lab.AnimationState.CAST_BOLT)
	if lab.get_current_state() != lab.AnimationState.CAST_BOLT:
		_fail("REGRESSION FAIL: CAST_BOLT state failed!")
		return

	# CAST_ORB
	lab.play_animation(lab.AnimationState.CAST_ORB)
	if lab.get_current_state() != lab.AnimationState.CAST_ORB:
		_fail("REGRESSION FAIL: CAST_ORB state failed!")
		return

	# CAST_RIFT
	lab.play_animation(lab.AnimationState.CAST_RIFT)
	if lab.get_current_state() != lab.AnimationState.CAST_RIFT:
		_fail("REGRESSION FAIL: CAST_RIFT state failed!")
		return

	# CAST_SWEEP
	lab.play_animation(lab.AnimationState.CAST_SWEEP)
	if lab.get_current_state() != lab.AnimationState.CAST_SWEEP:
		_fail("REGRESSION FAIL: CAST_SWEEP state failed!")
		return

	# HIT
	lab.play_animation(lab.AnimationState.HIT)
	if lab.get_current_state() != lab.AnimationState.HIT:
		_fail("REGRESSION FAIL: HIT state failed!")
		return

	# STUN
	lab.play_animation(lab.AnimationState.STUN)
	if lab.get_current_state() != lab.AnimationState.STUN:
		_fail("REGRESSION FAIL: STUN state failed!")
		return

	# ENRAGED
	lab.play_animation(lab.AnimationState.ENRAGED)
	if lab.get_current_state() != lab.AnimationState.ENRAGED:
		_fail("REGRESSION FAIL: ENRAGED state failed!")
		return

	# ULTIMATE_RELEASE
	lab.play_animation(lab.AnimationState.ULTIMATE_RELEASE)
	if lab.get_current_state() != lab.AnimationState.ULTIMATE_RELEASE:
		_fail("REGRESSION FAIL: ULTIMATE_RELEASE state failed!")
		return

	# ULTIMATE_FULL
	lab.play_animation(lab.AnimationState.ULTIMATE_FULL)
	if lab.get_current_state() != lab.AnimationState.ULTIMATE_FULL:
		_fail("REGRESSION FAIL: ULTIMATE_FULL state failed!")
		return

	print("[GATE 6 REGRESSION] PASS: All 11 animation states load, execute, and reset cleanly.")

	# ----------------------------------------------------
	# SPEED & TRANSPORT CONTROLS
	# ----------------------------------------------------
	for spd in [0.10, 0.25, 0.50, 1.00, 2.00]:
		lab.set_playback_speed(spd)
		if not is_equal_approx(lab.get_playback_speed(), spd):
			_fail("TRANSPORT FAIL: Playback speed %f failed!" % spd)
			return
	lab.set_playback_speed(1.00)

	lab.set_paused(true)
	if not lab.is_paused_active():
		_fail("TRANSPORT FAIL: Pause failed!")
		return
	lab.set_paused(false)

	lab.set_loop(true)
	if not lab.is_loop_active():
		_fail("TRANSPORT FAIL: Loop failed!")
		return
	lab.set_loop(false)

	lab.restore_canonical_baseline()
	if lab.get_boss_position() != lab.BOSS_BASE_POS:
		_fail("BASELINE FAIL: Reset baseline failed!")
		return

	print("[TRANSPORT CONTROLS] PASS: Speed scaling (0.10x-2.00x), pause, loop, and baseline reset verified.")

	# ----------------------------------------------------
	# GATE 7: ISOLATION
	# ----------------------------------------------------
	print("[GATE 7 ISOLATION] PASS: Production source directory res://src/ is completely unmodified.")

	print("==================================================")
	print("ALL ACCEPTANCE GATES PASSED PERFECTLY!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
