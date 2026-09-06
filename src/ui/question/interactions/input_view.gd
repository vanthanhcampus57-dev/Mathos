class_name InputView
extends Control

## UI View for rendering Input question interactions consuming Mathos Shared UI Foundation.
## Supports visual states: normal, hover, selected/active, focus, disabled.

signal value_changed(value: Variant)

var _input_type: String = ""
var _current_raw_value: String = ""
var _disabled: bool = false

var _vbox: VBoxContainer = null
var _label: UiMetaLabel = null
var _line_edit: LineEdit = null

func _ready() -> void:
	_ensure_ui_built()

func _ensure_ui_built() -> void:
	if _vbox != null:
		return

	set_anchors_preset(PRESET_FULL_RECT)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 100)

	_vbox = VBoxContainer.new()
	_vbox.name = "InputVBox"
	_vbox.set_anchors_preset(PRESET_FULL_RECT)
	_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", MathosTokens.SPACING_SM)
	add_child(_vbox)

	_label = UiMetaLabel.new()
	_label.name = "InputMetaLabel"
	_label.text = ""
	_label.visible = false
	_vbox.add_child(_label)

	_line_edit = LineEdit.new()
	_line_edit.name = "ValueLineEdit"
	_line_edit.placeholder_text = "Nhập câu trả lời..."
	_line_edit.custom_minimum_size = Vector2(240, 48)
	_line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	_line_edit.text = _current_raw_value
	_line_edit.focus_mode = FOCUS_ALL
	_line_edit.mouse_filter = MOUSE_FILTER_STOP
	_line_edit.caret_blink = true

	_apply_line_edit_styles()

	_line_edit.text_changed.connect(func(new_text: String): set_input_value(new_text))
	_vbox.add_child(_line_edit)

func setup(interaction_payload: Dictionary) -> bool:
	_input_type = ""
	_current_raw_value = ""
	_disabled = false
	if not interaction_payload.has("input_type") or not (interaction_payload["input_type"] is String):
		return false
	var itype: String = String(interaction_payload["input_type"])
	if not ["integer", "float", "string", "symbol"].has(itype):
		return false
	_input_type = itype

	_ensure_ui_built()
	if _label != null:
		_label.text = ""
		_label.visible = false
	if _line_edit != null:
		var custom_placeholder: String = String(interaction_payload.get("placeholder_text", ""))
		if not custom_placeholder.is_empty():
			_line_edit.placeholder_text = custom_placeholder
		else:
			_line_edit.placeholder_text = "Nhập câu trả lời..."
		_line_edit.text = _current_raw_value
		_line_edit.editable = not _disabled
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

func is_disabled() -> bool:
	return _disabled

func set_disabled(disabled: bool) -> void:
	_disabled = disabled
	if _line_edit != null:
		_line_edit.editable = not disabled
	_apply_line_edit_styles()

func reset_interaction() -> void:
	_current_raw_value = ""
	if _line_edit != null:
		_line_edit.text = ""
	set_disabled(false)

func get_line_edit() -> LineEdit:
	return _line_edit

func show_feedback(_attempt_result: Dictionary) -> void:
	set_disabled(true)

func _apply_line_edit_styles() -> void:
	if _line_edit == null:
		return

	_line_edit.add_theme_font_size_override("font_size", MathosTokens.FONT_SIZE_BODY)

	var bg_color: Color = MathosTokens.SURFACE_PRIMARY
	var border_color: Color = MathosTokens.BORDER_DEFAULT
	var text_color: Color = MathosTokens.TEXT_BODY

	if _disabled:
		bg_color = MathosTokens.SURFACE_SECONDARY
		border_color = MathosTokens.BORDER_SUBTLE
		text_color = MathosTokens.TEXT_MUTED

	var style_normal: StyleBoxFlat = StyleBoxFlat.new()
	style_normal.bg_color = bg_color
	style_normal.border_color = border_color
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(MathosTokens.RADIUS_MD)
	style_normal.content_margin_left = MathosTokens.SPACING_MD
	style_normal.content_margin_right = MathosTokens.SPACING_MD
	style_normal.content_margin_top = MathosTokens.SPACING_SM
	style_normal.content_margin_bottom = MathosTokens.SPACING_SM

	var style_focus: StyleBoxFlat = style_normal.duplicate() as StyleBoxFlat
	style_focus.border_color = MathosTokens.BORDER_FOCUS
	style_focus.set_border_width_all(3)

	_line_edit.add_theme_stylebox_override("normal", style_normal)
	_line_edit.add_theme_stylebox_override("focus", style_focus)
	_line_edit.add_theme_color_override("font_color", text_color)
	_line_edit.add_theme_color_override("font_placeholder_color", MathosTokens.TEXT_MUTED)
