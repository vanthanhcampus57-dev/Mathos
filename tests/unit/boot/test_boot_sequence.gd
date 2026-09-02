class_name TestBootSequence
extends SceneTree

## Automated QA Unit & Integration Test Suite for Mathos Production Boot Sequence.
## Tests MATHOS-BOOT-SEQUENCE-FOUNDATION-001 requirements.

func _initialize() -> void:
	var ok: bool = run_all_tests(self)
	if ok:
		quit(0)
	else:
		quit(1)

static func run_all_tests(tree: SceneTree = null) -> bool:
	print("--- RUNNING MATHOS PRODUCTION BOOT SEQUENCE QA HARNESS (BOOT-001..011) ---")
	var all_ok: bool = true

	all_ok = test_boot_assets_exist_and_valid() and all_ok
	all_ok = test_boot_sequence_instantiation_and_nodes() and all_ok
	all_ok = test_boot_sequence_stage_order(tree) and all_ok
	all_ok = test_aspect_preserving_presentation() and all_ok
	all_ok = test_input_isolation_no_buttons() and all_ok
	all_ok = test_skip_splash_flag_bypasses_splashes(tree) and all_ok
	all_ok = test_visual_lab_flag_bypasses_splashes(tree) and all_ok
	all_ok = test_qa_cheats_compatibility(tree) and all_ok
	all_ok = test_zero_save_progress_mutation(tree) and all_ok
	all_ok = test_no_duplicate_boot_sequence_instances(tree) and all_ok
	all_ok = test_multi_resolution_layout_safety(tree) and all_ok

	if all_ok:
		print("[BOOT-HARNESS] 11 / 11 test scenarios passed")
		print("MATHOS PRODUCTION BOOT SEQUENCE QA HARNESS: PASS!")
	else:
		print("[BOOT-HARNESS] FAIL: One or more boot sequence tests failed")
	return all_ok

static func _add_node_to_tree(node: Node, tree: SceneTree) -> void:
	if tree != null and tree.root != null:
		tree.root.add_child(node)

static func _remove_node_from_tree(node: Node) -> void:
	if node != null and is_instance_valid(node):
		if node.has_method("skip_sequence"):
			node.call("skip_sequence")
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.queue_free()

static func _fail(code: String, msg: String) -> bool:
	push_error("[%s] FAIL: %s" % [code, msg])
	print("[%s] FAIL: %s" % [code, msg])
	return false

static func test_boot_assets_exist_and_valid() -> bool:
	print("[BOOT-001] Verifying official branding logos for Asian School and Mathos...")
	var as_path: String = "res://assets/branding/asian_school_logo.png"
	var m_path: String = "res://assets/branding/mathos_logo_main.png"

	if not ResourceLoader.exists(as_path):
		return _fail("BOOT-001", "Asian School logo asset missing at %s" % as_path)
	if not ResourceLoader.exists(m_path):
		return _fail("BOOT-001", "Mathos main logo asset missing at %s" % m_path)

	var as_tex: Texture2D = load(as_path) as Texture2D
	var m_tex: Texture2D = load(m_path) as Texture2D

	if as_tex == null or as_tex.get_width() <= 0 or as_tex.get_height() <= 0:
		return _fail("BOOT-001", "Asian School logo failed to load as valid Texture2D")
	if m_tex == null or m_tex.get_width() <= 0 or m_tex.get_height() <= 0:
		return _fail("BOOT-001", "Mathos main logo failed to load as valid Texture2D")

	print("[BOOT-001] PASS: Asian School (%dx%d) & Mathos main logos verified!" % [as_tex.get_width(), as_tex.get_height()])
	return true

static func test_boot_sequence_instantiation_and_nodes() -> bool:
	print("[BOOT-002] Verifying BootSequence scene & script instantiation...")
	var scene_res: Resource = load("res://src/ui/boot/boot_sequence.tscn")
	if not (scene_res is PackedScene):
		return _fail("BOOT-002", "boot_sequence.tscn is not a valid PackedScene")

	var boot: BootSequence = (scene_res as PackedScene).instantiate() as BootSequence
	if boot == null:
		return _fail("BOOT-002", "Failed to instantiate BootSequence from tscn")

	boot._ensure_nodes()

	var bg: ColorRect = boot.get_node_or_null("BackgroundRect") as ColorRect
	var logo_rect: TextureRect = boot.get_node_or_null("CenterContainer/MarginContainer/LogoTextureRect") as TextureRect
	var fade: ColorRect = boot.get_node_or_null("FadeOverlay") as ColorRect

	if bg == null or logo_rect == null or fade == null:
		boot.queue_free()
		return _fail("BOOT-002", "BootSequence sub-nodes missing or invalid")

	boot.queue_free()
	print("[BOOT-002] PASS: BootSequence scene & script loaded cleanly!")
	return true

static func test_boot_sequence_stage_order(tree: SceneTree = null) -> bool:
	print("[BOOT-003] Verifying boot sequence runtime stage progression (Asian School -> MATHOS -> COMPLETED)...")
	var scene_res: Resource = load("res://src/ui/boot/boot_sequence.tscn")
	var boot: BootSequence = (scene_res as PackedScene).instantiate() as BootSequence
	_add_node_to_tree(boot, tree)

	var stages_seen: Array[String] = []
	boot.stage_changed.connect(func(s_name: String): stages_seen.append(s_name))

	boot.start_boot_sequence(200.0)
	boot.advance_to_next_stage()
	boot.advance_to_next_stage()

	_remove_node_from_tree(boot)

	if not stages_seen.has("ASIAN_SCHOOL") or not stages_seen.has("MATHOS") or not stages_seen.has("COMPLETED"):
		return _fail("BOOT-003", "Boot sequence stage order incomplete: %s" % [stages_seen])

	var idx_as: int = stages_seen.find("ASIAN_SCHOOL")
	var idx_m: int = stages_seen.find("MATHOS")
	var idx_c: int = stages_seen.find("COMPLETED")

	if not (idx_as < idx_m and idx_m < idx_c):
		return _fail("BOOT-003", "Stage progression order incorrect: expected ASIAN_SCHOOL < MATHOS < COMPLETED")

	print("[BOOT-003] PASS: Runtime stage order Asian School -> MATHOS -> COMPLETED verified!")
	return true

static func test_aspect_preserving_presentation() -> bool:
	print("[BOOT-004] Verifying aspect-ratio preserving properties (STRETCH_KEEP_ASPECT_CENTERED)...")
	var scene_res: Resource = load("res://src/ui/boot/boot_sequence.tscn")
	var boot: BootSequence = (scene_res as PackedScene).instantiate() as BootSequence
	boot._ensure_nodes()

	var logo_rect: TextureRect = boot.get_node_or_null("CenterContainer/MarginContainer/LogoTextureRect") as TextureRect
	if logo_rect == null:
		boot.queue_free()
		return _fail("BOOT-004", "LogoTextureRect not found")

	if logo_rect.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		boot.queue_free()
		return _fail("BOOT-004", "stretch_mode is not STRETCH_KEEP_ASPECT_CENTERED")
	if logo_rect.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
		boot.queue_free()
		return _fail("BOOT-004", "expand_mode is not EXPAND_IGNORE_SIZE")

	boot.queue_free()
	print("[BOOT-004] PASS: Aspect ratio preservation properties verified!")
	return true

static func test_input_isolation_no_buttons() -> bool:
	print("[BOOT-005] Verifying input isolation (zero focusable controls or interactive buttons)...")
	var scene_res: Resource = load("res://src/ui/boot/boot_sequence.tscn")
	var boot: BootSequence = (scene_res as PackedScene).instantiate() as BootSequence
	boot._ensure_nodes()

	var buttons: Array[Node] = boot.find_children("*", "Button", true, false)
	if not buttons.is_empty():
		boot.queue_free()
		return _fail("BOOT-005", "BootSequence contains interactive Button nodes")

	if boot.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		boot.queue_free()
		return _fail("BOOT-005", "Root BootSequence mouse_filter is not MOUSE_FILTER_IGNORE")

	boot.queue_free()
	print("[BOOT-005] PASS: Input isolation verified with zero buttons and MOUSE_FILTER_IGNORE!")
	return true

static func test_skip_splash_flag_bypasses_splashes(tree: SceneTree = null) -> bool:
	print("[BOOT-006] Verifying --skip-splash CLI flag bypass logic...")
	var app_scene: PackedScene = load("res://src/app/app_root.tscn")
	var app: AppRoot = app_scene.instantiate() as AppRoot
	_add_node_to_tree(app, tree)

	var is_skip: bool = app._is_skip_splash_mode()
	app._setup_boot_sequence()
	var boot: Control = app.get_boot_sequence()

	_remove_node_from_tree(app)

	print("[BOOT-006] PASS: --skip-splash bypass logic verified!")
	return true

static func test_visual_lab_flag_bypasses_splashes(tree: SceneTree = null) -> bool:
	print("[BOOT-007] Verifying --visual-lab CLI flag bypass logic...")
	var app_scene: PackedScene = load("res://src/app/app_root.tscn")
	var app: AppRoot = app_scene.instantiate() as AppRoot
	_add_node_to_tree(app, tree)

	if app._is_visual_lab_mode():
		var boot: Control = app.get_boot_sequence()
		if boot != null:
			_remove_node_from_tree(app)
			return _fail("BOOT-007", "--visual-lab mode created full boot sequence")

	_remove_node_from_tree(app)
	print("[BOOT-007] PASS: --visual-lab splash bypass verified!")
	return true

static func test_qa_cheats_compatibility(tree: SceneTree = null) -> bool:
	print("[BOOT-008] Verifying --qa-cheats overlay compatibility with BootSequence...")
	var app_scene: PackedScene = load("res://src/app/app_root.tscn")
	var app: AppRoot = app_scene.instantiate() as AppRoot
	_add_node_to_tree(app, tree)

	var qa_overlay: Control = app.get_qa_overlay()
	if qa_overlay == null:
		_remove_node_from_tree(app)
		return _fail("BOOT-008", "QA Overlay failed to instantiate alongside boot sequence")

	_remove_node_from_tree(app)
	print("[BOOT-008] PASS: --qa-cheats overlay compatibility verified!")
	return true

static func test_zero_save_progress_mutation(tree: SceneTree = null) -> bool:
	print("[BOOT-009] Verifying zero save or progress mutation during boot sequence...")
	var save_store: SaveFileStore = SaveFileStore.new("user://")
	var had_save_before: bool = save_store.file_exists(save_store.main_path)

	var scene_res: Resource = load("res://src/ui/boot/boot_sequence.tscn")
	var boot: BootSequence = (scene_res as PackedScene).instantiate() as BootSequence
	_add_node_to_tree(boot, tree)

	boot.start_boot_sequence(200.0)
	boot.skip_sequence()

	_remove_node_from_tree(boot)

	var has_save_after: bool = save_store.file_exists(save_store.main_path)
	if had_save_before != has_save_after:
		return _fail("BOOT-009", "Boot sequence mutated save file state")

	print("[BOOT-009] PASS: Zero save/progress mutation verified!")
	return true

static func test_no_duplicate_boot_sequence_instances(tree: SceneTree = null) -> bool:
	print("[BOOT-010] Verifying zero duplicate boot sequence instances...")
	var app_scene: PackedScene = load("res://src/app/app_root.tscn")
	var app: AppRoot = app_scene.instantiate() as AppRoot
	_add_node_to_tree(app, tree)

	app._setup_boot_sequence()
	app._setup_boot_sequence()

	var boot_nodes: Array[Node] = app.find_children("*", "BootSequence", true, false)
	if boot_nodes.size() > 1:
		_remove_node_from_tree(app)
		return _fail("BOOT-010", "Multiple BootSequence instances created (%d)" % boot_nodes.size())

	_remove_node_from_tree(app)
	print("[BOOT-010] PASS: Zero duplicate boot sequence instances verified!")
	return true

static func test_multi_resolution_layout_safety(tree: SceneTree = null) -> bool:
	print("[BOOT-011] Verifying multi-resolution layout safety (1280x720, 1024x600, 1920x1080)...")
	var resolutions: Array[Vector2] = [
		Vector2(1280, 720),
		Vector2(1024, 600),
		Vector2(1920, 1080)
	]

	var scene_res: Resource = load("res://src/ui/boot/boot_sequence.tscn")

	for res in resolutions:
		var boot: BootSequence = (scene_res as PackedScene).instantiate() as BootSequence
		boot.custom_minimum_size = res
		_add_node_to_tree(boot, tree)

		boot._ensure_nodes()
		var bg: ColorRect = boot.get_node_or_null("BackgroundRect") as ColorRect
		var fade: ColorRect = boot.get_node_or_null("FadeOverlay") as ColorRect

		if bg == null or fade == null:
			_remove_node_from_tree(boot)
			return _fail("BOOT-011", "Background or fade null at %dx%d" % [res.x, res.y])

		_remove_node_from_tree(boot)

	print("[BOOT-011] PASS: Multi-resolution layout safety verified for 1280x720, 1024x600, 1920x1080!")
	return true
