class_name QuestionGeneratorIdentity
extends RefCounted

## Utility for deterministic generated identity formatting, parsing, and collision checking.

static func build_generated_id(generator_spec_id: String, variant_key: String) -> String:
	return "qgen_" + generator_spec_id + "_" + variant_key

static func is_generated_id(question_id: String) -> bool:
	return question_id.begins_with("qgen_")

static func parse_generated_id(question_id: String) -> Dictionary:
	if not is_generated_id(question_id):
		return {"success": false, "raw_id": question_id, "spec_id": "", "variant_key": ""}
	
	var body: String = question_id.substr(5) # strip "qgen_"
	var last_idx: int = body.rfind("_")
	if last_idx <= 0 or last_idx >= body.length() - 1:
		return {"success": false, "raw_id": question_id, "spec_id": "", "variant_key": ""}
	
	var spec_id: String = body.left(last_idx)
	var variant_key: String = body.substr(last_idx + 1)
	
	return {
		"success": true,
		"raw_id": question_id,
		"spec_id": spec_id,
		"variant_key": variant_key
	}
