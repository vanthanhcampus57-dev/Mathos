class_name StagePresentationShell
extends PanelContainer

## Main UI Presentation Shell for Mathos stages (e.g. Stage 1.1 -> 4.5).
## Hosts lesson dialogue, question host container, feedback host container,
## left icon sidebar, advisor panel, stage completion panels,
## Game Victory Panel, Dungeon Stage Map Panel, and Pause Menu Overlay.

enum ViewMode {
	MODE_ENTRY = 0,
	MODE_LESSON = 1,
	MODE_QUESTION_HOST = 2,
	MODE_FEEDBACK_HOST = 3,
	MODE_STAGE_COMPLETE = 4,
	MODE_VICTORY = 5,
	MODE_MAP = 6,
	MODE_STORY = 7,
	MODE_DUNGEON_COMPLETE = 8,
	MODE_PROLOGUE = 9
}

signal new_game_requested()
signal continue_game_requested()
signal show_map_requested()
signal return_to_main_menu_requested()
signal lesson_continue_requested()
signal story_continue_requested()
signal story_completed()
signal question_host_ready(container: Control)
signal feedback_host_ready(container: Control)
signal stage_continue_requested()
signal stage_selected(stage_id: String)
signal pause_requested()
signal resume_requested()
signal logout_requested()
signal prologue_completed()
signal prologue_skipped()

var _current_mode: ViewMode = ViewMode.MODE_ENTRY
var _previous_mode: ViewMode = ViewMode.MODE_LESSON
var _context_info: PresentationModels.StageContextInfo = null

# Sub-components
var _victory_panel: GameVictoryPanel = null
var _stage_map_panel: DungeonStageMapPanel = null
var _pause_overlay: PauseMenuOverlay = null
var _story_panel: Control = null
var _prologue_player: Control = null
var _hub_panel: Control = null

# Buttons in Main Menu
var _journey_map_button: Button = null
var _save_summary_label: Label = null
var _pause_button: Button = null

# Notification Banner
var _notification_banner: PanelContainer = null
var _notification_label: Label = null
var _notification_tween: Tween = null

const D1_BG_PATH: String = "res://assets/backgrounds/d1_misty_forest_bg.png"
const D1_BG_ALT_PATH: String = "res://assets/backgrounds/dungeon_1/d1_misty_forest_bg.png"

const D1_FOG_PATH: String = "res://assets/backgrounds/d1_misty_forest_fog_8f.png"
const D1_FOG_ALT_PATH: String = "res://assets/backgrounds/dungeon_1/d1_misty_forest_fog_8f.png"

const D1_PROCEDURAL_FOG_PATH: String = "res://assets/backgrounds/d1_misty_forest_fog_layer.png"
const D1_PROCEDURAL_FOG_ALT_PATH: String = "res://assets/backgrounds/dungeon_1/d1_misty_forest_fog_layer.png"

const BRAND_LOGO_MAIN_PATH: String = "res://assets/branding/mathos_logo_main.png"
const BRAND_LOGO_EMBLEM_PATH: String = "res://assets/branding/mathos_logo_emblem.png"

# Locked D1 Production Fog Preset v1
const PROC_FOG_OPACITY: float = 0.48
const PROC_FOG_DRIFT_AMOUNT: float = 120.0
const PROC_FOG_DRIFT_SPEED: float = 0.15
const PROC_FOG_DISTORTION: float = 0.08
const PROC_FOG_BREATHING: float = 0.05
const PROC_FOG_LAYER_COUNT: int = 3

# Historical Old Atlas Constants (preserved for Visual Lab / backward compatibility)
const FOG_FPS: float = 2.0
const FOG_COLS: int = 4
const FOG_ROWS: int = 2
const FOG_FRAME_WIDTH: int = 512
const FOG_FRAME_HEIGHT: int = 288

var _fog_source_texture: Texture2D = null
var _fog_frames: Array[AtlasTexture] = []
var _fog_frame_timer: float = 0.0
var _fog_current_frame: int = 0

# Production Procedural Fog Nodes & State
var _procedural_fog_texture: Texture2D = null
var _procedural_fog_container: Control = null
var _proc_layer_1: TextureRect = null
var _proc_layer_2: TextureRect = null
var _proc_layer_3: TextureRect = null
var _procedural_fog_time: float = 0.0

func _ready() -> void:
	set_process(true)
	_ensure_visual_nodes()
	_update_background_texture()
	_update_branding_logos()
	_ensure_sub_components()

	var new_game_btn: Button = _get_new_game_button()
	if new_game_btn != null:
		if not new_game_btn.pressed.is_connected(_on_new_game_pressed):
			new_game_btn.pressed.connect(_on_new_game_pressed)

	var continue_game_btn: Button = _get_continue_game_button()
	if continue_game_btn != null:
		if not continue_game_btn.pressed.is_connected(_on_continue_game_pressed):
			continue_game_btn.pressed.connect(_on_continue_game_pressed)

	if _journey_map_button != null:
		if not _journey_map_button.pressed.is_connected(_on_journey_map_pressed):
			_journey_map_button.pressed.connect(_on_journey_map_pressed)

	var lesson_panel: LessonPanel = get_lesson_panel()
	if lesson_panel != null:
		if not lesson_panel.continue_requested.is_connected(_on_lesson_continue):
			lesson_panel.continue_requested.connect(_on_lesson_continue)

	var stage_complete_panel: StageCompletePanel = get_stage_complete_panel()
	if stage_complete_panel != null:
		if not stage_complete_panel.stage_continue_requested.is_connected(_on_stage_continue):
			stage_complete_panel.stage_continue_requested.connect(_on_stage_continue)

	var q_host: MarginContainer = get_question_host_container()
	if q_host != null and not q_host.child_entered_tree.is_connected(_on_question_host_child_entered):
		q_host.child_entered_tree.connect(_on_question_host_child_entered)

	var sidebar_map_btn: Button = get_node_or_null("VBoxContainer/MainBody/ContentHBox/LeftSidebar/SidebarVBox/NavMapButton") as Button
	if sidebar_map_btn != null and not sidebar_map_btn.pressed.is_connected(_on_journey_map_pressed):
		sidebar_map_btn.pressed.connect(_on_journey_map_pressed)

	set_view_mode(_current_mode)

func _ensure_sub_components() -> void:
	var main_content: Control = _get_main_content_vbox()

	# Victory Panel
	if _victory_panel == null and main_content != null:
		_victory_panel = main_content.get_node_or_null("GameVictoryPanel") as GameVictoryPanel
		if _victory_panel == null:
			_victory_panel = GameVictoryPanel.new()
			_victory_panel.name = "GameVictoryPanel"
			_victory_panel.visible = false
			main_content.add_child(_victory_panel)

		if not _victory_panel.return_to_main_menu_requested.is_connected(_on_victory_return_pressed):
			_victory_panel.return_to_main_menu_requested.connect(_on_victory_return_pressed)

	# Dungeon Stage Map Panel
	if _stage_map_panel == null and main_content != null:
		_stage_map_panel = main_content.get_node_or_null("DungeonStageMapPanel") as DungeonStageMapPanel
		if _stage_map_panel == null:
			_stage_map_panel = DungeonStageMapPanel.new()
			_stage_map_panel.name = "DungeonStageMapPanel"
			_stage_map_panel.custom_minimum_size = Vector2.ZERO
			_stage_map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_stage_map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_stage_map_panel.visible = false
			main_content.add_child(_stage_map_panel)
		else:
			_stage_map_panel.custom_minimum_size = Vector2.ZERO
			_stage_map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_stage_map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

		if not _stage_map_panel.is_node_ready():
			_stage_map_panel._ready()
		_stage_map_panel.custom_minimum_size = Vector2.ZERO

		if not _stage_map_panel.stage_selected.is_connected(_on_map_stage_selected):
			_stage_map_panel.stage_selected.connect(_on_map_stage_selected)
		if not _stage_map_panel.back_requested.is_connected(_on_map_return_pressed):
			_stage_map_panel.back_requested.connect(_on_map_return_pressed)

	# Story Panel
	if _story_panel == null:
		_story_panel = get_node_or_null("StoryPanel") as Control
		if _story_panel == null and main_content != null:
			_story_panel = main_content.get_node_or_null("StoryPanel") as Control
		if _story_panel == null:
			var story_scene: Resource = load("res://src/ui/story/story_panel.tscn")
			if story_scene is PackedScene:
				_story_panel = (story_scene as PackedScene).instantiate() as Control
			else:
				var story_script: Resource = load("res://src/ui/story/story_panel.gd")
				if story_script is GDScript:
					_story_panel = (story_script as GDScript).new() as Control
			if _story_panel != null:
				_story_panel.name = "StoryPanel"
				_story_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				_story_panel.custom_minimum_size = Vector2.ZERO
				_story_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				_story_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
				_story_panel.visible = false
				add_child(_story_panel)
				if _pause_overlay != null:
					move_child(_story_panel, _pause_overlay.get_index())
		else:
			_story_panel.custom_minimum_size = Vector2.ZERO
			_story_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_story_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

		if _story_panel != null:
			if not _story_panel.is_node_ready():
				_story_panel._ready()
			if not _story_panel.continue_requested.is_connected(_on_story_continue):
				_story_panel.continue_requested.connect(_on_story_continue)
			if not _story_panel.pause_requested.is_connected(toggle_pause):
				_story_panel.pause_requested.connect(toggle_pause)

	# Prologue Player
	if _prologue_player == null:
		var pro_scene: Resource = load("res://src/ui/prologue/prologue_player.tscn")
		if pro_scene is PackedScene:
			_prologue_player = (pro_scene as PackedScene).instantiate() as Control
		else:
			var pro_script: Resource = load("res://src/ui/prologue/prologue_player.gd")
			if pro_script is GDScript:
				_prologue_player = (pro_script as GDScript).new() as Control
		if _prologue_player != null:
			_prologue_player.name = "ProloguePlayer"
			_prologue_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_prologue_player.custom_minimum_size = Vector2.ZERO
			_prologue_player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_prologue_player.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_prologue_player.visible = false
			add_child(_prologue_player)
			if _pause_overlay != null:
				move_child(_prologue_player, _pause_overlay.get_index())
			if _prologue_player.has_signal("prologue_completed") and not _prologue_player.prologue_completed.is_connected(_on_prologue_completed):
				_prologue_player.prologue_completed.connect(_on_prologue_completed)
			if _prologue_player.has_signal("prologue_skipped") and not _prologue_player.prologue_skipped.is_connected(_on_prologue_skipped):
				_prologue_player.prologue_skipped.connect(_on_prologue_skipped)
			if _prologue_player.has_signal("volume_pressed") and not _prologue_player.volume_pressed.is_connected(toggle_pause):
				_prologue_player.volume_pressed.connect(toggle_pause)
			if _prologue_player.has_signal("settings_pressed") and not _prologue_player.settings_pressed.is_connected(toggle_pause):
				_prologue_player.settings_pressed.connect(toggle_pause)

	# Pause Menu Overlay
	if _pause_overlay == null:
		_pause_overlay = get_node_or_null("PauseMenuOverlay") as PauseMenuOverlay
		if _pause_overlay == null:
			_pause_overlay = PauseMenuOverlay.new()
			_pause_overlay.name = "PauseMenuOverlay"
			_pause_overlay.visible = false
			add_child(_pause_overlay)

		if not _pause_overlay.resume_requested.is_connected(_on_pause_resume):
			_pause_overlay.resume_requested.connect(_on_pause_resume)
		if not _pause_overlay.stage_map_requested.is_connected(_on_pause_map):
			_pause_overlay.stage_map_requested.connect(_on_pause_map)
		if not _pause_overlay.main_menu_requested.is_connected(_on_pause_main_menu):
			_pause_overlay.main_menu_requested.connect(_on_pause_main_menu)
		if not _pause_overlay.logout_requested.is_connected(_on_pause_logout):
			_pause_overlay.logout_requested.connect(_on_pause_logout)

	# Sanctum Nexus Hub Panel
	if _hub_panel == null:
		var hub_scene: Resource = load("res://src/ui/hub/sanctum_nexus_hub.tscn")
		if hub_scene is PackedScene:
			_hub_panel = (hub_scene as PackedScene).instantiate() as Control
		else:
			var hub_script: Resource = load("res://src/ui/hub/sanctum_nexus_hub.gd")
			if hub_script is GDScript:
				_hub_panel = (hub_script as GDScript).new() as Control
		if _hub_panel != null:
			_hub_panel.name = "SanctumNexusHub"
			_hub_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_hub_panel.custom_minimum_size = Vector2.ZERO
			_hub_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_hub_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_hub_panel.visible = (_current_mode == ViewMode.MODE_ENTRY)
			add_child(_hub_panel)
			if _pause_overlay != null:
				move_child(_hub_panel, _pause_overlay.get_index())
			_hub_panel.custom_minimum_size = Vector2.ZERO

			if _hub_panel.has_signal("continue_requested") and not _hub_panel.continue_requested.is_connected(_on_continue_game_pressed):
				_hub_panel.continue_requested.connect(_on_continue_game_pressed)
			if _hub_panel.has_signal("new_game_requested") and not _hub_panel.new_game_requested.is_connected(_on_new_game_pressed):
				_hub_panel.new_game_requested.connect(_on_new_game_pressed)
			if _hub_panel.has_signal("map_requested") and not _hub_panel.map_requested.is_connected(_on_journey_map_pressed):
				_hub_panel.map_requested.connect(_on_journey_map_pressed)
			if _hub_panel.has_signal("replay_requested") and not _hub_panel.replay_requested.is_connected(_on_hub_replay_requested):
				_hub_panel.replay_requested.connect(_on_hub_replay_requested)
			if _hub_panel.has_signal("pause_requested") and not _hub_panel.pause_requested.is_connected(toggle_pause):
				_hub_panel.pause_requested.connect(toggle_pause)

	# Journey Map Button in Start Container
	if _journey_map_button == null:
		var start_vbox: VBoxContainer = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer") as VBoxContainer
		if start_vbox != null:
			_journey_map_button = start_vbox.get_node_or_null("JourneyMapButton") as Button
			if _journey_map_button == null:
				_journey_map_button = Button.new()
				_journey_map_button.name = "JourneyMapButton"
				_journey_map_button.text = "Bản đồ hành trình"
				_journey_map_button.custom_minimum_size = Vector2(280, 48)
				_journey_map_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				_journey_map_button.theme_type_variation = &"MathosSecondaryButton"
				start_vbox.add_child(_journey_map_button)

			if not _journey_map_button.pressed.is_connected(_on_journey_map_pressed):
				_journey_map_button.pressed.connect(_on_journey_map_pressed)

	# Pause Button in Header
	var header_bar: HBoxContainer = get_node_or_null("VBoxContainer/HeaderBar") as HBoxContainer
	if header_bar != null:
		_pause_button = header_bar.get_node_or_null("PauseButton") as Button
		if _pause_button == null:
			_pause_button = Button.new()
			_pause_button.name = "PauseButton"
			_pause_button.custom_minimum_size = Vector2(100, 36)
			_pause_button.theme_type_variation = &"MathosSecondaryButton"
			_pause_button.text = "Tạm dừng"
			header_bar.add_child(_pause_button)
			if not _pause_button.pressed.is_connected(toggle_pause):
				_pause_button.pressed.connect(toggle_pause)

	var lesson_panel: LessonPanel = get_lesson_panel()
	if lesson_panel != null and not lesson_panel.continue_requested.is_connected(_on_lesson_continue):
		lesson_panel.continue_requested.connect(_on_lesson_continue)

	var stage_complete_panel: StageCompletePanel = get_stage_complete_panel()
	if stage_complete_panel != null and not stage_complete_panel.stage_continue_requested.is_connected(_on_stage_continue):
		stage_complete_panel.stage_continue_requested.connect(_on_stage_continue)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_sort()
		if _stage_map_panel != null and _stage_map_panel.visible:
			if size.x > 0 and size.y > 0:
				_stage_map_panel.size = size
				if _stage_map_panel.has_method("_update_responsive_layout"):
					_stage_map_panel.call("_update_responsive_layout")
		if _story_panel != null and _story_panel.visible:
			if size.x > 0 and size.y > 0:
				_story_panel.size = size
		if _prologue_player != null and _prologue_player.visible:
			if size.x > 0 and size.y > 0:
				_prologue_player.size = size
				if _prologue_player.has_method("update_responsive_layout"):
					_prologue_player.call("update_responsive_layout", size)
		if _hub_panel != null and _hub_panel.visible:
			if size.x > 0 and size.y > 0:
				if _hub_panel.has_method("update_responsive_layout"):
					_hub_panel.call("update_responsive_layout", size)

func _process(delta: float) -> void:
	_update_fog_animation(delta)

func _ensure_visual_nodes() -> void:
	var bg_rect: TextureRect = get_node_or_null("BackgroundTextureRect") as TextureRect
	if bg_rect != null:
		bg_rect.mouse_filter = MOUSE_FILTER_IGNORE
		bg_rect.texture_filter = TEXTURE_FILTER_NEAREST
		bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fog_rect: TextureRect = get_node_or_null("FogOverlayTextureRect") as TextureRect
	if fog_rect != null:
		fog_rect.mouse_filter = MOUSE_FILTER_IGNORE
		fog_rect.texture_filter = TEXTURE_FILTER_NEAREST
		fog_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fog_rect.visible = false # Old atlas is disabled in production

	_ensure_procedural_fog_nodes()

func _ensure_procedural_fog_nodes() -> void:
	if _procedural_fog_container != null and is_instance_valid(_procedural_fog_container):
		return

	_procedural_fog_container = get_node_or_null("ProceduralFogContainer") as Control
	if _procedural_fog_container == null:
		_procedural_fog_container = Control.new()
		_procedural_fog_container.name = "ProceduralFogContainer"
		_procedural_fog_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_procedural_fog_container.clip_contents = true
		_procedural_fog_container.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_procedural_fog_container)

		var bg_rect: TextureRect = get_node_or_null("BackgroundTextureRect") as TextureRect
		if bg_rect != null:
			move_child(_procedural_fog_container, bg_rect.get_index() + 1)

	if _procedural_fog_texture == null:
		_procedural_fog_texture = _load_texture_from_paths([D1_PROCEDURAL_FOG_PATH, D1_PROCEDURAL_FOG_ALT_PATH])

	if _proc_layer_3 == null or not is_instance_valid(_proc_layer_3):
		_proc_layer_3 = TextureRect.new()
		_proc_layer_3.name = "ProcFogLayer3"
		_proc_layer_3.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_proc_layer_3.stretch_mode = TextureRect.STRETCH_SCALE
		_proc_layer_3.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_proc_layer_3.mouse_filter = MOUSE_FILTER_IGNORE
		_proc_layer_3.texture = _procedural_fog_texture
		_procedural_fog_container.add_child(_proc_layer_3)

	if _proc_layer_2 == null or not is_instance_valid(_proc_layer_2):
		_proc_layer_2 = TextureRect.new()
		_proc_layer_2.name = "ProcFogLayer2"
		_proc_layer_2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_proc_layer_2.stretch_mode = TextureRect.STRETCH_SCALE
		_proc_layer_2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_proc_layer_2.mouse_filter = MOUSE_FILTER_IGNORE
		_proc_layer_2.texture = _procedural_fog_texture
		_procedural_fog_container.add_child(_proc_layer_2)

	if _proc_layer_1 == null or not is_instance_valid(_proc_layer_1):
		_proc_layer_1 = TextureRect.new()
		_proc_layer_1.name = "ProcFogLayer1"
		_proc_layer_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_proc_layer_1.stretch_mode = TextureRect.STRETCH_SCALE
		_proc_layer_1.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_proc_layer_1.mouse_filter = MOUSE_FILTER_IGNORE
		_proc_layer_1.texture = _procedural_fog_texture
		_procedural_fog_container.add_child(_proc_layer_1)

func _is_dungeon_1_context() -> bool:
	if _context_info == null:
		return true
	var d_title: String = _context_info.dungeon_title.to_lower()
	var s_id: String = _context_info.stage_id.to_lower()
	if d_title.is_empty() and s_id.is_empty():
		return true
	if d_title.contains("rừng mù sương") or d_title.contains("dungeon 1") or d_title.contains("d1"):
		return true
	if s_id.begins_with("stage_1") or s_id.begins_with("d1"):
		return true
	return false

func _update_background_texture() -> void:
	_ensure_visual_nodes()

	var bg_rect: TextureRect = get_node_or_null("BackgroundTextureRect") as TextureRect
	var fog_rect: TextureRect = get_node_or_null("FogOverlayTextureRect") as TextureRect

	if not _is_dungeon_1_context() or _current_mode == ViewMode.MODE_MAP or _current_mode == ViewMode.MODE_PROLOGUE:
		if fog_rect != null:
			fog_rect.visible = false
		if _procedural_fog_container != null:
			_procedural_fog_container.visible = false
		return

	var bg_tex: Texture2D = _load_texture_from_paths([D1_BG_PATH, D1_BG_ALT_PATH, "res://assets/backgrounds/misty_forest_v1.jpg"])
	if bg_rect != null and bg_tex != null:
		bg_rect.texture = bg_tex
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	if fog_rect != null:
		fog_rect.visible = false # Old atlas is disabled in production

	if _procedural_fog_container != null:
		_procedural_fog_container.visible = true

func calculate_overscan_info(vp_size: Vector2) -> Dictionary:
	var src_w: float = 2115.0
	var src_h: float = 744.0
	if _procedural_fog_texture != null:
		src_w = float(_procedural_fog_texture.get_width())
		src_h = float(_procedural_fog_texture.get_height())

	var aspect: float = src_w / src_h
	var base_disp_height: float = vp_size.y
	var base_disp_width: float = base_disp_height * aspect

	var max_drift_mult: float = 1.2
	var max_drift_px: float = PROC_FOG_DRIFT_AMOUNT * max_drift_mult
	var max_distortion_px: float = PROC_FOG_DISTORTION * 25.0
	var max_offset_px: float = max_drift_px + max_distortion_px
	var safety_margin: float = 64.0

	var required_overscan_per_side: float = max_offset_px + safety_margin
	var required_total_width: float = vp_size.x + 2.0 * required_overscan_per_side

	var scale_factor: float = 1.0
	if base_disp_width < required_total_width:
		scale_factor = required_total_width / base_disp_width

	var final_disp_width: float = base_disp_width * scale_factor
	var final_disp_height: float = base_disp_height * scale_factor

	return {
		"aspect": aspect,
		"disp_width": final_disp_width,
		"disp_height": final_disp_height,
		"base_center_x": (vp_size.x - final_disp_width) / 2.0,
		"base_center_y": (vp_size.y - final_disp_height) / 2.0,
		"required_overscan": required_overscan_per_side
	}

func get_fog_frames() -> Array[AtlasTexture]:
	_init_fog_frames()
	return _fog_frames

func _init_fog_frames() -> void:
	if not _fog_frames.is_empty():
		return

	_fog_source_texture = _load_texture_from_paths([D1_FOG_PATH, D1_FOG_ALT_PATH])
	if _fog_source_texture == null:
		return

	_fog_frames.clear()
	for row in range(FOG_ROWS):
		for col in range(FOG_COLS):
			var atlas_tex: AtlasTexture = AtlasTexture.new()
			atlas_tex.atlas = _fog_source_texture
			atlas_tex.region = Rect2(float(col * FOG_FRAME_WIDTH), float(row * FOG_FRAME_HEIGHT), float(FOG_FRAME_WIDTH), float(FOG_FRAME_HEIGHT))
			_fog_frames.append(atlas_tex)

func _update_fog_animation(delta: float) -> void:
	if _procedural_fog_container == null or not _procedural_fog_container.visible or not is_inside_tree():
		return

	if _procedural_fog_texture == null:
		_procedural_fog_texture = _load_texture_from_paths([D1_PROCEDURAL_FOG_PATH, D1_PROCEDURAL_FOG_ALT_PATH])
		if _procedural_fog_texture != null:
			if _proc_layer_1 != null: _proc_layer_1.texture = _procedural_fog_texture
			if _proc_layer_2 != null: _proc_layer_2.texture = _procedural_fog_texture
			if _proc_layer_3 != null: _proc_layer_3.texture = _procedural_fog_texture

	if _procedural_fog_texture == null:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return

	_procedural_fog_time += delta
	var time: float = _procedural_fog_time * PROC_FOG_DRIFT_SPEED

	var overscan_info: Dictionary = calculate_overscan_info(vp_size)
	var disp_w: float = overscan_info["disp_width"]
	var disp_h: float = overscan_info["disp_height"]
	var center_x: float = overscan_info["base_center_x"]
	var center_y: float = overscan_info["base_center_y"]

	var layers: Array[TextureRect] = [_proc_layer_1, _proc_layer_2, _proc_layer_3]
	var layer_configs: Array[Dictionary] = [
		{
			"freq_x": 0.7, "drift_mult": 1.0,
			"freq_y": 0.4, "dist_mult": 20.0,
			"freq_s": 0.3, "scale_amp": 0.05, "base_scale": 1.0,
			"freq_a": 0.8, "alpha_mult": 1.0
		},
		{
			"freq_x": 0.5, "phase_x": 1.5, "drift_mult": 0.8,
			"freq_y": 0.3, "phase_y": 2.0, "dist_mult": 15.0,
			"freq_s": 0.2, "scale_amp": 0.04, "base_scale": 1.05,
			"freq_a": 0.6, "alpha_mult": 0.65
		},
		{
			"freq_x": 0.3, "phase_x": 3.0, "drift_mult": 1.2,
			"freq_y": 0.5, "phase_y": 1.0, "dist_mult": 25.0,
			"freq_s": 0.1, "scale_amp": 0.03, "base_scale": 1.10,
			"freq_a": 0.4, "alpha_mult": 0.45
		}
	]

	for idx in range(3):
		var layer_node: TextureRect = layers[idx]
		var cfg: Dictionary = layer_configs[idx]

		if layer_node == null:
			continue

		var px_x: float = cfg.get("phase_x", 0.0)
		var px_y: float = cfg.get("phase_y", 0.0)

		var off_x: float = sin(time * cfg["freq_x"] + px_x) * (PROC_FOG_DRIFT_AMOUNT * cfg["drift_mult"])
		var off_y: float = cos(time * cfg["freq_y"] + px_y) * (PROC_FOG_DISTORTION * cfg["dist_mult"])

		var scale_delta: float = sin(time * cfg["freq_s"]) * (PROC_FOG_DISTORTION * cfg["scale_amp"])
		var layer_scale: float = maxf(0.8, cfg["base_scale"] + scale_delta)

		var alpha: float = clampf((PROC_FOG_OPACITY * cfg["alpha_mult"]) * (1.0 + sin(time * cfg["freq_a"]) * PROC_FOG_BREATHING), 0.0, 1.0)

		layer_node.size = Vector2(disp_w, disp_h)
		layer_node.pivot_offset = Vector2(disp_w / 2.0, disp_h / 2.0)
		layer_node.position = Vector2(center_x + off_x, center_y + off_y)
		layer_node.scale = Vector2(layer_scale, layer_scale)
		layer_node.modulate = Color(1.0, 1.0, 1.0, alpha)

func get_procedural_fog_container() -> Control:
	_ensure_procedural_fog_nodes()
	return _procedural_fog_container

func get_procedural_fog_texture() -> Texture2D:
	if _procedural_fog_texture == null:
		_procedural_fog_texture = _load_texture_from_paths([D1_PROCEDURAL_FOG_PATH, D1_PROCEDURAL_FOG_ALT_PATH])
	return _procedural_fog_texture

func get_procedural_fog_preset() -> Dictionary:
	return {
		"opacity": PROC_FOG_OPACITY,
		"drift_amount": PROC_FOG_DRIFT_AMOUNT,
		"drift_speed": PROC_FOG_DRIFT_SPEED,
		"distortion": PROC_FOG_DISTORTION,
		"breathing": PROC_FOG_BREATHING,
		"layer_count": PROC_FOG_LAYER_COUNT
	}

func is_old_fog_atlas_disabled_in_production() -> bool:
	var fog_rect: TextureRect = get_node_or_null("FogOverlayTextureRect") as TextureRect
	return fog_rect == null or not fog_rect.visible

func is_atmospheric_overlay_active() -> bool:
	if _procedural_fog_container != null and _procedural_fog_container.visible:
		return true
	var fog_rect: TextureRect = get_node_or_null("FogOverlayTextureRect") as TextureRect
	if fog_rect != null and fog_rect.visible:
		return true
	return false

func _update_branding_logos() -> void:
	var logo_main_tex: Texture2D = _load_texture_from_paths([BRAND_LOGO_MAIN_PATH])
	var start_vbox: VBoxContainer = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer") as VBoxContainer
	if start_vbox != null and logo_main_tex != null:
		var logo_rect: TextureRect = start_vbox.get_node_or_null("MainLogoTextureRect") as TextureRect
		if logo_rect == null:
			logo_rect = TextureRect.new()
			logo_rect.name = "MainLogoTextureRect"
			logo_rect.custom_minimum_size = Vector2(360, 120)
			logo_rect.size_flags_horizontal = SIZE_SHRINK_CENTER
			logo_rect.mouse_filter = MOUSE_FILTER_IGNORE
			logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			start_vbox.add_child(logo_rect)
			start_vbox.move_child(logo_rect, 0)
		logo_rect.texture = logo_main_tex
		var title_lbl: Label = start_vbox.get_node_or_null("TitleLabel") as Label
		if title_lbl != null:
			title_lbl.visible = false

func _load_texture_from_paths(paths: Array) -> Texture2D:
	for p in paths:
		var p_str: String = String(p)
		if ResourceLoader.exists(p_str):
			var res: Resource = load(p_str)
			if res is Texture2D:
				return res as Texture2D

		var global_p: String = ProjectSettings.globalize_path(p_str)
		var img: Image = Image.new()
		if img.load(global_p) == OK:
			var tex: ImageTexture = ImageTexture.create_from_image(img)
			if tex != null:
				return tex
		if img.load(p_str) == OK:
			var tex2: ImageTexture = ImageTexture.create_from_image(img)
			if tex2 != null:
				return tex2

		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(p_str)
		if bytes.is_empty() and FileAccess.file_exists(global_p):
			bytes = FileAccess.get_file_as_bytes(global_p)

		if not bytes.is_empty():
			var img_buf: Image = Image.new()
			var err: Error = img_buf.load_png_from_buffer(bytes)
			if err != OK:
				err = img_buf.load_jpg_from_buffer(bytes)
			if err == OK:
				var tex3: ImageTexture = ImageTexture.create_from_image(img_buf)
				if tex3 != null:
					return tex3

	return null

func set_stage_context(data: Variant) -> void:
	if data is PresentationModels.StageContextInfo:
		_context_info = data as PresentationModels.StageContextInfo
	elif data is Dictionary:
		_context_info = PresentationModels.StageContextInfo.from_dict(data as Dictionary)
	else:
		_context_info = PresentationModels.StageContextInfo.new()

	_update_header()
	_update_background_texture()

	var lesson_panel: LessonPanel = get_lesson_panel()
	if lesson_panel != null and _context_info != null:
		if _current_mode == ViewMode.MODE_STORY and not _context_info.story_steps.is_empty():
			if lesson_panel.has_method("set_story_mode"):
				lesson_panel.set_story_mode(true)
			lesson_panel.set_lesson_data(_context_info.story_steps)
		else:
			if lesson_panel.has_method("set_story_mode"):
				lesson_panel.set_story_mode(false)
			lesson_panel.set_lesson_data(_context_info.lesson_steps)

	_ensure_sub_components()
	if _story_panel != null and _context_info != null:
		_story_panel.set_context_info(_context_info)

	var stage_complete_panel: StageCompletePanel = get_stage_complete_panel()
	if stage_complete_panel != null and _context_info != null:
		stage_complete_panel.set_summary_data(_context_info.stage_title)

	var advisor_label: Label = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer/GameplayHBox/AdvisorPanel/AdvisorVBox/AdvisorDialogueLabel") as Label
	if advisor_label != null and _context_info != null and not _context_info.stage_advisor_text.is_empty():
		advisor_label.text = _context_info.stage_advisor_text

	var is_boss: bool = is_boss_stage()
	var existing_boss: BossCombatPanel = get_existing_boss_combat_panel()
	if not is_boss and existing_boss != null:
		existing_boss.visible = false
		existing_boss.set_controller(null)

func is_restored_context_displayed() -> bool:
	return _context_info != null and _context_info.is_restored_context

func _update_header() -> void:
	var header_bar: HBoxContainer = get_node_or_null("VBoxContainer/HeaderBar") as HBoxContainer
	if header_bar == null:
		return

	var d_label: Label = header_bar.get_node_or_null("DungeonTitleLabel") as Label
	var s_label: Label = header_bar.get_node_or_null("StageTitleLabel") as Label

	if d_label != null and _context_info != null:
		d_label.text = _context_info.dungeon_title
	if s_label != null and _context_info != null:
		s_label.text = _context_info.stage_title

	var badge_label: Label = header_bar.get_node_or_null("RestoredBadgeLabel") as Label
	if badge_label != null:
		badge_label.text = ""
		badge_label.visible = (_context_info != null and _context_info.is_restored_context)

	if _current_mode == ViewMode.MODE_ENTRY or _current_mode == ViewMode.MODE_MAP or _current_mode == ViewMode.MODE_VICTORY or _current_mode == ViewMode.MODE_DUNGEON_COMPLETE or _current_mode == ViewMode.MODE_STORY or _current_mode == ViewMode.MODE_PROLOGUE or (_current_mode == ViewMode.MODE_QUESTION_HOST and is_boss_stage()):
		header_bar.visible = false
		return

	header_bar.visible = true

func _get_dungeon_title_label() -> Label:
	var header_bar: HBoxContainer = _get_header_bar()
	if header_bar != null:
		return header_bar.get_node_or_null("DungeonTitleLabel") as Label
	return null

func set_view_mode(mode: ViewMode) -> void:
	_ensure_sub_components()
	_previous_mode = _current_mode
	_current_mode = mode
	_update_header()
	_update_background_texture()

	if _previous_mode == ViewMode.MODE_QUESTION_HOST and _current_mode != ViewMode.MODE_QUESTION_HOST:
		var q_panel: QuestionPanel = get_question_panel()
		if q_panel != null:
			q_panel.clear_question()

	var main_content: Control = _get_main_content_vbox()
	if main_content == null:
		return

	var start_container: Control = main_content.get_node_or_null("StartGameContainer") as Control
	var lesson_panel: LessonPanel = get_lesson_panel()
	var q_host: MarginContainer = get_question_host_container()
	var f_host: MarginContainer = get_feedback_host_container()
	var complete_panel: StageCompletePanel = get_stage_complete_panel()

	var _boss_fullscreen: bool = (_current_mode == ViewMode.MODE_QUESTION_HOST and is_boss_stage())
	if _current_mode == ViewMode.MODE_MAP or _current_mode == ViewMode.MODE_STORY or _current_mode == ViewMode.MODE_PROLOGUE or _current_mode == ViewMode.MODE_ENTRY or _boss_fullscreen:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		if has_theme_stylebox_override("panel"):
			remove_theme_stylebox_override("panel")

	if _story_panel != null:
		_story_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_story_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_story_panel.visible = (_current_mode == ViewMode.MODE_STORY)
		_story_panel.mouse_filter = Control.MOUSE_FILTER_STOP if (_current_mode == ViewMode.MODE_STORY) else Control.MOUSE_FILTER_IGNORE
		if _current_mode == ViewMode.MODE_STORY:
			var target_size: Vector2 = size
			if target_size.x <= 0 or target_size.y <= 0:
				var root_win: Window = get_tree().root if is_inside_tree() else null
				if root_win != null and root_win.size.x > 0 and root_win.size.y > 0:
					target_size = Vector2(root_win.size)
				else:
					target_size = Vector2(1280, 720)
			_story_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_story_panel.size = target_size
			if _context_info != null:
				_story_panel.set_context_info(_context_info)

	if _prologue_player != null:
		_prologue_player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_prologue_player.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_prologue_player.visible = (_current_mode == ViewMode.MODE_PROLOGUE)
		if _current_mode == ViewMode.MODE_PROLOGUE:
			_prologue_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var target_size_pro: Vector2 = size
			if target_size_pro.x <= 0 or target_size_pro.y <= 0:
				var root_win_pro: Window = get_tree().root if is_inside_tree() else null
				if root_win_pro != null and root_win_pro.size.x > 0 and root_win_pro.size.y > 0:
					target_size_pro = Vector2(root_win_pro.size)
				else:
					target_size_pro = Vector2(1280, 720)
			_prologue_player.size = target_size_pro
			if _prologue_player.has_method("update_responsive_layout"):
				_prologue_player.call("update_responsive_layout", target_size_pro)
			if _prologue_player.has_method("start_prologue"):
				_prologue_player.call("start_prologue")

	if _hub_panel != null:
		_hub_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_hub_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_hub_panel.visible = (_current_mode == ViewMode.MODE_ENTRY)
		_hub_panel.mouse_filter = Control.MOUSE_FILTER_STOP if (_current_mode == ViewMode.MODE_ENTRY) else Control.MOUSE_FILTER_IGNORE
		if _current_mode == ViewMode.MODE_ENTRY:
			var target_size_hub: Vector2 = size
			if target_size_hub.x <= 0 or target_size_hub.y <= 0:
				var root_win_hub: Window = get_tree().root if is_inside_tree() else null
				if root_win_hub != null and root_win_hub.size.x > 0 and root_win_hub.size.y > 0:
					target_size_hub = Vector2(root_win_hub.size)
				else:
					target_size_hub = Vector2(1280, 720)
			if _hub_panel.has_method("update_responsive_layout"):
				_hub_panel.call("update_responsive_layout", target_size_hub)

	if start_container != null: start_container.visible = (_current_mode == ViewMode.MODE_ENTRY)
	if lesson_panel != null: lesson_panel.visible = (_current_mode == ViewMode.MODE_LESSON)
	if q_host != null:
		q_host.visible = (_current_mode == ViewMode.MODE_QUESTION_HOST)
		var gameplay_hbox: Control = q_host.get_node_or_null("GameplayHBox") as Control
		if gameplay_hbox != null:
			var advisor: Control = gameplay_hbox.get_node_or_null("AdvisorPanel") as Control
			var is_boss: bool = is_boss_stage()
			var q_host_panel: MarginContainer = gameplay_hbox.get_node_or_null("QuestionPanelHost") as MarginContainer
			var left_sidebar: Control = get_node_or_null("VBoxContainer/MainBody/ContentHBox/LeftSidebar") as Control
			var main_body: MarginContainer = get_node_or_null("VBoxContainer/MainBody") as MarginContainer

			if is_boss:
				if _current_mode == ViewMode.MODE_QUESTION_HOST:
					var boss_panel: BossCombatPanel = get_boss_combat_panel()
					if boss_panel != null:
						boss_panel.visible = true
						boss_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					if advisor != null:
						advisor.visible = false
					if left_sidebar != null:
						left_sidebar.visible = false
					if main_body != null:
						main_body.add_theme_constant_override("margin_left", 0)
						main_body.add_theme_constant_override("margin_top", 0)
						main_body.add_theme_constant_override("margin_right", 0)
						main_body.add_theme_constant_override("margin_bottom", 0)
					if q_host != null:
						q_host.add_theme_constant_override("margin_left", 0)
						q_host.add_theme_constant_override("margin_top", 0)
						q_host.add_theme_constant_override("margin_right", 0)
						q_host.add_theme_constant_override("margin_bottom", 0)
					if q_host_panel != null:
						q_host_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
						q_host_panel.custom_minimum_size = Vector2(740, 300)
						q_host_panel.add_theme_constant_override("margin_left", 0)
						q_host_panel.add_theme_constant_override("margin_top", 0)
						q_host_panel.add_theme_constant_override("margin_right", 0)
						q_host_panel.add_theme_constant_override("margin_bottom", 0)
				else:
					var existing_boss: BossCombatPanel = get_existing_boss_combat_panel()
					if existing_boss != null:
						existing_boss.visible = false
					if advisor != null:
						advisor.visible = false
					if left_sidebar != null:
						left_sidebar.visible = true
					if main_body != null:
						main_body.add_theme_constant_override("margin_left", 16)
						main_body.add_theme_constant_override("margin_top", 16)
						main_body.add_theme_constant_override("margin_right", 16)
						main_body.add_theme_constant_override("margin_bottom", 16)
					if q_host != null:
						q_host.remove_theme_constant_override("margin_left")
						q_host.remove_theme_constant_override("margin_top")
						q_host.remove_theme_constant_override("margin_right")
						q_host.remove_theme_constant_override("margin_bottom")
					if q_host_panel != null:
						q_host_panel.remove_theme_constant_override("margin_left")
						q_host_panel.remove_theme_constant_override("margin_top")
						q_host_panel.remove_theme_constant_override("margin_right")
						q_host_panel.remove_theme_constant_override("margin_bottom")
			else:
				var existing_boss: BossCombatPanel = get_existing_boss_combat_panel()
				if existing_boss != null:
					existing_boss.visible = false
					if _context_info != null and not is_boss_stage():
						existing_boss.set_controller(null)
				if advisor != null:
					advisor.visible = (_current_mode == ViewMode.MODE_QUESTION_HOST)
				if left_sidebar != null:
					left_sidebar.visible = true
				if main_body != null:
					main_body.add_theme_constant_override("margin_left", 16)
					main_body.add_theme_constant_override("margin_top", 16)
					main_body.add_theme_constant_override("margin_right", 16)
					main_body.add_theme_constant_override("margin_bottom", 16)
				if q_host != null:
					q_host.remove_theme_constant_override("margin_left")
					q_host.remove_theme_constant_override("margin_top")
					q_host.remove_theme_constant_override("margin_right")
					q_host.remove_theme_constant_override("margin_bottom")
				if q_host_panel != null:
					q_host_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					q_host_panel.custom_minimum_size = Vector2(0, 0)
					q_host_panel.remove_theme_constant_override("margin_left")
					q_host_panel.remove_theme_constant_override("margin_top")
					q_host_panel.remove_theme_constant_override("margin_right")
					q_host_panel.remove_theme_constant_override("margin_bottom")

	if f_host != null: f_host.visible = (_current_mode == ViewMode.MODE_FEEDBACK_HOST)
	if complete_panel != null: complete_panel.visible = (_current_mode == ViewMode.MODE_STAGE_COMPLETE)
	if _victory_panel != null: _victory_panel.visible = (_current_mode == ViewMode.MODE_VICTORY or _current_mode == ViewMode.MODE_DUNGEON_COMPLETE)
	if _stage_map_panel != null:
		_stage_map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stage_map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_stage_map_panel.visible = (_current_mode == ViewMode.MODE_MAP)
		if _current_mode == ViewMode.MODE_MAP:
			if _procedural_fog_container != null:
				_procedural_fog_container.visible = false
			var fog_rect: TextureRect = get_node_or_null("FogOverlayTextureRect") as TextureRect
			if fog_rect != null:
				fog_rect.visible = false
			var target_size: Vector2 = size
			if target_size.x <= 0 or target_size.y <= 0:
				var root_win: Window = get_tree().root if is_inside_tree() else null
				if root_win != null and root_win.size.x > 0 and root_win.size.y > 0:
					target_size = Vector2(root_win.size)
				else:
					target_size = Vector2(1280, 720)
			_stage_map_panel.size = target_size
			if _stage_map_panel.has_method("_update_responsive_layout"):
				_stage_map_panel.call("_update_responsive_layout")

	var main_body: MarginContainer = get_node_or_null("VBoxContainer/MainBody") as MarginContainer
	if main_body != null:
		if _current_mode == ViewMode.MODE_MAP or _current_mode == ViewMode.MODE_STORY or _current_mode == ViewMode.MODE_PROLOGUE or _boss_fullscreen:
			main_body.add_theme_constant_override("margin_left", 0)
			main_body.add_theme_constant_override("margin_right", 0)
			main_body.add_theme_constant_override("margin_top", 0)
			main_body.add_theme_constant_override("margin_bottom", 0)
		else:
			main_body.add_theme_constant_override("margin_left", 16)
			main_body.add_theme_constant_override("margin_right", 16)
			main_body.add_theme_constant_override("margin_top", 16)
			main_body.add_theme_constant_override("margin_bottom", 16)

	if _current_mode == ViewMode.MODE_STORY:
		if _story_panel != null and _context_info != null:
			_story_panel.set_context_info(_context_info)
	elif _current_mode == ViewMode.MODE_LESSON and lesson_panel != null and _context_info != null:
		if lesson_panel.has_method("set_story_mode"):
			lesson_panel.set_story_mode(false)
		lesson_panel.set_lesson_data(_context_info.lesson_steps)

	if _current_mode == ViewMode.MODE_QUESTION_HOST and q_host != null:
		if get_question_panel() == null:
			question_host_ready.emit(q_host)
	elif _current_mode == ViewMode.MODE_FEEDBACK_HOST and f_host != null:
		feedback_host_ready.emit(f_host)

	var sidebar: Control = get_node_or_null("VBoxContainer/MainBody/ContentHBox/LeftSidebar") as Control
	var _is_boss_question: bool = (is_boss_stage() and _current_mode == ViewMode.MODE_QUESTION_HOST)
	if sidebar != null:
		sidebar.visible = (_current_mode != ViewMode.MODE_ENTRY and _current_mode != ViewMode.MODE_MAP and _current_mode != ViewMode.MODE_VICTORY and _current_mode != ViewMode.MODE_DUNGEON_COMPLETE and _current_mode != ViewMode.MODE_STORY and _current_mode != ViewMode.MODE_PROLOGUE and not _is_boss_question)

func show_story_phase() -> void:
	if _context_info != null and not _context_info.story_steps.is_empty():
		set_view_mode(ViewMode.MODE_STORY)
	else:
		show_lesson_phase()

func show_lesson_phase() -> void:
	set_view_mode(ViewMode.MODE_LESSON)

func show_dungeon_1_complete(gold: int = 0, exp_pts: int = 0, fragment_id: String = "Fragment 01") -> void:
	_ensure_sub_components()
	if _victory_panel != null:
		_victory_panel.set_dungeon_complete_data("Khu Rừng Mù Sương", fragment_id, gold, exp_pts)
	set_view_mode(ViewMode.MODE_DUNGEON_COMPLETE)

func set_stage_complete_rewards(coins: int, exp_pts: int, fragment_id: String = "") -> void:
	var complete_panel: StageCompletePanel = get_stage_complete_panel()
	if complete_panel != null:
		complete_panel.set_rewards_data(coins, exp_pts, fragment_id)

func get_view_mode() -> ViewMode:
	return _current_mode

func toggle_pause() -> void:
	if _pause_overlay != null:
		if _pause_overlay.visible:
			_pause_overlay.hide_pause()
			resume_requested.emit()
		else:
			_pause_overlay.show_pause()
			pause_requested.emit()

func _on_new_game_pressed() -> void:
	new_game_requested.emit()

func _on_continue_game_pressed() -> void:
	continue_game_requested.emit()

func _on_journey_map_pressed() -> void:
	show_map_requested.emit()

func _on_lesson_continue() -> void:
	if _current_mode == ViewMode.MODE_STORY:
		story_continue_requested.emit()
	else:
		lesson_continue_requested.emit()

func _on_story_continue() -> void:
	story_continue_requested.emit()

func _on_lesson_completed() -> void:
	if _current_mode == ViewMode.MODE_STORY:
		story_completed.emit()
	else:
		set_view_mode(ViewMode.MODE_QUESTION_HOST)

func _get_header_bar() -> HBoxContainer:
	return get_node_or_null("VBoxContainer/HeaderBar") as HBoxContainer

func _get_start_game_container() -> Control:
	var main_content: Control = _get_main_content_vbox()
	if main_content != null:
		return main_content.get_node_or_null("StartGameContainer") as Control
	return null

func _get_stage_title_label() -> Label:
	var header_bar: HBoxContainer = _get_header_bar()
	if header_bar != null:
		return header_bar.get_node_or_null("StageTitleLabel") as Label
	return null

func _get_restored_badge_label() -> Label:
	var header_bar: HBoxContainer = _get_header_bar()
	if header_bar != null:
		return header_bar.get_node_or_null("RestoredBadgeLabel") as Label
	return null

func show_feedback(data: Variant = null) -> void:
	set_view_mode(ViewMode.MODE_FEEDBACK_HOST)

func _on_question_host_child_entered(node: Node) -> void:
	if node is Control:
		question_host_ready.emit(node as Control)

func _on_stage_continue() -> void:
	stage_continue_requested.emit()

func _on_victory_return_pressed() -> void:
	return_to_main_menu_requested.emit()

func _on_map_stage_selected(stage_id: String) -> void:
	stage_selected.emit(stage_id)

func _on_hub_replay_requested() -> void:
	stage_selected.emit("stage_01_01")

func _on_map_return_pressed() -> void:
	if _previous_mode == ViewMode.MODE_ENTRY:
		set_view_mode(ViewMode.MODE_ENTRY)
	else:
		set_view_mode(_previous_mode)

func _on_pause_resume() -> void:
	resume_requested.emit()

func _on_pause_map() -> void:
	hide_pause()
	set_view_mode(ViewMode.MODE_MAP)
	show_map_requested.emit()

func _on_pause_main_menu() -> void:
	hide_pause()
	set_view_mode(ViewMode.MODE_ENTRY)
	return_to_main_menu_requested.emit()

func _on_pause_logout() -> void:
	hide_pause()
	logout_requested.emit()

func set_guest_mode(guest: bool) -> void:
	if _pause_overlay != null and _pause_overlay.has_method("set_guest_mode"):
		_pause_overlay.set_guest_mode(guest)

func _get_main_content_vbox() -> VBoxContainer:
	return get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox") as VBoxContainer

func get_lesson_panel() -> LessonPanel:
	var main_content: Control = _get_main_content_vbox()
	if main_content != null:
		return main_content.get_node_or_null("LessonPanel") as LessonPanel
	return null

func get_story_panel() -> Control:
	_ensure_sub_components()
	return _story_panel

func get_question_host_container() -> MarginContainer:
	var main_content: Control = _get_main_content_vbox()
	if main_content != null:
		return main_content.get_node_or_null("QuestionHostContainer") as MarginContainer
	return null

func get_question_panel() -> QuestionPanel:
	var q_host: MarginContainer = get_question_host_container()
	if q_host != null:
		var panel: QuestionPanel = q_host.get_node_or_null("GameplayHBox/QuestionPanelHost/QuestionPanel") as QuestionPanel
		if panel == null:
			panel = q_host.get_node_or_null("QuestionPanel") as QuestionPanel
		return panel
	return null

func is_boss_stage() -> bool:
	return _context_info != null and _context_info.encounter_mode == "card_combat" and not _context_info.enemy_id.is_empty()

func get_existing_boss_combat_panel() -> BossCombatPanel:
	var q_host: MarginContainer = get_question_host_container()
	if q_host == null:
		return null
	var gameplay_hbox: Control = q_host.get_node_or_null("GameplayHBox") as Control
	if gameplay_hbox == null:
		return null
	return gameplay_hbox.get_node_or_null("BossCombatPanel") as BossCombatPanel

func get_boss_combat_panel() -> BossCombatPanel:
	var q_host: MarginContainer = get_question_host_container()
	if q_host == null:
		return null
	var gameplay_hbox: Control = q_host.get_node_or_null("GameplayHBox") as Control
	if gameplay_hbox == null:
		return null
	var b_panel: BossCombatPanel = gameplay_hbox.get_node_or_null("BossCombatPanel") as BossCombatPanel
	if b_panel == null:
		var scene_res: Resource = load("res://src/ui/combat/boss_combat_panel.tscn")
		if scene_res is PackedScene:
			b_panel = (scene_res as PackedScene).instantiate() as BossCombatPanel
		else:
			var script_res: Resource = load("res://src/ui/combat/boss_combat_panel.gd")
			if script_res is GDScript:
				b_panel = (script_res as GDScript).new() as BossCombatPanel
		if b_panel != null:
			b_panel.name = "BossCombatPanel"
			b_panel.visible = false
			gameplay_hbox.add_child(b_panel)
	return b_panel

func get_feedback_host_container() -> MarginContainer:
	var main_content: Control = _get_main_content_vbox()
	if main_content != null:
		return main_content.get_node_or_null("FeedbackHostContainer") as MarginContainer
	return null

func get_stage_complete_panel() -> StageCompletePanel:
	var main_content: Control = _get_main_content_vbox()
	if main_content != null:
		return main_content.get_node_or_null("StageCompletePanel") as StageCompletePanel
	return null

func _get_new_game_button() -> Button:
	return get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer/NewGameButton") as Button

func _get_journey_map_button() -> Button:
	if _journey_map_button != null:
		return _journey_map_button
	return get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer/JourneyMapButton") as Button

func show_notification_banner(text: String, is_error: bool = false, duration: float = 3.0) -> void:
	var banner: UiStatusBanner = get_node_or_null("NotificationBanner") as UiStatusBanner
	if banner == null:
		banner = UiStatusBanner.new()
		banner.name = "NotificationBanner"
		add_child(banner)
	banner.show_status(UiStatusBanner.StatusType.ERROR if is_error else UiStatusBanner.StatusType.INFO, "Thông báo", text)
	var margin: MarginContainer = banner.get_node_or_null("MarginContainer") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "MarginContainer"
		banner.add_child(margin)
	var notif_lbl: Label = margin.get_node_or_null("NotificationLabel") as Label
	if notif_lbl == null:
		notif_lbl = Label.new()
		notif_lbl.name = "NotificationLabel"
		margin.add_child(notif_lbl)
	notif_lbl.text = text
	banner.visible = true

func _get_save_summary_label() -> Label:
	if _save_summary_label != null:
		return _save_summary_label
	return get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer/SaveSummaryLabel") as Label

func show_game_victory(gold: int = 0, xp: int = 0) -> void:
	_ensure_sub_components()
	if _victory_panel != null:
		_victory_panel.set_rewards(gold, xp)
	set_view_mode(ViewMode.MODE_VICTORY)

func show_stage_map(data: Dictionary = {}) -> void:
	_ensure_sub_components()
	if _stage_map_panel != null and not data.is_empty():
		_stage_map_panel.set_map_data(data)
	set_view_mode(ViewMode.MODE_MAP)

func get_victory_panel() -> GameVictoryPanel:
	_ensure_sub_components()
	return _victory_panel

func get_stage_map_panel() -> DungeonStageMapPanel:
	_ensure_sub_components()
	return _stage_map_panel

func get_pause_overlay() -> PauseMenuOverlay:
	_ensure_sub_components()
	return _pause_overlay

func get_pause_menu_overlay() -> PauseMenuOverlay:
	_ensure_sub_components()
	return _pause_overlay

func is_paused() -> bool:
	_ensure_sub_components()
	return _pause_overlay != null and _pause_overlay.visible

func show_pause() -> void:
	_ensure_sub_components()
	if _pause_overlay != null:
		if _pause_overlay.has_method("show_pause"):
			_pause_overlay.show_pause()
		elif _pause_overlay.has_method("show_overlay"):
			_pause_overlay.call("show_overlay")

func hide_pause() -> void:
	_ensure_sub_components()
	if _pause_overlay != null:
		if _pause_overlay.has_method("hide_pause"):
			_pause_overlay.hide_pause()
		elif _pause_overlay.has_method("hide_overlay"):
			_pause_overlay.call("hide_overlay")

func _get_continue_game_button() -> Button:
	var btn: Button = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer/ContinueButton") as Button
	if btn == null:
		btn = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer/ContinueGameButton") as Button
	return btn

func set_continue_available(available: bool, summary_data: Dictionary = {}) -> void:
	_ensure_sub_components()
	if _hub_panel != null and _hub_panel.has_method("set_continue_available"):
		_hub_panel.call("set_continue_available", available, summary_data)

	var continue_btn: Button = _get_continue_game_button()
	if continue_btn != null:
		continue_btn.visible = available

	var start_vbox: VBoxContainer = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer") as VBoxContainer
	if start_vbox != null:
		if _save_summary_label == null:
			_save_summary_label = start_vbox.get_node_or_null("SaveSummaryLabel") as Label
			if _save_summary_label == null:
				_save_summary_label = Label.new()
				_save_summary_label.name = "SaveSummaryLabel"
				_save_summary_label.theme_type_variation = &"MathosSubtitle"
				_save_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				start_vbox.add_child(_save_summary_label)

		if available and not summary_data.is_empty():
			var title: String = String(summary_data.get("stage_title", ""))
			var s_id: String = String(summary_data.get("stage_id", ""))
			_save_summary_label.text = "Tiếp tục: %s (%s)" % [title, s_id]
			_save_summary_label.visible = true
		else:
			_save_summary_label.visible = false

func update_hub_state(hub_data: Dictionary) -> void:
	_ensure_sub_components()
	if _hub_panel != null and _hub_panel.has_method("set_hub_data"):
		_hub_panel.call("set_hub_data", hub_data)

func get_hub_panel() -> Control:
	_ensure_sub_components()
	return _hub_panel

func show_prologue_phase() -> void:
	set_view_mode(ViewMode.MODE_PROLOGUE)

func get_prologue_player() -> Control:
	_ensure_sub_components()
	return _prologue_player

func _on_prologue_completed() -> void:
	prologue_completed.emit()

func _on_prologue_skipped() -> void:
	prologue_skipped.emit()
