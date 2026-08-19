class_name MultipleChoiceView
extends Control

## UI View for rendering Multiple Choice question interactions.

signal option_selected(option_id: String)

var _options: Array = []
var _selected_option_id: String = ""

func setup(interaction_payload: Dictionary) -> bool:
	_options = []
	_selected_option_id = ""
	if not interaction_payload.has("options") or not (interaction_payload["options"] is Array):
		return false
	var raw_options: Array = interaction_payload["options"] as Array
	if raw_options.size() < 2:
		return false

	for opt_var in raw_options:
		if not (opt_var is Dictionary):
			return false
		var opt: Dictionary = opt_var as Dictionary
		if not opt.has("option_id") or not (opt["option_id"] is String) or String(opt["option_id"]).is_empty():
			return false
		_options.append(opt.duplicate(true))
	return true

func select_option(option_id: String) -> bool:
	for opt in _options:
		if String(opt["option_id"]) == option_id:
			_selected_option_id = option_id
			option_selected.emit(_selected_option_id)
			return true
	return false

func get_selected_option_id() -> String:
	return _selected_option_id

func get_interaction_payload() -> Dictionary:
	if _selected_option_id.is_empty():
		return {}
	return {"selected_option_id": _selected_option_id}
