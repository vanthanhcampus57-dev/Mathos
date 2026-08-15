class_name QuestionService
extends RefCounted

## Owns QuestionSession lifecycle, hard scope enforcement, deterministic selection,
## presentation-safe question exposure, and QuestionEvaluator handoff.

const TOPIC_BY_DUNGEON: Dictionary = {
	"dungeon_01": "trial_sample_event",
	"dungeon_02": "classical_probability",
	"dungeon_03": "addition_rule",
	"dungeon_04": "multiplication_independence"
}
const SUBTOPICS_BY_TOPIC: Dictionary = {
	"trial_sample_event": ["random_trial", "sample_space", "event_subset", "event_classification", "counting_outcomes"],
	"classical_probability": ["equally_likely", "classical_probability_formula", "probability_representation", "compare_probability", "multi_data_classical"],
	"addition_rule": ["union_intersection", "mutually_exclusive", "addition_simple", "addition_general", "addition_selection"],
	"multiplication_independence": ["independence", "tree_diagram", "multiplication_two_step", "multiplication_chain", "independence_application"]
}
const INTERACTION_TYPES: Array[String] = ["multiple_choice", "drag_drop", "matching", "input"]
const CONTEXTS: Array[String] = ["lesson_check", "practice", "combat"]
const REQUEST_FIELDS: Array[String] = ["request_id", "stage_id", "scope", "context", "preferred_difficulty", "exclude_question_ids"]
const SCOPE_FIELDS: Array[String] = ["dungeon_id", "topic_id", "subtopic_ids", "difficulty_min", "difficulty_max", "interaction_types"]
const PRESENTATION_FIELDS: Array[String] = [
	"question_id", "dungeon_id", "topic_id", "subtopic_id", "learning_objective", "difficulty",
	"interaction_type", "prompt", "interaction_payload", "hints", "estimated_time_seconds", "tags",
	"story_context", "allowed_contexts"
]

var _catalog: ValidatedCatalog
var _clock_msec: Callable
var _active_session: QuestionSession = null
var _active_question: Dictionary = {}
var _active_stage_id: String = ""
var _session_counter: int = 0
var _attempt_counter: int = 0

func _init(p_catalog: ValidatedCatalog, p_clock_msec: Callable = Callable()) -> void:
	_catalog = p_catalog
	_clock_msec = p_clock_msec

func request_question(request: Dictionary, adaptive_recommendation: Dictionary = {}) -> Dictionary:
	if _active_session != null:
		return _error(QuestionErrorCodes.INVALID_QUESTION_SESSION, "An active QuestionSession already exists")
	var request_error: String = _validate_request(request)
	if request_error != "":
		return _error(QuestionErrorCodes.INVALID_QUESTION, request_error)

	var stage_id: String = String(request["stage_id"])
	var stage: Dictionary = _catalog.get_stage(stage_id)
	if stage.is_empty() or not stage.has("question_scope") or not (stage["question_scope"] is Dictionary):
		return _error(QuestionErrorCodes.INVALID_QUESTION, "Active stage lacks canonical question_scope")
	var request_scope: Dictionary = (request["scope"] as Dictionary).duplicate(true)
	var stage_scope: Dictionary = stage["question_scope"] as Dictionary
	var stage_scope_error: String = _validate_scope(stage_scope)
	if stage_scope_error != "":
		return _error(QuestionErrorCodes.INVALID_QUESTION, "Stage question_scope invalid: " + stage_scope_error)
	if not _scope_is_equal_or_narrower(request_scope, stage_scope):
		return _error(QuestionErrorCodes.INVALID_QUESTION, "QuestionRequest scope exceeds active Stage question_scope")

	var context: String = String(request["context"])
	var candidates: Array[Dictionary] = _catalog.query_questions(request_scope, context)
	candidates = _apply_request_filters(candidates, request_scope, request["exclude_question_ids"] as Array)
	candidates = _runtime_usable_candidates(candidates)
	if candidates.is_empty():
		return _error(QuestionErrorCodes.NO_VALID_QUESTION, "No valid question remains inside caller scope")

	var target_difficulty: int = _base_target_difficulty(request)
	var preferred_subtopics: Array[String] = []
	if not adaptive_recommendation.is_empty() and _is_valid_narrowing_recommendation(adaptive_recommendation, request_scope):
		var adaptive_scope: Dictionary = adaptive_recommendation["scope"] as Dictionary
		var narrowed: Array[Dictionary] = _filter_candidates_to_scope(candidates, adaptive_scope)
		# Adaptive is advisory: exhaustion of a legal narrowing falls back to the original caller scope.
		if not narrowed.is_empty():
			candidates = narrowed
			target_difficulty = int(adaptive_recommendation["target_difficulty"])
			preferred_subtopics = _string_array(adaptive_recommendation.get("preferred_subtopic_ids", []))

	var selected: Dictionary = _select_deterministically(candidates, target_difficulty, preferred_subtopics)
	if selected.is_empty():
		return _error(QuestionErrorCodes.NO_VALID_QUESTION, "Question candidate exhaustion inside caller scope")

	_session_counter += 1
	var session_id: String = "question_session_%06d" % _session_counter
	_active_session = QuestionSession.new(
		session_id,
		String(request["request_id"]),
		String(selected["question_id"]),
		context,
		_now_msec()
	)
	_active_question = selected.duplicate(true)
	_active_stage_id = stage_id
	return {
		"success": true,
		"session": _active_session.to_dictionary(),
		"question": _presentation_view(selected)
	}

func submit_answer(answer_payload: Dictionary) -> Dictionary:
	if _active_session == null or _active_question.is_empty():
		return _error(QuestionErrorCodes.INVALID_QUESTION_SESSION, "No active QuestionSession")
	if _active_session.submission_locked or _active_session.completed:
		return _error(QuestionErrorCodes.INVALID_QUESTION_SESSION, "QuestionSession submission is already complete")
	if not _has_exact_fields(answer_payload, ["session_id", "interaction_type", "payload"]):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "AnswerPayload requires session_id, interaction_type, payload")
	if not (answer_payload["session_id"] is String) or String(answer_payload["session_id"]) != _active_session.session_id:
		return _error(QuestionErrorCodes.INVALID_QUESTION_SESSION, "AnswerPayload session_id does not match active session")
	if not (answer_payload["interaction_type"] is String) or String(answer_payload["interaction_type"]) != String(_active_question["interaction_type"]):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "AnswerPayload interaction_type does not match active question")
	if not (answer_payload["payload"] is Dictionary):
		return _error(QuestionErrorCodes.INVALID_ANSWER_SHAPE, "AnswerPayload.payload must be Dictionary")

	var config: Dictionary = _catalog.get_config()
	if not config.has("performance_grade_thresholds") or not (config["performance_grade_thresholds"] is Dictionary):
		return _error(QuestionErrorCodes.INVALID_QUESTION_DEFINITION, "Validated GameConfig performance_grade_thresholds unavailable")
	var elapsed_seconds: float = max(0.0, float(_now_msec() - _active_session.started_at_msec) / 1000.0)
	_attempt_counter += 1
	var attempt_id: String = "question_attempt_%06d" % _attempt_counter
	var evaluation: Dictionary = QuestionEvaluator.evaluate(
		_active_question,
		answer_payload["payload"] as Dictionary,
		_active_stage_id,
		_active_session.context,
		elapsed_seconds,
		config["performance_grade_thresholds"] as Dictionary,
		attempt_id
	)
	if not bool(evaluation.get("success", false)):
		# Malformed submissions do not consume the active session; callers may safely correct and resubmit.
		return evaluation

	_active_session.submission_locked = true
	_active_session.completed = true
	var result: Dictionary = (evaluation["result"] as Dictionary).duplicate(true)
	_active_session = null
	_active_question = {}
	_active_stage_id = ""
	return {"success": true, "result": result}

func get_active_session() -> Dictionary:
	if _active_session == null:
		return {}
	return _active_session.to_dictionary()

func has_active_session() -> bool:
	return _active_session != null

func _validate_request(request: Dictionary) -> String:
	if not _has_exact_fields(request, REQUEST_FIELDS):
		return "QuestionRequest fields do not match V1 contract"
	if not (request["request_id"] is String) or String(request["request_id"]).is_empty():
		return "request_id must be non-empty String"
	if not (request["stage_id"] is String) or String(request["stage_id"]).is_empty():
		return "stage_id must be non-empty String"
	if not (request["scope"] is Dictionary):
		return "scope must be QuestionScope Dictionary"
	var scope_error: String = _validate_scope(request["scope"] as Dictionary)
	if scope_error != "":
		return scope_error
	if not (request["context"] is String) or not CONTEXTS.has(String(request["context"])):
		return "context must be lesson_check, practice, or combat"
	var preferred: Variant = request["preferred_difficulty"]
	if preferred != null and (not (preferred is int) or int(preferred) < 1 or int(preferred) > 5):
		return "preferred_difficulty must be null or int 1..5"
	if not (request["exclude_question_ids"] is Array) or not _array_is_unique_strings(request["exclude_question_ids"] as Array):
		return "exclude_question_ids must contain unique String IDs"
	return ""

func _validate_scope(scope: Dictionary) -> String:
	if scope.has("subtopics"):
		return "legacy subtopics key is not a canonical QuestionScope field"
	if not _has_exact_fields(scope, SCOPE_FIELDS):
		return "QuestionScope fields do not match V1 contract"
	if not (scope["dungeon_id"] is String) or not (scope["topic_id"] is String):
		return "QuestionScope dungeon_id/topic_id must be String"
	var dungeon_id: String = String(scope["dungeon_id"])
	var topic_id: String = String(scope["topic_id"])
	if not TOPIC_BY_DUNGEON.has(dungeon_id) or String(TOPIC_BY_DUNGEON[dungeon_id]) != topic_id:
		return "QuestionScope dungeon/topic combination is not canonical"
	if not (scope["subtopic_ids"] is Array) or not _array_is_unique_strings(scope["subtopic_ids"] as Array):
		return "subtopic_ids must contain unique String IDs"
	var canonical_subtopics: Array = SUBTOPICS_BY_TOPIC.get(topic_id, [])
	for subtopic_variant in scope["subtopic_ids"] as Array:
		if not canonical_subtopics.has(String(subtopic_variant)):
			return "subtopic_id is outside canonical topic"
	if not (scope["difficulty_min"] is int) or not (scope["difficulty_max"] is int):
		return "difficulty_min/max must be int"
	var min_diff: int = int(scope["difficulty_min"])
	var max_diff: int = int(scope["difficulty_max"])
	if min_diff < 1 or max_diff > 5 or min_diff > max_diff:
		return "QuestionScope difficulty range must be inside 1..5"
	if not (scope["interaction_types"] is Array) or not _array_is_unique_strings(scope["interaction_types"] as Array):
		return "interaction_types must contain unique String values"
	for interaction_variant in scope["interaction_types"] as Array:
		if not INTERACTION_TYPES.has(String(interaction_variant)):
			return "interaction_types contains non-V1 interaction"
	return ""

func _scope_is_equal_or_narrower(candidate: Dictionary, maximum: Dictionary) -> bool:
	if String(candidate.get("dungeon_id", "")) != String(maximum.get("dungeon_id", "")):
		return false
	if String(candidate.get("topic_id", "")) != String(maximum.get("topic_id", "")):
		return false
	if int(candidate.get("difficulty_min", 0)) < int(maximum.get("difficulty_min", 0)):
		return false
	if int(candidate.get("difficulty_max", 6)) > int(maximum.get("difficulty_max", 6)):
		return false
	if not _constraint_array_is_narrower(candidate.get("subtopic_ids", []) as Array, maximum.get("subtopic_ids", []) as Array):
		return false
	if not _constraint_array_is_narrower(candidate.get("interaction_types", []) as Array, maximum.get("interaction_types", []) as Array):
		return false
	return true

func _constraint_array_is_narrower(candidate: Array, maximum: Array) -> bool:
	# Empty means unrestricted within the already locked parent topic/type universe.
	if maximum.is_empty():
		return true
	if candidate.is_empty():
		return false
	for value in candidate:
		if not maximum.has(value):
			return false
	return true

func _apply_request_filters(candidates: Array[Dictionary], scope: Dictionary, excluded: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var interaction_types: Array = scope["interaction_types"] as Array
	for question in candidates:
		if excluded.has(String(question.get("question_id", ""))):
			continue
		if not interaction_types.is_empty() and not interaction_types.has(String(question.get("interaction_type", ""))):
			continue
		result.append(question)
	return result

func _runtime_usable_candidates(candidates: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for question in candidates:
		if _is_runtime_usable_question(question):
			result.append(question)
	return result

func _is_runtime_usable_question(question: Dictionary) -> bool:
	for field in ["question_id", "dungeon_id", "topic_id", "subtopic_id", "difficulty", "interaction_type", "prompt", "interaction_payload", "answer_spec", "explanation", "allowed_contexts"]:
		if not question.has(field):
			return false
	if not (question["interaction_payload"] is Dictionary) or not (question["answer_spec"] is Dictionary):
		return false
	if not INTERACTION_TYPES.has(String(question["interaction_type"])):
		return false
	return true

func _base_target_difficulty(request: Dictionary) -> int:
	var preferred: Variant = request["preferred_difficulty"]
	var scope: Dictionary = request["scope"] as Dictionary
	if preferred != null and int(preferred) >= int(scope["difficulty_min"]) and int(preferred) <= int(scope["difficulty_max"]):
		return int(preferred)
	return int(floor(float(int(scope["difficulty_min"]) + int(scope["difficulty_max"])) / 2.0))

func _is_valid_narrowing_recommendation(recommendation: Dictionary, caller_scope: Dictionary) -> bool:
	for field in ["scope", "target_difficulty", "preferred_subtopic_ids"]:
		if not recommendation.has(field):
			return false
	if not (recommendation["scope"] is Dictionary) or not (recommendation["target_difficulty"] is int) or not (recommendation["preferred_subtopic_ids"] is Array):
		return false
	var adaptive_scope: Dictionary = recommendation["scope"] as Dictionary
	if _validate_scope(adaptive_scope) != "" or not _scope_is_equal_or_narrower(adaptive_scope, caller_scope):
		return false
	var target: int = int(recommendation["target_difficulty"])
	if target < int(adaptive_scope["difficulty_min"]) or target > int(adaptive_scope["difficulty_max"]):
		return false
	if not _array_is_unique_strings(recommendation["preferred_subtopic_ids"] as Array):
		return false
	var adaptive_subtopics: Array = adaptive_scope["subtopic_ids"] as Array
	var caller_subtopics: Array = caller_scope["subtopic_ids"] as Array
	var canonical_subtopics: Array = SUBTOPICS_BY_TOPIC.get(String(caller_scope["topic_id"]), [])
	for subtopic_variant in recommendation["preferred_subtopic_ids"] as Array:
		var subtopic: String = String(subtopic_variant)
		if not canonical_subtopics.has(subtopic):
			return false
		if not adaptive_subtopics.is_empty() and not adaptive_subtopics.has(subtopic):
			return false
		if not caller_subtopics.is_empty() and not caller_subtopics.has(subtopic):
			return false
	return true

func _filter_candidates_to_scope(candidates: Array[Dictionary], scope: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var subtopics: Array = scope["subtopic_ids"] as Array
	var interactions: Array = scope["interaction_types"] as Array
	for question in candidates:
		if String(question.get("dungeon_id", "")) != String(scope["dungeon_id"]) or String(question.get("topic_id", "")) != String(scope["topic_id"]):
			continue
		var difficulty: int = int(question.get("difficulty", 0))
		if difficulty < int(scope["difficulty_min"]) or difficulty > int(scope["difficulty_max"]):
			continue
		if not subtopics.is_empty() and not subtopics.has(String(question.get("subtopic_id", ""))):
			continue
		if not interactions.is_empty() and not interactions.has(String(question.get("interaction_type", ""))):
			continue
		result.append(question)
	return result

func _select_deterministically(candidates: Array[Dictionary], target_difficulty: int, preferred_subtopics: Array[String]) -> Dictionary:
	var best: Dictionary = {}
	var best_key: Array = []
	for question in candidates:
		var preferred_rank: int = 1
		if not preferred_subtopics.is_empty() and preferred_subtopics.has(String(question.get("subtopic_id", ""))):
			preferred_rank = 0
		var difficulty: int = int(question.get("difficulty", 1))
		var key: Array = [preferred_rank, abs(difficulty - target_difficulty), difficulty, String(question.get("question_id", ""))]
		if best.is_empty() or _selection_key_less(key, best_key):
			best = question
			best_key = key
	return best.duplicate(true)

func _selection_key_less(left: Array, right: Array) -> bool:
	for index in range(left.size()):
		if left[index] == right[index]:
			continue
		return left[index] < right[index]
	return false

func _presentation_view(question: Dictionary) -> Dictionary:
	var view: Dictionary = {}
	for field in PRESENTATION_FIELDS:
		if question.has(field):
			view[field] = _duplicate_value(question[field])
	return view

func _duplicate_value(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	return value

func _array_is_unique_strings(values: Array) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if not (value is String):
			return false
		var string_value: String = String(value)
		if string_value.is_empty() or seen.has(string_value):
			return false
		seen[string_value] = true
	return true

func _string_array(values: Variant) -> Array[String]:
	var result: Array[String] = []
	if not (values is Array):
		return result
	for value in values as Array:
		if value is String:
			result.append(String(value))
	return result

func _has_exact_fields(data: Dictionary, fields: Array[String]) -> bool:
	if data.size() != fields.size():
		return false
	for field in fields:
		if not data.has(field):
			return false
	return true

func _now_msec() -> int:
	if _clock_msec.is_valid():
		return int(_clock_msec.call())
	return Time.get_ticks_msec()

func _error(code: String, message: String) -> Dictionary:
	return {"success": false, "error_code": code, "error_message": message}
