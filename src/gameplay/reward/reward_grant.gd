class_name RewardGrant
extends RefCounted

## Immutable value result produced by the future RewardService and consumed by
## the stage-completion commit boundary. This class performs no reward lookup,
## calculation, persistence, progression mutation, or UI work.

var _reward_id: String
var _stage_id: String
var _coin_delta: int
var _exp_delta: int
var _fragment_ids: Array[String] = []

var reward_id: String:
	set(_value):
		assert(false, "RewardGrant is immutable after construction")
	get:
		return _reward_id

var stage_id: String:
	set(_value):
		assert(false, "RewardGrant is immutable after construction")
	get:
		return _stage_id

var coin_delta: int:
	set(_value):
		assert(false, "RewardGrant is immutable after construction")
	get:
		return _coin_delta

var exp_delta: int:
	set(_value):
		assert(false, "RewardGrant is immutable after construction")
	get:
		return _exp_delta

var fragment_ids: Array[String]:
	set(_value):
		assert(false, "RewardGrant is immutable after construction")
	get:
		return _copy_string_array(_fragment_ids)

func _init(
	p_reward_id: String,
	p_stage_id: String,
	p_coin_delta: int,
	p_exp_delta: int,
	p_fragment_ids: Array[String]
) -> void:
	assert(p_coin_delta >= 0, "RewardGrant.coin_delta must be >= 0")
	assert(p_exp_delta >= 0, "RewardGrant.exp_delta must be >= 0")
	assert(_contains_unique_values(p_fragment_ids), "RewardGrant.fragment_ids must be unique")

	_reward_id = p_reward_id
	_stage_id = p_stage_id
	_coin_delta = p_coin_delta
	_exp_delta = p_exp_delta
	_fragment_ids = _copy_string_array(p_fragment_ids)

static func _contains_unique_values(values: Array[String]) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if seen.has(value):
			return false
		seen[value] = true
	return true

static func _copy_string_array(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(value)
	return result
