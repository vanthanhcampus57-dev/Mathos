class_name QuestionEvaluator
extends RefCounted

## Pure correctness and grade evaluator for one validated QuestionDefinition.
## It never mutates Combat, Player, Progress, Save, or Adaptive state.

const RESULT_FIELDS: Array[String] = [
	"attempt_id", "question_id", "stage_id", "dungeon_id", "topic_id", "subtopic_id",
	"context", "difficulty", "is_correct", "performance_grade", "elapsed_seconds", "feedback_text"
]

static func evaluate(
	question: Dictionary,
	submitted_payload: Dictionary,
	stage_id: String,
	context: String,
	elapsed_seconds: float,
	thresholds: Dictionary,
	attempt_id: String
) -> Dictionary:
	var definition_error: String = _validate_definition_common(question)
	if definition_error != "":
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, definition_error)
	if not (submitted_payload is Dictionary):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "submitted_payload must be a Dictionary")
	if elapsed_seconds < 0.0:
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "elapsed_seconds must be >= 0")

	var correctness: Dictionary
	match String(question["interaction_type"]):
		"multiple_choice":
			correctness = _evaluate_multiple_choice(question, submitted_payload)
		"drag_drop":
			correctness = _evaluate_drag_drop(question, submitted_payload)
		"matching":
			correctness = _evaluate_matching(question, submitted_payload)
		"input":
			correctness = _evaluate_input(question, submitted_payload)
		_:
			return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "Unsupported interaction_type")

	if not bool(correctness.get("success", false)):
		return correctness

	var is_correct: bool = bool(correctness["is_correct"])
	var grade_result: Dictionary = _grade(question, is_correct, elapsed_seconds, thresholds)
	if not bool(grade_result.get("success", false)):
		return grade_result

	var result: Dictionary = {
		"attempt_id": attempt_id,
		"question_id": String(question["question_id"]),
		"stage_id": stage_id,
		"dungeon_id": String(question["dungeon_id"]),
		"topic_id": String(question["topic_id"]),
		"subtopic_id": String(question["subtopic_id"]),
		"context": context,
		"difficulty": int(question["difficulty"]),
		"is_correct": is_correct,
		"performance_grade": String(grade_result["grade"]),
		"elapsed_seconds": elapsed_seconds,
		"feedback_text": String(question["explanation"])
	}
	return {"success": true, "result": result}

static func _validate_definition_common(question: Dictionary) -> String:
	for field in ["question_id", "dungeon_id", "topic_id", "subtopic_id", "difficulty", "interaction_type", "interaction_payload", "answer_spec", "explanation"]:
		if not question.has(field):
			return "QuestionDefinition missing required field " + String(field)
	if not (question["interaction_payload"] is Dictionary) or not (question["answer_spec"] is Dictionary):
		return "QuestionDefinition interaction_payload/answer_spec must be dictionaries"
	if not (question["explanation"] is String) or String(question["explanation"]).is_empty():
		return "QuestionDefinition explanation must be non-empty"
	if int(question["difficulty"]) < 1 or int(question["difficulty"]) > 5:
		return "QuestionDefinition difficulty must be 1..5"
	return ""

static func _evaluate_multiple_choice(question: Dictionary, payload: Dictionary) -> Dictionary:
	if not _has_exact_fields(payload, ["selected_option_id"]):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "multiple_choice payload requires only selected_option_id")
	if not (payload["selected_option_id"] is String):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "selected_option_id must be String")
	var interaction: Dictionary = question["interaction_payload"] as Dictionary
	var answer: Dictionary = question["answer_spec"] as Dictionary
	if not interaction.has("options") or not (interaction["options"] is Array) or not _has_exact_fields(answer, ["correct_option_id"]):
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "Invalid multiple_choice definition")
	if not (answer["correct_option_id"] is String):
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "correct_option_id must be String")
	var option_ids: Dictionary = _collect_ids(interaction["options"] as Array, "option_id")
	if option_ids.is_empty() or not option_ids.has(String(answer["correct_option_id"])):
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "multiple_choice option IDs are invalid")
	var selected: String = String(payload["selected_option_id"])
	if not option_ids.has(selected):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "Unknown selected_option_id")
	return {"success": true, "is_correct": selected == String(answer["correct_option_id"])}

static func _evaluate_drag_drop(question: Dictionary, payload: Dictionary) -> Dictionary:
	if not _has_exact_fields(payload, ["placements"]) or not (payload["placements"] is Array):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "drag_drop payload requires placements Array")
	var interaction: Dictionary = question["interaction_payload"] as Dictionary
	var answer: Dictionary = question["answer_spec"] as Dictionary
	if not interaction.has("items") or not (interaction["items"] is Array) or not interaction.has("targets") or not (interaction["targets"] is Array):
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "Invalid drag_drop interaction payload")
	if not _has_exact_fields(answer, ["mappings"]) or not (answer["mappings"] is Array):
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "drag_drop answer_spec.mappings is required")
	var item_ids: Dictionary = _collect_ids(interaction["items"] as Array, "item_id")
	var target_ids: Dictionary = _collect_ids(interaction["targets"] as Array, "target_id")
	if item_ids.is_empty() or target_ids.is_empty():
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "Invalid drag_drop item/target IDs")

	var ground: Dictionary = _normalize_mapping_pairs(answer["mappings"] as Array, "item_id", "target_id", item_ids, target_ids, false)
	if not bool(ground.get("success", false)):
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, String(ground.get("error_message", "Invalid mappings")))
	if bool(interaction.get("must_place_all", true)) and (ground["mapping"] as Dictionary).size() != item_ids.size():
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "must_place_all definition requires every item exactly once")
	var submitted: Dictionary = _normalize_mapping_pairs(payload["placements"] as Array, "item_id", "target_id", item_ids, target_ids, false)
	if not bool(submitted.get("success", false)):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, String(submitted.get("error_message", "Invalid placements")))

	var must_place_all: bool = bool(interaction.get("must_place_all", true))
	var submitted_map: Dictionary = submitted["mapping"] as Dictionary
	if must_place_all and submitted_map.size() != item_ids.size():
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "must_place_all requires every item exactly once")
	return {"success": true, "is_correct": submitted_map == (ground["mapping"] as Dictionary)}

static func _evaluate_matching(question: Dictionary, payload: Dictionary) -> Dictionary:
	if not _has_exact_fields(payload, ["pairs"]) or not (payload["pairs"] is Array):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "matching payload requires pairs Array")
	var interaction: Dictionary = question["interaction_payload"] as Dictionary
	var answer: Dictionary = question["answer_spec"] as Dictionary
	if not interaction.has("left_items") or not (interaction["left_items"] is Array) or not interaction.has("right_items") or not (interaction["right_items"] is Array):
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "Invalid matching interaction payload")
	if not _has_exact_fields(answer, ["pairs"]) or not (answer["pairs"] is Array):
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "matching answer_spec.pairs is required")
	var left_ids: Dictionary = _collect_ids(interaction["left_items"] as Array, "item_id")
	var right_ids: Dictionary = _collect_ids(interaction["right_items"] as Array, "item_id")
	if left_ids.is_empty() or right_ids.is_empty():
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "Invalid matching left/right IDs")

	var ground: Dictionary = _normalize_matching_pairs(answer["pairs"] as Array, left_ids, right_ids)
	if not bool(ground.get("success", false)) or (ground["mapping"] as Dictionary).size() != left_ids.size():
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "answer_spec.pairs must be complete one-to-one ground truth")
	var submitted: Dictionary = _normalize_matching_pairs(payload["pairs"] as Array, left_ids, right_ids)
	if not bool(submitted.get("success", false)):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, String(submitted.get("error_message", "Invalid matching pairs")))
	# A well-formed incomplete subset is a valid attempt and simply evaluates incorrect.
	return {"success": true, "is_correct": (submitted["mapping"] as Dictionary) == (ground["mapping"] as Dictionary)}

static func _evaluate_input(question: Dictionary, payload: Dictionary) -> Dictionary:
	if not _has_exact_fields(payload, ["value"]):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "input payload requires only value")
	var interaction: Dictionary = question["interaction_payload"] as Dictionary
	var answer: Dictionary = question["answer_spec"] as Dictionary
	var allowed_answer_fields: Array[String] = ["accepted_values", "numeric_tolerance", "case_sensitive", "trim_whitespace"]
	if not interaction.has("input_type") or not (interaction["input_type"] is String):
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "input_type is required")
	if not _has_only_fields(answer, allowed_answer_fields) or not answer.has("accepted_values") or not (answer["accepted_values"] is Array) or (answer["accepted_values"] as Array).is_empty():
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "input answer_spec.accepted_values is required")

	var input_type: String = String(interaction["input_type"])
	var normalized_submission: Dictionary = _normalize_input_value(payload["value"], input_type, bool(answer.get("trim_whitespace", true)), bool(answer.get("case_sensitive", false)))
	if not bool(normalized_submission.get("success", false)):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "Submitted input cannot be parsed for input_type")

	var tolerance_variant: Variant = answer.get("numeric_tolerance", null)
	var tolerance: float = 0.0
	if tolerance_variant != null:
		if not (tolerance_variant is int or tolerance_variant is float) or float(tolerance_variant) < 0.0:
			return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "numeric_tolerance must be null or >= 0")
		tolerance = float(tolerance_variant)

	for accepted_variant in answer["accepted_values"] as Array:
		var normalized_accepted: Dictionary = _normalize_input_value(accepted_variant, input_type, bool(answer.get("trim_whitespace", true)), bool(answer.get("case_sensitive", false)))
		if not bool(normalized_accepted.get("success", false)):
			return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "accepted_values contains incompatible value")
		if input_type == "integer" or input_type == "float":
			if abs(float(normalized_submission["value"]) - float(normalized_accepted["value"])) <= tolerance:
				return {"success": true, "is_correct": true}
		elif normalized_submission["value"] == normalized_accepted["value"]:
			return {"success": true, "is_correct": true}
	return {"success": true, "is_correct": false}

static func _normalize_input_value(value: Variant, input_type: String, trim_whitespace: bool, case_sensitive: bool) -> Dictionary:
	match input_type:
		"integer":
			if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
				return {"success": true, "value": int(value)}
			if typeof(value) == TYPE_STRING:
				var str_val: String = String(value)
				if trim_whitespace:
					str_val = str_val.strip_edges()
				if str_val.is_valid_int():
					return {"success": true, "value": str_val.to_int()}
		"float":
			if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
				return {"success": true, "value": float(value)}
			if typeof(value) == TYPE_STRING:
				var str_val: String = String(value)
				if trim_whitespace:
					str_val = str_val.strip_edges()
				if str_val.is_valid_float():
					return {"success": true, "value": str_val.to_float()}
		"string", "symbol":
			if typeof(value) == TYPE_STRING:
				var normalized: String = String(value)
				if trim_whitespace:
					normalized = normalized.strip_edges()
				if not case_sensitive:
					normalized = normalized.to_lower()
				return {"success": true, "value": normalized}
	return {"success": false}

static func _grade(question: Dictionary, is_correct: bool, elapsed_seconds: float, thresholds: Dictionary) -> Dictionary:
	if not is_correct:
		return {"success": true, "grade": "fail"}
	var estimate: Variant = question.get("estimated_time_seconds", null)
	if estimate == null:
		return {"success": true, "grade": "b"}
	if not (estimate is int or estimate is float) or float(estimate) <= 0.0:
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "estimated_time_seconds must be null or > 0")
	if not thresholds.has("a_max_time_ratio") or not thresholds.has("b_max_time_ratio"):
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "performance grade thresholds unavailable")
	var a_ratio: float = float(thresholds["a_max_time_ratio"])
	var b_ratio: float = float(thresholds["b_max_time_ratio"])
	if a_ratio <= 0.0 or b_ratio <= a_ratio:
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "performance grade thresholds invalid")
	var ratio: float = elapsed_seconds / float(estimate)
	if ratio <= a_ratio:
		return {"success": true, "grade": "a"}
	if ratio <= b_ratio:
		return {"success": true, "grade": "b"}
	return {"success": true, "grade": "c"}

static func _collect_ids(items: Array, field: String) -> Dictionary:
	var ids: Dictionary = {}
	for item_variant in items:
		if not (item_variant is Dictionary):
			return {}
		var item: Dictionary = item_variant as Dictionary
		if not item.has(field) or not (item[field] is String):
			return {}
		var item_id: String = String(item[field])
		if item_id.is_empty() or ids.has(item_id):
			return {}
		ids[item_id] = true
	return ids

static func _normalize_mapping_pairs(
	pairs: Array,
	left_field: String,
	right_field: String,
	valid_left: Dictionary,
	valid_right: Dictionary,
	require_unique_right: bool
) -> Dictionary:
	var mapping: Dictionary = {}
	var seen_right: Dictionary = {}
	for pair_variant in pairs:
		if not (pair_variant is Dictionary):
			return {"success": false, "error_message": "pair must be Dictionary"}
		var pair: Dictionary = pair_variant as Dictionary
		if not _has_exact_fields(pair, [left_field, right_field]):
			return {"success": false, "error_message": "pair has wrong fields"}
		if not (pair[left_field] is String) or not (pair[right_field] is String):
			return {"success": false, "error_message": "pair IDs must be String"}
		var left_id: String = String(pair[left_field])
		var right_id: String = String(pair[right_field])
		if not valid_left.has(left_id) or not valid_right.has(right_id):
			return {"success": false, "error_message": "pair contains unknown ID"}
		if mapping.has(left_id):
			return {"success": false, "error_message": "duplicate left assignment"}
		if require_unique_right and seen_right.has(right_id):
			return {"success": false, "error_message": "duplicate right assignment"}
		mapping[left_id] = right_id
		seen_right[right_id] = true
	return {"success": true, "mapping": mapping}

static func _normalize_matching_pairs(pairs: Array, left_ids: Dictionary, right_ids: Dictionary) -> Dictionary:
	return _normalize_mapping_pairs(pairs, "left_id", "right_id", left_ids, right_ids, true)

static func _has_exact_fields(data: Dictionary, fields: Array[String]) -> bool:
	if data.size() != fields.size():
		return false
	for field in fields:
		if not data.has(field):
			return false
	return true

static func _has_only_fields(data: Dictionary, fields: Array[String]) -> bool:
	for key_variant in data.keys():
		if not fields.has(String(key_variant)):
			return false
	return true

static func _error(code: String, message: String) -> Dictionary:
	return {"success": false, "error_code": code, "error_message": message}
