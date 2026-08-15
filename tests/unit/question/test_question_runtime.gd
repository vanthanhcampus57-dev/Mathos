class_name TestQuestionRuntime
extends RefCounted

## QUESTION-001..026 contract suite for QuestionEvaluator and QuestionService.

static func run_all_tests() -> bool:
	print("--- RUNNING QUESTION RUNTIME SUITE (QUESTION-001..026) ---")
	var all_ok: bool = true
	all_ok = question_001_mc_correct() and all_ok
	all_ok = question_002_mc_incorrect() and all_ok
	all_ok = question_003_mc_malformed() and all_ok
	all_ok = question_004_drag_correct_order_insensitive() and all_ok
	all_ok = question_005_drag_valid_incorrect() and all_ok
	all_ok = question_006_drag_unknown_duplicate_malformed() and all_ok
	all_ok = question_007_drag_must_place_all_incomplete_malformed() and all_ok
	all_ok = question_008_matching_correct_order_insensitive() and all_ok
	all_ok = question_009_matching_incomplete_valid_incorrect() and all_ok
	all_ok = question_010_matching_unknown_malformed() and all_ok
	all_ok = question_011_matching_duplicate_left_malformed() and all_ok
	all_ok = question_012_matching_duplicate_right_pair_malformed() and all_ok
	all_ok = question_013_input_integer_exact_parse() and all_ok
	all_ok = question_014_input_float_tolerance_boundary() and all_ok
	all_ok = question_015_input_string_symbol_normalization() and all_ok
	all_ok = question_016_input_malformed_numeric() and all_ok
	all_ok = question_017_incorrect_grade_fail() and all_ok
	all_ok = question_018_null_estimate_grade_b() and all_ok
	all_ok = question_019_configured_grade_boundaries() and all_ok
	all_ok = question_020_service_rejects_scope_broadening() and all_ok
	all_ok = question_021_service_honors_subtopic_ids() and all_ok
	all_ok = question_022_service_context_interaction_exclusion() and all_ok
	all_ok = question_023_deterministic_selection() and all_ok
	all_ok = question_024_exhaustion_error() and all_ok
	all_ok = question_025_presentation_session_result_contract() and all_ok
	all_ok = question_026_adaptive_narrowing_only() and all_ok
	return all_ok

static func question_001_mc_correct() -> bool:
	return _expect_correct("QUESTION-001", _mc_question(), {"selected_option_id": "opt_a"}, true)

static func question_002_mc_incorrect() -> bool:
	return _expect_correct("QUESTION-002", _mc_question(), {"selected_option_id": "opt_b"}, false)

static func question_003_mc_malformed() -> bool:
	return _expect_error("QUESTION-003", _mc_question(), {"selected_option_id": "unknown"}, QuestionErrorCodes.INVALID_ANSWER_SHAPE)

static func question_004_drag_correct_order_insensitive() -> bool:
	var payload: Dictionary = {"placements": [{"item_id": "item_b", "target_id": "target_b"}, {"item_id": "item_a", "target_id": "target_a"}]}
	return _expect_correct("QUESTION-004", _drag_question(true), payload, true)

static func question_005_drag_valid_incorrect() -> bool:
	var payload: Dictionary = {"placements": [{"item_id": "item_a", "target_id": "target_b"}]}
	return _expect_correct("QUESTION-005", _drag_question(false), payload, false)

static func question_006_drag_unknown_duplicate_malformed() -> bool:
	var unknown: Dictionary = _eval(_drag_question(false), {"placements": [{"item_id": "item_unknown", "target_id": "target_a"}]})
	var duplicate: Dictionary = _eval(_drag_question(false), {"placements": [{"item_id": "item_a", "target_id": "target_a"}, {"item_id": "item_a", "target_id": "target_b"}]})
	return _expect_two_errors("QUESTION-006", unknown, duplicate, QuestionErrorCodes.INVALID_ANSWER_SHAPE)

static func question_007_drag_must_place_all_incomplete_malformed() -> bool:
	return _expect_error("QUESTION-007", _drag_question(true), {"placements": [{"item_id": "item_a", "target_id": "target_a"}]}, QuestionErrorCodes.INVALID_ANSWER_SHAPE)

static func question_008_matching_correct_order_insensitive() -> bool:
	var payload: Dictionary = {"pairs": [{"left_id": "left_b", "right_id": "right_b"}, {"left_id": "left_a", "right_id": "right_a"}]}
	return _expect_correct("QUESTION-008", _matching_question(), payload, true)

static func question_009_matching_incomplete_valid_incorrect() -> bool:
	var result: Dictionary = _eval(_matching_question(), {"pairs": [{"left_id": "left_a", "right_id": "right_a"}]})
	if not bool(result.get("success", false)) or bool((result["result"] as Dictionary)["is_correct"]):
		return _fail("QUESTION-009", "Well-formed incomplete matching was not a valid incorrect attempt")
	print("[QUESTION-009] PASS")
	return true

static func question_010_matching_unknown_malformed() -> bool:
	return _expect_error("QUESTION-010", _matching_question(), {"pairs": [{"left_id": "left_a", "right_id": "right_unknown"}]}, QuestionErrorCodes.INVALID_ANSWER_SHAPE)

static func question_011_matching_duplicate_left_malformed() -> bool:
	var payload: Dictionary = {"pairs": [{"left_id": "left_a", "right_id": "right_a"}, {"left_id": "left_a", "right_id": "right_b"}]}
	return _expect_error("QUESTION-011", _matching_question(), payload, QuestionErrorCodes.INVALID_ANSWER_SHAPE)

static func question_012_matching_duplicate_right_pair_malformed() -> bool:
	var duplicate_right: Dictionary = _eval(_matching_question(), {"pairs": [{"left_id": "left_a", "right_id": "right_a"}, {"left_id": "left_b", "right_id": "right_a"}]})
	var duplicate_pair: Dictionary = _eval(_matching_question(), {"pairs": [{"left_id": "left_a", "right_id": "right_a"}, {"left_id": "left_a", "right_id": "right_a"}]})
	var wrong_shape: Dictionary = _eval(_matching_question(), {"pairs": [{"left_id": "left_a", "wrong_field": "right_a"}]})
	for malformed in [duplicate_right, duplicate_pair, wrong_shape]:
		if String((malformed as Dictionary).get("error_code", "")) != QuestionErrorCodes.INVALID_ANSWER_SHAPE:
			return _fail("QUESTION-012", "Duplicate right/pair or wrong-field shape was not rejected as invalid answer shape")
	print("[QUESTION-012] PASS")
	return true

static func question_013_input_integer_exact_parse() -> bool:
	var q: Dictionary = _input_question("integer", [4])
	var parsed: Dictionary = _eval(q, {"value": "4"})
	var wrong: Dictionary = _eval(q, {"value": 5})
	if not _is_correct_result(parsed, true) or not _is_correct_result(wrong, false):
		return _fail("QUESTION-013", "Integer parse/exact comparison failed")
	print("[QUESTION-013] PASS")
	return true

static func question_014_input_float_tolerance_boundary() -> bool:
	var q: Dictionary = _input_question("float", [1.0])
	q["answer_spec"]["numeric_tolerance"] = 0.25
	var boundary: Dictionary = _eval(q, {"value": 1.25})
	var outside: Dictionary = _eval(q, {"value": 1.251})
	if not _is_correct_result(boundary, true) or not _is_correct_result(outside, false):
		return _fail("QUESTION-014", "Float tolerance inclusive boundary failed")
	print("[QUESTION-014] PASS")
	return true

static func question_015_input_string_symbol_normalization() -> bool:
	var string_q: Dictionary = _input_question("string", ["Alpha"])
	var symbol_q: Dictionary = _input_question("symbol", ["Ω"])
	symbol_q["answer_spec"]["case_sensitive"] = true
	var string_result: Dictionary = _eval(string_q, {"value": "  ALPHA "})
	var symbol_result: Dictionary = _eval(symbol_q, {"value": " Ω "})
	if not _is_correct_result(string_result, true) or not _is_correct_result(symbol_result, true):
		return _fail("QUESTION-015", "String/symbol normalization failed")
	print("[QUESTION-015] PASS")
	return true

static func question_016_input_malformed_numeric() -> bool:
	return _expect_error("QUESTION-016", _input_question("integer", [4]), {"value": "four"}, QuestionErrorCodes.INVALID_ANSWER_SHAPE)

static func question_017_incorrect_grade_fail() -> bool:
	var result: Dictionary = QuestionEvaluator.evaluate(_mc_question(), {"selected_option_id": "opt_b"}, "stage_01_01", "practice", 1.0, _thresholds(), "attempt_test")
	if not bool(result.get("success", false)) or String((result["result"] as Dictionary)["performance_grade"]) != "fail":
		return _fail("QUESTION-017", "Incorrect answer did not grade fail")
	print("[QUESTION-017] PASS")
	return true

static func question_018_null_estimate_grade_b() -> bool:
	var q: Dictionary = _mc_question()
	q["estimated_time_seconds"] = null
	var result: Dictionary = QuestionEvaluator.evaluate(q, {"selected_option_id": "opt_a"}, "stage_01_01", "practice", 1.0, _thresholds(), "attempt_test")
	if not bool(result.get("success", false)) or String((result["result"] as Dictionary)["performance_grade"]) != "b":
		return _fail("QUESTION-018", "Correct null-estimate answer did not default to grade b")
	print("[QUESTION-018] PASS")
	return true

static func question_019_configured_grade_boundaries() -> bool:
	var q: Dictionary = _mc_question()
	q["estimated_time_seconds"] = 100
	var grade_a: Dictionary = QuestionEvaluator.evaluate(q, {"selected_option_id": "opt_a"}, "stage_01_01", "practice", 75.0, _thresholds(), "attempt_a")
	var grade_b: Dictionary = QuestionEvaluator.evaluate(q, {"selected_option_id": "opt_a"}, "stage_01_01", "practice", 125.0, _thresholds(), "attempt_b")
	var grade_c: Dictionary = QuestionEvaluator.evaluate(q, {"selected_option_id": "opt_a"}, "stage_01_01", "practice", 126.0, _thresholds(), "attempt_c")
	if _grade_of(grade_a) != "a" or _grade_of(grade_b) != "b" or _grade_of(grade_c) != "c":
		return _fail("QUESTION-019", "Configured a/b/c threshold boundaries failed")
	print("[QUESTION-019] PASS")
	return true

static func question_020_service_rejects_scope_broadening() -> bool:
	var service: QuestionService = QuestionService.new(_service_catalog())
	var cross: Dictionary = _request(_scope("dungeon_02", "classical_probability", [], 1, 5, []))
	var cross_result: Dictionary = service.request_question(cross)
	var broader_scope: Dictionary = _scope("dungeon_01", "trial_sample_event", [], 1, 5, [])
	var broader_result: Dictionary = service.request_question(_request(broader_scope))
	if String(cross_result.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION or String(broader_result.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION:
		return _fail("QUESTION-020", "Service did not reject cross-topic or broader-than-stage scope")
	print("[QUESTION-020] PASS")
	return true

static func question_021_service_honors_subtopic_ids() -> bool:
	var service: QuestionService = QuestionService.new(_service_catalog())
	var result: Dictionary = service.request_question(_request(_scope("dungeon_01", "trial_sample_event", ["sample_space"], 1, 3, [])))
	if not bool(result.get("success", false)) or String((result["question"] as Dictionary).get("subtopic_id", "")) != "sample_space":
		return _fail("QUESTION-021", "QuestionService did not enforce subtopic_ids")
	print("[QUESTION-021] PASS")
	return true

static func question_022_service_context_interaction_exclusion() -> bool:
	var service: QuestionService = QuestionService.new(_service_catalog())
	var request: Dictionary = _request(_scope("dungeon_01", "trial_sample_event", [], 1, 3, ["multiple_choice"]))
	request["context"] = "combat"
	request["exclude_question_ids"] = ["question_a"]
	var result: Dictionary = service.request_question(request)
	if not bool(result.get("success", false)) or String((result["question"] as Dictionary).get("question_id", "")) != "question_c":
		return _fail("QUESTION-022", "Context/interaction/exclusion filtering failed")
	print("[QUESTION-022] PASS")
	return true

static func question_023_deterministic_selection() -> bool:
	var result_a: Dictionary = QuestionService.new(_service_catalog()).request_question(_request(_scope("dungeon_01", "trial_sample_event", [], 1, 3, [])))
	var result_b: Dictionary = QuestionService.new(_service_catalog()).request_question(_request(_scope("dungeon_01", "trial_sample_event", [], 1, 3, [])))
	if not bool(result_a.get("success", false)) or not bool(result_b.get("success", false)):
		return _fail("QUESTION-023", "Deterministic selection did not return candidates")
	var id_a: String = String((result_a["question"] as Dictionary)["question_id"])
	var id_b: String = String((result_b["question"] as Dictionary)["question_id"])
	if id_a != "question_a" or id_b != id_a:
		return _fail("QUESTION-023", "Midpoint/distance/lower/lexical deterministic ordering failed")
	print("[QUESTION-023] PASS")
	return true

static func question_024_exhaustion_error() -> bool:
	var recovery_service: QuestionService = QuestionService.new(_service_catalog_with_unusable_candidate())
	var recovery: Dictionary = recovery_service.request_question(_request(_scope("dungeon_01", "trial_sample_event", [], 1, 3, [])))
	if not bool(recovery.get("success", false)) or String((recovery["question"] as Dictionary).get("question_id", "")) != "question_valid":
		return _fail("QUESTION-024", "Runtime-unusable candidate was not skipped for legal same-scope candidate")

	var service: QuestionService = QuestionService.new(_service_catalog())
	var request: Dictionary = _request(_scope("dungeon_01", "trial_sample_event", [], 1, 3, []))
	request["exclude_question_ids"] = ["question_a", "question_b", "question_c"]
	var result: Dictionary = service.request_question(request)
	if String(result.get("error_code", "")) != QuestionErrorCodes.NO_VALID_QUESTION:
		return _fail("QUESTION-024", "Exhausted same-scope pool did not return NoValidQuestionError")
	print("[QUESTION-024] PASS")
	return true

static func question_025_presentation_session_result_contract() -> bool:
	var service: QuestionService = QuestionService.new(_service_catalog())
	var request_result: Dictionary = service.request_question(_request(_scope("dungeon_01", "trial_sample_event", ["sample_space"], 1, 3, [])))
	if not bool(request_result.get("success", false)):
		return _fail("QUESTION-025", "Question request failed")
	var view: Dictionary = request_result["question"] as Dictionary
	var session: Dictionary = request_result["session"] as Dictionary
	if view.has("answer_spec") or view.has("explanation") or session.has("answer_spec"):
		return _fail("QUESTION-025", "Correctness data leaked into presentation/session")
	var expected_session_fields: Array[String] = ["session_id", "request_id", "question_id", "context", "started_at_msec", "submission_locked", "completed"]
	if not _has_exact_keys(session, expected_session_fields):
		return _fail("QUESTION-025", "QuestionSession shape does not match File 10")
	var malformed: Dictionary = {"session_id": session["session_id"], "interaction_type": "multiple_choice", "payload": {"selected_option_id": "unknown"}}
	var malformed_result: Dictionary = service.submit_answer(malformed)
	if String(malformed_result.get("error_code", "")) != QuestionErrorCodes.INVALID_ANSWER_SHAPE or not service.has_active_session():
		return _fail("QUESTION-025", "Malformed submission consumed the active QuestionSession")
	var answer: Dictionary = {"session_id": session["session_id"], "interaction_type": "multiple_choice", "payload": {"selected_option_id": "opt_a"}}
	var submit: Dictionary = service.submit_answer(answer)
	if not bool(submit.get("success", false)):
		return _fail("QUESTION-025", "Valid submission failed")
	var result: Dictionary = submit["result"] as Dictionary
	if not _has_exact_keys(result, QuestionEvaluator.RESULT_FIELDS):
		return _fail("QUESTION-025", "QuestionAttemptResult is not exact 12-field contract")
	var duplicate: Dictionary = service.submit_answer(answer)
	if String(duplicate.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION_SESSION:
		return _fail("QUESTION-025", "Completed session accepted duplicate submission")
	print("[QUESTION-025] PASS")
	return true

static func question_026_adaptive_narrowing_only() -> bool:
	var caller_scope: Dictionary = _scope("dungeon_01", "trial_sample_event", [], 1, 3, [])
	var narrowed_scope: Dictionary = _scope("dungeon_01", "trial_sample_event", ["event_subset"], 3, 3, [])
	var narrowing: Dictionary = {"scope": narrowed_scope, "target_difficulty": 3, "preferred_subtopic_ids": ["event_subset"], "reason_code": "challenge"}
	var narrow_result: Dictionary = QuestionService.new(_service_catalog()).request_question(_request(caller_scope), narrowing)
	if not bool(narrow_result.get("success", false)) or String((narrow_result["question"] as Dictionary)["question_id"]) != "question_c":
		return _fail("QUESTION-026", "Legal Adaptive narrowing was not honored")
	var broad_scope: Dictionary = _scope("dungeon_02", "classical_probability", [], 1, 5, [])
	var broadening: Dictionary = {"scope": broad_scope, "target_difficulty": 2, "preferred_subtopic_ids": [], "reason_code": "baseline"}
	var broad_result: Dictionary = QuestionService.new(_service_catalog()).request_question(_request(caller_scope), broadening)
	if not bool(broad_result.get("success", false)) or String((broad_result["question"] as Dictionary)["question_id"]) != "question_a":
		return _fail("QUESTION-026", "Broadening Adaptive recommendation changed caller hard scope")
	print("[QUESTION-026] PASS")
	return true

static func _eval(question: Dictionary, payload: Dictionary) -> Dictionary:
	return QuestionEvaluator.evaluate(question, payload, "stage_01_01", "practice", 10.0, _thresholds(), "attempt_test")

static func _expect_correct(test_id: String, question: Dictionary, payload: Dictionary, expected: bool) -> bool:
	var result: Dictionary = _eval(question, payload)
	if not _is_correct_result(result, expected):
		return _fail(test_id, "Unexpected correctness result: " + str(result))
	print("[" + test_id + "] PASS")
	return true

static func _expect_error(test_id: String, question: Dictionary, payload: Dictionary, code: String) -> bool:
	var result: Dictionary = _eval(question, payload)
	if String(result.get("error_code", "")) != code:
		return _fail(test_id, "Expected " + code + ", got " + str(result))
	print("[" + test_id + "] PASS")
	return true

static func _expect_two_errors(test_id: String, first: Dictionary, second: Dictionary, code: String) -> bool:
	if String(first.get("error_code", "")) != code or String(second.get("error_code", "")) != code:
		return _fail(test_id, "Malformed variants did not both return " + code)
	print("[" + test_id + "] PASS")
	return true

static func _is_correct_result(result: Dictionary, expected: bool) -> bool:
	return bool(result.get("success", false)) and bool((result["result"] as Dictionary).get("is_correct", not expected)) == expected

static func _grade_of(result: Dictionary) -> String:
	if not bool(result.get("success", false)):
		return ""
	return String((result["result"] as Dictionary).get("performance_grade", ""))

static func _fail(test_id: String, message: String) -> bool:
	print("[" + test_id + "] FAIL: " + message)
	return false

static func _thresholds() -> Dictionary:
	return {"a_max_time_ratio": 0.75, "b_max_time_ratio": 1.25}

static func _question_common(interaction_type: String) -> Dictionary:
	return {
		"schema_version": 1,
		"question_id": "question_test",
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "sample_space",
		"learning_objective": "Synthetic test objective",
		"difficulty": 2,
		"interaction_type": interaction_type,
		"prompt": "Synthetic prompt",
		"interaction_payload": {},
		"answer_spec": {},
		"explanation": "Synthetic explanation",
		"hints": [],
		"estimated_time_seconds": 20,
		"tags": [],
		"prerequisite_ids": [],
		"asset_refs": [],
		"story_context": null,
		"allowed_contexts": ["practice", "combat"],
		"adaptive_metadata": {"skill_ids": []}
	}

static func _mc_question() -> Dictionary:
	var q: Dictionary = _question_common("multiple_choice")
	q["interaction_payload"] = {"options": [{"option_id": "opt_a", "text": "A"}, {"option_id": "opt_b", "text": "B"}], "shuffle": false}
	q["answer_spec"] = {"correct_option_id": "opt_a"}
	return q

static func _drag_question(must_place_all: bool) -> Dictionary:
	var q: Dictionary = _question_common("drag_drop")
	q["interaction_payload"] = {
		"items": [{"item_id": "item_a", "text": "A"}, {"item_id": "item_b", "text": "B"}],
		"targets": [{"target_id": "target_a", "label": "A"}, {"target_id": "target_b", "label": "B"}],
		"must_place_all": must_place_all
	}
	q["answer_spec"] = {"mappings": [{"item_id": "item_a", "target_id": "target_a"}, {"item_id": "item_b", "target_id": "target_b"}]}
	return q

static func _matching_question() -> Dictionary:
	var q: Dictionary = _question_common("matching")
	q["interaction_payload"] = {
		"left_items": [{"item_id": "left_a", "text": "A"}, {"item_id": "left_b", "text": "B"}],
		"right_items": [{"item_id": "right_a", "text": "A"}, {"item_id": "right_b", "text": "B"}]
	}
	q["answer_spec"] = {"pairs": [{"left_id": "left_a", "right_id": "right_a"}, {"left_id": "left_b", "right_id": "right_b"}]}
	return q

static func _input_question(input_type: String, accepted_values: Array) -> Dictionary:
	var q: Dictionary = _question_common("input")
	q["interaction_payload"] = {"input_type": input_type, "placeholder": null, "unit": null}
	q["answer_spec"] = {"accepted_values": accepted_values, "numeric_tolerance": null, "case_sensitive": false, "trim_whitespace": true}
	return q

static func _scope(dungeon_id: String, topic_id: String, subtopics: Array, min_diff: int, max_diff: int, interactions: Array) -> Dictionary:
	return {
		"dungeon_id": dungeon_id,
		"topic_id": topic_id,
		"subtopic_ids": subtopics,
		"difficulty_min": min_diff,
		"difficulty_max": max_diff,
		"interaction_types": interactions
	}

static func _request(scope: Dictionary) -> Dictionary:
	return {
		"request_id": "request_test",
		"stage_id": "stage_01_01",
		"scope": scope,
		"context": "practice",
		"preferred_difficulty": 2,
		"exclude_question_ids": []
	}

static func _service_catalog() -> ValidatedCatalog:
	var config: Dictionary = {"performance_grade_thresholds": _thresholds()}
	var stage_scope: Dictionary = _scope("dungeon_01", "trial_sample_event", [], 1, 3, [])
	var stages: Dictionary = {"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01", "question_scope": stage_scope}}
	var question_a: Dictionary = _mc_question()
	question_a["question_id"] = "question_a"
	question_a["subtopic_id"] = "sample_space"
	question_a["difficulty"] = 2
	var question_b: Dictionary = _matching_question()
	question_b["question_id"] = "question_b"
	question_b["subtopic_id"] = "event_subset"
	question_b["difficulty"] = 2
	question_b["allowed_contexts"] = ["practice"]
	var question_c: Dictionary = _mc_question()
	question_c["question_id"] = "question_c"
	question_c["subtopic_id"] = "event_subset"
	question_c["difficulty"] = 3
	var questions: Dictionary = {"question_a": question_a, "question_b": question_b, "question_c": question_c}
	return ValidatedCatalog.new(config, {}, stages, {}, {}, {}, questions, {}, {}, {})


static func _service_catalog_with_unusable_candidate() -> ValidatedCatalog:
	var config: Dictionary = {"performance_grade_thresholds": _thresholds()}
	var stage_scope: Dictionary = _scope("dungeon_01", "trial_sample_event", [], 1, 3, [])
	var stages: Dictionary = {"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01", "question_scope": stage_scope}}
	var unusable: Dictionary = _mc_question()
	unusable["question_id"] = "question_a_unusable"
	unusable.erase("answer_spec")
	var valid: Dictionary = _mc_question()
	valid["question_id"] = "question_valid"
	var questions: Dictionary = {"question_a_unusable": unusable, "question_valid": valid}
	return ValidatedCatalog.new(config, {}, stages, {}, {}, {}, questions, {}, {}, {})

static func _has_exact_keys(data: Dictionary, fields: Array[String]) -> bool:
	if data.size() != fields.size():
		return false
	for field in fields:
		if not data.has(field):
			return false
	return true
