class_name DragDropView
extends Control

## UI View for rendering Drag and Drop question interactions.

signal placements_changed(placements: Array)

var _items: Array = []
var _targets: Array = []
var _placements: Dictionary = {} # item_id -> target_id

func setup(interaction_payload: Dictionary) -> bool:
	_items = []
	_targets = []
	_placements = {}
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
	placements_changed.emit(get_placements_array())
	return true

func remove_placement(item_id: String) -> bool:
	if _placements.has(item_id):
		_placements.erase(item_id)
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
