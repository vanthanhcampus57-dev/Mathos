class_name MultipleChoiceView
extends Control

## UI View for rendering Multiple Choice question interactions.

signal option_selected(option_id: String)

var _options: Array = []
var _selected_option_id: String = ""

var _vbox: VBoxContainer = null
var _option_buttons: Dictionary = {} # option_id -> Button

func _ready() -> void:
	_ensure_ui_built()

func _ensure_ui_built() -> void:
	if _vbox != null:
		return

	set_anchors_preset(PRESET_FULL_RECT)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(300, 150)

	_vbox = VBoxContainer.new()
	_vbox.name = "OptionsVBox"
	_vbox.set_anchors_preset(PRESET_FULL_RECT)
	_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 8)
	add_child(_vbox)

	_rebuild_option_buttons()

func setup(interaction_payload: Dictionary) -> bool:
	_options = []
	_selected_option_id = ""
	_option_buttons.clear()

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

	_ensure_ui_built()
	_rebuild_option_buttons()
	return true

func select_option(option_id: String) -> bool:
	for opt in _options:
		if String(opt["option_id"]) == option_id:
			_selected_option_id = option_id
			_update_button_states()
			option_selected.emit(_selected_option_id)
			return true
	return false

func get_selected_option_id() -> String:
	return _selected_option_id

func get_interaction_payload() -> Dictionary:
	if _selected_option_id.is_empty():
		return {}
	return {"selected_option_id": _selected_option_id}

func _rebuild_option_buttons() -> void:
	if _vbox == null:
		return

	for child in _vbox.get_children():
		_vbox.remove_child(child)
		if child.is_inside_tree():
			child.queue_free()
		else:
			child.free()
	_option_buttons.clear()

	for opt_var in _options:
		var opt: Dictionary = opt_var as Dictionary
		var opt_id: String = String(opt["option_id"])
		var opt_text: String = String(opt.get("text", opt_id))

		var btn: Button = Button.new()
		btn.name = "OptionButton_" + opt_id
		btn.text = "%s. %s" % [opt_id, opt_text]
		btn.custom_minimum_size = Vector2(240, 40)
		btn.size_flags_horizontal = SIZE_EXPAND_FILL

		btn.pressed.connect(func(): select_option(opt_id))

		_vbox.add_child(btn)
		_option_buttons[opt_id] = btn

	_update_button_states()

func _update_button_states() -> void:
	for opt_id in _option_buttons:
		var btn: Button = _option_buttons[opt_id] as Button
		if btn != null:
			var opt_text: String = opt_id
			for opt in _options:
				if String(opt["option_id"]) == opt_id:
					opt_text = String(opt.get("text", opt_id))
					break
			if opt_id == _selected_option_id:
				btn.text = "[X] %s. %s" % [opt_id, opt_text]
			else:
				btn.text = "   %s. %s" % [opt_id, opt_text]
