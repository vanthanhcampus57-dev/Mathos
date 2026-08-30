class_name QuestionGenerator
extends RefCounted

## Generic foundation interface for deterministic procedural question materialization.

const QuestionGeneratorIdentityScript = preload("res://src/education/question/generator/question_generator_identity.gd")

func get_family_id() -> String:
	return "base_generator"

func generate_question(spec: Dictionary, pack: Dictionary, variant_key: String = "", parameters: Dictionary = {}) -> Dictionary:
	var spec_id: String = String(spec.get("spec_id", "unknown_spec"))

	var effective_variant: String = variant_key
	if effective_variant.is_empty():
		effective_variant = QuestionGeneratorIdentityScript.derive_variant_key(parameters)

	var gen_id: String = QuestionGeneratorIdentityScript.build_generated_id(spec_id, effective_variant)

	var dungeon_id: String = String(spec.get("dungeon_id", ""))
	var topic_id: String = String(spec.get("topic_id", ""))
	var subtopic_id: String = String(spec.get("subtopic_id", ""))
	var itype: String = String(spec.get("interaction_type", "multiple_choice"))

	var tmpl: Dictionary = spec.get("template", {}) as Dictionary

	var prompt_str: String = format_template_string(String(tmpl.get("prompt", "")), parameters)
	var exp_str: String = format_template_string(String(tmpl.get("explanation", "")), parameters)
	var obj_str: String = format_template_string(String(tmpl.get("learning_objective", "")), parameters)

	var payload: Dictionary = format_template_dict(tmpl.get("interaction_payload", {}) as Dictionary, parameters)
	var answer_spec: Dictionary = format_template_dict(tmpl.get("answer_spec", {}) as Dictionary, parameters)

	var diff_range: Dictionary = spec.get("difficulty_range", {"min": 1, "max": 5}) as Dictionary
	var base_diff: int = int(diff_range.get("min", 1))
	var calc_diff: int = int(parameters.get("difficulty", base_diff))

	var question_def: Dictionary = {
		"schema_version": 1,
		"question_id": gen_id,
		"dungeon_id": dungeon_id,
		"topic_id": topic_id,
		"subtopic_id": subtopic_id,
		"learning_objective": obj_str,
		"prompt": prompt_str,
		"explanation": exp_str,
		"difficulty": calc_diff,
		"interaction_type": itype,
		"interaction_payload": payload,
		"answer_spec": answer_spec,
		"allowed_contexts": tmpl.get("allowed_contexts", ["lesson_check", "practice", "combat"]),
		"hints": tmpl.get("hints", []),
		"tags": [dungeon_id, subtopic_id, "procedural"],
		"prerequisite_ids": [],
		"asset_refs": [],
		"adaptive_metadata": {
			"skill_ids": [subtopic_id],
			"generator_spec_id": spec_id,
			"variant_key": effective_variant
		}
	}

	return question_def

func generate_batch(spec: Dictionary, pack: Dictionary, parameter_tuples: Array[Dictionary]) -> Dictionary:
	var questions: Array[Dictionary] = []
	var seen_ids: Dictionary = {}

	for i in range(parameter_tuples.size()):
		var params: Dictionary = parameter_tuples[i]
		var q: Dictionary = generate_question(spec, pack, "", params)
		var q_id: String = String(q.get("question_id", ""))

		if q_id.is_empty():
			return {
				"success": false,
				"error": "Generated question_id is empty or invalid at parameter index " + str(i),
				"duplicate_id": "",
				"questions": []
			}

		if seen_ids.has(q_id):
			var first_idx: int = seen_ids[q_id]
			return {
				"success": false,
				"error": "Duplicate generated question_id detected: '" + q_id + "' at indices " + str(first_idx) + " and " + str(i),
				"duplicate_id": q_id,
				"first_index": first_idx,
				"duplicate_index": i,
				"questions": []
			}

		seen_ids[q_id] = i
		questions.append(q)

	return {
		"success": true,
		"questions": questions,
		"count": questions.size()
	}

static func format_template_string(template_text: String, parameters: Dictionary) -> String:
	var result: String = template_text
	for key in parameters:
		var placeholder: String = "{" + str(key) + "}"
		if result.contains(placeholder):
			result = result.replace(placeholder, str(parameters[key]))
	return result

static func format_template_dict(dict_template: Dictionary, parameters: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for k in dict_template:
		var val: Variant = dict_template[k]
		if val is String:
			result[k] = format_template_string(val as String, parameters)
		elif val is Dictionary:
			result[k] = format_template_dict(val as Dictionary, parameters)
		elif val is Array:
			result[k] = format_template_array(val as Array, parameters)
		else:
			result[k] = val
	return result

static func format_template_array(arr_template: Array, parameters: Dictionary) -> Array:
	var result: Array = []
	for item in arr_template:
		if item is String:
			result.append(format_template_string(item as String, parameters))
		elif item is Dictionary:
			result.append(format_template_dict(item as Dictionary, parameters))
		elif item is Array:
			result.append(format_template_array(item as Array, parameters))
		else:
			result.append(item)
	return result
