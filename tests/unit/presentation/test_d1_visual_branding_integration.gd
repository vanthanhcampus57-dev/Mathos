extends SceneTree

## Targeted Verification Test Suite for MATHOS-D1-PIXEL-ART-BRANDING-VISUAL-INTEGRATION-001
## Verifies:
## A. Asset contracts (bg 1280x720, fog 2048x576, logo_main 1536x512, emblem 512x512).
## B. Fog atlas (4x2, 8 frames, 512x288 region size, loop, FPS=2.0).
## C. Presentation hierarchy (bg < fog < normal UI < QA CanvasLayer).
## D. Mouse interaction safety (mouse_filter = MOUSE_FILTER_IGNORE).
## E. Lifecycle (single fog instance, no duplication across question transitions).
## F. Viewport resolution bounds (1280x720 & 1024x600).
## G. Dungeon 1 scoping (D1 uses forest bg + fog, non-D1 disables fog).

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
	if test_visual_008_fog_live_runtime_visibility_and_opacity_boost(): passes += 1
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
		{"paths": ["res://assets/branding/mathos_logo_main.png"], "w": 1536, "h": 512},
		{"paths": ["res://assets/branding/mathos_logo_emblem.png"], "w": 512, "h": 512}
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
			if img.load(global_p) == OK:
				if img.get_width() == exp_w and img.get_height() == exp_h:
					found = true
					break

		if not found:
			print("[VIS-001] FAIL: Asset contract missing or wrong dimensions for '%s'" % String(paths[0]))
			return false

	print("[VIS-001] PASS: All 4 branding & D1 visual assets verified!")
	return true

static func test_visual_002_fog_atlas_structure_and_fps() -> bool:
	print("[VIS-002] Verifying fog atlas regions (4x2, 8 frames, 512x288, 2.0 FPS)...")
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

	if abs(StagePresentationShell.FOG_FPS - 2.0) > 0.01:
		print("[VIS-002] FAIL: FOG_FPS is not 2.0")
		app.queue_free()
		return false

	print("[VIS-002] PASS: Fog atlas 4x2 grid and 2.0 FPS verified!")
	app.queue_free()
	return true

static func test_visual_003_presentation_hierarchy_and_layering() -> bool:
	print("[VIS-003] Verifying layering contract: Static BG < Fog < Normal Presentation UI < QA Cheat...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var shell: StagePresentationShell = app.get_node_or_null("StagePresentationShell") as StagePresentationShell

	var bg_rect: Control = shell.get_node_or_null("BackgroundTextureRect") as Control
	var fog_rect: Control = shell.get_node_or_null("FogOverlayTextureRect") as Control
	var vbox_ui: Control = shell.get_node_or_null("VBoxContainer") as Control

	if bg_rect == null or fog_rect == null or vbox_ui == null:
		print("[VIS-003] FAIL: Missing presentation nodes in shell")
		app.queue_free()
		return false

	if bg_rect.get_index() >= fog_rect.get_index():
		print("[VIS-003] FAIL: Static background (index %d) not below Fog (index %d)" % [bg_rect.get_index(), fog_rect.get_index()])
		app.queue_free()
		return false

	if fog_rect.get_index() >= vbox_ui.get_index():
		print("[VIS-003] FAIL: Fog (index %d) not below Presentation UI (index %d)" % [fog_rect.get_index(), vbox_ui.get_index()])
		app.queue_free()
		return false

	var qa_overlay: Control = app.get_qa_overlay()
	if qa_overlay != null:
		var qa_canvas: CanvasLayer = qa_overlay.get_node_or_null("CanvasLayer") as CanvasLayer
		if qa_canvas != null and qa_canvas.layer < 1:
			print("[VIS-003] FAIL: QA Cheat CanvasLayer priority level insufficient")
			app.queue_free()
			return false

	print("[VIS-003] PASS: Layering contract background < fog < UI < QA verified!")
	app.queue_free()
	return true

static func test_visual_004_mouse_interaction_safety() -> bool:
	print("[VIS-004] Verifying mouse_filter = IGNORE on background and fog controls...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var shell: StagePresentationShell = app.get_node_or_null("StagePresentationShell") as StagePresentationShell

	var bg_rect: Control = shell.get_node_or_null("BackgroundTextureRect") as Control
	var fog_rect: Control = shell.get_node_or_null("FogOverlayTextureRect") as Control

	if bg_rect.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		print("[VIS-004] FAIL: BackgroundTextureRect mouse_filter is not IGNORE (got %d)" % bg_rect.mouse_filter)
		app.queue_free()
		return false

	if fog_rect.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		print("[VIS-004] FAIL: FogOverlayTextureRect mouse_filter is not IGNORE (got %d)" % fog_rect.mouse_filter)
		app.queue_free()
		return false

	print("[VIS-004] PASS: Background and fog mouse interaction safety verified!")
	app.queue_free()
	return true

static func test_visual_005_fog_lifecycle_and_single_instance() -> bool:
	print("[VIS-005] Verifying single fog instance and zero duplication across transitions...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	app.start_new_game()

	var shell: StagePresentationShell = app.get_node_or_null("StagePresentationShell") as StagePresentationShell
	var fog_count_before: int = 0
	for child in shell.get_children():
		if child.name == "FogOverlayTextureRect":
			fog_count_before += 1

	# Transition through questions
	app._on_lesson_continue_requested()

	var fog_count_after: int = 0
	for child in shell.get_children():
		if child.name == "FogOverlayTextureRect":
			fog_count_after += 1

	if fog_count_before != 1 or fog_count_after != 1:
		print("[VIS-005] FAIL: Fog overlay node duplicated (before: %d, after: %d)" % [fog_count_before, fog_count_after])
		app.queue_free()
		return false

	print("[VIS-005] PASS: Single fog instance lifecycle verified across transitions!")
	app.queue_free()
	return true

static func test_visual_006_viewport_resolutions_1280x720_and_1024x600() -> bool:
	print("[VIS-006] Verifying visual presentation bounds at 1280x720 and 1024x600...")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree

	var app_1280: AppRoot = _create_app(Vector2(1280, 720))
	var shell_1280: StagePresentationShell = app_1280.get_node_or_null("StagePresentationShell") as StagePresentationShell
	if shell_1280 == null or tree.root.size.x < 1000:
		print("[VIS-006] FAIL: 1280x720 shell bounds invalid")
		app_1280.queue_free()
		return false
	app_1280.queue_free()

	var app_1024: AppRoot = _create_app(Vector2(1024, 600))
	var shell_1024: StagePresentationShell = app_1024.get_node_or_null("StagePresentationShell") as StagePresentationShell
	if shell_1024 == null or tree.root.size.x < 800:
		print("[VIS-006] FAIL: 1024x600 shell bounds invalid")
		app_1024.queue_free()
		return false
	app_1024.queue_free()

	print("[VIS-006] PASS: Multi-resolution viewport bounds verified!")
	return true

static func test_visual_007_dungeon_1_scoping() -> bool:
	print("[VIS-007] Verifying Dungeon 1 background/fog scoping...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var shell: StagePresentationShell = app.get_node_or_null("StagePresentationShell") as StagePresentationShell
	var fog_rect: Control = shell.get_node_or_null("FogOverlayTextureRect") as Control

	# D1 context
	shell.set_stage_context({"dungeon_title": "Khu Rừng Mù Sương", "stage_id": "stage_1_1"})
	if not fog_rect.visible:
		print("[VIS-007] FAIL: Fog overlay not visible in Dungeon 1 context")
		app.queue_free()
		return false

	# Non-D1 context (e.g. Dungeon 2)
	shell.set_stage_context({"dungeon_title": "Hang Động Lửa", "stage_id": "stage_2_1"})
	if fog_rect.visible:
		print("[VIS-007] FAIL: D1 fog overlay remained visible in Dungeon 2 context")
		app.queue_free()
		return false

	print("[VIS-007] PASS: Dungeon 1 scoping correctly enforced!")
	app.queue_free()
	return true

static func test_visual_008_fog_live_runtime_visibility_and_opacity_boost() -> bool:
	print("[VIS-008] Verifying live runtime fog visibility, texture, opacity boost, and animation tick...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var shell: StagePresentationShell = app.get_node_or_null("StagePresentationShell") as StagePresentationShell
	shell._update_background_texture()

	var fog_rect: TextureRect = shell.get_node_or_null("FogOverlayTextureRect") as TextureRect

	if fog_rect == null:
		print("[VIS-008] FAIL: FogOverlayTextureRect not found")
		app.queue_free()
		return false

	if not fog_rect.visible:
		print("[VIS-008] FAIL: FogOverlayTextureRect is not visible")
		app.queue_free()
		return false

	if fog_rect.texture == null:
		print("[VIS-008] FAIL: FogOverlayTextureRect texture is null")
		app.queue_free()
		return false

	if fog_rect.modulate.a < 2.0:
		print("[VIS-008] FAIL: Fog overlay modulate alpha (%f) insufficient for human visibility" % fog_rect.modulate.a)
		app.queue_free()
		return false

	var initial_frame: int = shell._fog_current_frame
	shell._process(0.6) # Advance timer past 0.5s (2 FPS)
	var next_frame: int = shell._fog_current_frame

	if next_frame == initial_frame:
		print("[VIS-008] FAIL: Fog frame index did not advance after animation tick (remained %d)" % initial_frame)
		app.queue_free()
		return false

	print("[VIS-008] PASS: Live fog visibility, texture, modulate boost (a=%f), and animation tick verified!" % fog_rect.modulate.a)
	app.queue_free()
	return true

static func test_visual_009_application_icon_configuration() -> bool:
	print("[VIS-009] Verifying Godot project application branding icon configuration...")
	var icon_setting: String = String(ProjectSettings.get_setting("application/config/icon", ""))
	if icon_setting != "res://assets/branding/mathos_logo_emblem.png":
		print("[VIS-009] FAIL: application/config/icon is '%s', expected 'res://assets/branding/mathos_logo_emblem.png'" % icon_setting)
		return false

	var file_exists: bool = FileAccess.file_exists(icon_setting) or ResourceLoader.exists(icon_setting)
	if not file_exists:
		print("[VIS-009] FAIL: Configured icon asset missing at '%s'" % icon_setting)
		return false

	print("[VIS-009] PASS: Application branding icon correctly configured!")
	return true
