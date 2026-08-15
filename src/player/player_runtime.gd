class_name PlayerRuntime
extends RefCounted

## Transient stage-lifetime player state. Never persisted in V1.

var stage_id: String
var max_hp: int
var current_hp: int
var shield: int = 0
var temporary_modifiers: Dictionary[String, float] = {}
var is_defeated: bool = false

func _init(p_stage_id: String, stats: PlayerStats) -> void:
	assert(p_stage_id != "", "PlayerRuntime.stage_id is required")
	stage_id = p_stage_id
	max_hp = stats.max_hp
	current_hp = stats.starting_hp
	shield = 0
	temporary_modifiers = {}
	is_defeated = false

func apply_damage(amount: int) -> void:
	assert(amount >= 0, "Damage amount must be >= 0")
	var remaining_damage: int = amount
	if shield > 0:
		var absorbed: int = min(shield, remaining_damage)
		shield -= absorbed
		remaining_damage -= absorbed
	current_hp = max(0, current_hp - remaining_damage)
	is_defeated = current_hp <= 0

func apply_shield(amount: int) -> void:
	assert(amount >= 0, "Shield amount must be >= 0")
	shield += amount

func heal(amount: int) -> void:
	assert(amount >= 0, "Heal amount must be >= 0")
	current_hp = min(max_hp, current_hp + amount)
	is_defeated = current_hp <= 0

func reset_stage_runtime(stats: PlayerStats) -> void:
	max_hp = stats.max_hp
	current_hp = stats.starting_hp
	shield = 0
	temporary_modifiers.clear()
	is_defeated = false
