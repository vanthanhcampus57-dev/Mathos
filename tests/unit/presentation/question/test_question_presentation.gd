class_name TestQuestionPresentation
extends RefCounted

## Unit test suite for QuestionPresentationController, QuestionPanel, and Interaction Views (PRES-001..008, PRES-012).

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
	if not bool(submit_res.get("success", false)) or not bool((submit_res["result"] as Dictionary).get("is_correct", false)):
		print("[PRES-001] FAIL: submit_answer for correct option failed: ", submit_res)
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
		print("[PRES-002] FAIL: start_question failed")
		return false

	var inp_view: InputView = panel.get_active_interaction_view() as InputView
	if inp_view == null:
		print("[PRES-002] FAIL: InputView was not instantiated")
		return false

	inp_view.set_input_value("4")
	var payload: Dictionary = panel.get_current_interaction_payload()
	if not payload.has("value") or int(payload["value"]) != 4:
		print("[PRES-002] FAIL: Input payload value != 4")
		return false

	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)) or not bool((submit_res["result"] as Dictionary).get("is_correct", false)):
		print("[PRES-002] FAIL: submit_answer for input failed: ", submit_res)
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
		print("[PRES-003] FAIL: start_question failed")
		return false

	var dd_view: DragDropView = panel.get_active_interaction_view() as DragDropView
	if dd_view == null:
		print("[PRES-003] FAIL: DragDropView was not instantiated")
		return false

	dd_view.place_item("item_a", "target_a")
	dd_view.place_item("item_b", "target_b")

	var payload: Dictionary = panel.get_current_interaction_payload()
	if not payload.has("placements") or not (payload["placements"] is Array):
		print("[PRES-003] FAIL: drag_drop payload missing canonical placements array")
		return false

	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)) or not bool((submit_res["result"] as Dictionary).get("is_correct", false)):
		print("[PRES-003] FAIL: submit_answer for drag_drop failed: ", submit_res)
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
		print("[PRES-004] FAIL: start_question failed")
		return false

	var mat_view: MatchingView = panel.get_active_interaction_view() as MatchingView
	if mat_view == null:
		print("[PRES-004] FAIL: MatchingView was not instantiated")
		return false

	mat_view.add_pair("left_a", "right_a")
	mat_view.add_pair("left_b", "right_b")

	var payload: Dictionary = panel.get_current_interaction_payload()
	if not payload.has("pairs") or not (payload["pairs"] is Array):
		print("[PRES-004] FAIL: matching payload missing canonical pairs array")
		return false

	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)) or not bool((submit_res["result"] as Dictionary).get("is_correct", false)):
		print("[PRES-004] FAIL: submit_answer for matching failed: ", submit_res)
		return false

	print("[PRES-004] PASS")
	return true

static func pres_005_feedback_uses_attempt_result() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	controller.start_question(_request("multiple_choice"))
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_b") # Wrong option

	var submit_res: Dictionary = controller.submit_answer(panel.get_current_interaction_payload())
	if not bool(submit_res.get("success", false)):
		print("[PRES-005] FAIL: submit_answer failed")
		return false

	if not panel.has_feedback() or panel.is_correct() != false or panel.get_feedback_text().is_empty():
		print("[PRES-005] FAIL: QuestionPanel feedback was not updated from AttemptResult")
		return false

	print("[PRES-005] PASS")
	return true

static func pres_006_completion_event_exactly_once() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var tracker: Array = [0]
	controller.question_completed.connect(func(_res: Dictionary) -> void: tracker[0] = int(tracker[0]) + 1)

	controller.start_question(_request("multiple_choice"))
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_a")

	var payload: Dictionary = panel.get_current_interaction_payload()
	var first_submit: Dictionary = controller.submit_answer(payload)
	var second_submit: Dictionary = controller.submit_answer(payload)

	if not bool(first_submit.get("success", false)):
		print("[PRES-006] FAIL: First submission failed")
		return false

	if bool(second_submit.get("success", false)) or String(second_submit.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION_SESSION:
		print("[PRES-006] FAIL: Second submission was not rejected")
		return false

	if int(tracker[0]) != 1:
		print("[PRES-006] FAIL: question_completed emitted %d times (expected 1)" % int(tracker[0]))
		return false

	print("[PRES-006] PASS")
	return true

static func pres_008_invalid_question_definition_fails_explicitly() -> bool:
	var panel: QuestionPanel = QuestionPanel.new()
	var malformed_question: Dictionary = {
		"question_id": "q_invalid",
		"interaction_type": "multiple_choice",
		"prompt": "Malformed question",
		"interaction_payload": {} # Missing options
	}
	var setup_ok: bool = panel.setup_question(malformed_question)
	if setup_ok:
		print("[PRES-008] FAIL: Malformed question_view setup succeeded unexpectedly")
		return false

	# Test answer_spec leak rejection
	var leaking_question: Dictionary = malformed_question.duplicate(true)
	leaking_question["interaction_payload"] = {"options": [{"option_id": "a", "text": "A"}]}
	leaking_question["answer_spec"] = {"correct_option_id": "a"}
	var leak_ok: bool = panel.setup_question(leaking_question)
	if leak_ok:
		print("[PRES-008] FAIL: QuestionPanel accepted leaking answer_spec")
		return false

	print("[PRES-008] PASS")
	return true

static func pres_012_question_mount_and_ui_visibility_regression() -> bool:
	# 1. Verify production scene resource exists and instantiates cleanly
	var scene_res: Resource = load("res://src/ui/question/question_panel.tscn")
	if not (scene_res is PackedScene):
		print("[PRES-012] FAIL: res://src/ui/question/question_panel.tscn resource missing or not a PackedScene")
		return false

	var panel: QuestionPanel = (scene_res as PackedScene).instantiate() as QuestionPanel
	if panel == null:
		print("[PRES-012] FAIL: Failed to instantiate QuestionPanel from res://src/ui/question/question_panel.tscn")
		return false

	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var host: MarginContainer = MarginContainer.new()
	host.name = "QuestionHostContainer"
	host.add_child(panel)

	var request: Dictionary = _request("multiple_choice")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-012] FAIL: start_question failed: ", start_res)
		return false

	if not controller.has_active_session():
		print("[PRES-012] FAIL: QuestionPresentationController does not own active session")
		return false

	# Verify Prompt Label
	var prompt_label: Label = panel.get_node_or_null("MainVBox/PromptLabel") as Label
	if prompt_label == null:
		print("[PRES-012] FAIL: PromptLabel node does not exist in QuestionPanel scene tree")
		return false

	if prompt_label.text.is_empty():
		print("[PRES-012] FAIL: PromptLabel text is empty")
		return false

	if not prompt_label.visible:
		print("[PRES-012] FAIL: PromptLabel is not visible")
		return false

	# Verify Interaction View
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null:
		print("[PRES-012] FAIL: MultipleChoiceView does not exist on QuestionPanel")
		return false

	if mc_view.get_parent() == null:
		print("[PRES-012] FAIL: MultipleChoiceView interaction node is not mounted under parent container")
		return false

	if not mc_view.visible:
		print("[PRES-012] FAIL: MultipleChoiceView interaction node is not visible")
		return false

	if mc_view.custom_minimum_size.x <= 0 or mc_view.custom_minimum_size.y <= 0:
		print("[PRES-012] FAIL: MultipleChoiceView interaction node has zero custom minimum layout size")
		return false

	# Verify Option Buttons for all options returned in payload
	var opt_a_btn: Button = mc_view.get_node_or_null("OptionsVBox/OptionButton_opt_a") as Button
	var opt_b_btn: Button = mc_view.get_node_or_null("OptionsVBox/OptionButton_opt_b") as Button

	if opt_a_btn == null or opt_b_btn == null:
		print("[PRES-012] FAIL: Option buttons opt_a or opt_b not created inside MultipleChoiceView")
		return false

	if not opt_a_btn.visible or not opt_b_btn.visible:
		print("[PRES-012] FAIL: Option buttons opt_a or opt_b are not visible")
		return false

	# Verify Submit Button
	var submit_btn: Button = panel.get_node_or_null("MainVBox/SubmitButton") as Button
	if submit_btn == null or not submit_btn.visible:
		print("[PRES-012] FAIL: QuestionPanel does not have a visible SubmitButton path")
		return false

	print("[PRES-012] PASS")
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
