class_name GeneratorRegistry
extends RefCounted

## Registry for managing registered QuestionGenerator instances by family_id.

const QuestionGeneratorScript = preload("res://src/education/question/generator/question_generator.gd")

var _generators: Dictionary = {} # family_id -> QuestionGenerator

func register_generator(family_id: String, generator: RefCounted) -> void:
	_generators[family_id] = generator

func get_generator(family_id: String) -> RefCounted:
	if _generators.has(family_id):
		return _generators[family_id] as RefCounted
	return null

func has_generator(family_id: String) -> bool:
	return _generators.has(family_id)

func clear() -> void:
	_generators.clear()

func get_all_registered_family_ids() -> Array[String]:
	var result: Array[String] = []
	for fid in _generators:
		result.append(String(fid))
	return result
