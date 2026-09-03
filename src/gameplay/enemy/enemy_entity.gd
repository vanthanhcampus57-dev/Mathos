class_name EnemyEntity
extends RefCounted

## Runtime Entity representing an Enemy or Boss in Mathos Combat.
## Holds current HP, max HP, shield, intent sequence, and damage resolution.

var enemy_id: String = ""
var display_name: String = ""
var dungeon_id: String = ""
var role: String = "boss"
var max_hp: int = 100
var current_hp: int = 100
var shield: int = 0
var intents: Array = []
var current_intent_index: int = 0
var is_defeated: bool = false

func _init(
	p_enemy_id: String = "",
	p_display_name: String = "",
	p_max_hp: int = 100,
	p_intents: Array = [],
	p_role: String = "boss",
	p_dungeon_id: String = ""
) -> void:
	enemy_id = p_enemy_id
	display_name = p_display_name if not p_display_name.is_empty() else _format_default_name(p_enemy_id)
	max_hp = p_max_hp
	current_hp = p_max_hp
	shield = 0
	intents = p_intents.duplicate(true)
	current_intent_index = 0
	role = p_role
	dungeon_id = p_dungeon_id
	is_defeated = false

static func from_catalog(catalog: ValidatedCatalog, id: String) -> EnemyEntity:
	assert(catalog != null, "EnemyEntity.from_catalog requires ValidatedCatalog")
	var data: Dictionary = catalog.get_enemy(id)
	if data.is_empty():
		return null

	var e_id: String = String(data.get("enemy_id", id))
	var m_hp: int = int(data.get("max_hp", 100))
	var e_role: String = String(data.get("role", "boss"))
	var d_id: String = String(data.get("dungeon_id", ""))
	var raw_intents: Array = data.get("intents", []) as Array

	var d_name: String = "STOCHAS" if e_id == "enemy_d1_stochas" else _format_default_name(e_id)

	return EnemyEntity.new(e_id, d_name, m_hp, raw_intents, e_role, d_id)

func apply_damage(amount: int) -> int:
	assert(amount >= 0, "Damage amount must be >= 0")
	var remaining: int = amount
	if shield > 0:
		var absorbed: int = min(shield, remaining)
		shield -= absorbed
		remaining -= absorbed

	var hp_damage: int = min(current_hp, remaining)
	current_hp = max(0, current_hp - hp_damage)
	is_defeated = (current_hp <= 0)
	return hp_damage

func apply_shield(amount: int) -> void:
	assert(amount >= 0, "Shield amount must be >= 0")
	shield += amount

func heal(amount: int) -> void:
	assert(amount >= 0, "Heal amount must be >= 0")
	current_hp = min(max_hp, current_hp + amount)
	is_defeated = (current_hp <= 0)

func get_current_intent() -> Dictionary:
	if intents.is_empty():
		return {}
	var idx: int = current_intent_index % intents.size()
	return intents[idx] as Dictionary

func advance_intent() -> Dictionary:
	if intents.is_empty():
		return {}
	current_intent_index = (current_intent_index + 1) % intents.size()
	return get_current_intent()

func reset() -> void:
	current_hp = max_hp
	shield = 0
	current_intent_index = 0
	is_defeated = false

static func _format_default_name(raw_id: String) -> String:
	if raw_id == "enemy_d1_stochas":
		return "STOCHAS"
	elif raw_id == "enemy_d2_aleator":
		return "ALEATOR"
	elif raw_id == "enemy_d3_melkor":
		return "MELKOR"
	elif raw_id == "enemy_d4_aphodius":
		return "APHODIUS"
	return raw_id.trim_prefix("enemy_").capitalize()
