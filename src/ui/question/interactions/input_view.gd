class_name InputView
extends Control

## UI View for rendering Input question interactions.

signal value_changed(value: Variant)

var _input_type: String = ""
var _current_raw_value: String = ""

func setup(interaction_payload: Dictionary) -> bool:
	_input_type = ""
	_current_raw_value = ""
	if not interaction_payload.has("input_type") or not (interaction_payload["input_type"] is String):
		return false
	var itype: String = String(interaction_payload["input_type"])
	if not ["integer", "float", "string", "symbol"].has(itype):
		return false
	_input_type = itype
	return true

func set_input_value(raw_value: String) -> void:
	_current_raw_value = raw_value
	value_changed.emit(get_parsed_value())

func get_parsed_value() -> Variant:
	match _input_type:
		"integer":
			if _current_raw_value.is_valid_int():
				return _current_raw_value.to_int()
			return _current_raw_value
		"float":
			if _current_raw_value.is_valid_float():
				return _current_raw_value.to_float()
			return _current_raw_value
		"string", "symbol":
			return _current_raw_value
		_:
			return _current_raw_value

func get_interaction_payload() -> Dictionary:
	return {"value": get_parsed_value()}
