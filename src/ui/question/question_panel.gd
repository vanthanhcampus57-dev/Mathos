class_name QuestionPanel
extends Control

## Presentation UI container for rendering a presentation-safe QuestionDefinition,
## capturing interaction input, and displaying AttemptResult feedback.

signal submit_requested(interaction_payload: Dictionary)

var _question_view: Dictionary = {}
var _active_interaction_view: Control = null
var _prompt_text: String = ""
var _objective_text: String = ""
var _feedback_text: String = ""
var _is_correct: bool = false
var _has_feedback: bool = false

# UI Control nodes
var _main_vbox: VBoxContainer = null
var _objective_label: Label = null
var _prompt_label: Label = null
var _interaction_container: MarginContainer = null
var _feedback_label: Label = null
var _submit_button: Button = null

func _ready() -> void:
	_ensure_ui_built()

func _ensure_ui_built() -> void:
	if _main_vbox != null:
		return

	set_anchors_preset(PRESET_FULL_RECT)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(400, 300)

	_main_vbox = VBoxContainer.new()
	_main_vbox.name = "MainVBox"
	_main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	_main_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_main_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_main_vbox.add_theme_constant_override("separation", 12)
	add_child(_main_vbox)

	_objective_label = Label.new()
	_objective_label.name = "ObjectiveLabel"
	_objective_label.visible = false
	_main_vbox.add_child(_objective_label)

	_prompt_label = Label.new()
	_prompt_label.name = "PromptLabel"
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.text = _prompt_text
	_prompt_label.visible = not _prompt_text.is_empty()
	_main_vbox.add_child(_prompt_label)

	_interaction_container = MarginContainer.new()
	_interaction_container.name = "InteractionContainer"
	_interaction_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_interaction_container.size_flags_vertical = SIZE_EXPAND_FILL
	_main_vbox.add_child(_interaction_container)

	_feedback_label = Label.new()
	_feedback_label.name = "FeedbackLabel"
	_feedback_label.visible = _has_feedback
	_feedback_label.text = _feedback_text
	_main_vbox.add_child(_feedback_label)

	_submit_button = Button.new()
	_submit_button.name = "SubmitButton"
	_submit_button.text = "Submit Answer"
	_submit_button.custom_minimum_size = Vector2(160, 40)
	_submit_button.pressed.connect(_on_submit_button_pressed)
	_main_vbox.add_child(_submit_button)

	if _active_interaction_view != null and _active_interaction_view.get_parent() == null:
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
	_prompt_text = String(question_view["prompt"])
	_objective_text = String(question_view.get("learning_objective", ""))

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

	if _prompt_label != null:
		_prompt_label.text = _prompt_text
		_prompt_label.visible = not _prompt_text.is_empty()

	if _objective_label != null:
		_objective_label.text = _objective_text
		_objective_label.visible = not _objective_text.is_empty()

	if _feedback_label != null:
		_feedback_label.visible = false
		_feedback_label.text = ""

	if _active_interaction_view != null:
		if _active_interaction_view.get_parent() != null:
			_active_interaction_view.get_parent().remove_child(_active_interaction_view)
		if _interaction_container != null:
			_interaction_container.add_child(_active_interaction_view)
		else:
			add_child(_active_interaction_view)
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

	if _feedback_label != null:
		_feedback_label.text = "[%s] %s" % ["CORRECT" if _is_correct else "INCORRECT", _feedback_text]
		_feedback_label.visible = true
	return true

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

func _on_submit_button_pressed() -> void:
	request_submit()
