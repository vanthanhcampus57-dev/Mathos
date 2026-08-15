class_name ProgressState
extends RefCounted

## Single source of truth for committed progression.

var unlocked_dungeon_ids: Array[String] = []
var unlocked_stage_ids: Array[String] = []
var cleared_stage_ids: Array[String] = []
var fragment_ids: Array[String] = []
var game_complete: bool = false

func _init(
	p_unlocked_dungeon_ids: Array[String] = [],
	p_unlocked_stage_ids: Array[String] = [],
	p_cleared_stage_ids: Array[String] = [],
	p_fragment_ids: Array[String] = [],
	p_game_complete: bool = false
) -> void:
	unlocked_dungeon_ids = _copy_unique(p_unlocked_dungeon_ids)
	unlocked_stage_ids = _copy_unique(p_unlocked_stage_ids)
	cleared_stage_ids = _copy_unique(p_cleared_stage_ids)
	fragment_ids = _copy_unique(p_fragment_ids)
	game_complete = p_game_complete

func _copy() -> ProgressState:
	return ProgressState.new(
		unlocked_dungeon_ids,
		unlocked_stage_ids,
		cleared_stage_ids,
		fragment_ids,
		game_complete
	)

static func _copy_unique(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		assert(not result.has(value), "ProgressState arrays must contain unique IDs")
		result.append(value)
	return result
