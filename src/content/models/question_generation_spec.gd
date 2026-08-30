class_name QuestionGenerationSpec
extends RefCounted

## Model for QuestionGenerationSpec generic content schema.

var spec_id: String = ""
var schema_version: int = 1
var generator_family_id: String = ""
var pack_id: String = ""
var dungeon_id: String = ""
var topic_id: String = ""
var subtopic_id: String = ""
var difficulty_range: Dictionary = {"min": 1, "max": 5}
var interaction_type: String = "multiple_choice"
var template: Dictionary = {}
var parameter_bindings: Variant = {}

func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		spec_id = String(data.get("spec_id", ""))
		schema_version = int(data.get("schema_version", 1))
		generator_family_id = String(data.get("generator_family_id", ""))
		pack_id = String(data.get("pack_id", ""))
		dungeon_id = String(data.get("dungeon_id", ""))
		topic_id = String(data.get("topic_id", ""))
		subtopic_id = String(data.get("subtopic_id", ""))
		difficulty_range = (data.get("difficulty_range", {"min": 1, "max": 5}) as Dictionary).duplicate(true)
		interaction_type = String(data.get("interaction_type", "multiple_choice"))
		template = (data.get("template", {}) as Dictionary).duplicate(true)
		var raw_bind: Variant = data.get("parameter_bindings", {})
		if raw_bind is Dictionary:
			parameter_bindings = (raw_bind as Dictionary).duplicate(true)
		elif raw_bind is Array:
			parameter_bindings = (raw_bind as Array).duplicate(true)
		else:
			parameter_bindings = raw_bind


func to_dictionary() -> Dictionary:
	return {
		"schema_version": schema_version,
		"spec_id": spec_id,
		"generator_family_id": generator_family_id,
		"pack_id": pack_id,
		"dungeon_id": dungeon_id,
		"topic_id": topic_id,
		"subtopic_id": subtopic_id,
		"difficulty_range": difficulty_range.duplicate(true),
		"interaction_type": interaction_type,
		"template": template.duplicate(true),
		"parameter_bindings": parameter_bindings.duplicate(true) if (parameter_bindings is Dictionary or parameter_bindings is Array) else parameter_bindings
	}

func get_spec_id() -> String:
	return spec_id

func get_generator_family_id() -> String:
	return generator_family_id

func get_pack_id() -> String:
	return pack_id

func get_dungeon_id() -> String:
	return dungeon_id

func get_topic_id() -> String:
	return topic_id

func get_subtopic_id() -> String:
	return subtopic_id

func get_difficulty_range() -> Dictionary:
	return difficulty_range.duplicate(true)

func get_interaction_type() -> String:
	return interaction_type

func get_template() -> Dictionary:
	return template.duplicate(true)

func get_parameter_bindings() -> Variant:
	if parameter_bindings is Dictionary or parameter_bindings is Array:
		return parameter_bindings.duplicate(true)
	return parameter_bindings
