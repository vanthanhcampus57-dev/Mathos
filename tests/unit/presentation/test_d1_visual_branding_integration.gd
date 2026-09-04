extends SceneTree

## Targeted Verification Test Suite for MATHOS-D1-PROCEDURAL-FOG-PRODUCTION-INTEGRATION-004
## Verifies:
## A. Asset contracts (bg 1280x720, old fog 2048x576, procedural fog 2115x744, logo_main 1536x512, emblem 512x512).
## B. Production D1 fog uses 3-layer procedural fog system with locked preset (0.48 / 120 / 0.15 / 0.08 / 0.05 / 3).
## C. Old atlas fog disabled in normal production path, but preserved for Visual Lab / backward compatibility.
## D. Presentation hierarchy (bg < procedural fog container < normal UI < QA CanvasLayer).
## E. Mouse interaction safety (mouse_filter = MOUSE_FILTER_IGNORE on procedural fog nodes).
## F. Lifecycle (single fog instance, no duplication across question transitions).
## G. Viewport resolution bounds & EDGE_SAFE contract at 1280x720 & 1024x600.
## H. Dungeon 1 scoping (D1 uses forest bg + procedural fog, non-D1 disables fog).

const AppRootClass = preload("res://src/app/app_root.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS D1 VISUAL & BRANDING QA HARNESS ---")
	var ok: bool = run_all_tests()
	if ok:
		print("MATHOS D1 VISUAL & BRANDING QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS D1 VISUAL & BRANDING QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var passes: int = 0
	if test_visual_001_asset_contracts_and_dimensions(): passes += 1
	if test_visual_002_fog_atlas_structure_and_fps(): passes += 1
	if test_visual_003_presentation_hierarchy_and_layering(): passes += 1
	if test_visual_004_mouse_interaction_safety(): passes += 1
	if test_visual_005_fog_lifecycle_and_single_instance(): passes += 1
	if test_visual_006_viewport_resolutions_1280x720_and_1024x600(): passes += 1
	if test_visual_007_dungeon_1_scoping(): passes += 1
	if test_visual_008_procedural_fog_production_preset_and_layers(): passes += 1
	if test_visual_009_application_icon_configuration(): passes += 1

	print("[D1-VISUAL-HARNESS] %d / 9 test scenarios passed" % passes)
	return passes == 9

static func _create_app(vp_size: Vector2 = Vector2(1280, 720)) -> AppRoot:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var root: Window = tree.root
	root.size = Vector2i(int(vp_size.x), int(vp_size.y))

	var app_scene: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	var app: AppRoot = app_scene.instantiate() as AppRoot
	root.add_child(app)
	app.bootstrap_runtime()
	return app

static func test_visual_001_asset_contracts_and_dimensions() -> bool:
	print("[VIS-001] Verifying asset paths and pixel dimensions...")
	var assets: Array = [
		{"paths": ["res://assets/backgrounds/dungeon_1/d1_misty_forest_bg.png", "res://assets/backgrounds/d1_misty_forest_bg.png"], "w": 1280, "h": 720},
		{"paths": ["res://assets/backgrounds/dungeon_1/d1_misty_forest_fog_8f.png", "res://assets/backgrounds/d1_misty_forest_fog_8f.png"], "w": 2048, "h": 576},
		{"paths": ["res://assets/backgrounds/d1_misty_forest_fog_layer.png"], "w": 2115, "h": 744},
		{"paths": ["res://assets/branding/mathos_logo_main.png"], "w": 1536, "h": 512},
		{"paths": ["res://assets/branding/mathos_logo_emblem.png"], "w": 512, "h": 512},
		{"paths": ["res://assets/items/fragments/fragment_01.png"], "w": 512, "h": 512}
	]

	for item in assets:
		var paths: Array = item["paths"] as Array
		var exp_w: int = item["w"]
		var exp_h: int = item["h"]
		var found: bool = false
		for p in paths:
			var p_str: String = String(p)
			var global_p: String = ProjectSettings.globalize_path(p_str)
			var img: Image = Image.new()
			if img.load(global_p) == OK or img.load(p_str) == OK:
				if img.get_width() == exp_w and img.get_height() == exp_h:
					found = true
					break

		if not found:
			print("[VIS-001] FAIL: Asset contract missing or wrong dimensions for '%s'" % String(paths[0]))
			return false

	print("[VIS-001] PASS: All 5 branding & D1 visual assets (including 2115x744 fog layer) verified!")
	return true

static func test_visual_002_fog_atlas_structure_and_fps() -> bool:
	print("[VIS-002] Verifying historical fog atlas preservation for Visual Lab...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var shell: StagePresentationShell = app.get_node_or_null("StagePresentationShell") as StagePresentationShell

	if shell == null:
		print("[VIS-002] FAIL: StagePresentationShell not found")
		app.queue_free()
		return false

	var frames: Array[AtlasTexture] = shell.get_fog_frames()
	if frames.size() != 8:
		print("[VIS-002] FAIL: Expected 8 fog frames, got %d" % frames.size())
		app.queue_free()
		return false

	for idx in range(frames.size()):
		var atlas_tex: AtlasTexture = frames[idx]
		if atlas_tex == null or atlas_tex.region.size != Vector2(512, 288):
			print("[VIS-002] FAIL: Fog frame %d region invalid: %s" % [idx, str(atlas_tex.region if atlas_tex != null else "null")])
			app.queue_free()
			return false

	print("[VIS-002] PASS: Historical fog atlas preserved cleanly for Visual Lab!")
	app.queue_free()
	return true

static func test_visual_003_presentation_hierarchy_and_layering() -> bool:
	print("[VIS-003] Verifying layering contract: Static BG < Procedural Fog Container < Normal UI < QA Cheat...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var shell: StagePresentationShell = app.get_node_or_null("StagePresentationShell") as StagePresentationShell

	var bg_rect: Control = shell.get_node_or_null("BackgroundTextureRect") as Control
	var proc_container: Control = shell.get_procedural_fog_container()
	var vbox_ui: Control = shell.get_node_or_null("VBoxContainer") as Control

	if bg_rect == null or proc_container == null or vbox_ui == null:
		print("[VIS-003] FAIL: Missing presentation nodes in shell")
		app.queue_free()
		return false

	if bg_rect.get_index() >= proc_container.get_index():
		print("[VIS-003] FAIL: Static background (index %d) not below Procedural Fog Container (index %d)" % [bg_rect.get_index(), proc_container.get_index()])
		app.queue_free()
		return false

	if proc_container.get_index() >= vbox_ui.get_index():
		print("[VIS-003] FAIL: Procedural Fog Container (index %d) not below Presentation UI (index %d)" % [proc_container.get_index(), vbox_ui.get_index()])
		app.queue_free()
		return false

	var qa_overlay: Control = app.get_qa_overlay()
	if qa_overlay != null:
		var qa_canvas: CanvasLayer = qa_overlay.get_node_or_null("CanvasLayer") as CanvasLayer
		if qa_canvas != null and qa_canvas.layer < 1:
			print("[VIS-003] FAIL: QA Cheat CanvasLayer priority level insufficient")
			app.queue_free()
			return false

	print("[VIS-003] PASS: Layering contract background < procedural fog < UI < QA verified!")
	app.queue_free()
	return true

static func test_visual_004_mouse_interaction_safety() -> bool:
	print("[VIS-004] Verifying mouse_filter = IGNORE on background and procedural fog controls...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var shell: StagePresentationShell = app.get_node_or_null("StagePresentationShell") as StagePresentationShell

	var bg_rect: Control = shell.get_node_or_null("BackgroundTextureRect") as Control
	var proc_container: Control = shell.get_procedural_fog_container()

	if bg_rect.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		print("[VIS-004] FAIL: BackgroundTextureRect mouse_filter is not IGNORE (got %d)" % bg_rect.mouse_filter)
		app.queue_free()
		return false

	if proc_container.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		print("[VIS-004] FAIL: ProceduralFogContainer mouse_filter is not IGNORE (got %d)" % proc_container.mouse_filter)
		app.queue_free()
		return false

	for child in proc_container.get_children():
		if child is Control and (child as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			print("[VIS-004] FAIL: Layer %s mouse_filter is not IGNORE" % child.name)
			app.queue_free()
			return false

	print("[VIS-004] PASS: Background and procedural fog mouse interaction safety verified!")
	app.queue_free()
	return true

static func test_visual_005_fog_lifecycle_and_single_instance() -> bool:
	print("[VIS-005] Verifying single procedural fog container and zero duplication across transitions...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	app.start_new_game()

	var shell: StagePresentationShell = app.get_node_or_null("StagePresentationShell") as StagePresentationShell
	var fog_count_before: int = 0
	for child in shell.get_children():
		if child.name == "ProceduralFogContainer":
			fog_count_before += 1

	# Transition through questions
	app._on_lesson_continue_requested()

	var fog_count_after: int = 0
	for child in shell.get_children():
		if child.name == "ProceduralFogContainer":
			fog_count_after += 1

	if fog_count_before != 1 or fog_count_after != 1:
		print("[VIS-005] FAIL: Procedural fog container duplicated (before: %d, after: %d)" % [fog_count_before, fog_count_after])
		app.queue_free()
		return false

	print("[VIS-005] PASS: Single procedural fog instance lifecycle verified across transitions!")
	app.queue_free()
	return true

static func test_visual_006_viewport_resolutions_1280x720_and_1024x600() -> bool:
	print("[VIS-006] Verifying procedural fog overscan & aspect ratio at 1280x720 and 1024x600...")
	var app_1280: AppRoot = _create_app(Vector2(1280, 720))
	var shell_1280: StagePresentationShell = app_1280.get_node_or_null("StagePresentationShell") as StagePresentationShell
	var info_1280: Dictionary = shell_1280.calculate_overscan_info(Vector2(1280, 720))

	if info_1280["disp_width"] < 1280.0 or info_1280["disp_width"] < info_1280["required_overscan"] * 2.0 + 1280.0:
		print("[VIS-006] FAIL: Insufficient overscan at 1280x720")
		app_1280.queue_free()
		return false
	app_1280.queue_free()

	var app_1024: AppRoot = _create_app(Vector2(1024, 600))
	var shell_1024: StagePresentationShell = app_1024.get_node_or_null("StagePresentationShell") as StagePresentationShell
	var info_1024: Dictionary = shell_1024.calculate_overscan_info(Vector2(1024, 600))

	if info_1024["disp_width"] < 1024.0 or info_1024["disp_width"] < info_1024["required_overscan"] * 2.0 + 1024.0:
		print("[VIS-006] FAIL: Insufficient overscan at 1024x600")
		app_1024.queue_free()
		return false
	app_1024.queue_free()

	print("[VIS-006] PASS: Multi-resolution viewport bounds & overscan contract verified!")
	return true

static func test_visual_007_dungeon_1_scoping() -> bool:
	print("[VIS-007] Verifying Dungeon 1 background/fog scoping...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var shell: StagePresentationShell = app.get_node_or_null("StagePresentationShell") as StagePresentationShell
	var proc_container: Control = shell.get_procedural_fog_container()

	# D1 context
	shell.set_stage_context({"dungeon_title": "Khu Rừng Mù Sương", "stage_id": "stage_1_1"})
	if not proc_container.visible:
		print("[VIS-007] FAIL: Procedural fog container not visible in Dungeon 1 context")
		app.queue_free()
		return false

	# Non-D1 context (e.g. Dungeon 2)
	shell.set_stage_context({"dungeon_title": "Hang Động Lửa", "stage_id": "stage_2_1"})
	if proc_container.visible:
		print("[VIS-007] FAIL: D1 procedural fog container remained visible in Dungeon 2 context")
		app.queue_free()
		return false

	print("[VIS-007] PASS: Dungeon 1 scoping correctly enforced!")
	app.queue_free()
	return true

static func test_visual_008_procedural_fog_production_preset_and_layers() -> bool:
	print("[VIS-008] Verifying production procedural fog texture, locked preset (0.48/120/0.15/0.08/0.05/3), and layer count...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var shell: StagePresentationShell = app.get_node_or_null("StagePresentationShell") as StagePresentationShell
	shell._update_background_texture()

	var proc_container: Control = shell.get_procedural_fog_container()
	if proc_container == null or not proc_container.visible:
		print("[VIS-008] FAIL: ProceduralFogContainer is missing or not visible")
		app.queue_free()
		return false

	var proc_tex: Texture2D = shell.get_procedural_fog_texture()
	if proc_tex == null or proc_tex.get_width() != 2115 or proc_tex.get_height() != 744:
		print("[VIS-008] FAIL: Production procedural fog texture missing or incorrect dimensions")
		app.queue_free()
		return false

	var layers: Array[Node] = proc_container.get_children()
	if layers.size() != 3:
		print("[VIS-008] FAIL: Expected exactly 3 production fog layers, got %d" % layers.size())
		app.queue_free()
		return false

	var preset: Dictionary = shell.get_procedural_fog_preset()
	if abs(preset["opacity"] - 0.48) > 0.001 or abs(preset["drift_amount"] - 120.0) > 0.001 or abs(preset["drift_speed"] - 0.15) > 0.001 or abs(preset["distortion"] - 0.08) > 0.001 or abs(preset["breathing"] - 0.05) > 0.001 or int(preset["layer_count"]) != 3:
		print("[VIS-008] FAIL: Production procedural fog preset mismatch: %s" % str(preset))
		app.queue_free()
		return false

	if not shell.is_old_fog_atlas_disabled_in_production():
		print("[VIS-008] FAIL: Old atlas fog overlay was not disabled in production path")
		app.queue_free()
		return false

	print("[VIS-008] PASS: Production procedural fog source (2115x744), locked preset, 3 layers, and old atlas disabling verified!")
	app.queue_free()
	return true

static func test_visual_009_application_icon_configuration() -> bool:
	print("[VIS-009] Verifying Godot project application branding icon configuration...")
	var runtime_icon: String = String(ProjectSettings.get_setting("application/config/icon", ""))
	if runtime_icon != "res://assets/branding/mathos_logo_emblem.png":
		print("[VIS-009] FAIL: application/config/icon is '%s', expected 'res://assets/branding/mathos_logo_emblem.png'" % runtime_icon)
		return false

	var png_exists: bool = FileAccess.file_exists(runtime_icon) or ResourceLoader.exists(runtime_icon)
	if not png_exists:
		print("[VIS-009] FAIL: Configured runtime icon asset missing at '%s'" % runtime_icon)
		return false

	var export_presets_path: String = "res://export_presets.cfg"
	var global_presets: String = ProjectSettings.globalize_path(export_presets_path)
	var cfg_bytes: PackedByteArray = FileAccess.get_file_as_bytes(export_presets_path)
	if cfg_bytes.is_empty() and FileAccess.file_exists(global_presets):
		cfg_bytes = FileAccess.get_file_as_bytes(global_presets)

	var cfg_text: String = cfg_bytes.get_string_from_utf8()
	if not cfg_text.contains('application/icon="res://assets/branding/mathos_logo_emblem.ico"'):
		print("[VIS-009] FAIL: export_presets.cfg does not configure application/icon=\"res://assets/branding/mathos_logo_emblem.ico\"")
		return false

	var ico_path: String = "res://assets/branding/mathos_logo_emblem.ico"
	var ico_bytes: PackedByteArray = FileAccess.get_file_as_bytes(ico_path)
	if ico_bytes.is_empty():
		var global_ico: String = ProjectSettings.globalize_path(ico_path)
		ico_bytes = FileAccess.get_file_as_bytes(global_ico)

	if ico_bytes.size() < 6:
		print("[VIS-009] FAIL: Windows emblem ICO file missing or invalid size")
		return false

	print("[VIS-009] PASS: Application runtime PNG and Windows executable ICO icons correctly configured!")
	return true
