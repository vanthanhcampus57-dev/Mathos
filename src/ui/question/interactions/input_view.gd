class_name InputView
extends Control

## UI View for rendering Input question interactions.

signal value_changed(value: Variant)

var _input_type: String = ""
var _current_raw_value: String = ""

var _vbox: VBoxContainer = null
var _line_edit: LineEdit = null

func _ready() -> void:
	_ensure_ui_built()

func _ensure_ui_built() -> void:
	if _vbox != null:
		return

	set_anchors_preset(PRESET_FULL_RECT)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(300, 100)

	_vbox = VBoxContainer.new()
	_vbox.name = "InputVBox"
	_vbox.set_anchors_preset(PRESET_FULL_RECT)
	_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 8)
	add_child(_vbox)

	_line_edit = LineEdit.new()
	_line_edit.name = "ValueLineEdit"
	_line_edit.placeholder_text = "Enter %s answer..." % (_input_type if not _input_type.is_empty() else "your")
	_line_edit.custom_minimum_size = Vector2(240, 40)
	_line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	_line_edit.text = _current_raw_value

	_line_edit.text_changed.connect(func(new_text: String): set_input_value(new_text))
	_vbox.add_child(_line_edit)

func setup(interaction_payload: Dictionary) -> bool:
	_input_type = ""
	_current_raw_value = ""
	if not interaction_payload.has("input_type") or not (interaction_payload["input_type"] is String):
		return false
	var itype: String = String(interaction_payload["input_type"])
	if not ["integer", "float", "string", "symbol"].has(itype):
		return false
	_input_type = itype

	_ensure_ui_built()
	if _line_edit != null:
		_line_edit.placeholder_text = "Enter %s answer..." % _input_type
		_line_edit.text = _current_raw_value
	return true

func set_input_value(raw_value: String) -> void:
	_current_raw_value = raw_value
	if _line_edit != null and _line_edit.text != raw_value:
		_line_edit.text = raw_value
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
