class_name MultipleChoiceView
extends Control

## UI View for rendering Multiple Choice question interactions consuming Mathos Shared UI Foundation.
## Supports visual states: normal, hover, selected, focus, disabled, correct feedback, incorrect feedback.
## Format player-facing option prefixes as A., B., C., D. while preserving underlying option_id in payloads.

signal option_selected(option_id: String)

var _options: Array = []
var _selected_option_id: String = ""
var _disabled: bool = false

var _vbox: VBoxContainer = null
var _option_buttons: Dictionary = {} # option_id -> UiOptionCard
var _combat_grid_mode: bool = false
var _grid: GridContainer = null

func set_combat_grid_mode(enabled: bool) -> void:
	if _combat_grid_mode == enabled:
		return
	_combat_grid_mode = enabled
	_ensure_ui_built()
	_rebuild_option_buttons()

func is_combat_grid_mode() -> bool:
	return _combat_grid_mode

func _ready() -> void:
	_ensure_ui_built()

func _ensure_ui_built() -> void:
	if _vbox != null:
		return

	set_anchors_preset(PRESET_FULL_RECT)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(240, 100)

	_vbox = VBoxContainer.new()
	_vbox.name = "OptionsVBox"
	_vbox.set_anchors_preset(PRESET_FULL_RECT)
	_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", MathosTokens.SPACING_SM)
	add_child(_vbox)

	_grid = GridContainer.new()
	_grid.name = "OptionsGrid"
	_grid.set_anchors_preset(PRESET_FULL_RECT)
	_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	_grid.size_flags_vertical = SIZE_EXPAND_FILL
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 8)
	_grid.visible = false
	add_child(_grid)

	_rebuild_option_buttons()

static func get_option_letter(opt_id: String, index: int) -> String:
	var clean: String = opt_id.to_lower()
	if clean.begins_with("opt_"):
		var suffix: String = clean.trim_prefix("opt_")
		if suffix.length() == 1 and suffix[0] >= 'a' and suffix[0] <= 'z':
			return suffix.to_upper()
		elif suffix.is_valid_int():
			var num: int = suffix.to_int()
			if num >= 1 and num <= 26:
				return String.chr(64 + num)
	if index >= 0 and index < 26:
		return String.chr(65 + index)
	return opt_id

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

	for i in range(_options.size()):
		var opt: Dictionary = _options[i] as Dictionary
		var opt_id: String = String(opt["option_id"])
		var letter: String = get_option_letter(opt_id, i)
		var card: UiOptionCard = _option_buttons.get(opt_id) as UiOptionCard
		if card != null:
			card.disabled = true
			var raw_label: String = "%s. %s" % [letter, MathContentRenderer.render(String(opt.get("text", opt_id)))]

			if opt_id == _selected_option_id:
				if is_correct:
					card.set_feedback(true)
					card.text = "✓ %s (Chính xác)" % raw_label
				else:
					card.set_feedback(false)
					card.text = "✗ BẠN CHỌN: %s" % raw_label
			elif not is_correct and not correct_opt_id.is_empty() and opt_id == correct_opt_id:
				card.set_feedback(true)
				card.text = "✓ ĐÁP ÁN ĐÚNG: %s" % raw_label

func _rebuild_option_buttons() -> void:
	if _vbox == null or _grid == null:
		return

	for child in _vbox.get_children():
		_vbox.remove_child(child)
		if child.is_inside_tree():
			child.queue_free()
		else:
			child.free()
	for child in _grid.get_children():
		_grid.remove_child(child)
		if child.is_inside_tree():
			child.queue_free()
		else:
			child.free()
	_option_buttons.clear()

	var target_parent: Control = _grid if _combat_grid_mode else _vbox
	_grid.visible = _combat_grid_mode
	_vbox.visible = not _combat_grid_mode

	for i in range(_options.size()):
		var opt: Dictionary = _options[i] as Dictionary
		var opt_id: String = String(opt["option_id"])
		var opt_text: String = MathContentRenderer.render(String(opt.get("text", opt_id)))
		var letter: String = get_option_letter(opt_id, i)

		var card: UiOptionCard = UiOptionCard.new()
		card.name = "OptionButton_" + opt_id
		card.text = "   %s. %s" % [letter, opt_text]
		if _combat_grid_mode:
			card.custom_minimum_size = Vector2(236, 40)
			card.add_theme_font_size_override("font_size", 12)
		else:
			card.custom_minimum_size = Vector2(240, 44)
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.clip_text = false
		card.focus_mode = FOCUS_ALL
		card.mouse_filter = MOUSE_FILTER_STOP

		card.pressed.connect(func(): select_option(opt_id))

		target_parent.add_child(card)
		_option_buttons[opt_id] = card

	_update_button_states()

	if _combat_grid_mode:
		var grid_min: Vector2 = _grid.get_combined_minimum_size()
		custom_minimum_size = Vector2(maxf(480.0, grid_min.x), maxf(88.0, grid_min.y))
	else:
		var total_h: float = 0.0
		for child in _vbox.get_children():
			if child is Control and (child as Control).visible:
				total_h += (child as Control).get_combined_minimum_size().y + float(MathosTokens.SPACING_SM)
		custom_minimum_size = Vector2(240, maxf(100.0, total_h))
	update_minimum_size()

func _get_minimum_size() -> Vector2:
	if _combat_grid_mode and _grid != null:
		return _grid.get_combined_minimum_size()
	if _vbox != null:
		return _vbox.get_combined_minimum_size()
	return custom_minimum_size

func _update_button_states() -> void:
	for i in range(_options.size()):
		var opt: Dictionary = _options[i] as Dictionary
		var opt_id: String = String(opt["option_id"])
		var opt_text: String = MathContentRenderer.render(String(opt.get("text", opt_id)))
		var letter: String = get_option_letter(opt_id, i)
		var card: UiOptionCard = _option_buttons.get(opt_id) as UiOptionCard

		if card != null:
			var is_selected: bool = (opt_id == _selected_option_id)
			card.set_selected(is_selected)
			card.disabled = _disabled

			if is_selected:
				card.text = "◆  %s. %s" % [letter, opt_text]
			else:
				card.text = "   %s. %s" % [letter, opt_text]
