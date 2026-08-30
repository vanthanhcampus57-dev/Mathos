class_name MathKnowledgePack
extends RefCounted

## Model for MathKnowledgePack generic content schema.

var pack_id: String = ""
var schema_version: int = 1
var dungeon_id: String = ""
var topic_id: String = ""
var subtopic_id: String = ""
var domain_variables: Dictionary = {}
var math_rules: Variant = {}
var forbidden_concepts: Array = []
var prerequisite_concepts: Array = []

func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		pack_id = String(data.get("pack_id", ""))
		schema_version = int(data.get("schema_version", 1))
		dungeon_id = String(data.get("dungeon_id", ""))
		topic_id = String(data.get("topic_id", ""))
		subtopic_id = String(data.get("subtopic_id", ""))
		domain_variables = (data.get("domain_variables", {}) as Dictionary).duplicate(true)
		var raw_rules: Variant = data.get("math_rules", {})
		if raw_rules is Dictionary:
			math_rules = (raw_rules as Dictionary).duplicate(true)
		elif raw_rules is Array:
			math_rules = (raw_rules as Array).duplicate(true)
		else:
			math_rules = raw_rules
		forbidden_concepts = (data.get("forbidden_concepts", []) as Array).duplicate(true)
		prerequisite_concepts = (data.get("prerequisite_concepts", []) as Array).duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"schema_version": schema_version,
		"pack_id": pack_id,
		"dungeon_id": dungeon_id,
		"topic_id": topic_id,
		"subtopic_id": subtopic_id,
		"domain_variables": domain_variables.duplicate(true),
		"math_rules": math_rules.duplicate(true) if (math_rules is Dictionary or math_rules is Array) else math_rules,
		"forbidden_concepts": forbidden_concepts.duplicate(true),
		"prerequisite_concepts": prerequisite_concepts.duplicate(true)
	}

func get_pack_id() -> String:
	return pack_id

func get_dungeon_id() -> String:
	return dungeon_id

func get_topic_id() -> String:
	return topic_id

func get_subtopic_id() -> String:
	return subtopic_id

func get_domain_variables() -> Dictionary:
	return domain_variables.duplicate(true)

func get_math_rules() -> Variant:
	if math_rules is Dictionary or math_rules is Array:
		return math_rules.duplicate(true)
	return math_rules

func get_forbidden_concepts() -> Array:
	return forbidden_concepts.duplicate(true)

func get_prerequisite_concepts() -> Array:
	return prerequisite_concepts.duplicate(true)
