class_name QuestionGeneratorIdentity
extends RefCounted

## Utility for deterministic generated identity formatting, parsing, and collision checking.
## Enforces locked contract: qgen_<generator_spec_id>_<variant_key>
## Constraint: variant_key MUST match [a-z0-9-] and CANNOT contain underscores ("_").

static func is_valid_variant_key(variant_key: String) -> bool:
	if variant_key.is_empty():
		return false
	for i in range(variant_key.length()):
		var c: int = variant_key.unicode_at(i)
		var is_lower: bool = (c >= 97 and c <= 122) # a-z
		var is_digit: bool = (c >= 48 and c <= 57)  # 0-9
		var is_hyphen: bool = (c == 45)             # -
		if not (is_lower or is_digit or is_hyphen):
			return false
	return true

static func build_generated_id(generator_spec_id: String, variant_key: String) -> String:
	if generator_spec_id.is_empty() or not is_valid_variant_key(variant_key):
		return ""
	return "qgen_" + generator_spec_id + "_" + variant_key

static func is_generated_id(question_id: String) -> bool:
	return question_id.begins_with("qgen_")

static func parse_generated_id(question_id: String) -> Dictionary:
	if not is_generated_id(question_id):
		return {"success": false, "raw_id": question_id, "spec_id": "", "variant_key": "", "error": "Missing prefix"}
	
	var body: String = question_id.substr(5) # strip "qgen_"
	var last_idx: int = body.rfind("_")
	if last_idx <= 0 or last_idx >= body.length() - 1:
		return {"success": false, "raw_id": question_id, "spec_id": "", "variant_key": "", "error": "Malformed structure"}
	
	var spec_id: String = body.left(last_idx)
	var variant_key: String = body.substr(last_idx + 1)
	
	if spec_id.is_empty() or not is_valid_variant_key(variant_key):
		return {"success": false, "raw_id": question_id, "spec_id": spec_id, "variant_key": variant_key, "error": "Invalid variant_key or spec_id"}

	return {
		"success": true,
		"raw_id": question_id,
		"spec_id": spec_id,
		"variant_key": variant_key
	}
