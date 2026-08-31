class_name QuestionPanel
extends PanelContainer

## Presentation UI container for rendering a presentation-safe QuestionDefinition,
## capturing interaction input, and displaying AttemptResult feedback.

signal submit_requested(interaction_payload: Dictionary)
signal retry_requested()
signal continue_requested()

var _question_view: Dictionary = {}
var _active_interaction_view: Control = null
var _prompt_text: String = ""
var _objective_text: String = ""
var _feedback_text: String = ""
var _is_correct: bool = false
var _has_feedback: bool = false
var _is_submitting: bool = false
var _panel_tween: Tween = null

# UI Control nodes
var _main_vbox: VBoxContainer = null
var _objective_label: Label = null
var _prompt_label: Label = null
var _interaction_container: MarginContainer = null
var _feedback_label: Label = null
var _action_hbox: HBoxContainer = null
var _hint_button: Button = null
var _submit_button: Button = null

func _ready() -> void:
	_ensure_ui_built()

func _ensure_ui_built() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(400, 300)

	if theme == null:
		theme = load("res://src/ui/theme/mathos_theme.tres")
	theme_type_variation = &"MathosCard"

	if _main_vbox == null:
		_main_vbox = get_node_or_null("MainVBox") as VBoxContainer
	if _objective_label == null:
		_objective_label = get_node_or_null("MainVBox/ObjectiveLabel") as Label
	if _prompt_label == null:
		_prompt_label = get_node_or_null("MainVBox/PromptLabel") as Label
	if _interaction_container == null:
		_interaction_container = get_node_or_null("MainVBox/InteractionContainer") as MarginContainer
	if _feedback_label == null:
		_feedback_label = get_node_or_null("MainVBox/FeedbackLabel") as Label
	if _action_hbox == null:
		_action_hbox = get_node_or_null("MainVBox/ActionHBox") as HBoxContainer
	if _hint_button == null:
		_hint_button = get_node_or_null("MainVBox/ActionHBox/HintButton") as Button
	if _submit_button == null:
		_submit_button = get_node_or_null("MainVBox/SubmitButton") as Button

	# Fallback programmatic node creation if instantiated programmatically without .tscn scene hierarchy
	if _main_vbox == null:
		_main_vbox = VBoxContainer.new()
		_main_vbox.name = "MainVBox"
		_main_vbox.set_anchors_preset(PRESET_FULL_RECT)
		_main_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		_main_vbox.size_flags_vertical = SIZE_EXPAND_FILL
		_main_vbox.add_theme_constant_override("separation", 12)
		add_child(_main_vbox)

	if _objective_label == null:
		_objective_label = Label.new()
		_objective_label.name = "ObjectiveLabel"
		_objective_label.theme_type_variation = &"MathosMeta"
		_objective_label.visible = false
		_main_vbox.add_child(_objective_label)

	if _prompt_label == null:
		_prompt_label = Label.new()
		_prompt_label.name = "PromptLabel"
		_prompt_label.theme_type_variation = &"MathosHeading"
		_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_prompt_label.custom_minimum_size = Vector2(0, 44)
		_prompt_label.size_flags_horizontal = SIZE_EXPAND_FILL
		_main_vbox.add_child(_prompt_label)

	if _interaction_container == null:
		_interaction_container = MarginContainer.new()
		_interaction_container.name = "InteractionContainer"
		_interaction_container.size_flags_horizontal = SIZE_EXPAND_FILL
		_interaction_container.size_flags_vertical = SIZE_EXPAND_FILL
		_main_vbox.add_child(_interaction_container)

	if _feedback_label == null:
		_feedback_label = Label.new()
		_feedback_label.name = "FeedbackLabel"
		_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_feedback_label.visible = false
		_main_vbox.add_child(_feedback_label)

	if _action_hbox == null:
		_action_hbox = HBoxContainer.new()
		_action_hbox.name = "ActionHBox"
		_action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		_action_hbox.add_theme_constant_override("separation", 16)

		_hint_button = Button.new()
		_hint_button.name = "HintButton"
		_hint_button.theme_type_variation = &"MathosSecondaryButton"
		_hint_button.text = "Gợi ý"
		_hint_button.custom_minimum_size = Vector2(140, 44)
		_action_hbox.add_child(_hint_button)
		_main_vbox.add_child(_action_hbox)

	if _submit_button == null:
		_submit_button = Button.new()
		_submit_button.name = "SubmitButton"
		_submit_button.theme_type_variation = &"MathosPrimaryButton"
		_submit_button.text = "Xác nhận"
		_submit_button.custom_minimum_size = Vector2(160, 44)
		_submit_button.size_flags_horizontal = SIZE_SHRINK_CENTER
		_main_vbox.add_child(_submit_button)

	# Ensure theme variations and layout properties on existing scene nodes
	if _objective_label != null:
		_objective_label.theme_type_variation = &"MathosMeta"
	if _prompt_label != null:
		_prompt_label.theme_type_variation = &"MathosHeading"
		_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_prompt_label.custom_minimum_size = Vector2(0, 44)
	if _feedback_label != null:
		_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _submit_button != null:
		_submit_button.theme_type_variation = &"MathosPrimaryButton"

	if _submit_button != null and not _submit_button.pressed.is_connected(_on_submit_button_pressed):
		_submit_button.pressed.connect(_on_submit_button_pressed)
	if _hint_button != null and not _hint_button.pressed.is_connected(_on_hint_button_pressed):
		_hint_button.pressed.connect(_on_hint_button_pressed)

	_update_labels()

	if _active_interaction_view != null and _interaction_container != null:
		if _active_interaction_view.get_parent() != _interaction_container:
			if _active_interaction_view.get_parent() != null:
				_active_interaction_view.get_parent().remove_child(_active_interaction_view)
			_interaction_container.add_child(_active_interaction_view)

func setup_question(question_view: Dictionary) -> bool:
	_question_view = {}
	if _active_interaction_view != null:
		if _active_interaction_view.get_parent() != null:
			_active_interaction_view.get_parent().remove_child(_active_interaction_view)
		if _active_interaction_view.is_inside_tree():
			_active_interaction_view.queue_free()
		else:
			_active_interaction_view.free()
		_active_interaction_view = null

	_prompt_text = ""
	_objective_text = ""
	_feedback_text = ""
	_is_correct = false
	_has_feedback = false
	_is_submitting = false

	if not (question_view is Dictionary) or question_view.is_empty():
		return false

	# Must contain required presentation fields
	for field in ["question_id", "interaction_type", "prompt", "interaction_payload"]:
		if not question_view.has(field):
			return false

	var interaction_type: String = String(question_view["interaction_type"])
	if not ["multiple_choice", "drag_drop", "matching", "input"].has(interaction_type):
		return false

	var payload: Variant = question_view["interaction_payload"]
	if not (payload is Dictionary):
		return false

	# Never require or expose answer_spec from presentation view
	if question_view.has("answer_spec"):
		return false

	_question_view = question_view.duplicate(true)
	_prompt_text = sanitize_presentation_text(String(question_view["prompt"]))
	_objective_text = sanitize_presentation_text(String(question_view.get("learning_objective", "")))

	# Create interaction view child according to interaction_type
	match interaction_type:
		"multiple_choice":
			var mc_view: MultipleChoiceView = MultipleChoiceView.new()
			if not mc_view.setup(payload as Dictionary):
				return false
			_active_interaction_view = mc_view
		"input":
			var inp_view: InputView = InputView.new()
			if not inp_view.setup(payload as Dictionary):
				return false
			_active_interaction_view = inp_view
		"drag_drop":
			var dd_view: DragDropView = DragDropView.new()
			if not dd_view.setup(payload as Dictionary):
				return false
			_active_interaction_view = dd_view
		"matching":
			var mat_view: MatchingView = MatchingView.new()
			if not mat_view.setup(payload as Dictionary):
				return false
			_active_interaction_view = mat_view

	_ensure_ui_built()

	if _submit_button != null:
		_submit_button.text = "Xác nhận"

	if _active_interaction_view != null:
		if _active_interaction_view.get_parent() != null:
			_active_interaction_view.get_parent().remove_child(_active_interaction_view)
		if _interaction_container != null:
			_interaction_container.add_child(_active_interaction_view)
		else:
			add_child(_active_interaction_view)

	if is_inside_tree():
		modulate.a = 0.0
		if _panel_tween != null and _panel_tween.is_running():
			_panel_tween.kill()
		_panel_tween = create_tween()
		if _panel_tween != null:
			_panel_tween.tween_property(self, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	return true

func get_current_interaction_payload() -> Dictionary:
	if _active_interaction_view == null:
		return {}
	if _active_interaction_view.has_method("get_interaction_payload"):
		return _active_interaction_view.call("get_interaction_payload") as Dictionary
	return {}

func request_submit() -> void:
	var payload: Dictionary = get_current_interaction_payload()
	submit_requested.emit(payload)

func show_feedback(attempt_result: Dictionary) -> bool:
	if not (attempt_result is Dictionary) or not attempt_result.has("is_correct") or not attempt_result.has("feedback_text"):
		return false
	_is_correct = bool(attempt_result["is_correct"])
	_feedback_text = String(attempt_result["feedback_text"])
	_has_feedback = true
	_is_submitting = false

	_ensure_ui_built()
	if _feedback_label != null:
		_feedback_label.theme_type_variation = &"MathosSuccess" if _is_correct else &"MathosError"
		var header_str: String = "Chính xác!" if _is_correct else "Chưa chính xác"
		var explanation_str: String = String(attempt_result.get("explanation", ""))
		_feedback_label.text = "[%s] %s\n%s" % [header_str, _feedback_text, explanation_str]
		_feedback_label.modulate.a = 0.0
		_feedback_label.visible = true
		var fb_tween: Tween = create_tween()
		if fb_tween != null:
			fb_tween.tween_property(_feedback_label, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if _submit_button != null:
		_submit_button.text = "TIẾP TỤC" if _is_correct else "THỬ LẠI"

	if _active_interaction_view != null and _active_interaction_view.has_method("show_feedback"):
		_active_interaction_view.call("show_feedback", attempt_result)

	return true

static func sanitize_presentation_text(text: String) -> String:
	if text.is_empty():
		return ""
	var regex := RegEx.new()
	regex.compile("\\s*q_d\\d+_\\d+_\\d+\\b|\\s*q_[a-zA-Z0-9_]+\\b")
	return regex.sub(text, "", true).strip_edges()

func get_prompt_text() -> String:
	return _prompt_text

func get_objective_text() -> String:
	return _objective_text

func get_feedback_text() -> String:
	return _feedback_text

func is_correct() -> bool:
	return _is_correct

func has_feedback() -> bool:
	return _has_feedback

func get_active_interaction_view() -> Control:
	return _active_interaction_view

func _update_labels() -> void:
	if _prompt_label != null:
		_prompt_label.text = _prompt_text
		_prompt_label.visible = not _prompt_text.is_empty()

	if _objective_label != null:
		_objective_label.text = _objective_text
		_objective_label.visible = not _objective_text.is_empty()

	if _feedback_label != null:
		_feedback_label.visible = _has_feedback
		if _has_feedback:
			_feedback_label.theme_type_variation = &"MathosSuccess" if _is_correct else &"MathosError"
			var header_str: String = "Chính xác!" if _is_correct else "Chưa chính xác"
			_feedback_label.text = "[%s] %s" % [header_str, _feedback_text]

func _on_submit_button_pressed() -> void:
	if _has_feedback:
		if _is_correct or (_submit_button != null and _submit_button.text == "TIẾP TỤC"):
			continue_requested.emit()
		else:
			_has_feedback = false
			_feedback_text = ""
			_is_submitting = false
			if _feedback_label != null:
				_feedback_label.visible = false
			if _submit_button != null:
				_submit_button.text = "Xác nhận"
			if _active_interaction_view != null:
				if _active_interaction_view.has_method("reset_interaction"):
					_active_interaction_view.call("reset_interaction")
				elif _active_interaction_view.has_method("set_disabled"):
					_active_interaction_view.call("set_disabled", false)
			retry_requested.emit()
	else:
		if _is_submitting:
			return
		_is_submitting = true
		request_submit()

func _on_hint_button_pressed() -> void:
	var hint: String = String(_question_view.get("hint", "")).strip_edges()
	if hint.is_empty():
		hint = String(_question_view.get("explanation", "")).strip_edges()
	hint = sanitize_presentation_text(hint)

	if hint.is_empty():
		hint = "Đọc kỹ các giả thiết và phân tích không gian mẫu hoặc các biến cố độc lập để chọn đáp án."

	_feedback_text = "💡 Gợi ý: %s" % hint
	_has_feedback = true
	_ensure_ui_built()

	if _feedback_label != null:
		_feedback_label.theme_type_variation = &"MathosMeta"
		_feedback_label.text = _feedback_text
		_feedback_label.modulate.a = 0.0
		_feedback_label.visible = true
		var fb_tween: Tween = create_tween()
		if fb_tween != null:
			fb_tween.tween_property(_feedback_label, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
