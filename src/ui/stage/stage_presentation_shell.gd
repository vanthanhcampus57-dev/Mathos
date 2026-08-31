class_name StagePresentationShell
extends Control

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
	MODE_MAP = 6
}

signal new_game_requested()
signal continue_game_requested()
signal show_map_requested()
signal return_to_main_menu_requested()
signal lesson_continue_requested()
signal question_host_ready(container: Control)
signal feedback_host_ready(container: Control)
signal stage_continue_requested()
signal stage_selected(stage_id: String)
signal pause_requested()
signal resume_requested()

var _current_mode: ViewMode = ViewMode.MODE_ENTRY
var _previous_mode: ViewMode = ViewMode.MODE_LESSON
var _context_info: PresentationModels.StageContextInfo = null

# Sub-components
var _victory_panel: GameVictoryPanel = null
var _stage_map_panel: DungeonStageMapPanel = null
var _pause_overlay: PauseMenuOverlay = null

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

const BRAND_LOGO_MAIN_PATH: String = "res://assets/branding/mathos_logo_main.png"
const BRAND_LOGO_EMBLEM_PATH: String = "res://assets/branding/mathos_logo_emblem.png"

const FOG_FPS: float = 2.0
const FOG_COLS: int = 4
const FOG_ROWS: int = 2
const FOG_FRAME_WIDTH: int = 512
const FOG_FRAME_HEIGHT: int = 288

var _fog_source_texture: Texture2D = null
var _fog_frames: Array[AtlasTexture] = []
var _fog_frame_timer: float = 0.0
var _fog_current_frame: int = 0

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
		if not lesson_panel.lesson_completed.is_connected(_on_lesson_completed):
			lesson_panel.lesson_completed.connect(_on_lesson_completed)

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
			main_content.add_child(_victory_panel)
		if not _victory_panel.return_to_main_menu_requested.is_connected(_on_victory_return):
			_victory_panel.return_to_main_menu_requested.connect(_on_victory_return)

	# Stage Map Panel
	if _stage_map_panel == null and main_content != null:
		_stage_map_panel = main_content.get_node_or_null("DungeonStageMapPanel") as DungeonStageMapPanel
		if _stage_map_panel == null:
			_stage_map_panel = DungeonStageMapPanel.new()
			_stage_map_panel.name = "DungeonStageMapPanel"
			main_content.add_child(_stage_map_panel)
		if not _stage_map_panel.stage_selected.is_connected(_on_map_stage_selected):
			_stage_map_panel.stage_selected.connect(_on_map_stage_selected)
		if not _stage_map_panel.back_requested.is_connected(_on_map_back):
			_stage_map_panel.back_requested.connect(_on_map_back)

	# Pause Menu Overlay
	if _pause_overlay == null:
		_pause_overlay = get_node_or_null("PauseMenuOverlay") as PauseMenuOverlay
		if _pause_overlay == null:
			_pause_overlay = PauseMenuOverlay.new()
			_pause_overlay.name = "PauseMenuOverlay"
			add_child(_pause_overlay)
		if not _pause_overlay.resume_requested.is_connected(_on_pause_resume):
			_pause_overlay.resume_requested.connect(_on_pause_resume)
		if not _pause_overlay.stage_map_requested.is_connected(_on_pause_stage_map):
			_pause_overlay.stage_map_requested.connect(_on_pause_stage_map)
		if not _pause_overlay.main_menu_requested.is_connected(_on_pause_main_menu):
			_pause_overlay.main_menu_requested.connect(_on_pause_main_menu)

	# Main Menu Journey Map Button & Save Summary Label
	var start_vbox: VBoxContainer = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer") as VBoxContainer
	if start_vbox != null:
		if _journey_map_button == null:
			_journey_map_button = start_vbox.get_node_or_null("JourneyMapButton") as Button
			if _journey_map_button == null:
				_journey_map_button = Button.new()
				_journey_map_button.name = "JourneyMapButton"
				_journey_map_button.custom_minimum_size = Vector2(280, 48)
				_journey_map_button.size_flags_horizontal = SIZE_SHRINK_CENTER
				_journey_map_button.theme_type_variation = &"MathosSecondaryButton"
				_journey_map_button.text = "Bản đồ hành trình"
				start_vbox.add_child(_journey_map_button)

		if _save_summary_label == null:
			_save_summary_label = start_vbox.get_node_or_null("SaveSummaryLabel") as Label
			if _save_summary_label == null:
				_save_summary_label = Label.new()
				_save_summary_label.name = "SaveSummaryLabel"
				_save_summary_label.theme_type_variation = &"MathosMeta"
				_save_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				_save_summary_label.visible = false
				start_vbox.add_child(_save_summary_label)

	# Pause Button in HeaderBar
	var header_bar: HBoxContainer = _get_header_bar() as HBoxContainer
	if header_bar != null and _pause_button == null:
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

func _process(delta: float) -> void:
	_update_fog_animation(delta)

func _ensure_visual_nodes() -> void:
	var bg_rect: TextureRect = get_node_or_null("BackgroundTextureRect") as TextureRect
	if bg_rect != null:
		bg_rect.mouse_filter = MOUSE_FILTER_IGNORE
		bg_rect.texture_filter = TEXTURE_FILTER_NEAREST

	var fog_rect: TextureRect = get_node_or_null("FogOverlayTextureRect") as TextureRect
	if fog_rect != null:
		fog_rect.mouse_filter = MOUSE_FILTER_IGNORE
		fog_rect.texture_filter = TEXTURE_FILTER_NEAREST

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

	if not _is_dungeon_1_context():
		if fog_rect != null:
			fog_rect.visible = false
		return

	var bg_tex: Texture2D = _load_texture_from_paths([D1_BG_PATH, D1_BG_ALT_PATH, "res://assets/backgrounds/misty_forest_v1.jpg"])
	if bg_rect != null and bg_tex != null:
		bg_rect.texture = bg_tex
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	_init_fog_frames()
	if fog_rect != null and not _fog_frames.is_empty():
		fog_rect.visible = true
		fog_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fog_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fog_rect.texture = _fog_frames[_fog_current_frame]

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
	var fog_rect: TextureRect = get_node_or_null("FogOverlayTextureRect") as TextureRect
	if fog_rect == null or not fog_rect.visible or _fog_frames.is_empty():
		return

	_fog_frame_timer += delta
	var frame_dur: float = 1.0 / FOG_FPS
	if _fog_frame_timer >= frame_dur:
		_fog_frame_timer = fmod(_fog_frame_timer, frame_dur)
		_fog_current_frame = (_fog_current_frame + 1) % _fog_frames.size()
		fog_rect.texture = _fog_frames[_fog_current_frame]

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
		lesson_panel.set_lesson_data(_context_info.lesson_steps)

	var stage_complete_panel: StageCompletePanel = get_stage_complete_panel()
	if stage_complete_panel != null and _context_info != null:
		stage_complete_panel.set_summary_data(_context_info.stage_title)

func set_continue_available(available: bool, summary_data: Dictionary = {}) -> void:
	_ensure_sub_components()
	var continue_btn: Button = _get_continue_game_button()
	if continue_btn != null:
		continue_btn.visible = available
		continue_btn.disabled = not available
		if available:
			continue_btn.text = "Tiếp tục"
			continue_btn.theme_type_variation = &"MathosPrimaryButton"

	var new_game_btn: Button = _get_new_game_button()
	if new_game_btn != null:
		new_game_btn.text = "Bắt đầu mới"
		if available:
			new_game_btn.theme_type_variation = &"MathosSecondaryButton"
		else:
			new_game_btn.theme_type_variation = &"MathosPrimaryButton"

	var summary_lbl: Label = _get_save_summary_label()
	if summary_lbl != null:
		if available and not summary_data.is_empty():
			var title_str: String = String(summary_data.get("stage_title", summary_data.get("stage_id", "")))
			summary_lbl.text = "Tiến độ đã lưu: %s" % title_str
			summary_lbl.visible = true
		else:
			summary_lbl.visible = false
			summary_lbl.text = ""

func show_notification_banner(message: String, is_error: bool = false, duration: float = 4.0) -> void:
	_ensure_sub_components()
	if _notification_banner == null:
		_notification_banner = PanelContainer.new()
		_notification_banner.name = "NotificationBanner"
		_notification_banner.custom_minimum_size = Vector2(420, 44)
		_notification_banner.size_flags_horizontal = SIZE_SHRINK_CENTER

		var margin: MarginContainer = MarginContainer.new()
		margin.name = "MarginContainer"
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		_notification_banner.add_child(margin)

		_notification_label = Label.new()
		_notification_label.name = "NotificationLabel"
		_notification_label.theme_type_variation = &"MathosMeta"
		_notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		margin.add_child(_notification_label)

		add_child(_notification_banner)

	if _notification_banner != null and _notification_label != null:
		if is_error:
			_notification_banner.theme_type_variation = &"MathosPanelElevated"
			_notification_label.text = "⚠️ " + message
			_notification_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		else:
			_notification_banner.theme_type_variation = &"MathosCard"
			_notification_label.text = "ℹ️ " + message
			_notification_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))

		_notification_banner.visible = true
		_notification_banner.modulate.a = 0.0

		if _notification_tween != null and _notification_tween.is_valid():
			_notification_tween.kill()

		_notification_tween = create_tween()
		_notification_tween.tween_property(_notification_banner, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_notification_tween.tween_interval(duration)
		_notification_tween.tween_property(_notification_banner, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_notification_tween.tween_callback(func(): if _notification_banner != null: _notification_banner.visible = false)

func show_game_victory(player_gold: int = 0, player_xp: int = 0) -> void:
	_ensure_sub_components()
	if _victory_panel != null:
		_victory_panel.set_victory_data(player_gold, player_xp)
	set_view_mode(ViewMode.MODE_VICTORY)

func show_stage_map(map_data: Dictionary = {}) -> void:
	_ensure_sub_components()
	if _stage_map_panel != null:
		_stage_map_panel.set_map_data(map_data)
	set_view_mode(ViewMode.MODE_MAP)

func toggle_pause() -> void:
	_ensure_sub_components()
	if _pause_overlay == null:
		return

	# Only allow pausing during active stage gameplay
	var is_gameplay: bool = (_current_mode == ViewMode.MODE_LESSON or _current_mode == ViewMode.MODE_QUESTION_HOST or _current_mode == ViewMode.MODE_FEEDBACK_HOST or _current_mode == ViewMode.MODE_STAGE_COMPLETE)
	if not is_gameplay and not _pause_overlay.is_paused():
		return

	_pause_overlay.toggle_pause()

func show_pause() -> void:
	_ensure_sub_components()
	if _pause_overlay != null:
		_pause_overlay.show_pause()

func hide_pause() -> void:
	_ensure_sub_components()
	if _pause_overlay != null:
		_pause_overlay.hide_pause()

func is_paused() -> bool:
	return _pause_overlay != null and _pause_overlay.is_paused()

func set_view_mode(mode: ViewMode) -> void:
	_ensure_sub_components()

	if _current_mode != ViewMode.MODE_MAP and _current_mode != ViewMode.MODE_VICTORY and _current_mode != ViewMode.MODE_ENTRY:
		_previous_mode = _current_mode

	_current_mode = mode

	var is_gameplay: bool = (_current_mode == ViewMode.MODE_LESSON or _current_mode == ViewMode.MODE_QUESTION_HOST or _current_mode == ViewMode.MODE_FEEDBACK_HOST or _current_mode == ViewMode.MODE_STAGE_COMPLETE)

	var header_bar: Control = _get_header_bar()
	if header_bar != null:
		header_bar.visible = is_gameplay

	var left_sidebar: Control = _get_left_sidebar()
	if left_sidebar != null:
		left_sidebar.visible = is_gameplay

	var start_game_container: Control = _get_start_game_container()
	if start_game_container != null:
		start_game_container.visible = (_current_mode == ViewMode.MODE_ENTRY)

	var active_target: Control = null

	var lesson_panel: LessonPanel = get_lesson_panel()
	if lesson_panel != null:
		lesson_panel.visible = (_current_mode == ViewMode.MODE_LESSON)
		if _current_mode == ViewMode.MODE_LESSON:
			active_target = lesson_panel

	var question_host: MarginContainer = get_question_host_container()
	if question_host != null:
		question_host.visible = (_current_mode == ViewMode.MODE_QUESTION_HOST)
		if _current_mode == ViewMode.MODE_QUESTION_HOST:
			active_target = question_host
			question_host_ready.emit(question_host)

	var feedback_host_container: MarginContainer = get_feedback_host_container()
	if feedback_host_container != null:
		feedback_host_container.visible = (_current_mode == ViewMode.MODE_FEEDBACK_HOST)
		if _current_mode == ViewMode.MODE_FEEDBACK_HOST:
			active_target = feedback_host_container
			feedback_host_ready.emit(feedback_host_container)

	var stage_complete_panel: StageCompletePanel = get_stage_complete_panel()
	if stage_complete_panel != null:
		stage_complete_panel.visible = (_current_mode == ViewMode.MODE_STAGE_COMPLETE)
		if _current_mode == ViewMode.MODE_STAGE_COMPLETE:
			active_target = stage_complete_panel

	if _victory_panel != null:
		_victory_panel.visible = (_current_mode == ViewMode.MODE_VICTORY)
		if _current_mode == ViewMode.MODE_VICTORY:
			active_target = _victory_panel

	if _stage_map_panel != null:
		_stage_map_panel.visible = (_current_mode == ViewMode.MODE_MAP)
		if _current_mode == ViewMode.MODE_MAP:
			active_target = _stage_map_panel

	# Game Polish: smooth mode transition tween
	if active_target != null and is_inside_tree():
		active_target.modulate.a = 0.0
		var t: Tween = create_tween()
		if t != null:
			t.tween_property(active_target, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func get_view_mode() -> ViewMode:
	return _current_mode

func get_victory_panel() -> GameVictoryPanel:
	_ensure_sub_components()
	return _victory_panel

func get_stage_map_panel() -> DungeonStageMapPanel:
	_ensure_sub_components()
	return _stage_map_panel

func get_pause_menu_overlay() -> PauseMenuOverlay:
	_ensure_sub_components()
	return _pause_overlay

func get_question_host_container() -> MarginContainer:
	var node = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer")
	if node != null:
		return node as MarginContainer
	return null

func get_question_panel() -> QuestionPanel:
	var host: Control = get_question_host_container()
	if host != null:
		var panel: Control = host.get_node_or_null("GameplayHBox/QuestionPanelHost/QuestionPanel") as Control
		if panel != null:
			return panel as QuestionPanel
		panel = host.get_node_or_null("QuestionPanel") as Control
		if panel != null:
			return panel as QuestionPanel
	return null

func get_feedback_host_container() -> MarginContainer:
	var node = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/FeedbackHostContainer")
	if node != null:
		return node as MarginContainer
	return null

func get_lesson_panel() -> LessonPanel:
	var node = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/LessonPanel")
	if node != null:
		return node as LessonPanel
	return null

func get_stage_complete_panel() -> StageCompletePanel:
	var node = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StageCompletePanel")
	if node != null:
		return node as StageCompletePanel
	return null

func _get_start_game_container() -> Control:
	return get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer") as Control

func _get_new_game_button() -> Button:
	return get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer/NewGameButton") as Button

func _get_continue_game_button() -> Button:
	return get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer/ContinueButton") as Button

func _get_journey_map_button() -> Button:
	_ensure_sub_components()
	return _journey_map_button

func _get_save_summary_label() -> Label:
	_ensure_sub_components()
	return _save_summary_label

func _get_header_bar() -> Control:
	return get_node_or_null("VBoxContainer/HeaderBar") as Control

func _get_left_sidebar() -> Control:
	return get_node_or_null("VBoxContainer/MainBody/ContentHBox/LeftSidebar") as Control

func _get_main_content_vbox() -> Control:
	return get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox") as Control

func _update_header() -> void:
	if _context_info == null:
		return

	var d_label: Label = get_node_or_null("VBoxContainer/HeaderBar/DungeonTitleLabel") as Label
	if d_label != null:
		d_label.text = _context_info.dungeon_title

	var s_label: Label = get_node_or_null("VBoxContainer/HeaderBar/StageTitleLabel") as Label
	if s_label != null:
		s_label.text = _context_info.stage_title

	var r_label: Label = get_node_or_null("VBoxContainer/HeaderBar/RestoredBadgeLabel") as Label
	if r_label != null:
		r_label.visible = _context_info.is_restored_context

func _on_new_game_pressed() -> void:
	new_game_requested.emit()

func _on_continue_game_pressed() -> void:
	continue_game_requested.emit()

func _on_journey_map_pressed() -> void:
	show_map_requested.emit()

func show_feedback(data: Variant = null) -> void:
	set_view_mode(ViewMode.MODE_FEEDBACK_HOST)

func is_restored_context_displayed() -> bool:
	return _context_info != null and _context_info.is_restored_context

func _get_restored_badge_label() -> Label:
	return get_node_or_null("VBoxContainer/HeaderBar/RestoredBadgeLabel") as Label

func _get_stage_title_label() -> Label:
	return get_node_or_null("VBoxContainer/HeaderBar/StageTitleLabel") as Label

func _get_dungeon_title_label() -> Label:
	return get_node_or_null("VBoxContainer/HeaderBar/DungeonTitleLabel") as Label

func _on_lesson_continue() -> void:
	lesson_continue_requested.emit()

func _on_lesson_completed() -> void:
	lesson_continue_requested.emit()
	set_view_mode(ViewMode.MODE_QUESTION_HOST)

func _on_stage_continue() -> void:
	stage_continue_requested.emit()

func _on_question_host_child_entered(node: Node) -> void:
	pass

func _on_map_stage_selected(stage_id: String) -> void:
	stage_selected.emit(stage_id)

func _on_map_back() -> void:
	return_to_main_menu_requested.emit()

func _on_victory_return() -> void:
	return_to_main_menu_requested.emit()

func _on_pause_resume() -> void:
	hide_pause()
	resume_requested.emit()

func _on_pause_stage_map() -> void:
	hide_pause()
	show_map_requested.emit()

func _on_pause_main_menu() -> void:
	hide_pause()
	return_to_main_menu_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		var is_gameplay: bool = (_current_mode == ViewMode.MODE_LESSON or _current_mode == ViewMode.MODE_QUESTION_HOST or _current_mode == ViewMode.MODE_FEEDBACK_HOST or _current_mode == ViewMode.MODE_STAGE_COMPLETE)
		if is_gameplay or (_pause_overlay != null and _pause_overlay.is_paused()):
			toggle_pause()
			get_viewport().set_input_as_handled()
