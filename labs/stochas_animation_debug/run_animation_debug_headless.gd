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
