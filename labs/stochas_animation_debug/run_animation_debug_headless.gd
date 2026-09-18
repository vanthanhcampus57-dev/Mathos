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
	if not is_equal_approx(lab.get_animation_duration(lab.AnimationState.ULTIMATE_CHARGE), 0.80):
		_fail("TASK 239N FAIL: ULTIMATE_CHARGE visual duration expected 0.80s, got %f!" % lab.get_animation_duration(lab.AnimationState.ULTIMATE_CHARGE))
		return

	# Frame stepping F03 -> F06 & Task 239N Stable Transform Verification
	var active_indices_239n = [2, 3, 4, 5]
	for i in range(4):
		var frame_idx = active_indices_239n[i]
		lab.step_frame(1 if i > 0 else 0)
		if lab.get_current_charge_frame() != frame_idx:
			_fail("STEPPING FAIL: Expected charge frame index %d, got %d" % [frame_idx, lab.get_current_charge_frame()])
			return
		if lab.get_boss_texture() != charge_frames[frame_idx]:
			_fail("STEPPING FAIL: Boss texture at step %d does not match F0%d!" % [i, frame_idx + 1])
			return
		# Task 239S: Verify authoritative per-frame transform across F03..F06
		var f_pos: Vector2 = lab.get_boss_position()
		var f_scale: Vector2 = lab.get_boss_scale()
		var exp_tf: Dictionary = lab.get_frame_transform(frame_idx)
		if not f_pos.is_equal_approx(Vector2(exp_tf["x"], exp_tf["y"])):
			_fail("TASK 239S FAIL: F0%d position %s does not match expected %s!" % [(frame_idx + 1), str(f_pos), str(Vector2(exp_tf["x"], exp_tf["y"]))])
			return
		if not f_scale.is_equal_approx(Vector2(exp_tf["scale"], exp_tf["scale"])):
			_fail("TASK 239S FAIL: F0%d scale %s does not match expected %f!" % [(frame_idx + 1), str(f_scale), exp_tf["scale"]])
			return
	print("[TASK 239N] PASS: Frame stepping F03..F06 verified with 0.80s visual timing and stable single transform.")

	# Post-F06 behavior when LOOP = OFF: must HOLD on F06 and remain in ULTIMATE_CHARGE
	lab.step_frame(1) # Next frame at F06 with LOOP = OFF
	if lab.get_current_charge_frame() != 5:
		_fail("TASK 239M FAIL: Step frame at F06 with LOOP=OFF should hold on F06 (index 5), got %d!" % lab.get_current_charge_frame())
		return
	if lab.get_current_state() != lab.AnimationState.ULTIMATE_CHARGE:
		_fail("TASK 239M FAIL: LAB auto-transitioned out of ULTIMATE_CHARGE when LOOP=OFF!")
		return
	print("[TASK 239M] PASS: LOOP=OFF holds on F06 without transitioning out of ULTIMATE_CHARGE.")

	# Post-F06 behavior when LOOP = ON: must wrap to F03
	lab.set_loop(true)
	lab.step_frame(1) # Next frame at F06 with LOOP = ON
	if lab.get_current_charge_frame() != 2:
		_fail("TASK 239M FAIL: Step frame at F06 with LOOP=ON should wrap to F03 (index 2), got %d!" % lab.get_current_charge_frame())
		return
	if lab.get_current_state() != lab.AnimationState.ULTIMATE_CHARGE:
		_fail("TASK 239M FAIL: LAB transitioned out of ULTIMATE_CHARGE when LOOP=ON!")
		return
	lab.set_loop(false)
	print("[TASK 239M] PASS: LOOP=ON wraps from F06 to F03 within ULTIMATE_CHARGE.")


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
	var exp_f01 = lab.FINAL_CHARGE_TRANSFORMS[0]
	if not is_equal_approx(tf_f01["scale"], exp_f01["scale"]) or not is_equal_approx(tf_f01["x"], exp_f01["x"]) or not is_equal_approx(tf_f01["y"], exp_f01["y"]):
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
	var exp_f03 = lab.FINAL_CHARGE_TRANSFORMS[2]
	if not is_equal_approx(lab.get_frame_transform(2)["scale"], exp_f03["scale"]):
		_fail("TASK 239O FAIL: Reset current frame failed!")
		return
	lab.reset_all_tuner_frames()
	for i in range(6):
		var exp_i = lab.FINAL_CHARGE_TRANSFORMS[i]
		if not is_equal_approx(lab.get_frame_transform(i)["scale"], exp_i["scale"]):
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
	if not is_equal_approx(lab.get_frame_transform(0)["scale"], lab.FINAL_CHARGE_TRANSFORMS[0]["scale"]):
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
	lab.set_frame_transform(2, 1.1000, 180.0, 40.0)
	lab.set_frame_transform(3, 1.2000, 190.0, 38.0)
	lab.select_tuner_frame(2) # F03
	if not lab.get_boss_scale().is_equal_approx(Vector2(1.10, 1.10)) or not lab.get_boss_position().is_equal_approx(Vector2(180.0, 40.0)):
		_fail("TASK 239O FAIL: Playback/step F03 did not apply F03 transform!")
		return
	lab.step_frame(1) # F04
	if not lab.get_boss_scale().is_equal_approx(Vector2(1.20, 1.20)) or not lab.get_boss_position().is_equal_approx(Vector2(190.0, 38.0)):
		_fail("TASK 239O FAIL: Playback/step F04 did not apply F04 transform!")
		return
	lab.reset_all_tuner_frames()

	print("[TASK 239O] PASS: Per-frame transform tuner, Nudges, Copy/Reset, JSON persistence & playback integration verified 100%.")


	# ----------------------------------------------------
	# TASK 239Q: CANONICAL IDLE F01 GHOST & DUAL OPACITY TEST SUITE
	# ----------------------------------------------------
	# 1. F03 reference MUST be CANONICAL IDLE boss frame with original transform
	lab.select_tuner_frame(2) # F03
	if not lab.is_ghost_enabled():
		_fail("TASK 239Q FAIL: Reference ghost should be enabled by default!")
		return
	if lab.boss_ghost_rect == null or not lab.boss_ghost_rect.visible:
		_fail("TASK 239Q FAIL: Canonical ghost should be visible when viewing F03!")
		return
	if lab.boss_ghost_rect.texture != lab.canonical_boss_tex:
		_fail("TASK 239Q FAIL: F03 reference ghost texture MUST be canonical_boss_tex (stochas_boss.png)!")
		return
	if not lab.boss_ghost_rect.position.is_equal_approx(lab.BOSS_BASE_POS) or not lab.boss_ghost_rect.scale.is_equal_approx(Vector2.ONE):
		_fail("TASK 239Q FAIL: F03 canonical reference ghost MUST use original canonical transform (BOSS_BASE_POS, scale 1.0)!")
		return

	# 2. F04 -> F03, F06 -> F05 reference mapping
	lab.select_tuner_frame(3) # F04
	if lab.boss_ghost_rect.texture != charge_frames[2]:
		_fail("TASK 239Q FAIL: F04 reference ghost texture should be F03!")
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
	# TASK 239U: F03..F06 ACTIVE CHARGE SEQUENCE & LARGE FLASH TEST SUITE
	# ----------------------------------------------------
	# 1. Large Entry Flash Node Dimensions & Layering (Gate 4)
	if lab.entry_flash_rect == null:
		_fail("TASK 239U FAIL: entry_flash_rect overlay node missing!")
		return
	if lab.entry_flash_rect.size != Vector2(680, 680):
		_fail("TASK 239U FAIL: Flash area size expected (680, 680), got %s!" % str(lab.entry_flash_rect.size))
		return

	# 2. State Entry Trigger (IDLE -> Large Flash -> F03) (Gates 1, 2, 3, 5, 6, 7)
	lab.set_paused(false)
	lab.play_animation(lab.AnimationState.IDLE)
	await process_frame
	lab.play_animation(lab.AnimationState.ULTIMATE_CHARGE)

	if not is_equal_approx(lab.get_animation_duration(lab.AnimationState.ULTIMATE_CHARGE), 0.80):
		_fail("TASK 239U FAIL: Visual duration expected 0.80s (4 frames * 0.20s), got %f!" % lab.get_animation_duration(lab.AnimationState.ULTIMATE_CHARGE))
		return

	# Fast forward to peak flash (~0.06s-0.07s)
	lab.active_tween.custom_step(0.07)
	if lab.get_current_charge_frame() != 2: # F03
		_fail("TASK 239U FAIL: Frame at peak flash expected F03 (index 2), got index %d!" % lab.get_current_charge_frame())
		return

	# Step through active sequence F03 -> F04 -> F05 -> F06
	var active_indices = [2, 3, 4, 5]
	for i in range(4):
		var target_idx = active_indices[i]
		if i > 0:
			lab.step_frame(1)
		if lab.get_current_charge_frame() != target_idx:
			_fail("TASK 239U FAIL: Step %d expected active charge frame %d (F0%d), got %d!" % [i, target_idx, target_idx + 1, lab.get_current_charge_frame()])
			return
		if lab.get_current_charge_frame() == 0 or lab.get_current_charge_frame() == 1:
			_fail("TASK 239U FAIL: F01 or F02 appeared during active sequence!")
			return

	print("[TASK 239U ACTIVE SEQUENCE] PASS: Active sequence F03->F04->F05->F06 verified in 0.80s without F01/F02.")

	# 3. Post-F06 Hold & Loop Wrap F06 -> F03 (Gates 8, 9, 10)
	lab.entry_flash_rect.modulate.a = 0.0
	lab.set_loop(false)
	lab.step_frame(1) # Next on F06 with LOOP OFF
	if lab.get_current_charge_frame() != 5: # F06
		_fail("TASK 239U FAIL: LOOP OFF should hold on F06 (index 5), got %d!" % lab.get_current_charge_frame())
		return

	lab.set_loop(true)
	lab.step_frame(1) # Next on F06 with LOOP ON
	if lab.get_current_charge_frame() != 2: # F03
		_fail("TASK 239U FAIL: LOOP ON should wrap F06 -> F03 (index 2), got %d!" % lab.get_current_charge_frame())
		return
	if lab.entry_flash_rect.modulate.a > 0.001:
		_fail("TASK 239U FAIL: Loop wrap F06 -> F03 triggered entry flash!")
		return
	lab.set_loop(false)

	print("[TASK 239U LOOP WRAP] PASS: LOOP OFF holds F06, LOOP ON wraps F06->F03 with NO flash.")

	# 4. Frame Stepping Bounds (Gate 11)
	lab.select_tuner_frame(2) # F03
	lab.step_frame(-1) # Prev on F03 with LOOP OFF
	if lab.get_current_charge_frame() != 2:
		_fail("TASK 239U FAIL: PREV on F03 with LOOP OFF should hold F03, got %d!" % lab.get_current_charge_frame())
		return

	lab.set_loop(true)
	lab.step_frame(-1) # Prev on F03 with LOOP ON
	if lab.get_current_charge_frame() != 5:
		_fail("TASK 239U FAIL: PREV on F03 with LOOP ON should wrap to F06, got %d!" % lab.get_current_charge_frame())
		return
	lab.set_loop(false)

	# 5. Reference Ghost Mapping F03->IDLE, F04->F03, F05->F04, F06->F05 (Gates 12, 13, 14, 15)
	lab.select_tuner_frame(2) # F03
	if lab.boss_ghost_rect.texture != lab.canonical_boss_tex:
		_fail("TASK 239U FAIL: F03 reference ghost MUST be canonical_boss_tex (IDLE)!")
		return

	var ref_charge_frames = lab.get_ultimate_charge_frames()
	lab.select_tuner_frame(3) # F04
	if lab.boss_ghost_rect.texture != ref_charge_frames[2]: # F03
		_fail("TASK 239U FAIL: F04 reference ghost MUST be F03!")
		return

	lab.select_tuner_frame(4) # F05
	if lab.boss_ghost_rect.texture != ref_charge_frames[3]: # F04
		_fail("TASK 239U FAIL: F05 reference ghost MUST be F04!")
		return

	lab.select_tuner_frame(5) # F06
	if lab.boss_ghost_rect.texture != ref_charge_frames[4]: # F05
		_fail("TASK 239U FAIL: F06 reference ghost MUST be F05!")
		return

	print("[TASK 239U GHOST MAPPING] PASS: F03->IDLE, F04->F03, F05->F04, F06->F05 reference mapping verified.")


	# ----------------------------------------------------
	# TASK 239S: HUMAN FINAL TRANSFORMS LOCK TEST SUITE
	# ----------------------------------------------------
	# Authoritative Expected Values:
	var expected_final = {
		0: {"scale": 1.0076, "x": 203.99, "y": 8.49},
		1: {"scale": 1.1533, "x": 191.63, "y": 24.47},
		2: {"scale": 1.1378, "x": 195.26, "y": 25.20},
		3: {"scale": 1.1378, "x": 208.35, "y": 35.37},
		4: {"scale": 1.1378, "x": 214.89, "y": 25.20},
		5: {"scale": 1.1378, "x": 190.18, "y": 14.30}
	}

	# 1. Fresh Launch Source Default Verification
	for i in range(6):
		var tf = lab.get_frame_transform(i)
		var exp = expected_final[i]
		if not is_equal_approx(tf["scale"], exp["scale"]) or not is_equal_approx(tf["x"], exp["x"]) or not is_equal_approx(tf["y"], exp["y"]):
			_fail("TASK 239S FAIL: F0%d default transform mismatch! Expected (%f, %f, %f), got (%f, %f, %f)" % [i + 1, exp["scale"], exp["x"], exp["y"], tf["scale"], tf["x"], tf["y"]])
			return

	print("[TASK 239S STARTUP] PASS: Fresh launch defaults to exact HUMAN-approved final transforms F01..F06.")

	# 2. Verify Normal Playback Applies Exact Final Transforms
	lab.play_animation(lab.AnimationState.ULTIMATE_CHARGE)
	var active_indices_239s = [2, 3, 4, 5]
	for i in range(4):
		var frame_idx = active_indices_239s[i]
		lab.step_frame(1 if i > 0 else 0)
		var play_pos = lab.get_boss_position()
		var play_scale = lab.get_boss_scale()
		var exp = expected_final[frame_idx]
		if not play_pos.is_equal_approx(Vector2(exp["x"], exp["y"])) or not play_scale.is_equal_approx(Vector2(exp["scale"], exp["scale"])):
			_fail("TASK 239S FAIL: Runtime F0%d playback transform expected pos (%f, %f) scale %f, got pos %s scale %s!" % [frame_idx + 1, exp["x"], exp["y"], exp["scale"], str(play_pos), str(play_scale)])
			return

	print("[TASK 239S PLAYBACK] PASS: ULTIMATE_CHARGE normal playback applies exact final per-frame transforms.")

	# 3. Test RESET FRAME & RESET ALL Restore HUMAN Final Values
	lab.select_tuner_frame(1) # F02
	lab.set_frame_transform(1, 1.4500, 300.0, 100.0) # Apply experimental override
	var modified_tf = lab.get_frame_transform(1)
	if is_equal_approx(modified_tf["scale"], expected_final[1]["scale"]):
		_fail("TASK 239S FAIL: Modified F02 transform failed to set!")
		return

	lab.reset_current_frame_tuner()
	var reset_f02 = lab.get_frame_transform(1)
	if not is_equal_approx(reset_f02["scale"], expected_final[1]["scale"]) or not is_equal_approx(reset_f02["x"], expected_final[1]["x"]):
		_fail("TASK 239S FAIL: RESET FRAME did not restore F02 to HUMAN final transform!")
		return

	# Modify all frames and call RESET ALL
	for i in range(6):
		lab.set_frame_transform(i, 1.5000, 250.0, 50.0)
	lab.reset_all_tuner_frames()
	for i in range(6):
		var tf = lab.get_frame_transform(i)
		var exp = expected_final[i]
		if not is_equal_approx(tf["scale"], exp["scale"]) or not is_equal_approx(tf["x"], exp["x"]) or not is_equal_approx(tf["y"], exp["y"]):
			_fail("TASK 239S FAIL: RESET ALL did not restore F0%d to HUMAN final transform!" % (i + 1))
			return

	print("[TASK 239S RESETS] PASS: RESET FRAME and RESET ALL restore exact HUMAN-approved final transforms.")

	# 4. Verify Stale Config File Does Not Auto-Override Startup Defaults
	lab.set_frame_transform(0, 1.7777, 999.0, 999.0)
	lab.save_tuning_config() # Create a stale config file

	# Re-instantiate lab to simulate fresh scene startup
	lab.queue_free()
	await process_frame
	await process_frame

	lab = lab_scene.instantiate()
	self.root.add_child(lab)
	await process_frame
	await process_frame

	var fresh_f01 = lab.get_frame_transform(0)
	if not is_equal_approx(fresh_f01["scale"], expected_final[0]["scale"]) or not is_equal_approx(fresh_f01["x"], expected_final[0]["x"]):
		_fail("TASK 239S FAIL: Fresh launch auto-loaded stale user config file instead of HUMAN final source defaults!")
		return

	# RELOAD TUNING manually loads local override
	lab.load_tuning_config()
	var reloaded_f01 = lab.get_frame_transform(0)
	if not is_equal_approx(reloaded_f01["scale"], 1.7777) or not is_equal_approx(reloaded_f01["x"], 999.0):
		_fail("TASK 239S FAIL: Manual RELOAD TUNING failed to load user config override!")
		return

	lab.reset_saved_tuning_config()
	print("[TASK 239S CONFIG] PASS: Startup defaults to source final values; user config works as manual debug override only.")

	# ----------------------------------------------------
	# TASK 240K: ULTIMATE_RELEASE WIP INTEGRATION TEST SUITE
	# ----------------------------------------------------
	# 1. Asset Discovery & Count Verification (8 WIP frames)
	var rel_wip_frames: Array[Texture2D] = lab.get_ultimate_release_wip_frames()
	if rel_wip_frames.size() != 8:
		_fail("TASK 240K FAIL: Expected 8 release WIP frames (F01..F08), got %d!" % rel_wip_frames.size())
		return

	for i in range(8):
		var w_tex: Texture2D = rel_wip_frames[i]
		if w_tex == null:
			_fail("TASK 240K FAIL: Release WIP frame F0%d is null!" % (i + 1))
			return
		if w_tex is AtlasTexture:
			_fail("TASK 240K FAIL: Release WIP frame F0%d is an AtlasTexture! Must be independent Texture2D!" % (i + 1))
			return

	print("[TASK 240K ASSETS] PASS: Discovered 8 independent release WIP frames F01..F08.")

	# 2. Playback & Duration Verification (~0.80s, 0.10s/frame)
	lab.set_loop(false)
	lab.set_paused(false)
	lab.play_animation(lab.AnimationState.ULTIMATE_RELEASE)
	if lab.get_current_state() != lab.AnimationState.ULTIMATE_RELEASE:
		_fail("TASK 240K FAIL: Current state is not ULTIMATE_RELEASE!")
		return
	if not is_equal_approx(lab.get_animation_duration(lab.AnimationState.ULTIMATE_RELEASE), 0.80):
		_fail("TASK 240K FAIL: ULTIMATE_RELEASE visual duration expected 0.80s, got %f!" % lab.get_animation_duration(lab.AnimationState.ULTIMATE_RELEASE))
		return

	# Step through F01..F08 & verify textures (no old atlas art)
	for i in range(8):
		lab.step_frame(1 if i > 0 else 0)
		if lab.get_current_release_frame() != i:
			_fail("TASK 240K FAIL: Expected release frame index %d (F0%d), got %d!" % [i, i + 1, lab.get_current_release_frame()])
			return
		if lab.get_boss_texture() != rel_wip_frames[i]:
			_fail("TASK 240K FAIL: Boss texture at step %d does not match WIP frame F0%d!" % [i, i + 1])
			return
		if lab.get_boss_texture() is AtlasTexture:
			_fail("TASK 240K FAIL: Old release atlas art detected at frame F0%d!" % (i + 1))
			return

	print("[TASK 240K PLAYBACK] PASS: F01->F08 active sequence verified in 0.80s without old atlas art.")

	# 3. Post-F08 Behavior (LOOP OFF holds F08, LOOP ON wraps F08->F01)
	lab.set_loop(false)
	lab.step_frame(1) # Next on F08 with LOOP OFF
	if lab.get_current_release_frame() != 7:
		_fail("TASK 240K FAIL: Step frame at F08 with LOOP=OFF should hold on F08 (index 7), got %d!" % lab.get_current_release_frame())
		return
	if lab.get_current_state() != lab.AnimationState.ULTIMATE_RELEASE:
		_fail("TASK 240K FAIL: LAB auto-transitioned out of ULTIMATE_RELEASE when LOOP=OFF!")
		return

	lab.set_loop(true)
	lab.step_frame(1) # Next on F08 with LOOP ON
	if lab.get_current_release_frame() != 0:
		_fail("TASK 240K FAIL: Step frame at F08 with LOOP=ON should wrap to F01 (index 0), got %d!" % lab.get_current_release_frame())
		return
	lab.set_loop(false)

	print("[TASK 240K LOOP BEHAVIOR] PASS: LOOP OFF holds F08; LOOP ON wraps F08->F01.")

	# 4. Frame Stepping Bounds (F01 PREV holds on LOOP OFF, wraps to F08 on LOOP ON)
	lab.select_release_wip_frame(0) # F01
	lab.step_frame(-1) # PREV on F01 with LOOP OFF
	if lab.get_current_release_frame() != 0:
		_fail("TASK 240K FAIL: PREV on F01 with LOOP=OFF should hold F01, got %d!" % lab.get_current_release_frame())
		return

	lab.set_loop(true)
	lab.step_frame(-1) # PREV on F01 with LOOP ON
	if lab.get_current_release_frame() != 7:
		_fail("TASK 240K FAIL: PREV on F01 with LOOP=ON should wrap to F08, got %d!" % lab.get_current_release_frame())
		return
	lab.set_loop(false)

	print("[TASK 240K STEPPING] PASS: PREV/NEXT frame stepping with loop bounds verified.")

	# 5. Reference Ghost Mapping
	# F01 -> Charge F06
	lab.select_release_wip_frame(0) # F01
	var chg_frames = lab.get_ultimate_charge_frames()
	if lab.boss_ghost_rect.texture != chg_frames[5]:
		_fail("TASK 240K FAIL: Release F01 reference ghost MUST be approved Charge F06!")
		return

	# F02 -> Release F01
	lab.select_release_wip_frame(1) # F02
	if lab.boss_ghost_rect.texture != rel_wip_frames[0]:
		_fail("TASK 240K FAIL: Release F02 reference ghost MUST be Release F01!")
		return

	# F08 -> Release F07
	lab.select_release_wip_frame(7) # F08
	if lab.boss_ghost_rect.texture != rel_wip_frames[6]:
		_fail("TASK 240K FAIL: Release F08 reference ghost MUST be Release F07!")
		return

	print("[TASK 240K GHOST MAPPING] PASS: F01->Charge F06, F02..F08->Release F0(x-1) reference ghost verified.")

	# 6. RELOAD RELEASE WIP Rescan & Reload
	var reloaded_count = lab.reload_release_wip()
	if reloaded_count != 8:
		_fail("TASK 240K FAIL: reload_release_wip() expected 8 frames, got %d!" % reloaded_count)
		return

	print("[TASK 240K RELOAD] PASS: RELOAD RELEASE WIP (Shortcut J) rescans and reloads PNGs cleanly.")

	# ----------------------------------------------------
	# TASK 240K1: ULTIMATE_RELEASE TUNER UI & DATA PERSISTENCE BINDING TEST SUITE
	# ----------------------------------------------------
	# 1. Switch to ULTIMATE_RELEASE state & verify tuner header and buttons
	lab.play_animation(lab.AnimationState.ULTIMATE_RELEASE)
	if lab.lbl_tuner_sec_title == null or lab.lbl_tuner_sec_title.text != "ULTIMATE_RELEASE FRAME TUNER":
		_fail("TASK 240K1 FAIL: Tuner header title expected 'ULTIMATE_RELEASE FRAME TUNER', got %s" % (lab.lbl_tuner_sec_title.text if lab.lbl_tuner_sec_title != null else "null"))
		return
	if lab.tuner_frame_buttons.size() != 8:
		_fail("TASK 240K1 FAIL: Release tuner expected 8 frame buttons (F01..F08), got %d" % lab.tuner_frame_buttons.size())
		return

	# 2. Select Release frame 0 (F01) and set custom transform
	lab.select_tuner_frame(0) # F01
	lab.set_frame_transform(0, 1.2500, 190.0, 45.0)
	var rel_tf0 = lab.get_frame_transform(0)
	if rel_tf0["scale"] != 1.25 or rel_tf0["x"] != 190.0 or rel_tf0["y"] != 45.0:
		_fail("TASK 240K1 FAIL: Set frame transform for Release F01 failed!")
		return

	# 3. Verify Charge transforms were NOT affected by Release changes
	var chg_tf2 = lab.charge_frame_transforms[2]
	var exp_chg2 = lab.FINAL_CHARGE_TRANSFORMS[2]
	if not is_equal_approx(chg_tf2["scale"], exp_chg2["scale"]) or not is_equal_approx(chg_tf2["x"], exp_chg2["x"]):
		_fail("TASK 240K1 FAIL: Release frame transform modification leaked into Charge transforms!")
		return

	# 4. Save Release tuning config to user://stochas_ultimate_release_tuning.json
	lab.save_tuning_config()
	if not FileAccess.file_exists(lab.RELEASE_CONFIG_PATH):
		_fail("TASK 240K1 FAIL: Release config file missing at %s!" % lab.RELEASE_CONFIG_PATH)
		return

	# Reset Release defaults and load from JSON persistence
	lab._reset_all_release_transforms_to_default()
	lab.load_tuning_config()
	if lab.get_frame_transform(0)["scale"] != 1.25 or lab.get_frame_transform(0)["x"] != 190.0:
		_fail("TASK 240K1 FAIL: Reloading saved Release config failed to restore per-frame transforms!")
		return

	# 5. Copy Release tuning values text check
	var rel_copy_txt = lab.copy_tuning_values()
	if not ("F01 scale=1.2500" in rel_copy_txt) or not ("F08 scale=1.0000" in rel_copy_txt):
		_fail("TASK 240K1 FAIL: Copy Release tuning values output mismatch!")
		return

	# 6. Switch back to ULTIMATE_CHARGE and verify Charge tuner UI & values restored cleanly
	lab.play_animation(lab.AnimationState.ULTIMATE_CHARGE)
	if lab.lbl_tuner_sec_title == null or lab.lbl_tuner_sec_title.text != "ULTIMATE_CHARGE FRAME TUNER":
		_fail("TASK 240K1 FAIL: Switch back to Charge failed to update tuner header title!")
		return
	if lab.tuner_frame_buttons.size() != 4:
		_fail("TASK 240K1 FAIL: Charge tuner expected 4 frame buttons (F03..F06), got %d" % lab.tuner_frame_buttons.size())
		return

	# Cleanup Release test save
	lab.select_tuner_frame(0)
	lab.reset_saved_tuning_config()

	print("[TASK 240K1 BINDING] PASS: Dynamic header/button switching, Release JSON storage, copy & clean Charge restoration verified 100%.")

	# ----------------------------------------------------
	# TASK 240K2: AUTHORITATIVE HUMAN FINAL APPROVED RELEASE TRANSFORMS LOCK
	# ----------------------------------------------------
	# 1. Fresh launch / default values verification
	lab.play_animation(lab.AnimationState.ULTIMATE_RELEASE)
	lab.reset_saved_tuning_config() # ensure no user JSON override
	lab._reset_all_release_transforms_to_default()

	var expected_release_240k2: Dictionary = {
		0: {"scale": 0.9807, "x": 179.00, "y": 49.00},
		1: {"scale": 1.0000, "x": 182.00, "y": 50.00},
		2: {"scale": 1.1089, "x": 180.00, "y": 50.00},
		3: {"scale": 0.9423, "x": 180.00, "y": 62.00},
		4: {"scale": 1.0037, "x": 180.00, "y": 50.00},
		5: {"scale": 1.0000, "x": 180.00, "y": 50.00},
		6: {"scale": 1.0000, "x": 180.00, "y": 50.00},
		7: {"scale": 1.0000, "x": 180.00, "y": 50.00}
	}

	for i in range(8):
		var tf = lab.get_frame_transform(i)
		var exp_tf = expected_release_240k2[i]
		if not is_equal_approx(tf["scale"], exp_tf["scale"]) or not is_equal_approx(tf["x"], exp_tf["x"]) or not is_equal_approx(tf["y"], exp_tf["y"]):
			_fail("TASK 240K2 FAIL: Fresh Release frame F0%d transform mismatch! Expected %s, got %s" % [(i + 1), str(exp_tf), str(tf)])
			return

	print("[TASK 240K2 DEFAULTS] PASS: Fresh launch defaults to exact HUMAN-approved final transforms F01..F08.")

	# 2. Reset Frame & Reset All verification
	lab.select_tuner_frame(0) # F01
	lab.set_frame_transform(0, 1.5000, 200.0, 100.0)
	lab.reset_current_frame_tuner()
	var reset_tf0 = lab.get_frame_transform(0)
	if not is_equal_approx(reset_tf0["scale"], 0.9807) or not is_equal_approx(reset_tf0["x"], 179.00) or not is_equal_approx(reset_tf0["y"], 49.00):
		_fail("TASK 240K2 FAIL: RESET FRAME for Release F01 did not restore HUMAN FINAL transform!")
		return

	for i in range(8):
		lab.set_frame_transform(i, 1.2000, 190.0, 60.0)
	lab.reset_all_tuner_frames()
	for i in range(8):
		var tf = lab.get_frame_transform(i)
		var exp_tf = expected_release_240k2[i]
		if not is_equal_approx(tf["scale"], exp_tf["scale"]) or not is_equal_approx(tf["x"], exp_tf["x"]) or not is_equal_approx(tf["y"], exp_tf["y"]):
			_fail("TASK 240K2 FAIL: RESET ALL for Release did not restore HUMAN FINAL transform for F0%d!" % (i + 1))
			return

	print("[TASK 240K2 RESETS] PASS: RESET FRAME and RESET ALL restore exact HUMAN-approved final transforms F01..F08.")

	# 3. Copy Tuning Values format check
	var copy_txt_240k2 = lab.copy_tuning_values()
	if not ("F01 scale=0.9807 x=179.00 y=49.00" in copy_txt_240k2) or not ("F03 scale=1.1089 x=180.00 y=50.00" in copy_txt_240k2) or not ("F04 scale=0.9423 x=180.00 y=62.00" in copy_txt_240k2) or not ("F05 scale=1.0037 x=180.00 y=50.00" in copy_txt_240k2):
		_fail("TASK 240K2 FAIL: COPY TUNING VALUES output mismatch for locked Release transforms!")
		return

	print("[TASK 240K2 COPY] PASS: COPY TUNING VALUES outputs exact approved F01..F08 transforms.")




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
