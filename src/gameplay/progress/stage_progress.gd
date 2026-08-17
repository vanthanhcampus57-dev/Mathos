class_name StageProgress
extends RefCounted

## Immutable derived per-stage view.

var _stage_id: String
var _is_unlocked: bool
var _is_cleared: bool

var stage_id: String:
	set(_value):
		assert(false, "StageProgress is immutable")
	get:
		return _stage_id

var is_unlocked: bool:
	set(_value):
		assert(false, "StageProgress is immutable")
	get:
		return _is_unlocked

var is_cleared: bool:
	set(_value):
		assert(false, "StageProgress is immutable")
	get:
		return _is_cleared

func _init(p_stage_id: String, p_is_unlocked: bool, p_is_cleared: bool) -> void:
	_stage_id = p_stage_id
	_is_unlocked = p_is_unlocked
	_is_cleared = p_is_cleared
