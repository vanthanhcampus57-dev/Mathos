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
	custom_minimum_size = Vector2(300, 100)

	_vbox = VBoxContainer.new()
	_vbox.name = "InputVBox"
	_vbox.set_anchors_preset(PRESET_FULL_RECT)
	_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", MathosTokens.SPACING_SM)
	add_child(_vbox)

	_label = UiMetaLabel.new()
	_label.name = "InputMetaLabel"
	_label.text = "Input response type: %s" % (_input_type if not _input_type.is_empty() else "answer")
	_vbox.add_child(_label)

	_line_edit = LineEdit.new()
	_line_edit.name = "ValueLineEdit"
	_line_edit.placeholder_text = "Enter %s answer..." % (_input_type if not _input_type.is_empty() else "your")
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
		_label.text = "Input response type: %s" % _input_type
	if _line_edit != null:
		_line_edit.placeholder_text = "Enter %s answer..." % _input_type
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

func set_disabled(p_disabled: bool) -> void:
	_disabled = p_disabled
	if _line_edit != null:
		_line_edit.editable = not _disabled

func is_disabled() -> bool:
	return _disabled

func _apply_line_edit_styles() -> void:
	if _line_edit == null:
		return

	# StyleBox definitions consuming MathosTokens
	var sb_normal: StyleBoxFlat = StyleBoxFlat.new()
	sb_normal.bg_color = MathosTokens.SURFACE_SECONDARY
	sb_normal.border_color = MathosTokens.BORDER_DEFAULT
	sb_normal.border_width_left = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_bottom = 1
	sb_normal.corner_radius_top_left = MathosTokens.RADIUS_MD
	sb_normal.corner_radius_top_right = MathosTokens.RADIUS_MD
	sb_normal.corner_radius_bottom_right = MathosTokens.RADIUS_MD
	sb_normal.corner_radius_bottom_left = MathosTokens.RADIUS_MD
	sb_normal.content_margin_left = MathosTokens.SPACING_LG
	sb_normal.content_margin_top = MathosTokens.SPACING_MD
	sb_normal.content_margin_right = MathosTokens.SPACING_LG
	sb_normal.content_margin_bottom = MathosTokens.SPACING_MD

	var sb_focus: StyleBoxFlat = sb_normal.duplicate() as StyleBoxFlat
	sb_focus.border_color = MathosTokens.BORDER_FOCUS
	sb_focus.border_width_left = 2
	sb_focus.border_width_top = 2
	sb_focus.border_width_right = 2
	sb_focus.border_width_bottom = 2

	var sb_read_only: StyleBoxFlat = sb_normal.duplicate() as StyleBoxFlat
	sb_read_only.bg_color = MathosTokens.SURFACE_CARD
	sb_read_only.border_color = MathosTokens.BORDER_SUBTLE

	_line_edit.add_theme_stylebox_override("normal", sb_normal)
	_line_edit.add_theme_stylebox_override("focus", sb_focus)
	_line_edit.add_theme_stylebox_override("read_only", sb_read_only)

	_line_edit.add_theme_color_override("font_color", MathosTokens.TEXT_TITLE)
	_line_edit.add_theme_color_override("placeholder_color", MathosTokens.TEXT_MUTED)
	_line_edit.add_theme_color_override("selection_color", Color(0.22, 0.74, 0.97, 0.35))
	_line_edit.add_theme_font_size_override("font_size", MathosTokens.FONT_SIZE_BODY)
