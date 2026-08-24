class_name MatchingView
extends Control

## UI View for rendering Matching question interactions.

signal pairs_changed(pairs: Array)

var _left_items: Array = []
var _right_items: Array = []
var _pairs: Dictionary = {} # left_id -> right_id

func setup(interaction_payload: Dictionary) -> bool:
	_left_items = []
	_right_items = []
	_pairs = {}
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
	pairs_changed.emit(get_pairs_array())
	return true

func remove_pair(left_id: String) -> bool:
	if _pairs.has(left_id):
		_pairs.erase(left_id)
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
