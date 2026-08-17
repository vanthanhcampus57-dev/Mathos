class_name StageCompletionResult
extends RefCounted

## Immutable result of one stage-clear commit attempt.

var _stage_id: String
var _reward_grant: RewardGrant
var _newly_unlocked_stage_ids: Array[String] = []
var _newly_unlocked_dungeon_ids: Array[String] = []
var _newly_collected_fragment_ids: Array[String] = []
var _game_complete_candidate: bool
var _progress_snapshot: ProgressState

var stage_id: String:
	set(_value):
		assert(false, "StageCompletionResult is immutable")
	get:
		return _stage_id

var reward_grant: RewardGrant:
	set(_value):
		assert(false, "StageCompletionResult is immutable")
	get:
		return _reward_grant

var newly_unlocked_stage_ids: Array[String]:
	set(_value):
		assert(false, "StageCompletionResult is immutable")
	get:
		return _copy_string_array(_newly_unlocked_stage_ids)

var newly_unlocked_dungeon_ids: Array[String]:
	set(_value):
		assert(false, "StageCompletionResult is immutable")
	get:
		return _copy_string_array(_newly_unlocked_dungeon_ids)

var newly_collected_fragment_ids: Array[String]:
	set(_value):
		assert(false, "StageCompletionResult is immutable")
	get:
		return _copy_string_array(_newly_collected_fragment_ids)

var game_complete_candidate: bool:
	set(_value):
		assert(false, "StageCompletionResult is immutable")
	get:
		return _game_complete_candidate

var progress_snapshot: ProgressState:
	set(_value):
		assert(false, "StageCompletionResult is immutable")
	get:
		return _progress_snapshot._copy()

func _init(
	p_stage_id: String,
	p_reward_grant: RewardGrant,
	p_newly_unlocked_stage_ids: Array[String],
	p_newly_unlocked_dungeon_ids: Array[String],
	p_newly_collected_fragment_ids: Array[String],
	p_game_complete_candidate: bool,
	p_progress_snapshot: ProgressState
) -> void:
	_stage_id = p_stage_id
	_reward_grant = p_reward_grant
	_newly_unlocked_stage_ids = _copy_string_array(p_newly_unlocked_stage_ids)
	_newly_unlocked_dungeon_ids = _copy_string_array(p_newly_unlocked_dungeon_ids)
	_newly_collected_fragment_ids = _copy_string_array(p_newly_collected_fragment_ids)
	_game_complete_candidate = p_game_complete_candidate
	_progress_snapshot = p_progress_snapshot._copy()

static func _copy_string_array(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(value)
	return result
