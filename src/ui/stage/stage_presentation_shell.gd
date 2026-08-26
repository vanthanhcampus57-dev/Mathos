class_name StagePresentationShell
extends Control

## Main UI Presentation Shell for Mathos stages (e.g. Stage 1.1 -> 1.3).
## Hosts lesson dialogue, question host container, feedback host container,
## and stage completion panels.
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

	set_view_mode(_current_mode)

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

	var start_game_container: Control = _get_start_game_container()
	if start_game_container != null:
		start_game_container.visible = (_current_mode == ViewMode.MODE_ENTRY)

	var lesson_panel: LessonPanel = get_lesson_panel()
	if lesson_panel != null:
		lesson_panel.visible = (_current_mode == ViewMode.MODE_LESSON)

	var question_host_container: MarginContainer = get_question_host_container()
	if question_host_container != null:
		question_host_container.visible = (_current_mode == ViewMode.MODE_QUESTION_HOST)
		if _current_mode == ViewMode.MODE_QUESTION_HOST:
			question_host_ready.emit(question_host_container)

	var feedback_host_container: MarginContainer = get_feedback_host_container()
	if feedback_host_container != null:
		feedback_host_container.visible = (_current_mode == ViewMode.MODE_FEEDBACK_HOST)
		if _current_mode == ViewMode.MODE_FEEDBACK_HOST:
			feedback_host_ready.emit(feedback_host_container)

	var stage_complete_panel: StageCompletePanel = get_stage_complete_panel()
	if stage_complete_panel != null:
		stage_complete_panel.visible = (_current_mode == ViewMode.MODE_STAGE_COMPLETE)

func get_view_mode() -> ViewMode:
	return _current_mode

func get_question_host_container() -> MarginContainer:
	return get_node_or_null("VBoxContainer/MainBody/QuestionHostContainer") as MarginContainer

func get_feedback_host_container() -> MarginContainer:
	return get_node_or_null("VBoxContainer/MainBody/FeedbackHostContainer") as MarginContainer

func get_lesson_panel() -> LessonPanel:
	return get_node_or_null("VBoxContainer/MainBody/LessonPanel") as LessonPanel

func get_stage_complete_panel() -> StageCompletePanel:
	return get_node_or_null("VBoxContainer/MainBody/StageCompletePanel") as StageCompletePanel

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
	# Advance sequence to Question Host area (PRES-009)
	set_view_mode(ViewMode.MODE_QUESTION_HOST)

func _on_stage_continue() -> void:
	stage_continue_requested.emit()

func _get_header_bar() -> Control:
	return get_node_or_null("VBoxContainer/HeaderBar") as Control

func _get_stage_title_label() -> Label:
	return get_node_or_null("VBoxContainer/HeaderBar/StageTitleLabel") as Label

func _get_dungeon_title_label() -> Label:
	return get_node_or_null("VBoxContainer/HeaderBar/DungeonTitleLabel") as Label

func _get_restored_badge_label() -> Label:
	return get_node_or_null("VBoxContainer/HeaderBar/RestoredBadgeLabel") as Label

func _get_start_game_container() -> Control:
	return get_node_or_null("VBoxContainer/MainBody/StartGameContainer") as Control

func _get_new_game_button() -> Button:
	var btn: Button = get_node_or_null("VBoxContainer/MainBody/StartGameContainer/NewGameButton") as Button
	if btn == null:
		btn = get_node_or_null("VBoxContainer/MainBody/StartGameContainer/VBoxContainer/NewGameButton") as Button
	return btn

func _get_continue_game_button() -> Button:
	var btn: Button = get_node_or_null("VBoxContainer/MainBody/StartGameContainer/ContinueButton") as Button
	if btn == null:
		btn = get_node_or_null("VBoxContainer/MainBody/StartGameContainer/VBoxContainer/ContinueButton") as Button
	return btn

func _get_feedback_label() -> Label:
	return get_node_or_null("VBoxContainer/MainBody/FeedbackHostContainer/FeedbackPanel/FeedbackLabel") as Label
