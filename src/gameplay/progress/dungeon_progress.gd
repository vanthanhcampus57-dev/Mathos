class_name DungeonProgress
extends RefCounted

## Immutable derived per-dungeon view.

var _dungeon_id: String
var _is_unlocked: bool
var _cleared_stage_ids: Array[String] = []
var _is_complete: bool
var _fragment_id: Variant

var dungeon_id: String:
	set(_value):
		assert(false, "DungeonProgress is immutable")
	get:
		return _dungeon_id

var is_unlocked: bool:
	set(_value):
		assert(false, "DungeonProgress is immutable")
	get:
		return _is_unlocked

var cleared_stage_ids: Array[String]:
	set(_value):
		assert(false, "DungeonProgress is immutable")
	get:
		return _copy_string_array(_cleared_stage_ids)

var is_complete: bool:
	set(_value):
		assert(false, "DungeonProgress is immutable")
	get:
		return _is_complete

var fragment_id: Variant:
	set(_value):
		assert(false, "DungeonProgress is immutable")
	get:
		return _fragment_id

func _init(
	p_dungeon_id: String,
	p_is_unlocked: bool,
	p_cleared_stage_ids: Array[String],
	p_is_complete: bool,
	p_fragment_id: Variant = null
) -> void:
	_dungeon_id = p_dungeon_id
	_is_unlocked = p_is_unlocked
	_cleared_stage_ids = _copy_string_array(p_cleared_stage_ids)
	_is_complete = p_is_complete
	_fragment_id = p_fragment_id

static func _copy_string_array(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(value)
	return result
