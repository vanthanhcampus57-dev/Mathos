class_name TestQuestionPresentation
extends RefCounted

## Unit test suite for QuestionPresentationController, QuestionPanel, and Interaction Views (PRES-001..008, PRES-012..019).

static func run_all_tests() -> bool:
	print("--- RUNNING QUESTION PRESENTATION SUITE ---")
	var all_ok: bool = true
	all_ok = pres_001_multiple_choice_render_and_submit() and all_ok
	all_ok = pres_002_input_render_and_submit() and all_ok
	all_ok = pres_003_drag_drop_canonical_mappings() and all_ok
	all_ok = pres_004_matching_canonical_pairs() and all_ok
	all_ok = pres_005_feedback_uses_attempt_result() and all_ok
	all_ok = pres_006_completion_event_exactly_once() and all_ok
	all_ok = pres_008_invalid_question_definition_fails_explicitly() and all_ok
	all_ok = pres_012_question_mount_and_ui_visibility_regression() and all_ok
	all_ok = pres_013_bind_existing_session_success() and all_ok
	all_ok = pres_014_bind_existing_session_no_active_session() and all_ok
	all_ok = pres_015_bind_existing_session_mismatched_session_id() and all_ok
	all_ok = pres_016_bind_existing_session_invalid_question_payload() and all_ok
	all_ok = pres_017_bind_existing_session_duplicate_bind_after_completion() and all_ok
	all_ok = pres_018_bind_existing_session_mismatched_question_id() and all_ok
	all_ok = pres_019_mcq_diagnostic_submission_contract_fix() and all_ok
	return all_ok

static func pres_001_multiple_choice_render_and_submit() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request: Dictionary = _request("multiple_choice")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-001] FAIL: start_question failed: ", start_res)
		return false

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null:
		print("[PRES-001] FAIL: MultipleChoiceView was not instantiated")
		return false

	if not mc_view.select_option("opt_a"):
		print("[PRES-001] FAIL: select_option opt_a failed")
		return false

	var payload: Dictionary = panel.get_current_interaction_payload()
	if String(payload.get("selected_option_id", "")) != "opt_a":
		print("[PRES-001] FAIL: canonical payload selected_option_id != opt_a")
		return false

	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)):
		print("[PRES-001] FAIL: submit_answer failed: ", submit_res)
		return false

	print("[PRES-001] PASS")
	return true

static func pres_002_input_render_and_submit() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request: Dictionary = _request("input")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-002] FAIL: start_question failed: ", start_res)
		return false

	var inp_view: InputView = panel.get_active_interaction_view() as InputView
	if inp_view == null:
		print("[PRES-002] FAIL: InputView was not instantiated")
		return false

	inp_view.set_input_value("4")
	var payload: Dictionary = panel.get_current_interaction_payload()
	if int(payload.get("value", 0)) != 4:
		print("[PRES-002] FAIL: input payload value != 4")
		return false

	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)):
		print("[PRES-002] FAIL: submit_answer failed: ", submit_res)
		return false

	print("[PRES-002] PASS")
	return true

static func pres_003_drag_drop_canonical_mappings() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request: Dictionary = _request("drag_drop")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-003] FAIL: start_question failed: ", start_res)
		return false

	var dd_view: DragDropView = panel.get_active_interaction_view() as DragDropView
	if dd_view == null:
		print("[PRES-003] FAIL: DragDropView was not instantiated")
		return false

	dd_view.place_item("item_a", "target_a")
	dd_view.place_item("item_b", "target_b")

	var payload: Dictionary = panel.get_current_interaction_payload()
	var placements: Array = payload.get("placements", []) as Array
	if placements.size() != 2:
		print("[PRES-003] FAIL: placements size != 2")
		return false

	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)):
		print("[PRES-003] FAIL: submit_answer failed: ", submit_res)
		return false

	print("[PRES-003] PASS")
	return true

static func pres_004_matching_canonical_pairs() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request: Dictionary = _request("matching")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-004] FAIL: start_question failed: ", start_res)
		return false

	var mat_view: MatchingView = panel.get_active_interaction_view() as MatchingView
	if mat_view == null:
		print("[PRES-004] FAIL: MatchingView was not instantiated")
		return false

	mat_view.add_pair("left_a", "right_a")
	mat_view.add_pair("left_b", "right_b")

	var payload: Dictionary = panel.get_current_interaction_payload()
	var pairs: Array = payload.get("pairs", []) as Array
	if pairs.size() != 2:
		print("[PRES-004] FAIL: pairs size != 2")
		return false

	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)):
		print("[PRES-004] FAIL: submit_answer failed: ", submit_res)
		return false

	print("[PRES-004] PASS")
	return true

static func pres_005_feedback_uses_attempt_result() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	controller.start_question(_request("multiple_choice"))
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_a")

	controller.submit_answer(panel.get_current_interaction_payload())

	if not panel.has_feedback() or not panel.is_correct():
		print("[PRES-005] FAIL: panel feedback state is invalid")
		return false

	print("[PRES-005] PASS")
	return true

static func pres_006_completion_event_exactly_once() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var count: Array[int] = [0]
	controller.question_completed.connect(func(_result): count[0] += 1)

	controller.start_question(_request("multiple_choice"))
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_a")

	var payload: Dictionary = panel.get_current_interaction_payload()
	controller.submit_answer(payload)
	controller.submit_answer(payload)

	if count[0] != 1:
		print("[PRES-006] FAIL: question_completed count != 1 (got %d)" % count[0])
		return false

	print("[PRES-006] PASS")
	return true

static func pres_008_invalid_question_definition_fails_explicitly() -> bool:
	var panel: QuestionPanel = QuestionPanel.new()
	if panel.setup_question({}):
		print("[PRES-008] FAIL: empty dictionary setup_question returned true")
		return false

	var invalid_q: Dictionary = {
		"question_id": "q_invalid",
		"interaction_type": "multiple_choice",
		"prompt": "Test",
		"interaction_payload": {},
		"answer_spec": {"correct_option_id": "opt_a"}
	}
	if panel.setup_question(invalid_q):
		print("[PRES-008] FAIL: question containing answer_spec returned true")
		return false

	print("[PRES-008] PASS")
	return true

static func pres_012_question_mount_and_ui_visibility_regression() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var start_res: Dictionary = controller.start_question(_request("multiple_choice"))
	if not bool(start_res.get("success", false)):
		print("[PRES-012] FAIL: start_question failed")
		return false

	if panel.get_prompt_text().is_empty() or panel.get_objective_text().is_empty():
		print("[PRES-012] FAIL: prompt or objective text empty")
		return false

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null or mc_view.get_parent() == null:
		print("[PRES-012] FAIL: interaction view not mounted in scene tree")
		return false

	print("[PRES-012] PASS")
	return true

static func pres_013_bind_existing_session_success() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var req_res: Dictionary = service.request_question(_request("multiple_choice"))
	if not bool(req_res.get("success", false)):
		print("[PRES-013] FAIL: request_question failed: ", req_res)
		return false

	var sess: Dictionary = req_res.get("session", {}) as Dictionary
	var q_def: Dictionary = req_res.get("question", {}) as Dictionary
	var q_view: Dictionary = QuestionPresentationController.strip_answer_spec(q_def)

	var bind_res: Dictionary = controller.bind_existing_session(sess, q_view)
	if not bool(bind_res.get("success", false)):
		print("[PRES-013] FAIL: bind_existing_session returned false: ", bind_res)
		return false

	var bound_sess: Dictionary = bind_res.get("session", {}) as Dictionary
	if String(bound_sess.get("session_id", "")) != String(sess.get("session_id", "")):
		print("[PRES-013] FAIL: session_id mismatch")
		return false

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null or not mc_view.select_option("opt_a"):
		print("[PRES-013] FAIL: select_option opt_a failed")
		return false

	var payload: Dictionary = panel.get_current_interaction_payload()
	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)):
		print("[PRES-013] FAIL: submit_answer failed: ", submit_res)
		return false

	print("[PRES-013] PASS")
	return true

static func pres_014_bind_existing_session_no_active_session() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var dummy_sess: Dictionary = {"session_id": "session_dummy", "question_id": "q_mc"}
	var dummy_view: Dictionary = {"question_id": "q_mc", "interaction_type": "multiple_choice", "prompt": "Prompt", "interaction_payload": {"options": [{"option_id": "opt_a", "text": "A"}, {"option_id": "opt_b", "text": "B"}]}}

	var bind_res: Dictionary = controller.bind_existing_session(dummy_sess, dummy_view)
	if bool(bind_res.get("success", false)):
		print("[PRES-014] FAIL: bind_existing_session succeeded when QuestionService had no active session")
		return false

	print("[PRES-014] PASS")
	return true

static func pres_015_bind_existing_session_mismatched_session_id() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var req_res: Dictionary = service.request_question(_request("multiple_choice"))
	if not bool(req_res.get("success", false)):
		print("[PRES-015] FAIL: request_question failed")
		return false

	var real_sess: Dictionary = req_res.get("session", {}) as Dictionary
	var q_def: Dictionary = req_res.get("question", {}) as Dictionary
	var q_view: Dictionary = QuestionPresentationController.strip_answer_spec(q_def)

	var fake_sess: Dictionary = real_sess.duplicate(true)
	fake_sess["session_id"] = "session_mismatched_999"

	var bind_res: Dictionary = controller.bind_existing_session(fake_sess, q_view)
	if bool(bind_res.get("success", false)):
		print("[PRES-015] FAIL: bind_existing_session succeeded for mismatched session_id")
		return false

	print("[PRES-015] PASS")
	return true

static func pres_016_bind_existing_session_invalid_question_payload() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var req_res: Dictionary = service.request_question(_request("multiple_choice"))
	var real_sess: Dictionary = req_res.get("session", {}) as Dictionary

	var invalid_view_1: Dictionary = {"question_id": "q_mc"}
	var bind_res_1: Dictionary = controller.bind_existing_session(real_sess, invalid_view_1)
	if bool(bind_res_1.get("success", false)):
		print("[PRES-016] FAIL: bind_existing_session succeeded for incomplete question_view")
		return false

	var q_def: Dictionary = req_res.get("question", {}) as Dictionary
	var view_with_answer_spec: Dictionary = q_def.duplicate(true)
	view_with_answer_spec["answer_spec"] = {"correct_option_id": "opt_a"}
	var bind_res_2: Dictionary = controller.bind_existing_session(real_sess, view_with_answer_spec)
	if bool(bind_res_2.get("success", false)):
		print("[PRES-016] FAIL: bind_existing_session succeeded when answer_spec was present in view")
		return false

	print("[PRES-016] PASS")
	return true

static func pres_017_bind_existing_session_duplicate_bind_after_completion() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var req_res: Dictionary = service.request_question(_request("multiple_choice"))
	var real_sess: Dictionary = req_res.get("session", {}) as Dictionary
	var q_def: Dictionary = req_res.get("question", {}) as Dictionary
	var q_view: Dictionary = QuestionPresentationController.strip_answer_spec(q_def)

	controller.bind_existing_session(real_sess, q_view)
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_a")
	controller.submit_answer(panel.get_current_interaction_payload())

	var bind_res_after: Dictionary = controller.bind_existing_session(real_sess, q_view)
	if bool(bind_res_after.get("success", false)):
		print("[PRES-017] FAIL: bind_existing_session succeeded after session completion")
		return false

	print("[PRES-017] PASS")
	return true

static func pres_018_bind_existing_session_mismatched_question_id() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var req_res: Dictionary = service.request_question(_request("multiple_choice"))
	var real_sess: Dictionary = req_res.get("session", {}) as Dictionary
	var q_def: Dictionary = req_res.get("question", {}) as Dictionary
	var q_view: Dictionary = QuestionPresentationController.strip_answer_spec(q_def)

	var mismatched_view: Dictionary = q_view.duplicate(true)
	mismatched_view["question_id"] = "q_different_999"

	var completion_count: Array[int] = [0]
	controller.question_completed.connect(func(_r): completion_count[0] += 1)

	var bind_res: Dictionary = controller.bind_existing_session(real_sess, mismatched_view)
	if bool(bind_res.get("success", false)):
		print("[PRES-018] FAIL: bind_existing_session succeeded for mismatched question_id")
		return false

	if completion_count[0] != 0:
		print("[PRES-018] FAIL: question_completed emitted during rejection")
		return false

	print("[PRES-018] PASS")
	return true

static func pres_019_mcq_diagnostic_submission_contract_fix() -> bool:
	# A. Normal QuestionPanel initialization does not submit an answer
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)
	var submitted_count: Array[int] = [0]
	panel.submit_requested.connect(func(_payload): submitted_count[0] += 1)

	var request: Dictionary = _request("multiple_choice")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-019] FAIL: start_question failed: ", start_res)
		return false

	if submitted_count[0] != 0:
		print("[PRES-019] FAIL: setup_question triggered submit_requested!")
		return false

	# B. MCQ payload keys == exactly: ["selected_option_id"] when option selected
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null or not mc_view.select_option("opt_a"):
		print("[PRES-019] FAIL: MultipleChoiceView select_option failed")
		return false

	var payload: Dictionary = panel.get_current_interaction_payload()
	if payload.keys() != ["selected_option_id"]:
		print("[PRES-019] FAIL: MCQ payload keys != ['selected_option_id'], got: ", payload.keys())
		return false

	# C. No generic input/classification/matching fields leak into MCQ payload
	for forbidden_key in ["value", "pairs", "placements", "items", "targets", "left_items"]:
		if payload.has(forbidden_key):
			print("[PRES-019] FAIL: Forbidden key '%s' leaked into MCQ payload" % forbidden_key)
			return false

	# D. Invalid payload is STILL rejected by QuestionService (strictness preserved)
	var active_sess: Dictionary = service.get_active_session()
	var sess_id: String = String(active_sess.get("session_id", ""))
	var invalid_payload_res: Dictionary = service.submit_answer({
		"session_id": sess_id,
		"interaction_type": "multiple_choice",
		"payload": {}
	})
	if bool(invalid_payload_res.get("success", true)):
		print("[PRES-019] FAIL: QuestionService did not reject empty MCQ payload!")
		return false

	var err_msg: String = String(invalid_payload_res.get("error_message", ""))
	if not err_msg.contains("multiple_choice payload requires only selected_option_id"):
		print("[PRES-019] FAIL: Unexpected error message from QuestionService: ", err_msg)
		return false

	# E & F. Real MCQ submission evaluates cleanly
	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)):
		print("[PRES-019] FAIL: Valid MCQ submit_answer failed: ", submit_res)
		return false

	print("[PRES-019] PASS")
	return true

static func _request(interaction_type: String) -> Dictionary:
	return {
		"request_id": "req_pres_test",
		"stage_id": "stage_01_01",
		"scope": {
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"subtopic_ids": ["sample_space"],
			"difficulty_min": 1,
			"difficulty_max": 5,
			"interaction_types": [interaction_type]
		},
		"context": "practice",
		"preferred_difficulty": 2,
		"exclude_question_ids": []
	}

static func _synthetic_catalog() -> ValidatedCatalog:
	var config: Dictionary = {
		"performance_grade_thresholds": {
			"a_max_time_ratio": 0.75,
			"b_max_time_ratio": 1.25
		}
	}
	var stage_scope: Dictionary = {
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_ids": [],
		"difficulty_min": 1,
		"difficulty_max": 5,
		"interaction_types": []
	}
	var stages: Dictionary = {"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01", "practice_id": "practice_01_01", "question_scope": stage_scope}}
	var practices: Dictionary = {"practice_01_01": {"practice_id": "practice_01_01", "question_scope": stage_scope}}

	var mc_q: Dictionary = _base_question("q_mc", "multiple_choice")
	mc_q["interaction_payload"] = {"options": [{"option_id": "opt_a", "text": "A"}, {"option_id": "opt_b", "text": "B"}]}
	mc_q["answer_spec"] = {"correct_option_id": "opt_a"}

	var inp_q: Dictionary = _base_question("q_inp", "input")
	inp_q["interaction_payload"] = {"input_type": "integer"}
	inp_q["answer_spec"] = {"accepted_values": [4]}

	var dd_q: Dictionary = _base_question("q_dd", "drag_drop")
	dd_q["interaction_payload"] = {
		"items": [{"item_id": "item_a", "text": "A"}, {"item_id": "item_b", "text": "B"}],
		"targets": [{"target_id": "target_a", "label": "A"}, {"target_id": "target_b", "label": "B"}]
	}
	dd_q["answer_spec"] = {"mappings": [{"item_id": "item_a", "target_id": "target_a"}, {"item_id": "item_b", "target_id": "target_b"}]}

	var mat_q: Dictionary = _base_question("q_mat", "matching")
	mat_q["interaction_payload"] = {
		"left_items": [{"item_id": "left_a", "text": "A"}, {"item_id": "left_b", "text": "B"}],
		"right_items": [{"item_id": "right_a", "text": "A"}, {"item_id": "right_b", "text": "B"}]
	}
	mat_q["answer_spec"] = {"pairs": [{"left_id": "left_a", "right_id": "right_a"}, {"left_id": "left_b", "right_id": "right_b"}]}

	var questions: Dictionary = {"q_mc": mc_q, "q_inp": inp_q, "q_dd": dd_q, "q_mat": mat_q}
	return ValidatedCatalog.new(config, {}, stages, {}, {}, practices, questions, {}, {}, {})

static func _base_question(qid: String, interaction_type: String) -> Dictionary:
	return {
		"schema_version": 1,
		"question_id": qid,
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "sample_space",
		"learning_objective": "Test objective",
		"difficulty": 2,
		"interaction_type": interaction_type,
		"prompt": "Test prompt",
		"explanation": "Test explanation",
		"hints": [],
		"estimated_time_seconds": 20,
		"tags": [],
		"allowed_contexts": ["practice", "combat"]
	}
