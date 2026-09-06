class_name DragDropView
extends Control

## UI View for rendering Drag and Drop question interactions consuming Mathos Shared UI Foundation.
## Supports visual states: normal, hover, selected, focus, dragging/active, completed/placed, disabled.

signal placements_changed(placements: Array)

var _items: Array = []
var _targets: Array = []
var _placements: Dictionary = {} # item_id -> target_id
var _disabled: bool = false

var _vbox: VBoxContainer = null
var _target_options: Dictionary = {} # item_id -> OptionButton
var _item_cards: Dictionary = {} # item_id -> UiOptionCard

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
	_vbox.name = "DragDropVBox"
	_vbox.set_anchors_preset(PRESET_FULL_RECT)
	_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", MathosTokens.SPACING_SM)
	add_child(_vbox)

	_rebuild_ui()

func setup(interaction_payload: Dictionary) -> bool:
	_items = []
	_targets = []
	_placements = {}
	_disabled = false
	_target_options.clear()
	_item_cards.clear()

	if not interaction_payload.has("items") or not (interaction_payload["items"] is Array) or not interaction_payload.has("targets") or not (interaction_payload["targets"] is Array):
		return false
	var raw_items: Array = interaction_payload["items"] as Array
	var raw_targets: Array = interaction_payload["targets"] as Array
	if raw_items.is_empty() or raw_targets.is_empty():
		return false

	for it_var in raw_items:
		if not (it_var is Dictionary) or not (it_var as Dictionary).has("item_id"):
			return false
		_items.append((it_var as Dictionary).duplicate(true))

	for tg_var in raw_targets:
		if not (tg_var is Dictionary) or not (tg_var as Dictionary).has("target_id"):
			return false
		_targets.append((tg_var as Dictionary).duplicate(true))

	_ensure_ui_built()
	_rebuild_ui()
	return true

func place_item(item_id: String, target_id: String) -> bool:
	var item_valid: bool = false
	for it in _items:
		if String(it["item_id"]) == item_id:
			item_valid = true
			break
	if not item_valid:
		return false

	var target_valid: bool = false
	for tg in _targets:
		if String(tg["target_id"]) == target_id:
			target_valid = true
			break
	if not target_valid:
		return false

	_placements[item_id] = target_id
	_update_option_selections()
	placements_changed.emit(get_placements_array())
	return true

func remove_placement(item_id: String) -> bool:
	if _placements.has(item_id):
		_placements.erase(item_id)
		_update_option_selections()
		placements_changed.emit(get_placements_array())
		return true
	return false

func get_placements_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in _placements:
		result.append({
			"item_id": item_id,
			"target_id": String(_placements[item_id])
		})
	return result

func get_interaction_payload() -> Dictionary:
	return {"placements": get_placements_array()}

func set_disabled(p_disabled: bool) -> void:
	_disabled = p_disabled
	_update_option_selections()

func is_disabled() -> bool:
	return _disabled

func reset_interaction() -> void:
	_placements.clear()
	_disabled = false
	_update_option_selections()

func show_feedback(_attempt_result: Dictionary) -> void:
	set_disabled(true)

func _rebuild_ui() -> void:
	if _vbox == null:
		return

	for child in _vbox.get_children():
		_vbox.remove_child(child)
		if child.is_inside_tree():
			child.queue_free()
		else:
			child.free()
	_target_options.clear()
	_item_cards.clear()

	var panel_width: float = size.x if size.x > 100.0 else 480.0
	var avail_left_width: float = maxf(140.0, (panel_width - MathosTokens.SPACING_SM - 32.0) * 0.55)
	var total_min_height: float = 16.0

	for it_var in _items:
		var it: Dictionary = it_var as Dictionary
		var item_id: String = String(it["item_id"])
		var item_text: String = String(it.get("text", item_id))

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.name = "ItemHBox_" + item_id
		hbox.size_flags_horizontal = SIZE_EXPAND_FILL
		hbox.size_flags_vertical = SIZE_SHRINK_CENTER
		hbox.add_theme_constant_override("separation", MathosTokens.SPACING_SM)

		# Left Item Token Card (UiOptionCard / Draggable item)
		var item_card: DragItemCard = DragItemCard.new(item_id, item_text, self)
		item_card.size_flags_horizontal = SIZE_EXPAND_FILL
		item_card.size_flags_vertical = SIZE_FILL
		item_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(item_card)
		_item_cards[item_id] = item_card

		# Fallback legacy label reference for standard inspection
		var label: Label = Label.new()
		label.text = "%s: " % item_text
		label.custom_minimum_size = Vector2(80, 30)
		label.visible = false # Hidden, item_card renders text visually
		hbox.add_child(label)

		# Right Target Selection (OptionButton)
		var opt_btn: OptionButton = OptionButton.new()
		opt_btn.name = "TargetOption_" + item_id
		opt_btn.size_flags_horizontal = SIZE_EXPAND_FILL
		opt_btn.size_flags_vertical = SIZE_FILL
		opt_btn.custom_minimum_size = Vector2(140, 44)
		opt_btn.focus_mode = FOCUS_ALL
		opt_btn.mouse_filter = MOUSE_FILTER_STOP
		opt_btn.add_item("-- Unassigned --", 0)

		var target_ids: Array[String] = []
		var idx: int = 1
		for tg_var in _targets:
			var tg: Dictionary = tg_var as Dictionary
			var tg_id: String = String(tg["target_id"])
			var tg_text: String = String(tg.get("label", tg.get("text", tg_id)))
			opt_btn.add_item(tg_text, idx)
			target_ids.append(tg_id)
			idx += 1

		var captured_item_id: String = item_id
		opt_btn.item_selected.connect(func(selected_idx: int):
			if selected_idx <= 0:
				remove_placement(captured_item_id)
			else:
				var chosen_target_id: String = target_ids[selected_idx - 1]
				place_item(captured_item_id, chosen_target_id)
		)

		hbox.add_child(opt_btn)

		var row_h: float = _calc_required_row_height(item_text, avail_left_width)
		item_card.custom_minimum_size = Vector2(140, row_h)
		opt_btn.custom_minimum_size = Vector2(140, row_h)
		hbox.custom_minimum_size = Vector2(0, row_h)
		total_min_height += row_h + float(MathosTokens.SPACING_SM)

		_vbox.add_child(hbox)
		_target_options[item_id] = opt_btn

	_update_option_selections()
	custom_minimum_size = Vector2(0, maxf(100.0, total_min_height))

func _calc_required_row_height(item_text: String, avail_width: float) -> float:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 16
	var text_size: Vector2 = font.get_multiline_string_size(item_text, HORIZONTAL_ALIGNMENT_LEFT, maxf(120.0, avail_width - 24.0), font_size)
	return maxf(48.0, text_size.y + 24.0)

func _update_option_selections() -> void:
	for item_id in _target_options:
		var opt_btn: OptionButton = _target_options[item_id] as OptionButton
		var item_card: DragItemCard = _item_cards.get(item_id) as DragItemCard

		if opt_btn == null:
			continue

		opt_btn.disabled = _disabled
		if item_card != null:
			item_card.disabled = _disabled

		if _placements.has(item_id):
			var assigned_target_id: String = String(_placements[item_id])
			var target_label: String = assigned_target_id
			for idx in range(1, opt_btn.item_count):
				var target_idx: int = idx - 1
				if target_idx < _targets.size() and String((_targets[target_idx] as Dictionary)["target_id"]) == assigned_target_id:
					opt_btn.select(idx)
					var tg: Dictionary = _targets[target_idx] as Dictionary
					target_label = String(tg.get("label", tg.get("text", assigned_target_id)))
					break

			if item_card != null:
				item_card.set_placed_state(true, target_label)
		else:
			opt_btn.select(0)
			if item_card != null:
				item_card.set_placed_state(false, "")

# Nested helper class for Draggable Item Card with visual states
class DragItemCard extends UiOptionCard:
	var item_id: String = ""
	var base_text: String = ""
	var owner_view: DragDropView = null
	var is_placed: bool = false

	func _init(p_id: String = "", p_text: String = "", p_owner: DragDropView = null) -> void:
		super._init()
		item_id = p_id
		base_text = p_text
		owner_view = p_owner
		text = base_text
		focus_mode = FOCUS_ALL
		mouse_filter = MOUSE_FILTER_STOP

	func set_placed_state(placed: bool, _target_label: String = "") -> void:
		is_placed = placed
		set_selected(placed) # Visual selection state (border variation)
		text = base_text # ALWAYS preserve original base_text! Never mutate with [Placed] or -> <target>

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if disabled or owner_view == null:
			return null

		# Dragging / active visual state preview
		var preview: PanelContainer = PanelContainer.new()
		preview.theme_type_variation = &"MathosOption"
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = MathosTokens.SURFACE_ELEVATED
		sb.border_color = MathosTokens.BORDER_SELECTED
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.corner_radius_top_left = MathosTokens.RADIUS_MD
		sb.corner_radius_top_right = MathosTokens.RADIUS_MD
		sb.corner_radius_bottom_right = MathosTokens.RADIUS_MD
		sb.corner_radius_bottom_left = MathosTokens.RADIUS_MD
		sb.content_margin_left = MathosTokens.SPACING_MD
		sb.content_margin_top = MathosTokens.SPACING_SM
		sb.content_margin_right = MathosTokens.SPACING_MD
		sb.content_margin_bottom = MathosTokens.SPACING_SM
		preview.add_theme_stylebox_override("panel", sb)

		var lbl: Label = Label.new()
		lbl.text = "[Dragging] %s" % base_text
		lbl.add_theme_color_override("font_color", MathosTokens.TEXT_HEADING)
		lbl.add_theme_font_size_override("font_size", MathosTokens.FONT_SIZE_BODY)
		preview.add_child(lbl)

		set_drag_preview(preview)

		return {
			"type": "mathos_drag_item",
			"item_id": item_id,
			"source_view": owner_view
		}
