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

static func is_valid_parameter_value(val: Variant) -> bool:
	if val == null:
		return true
	elif val is bool:
		return true
	elif val is int:
		return true
	elif val is float:
		var f_val: float = val as float
		return not (is_nan(f_val) or is_inf(f_val))
	elif val is String:
		return true
	elif val is Array:
		var arr: Array = val as Array
		for item in arr:
			if not is_valid_parameter_value(item):
				return false
		return true
	elif val is Dictionary:
		var dict: Dictionary = val as Dictionary
		for k in dict.keys():
			if not (k is String):
				return false
			if not is_valid_parameter_value(dict[k]):
				return false
		return true
	return false

static func canonical_serialize(val: Variant) -> String:
	if not is_valid_parameter_value(val):
		return ""
	if val == null:
		return "n;"
	elif val is bool:
		return "b:1;" if (val as bool) else "b:0;"
	elif val is int:
		return "i:" + str(val) + ";"
	elif val is float:
		var f_val: float = val as float
		var s: String = str(f_val)
		if not s.contains("."):
			s += ".0"
		return "f:" + s + ";"
	elif val is String:
		var s_val: String = val as String
		return "s:" + str(s_val.length()) + ":" + s_val + ";"
	elif val is Array:
		var arr: Array = val as Array
		var items: Array[String] = []
		for item in arr:
			var ser: String = canonical_serialize(item)
			if ser.is_empty():
				return ""
			items.append(ser)
		return "a:" + str(arr.size()) + ":[" + "".join(items) + "]"
	elif val is Dictionary:
		var dict: Dictionary = val as Dictionary
		var keys: Array = dict.keys()
		keys.sort()
		var pairs: Array[String] = []
		for k in keys:
			var ser_k: String = canonical_serialize(k)
			var ser_v: String = canonical_serialize(dict[k])
			if ser_k.is_empty() or ser_v.is_empty():
				return ""
			pairs.append(ser_k + ser_v)
		return "d:" + str(dict.size()) + ":{" + "".join(pairs) + "}"
	else:
		return ""

static func derive_variant_key(parameters: Dictionary) -> String:
	if parameters.is_empty():
		return "v-default"
	if not is_valid_parameter_value(parameters):
		return ""
	var serialized: String = canonical_serialize(parameters)
	if serialized.is_empty():
		return ""
	var md5_hash: String = serialized.md5_text().to_lower()
	return "v-" + md5_hash.substr(0, 12)

static func build_generated_id(generator_spec_id: String, variant_key: String) -> String:
	if generator_spec_id.is_empty() or not is_valid_variant_key(variant_key):
		return ""
	return "qgen_" + generator_spec_id + "_" + variant_key

static func build_generated_id_from_params(generator_spec_id: String, parameters: Dictionary) -> String:
	var v_key: String = derive_variant_key(parameters)
	return build_generated_id(generator_spec_id, v_key)

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

static func validate_batch_uniqueness(questions: Array[Dictionary]) -> Dictionary:
	var seen_ids: Dictionary = {}
	for i in range(questions.size()):
		var q: Dictionary = questions[i]
		var q_id: String = String(q.get("question_id", ""))
		if q_id.is_empty():
			return {"success": false, "error": "Empty question_id at index " + str(i)}
		if seen_ids.has(q_id):
			var first_index: int = seen_ids[q_id]
			return {
				"success": false,
				"error": "Duplicate generated question_id detected: '" + q_id + "' at indices " + str(first_index) + " and " + str(i),
				"duplicate_id": q_id,
				"first_index": first_index,
				"duplicate_index": i
			}
		seen_ids[q_id] = i
	return {"success": true, "count": questions.size()}
