class_name DragDropView
extends Control

## UI View for rendering Drag and Drop question interactions.

signal placements_changed(placements: Array)

var _items: Array = []
var _targets: Array = []
var _placements: Dictionary = {} # item_id -> target_id

var _vbox: VBoxContainer = null
var _target_options: Dictionary = {} # item_id -> OptionButton

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
	_vbox.name = "DragDropVBox"
	_vbox.set_anchors_preset(PRESET_FULL_RECT)
	_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 8)
	add_child(_vbox)

	_rebuild_ui()

func setup(interaction_payload: Dictionary) -> bool:
	_items = []
	_targets = []
	_placements = {}
	_target_options.clear()

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

	for it_var in _items:
		var it: Dictionary = it_var as Dictionary
		var item_id: String = String(it["item_id"])
		var item_text: String = String(it.get("text", item_id))

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.name = "ItemHBox_" + item_id
		hbox.size_flags_horizontal = SIZE_EXPAND_FILL

		var label: Label = Label.new()
		label.text = "%s: " % item_text
		label.custom_minimum_size = Vector2(120, 30)
		hbox.add_child(label)

		var opt_btn: OptionButton = OptionButton.new()
		opt_btn.name = "TargetOption_" + item_id
		opt_btn.size_flags_horizontal = SIZE_EXPAND_FILL
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
		_vbox.add_child(hbox)
		_target_options[item_id] = opt_btn

	_update_option_selections()

func _update_option_selections() -> void:
	for item_id in _target_options:
		var opt_btn: OptionButton = _target_options[item_id] as OptionButton
		if opt_btn == null:
			continue
		if _placements.has(item_id):
			var assigned_target_id: String = String(_placements[item_id])
			for idx in range(1, opt_btn.item_count):
				var target_idx: int = idx - 1
				if target_idx < _targets.size() and String((_targets[target_idx] as Dictionary)["target_id"]) == assigned_target_id:
					opt_btn.select(idx)
					break
		else:
			opt_btn.select(0)
