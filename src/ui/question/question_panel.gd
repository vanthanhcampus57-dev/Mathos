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

func setup_question(question_view: Dictionary) -> bool:
	_question_view = {}
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

	if _active_interaction_view != null:
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
