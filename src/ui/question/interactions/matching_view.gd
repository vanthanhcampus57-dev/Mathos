class_name MatchingView
extends Control

## UI View for rendering Matching question interactions consuming Mathos Shared UI Foundation.
## Supports visual states: normal, hover, selected, focus, completed/placed, disabled.

signal pairs_changed(pairs: Array)

var _left_items: Array = []
var _right_items: Array = []
var _pairs: Dictionary = {} # left_id -> right_id
var _disabled: bool = false
var _active_left_id: String = ""

var _vbox: VBoxContainer = null
var _right_options: Dictionary = {} # left_id -> OptionButton
var _left_cards: Dictionary = {} # left_id -> UiOptionCard

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
	_vbox.name = "MatchingVBox"
	_vbox.set_anchors_preset(PRESET_FULL_RECT)
	_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", MathosTokens.SPACING_SM)
	add_child(_vbox)

	_rebuild_ui()

func setup(interaction_payload: Dictionary) -> bool:
	_left_items = []
	_right_items = []
	_pairs = {}
	_disabled = false
	_active_left_id = ""
	_right_options.clear()
	_left_cards.clear()

	if not interaction_payload.has("left_items") or not (interaction_payload["left_items"] is Array) or not interaction_payload.has("right_items") or not (interaction_payload["right_items"] is Array):
		return false
	var raw_left: Array = interaction_payload["left_items"] as Array
	var raw_right: Array = interaction_payload["right_items"] as Array
	if raw_left.is_empty() or raw_right.is_empty():
		return false

	for l_var in raw_left:
		if not (l_var is Dictionary) or not (l_var as Dictionary).has("item_id"):
			return false
		_left_items.append((l_var as Dictionary).duplicate(true))

	for r_var in raw_right:
		if not (r_var is Dictionary) or not (r_var as Dictionary).has("item_id"):
			return false
		_right_items.append((r_var as Dictionary).duplicate(true))

	_ensure_ui_built()
	_rebuild_ui()
	return true

func add_pair(left_id: String, right_id: String) -> bool:
	var left_valid: bool = false
	for l in _left_items:
		if String(l["item_id"]) == left_id:
			left_valid = true
			break
	if not left_valid:
		return false

	var right_valid: bool = false
	for r in _right_items:
		if String(r["item_id"]) == right_id:
			right_valid = true
			break
	if not right_valid:
		return false

	_pairs[left_id] = right_id
	_active_left_id = ""
	_update_option_selections()
	pairs_changed.emit(get_pairs_array())
	return true

func remove_pair(left_id: String) -> bool:
	if _pairs.has(left_id):
		_pairs.erase(left_id)
		if _active_left_id == left_id:
			_active_left_id = ""
		_update_option_selections()
		pairs_changed.emit(get_pairs_array())
		return true
	return false

func get_pairs_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for left_id in _pairs:
		result.append({
			"left_id": left_id,
			"right_id": String(_pairs[left_id])
		})
	return result

func get_interaction_payload() -> Dictionary:
	return {"pairs": get_pairs_array()}

func set_disabled(p_disabled: bool) -> void:
	_disabled = p_disabled
	_update_option_selections()

func is_disabled() -> bool:
	return _disabled

func select_left_card(left_id: String) -> void:
	if _disabled:
		return
	if _active_left_id == left_id:
		_active_left_id = ""
	else:
		_active_left_id = left_id
	_update_option_selections()

func _rebuild_ui() -> void:
	if _vbox == null:
		return

	for child in _vbox.get_children():
		_vbox.remove_child(child)
		if child.is_inside_tree():
			child.queue_free()
		else:
			child.free()
	_right_options.clear()
	_left_cards.clear()

	var panel_width: float = size.x if size.x > 100.0 else 480.0
	var avail_left_width: float = maxf(140.0, (panel_width - 32.0 - MathosTokens.SPACING_SM * 2.0) * 0.45)
	var total_min_height: float = 16.0

	for l_var in _left_items:
		var l: Dictionary = l_var as Dictionary
		var left_id: String = String(l["item_id"])
		var left_text: String = String(l.get("text", left_id))

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.name = "LeftItemHBox_" + left_id
		hbox.size_flags_horizontal = SIZE_EXPAND_FILL
		hbox.size_flags_vertical = SIZE_SHRINK_CENTER
		hbox.add_theme_constant_override("separation", MathosTokens.SPACING_SM)

		# Left Item Card (UiOptionCard)
		var left_card: UiOptionCard = UiOptionCard.new()
		left_card.text = left_text
		left_card.size_flags_horizontal = SIZE_EXPAND_FILL
		left_card.size_flags_vertical = SIZE_FILL
		left_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left_card.focus_mode = FOCUS_ALL
		left_card.mouse_filter = MOUSE_FILTER_STOP

		var captured_left_id: String = left_id
		left_card.pressed.connect(func(): select_left_card(captured_left_id))
		hbox.add_child(left_card)
		_left_cards[left_id] = left_card

		# Legacy Label for compatibility (hidden)
		var label: Label = Label.new()
		label.text = "%s <->" % left_text
		label.custom_minimum_size = Vector2(80, 30)
		label.visible = false
		hbox.add_child(label)

		# Indicator Badge
		var meta_label: UiMetaLabel = UiMetaLabel.new()
		meta_label.name = "MetaLabel_" + left_id
		meta_label.text = "<->"
		meta_label.custom_minimum_size = Vector2(32, 30)
		meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		meta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(meta_label)

		# Right Item OptionButton
		var opt_btn: OptionButton = OptionButton.new()
		opt_btn.name = "RightOption_" + left_id
		opt_btn.size_flags_horizontal = SIZE_EXPAND_FILL
		opt_btn.size_flags_vertical = SIZE_FILL
		opt_btn.custom_minimum_size = Vector2(140, 44)
		opt_btn.focus_mode = FOCUS_ALL
		opt_btn.mouse_filter = MOUSE_FILTER_STOP
		opt_btn.add_item("-- Unmatched --", 0)

		var right_ids: Array[String] = []
		var idx: int = 1
		for r_var in _right_items:
			var r: Dictionary = r_var as Dictionary
			var right_id: String = String(r["item_id"])
			var right_text: String = String(r.get("text", right_id))
			opt_btn.add_item(right_text, idx)
			right_ids.append(right_id)
			idx += 1

		opt_btn.item_selected.connect(func(selected_idx: int):
			if selected_idx <= 0:
				remove_pair(captured_left_id)
			else:
				var chosen_right_id: String = right_ids[selected_idx - 1]
				add_pair(captured_left_id, chosen_right_id)
		)

		hbox.add_child(opt_btn)

		var row_h: float = _calc_required_row_height(left_text, avail_left_width)
		left_card.custom_minimum_size = Vector2(140, row_h)
		opt_btn.custom_minimum_size = Vector2(140, row_h)
		hbox.custom_minimum_size = Vector2(0, row_h)
		total_min_height += row_h + float(MathosTokens.SPACING_SM)

		_vbox.add_child(hbox)
		_right_options[left_id] = opt_btn

	_update_option_selections()
	custom_minimum_size = Vector2(0, maxf(100.0, total_min_height))

func _calc_required_row_height(left_text: String, avail_width: float) -> float:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 16
	var text_size: Vector2 = font.get_multiline_string_size(left_text, HORIZONTAL_ALIGNMENT_LEFT, maxf(120.0, avail_width - 24.0), font_size)
	return maxf(48.0, text_size.y + 24.0)

func _update_option_selections() -> void:
	for left_id in _right_options:
		var opt_btn: OptionButton = _right_options[left_id] as OptionButton
		var left_card: UiOptionCard = _left_cards.get(left_id) as UiOptionCard
		var left_text: String = left_id
		for l in _left_items:
			if String(l["item_id"]) == left_id:
				left_text = String(l.get("text", left_id))
				break

		if opt_btn == null:
			continue

		opt_btn.disabled = _disabled
		if left_card != null:
			left_card.disabled = _disabled

		if _pairs.has(left_id):
			var assigned_right_id: String = String(_pairs[left_id])
			for idx in range(1, opt_btn.item_count):
				var right_idx: int = idx - 1
				if right_idx < _right_items.size() and String((_right_items[right_idx] as Dictionary)["item_id"]) == assigned_right_id:
					opt_btn.select(idx)
					break

			if left_card != null:
				left_card.set_selected(true) # Completed / matched pair visual state (border variation)
				left_card.text = left_text # ALWAYS preserve original left_text! Never mutate with [Matched]
		else:
			opt_btn.select(0)
			if left_card != null:
				var is_active: bool = (left_id == _active_left_id)
				left_card.set_selected(is_active)
				left_card.text = left_text # ALWAYS preserve original left_text! Never mutate with [Selecting]
