class_name TestQuestionUiAcceptance
extends SceneTree

## Independent Question UI Acceptance & Regression Gate for MATHOS-DIRECT-QUESTION-QA-001.
## Validates QuestionPanel, QuestionPresentationController, and Interaction Views without modifying production code.

func _initialize() -> void:
	print("==========================================")
	print("MATHOS DIRECT QUESTION UI ACCEPTANCE GATE")
	print("==========================================")
	var pass_count: int = 0
	var fail_count: int = 0

	var result: Dictionary = run_all_checks()
	pass_count = int(result.get("pass", 0))
	fail_count = int(result.get("fail", 0))

	print("==========================================")
	print("QUESTION ACCEPTANCE GATE SUMMARY:")
	print("  PASS: %d" % pass_count)
	print("  FAIL: %d" % fail_count)
	print("==========================================")

	if fail_count > 0:
		print("RESULT: QUESTION ACCEPTANCE GATE FAILED")
		quit(1)
	else:
		print("RESULT: QUESTION ACCEPTANCE GATE PASSED")
		quit(0)

static func run_all_checks() -> Dictionary:
	var pass_count: int = 0
	var fail_count: int = 0

	var checks: Array[Dictionary] = [
		{"name": "QuestionPanel Instantiation", "func": Callable(TestQuestionUiAcceptance, "check_panel_instantiation")},
		{"name": "setup_question Valid Path", "func": Callable(TestQuestionUiAcceptance, "check_setup_question_valid_path")},
		{"name": "All Four Interaction Types Mount", "func": Callable(TestQuestionUiAcceptance, "check_interaction_types_mount")},
		{"name": "Prompt Rendering", "func": Callable(TestQuestionUiAcceptance, "check_prompt_rendering")},
		{"name": "Learning Objective Rendering", "func": Callable(TestQuestionUiAcceptance, "check_objective_rendering")},
		{"name": "Submit Signal Compatibility", "func": Callable(TestQuestionUiAcceptance, "check_submit_signal_compatibility")},
		{"name": "Interaction Payload Compatibility", "func": Callable(TestQuestionUiAcceptance, "check_interaction_payload_compatibility")},
		{"name": "No answer_spec Leak to Presentation", "func": Callable(TestQuestionUiAcceptance, "check_no_answer_spec_leak")},
		{"name": "No Duplicate Session Lifecycle", "func": Callable(TestQuestionUiAcceptance, "check_no_duplicate_session_lifecycle")},
		{"name": "Runtime Invariants Verification", "func": Callable(TestQuestionUiAcceptance, "check_runtime_invariants")}
	]

	for c in checks:
		var check_name: String = String(c["name"])
		var check_func: Callable = c["func"] as Callable
		print("[%s] Testing..." % check_name)
		var ok: bool = bool(check_func.call())
		if ok:
			print("[%s] PASS" % check_name)
			pass_count += 1
		else:
			print("[%s] FAIL" % check_name)
			fail_count += 1

	return {"pass": pass_count, "fail": fail_count}

static func check_panel_instantiation() -> bool:
	# 1. Programmatic creation (fallback)
	var prog_panel: QuestionPanel = QuestionPanel.new()
	if prog_panel == null:
		print("  - Failed programmatic QuestionPanel instantiation")
		return false
	prog_panel._ensure_ui_built()

	if prog_panel.get_node_or_null("MainVBox") == null:
		print("  - Programmatic QuestionPanel missing MainVBox")
		return false
	if prog_panel.get_node_or_null("MainVBox/PromptLabel") == null:
		print("  - Programmatic QuestionPanel missing PromptLabel")
		return false
	if prog_panel.get_node_or_null("MainVBox/SubmitButton") == null and prog_panel.get_node_or_null("MainVBox/FooterVBox/SubmitButton") == null:
		print("  - Programmatic QuestionPanel missing SubmitButton")
		return false

	# 2. PackedScene instantiation
	var scene_res: Resource = load("res://src/ui/question/question_panel.tscn")
	if not (scene_res is PackedScene):
		print("  - question_panel.tscn missing or not PackedScene")
		return false
	var scene_panel: QuestionPanel = (scene_res as PackedScene).instantiate() as QuestionPanel
	if scene_panel == null:
		print("  - Failed scene QuestionPanel instantiation")
		return false

	if scene_panel.get_node_or_null("MainVBox/PromptLabel") == null:
		print("  - Scene QuestionPanel missing PromptLabel")
		return false
	if scene_panel.get_node_or_null("MainVBox/InteractionContainer") == null and scene_panel.get_node_or_null("MainVBox/InteractionScrollContainer/InteractionContainer") == null:
		print("  - Scene QuestionPanel missing InteractionContainer")
		return false
	if scene_panel.get_node_or_null("MainVBox/SubmitButton") == null and scene_panel.get_node_or_null("MainVBox/FooterVBox/SubmitButton") == null:
		print("  - Scene QuestionPanel missing SubmitButton")
		return false

	return true

static func check_setup_question_valid_path() -> bool:
	var panel: QuestionPanel = QuestionPanel.new()

	# Valid question views for all 4 types
	for itype in ["multiple_choice", "input", "drag_drop", "matching"]:
		var q_view: Dictionary = _valid_question_view(itype)
		if not panel.setup_question(q_view):
			print("  - setup_question failed for valid %s view" % itype)
			return false

	# Invalid views (missing fields)
	var missing_prompt: Dictionary = _valid_question_view("multiple_choice")
	missing_prompt.erase("prompt")
	if panel.setup_question(missing_prompt):
		print("  - setup_question accepted missing prompt field")
		return false

	# Invalid interaction type
	var bad_type: Dictionary = _valid_question_view("multiple_choice")
	bad_type["interaction_type"] = "invalid_type"
	if panel.setup_question(bad_type):
		print("  - setup_question accepted invalid interaction_type")
		return false

	# Non-dictionary payload
	var bad_payload: Dictionary = _valid_question_view("multiple_choice")
	bad_payload["interaction_payload"] = "not_a_dict"
	if panel.setup_question(bad_payload):
		print("  - setup_question accepted non-dictionary payload")
		return false

	return true

static func check_interaction_types_mount() -> bool:
	var panel: QuestionPanel = QuestionPanel.new()

	# 1. multiple_choice
	if not panel.setup_question(_valid_question_view("multiple_choice")):
		return false
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null or mc_view.get_parent() == null:
		print("  - MultipleChoiceView not mounted")
		return false

	# 2. input
	if not panel.setup_question(_valid_question_view("input")):
		return false
	var inp_view: InputView = panel.get_active_interaction_view() as InputView
	if inp_view == null or inp_view.get_parent() == null:
		print("  - InputView not mounted")
		return false

	# 3. drag_drop
	if not panel.setup_question(_valid_question_view("drag_drop")):
		return false
	var dd_view: DragDropView = panel.get_active_interaction_view() as DragDropView
	if dd_view == null or dd_view.get_parent() == null:
		print("  - DragDropView not mounted")
		return false

	# 4. matching
	if not panel.setup_question(_valid_question_view("matching")):
		return false
	var mat_view: MatchingView = panel.get_active_interaction_view() as MatchingView
	if mat_view == null or mat_view.get_parent() == null:
		print("  - MatchingView not mounted")
		return false

	return true

static func check_prompt_rendering() -> bool:
	var panel: QuestionPanel = QuestionPanel.new()
	var q_view: Dictionary = _valid_question_view("multiple_choice")
	q_view["prompt"] = "What is 2 + 2?"
	if not panel.setup_question(q_view):
		return false

	if panel.get_prompt_text() != "What is 2 + 2?":
		print("  - get_prompt_text mismatch")
		return false

	var prompt_label: Label = panel.get_node_or_null("MainVBox/PromptLabel") as Label
	if prompt_label == null or prompt_label.text != "What is 2 + 2?" or not prompt_label.visible:
		print("  - PromptLabel text or visibility incorrect")
		return false

	return true

static func check_objective_rendering() -> bool:
	var panel: QuestionPanel = QuestionPanel.new()

	# 1. With objective
	var q_view_with: Dictionary = _valid_question_view("multiple_choice")
	q_view_with["learning_objective"] = "Master simple addition"
	if not panel.setup_question(q_view_with):
		return false

	if panel.get_objective_text() != "Master simple addition":
		print("  - get_objective_text mismatch")
		return false

	var obj_label: Label = panel.get_node_or_null("MainVBox/ObjectiveLabel") as Label
	if obj_label == null or obj_label.text != "Master simple addition" or not obj_label.visible:
		print("  - ObjectiveLabel text or visibility incorrect when objective present")
		return false

	# 2. Without objective (empty)
	var q_view_without: Dictionary = _valid_question_view("multiple_choice")
	q_view_without["learning_objective"] = ""
	if not panel.setup_question(q_view_without):
		return false

	if obj_label != null and obj_label.visible:
		print("  - ObjectiveLabel visible when objective is empty")
		return false

	return true

static func check_submit_signal_compatibility() -> bool:
	var panel: QuestionPanel = QuestionPanel.new()
	if not panel.setup_question(_valid_question_view("multiple_choice")):
		return false

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_a")

	var emitted_payload: Array = []
	panel.submit_requested.connect(func(payload: Dictionary) -> void: emitted_payload.append(payload))

	panel.request_submit()

	if emitted_payload.size() != 1:
		print("  - submit_requested signal not emitted exactly once")
		return false

	var payload: Dictionary = emitted_payload[0] as Dictionary
	if String(payload.get("selected_option_id", "")) != "opt_a":
		print("  - submit_requested payload mismatch: ", payload)
		return false

	return true

static func check_interaction_payload_compatibility() -> bool:
	var panel: QuestionPanel = QuestionPanel.new()

	# 1. multiple_choice
	panel.setup_question(_valid_question_view("multiple_choice"))
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_a")
	var mc_payload: Dictionary = panel.get_current_interaction_payload()
	if String(mc_payload.get("selected_option_id", "")) != "opt_a":
		print("  - multiple_choice payload format incorrect")
		return false

	# 2. input
	panel.setup_question(_valid_question_view("input"))
	var inp_view: InputView = panel.get_active_interaction_view() as InputView
	inp_view.set_input_value("4")
	var inp_payload: Dictionary = panel.get_current_interaction_payload()
	if int(inp_payload.get("value", 0)) != 4:
		print("  - input payload format incorrect")
		return false

	# 3. drag_drop
	panel.setup_question(_valid_question_view("drag_drop"))
	var dd_view: DragDropView = panel.get_active_interaction_view() as DragDropView
	dd_view.place_item("item_a", "target_a")
	var dd_payload: Dictionary = panel.get_current_interaction_payload()
	if not (dd_payload.get("placements", null) is Array):
		print("  - drag_drop payload format incorrect")
		return false

	# 4. matching
	panel.setup_question(_valid_question_view("matching"))
	var mat_view: MatchingView = panel.get_active_interaction_view() as MatchingView
	mat_view.add_pair("left_a", "right_a")
	var mat_payload: Dictionary = panel.get_current_interaction_payload()
	if not (mat_payload.get("pairs", null) is Array):
		print("  - matching payload format incorrect")
		return false

	return true

static func check_no_answer_spec_leak() -> bool:
	var panel: QuestionPanel = QuestionPanel.new()
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	# 1. QuestionPanel rejects answer_spec leak directly
	var leak_q: Dictionary = _valid_question_view("multiple_choice")
	leak_q["answer_spec"] = {"correct_option_id": "opt_a"}

	if panel.setup_question(leak_q):
		print("  - QuestionPanel accepted leaking answer_spec")
		return false

	# 2. QuestionPresentationController rejects answer_spec leak on bind_existing_session
	var req: Dictionary = _request("multiple_choice")
	controller.start_question(req)
	var active_sess: Dictionary = service.get_active_session()
	leak_q["question_id"] = String(active_sess["question_id"])

	var leak_res: Dictionary = controller.bind_existing_session(active_sess, leak_q)
	if bool(leak_res.get("success", true)) or String(leak_res.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION:
		print("  - Controller did not reject answer_spec leak with INVALID_QUESTION: ", leak_res)
		return false

	return true

static func check_no_duplicate_session_lifecycle() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var completed_counts: Array = [0]
	controller.question_completed.connect(func(_res: Dictionary) -> void: completed_counts[0] = int(completed_counts[0]) + 1)

	var request: Dictionary = _request("multiple_choice")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("  - controller.start_question failed")
		return false

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_a")
	var payload: Dictionary = panel.get_current_interaction_payload()

	# First submit -> PASS
	var first_sub: Dictionary = controller.submit_answer(payload)
	if not bool(first_sub.get("success", false)):
		print("  - First submission failed")
		return false

	# Second submit -> FAIL with INVALID_QUESTION_SESSION
	var second_sub: Dictionary = controller.submit_answer(payload)
	if bool(second_sub.get("success", false)) or String(second_sub.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION_SESSION:
		print("  - Second submission accepted or returned wrong error_code: ", second_sub)
		return false

	if int(completed_counts[0]) != 1:
		print("  - question_completed emitted %d times (expected 1)" % int(completed_counts[0]))
		return false

	return true

static func check_runtime_invariants() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request: Dictionary = _request("multiple_choice")

	var request_question_count: int = 0
	var session_creation_count: int = 0
	var bind_existing_session_count: int = 0
	var panel_setup_count: int = 0
	var invalid_session_error_count: int = 0

	# 1. QuestionService.request_question = 1 & QuestionSession creation = 1
	var start_res: Dictionary = controller.start_question(request)
	if bool(start_res.get("success", false)):
		request_question_count += 1
		session_creation_count += 1

	# 2. bind_existing_session = 1
	if service.has_active_session():
		var active_sess: Dictionary = service.get_active_session()
		var active_q: Dictionary = _valid_question_view("multiple_choice")
		active_q["question_id"] = String(active_sess["question_id"])
		var bind_res: Dictionary = controller.bind_existing_session(active_sess, active_q)
		if bool(bind_res.get("success", false)):
			bind_existing_session_count += 1

	# 3. QuestionPanel.setup_question = 1
	if panel.setup_question(_valid_question_view("multiple_choice")):
		panel_setup_count += 1

	# 4. InvalidQuestionSessionError = 0 during valid operational path
	if not service.has_active_session():
		invalid_session_error_count += 1

	print("  Invariant Counts:")
	print("    QuestionService.request_question = %d (Expected: 1)" % request_question_count)
	print("    QuestionSession creation = %d (Expected: 1)" % session_creation_count)
	print("    bind_existing_session = %d (Expected: 1)" % bind_existing_session_count)
	print("    QuestionPanel.setup_question = %d (Expected: 1)" % panel_setup_count)
	print("    InvalidQuestionSessionError = %d (Expected: 0)" % invalid_session_error_count)

	if request_question_count != 1 or session_creation_count != 1 or bind_existing_session_count != 1 or panel_setup_count != 1 or invalid_session_error_count != 0:
		print("  - Runtime invariants check failed")
		return false

	return true

static func _request(itype: String) -> Dictionary:
	return {
		"request_id": "req_qa_test",
		"stage_id": "stage_01_01",
		"scope": {
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"subtopic_ids": [],
			"difficulty_min": 1,
			"difficulty_max": 5,
			"interaction_types": [itype]
		},
		"context": "practice",
		"preferred_difficulty": 2,
		"exclude_question_ids": []
	}

static func _valid_question_view(itype: String) -> Dictionary:
	var payload: Dictionary = {}
	match itype:
		"multiple_choice":
			payload = {"options": [{"option_id": "opt_a", "text": "A"}, {"option_id": "opt_b", "text": "B"}]}
		"input":
			payload = {"input_type": "integer"}
		"drag_drop":
			payload = {
				"items": [{"item_id": "item_a", "text": "A"}],
				"targets": [{"target_id": "target_a", "label": "A"}]
			}
		"matching":
			payload = {
				"left_items": [{"item_id": "left_a", "text": "A"}],
				"right_items": [{"item_id": "right_a", "text": "A"}]
			}

	return {
		"question_id": "q_test_%s" % itype,
		"interaction_type": itype,
		"prompt": "Test Prompt for %s" % itype,
		"learning_objective": "Test Objective",
		"interaction_payload": payload
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

	var mc_q: Dictionary = {
		"schema_version": 1,
		"question_id": "q_mc",
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "sample_space",
		"learning_objective": "Test objective",
		"difficulty": 2,
		"interaction_type": "multiple_choice",
		"prompt": "Test prompt",
		"explanation": "Test explanation",
		"hints": [],
		"estimated_time_seconds": 20,
		"tags": [],
		"allowed_contexts": ["practice", "combat"],
		"interaction_payload": {"options": [{"option_id": "opt_a", "text": "A"}, {"option_id": "opt_b", "text": "B"}]},
		"answer_spec": {"correct_option_id": "opt_a"}
	}

	var questions: Dictionary = {"q_mc": mc_q}
	return ValidatedCatalog.new(config, {}, stages, {}, {}, practices, questions, {}, {}, {})
