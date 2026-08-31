class_name LessonPanel
extends Control

## UI component for displaying lesson dialogue text, speaker label, page indicator,
## and handling Continue/Next pagination interactions.

signal continue_requested()
signal step_changed(step_index: int, total_steps: int)
signal lesson_completed()

var _steps: Array[PresentationModels.LessonStepData] = []
var _current_index: int = 0

func _ready() -> void:
	var btn: Button = _get_continue_button()
	if btn != null:
		if not btn.pressed.is_connected(_on_continue_pressed):
			btn.pressed.connect(_on_continue_pressed)
	_update_display()

static func get_player_facing_speaker_name(raw_speaker: String, display_name: String = "") -> String:
	if not display_name.is_empty() and not display_name.begins_with("npc_"):
		return display_name
	if raw_speaker.is_empty() or raw_speaker.begins_with("npc_"):
		return "CỐ VẤN"
	return raw_speaker

func set_lesson_data(steps: Array) -> void:
	_steps.clear()
	for s in steps:
		if s is PresentationModels.LessonStepData:
			_steps.append(s as PresentationModels.LessonStepData)
		elif s is Dictionary:
			_steps.append(PresentationModels.LessonStepData.from_dict(s as Dictionary))
	_current_index = 0
	_update_display()

func show_step(index: int) -> void:
	if index >= 0 and index < _steps.size():
		_current_index = index
		_update_display()

func next_step() -> bool:
	if _current_index + 1 < _steps.size():
		_current_index += 1
		_update_display()
		return true
	else:
		lesson_completed.emit()
		return false

func get_current_step_index() -> int:
	return _current_index

func get_total_steps() -> int:
	return _steps.size()

func is_on_last_step() -> bool:
	return _current_index >= _steps.size() - 1

func _update_display() -> void:
	var speaker_label: Label = _get_speaker_label()
	var body_label: RichTextLabel = _get_body_label()
	var context_title_label: Label = _get_context_title_label()
	var page_indicator_label: Label = _get_page_indicator_label()
	var continue_button: Button = _get_continue_button()

	if _steps.is_empty():
		if speaker_label != null: speaker_label.text = "CỐ VẤN"
		if body_label != null: body_label.text = ""
		if context_title_label != null: context_title_label.text = ""
		if page_indicator_label != null: page_indicator_label.text = "Bước 0 / 0"
		if continue_button != null:
			continue_button.focus_mode = FOCUS_ALL
			continue_button.text = "Bắt đầu giải đố"
			continue_button.disabled = true
		return

	var step: PresentationModels.LessonStepData = _steps[_current_index]

	if speaker_label != null:
		var raw_speaker: String = step.speaker_label
		speaker_label.text = get_player_facing_speaker_name(raw_speaker)
		speaker_label.visible = true

	if body_label != null:
		body_label.text = step.body_text

	if context_title_label != null:
		context_title_label.text = step.context_title
		context_title_label.visible = not step.context_title.is_empty()

	if page_indicator_label != null:
		page_indicator_label.text = "Bước %d / %d" % [_current_index + 1, _steps.size()]

	if continue_button != null:
		continue_button.focus_mode = FOCUS_ALL
		continue_button.disabled = false
		if _current_index == _steps.size() - 1:
			continue_button.text = "Bắt đầu giải đố"
		else:
			continue_button.text = "Tiếp tục"

	if is_inside_tree():
		var body_panel: Node = get_node_or_null("MarginContainer/VBoxContainer/BodyPanel")
		if body_panel is Control:
			var c: Control = body_panel as Control
			c.modulate.a = 0.0
			var t: Tween = create_tween()
			if t != null:
				t.tween_property(c, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_continue_pressed() -> void:
	if not next_step():
		continue_requested.emit()

func _get_speaker_label() -> Label:
	var node = get_node_or_null("MarginContainer/VBoxContainer/HeaderHBox/SpeakerLabel")
	if node == null:
		node = get_node_or_null("MarginContainer/VBoxContainer/HeaderContainer/SpeakerLabel")
	return node as Label

func _get_body_label() -> RichTextLabel:
	var node = get_node_or_null("MarginContainer/VBoxContainer/BodyPanel/MarginContainer/BodyLabel")
	if node == null:
		node = get_node_or_null("MarginContainer/VBoxContainer/BodyPanel/BodyMargin/BodyTextLabel")
	if node == null:
		node = get_node_or_null("MarginContainer/VBoxContainer/BodyPanel/MarginContainer/BodyTextLabel")
	return node as RichTextLabel

func _get_context_title_label() -> Label:
	var node = get_node_or_null("MarginContainer/VBoxContainer/HeaderHBox/ContextTitleLabel")
	if node == null:
		node = get_node_or_null("MarginContainer/VBoxContainer/HeaderContainer/ContextTitleLabel")
	return node as Label

func _get_page_indicator_label() -> Label:
	var node = get_node_or_null("MarginContainer/VBoxContainer/FooterHBox/PageIndicatorLabel")
	if node == null:
		node = get_node_or_null("MarginContainer/VBoxContainer/FooterContainer/PageIndicatorLabel")
	return node as Label

func _get_continue_button() -> Button:
	var node = get_node_or_null("MarginContainer/VBoxContainer/FooterHBox/ContinueButton")
	if node == null:
		node = get_node_or_null("MarginContainer/VBoxContainer/FooterContainer/ContinueButton")
	return node as Button
