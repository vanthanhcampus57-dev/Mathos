class_name PlayerStats
extends RefCounted

## Immutable baseline player stats copied from the already-validated GameConfig.

var _max_hp: int
var _starting_hp: int
var _hand_size: int

var max_hp: int:
	set(_value):
		assert(false, "PlayerStats is immutable after construction")
	get:
		return _max_hp

var starting_hp: int:
	set(_value):
		assert(false, "PlayerStats is immutable after construction")
	get:
		return _starting_hp

var hand_size: int:
	set(_value):
		assert(false, "PlayerStats is immutable after construction")
	get:
		return _hand_size

func _init(validated_config: Dictionary) -> void:
	var config_stats: Dictionary = validated_config.get("player_stats", {}) as Dictionary
	var configured_max_hp: int = int(config_stats.get("max_hp", 0))
	var configured_starting_hp: int = int(config_stats.get("starting_hp", 0))
	var configured_hand_size: int = int(config_stats.get("hand_size", 0))

	assert(configured_max_hp > 0, "PlayerStats.max_hp must be > 0")
	assert(configured_starting_hp >= 1 and configured_starting_hp <= configured_max_hp, "PlayerStats.starting_hp must be within 1..max_hp")
	assert(configured_hand_size > 0, "PlayerStats.hand_size must be > 0")

	_max_hp = configured_max_hp
	_starting_hp = configured_starting_hp
	_hand_size = configured_hand_size
