class_name MultipleChoiceView
extends Control

## UI View for rendering Multiple Choice question interactions consuming Mathos Shared UI Foundation.
## Supports visual states: normal, hover, selected, focus, disabled, correct feedback, incorrect feedback.

signal option_selected(option_id: String)

var _options: Array = []
var _selected_option_id: String = ""
var _disabled: bool = false

var _vbox: VBoxContainer = null
var _option_buttons: Dictionary = {} # option_id -> UiOptionCard

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
	_vbox.add_theme_constant_override("separation", MathosTokens.SPACING_SM)
	add_child(_vbox)

	_rebuild_option_buttons()

func setup(interaction_payload: Dictionary) -> bool:
	_options = []
	_selected_option_id = ""
	_disabled = false
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
	if _disabled:
		return false
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

func set_disabled(p_disabled: bool) -> void:
	_disabled = p_disabled
	_update_button_states()

func is_disabled() -> bool:
	return _disabled

func reset_interaction() -> void:
	_disabled = false
	_selected_option_id = ""
	_update_button_states()

func show_feedback(attempt_result: Dictionary) -> void:
	_disabled = true
	var is_correct: bool = bool(attempt_result.get("is_correct", false))
	var correct_opt_id: String = String(attempt_result.get("correct_option_id", ""))
	if correct_opt_id.is_empty() and attempt_result.has("feedback_details"):
		var details: Dictionary = attempt_result.get("feedback_details", {}) as Dictionary
		correct_opt_id = String(details.get("correct_option_id", ""))

	for opt_id in _option_buttons:
		var card: UiOptionCard = _option_buttons[opt_id] as UiOptionCard
		if card != null:
			card.disabled = true
			var raw_label: String = ""
			for opt in _options:
				if String(opt["option_id"]) == opt_id:
					raw_label = "%s. %s" % [opt_id, String(opt.get("text", opt_id))]
					break

			if opt_id == _selected_option_id:
				if is_correct:
					card.set_selected(true) # CYAN selected state per master
					card.text = "[✓] %s (Chính xác)" % raw_label
				else:
					card.set_feedback(false) # Coral/Red wrong selection
					card.text = "[X] BẠN CHỌN: %s" % raw_label
			elif not is_correct and not correct_opt_id.is_empty() and opt_id == correct_opt_id:
				card.set_selected(true) # CYAN correct option per master
				card.text = "[✓] ĐÁP ÁN ĐÚNG: %s" % raw_label

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

		var card: UiOptionCard = UiOptionCard.new()
		card.name = "OptionButton_" + opt_id
		card.text = "   %s. %s" % [opt_id, opt_text]
		card.custom_minimum_size = Vector2(240, 48)
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		card.focus_mode = FOCUS_ALL
		card.mouse_filter = MOUSE_FILTER_STOP

		card.pressed.connect(func(): select_option(opt_id))

		_vbox.add_child(card)
		_option_buttons[opt_id] = card

	_update_button_states()

func _update_button_states() -> void:
	for opt_id in _option_buttons:
		var card: UiOptionCard = _option_buttons[opt_id] as UiOptionCard
		if card != null:
			var opt_text: String = opt_id
			for opt in _options:
				if String(opt["option_id"]) == opt_id:
					opt_text = String(opt.get("text", opt_id))
					break

			var is_selected: bool = (opt_id == _selected_option_id)
			card.set_selected(is_selected)
			card.disabled = _disabled

			if is_selected:
				card.text = "[X] %s. %s" % [opt_id, opt_text]
			else:
				card.text = "   %s. %s" % [opt_id, opt_text]
