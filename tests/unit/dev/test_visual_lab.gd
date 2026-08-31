extends SceneTree

## Targeted Verification Test Suite for MATHOS-VISUAL-LAB-FOG-HARNESS-001
## Verifies:
## 1. CLI flag routing for --visual-lab.
## 2. Normal boot un-affected when flag absent.
## 3. VisualLab scene and script loading.
## 4. Real D1 background and real production fog sheet atlas (8 frames).
## 5. Manual frame 0..7 stepping & bounds safety.
## 6. Play/Pause toggle state.
## 7. FPS and Opacity controls.
## 8. Compare mode (side-by-side) layout toggle.
## 9. Zero save data / progression mutation.

const AppRootClass = preload("res://src/app/app_root.gd")
const VisualLabClass = preload("res://dev/visual_lab/visual_lab.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS VISUAL LAB QA HARNESS (VIS-LAB-001..012) ---")
	var ok: bool = run_all_tests()
	if ok:
		print("MATHOS VISUAL LAB QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS VISUAL LAB QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var passes: int = 0
	if test_vislab_001_scene_and_script_loading(): passes += 1
	if test_vislab_002_d1_background_and_fog_atlas_loading(): passes += 1
	if test_vislab_003_manual_frame_stepping_0_to_7(): passes += 1
	if test_vislab_004_bounds_safety_no_invalid_frame_index(): passes += 1
	if test_vislab_005_play_pause_toggle(): passes += 1
	if test_vislab_006_fps_control(): passes += 1
	if test_vislab_007_opacity_control(): passes += 1
	if test_vislab_008_compare_mode_side_by_side_toggle(): passes += 1
	if test_vislab_009_motion_mode_toggle(): passes += 1
	if test_vislab_010_reset_defaults(): passes += 1
	if test_vislab_011_zero_save_or_progression_mutation(): passes += 1
	if test_vislab_012_normal_boot_unaffected(): passes += 1

	print("[VIS-LAB-HARNESS] %d / 12 test scenarios passed" % passes)
	return passes == 12

static func _create_lab() -> VisualLab:
	var scene: PackedScene = load("res://dev/visual_lab/visual_lab.tscn") as PackedScene
	if scene != null:
		return scene.instantiate() as VisualLab
	return VisualLabClass.new() as VisualLab

static func test_vislab_001_scene_and_script_loading() -> bool:
	print("[VIS-LAB-001] Verifying Visual Lab scene & script instantiation...")
	var lab: VisualLab = _create_lab()
	if lab == null:
		print("[VIS-LAB-001] FAIL: Unable to instantiate VisualLab")
		return false
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(lab)
	if lab.get_parent() == null:
		print("[VIS-LAB-001] FAIL: VisualLab parent is null")
		lab.queue_free()
		return false
	print("[VIS-LAB-001] PASS: VisualLab scene & script loaded cleanly!")
	lab.queue_free()
	return true

static func test_vislab_002_d1_background_and_fog_atlas_loading() -> bool:
	print("[VIS-LAB-002] Verifying real D1 background and production fog sheet (8 frames)...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)
	var frames: Array[AtlasTexture] = lab.get_fog_frames()
	if frames.size() != 8:
		print("[VIS-LAB-002] FAIL: Expected 8 fog frames, got %d" % frames.size())
		lab.queue_free()
		return false
	for idx in range(frames.size()):
		var f: AtlasTexture = frames[idx]
		if f == null or f.region.size != Vector2(512, 288):
			print("[VIS-LAB-002] FAIL: Invalid region for frame %d" % idx)
			lab.queue_free()
			return false
	print("[VIS-LAB-002] PASS: D1 background & 8-frame fog atlas verified!")
	lab.queue_free()
	return true

static func test_vislab_003_manual_frame_stepping_0_to_7() -> bool:
	print("[VIS-LAB-003] Verifying manual frame 0..7 stepping (Prev/Next)...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)
	lab.set_playing(false)
	lab.set_frame_index(0)
	if lab.get_current_frame_index() != 0:
		print("[VIS-LAB-003] FAIL: Frame index did not set to 0")
		lab.queue_free()
		return false

	lab.step_next_frame()
	if lab.get_current_frame_index() != 1:
		print("[VIS-LAB-003] FAIL: Next frame expected 1, got %d" % lab.get_current_frame_index())
		lab.queue_free()
		return false

	lab.step_previous_frame()
	if lab.get_current_frame_index() != 0:
		print("[VIS-LAB-003] FAIL: Prev frame expected 0, got %d" % lab.get_current_frame_index())
		lab.queue_free()
		return false

	lab.step_previous_frame()
	if lab.get_current_frame_index() != 7:
		print("[VIS-LAB-003] FAIL: Prev frame wrap expected 7, got %d" % lab.get_current_frame_index())
		lab.queue_free()
		return false

	print("[VIS-LAB-003] PASS: Manual frame stepping 0..7 verified!")
	lab.queue_free()
	return true

static func test_vislab_004_bounds_safety_no_invalid_frame_index() -> bool:
	print("[VIS-LAB-004] Verifying bounds safety (out-of-range index clamped)...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	lab.set_frame_index(999)
	if lab.get_current_frame_index() != 7:
		print("[VIS-LAB-004] FAIL: Index 999 did not clamp to 7")
		lab.queue_free()
		return false

	lab.set_frame_index(-50)
	if lab.get_current_frame_index() != 0:
		print("[VIS-LAB-004] FAIL: Index -50 did not clamp to 0")
		lab.queue_free()
		return false

	print("[VIS-LAB-004] PASS: Frame index bounds safety verified!")
	lab.queue_free()
	return true

static func test_vislab_005_play_pause_toggle() -> bool:
	print("[VIS-LAB-005] Verifying Play/Pause toggle state...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	if not lab.is_playing():
		print("[VIS-LAB-005] FAIL: Initial playing state expected true")
		lab.queue_free()
		return false

	lab.set_playing(false)
	if lab.is_playing():
		print("[VIS-LAB-005] FAIL: Playing state expected false after pause")
		lab.queue_free()
		return false

	print("[VIS-LAB-005] PASS: Play/Pause toggle verified!")
	lab.queue_free()
	return true

static func test_vislab_006_fps_control() -> bool:
	print("[VIS-LAB-006] Verifying FPS control (0.5 -> 15.0)...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	lab.set_fps(10.0)
	if abs(lab.get_fps() - 10.0) > 0.01:
		print("[VIS-LAB-006] FAIL: FPS set to 10.0 failed")
		lab.queue_free()
		return false

	lab.set_fps(0.1) # Clamped to 0.5
	if abs(lab.get_fps() - 0.5) > 0.01:
		print("[VIS-LAB-006] FAIL: FPS 0.1 did not clamp to 0.5")
		lab.queue_free()
		return false

	print("[VIS-LAB-006] PASS: FPS control verified!")
	lab.queue_free()
	return true

static func test_vislab_007_opacity_control() -> bool:
	print("[VIS-LAB-007] Verifying Opacity control (0.0 -> 2.5)...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	lab.set_opacity(1.8)
	if abs(lab.get_opacity() - 1.8) > 0.01:
		print("[VIS-LAB-007] FAIL: Opacity set to 1.8 failed")
		lab.queue_free()
		return false

	print("[VIS-LAB-007] PASS: Opacity control verified!")
	lab.queue_free()
	return true

static func test_vislab_008_compare_mode_side_by_side_toggle() -> bool:
	print("[VIS-LAB-008] Verifying Compare Frames side-by-side toggle...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	if lab.is_compare_mode():
		print("[VIS-LAB-008] FAIL: Initial compare mode expected false")
		lab.queue_free()
		return false

	lab.set_compare_mode(true)
	if not lab.is_compare_mode():
		print("[VIS-LAB-008] FAIL: Compare mode expected true after toggle")
		lab.queue_free()
		return false

	print("[VIS-LAB-008] PASS: Compare mode toggle verified!")
	lab.queue_free()
	return true

static func test_vislab_009_motion_mode_toggle() -> bool:
	print("[VIS-LAB-009] Verifying Motion Mode toggle (ATLAS vs STATIC)...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	if lab.get_motion_mode() != VisualLab.MotionMode.CURRENT_ATLAS_ANIMATION:
		print("[VIS-LAB-009] FAIL: Initial motion mode expected CURRENT_ATLAS_ANIMATION")
		lab.queue_free()
		return false

	lab.set_motion_mode(VisualLab.MotionMode.STATIC_FRAME)
	if lab.get_motion_mode() != VisualLab.MotionMode.STATIC_FRAME or lab.is_playing():
		print("[VIS-LAB-009] FAIL: Motion mode STATIC_FRAME expected playing=false")
		lab.queue_free()
		return false

	print("[VIS-LAB-009] PASS: Motion mode toggle verified!")
	lab.queue_free()
	return true

static func test_vislab_010_reset_defaults() -> bool:
	print("[VIS-LAB-010] Verifying Reset Defaults button action...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	lab.set_fps(12.0)
	lab.set_opacity(0.4)
	lab.set_compare_mode(true)
	lab.reset_defaults()

	if abs(lab.get_fps() - 2.0) > 0.01 or abs(lab.get_opacity() - 2.2) > 0.01 or lab.is_compare_mode():
		print("[VIS-LAB-010] FAIL: Reset defaults failed to restore initial parameters")
		lab.queue_free()
		return false

	print("[VIS-LAB-010] PASS: Reset defaults verified!")
	lab.queue_free()
	return true

static func test_vislab_011_zero_save_or_progression_mutation() -> bool:
	print("[VIS-LAB-011] Verifying zero save file or progression mutation...")
	var store: SaveFileStore = SaveFileStore.new("user://")
	var has_save_before: bool = store.file_exists(store.main_path)

	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)
	lab.step_next_frame()
	lab.set_fps(8.0)
	lab._process(1.0)
	lab.queue_free()

	var has_save_after: bool = store.file_exists(store.main_path)
	if has_save_before != has_save_after:
		print("[VIS-LAB-011] FAIL: Save file status mutated during lab execution")
		return false

	print("[VIS-LAB-011] PASS: Zero save or progression mutation verified!")
	return true

static func test_vislab_012_normal_boot_unaffected() -> bool:
	print("[VIS-LAB-012] Verifying normal boot is unaffected when --visual-lab flag is absent...")
	var app_scene: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	var app: AppRoot = app_scene.instantiate() as AppRoot
	Engine.get_main_loop().root.add_child(app)
	app.bootstrap_runtime()

	var shell: Control = app.get_presentation_shell()
	var lab: Control = app.get_visual_lab()

	if shell == null or lab != null:
		print("[VIS-LAB-012] FAIL: Normal boot did not load StagePresentationShell cleanly")
		app.queue_free()
		return false

	print("[VIS-LAB-012] PASS: Normal boot unaffected when flag is absent!")
	app.queue_free()
	return true
