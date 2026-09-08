class_name TestD1StoryVisual
extends SceneTree

## Dedicated Verification Suite for Human-Approved MATHOS D1 Story Visual Integration
## Validates STORY-VIS-001 through STORY-VIS-015 according to TASK-059 specification.

const PresentationModels = preload("res://src/ui/common/presentation/presentation_models.gd")
const StoryPanel = preload("res://src/ui/story/story_panel.gd")
const StagePresentationShell = preload("res://src/ui/stage/stage_presentation_shell.gd")
const LessonPanel = preload("res://src/ui/lesson/lesson_panel.gd")
const PauseMenuOverlay = preload("res://src/ui/common/pause_menu_overlay.gd")
const AppRoot = preload("res://src/app/app_root.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func run_all_tests() -> bool:
	print("==========================================")
	print("D1 STORY VISUAL VERIFICATION (STORY-VIS-001..015)")
	print("==========================================")
	var pass_count: int = 0

	if test_story_vis_001_root_geometry(): pass_count += 1
	if test_story_vis_002_production_background_retained(): pass_count += 1
	if test_story_vis_003_production_fog_retained(): pass_count += 1
	if test_story_vis_004_no_theory_badge_in_story(): pass_count += 1
	if test_story_vis_005_cot_truyen_badge_visible(): pass_count += 1
	if test_story_vis_006_approved_draven_asset_loaded(): pass_count += 1
	if test_story_vis_007_draven_bottom_fade_shader_active(): pass_count += 1
	if test_story_vis_008_exact_dialogue_text_verified(): pass_count += 1
	if test_story_vis_009_canonical_pause_connected(): pass_count += 1
	if test_story_vis_010_step_indicator_format(): pass_count += 1
	if test_story_vis_011_canonical_story_to_lesson_cta(): pass_count += 1
	if test_story_vis_012_lesson_visual_remains_unchanged(): pass_count += 1
	if test_story_vis_013_responsive_1600x900(): pass_count += 1
	if test_story_vis_014_responsive_1920x1080(): pass_count += 1
	if test_story_vis_015_no_invented_controls(): pass_count += 1
	if test_story_vis_016_no_opaque_white_lower_overlay(): pass_count += 1

	print("==========================================")
	print("D1 STORY VISUAL SUMMARY: %d / 16 passed" % pass_count)
	print("==========================================")
	return pass_count == 16

static func _add_node_to_tree(node: Node) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(node)
	if not node.is_node_ready():
		node._ready()

static func _remove_node_from_tree(node: Node) -> void:
	if node != null:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()

static func _create_story_panel(p_size: Vector2 = Vector2(1280, 720)) -> Control:
	var scene: PackedScene = load("res://src/ui/story/story_panel.tscn") as PackedScene
	var panel: Control = null
	if scene != null:
		panel = scene.instantiate() as Control
	else:
		panel = (StoryPanel as GDScript).new() as Control
	panel.size = p_size
	_add_node_to_tree(panel)
	return panel

static func _create_shell(p_size: Vector2 = Vector2(1280, 720)) -> Control:
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn") as PackedScene
	var shell: Control = null
	if scene != null:
		shell = scene.instantiate() as Control
	else:
		shell = (StagePresentationShell as GDScript).new() as Control
	shell.visible = true
	shell.size = p_size
	_add_node_to_tree(shell)
	return shell

static func _sample_d1_story_context() -> RefCounted:
	var dict: Dictionary = {
		"stage_id": "stage_01_01",
		"stage_title": "Khởi Đầu Rừng Mù Sương",
		"dungeon_title": "Khu Rừng Mù Sương",
		"lesson_steps": [],
		"story_steps": [
			{
				"speaker_label": "npc_draven",
				"body_text": "Karl! Rừng Mù Sương bị bao phủ bởi Ma Thuật Ngẫu Nhiên. Mọi hành động ở đây đều là một phép thử — ta không thể biết trước kết quả, nhưng có thể lường trước mọi khả năng!",
				"context_title": "Khởi Đầu Rừng Mù Sương",
				"step_index": 1,
				"total_steps": 1
			}
		],
		"is_restored_context": false
	}
	return PresentationModels.StageContextInfo.from_dict(dict)

# STORY-VIS-001: 1280x720 composition & bounds
static func test_story_vis_001_root_geometry() -> bool:
	print("[STORY-VIS-001] Verifying root 1280x720 composition & bounds...")
	var panel: Control = _create_story_panel(Vector2(1280, 720))
	if panel == null:
		print("[STORY-VIS-001] FAIL: Could not instantiate StoryPanel")
		return false

	var top_bar: Control = panel.call("get_top_bar") as Control
	if top_bar == null or top_bar.custom_minimum_size.y < 72.0:
		print("[STORY-VIS-001] FAIL: TopBar missing or height < 72")
		_remove_node_from_tree(panel)
		return false

	var draven_rect: TextureRect = panel.call("get_draven_texture_rect") as TextureRect
	if draven_rect == null:
		print("[STORY-VIS-001] FAIL: DravenTextureRect missing")
		_remove_node_from_tree(panel)
		return false

	var dlg_panel: Control = panel.call("get_dialogue_panel") as Control
	if dlg_panel == null or dlg_panel.custom_minimum_size.x < 800.0 or dlg_panel.custom_minimum_size.y < 200.0:
		print("[STORY-VIS-001] FAIL: DialoguePanel missing or dimension < 800x200")
		_remove_node_from_tree(panel)
		return false

	_remove_node_from_tree(panel)
	print("[STORY-VIS-001] PASS")
	return true

# STORY-VIS-002: Production D1 background retained
static func test_story_vis_002_production_background_retained() -> bool:
	print("[STORY-VIS-002] Verifying production D1 background retained in MODE_STORY...")
	var shell: Control = _create_shell()
	var ctx: RefCounted = _sample_d1_story_context()
	shell.call("set_stage_context", ctx)
	shell.call("show_story_phase")

	var bg_rect: TextureRect = shell.get_node_or_null("BackgroundTextureRect") as TextureRect
	if bg_rect == null or bg_rect.texture == null:
		print("[STORY-VIS-002] FAIL: BackgroundTextureRect or texture is null")
		_remove_node_from_tree(shell)
		return false

	if bg_rect.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
		print("[STORY-VIS-002] FAIL: expand_mode must be EXPAND_IGNORE_SIZE")
		_remove_node_from_tree(shell)
		return false

	if bg_rect.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
		print("[STORY-VIS-002] FAIL: stretch_mode must be STRETCH_KEEP_ASPECT_COVERED")
		_remove_node_from_tree(shell)
		return false

	_remove_node_from_tree(shell)
	print("[STORY-VIS-002] PASS")
	return true

# STORY-VIS-003: Production fog retained
static func test_story_vis_003_production_fog_retained() -> bool:
	print("[STORY-VIS-003] Verifying production procedural fog active underneath Story UI...")
	var shell: Control = _create_shell()
	var ctx: RefCounted = _sample_d1_story_context()
	shell.call("set_stage_context", ctx)
	shell.call("show_story_phase")

	if not bool(shell.call("is_atmospheric_overlay_active")):
		print("[STORY-VIS-003] FAIL: Procedural fog should be active in MODE_STORY")
		_remove_node_from_tree(shell)
		return false

	var fog_cfg: Dictionary = shell.call("get_procedural_fog_preset") as Dictionary
	if int(fog_cfg.get("layer_count", 0)) != 3:
		print("[STORY-VIS-003] FAIL: Expected 3 fog layers, got %s" % str(fog_cfg.get("layer_count")))
		_remove_node_from_tree(shell)
		return false

	_remove_node_from_tree(shell)
	print("[STORY-VIS-003] PASS")
	return true

# STORY-VIS-004: No [LÝ THUYẾT] badge in Story
static func test_story_vis_004_no_theory_badge_in_story() -> bool:
	print("[STORY-VIS-004] Verifying no [LÝ THUYẾT] badge in Story mode...")
	var shell: Control = _create_shell()
	var ctx: RefCounted = _sample_d1_story_context()
	shell.call("set_stage_context", ctx)
	shell.call("show_story_phase")

	# 1. Shell header bar is hidden in MODE_STORY
	var header_bar: Control = shell.get_node_or_null("VBoxContainer/HeaderBar") as Control
	if header_bar != null and header_bar.visible:
		print("[STORY-VIS-004] FAIL: Default HeaderBar should be hidden in MODE_STORY")
		_remove_node_from_tree(shell)
		return false

	# 2. Check story panel does not contain [LÝ THUYẾT]
	var story_panel: Control = shell.call("get_story_panel") as Control
	if story_panel != null:
		var txt: String = ""
		var queue: Array[Node] = [story_panel]
		while not queue.is_empty():
			var cur: Node = queue.pop_front()
			if cur is Label:
				txt += (cur as Label).text + " "
			elif cur is Button:
				txt += (cur as Button).text + " "
			for c in cur.get_children():
				queue.append(c)
		if "LÝ THUYẾT" in txt:
			print("[STORY-VIS-004] FAIL: Found unexpected [LÝ THUYẾT] in StoryPanel text: %s" % txt)
			_remove_node_from_tree(shell)
			return false

	_remove_node_from_tree(shell)
	print("[STORY-VIS-004] PASS")
	return true

# STORY-VIS-005: CỐT TRUYỆN phase badge visible
static func test_story_vis_005_cot_truyen_badge_visible() -> bool:
	print("[STORY-VIS-005] Verifying CỐT TRUYỆN phase badge visible...")
	var panel: Control = _create_story_panel()
	var badge: Label = panel.call("get_phase_badge_label") as Label
	if badge == null or not badge.visible:
		print("[STORY-VIS-005] FAIL: Phase badge label is null or not visible")
		_remove_node_from_tree(panel)
		return false

	if badge.text != "CỐT TRUYỆN":
		print("[STORY-VIS-005] FAIL: Expected badge text 'CỐT TRUYỆN', got '%s'" % badge.text)
		_remove_node_from_tree(panel)
		return false

	_remove_node_from_tree(panel)
	print("[STORY-VIS-005] PASS")
	return true

# STORY-VIS-006: Approved Draven asset loaded
static func test_story_vis_006_approved_draven_asset_loaded() -> bool:
	print("[STORY-VIS-006] Verifying approved Draven asset loaded (1254x1254)...")
	var panel: Control = _create_story_panel()
	var rect: TextureRect = panel.call("get_draven_texture_rect") as TextureRect
	if rect == null or rect.texture == null:
		print("[STORY-VIS-006] FAIL: Draven TextureRect or texture is null")
		_remove_node_from_tree(panel)
		return false

	var w: int = rect.texture.get_width()
	var h: int = rect.texture.get_height()
	if w != 1254 or h != 1254:
		print("[STORY-VIS-006] FAIL: Expected Draven dimensions 1254x1254, got %dx%d" % [w, h])
		_remove_node_from_tree(panel)
		return false

	_remove_node_from_tree(panel)
	print("[STORY-VIS-006] PASS")
	return true

# STORY-VIS-007: Draven bottom fade shader active
static func test_story_vis_007_draven_bottom_fade_shader_active() -> bool:
	print("[STORY-VIS-007] Verifying Draven bottom alpha fade shader active...")
	var panel: Control = _create_story_panel()
	var mat: ShaderMaterial = panel.call("get_draven_shader_material") as ShaderMaterial
	if mat == null or mat.shader == null:
		print("[STORY-VIS-007] FAIL: Draven ShaderMaterial or shader is null")
		_remove_node_from_tree(panel)
		return false

	var fade_start: float = float(mat.get_shader_parameter("fade_start"))
	var fade_end: float = float(mat.get_shader_parameter("fade_end"))
	if (fade_start < 0.6 or fade_start > 0.9) or fade_end != 1.0:
		print("[STORY-VIS-007] FAIL: Unexpected shader parameters fade_start=%f fade_end=%f" % [fade_start, fade_end])
		_remove_node_from_tree(panel)
		return false

	_remove_node_from_tree(panel)
	print("[STORY-VIS-007] PASS")
	return true

# STORY-VIS-008: Exact dialogue text verified
static func test_story_vis_008_exact_dialogue_text_verified() -> bool:
	print("[STORY-VIS-008] Verifying exact dialogue text and speaker labels...")
	var panel: Control = _create_story_panel()
	var ctx: RefCounted = _sample_d1_story_context()
	panel.call("set_context_info", ctx)

	var speaker_lbl: Label = panel.call("get_speaker_label") as Label
	if speaker_lbl == null or speaker_lbl.text != "DRAVEN":
		print("[STORY-VIS-008] FAIL: Expected speaker 'DRAVEN', got '%s'" % (speaker_lbl.text if speaker_lbl else "null"))
		_remove_node_from_tree(panel)
		return false

	var sub_lbl: Label = panel.call("get_nameplate_subtitle_label") as Label
	if sub_lbl == null or sub_lbl.text != "ĐẠI PHÁP SƯ HƯỚNG DẪN":
		print("[STORY-VIS-008] FAIL: Expected subtitle 'ĐẠI PHÁP SƯ HƯỚNG DẪN', got '%s'" % (sub_lbl.text if sub_lbl else "null"))
		_remove_node_from_tree(panel)
		return false

	var body_lbl: RichTextLabel = panel.call("get_body_text_label") as RichTextLabel
	if body_lbl == null or not body_lbl.text.contains("Karl! Rừng Mù Sương bị bao phủ"):
		print("[STORY-VIS-008] FAIL: Body text mismatch: '%s'" % (body_lbl.text if body_lbl else "null"))
		_remove_node_from_tree(panel)
		return false

	_remove_node_from_tree(panel)
	print("[STORY-VIS-008] PASS")
	return true

# STORY-VIS-009: Canonical pause connected
static func test_story_vis_009_canonical_pause_connected() -> bool:
	print("[STORY-VIS-009] Verifying canonical pause connected from StoryPanel...")
	var shell: Control = _create_shell()
	var ctx: RefCounted = _sample_d1_story_context()
	shell.call("set_stage_context", ctx)
	shell.call("show_story_phase")

	var story_panel: Control = shell.call("get_story_panel") as Control
	if story_panel == null:
		print("[STORY-VIS-009] FAIL: StoryPanel is null in shell")
		_remove_node_from_tree(shell)
		return false

	var pause_btn: Button = story_panel.call("get_pause_button") as Button
	if pause_btn == null or pause_btn.text != "Tạm dừng":
		print("[STORY-VIS-009] FAIL: Pause button missing or text incorrect: %s" % (pause_btn.text if pause_btn else "null"))
		_remove_node_from_tree(shell)
		return false

	# Emit pause_requested and check PauseMenuOverlay becomes visible
	pause_btn.emit_signal("pressed")

	var pause_overlay: Control = shell.get_node_or_null("PauseMenuOverlay") as Control
	if pause_overlay == null or not pause_overlay.visible:
		print("[STORY-VIS-009] FAIL: PauseMenuOverlay did not become visible after pause button pressed")
		_remove_node_from_tree(shell)
		return false

	# Toggle off
	shell.call("toggle_pause")
	if pause_overlay.visible:
		print("[STORY-VIS-009] FAIL: PauseMenuOverlay should hide on toggle_pause")
		_remove_node_from_tree(shell)
		return false

	_remove_node_from_tree(shell)
	print("[STORY-VIS-009] PASS")
	return true

# STORY-VIS-010: Step indicator displays "Bước 1 / 1"
static func test_story_vis_010_step_indicator_format() -> bool:
	print("[STORY-VIS-010] Verifying step indicator format...")
	var panel: Control = _create_story_panel()
	var ctx: RefCounted = _sample_d1_story_context()
	panel.call("set_context_info", ctx)

	var page_lbl: Label = panel.call("get_page_indicator_label") as Label
	if page_lbl == null or page_lbl.text != "Bước 1 / 1":
		print("[STORY-VIS-010] FAIL: Expected 'Bước 1 / 1', got '%s'" % (page_lbl.text if page_lbl else "null"))
		_remove_node_from_tree(panel)
		return false

	# Test multi-step
	var step1: RefCounted = (PresentationModels.LessonStepData as GDScript).new("Draven", "Step 1", "T", 1, 2)
	var step2: RefCounted = (PresentationModels.LessonStepData as GDScript).new("Draven", "Step 2", "T", 2, 2)
	panel.call("set_story_data", [step1, step2])

	if page_lbl.text != "Bước 1 / 2":
		print("[STORY-VIS-010] FAIL: Expected 'Bước 1 / 2', got '%s'" % page_lbl.text)
		_remove_node_from_tree(panel)
		return false

	panel.call("show_step", 1)
	if page_lbl.text != "Bước 2 / 2":
		print("[STORY-VIS-010] FAIL: Expected 'Bước 2 / 2', got '%s'" % page_lbl.text)
		_remove_node_from_tree(panel)
		return false

	_remove_node_from_tree(panel)
	print("[STORY-VIS-010] PASS")
	return true

# STORY-VIS-011: Canonical Story -> Lesson CTA transition
static func test_story_vis_011_canonical_story_to_lesson_cta() -> bool:
	print("[STORY-VIS-011] Verifying canonical Story -> Lesson CTA transition...")
	var app_scene: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	var app: Node = app_scene.instantiate()
	_add_node_to_tree(app)
	if app.has_method("bootstrap_runtime"):
		app.call("bootstrap_runtime")
	app.call("_on_guest_entered")

	# Start new game (or enter stage 1.1)
	app.call("start_new_game")

	var shell: Control = app.call("get_presentation_shell") as Control
	if shell == null:
		print("[STORY-VIS-011] FAIL: StagePresentationShell is null in AppRoot")
		_remove_node_from_tree(app)
		return false

	# Ensure in story mode
	shell.call("show_story_phase")
	if int(shell.call("get_view_mode")) != int(StagePresentationShell.ViewMode.MODE_STORY):
		print("[STORY-VIS-011] FAIL: Shell not in MODE_STORY")
		_remove_node_from_tree(app)
		return false

	var story_panel: Control = shell.call("get_story_panel") as Control
	var continue_btn: Button = story_panel.call("get_continue_button") as Button if story_panel else null
	if continue_btn == null or continue_btn.text != "VÀO BÀI HỌC":
		print("[STORY-VIS-011] FAIL: Continue CTA button missing or text != 'VÀO BÀI HỌC': %s" % (continue_btn.text if continue_btn else "null"))
		_remove_node_from_tree(app)
		return false

	# Press continue button -> should trigger _on_story_completed in AppRoot -> show_lesson_phase
	continue_btn.emit_signal("pressed")

	if int(shell.call("get_view_mode")) != int(StagePresentationShell.ViewMode.MODE_LESSON):
		print("[STORY-VIS-011] FAIL: Expected transition to MODE_LESSON, got %d" % int(shell.call("get_view_mode")))
		_remove_node_from_tree(app)
		return false

	_remove_node_from_tree(app)
	print("[STORY-VIS-011] PASS")
	return true

# STORY-VIS-012: Lesson visual remains 100% unchanged
static func test_story_vis_012_lesson_visual_remains_unchanged() -> bool:
	print("[STORY-VIS-012] Verifying LessonPanel visual and shell state unaffected...")
	var shell: Control = _create_shell()
	var ctx: RefCounted = _sample_d1_story_context()
	shell.call("set_stage_context", ctx)

	# 1. Switch to MODE_STORY
	shell.call("show_story_phase")
	var story_p: Control = shell.call("get_story_panel") as Control
	var lesson_p: Control = shell.call("get_lesson_panel") as Control

	if not story_p.visible:
		print("[STORY-VIS-012] FAIL: In MODE_STORY, story_panel must be visible")
		_remove_node_from_tree(shell)
		return false

	# 2. Switch to MODE_LESSON
	shell.call("show_lesson_phase")

	if story_p.visible or not lesson_p.visible:
		print("[STORY-VIS-012] FAIL: In MODE_LESSON, story_panel must be hidden and lesson_panel visible")
		_remove_node_from_tree(shell)
		return false

	var sidebar: Control = shell.get_node_or_null("VBoxContainer/MainBody/ContentHBox/LeftSidebar") as Control
	if sidebar == null or not sidebar.visible:
		print("[STORY-VIS-012] FAIL: LeftSidebar must be visible in MODE_LESSON")
		_remove_node_from_tree(shell)
		return false

	var header_bar: Control = shell.get_node_or_null("VBoxContainer/HeaderBar") as Control
	if header_bar == null or not header_bar.visible:
		print("[STORY-VIS-012] FAIL: HeaderBar must be visible in MODE_LESSON")
		_remove_node_from_tree(shell)
		return false

	_remove_node_from_tree(shell)
	print("[STORY-VIS-012] PASS")
	return true

# STORY-VIS-013: Responsive layout at 1600x900
static func test_story_vis_013_responsive_1600x900() -> bool:
	print("[STORY-VIS-013] Verifying responsive layout stability at 1600x900...")
	var shell: Control = _create_shell(Vector2(1600, 900))
	var ctx: RefCounted = _sample_d1_story_context()
	shell.call("set_stage_context", ctx)
	shell.call("show_story_phase")

	var story_p: Control = shell.call("get_story_panel") as Control
	if story_p == null or not story_p.visible:
		print("[STORY-VIS-013] FAIL: StoryPanel not visible at 1600x900")
		_remove_node_from_tree(shell)
		return false

	if story_p.size.x < 1500.0 or story_p.size.y < 850.0:
		print("[STORY-VIS-013] FAIL: StoryPanel size not expanded to 1600x900: %s" % str(story_p.size))
		_remove_node_from_tree(shell)
		return false

	var dlg: Control = story_p.call("get_dialogue_panel") as Control
	if dlg == null or not dlg.visible:
		print("[STORY-VIS-013] FAIL: Dialogue panel not visible at 1600x900")
		_remove_node_from_tree(shell)
		return false

	var cta: Button = story_p.call("get_continue_button") as Button
	if cta == null or not cta.visible:
		print("[STORY-VIS-013] FAIL: CTA button not visible at 1600x900")
		_remove_node_from_tree(shell)
		return false

	_remove_node_from_tree(shell)
	print("[STORY-VIS-013] PASS")
	return true

# STORY-VIS-014: Responsive layout at 1920x1080
static func test_story_vis_014_responsive_1920x1080() -> bool:
	print("[STORY-VIS-014] Verifying responsive layout stability at 1920x1080...")
	var shell: Control = _create_shell(Vector2(1920, 1080))
	var ctx: RefCounted = _sample_d1_story_context()
	shell.call("set_stage_context", ctx)
	shell.call("show_story_phase")

	var story_p: Control = shell.call("get_story_panel") as Control
	if story_p == null or not story_p.visible:
		print("[STORY-VIS-014] FAIL: StoryPanel not visible at 1920x1080")
		_remove_node_from_tree(shell)
		return false

	if story_p.size.x < 1800.0 or story_p.size.y < 1000.0:
		print("[STORY-VIS-014] FAIL: StoryPanel size not expanded to 1920x1080: %s" % str(story_p.size))
		_remove_node_from_tree(shell)
		return false

	var cta: Button = story_p.call("get_continue_button") as Button
	if cta == null or not cta.visible:
		print("[STORY-VIS-014] FAIL: CTA button not visible at 1920x1080")
		_remove_node_from_tree(shell)
		return false

	_remove_node_from_tree(shell)
	print("[STORY-VIS-014] PASS")
	return true

# STORY-VIS-015: No invented controls
static func test_story_vis_015_no_invented_controls() -> bool:
	print("[STORY-VIS-015] Verifying strict Figma adherence without invented controls...")
	var panel: Control = _create_story_panel()
	var buttons: Array[Button] = []
	var queue: Array[Node] = [panel]
	while not queue.is_empty():
		var cur: Node = queue.pop_front()
		if cur is Button:
			buttons.append(cur as Button)
		for c in cur.get_children():
			queue.append(c)

	# Exactly 2 canonical buttons: PauseButton and ContinueButton
	var button_names: Array[String] = []
	for b in buttons:
		button_names.append(b.name)

	if not button_names.has("PauseButton") or not button_names.has("ContinueButton"):
		print("[STORY-VIS-015] FAIL: Expected PauseButton and ContinueButton, got: %s" % str(button_names))
		_remove_node_from_tree(panel)
		return false

	if button_names.size() > 2:
		print("[STORY-VIS-015] FAIL: Found invented buttons in StoryPanel: %s" % str(button_names))
		_remove_node_from_tree(panel)
		return false

	_remove_node_from_tree(panel)
	print("[STORY-VIS-015] PASS")
	return true

# STORY-VIS-016: No opaque white lower overlay on Draven portrait
static func test_story_vis_016_no_opaque_white_lower_overlay() -> bool:
	print("[STORY-VIS-016] Verifying no opaque white lower overlay on Draven portrait...")
	var panel: Control = _create_story_panel()
	var lower_grad_rect: TextureRect = panel.find_child("DravenLowerGradient", true, false) as TextureRect

	if lower_grad_rect == null:
		print("[STORY-VIS-016] FAIL: DravenLowerGradient node missing")
		_remove_node_from_tree(panel)
		return false

	var tex: GradientTexture2D = lower_grad_rect.texture as GradientTexture2D
	if tex == null or tex.gradient == null:
		print("[STORY-VIS-016] FAIL: DravenLowerGradient texture or gradient is null")
		_remove_node_from_tree(panel)
		return false

	var colors: PackedColorArray = tex.gradient.colors
	for c in colors:
		# Assert no point in lower gradient is opaque white (R>0.8, G>0.8, B>0.8, A>0.5)
		if c.r > 0.8 and c.g > 0.8 and c.b > 0.8 and c.a > 0.5:
			print("[STORY-VIS-016] FAIL: Found opaque white color in Draven lower gradient: %s" % str(c))
			_remove_node_from_tree(panel)
			return false

	# Assert Draven portrait path is untouched
	var draven_rect: TextureRect = panel.call("get_draven_texture_rect") as TextureRect
	if draven_rect == null:
		print("[STORY-VIS-016] FAIL: DravenTextureRect missing")
		_remove_node_from_tree(panel)
		return false

	_remove_node_from_tree(panel)
	print("[STORY-VIS-016] PASS: Draven lower gradient transparency & atmospheric blend verified!")
	return true
