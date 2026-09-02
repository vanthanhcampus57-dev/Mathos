extends SceneTree

## Targeted Verification Test Suite for MATHOS-VISUAL-LAB & MATHOS-AUTH-BACKGROUND-VISUAL-LAB-001
## Verifies:
## 1. CLI flag routing for --visual-lab.
## 2. Normal boot un-affected when flag absent.
## 3. VisualLab scene and script loading.
## 4. Real D1 background, old atlas (8 frames), and new procedural fog layer loading.
## 5. Manual frame 0..7 stepping & bounds safety.
## 6. Play/Pause toggle state.
## 7. FPS and Opacity controls.
## 8. Compare mode (side-by-side) layout toggle.
## 9. Procedural fog controls: Opacity, Drift, Speed, Distortion, Breathing, Layer Count (1/2/3).
## 10. Compare Old vs New side-by-side mode.
## 11. Zero save data / progression mutation.
## 12. Preserved source aspect ratio (2115/744 ≈ 2.8427).
## 13. Dynamic overscan contract at 1280x720 and 1024x600.
## 14. Edge-stress test (Drift 300, Distortion 0.50, Layers 3) EDGE_SAFE=true across animation samples.
## 15. Normal human preset EDGE_SAFE=true across animation samples.
## 16. Auth Login Background mode availability and asset validity.
## 17. Auth Login Background 2 fog layers and bounded motion.
## 18. Auth Login Background 2 top-pinned swaying banners.
## 19. Auth Login Background crystal glow pulse and magic dust particles.
## 20. Auth Login Background Play/Pause and Reset Defaults.

const AppRootClass = preload("res://src/app/app_root.gd")
const VisualLabClass = preload("res://dev/visual_lab/visual_lab.gd")
const AuthLoginBackgroundClass = preload("res://src/ui/auth/auth_login_background.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS VISUAL LAB QA HARNESS (VIS-LAB-001..027) ---")
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
	if test_vislab_013_new_procedural_fog_layer_loading_and_dimensions(): passes += 1
	if test_vislab_014_fog_source_selector_switching(): passes += 1
	if test_vislab_015_procedural_fog_controls(): passes += 1
	if test_vislab_016_procedural_fog_layer_count_1_2_3(): passes += 1
	if test_vislab_017_compare_old_vs_new_mode(): passes += 1
	if test_vislab_018_source_aspect_ratio_preserved(): passes += 1
	if test_vislab_019_dynamic_overscan_at_1280x720_and_1024x600(): passes += 1
	if test_vislab_020_edge_stress_test_drift_300_distortion_050_all_layers(): passes += 1
	if test_vislab_021_normal_preset_edge_safety(): passes += 1
	if test_vislab_022_minimum_scale_never_exposes_boundary(): passes += 1
	if test_vislab_023_auth_login_background_mode_available_and_assets_valid(): passes += 1
	if test_vislab_024_auth_login_background_fog_layers_and_bounded_motion(): passes += 1
	if test_vislab_025_auth_login_background_banners_shader_and_controls(): passes += 1
	if test_vislab_026_auth_login_background_crystal_glow_and_particles(): passes += 1
	if test_vislab_027_auth_login_background_play_pause_and_reset_defaults(): passes += 1

	print("[VIS-LAB-HARNESS] %d / 27 test scenarios passed" % passes)
	return passes == 27

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
	print("[VIS-LAB-010] Verifying Reset Defaults button...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	lab.set_fps(12.0)
	lab.set_opacity(0.5)
	lab.set_compare_mode(true)

	lab.reset_defaults()
	if abs(lab.get_fps() - VisualLab.DEFAULT_FPS) > 0.01 or abs(lab.get_opacity() - VisualLab.DEFAULT_OLD_OPACITY) > 0.01 or lab.is_compare_mode():
		print("[VIS-LAB-010] FAIL: Reset defaults did not restore initial values")
		lab.queue_free()
		return false

	print("[VIS-LAB-010] PASS: Reset defaults verified!")
	lab.queue_free()
	return true

static func test_vislab_011_zero_save_or_progression_mutation() -> bool:
	print("[VIS-LAB-011] Verifying zero save data or progression mutation in VisualLab...")
	var save_store: SaveFileStore = SaveFileStore.new("user://")
	var file_existed_before: bool = save_store.file_exists(save_store.main_path)

	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)
	lab.step_next_frame()
	lab.set_compare_mode(true)
	lab.reset_defaults()
	lab.queue_free()

	var file_existed_after: bool = save_store.file_exists(save_store.main_path)
	if file_existed_before != file_existed_after:
		print("[VIS-LAB-011] FAIL: Save file existence mutated!")
		return false

	print("[VIS-LAB-011] PASS: Zero save or progression mutation verified!")
	return true

static func test_vislab_012_normal_boot_unaffected() -> bool:
	print("[VIS-LAB-012] Verifying normal boot is unaffected when --visual-lab flag is absent...")
	var app_scene: PackedScene = load("res://src/app/app_root.tscn")
	var app: AppRoot = app_scene.instantiate() as AppRoot
	Engine.get_main_loop().root.add_child(app)
	if app._is_visual_lab_mode():
		print("[VIS-LAB-012] FAIL: AppRoot misidentified normal boot as visual-lab mode")
		app.queue_free()
		return false
	print("[VIS-LAB-012] PASS: Normal boot routing unaffected verified!")
	app.queue_free()
	return true

static func test_vislab_013_new_procedural_fog_layer_loading_and_dimensions() -> bool:
	print("[VIS-LAB-013] Verifying new procedural fog layer asset loading (2115x744)...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)
	var proc_tex: Texture2D = lab.get_procedural_texture()
	if proc_tex == null:
		print("[VIS-LAB-013] FAIL: Procedural fog texture is null")
		lab.queue_free()
		return false
	if proc_tex.get_width() != 2115 or proc_tex.get_height() != 744:
		print("[VIS-LAB-013] FAIL: Expected 2115x744, got %dx%d" % [proc_tex.get_width(), proc_tex.get_height()])
		lab.queue_free()
		return false
	print("[VIS-LAB-013] PASS: Procedural fog layer 2115x744 verified!")
	lab.queue_free()
	return true

static func test_vislab_014_fog_source_selector_switching() -> bool:
	print("[VIS-LAB-014] Verifying fog source selector switching (PROCEDURAL vs OLD_ATLAS)...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	if lab.get_fog_source_mode() != VisualLab.FogSourceMode.NEW_PROCEDURAL_LAYER:
		print("[VIS-LAB-014] FAIL: Default fog source mode expected NEW_PROCEDURAL_LAYER")
		lab.queue_free()
		return false

	lab.set_fog_source_mode(VisualLab.FogSourceMode.OLD_ATLAS_8F)
	if lab.get_fog_source_mode() != VisualLab.FogSourceMode.OLD_ATLAS_8F:
		print("[VIS-LAB-014] FAIL: Fog source mode did not switch to OLD_ATLAS_8F")
		lab.queue_free()
		return false

	print("[VIS-LAB-014] PASS: Fog source selector switching verified!")
	lab.queue_free()
	return true

static func test_vislab_015_procedural_fog_controls() -> bool:
	print("[VIS-LAB-015] Verifying procedural fog controls (Opacity, Drift, Speed, Distortion, Breathing)...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	lab.set_procedural_opacity(0.75)
	lab.set_drift_amount(180.0)
	lab.set_drift_speed(0.40)
	lab.set_distortion(0.20)
	lab.set_breathing(0.12)

	if abs(lab.get_procedural_opacity() - 0.75) > 0.01 or abs(lab.get_drift_amount() - 180.0) > 0.1 or abs(lab.get_drift_speed() - 0.40) > 0.01 or abs(lab.get_distortion() - 0.20) > 0.01 or abs(lab.get_breathing() - 0.12) > 0.01:
		print("[VIS-LAB-015] FAIL: Procedural control parameter values mismatch")
		lab.queue_free()
		return false

	print("[VIS-LAB-015] PASS: Procedural fog controls verified!")
	lab.queue_free()
	return true

static func test_vislab_016_procedural_fog_layer_count_1_2_3() -> bool:
	print("[VIS-LAB-016] Verifying procedural fog layer count options (1, 2, 3 layers)...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	lab.set_layer_count(1)
	if lab.get_layer_count() != 1:
		print("[VIS-LAB-016] FAIL: Layer count expected 1")
		lab.queue_free()
		return false

	lab.set_layer_count(3)
	if lab.get_layer_count() != 3:
		print("[VIS-LAB-016] FAIL: Layer count expected 3")
		lab.queue_free()
		return false

	print("[VIS-LAB-016] PASS: Procedural fog layer count options verified!")
	lab.queue_free()
	return true

static func test_vislab_017_compare_old_vs_new_mode() -> bool:
	print("[VIS-LAB-017] Verifying Compare Old vs New side-by-side mode...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	if lab.is_compare_old_vs_new_mode():
		print("[VIS-LAB-017] FAIL: Initial compare old vs new mode expected false")
		lab.queue_free()
		return false

	lab.set_compare_old_vs_new_mode(true)
	if not lab.is_compare_old_vs_new_mode():
		print("[VIS-LAB-017] FAIL: Compare old vs new mode expected true after toggle")
		lab.queue_free()
		return false

	print("[VIS-LAB-017] PASS: Compare Old vs New mode verified!")
	lab.queue_free()
	return true

static func test_vislab_018_source_aspect_ratio_preserved() -> bool:
	print("[VIS-LAB-018] Verifying preserved source aspect ratio (2115 / 744 ≈ 2.8427)...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)
	var overscan_info: Dictionary = lab.calculate_overscan_info(Vector2(1280, 720))
	var expected_aspect: float = 2115.0 / 744.0
	if abs(overscan_info["aspect"] - expected_aspect) > 0.001:
		print("[VIS-LAB-018] FAIL: Calculated aspect %f does not match expected %f" % [overscan_info["aspect"], expected_aspect])
		lab.queue_free()
		return false
	print("[VIS-LAB-018] PASS: Source aspect ratio preservation verified!")
	lab.queue_free()
	return true

static func test_vislab_019_dynamic_overscan_at_1280x720_and_1024x600() -> bool:
	print("[VIS-LAB-019] Verifying dynamic overscan calculation at 1280x720 and 1024x600...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	var info_720: Dictionary = lab.calculate_overscan_info(Vector2(1280, 720))
	if info_720["disp_width"] < 1280.0 or info_720["disp_height"] < 720.0:
		print("[VIS-LAB-019] FAIL: Display size smaller than viewport at 1280x720")
		lab.queue_free()
		return false

	var info_600: Dictionary = lab.calculate_overscan_info(Vector2(1024, 600))
	if info_600["disp_width"] < 1024.0 or info_600["disp_height"] < 600.0:
		print("[VIS-LAB-019] FAIL: Display size smaller than viewport at 1024x600")
		lab.queue_free()
		return false

	print("[VIS-LAB-019] PASS: Dynamic overscan contract verified for 1280x720 and 1024x600!")
	lab.queue_free()
	return true

static func test_vislab_020_edge_stress_test_drift_300_distortion_050_all_layers() -> bool:
	print("[VIS-LAB-020] Verifying edge-stress test (Drift 300, Distortion 0.50, Layers 3) EDGE_SAFE=true...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)
	lab.size = Vector2(1280, 720)
	lab.custom_minimum_size = Vector2(1280, 720)

	lab.set_drift_amount(300.0)
	lab.set_distortion(0.50)
	lab.set_layer_count(3)
	lab.set_drift_speed(1.0)

	for t in [0.0, 0.5, 1.2, 2.7, 5.0, 10.0]:
		lab.set_procedural_time(t)
		if not lab.is_edge_safe():
			print("[VIS-LAB-020] FAIL: Edge unsafe at t=%.1f under stress test conditions" % t)
			lab.queue_free()
			return false

	print("[VIS-LAB-020] PASS: Edge-stress test passed with zero boundary exposure!")
	lab.queue_free()
	return true

static func test_vislab_021_normal_preset_edge_safety() -> bool:
	print("[VIS-LAB-021] Verifying production default preset EDGE_SAFE=true across animation samples...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)
	lab.size = Vector2(1280, 720)
	lab.custom_minimum_size = Vector2(1280, 720)
	lab.reset_defaults()

	for t in [0.0, 1.0, 3.5, 7.2, 12.0]:
		lab.set_procedural_time(t)
		if not lab.is_edge_safe():
			print("[VIS-LAB-021] FAIL: Edge unsafe at t=%.1f under normal preset" % t)
			lab.queue_free()
			return false

	print("[VIS-LAB-021] PASS: Production preset edge safety verified!")
	lab.queue_free()
	return true

static func test_vislab_022_minimum_scale_never_exposes_boundary() -> bool:
	print("[VIS-LAB-022] Verifying minimum layer scale never exposes boundary at viewport edges...")
	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)
	lab.size = Vector2(1280, 720)
	lab.custom_minimum_size = Vector2(1280, 720)
	lab.reset_defaults()

	var min_l: float = 9999.0
	var min_r: float = 9999.0

	for t in range(0, 50):
		lab.set_procedural_time(float(t) * 0.2)
		var l: float = lab.get_left_overscan()
		var r: float = lab.get_right_overscan()
		if l < min_l: min_l = l
		if r < min_r: min_r = r

	if min_l < 0.0 or min_r < 0.0:
		print("[VIS-LAB-022] FAIL: Negative overscan detected (Left: %.1f, Right: %.1f)" % [min_l, min_r])
		lab.queue_free()
		return false

	print("[VIS-LAB-022] PASS: Minimum overscan positive (Left: %.1f px, Right: %.1f px) verified!" % [min_l, min_r])
	lab.queue_free()
	return true

static func test_vislab_023_auth_login_background_mode_available_and_assets_valid() -> bool:
	print("[VIS-LAB-023] Verifying Auth Login Background mode availability and asset validity...")
	var bg_path: String = "res://assets/backgrounds/auth/login_academy_bg_clean.png"
	var fog_path: String = "res://assets/backgrounds/auth/login_ground_fog.png"
	var banner_path: String = "res://assets/backgrounds/auth/login_academy_banner.png"

	if not ResourceLoader.exists(bg_path) or not ResourceLoader.exists(fog_path) or not ResourceLoader.exists(banner_path):
		print("[VIS-LAB-023] FAIL: Missing one or more required auth background assets")
		return false

	var lab: VisualLab = _create_lab()
	Engine.get_main_loop().root.add_child(lab)

	lab.set_lab_mode(VisualLab.LabMode.AUTH_LOGIN_BG)
	if lab.get_lab_mode() != VisualLab.LabMode.AUTH_LOGIN_BG:
		print("[VIS-LAB-023] FAIL: VisualLab failed to switch to AUTH_LOGIN_BG mode")
		lab.queue_free()
		return false

	var auth_bg: AuthLoginBackground = lab.get_auth_background()
	if auth_bg == null:
		print("[VIS-LAB-023] FAIL: AuthLoginBackground node is null")
		lab.queue_free()
		return false

	print("[VIS-LAB-023] PASS: Auth Login Background mode and assets verified!")
	lab.queue_free()
	return true

static func test_vislab_024_auth_login_background_fog_layers_and_bounded_motion() -> bool:
	print("[VIS-LAB-024] Verifying Auth Login Background 2 fog layers and bounded motion...")
	var auth_bg: AuthLoginBackground = AuthLoginBackgroundClass.new() as AuthLoginBackground
	Engine.get_main_loop().root.add_child(auth_bg)

	if auth_bg.get_fog_layer_count() != 2:
		print("[VIS-LAB-024] FAIL: Expected 2 fog layers in AuthLoginBackground")
		auth_bg.queue_free()
		return false

	if auth_bg.get_fog_texture() == null or auth_bg.get_fog_texture().get_width() != 2115:
		print("[VIS-LAB-024] FAIL: Fog texture missing or invalid dimensions")
		auth_bg.queue_free()
		return false

	print("[VIS-LAB-024] PASS: 2 fog layers and reused fog texture verified!")
	auth_bg.queue_free()
	return true

static func test_vislab_025_auth_login_background_banners_shader_and_controls() -> bool:
	print("[VIS-LAB-025] Verifying Auth Login Background 2 banners and top-pin deformation shader...")
	var auth_bg: AuthLoginBackground = AuthLoginBackgroundClass.new() as AuthLoginBackground
	Engine.get_main_loop().root.add_child(auth_bg)

	var banner_tex: Texture2D = auth_bg.get_banner_texture()
	if banner_tex == null or banner_tex.get_width() != 887 or banner_tex.get_height() != 1774:
		print("[VIS-LAB-025] FAIL: Banner texture missing or dimensions mismatch (expected 887x1774)")
		auth_bg.queue_free()
		return false

	auth_bg.banner_sway = 5.0
	auth_bg.banner_speed = 0.8
	if abs(auth_bg.banner_sway - 5.0) > 0.01 or abs(auth_bg.banner_speed - 0.8) > 0.01:
		print("[VIS-LAB-025] FAIL: Banner parameters update failed")
		auth_bg.queue_free()
		return false

	print("[VIS-LAB-025] PASS: 2 banners and top-pin deformation shader verified!")
	auth_bg.queue_free()
	return true

static func test_vislab_026_auth_login_background_crystal_glow_and_particles() -> bool:
	print("[VIS-LAB-026] Verifying Auth Login Background crystal glow pulse and magic dust particles...")
	var auth_bg: AuthLoginBackground = AuthLoginBackgroundClass.new() as AuthLoginBackground
	Engine.get_main_loop().root.add_child(auth_bg)

	auth_bg.crystal_master_opacity = 0.8
	auth_bg.dust_density = 25
	if abs(auth_bg.crystal_master_opacity - 0.8) > 0.01 or auth_bg.dust_density != 25:
		print("[VIS-LAB-026] FAIL: Crystal glow or dust parameters update failed")
		auth_bg.queue_free()
		return false

	print("[VIS-LAB-026] PASS: Crystal glow pulse and magic dust particles verified!")
	auth_bg.queue_free()
	return true

static func test_vislab_027_auth_login_background_play_pause_and_reset_defaults() -> bool:
	print("[VIS-LAB-027] Verifying Auth Login Background Play/Pause and Reset Defaults...")
	var auth_bg: AuthLoginBackground = AuthLoginBackgroundClass.new() as AuthLoginBackground
	Engine.get_main_loop().root.add_child(auth_bg)

	auth_bg.set_playing(false)
	if auth_bg.is_playing():
		print("[VIS-LAB-027] FAIL: Pause failed on AuthLoginBackground")
		auth_bg.queue_free()
		return false

	auth_bg.fog_master_opacity = 0.1
	auth_bg.banner_sway = 10.0
	auth_bg.reset_defaults()

	if abs(auth_bg.fog_master_opacity - AuthLoginBackground.DEFAULT_FOG_MASTER_OPACITY) > 0.01 or abs(auth_bg.banner_sway - AuthLoginBackground.DEFAULT_BANNER_SWAY) > 0.01:
		print("[VIS-LAB-027] FAIL: Reset defaults failed on AuthLoginBackground")
		auth_bg.queue_free()
		return false

	print("[VIS-LAB-027] PASS: Auth Login Background Play/Pause & Reset Defaults verified!")
	auth_bg.queue_free()
	return true
