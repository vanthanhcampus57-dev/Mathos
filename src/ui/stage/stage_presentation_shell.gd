class_name StagePresentationShell
extends Control

## Main UI Presentation Shell for Mathos stages (e.g. Stage 1.1 -> 1.3).
## Hosts lesson dialogue, question host container, feedback host container,
## left icon sidebar, separate advisor panel, and stage completion panels.
##
## Pure view component. Emits presentation intents only without touching
## GameFlow, ProgressState, SaveService, or Combat engines.

enum ViewMode {
	MODE_ENTRY = 0,
	MODE_LESSON = 1,
	MODE_QUESTION_HOST = 2,
	MODE_FEEDBACK_HOST = 3,
	MODE_STAGE_COMPLETE = 4
}

signal new_game_requested()
signal continue_game_requested()
signal lesson_continue_requested()
signal question_host_ready(container: Control)
signal feedback_host_ready(container: Control)
signal stage_continue_requested()

var _current_mode: ViewMode = ViewMode.MODE_ENTRY
var _context_info: PresentationModels.StageContextInfo = null

func _ready() -> void:
	_update_background_texture()

	var new_game_btn: Button = _get_new_game_button()
	if new_game_btn != null:
		if not new_game_btn.pressed.is_connected(_on_new_game_pressed):
			new_game_btn.pressed.connect(_on_new_game_pressed)

	var continue_game_btn: Button = _get_continue_game_button()
	if continue_game_btn != null:
		if not continue_game_btn.pressed.is_connected(_on_continue_game_pressed):
			continue_game_btn.pressed.connect(_on_continue_game_pressed)

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

	set_view_mode(_current_mode)

func _update_background_texture() -> void:
	var bg_rect: TextureRect = get_node_or_null("BackgroundTextureRect") as TextureRect
	if bg_rect == null:
		return

	var path: String = "res://assets/backgrounds/misty_forest_v1.jpg"
	var tex: Texture2D = null

	if FileAccess.file_exists(path):
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		if not bytes.is_empty():
			var img: Image = Image.new()
			var err: int = img.load_png_from_buffer(bytes)
			if err != OK:
				err = img.load_jpg_from_buffer(bytes)
			if err == OK:
				tex = ImageTexture.create_from_image(img)

	if tex == null and ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			tex = res as Texture2D

	if tex != null:
		bg_rect.texture = tex
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

## Consumes caller-supplied neutral presentation data.
func set_stage_context(data: Variant) -> void:
	if data is PresentationModels.StageContextInfo:
		_context_info = data as PresentationModels.StageContextInfo
	elif data is Dictionary:
		_context_info = PresentationModels.StageContextInfo.from_dict(data as Dictionary)
	else:
		_context_info = PresentationModels.StageContextInfo.new()

	_update_header()

	var lesson_panel: LessonPanel = get_lesson_panel()
	if lesson_panel != null and _context_info != null:
		lesson_panel.set_lesson_data(_context_info.lesson_steps)

	var stage_complete_panel: StageCompletePanel = get_stage_complete_panel()
	if stage_complete_panel != null and _context_info != null:
		stage_complete_panel.set_summary_data(_context_info.stage_title)

func set_view_mode(mode: ViewMode) -> void:
	_current_mode = mode

	var header_bar: Control = _get_header_bar()
	if header_bar != null:
		header_bar.visible = (_current_mode != ViewMode.MODE_ENTRY)

	var left_sidebar: Control = _get_left_sidebar()
	if left_sidebar != null:
		left_sidebar.visible = (_current_mode != ViewMode.MODE_ENTRY)

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

	if active_target != null and is_inside_tree():
		active_target.modulate.a = 0.0
		var t: Tween = create_tween()
		if t != null:
			t.tween_property(active_target, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func get_view_mode() -> ViewMode:
	return _current_mode

func get_question_host_container() -> MarginContainer:
	var node = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer")
	if node == null:
		node = get_node_or_null("VBoxContainer/MainBody/QuestionHostContainer")
	return node as MarginContainer

func get_feedback_host_container() -> MarginContainer:
	var node = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/FeedbackHostContainer")
	if node == null:
		node = get_node_or_null("VBoxContainer/MainBody/FeedbackHostContainer")
	return node as MarginContainer

func get_lesson_panel() -> LessonPanel:
	var node = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/LessonPanel")
	if node == null:
		node = get_node_or_null("VBoxContainer/MainBody/LessonPanel")
	return node as LessonPanel

func get_stage_complete_panel() -> StageCompletePanel:
	var node = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StageCompletePanel")
	if node == null:
		node = get_node_or_null("VBoxContainer/MainBody/StageCompletePanel")
	return node as StageCompletePanel

func show_feedback(data: Variant) -> void:
	var info: PresentationModels.FeedbackInfo = null
	if data is PresentationModels.FeedbackInfo:
		info = data as PresentationModels.FeedbackInfo
	elif data is Dictionary:
		info = PresentationModels.FeedbackInfo.from_dict(data as Dictionary)

	var feedback_label: Label = _get_feedback_label()
	if info != null and feedback_label != null:
		feedback_label.text = "[%s] %s\n%s" % [
			"CORRECT" if info.is_correct else "INCORRECT",
			info.title if not info.title.is_empty() else info.message,
			info.detail_text
		]

	set_view_mode(ViewMode.MODE_FEEDBACK_HOST)

func is_restored_context_displayed() -> bool:
	return _context_info != null and _context_info.is_restored_context

func _update_header() -> void:
	var stage_title_label: Label = _get_stage_title_label()
	if stage_title_label != null:
		stage_title_label.text = _context_info.stage_title if _context_info != null else ""

	var dungeon_title_label: Label = _get_dungeon_title_label()
	if dungeon_title_label != null:
		dungeon_title_label.text = _context_info.dungeon_title if _context_info != null else ""

	var restored_badge_label: Label = _get_restored_badge_label()
	if restored_badge_label != null:
		var is_restored: bool = _context_info != null and _context_info.is_restored_context
		restored_badge_label.visible = is_restored
		restored_badge_label.text = "[RESTORED STATE]" if is_restored else ""

func set_continue_available(available: bool) -> void:
	var continue_btn: Button = _get_continue_game_button()
	if continue_btn != null:
		continue_btn.visible = available

func _on_new_game_pressed() -> void:
	new_game_requested.emit()

func _on_continue_game_pressed() -> void:
	continue_game_requested.emit()

func _on_lesson_continue() -> void:
	lesson_continue_requested.emit()

func _on_lesson_completed() -> void:
	set_view_mode(ViewMode.MODE_QUESTION_HOST)

func _on_stage_continue() -> void:
	stage_continue_requested.emit()

func _on_question_host_child_entered(child: Node) -> void:
	var panel_host: MarginContainer = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer/GameplayHBox/QuestionPanelHost") as MarginContainer
	if panel_host != null and child != get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer/GameplayHBox"):
		call_deferred("_reparent_question_panel", child, panel_host)

func _reparent_question_panel(child: Node, panel_host: MarginContainer) -> void:
	if is_instance_valid(child) and child.get_parent() != panel_host:
		child.get_parent().remove_child(child)
		panel_host.add_child(child)

func _get_header_bar() -> Control:
	return get_node_or_null("VBoxContainer/HeaderBar") as Control

func _get_left_sidebar() -> Control:
	return get_node_or_null("VBoxContainer/MainBody/ContentHBox/LeftSidebar") as Control

func _get_stage_title_label() -> Label:
	return get_node_or_null("VBoxContainer/HeaderBar/StageTitleLabel") as Label

func _get_dungeon_title_label() -> Label:
	return get_node_or_null("VBoxContainer/HeaderBar/DungeonTitleLabel") as Label

func _get_restored_badge_label() -> Label:
	return get_node_or_null("VBoxContainer/HeaderBar/RestoredBadgeLabel") as Label

func _get_start_game_container() -> Control:
	var node = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer")
	if node == null:
		node = get_node_or_null("VBoxContainer/MainBody/StartGameContainer")
	return node as Control

func _get_new_game_button() -> Button:
	var btn: Button = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer/NewGameButton") as Button
	if btn == null:
		btn = get_node_or_null("VBoxContainer/MainBody/StartGameContainer/VBoxContainer/NewGameButton") as Button
	if btn == null:
		btn = get_node_or_null("VBoxContainer/MainBody/StartGameContainer/NewGameButton") as Button
	return btn

func _get_continue_game_button() -> Button:
	var btn: Button = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/StartGameContainer/VBoxContainer/ContinueButton") as Button
	if btn == null:
		btn = get_node_or_null("VBoxContainer/MainBody/StartGameContainer/VBoxContainer/ContinueButton") as Button
	if btn == null:
		btn = get_node_or_null("VBoxContainer/MainBody/StartGameContainer/ContinueButton") as Button
	return btn

func _get_feedback_label() -> Label:
	var lbl = get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/FeedbackHostContainer/FeedbackPanel/FeedbackLabel")
	if lbl == null:
		lbl = get_node_or_null("VBoxContainer/MainBody/FeedbackHostContainer/FeedbackPanel/FeedbackLabel")
	return lbl as Label
