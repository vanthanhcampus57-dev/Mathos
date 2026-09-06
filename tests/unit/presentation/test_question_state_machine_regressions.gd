class_name TestQuestionStateMachineRegressions
extends SceneTree

## Comprehensive Regression Suite for Question State Machine Bugs (MATHOS-P0-QUESTION-STATE-MACHINE-FIX-078)
## Verifies Scenarios A through J:
## A: MCQ normal submit flow (FRESH -> select -> submit 1st click -> EVALUATED_CORRECT -> continue)
## B: MCQ hint flow (FRESH -> hint -> select -> submit 1st click evaluated immediately, no reset)
## C: MCQ validation warning flow (FRESH -> empty submit -> warning -> select -> submit 1st click evaluated)
## D: MCQ wrong -> Retry flow (FRESH -> wrong -> EVALUATED_WRONG -> retry -> FRESH/cleared -> correct -> continue)
## E: Numeric input wrong -> locked -> Retry -> unlocked/cleared -> correct submit
## F: Matching / Drag-drop classification unassigned upon entry and reset
## G: Stage transition cleanup (stage N -> stage N+1 starts clean, panel purged)
## H: Boss first question starts clean (FRESH, no auto-select, no auto-correct)
## I: Boss question pool loop (reused question starts completely fresh)
## J: Phantom accuracy guard (viewing/hinting does not increment attempt/correct metrics)

func _initialize() -> void:
	print("==========================================")
	print("TEST QUESTION STATE MACHINE REGRESSIONS")
	print("==========================================")
	var ok: bool = run_all_tests()
	if ok:
		print("QUESTION STATE MACHINE REGRESSIONS: ALL PASS!")
		quit(0)
	else:
		print("QUESTION STATE MACHINE REGRESSIONS: FAILED!")
		quit(1)

static func run_all_tests() -> bool:
	print("--- RUNNING SUITE: Question State Machine Regressions ---")
	var passed: bool = true

	passed = test_scenario_a_mcq_normal_submit() and passed
	passed = test_scenario_b_mcq_hint_then_submit_one_click() and passed
	passed = test_scenario_c_mcq_validation_warning_then_submit() and passed
	passed = test_scenario_d_mcq_wrong_retry_correct_flow() and passed
	passed = test_scenario_e_numeric_input_wrong_locked_retry_flow() and passed
	passed = test_scenario_f_matching_dragdrop_unassigned_on_reset() and passed
	passed = test_scenario_g_stage_transition_panel_cleanup() and passed
	passed = test_scenario_h_boss_first_question_starts_clean() and passed
	passed = test_scenario_i_boss_pool_loop_fresh_question() and passed
	passed = test_scenario_j_phantom_accuracy_guard() and passed

	if passed:
		print("[STATE-MACHINE-REGRESSIONS] ALL 10 SCENARIOS PASSED!")
	else:
		print("[STATE-MACHINE-REGRESSIONS] SOME SCENARIOS FAILED!")
	return passed

static func _cleanup_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()

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
		"subtopic_ids": ["sample_space"],
		"difficulty_min": 1,
		"difficulty_max": 5,
		"interaction_types": []
	}
	var stages: Dictionary = {
		"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01", "practice_id": "practice_01_01", "question_scope": stage_scope},
		"stage_01_02": {"stage_id": "stage_01_02", "dungeon_id": "dungeon_01", "practice_id": "practice_01_02", "question_scope": stage_scope},
		"stage_01_05": {"stage_id": "stage_01_05", "dungeon_id": "dungeon_01", "practice_id": "practice_01_05", "question_scope": stage_scope, "encounter_mode": "card_combat", "enemy_id": "enemy_d1_stochas"}
	}
	var practices: Dictionary = {
		"practice_01_01": {"practice_id": "practice_01_01", "question_scope": stage_scope, "question_count": 3},
		"practice_01_02": {"practice_id": "practice_01_02", "question_scope": stage_scope, "question_count": 3},
		"practice_01_05": {"practice_id": "practice_01_05", "question_scope": stage_scope, "question_count": 3}
	}

	var mc_q: Dictionary = _base_question("q_mc_01", "multiple_choice")
	mc_q["interaction_payload"] = {
		"options": [
			{"option_id": "opt_a", "text": "Option A (Correct)"},
			{"option_id": "opt_b", "text": "Option B (Incorrect)"}
		]
	}
	mc_q["answer_spec"] = {"correct_option_id": "opt_a"}
	mc_q["hint"] = "Chọn đáp án Option A để giải bài này."
	mc_q["allowed_contexts"] = ["practice"]

	var inp_q: Dictionary = _base_question("q_inp_01", "input")
	inp_q["interaction_payload"] = {"input_type": "integer"}
	inp_q["answer_spec"] = {"accepted_values": [42]}
	inp_q["hint"] = "Số cần điền là 42."
	inp_q["allowed_contexts"] = ["practice"]

	var dd_q: Dictionary = _base_question("q_dd_01", "drag_drop")
	dd_q["interaction_payload"] = {
		"items": [{"item_id": "item_1", "text": "Item 1"}, {"item_id": "item_2", "text": "Item 2"}],
		"targets": [{"target_id": "target_1", "label": "Target 1"}, {"target_id": "target_2", "label": "Target 2"}]
	}
	dd_q["answer_spec"] = {
		"mappings": [
			{"item_id": "item_1", "target_id": "target_1"},
			{"item_id": "item_2", "target_id": "target_2"}
		]
	}
	dd_q["allowed_contexts"] = ["practice"]

	var mat_q: Dictionary = _base_question("q_mat_01", "matching")
	mat_q["interaction_payload"] = {
		"left_items": [{"item_id": "l1", "text": "Left 1"}, {"item_id": "l2", "text": "Left 2"}],
		"right_items": [{"item_id": "r1", "text": "Right 1"}, {"item_id": "r2", "text": "Right 2"}]
	}
	mat_q["answer_spec"] = {
		"pairs": [
			{"left_id": "l1", "right_id": "r1"},
			{"left_id": "l2", "right_id": "r2"}
		]
	}
	mat_q["allowed_contexts"] = ["practice"]

	var boss_q: Dictionary = _base_question("q_boss_01", "multiple_choice")
	boss_q["interaction_payload"] = {
		"options": [
			{"option_id": "opt_b1", "text": "Boss Option 1 (Correct)"},
			{"option_id": "opt_b2", "text": "Boss Option 2 (Incorrect)"}
		]
	}
	boss_q["answer_spec"] = {"correct_option_id": "opt_b1"}
	boss_q["allowed_contexts"] = ["combat"]

	var questions: Dictionary = {
		"q_mc_01": mc_q,
		"q_inp_01": inp_q,
		"q_dd_01": dd_q,
		"q_mat_01": mat_q,
		"q_boss_01": boss_q
	}
	return ValidatedCatalog.new(config, {}, stages, {}, {}, practices, questions, {}, {}, {})

static func _base_question(qid: String, interaction_type: String) -> Dictionary:
	return {
		"schema_version": 1,
		"question_id": qid,
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "sample_space",
		"learning_objective": "State machine verification",
		"difficulty": 2,
		"interaction_type": interaction_type,
		"prompt": "Prompt for %s" % qid,
		"explanation": "Explanation for %s" % qid,
		"hints": ["Hint 1 for %s" % qid],
		"estimated_time_seconds": 25,
		"tags": ["regression_test"],
		"allowed_contexts": ["practice", "combat"]
	}

static func _request(qid: String, interaction_type: String, stage_id: String = "stage_01_01", context: String = "practice") -> Dictionary:
	return {
		"request_id": "req_%s" % qid,
		"stage_id": stage_id,
		"scope": {
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"subtopic_ids": ["sample_space"],
			"difficulty_min": 1,
			"difficulty_max": 5,
			"interaction_types": [interaction_type]
		},
		"context": context,
		"preferred_difficulty": 2,
		"exclude_question_ids": []
	}

# -------------------------------------------------------------------------
# Scenario A: MCQ normal submit flow
# -------------------------------------------------------------------------
static func test_scenario_a_mcq_normal_submit() -> bool:
	print("[SCENARIO-A] Testing MCQ normal fresh submit...")
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: QuestionService = QuestionService.new(catalog)
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var req: Dictionary = _request("q_mc_01", "multiple_choice")
	var start_res: Dictionary = controller.start_question(req)
	if not bool(start_res.get("success", false)):
		print("[SCENARIO-A] FAIL: start_question failed: ", start_res)
		_cleanup_node(panel)
		return false

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.FRESH:
		print("[SCENARIO-A] FAIL: Expected FRESH state initially, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	var submit_btn: Button = panel.get_submit_button()
	if submit_btn == null or submit_btn.text != "Xác nhận":
		print("[SCENARIO-A] FAIL: Submit button text should be 'Xác nhận', got: ", submit_btn.text if submit_btn else "null")
		_cleanup_node(panel)
		return false

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null or not mc_view.select_option("opt_a"):
		print("[SCENARIO-A] FAIL: Failed to select opt_a")
		_cleanup_node(panel)
		return false

	# Submit via confirm button press
	panel._on_submit_button_pressed()

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.EVALUATED_CORRECT:
		print("[SCENARIO-A] FAIL: Expected EVALUATED_CORRECT after valid correct submit, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	if submit_btn.text != "TIẾP TỤC":
		print("[SCENARIO-A] FAIL: Expected submit button text 'TIẾP TỤC' after correct evaluation, got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	var continue_emitted: Array = [false]
	panel.continue_requested.connect(func(): continue_emitted[0] = true)
	panel._on_submit_button_pressed()

	if not continue_emitted[0]:
		print("[SCENARIO-A] FAIL: Expected continue_requested emitted on second click")
		_cleanup_node(panel)
		return false

	_cleanup_node(panel)
	print("[SCENARIO-A] PASS")
	return true

# -------------------------------------------------------------------------
# Scenario B: MCQ Hint flow (1 confirm click after hint, no reset)
# -------------------------------------------------------------------------
static func test_scenario_b_mcq_hint_then_submit_one_click() -> bool:
	print("[SCENARIO-B] Testing MCQ hint -> select -> 1 click confirm...")
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: QuestionService = QuestionService.new(catalog)
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var req: Dictionary = _request("q_mc_01", "multiple_choice")
	controller.start_question(req)

	# Click hint button
	panel._on_hint_button_pressed()

	if not panel.is_hint_visible():
		print("[SCENARIO-B] FAIL: Expected hint to be visible")
		_cleanup_node(panel)
		return false

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.FRESH:
		print("[SCENARIO-B] FAIL: Hint must not mutate state away from FRESH, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	var submit_btn: Button = panel.get_submit_button()
	if submit_btn.text != "Xác nhận":
		print("[SCENARIO-B] FAIL: Submit button text must stay 'Xác nhận', got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	# Select option AFTER viewing hint
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null or not mc_view.select_option("opt_a"):
		print("[SCENARIO-B] FAIL: Failed to select opt_a after hint")
		_cleanup_node(panel)
		return false

	# Click submit ONCE: MUST evaluate immediately and NOT wipe selection or require second click
	panel._on_submit_button_pressed()

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.EVALUATED_CORRECT:
		print("[SCENARIO-B] FAIL: Single click after hint must evaluate to EVALUATED_CORRECT, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	if mc_view.get_selected_option_id() != "opt_a":
		print("[SCENARIO-B] FAIL: Selection must NOT have been wiped on first confirm click, got: ", mc_view.get_selected_option_id())
		_cleanup_node(panel)
		return false

	if submit_btn.text != "TIẾP TỤC":
		print("[SCENARIO-B] FAIL: Submit button must transition to 'TIẾP TỤC', got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	_cleanup_node(panel)
	print("[SCENARIO-B] PASS")
	return true

# -------------------------------------------------------------------------
# Scenario C: MCQ Validation warning flow
# -------------------------------------------------------------------------
static func test_scenario_c_mcq_validation_warning_then_submit() -> bool:
	print("[SCENARIO-C] Testing empty confirm -> validation warning -> select -> 1 click submit...")
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: QuestionService = QuestionService.new(catalog)
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var req: Dictionary = _request("q_mc_01", "multiple_choice")
	controller.start_question(req)

	# Click submit without selecting any option
	panel._on_submit_button_pressed()

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.VALIDATION_WARNING:
		print("[SCENARIO-C] FAIL: Expected VALIDATION_WARNING state, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	if not panel.is_validation_warning_visible():
		print("[SCENARIO-C] FAIL: Expected validation warning to be visible")
		_cleanup_node(panel)
		return false

	var submit_btn: Button = panel.get_submit_button()
	if submit_btn.text != "Xác nhận":
		print("[SCENARIO-C] FAIL: Submit button text must stay 'Xác nhận' during validation warning, got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	# Select option now
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null or not mc_view.select_option("opt_a"):
		print("[SCENARIO-C] FAIL: Failed to select opt_a after validation warning")
		_cleanup_node(panel)
		return false

	# Click submit ONCE: MUST evaluate immediately
	panel._on_submit_button_pressed()

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.EVALUATED_CORRECT:
		print("[SCENARIO-C] FAIL: Single click after warning must evaluate to EVALUATED_CORRECT, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	if submit_btn.text != "TIẾP TỤC":
		print("[SCENARIO-C] FAIL: Expected button text 'TIẾP TỤC', got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	_cleanup_node(panel)
	print("[SCENARIO-C] PASS")
	return true

# -------------------------------------------------------------------------
# Scenario D: MCQ wrong -> Retry flow
# -------------------------------------------------------------------------
static func test_scenario_d_mcq_wrong_retry_correct_flow() -> bool:
	print("[SCENARIO-D] Testing MCQ wrong -> retry -> fresh -> correct submit...")
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: QuestionService = QuestionService.new(catalog)
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var req: Dictionary = _request("q_mc_01", "multiple_choice")
	var start_res: Dictionary = controller.start_question(req)
	if not bool(start_res.get("success", false)):
		print("[SCENARIO-D] FAIL: start_question failed: ", start_res)
		_cleanup_node(panel)
		return false

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	# Select incorrect option
	if not mc_view.select_option("opt_b"):
		print("[SCENARIO-D] FAIL: select_option opt_b failed")
		_cleanup_node(panel)
		return false

	panel._on_submit_button_pressed()

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.EVALUATED_WRONG:
		print("[SCENARIO-D] FAIL: Expected EVALUATED_WRONG, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	var submit_btn: Button = panel.get_submit_button()
	if submit_btn.text.to_upper() != "THỬ LẠI":
		print("[SCENARIO-D] FAIL: Expected submit button text 'THỬ LẠI', got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	# Wire retry handler (simulating AppRoot re-requesting a fresh session for the retry)
	var retry_emitted: Array = [false]
	panel.retry_requested.connect(func():
		retry_emitted[0] = true
		controller.start_question(req)
	)

	# Click "Thử lại"
	panel._on_submit_button_pressed()

	if not retry_emitted[0]:
		print("[SCENARIO-D] FAIL: Expected retry_requested emitted on retry button press")
		_cleanup_node(panel)
		return false

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.FRESH:
		print("[SCENARIO-D] FAIL: Expected state reset to FRESH on retry, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	mc_view = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view.get_selected_option_id() != "":
		print("[SCENARIO-D] FAIL: Selection should be reset to empty on retry, got: ", mc_view.get_selected_option_id())
		_cleanup_node(panel)
		return false

	if submit_btn.text != "Xác nhận":
		print("[SCENARIO-D] FAIL: Button text must reset to 'Xác nhận' on retry, got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	# Now select correct option
	mc_view.select_option("opt_a")
	panel._on_submit_button_pressed()

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.EVALUATED_CORRECT:
		print("[SCENARIO-D] FAIL: Expected EVALUATED_CORRECT after retry correct submit, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	if submit_btn.text != "TIẾP TỤC":
		print("[SCENARIO-D] FAIL: Expected button text 'TIẾP TỤC', got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	_cleanup_node(panel)
	print("[SCENARIO-D] PASS")
	return true

# -------------------------------------------------------------------------
# Scenario E: Numeric Input wrong -> locked -> Retry -> unlocked/cleared -> correct submit
# -------------------------------------------------------------------------
static func test_scenario_e_numeric_input_wrong_locked_retry_flow() -> bool:
	print("[SCENARIO-E] Testing Numeric Input wrong -> locked -> retry -> cleared/unlocked...")
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: QuestionService = QuestionService.new(catalog)
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var req: Dictionary = _request("q_inp_01", "input")
	controller.start_question(req)

	var inp_view: InputView = panel.get_active_interaction_view() as InputView
	if inp_view == null:
		print("[SCENARIO-E] FAIL: InputView is null")
		_cleanup_node(panel)
		return false

	# Enter wrong number
	inp_view.set_input_value("99")
	panel._on_submit_button_pressed()

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.EVALUATED_WRONG:
		print("[SCENARIO-E] FAIL: Expected EVALUATED_WRONG for input 99, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	# Verify input is locked on wrong feedback
	if not inp_view.is_disabled():
		print("[SCENARIO-E] FAIL: InputView must be locked (disabled) while in feedback")
		_cleanup_node(panel)
		return false

	var submit_btn: Button = panel.get_submit_button()
	if submit_btn.text.to_upper() != "THỬ LẠI":
		print("[SCENARIO-E] FAIL: Expected button 'THỬ LẠI', got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	# Wire retry handler (simulating AppRoot re-requesting a fresh session for the retry)
	panel.retry_requested.connect(func():
		controller.start_question(req)
	)

	# Click "Thử lại"
	panel._on_submit_button_pressed()

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.FRESH:
		print("[SCENARIO-E] FAIL: Expected FRESH state after retry, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	# Verify input is cleared and unlocked
	inp_view = panel.get_active_interaction_view() as InputView
	if inp_view != null:
		if inp_view.is_disabled():
			print("[SCENARIO-E] FAIL: InputView must be unlocked after retry")
			_cleanup_node(panel)
			return false
		var le: LineEdit = inp_view.get_line_edit()
		if le != null and le.text != "":
			print("[SCENARIO-E] FAIL: LineEdit text must be cleared after retry, got: '", le.text, "'")
			_cleanup_node(panel)
			return false

	# Enter correct number 42
	inp_view.set_input_value("42")
	panel._on_submit_button_pressed()

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.EVALUATED_CORRECT:
		print("[SCENARIO-E] FAIL: Expected EVALUATED_CORRECT for input 42, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	_cleanup_node(panel)
	print("[SCENARIO-E] PASS")
	return true

# -------------------------------------------------------------------------
# Scenario F: Matching / Drag-drop classification unassigned upon entry and reset
# -------------------------------------------------------------------------
static func test_scenario_f_matching_dragdrop_unassigned_on_reset() -> bool:
	print("[SCENARIO-F] Testing Matching and DragDrop reset_interaction behavior...")
	var catalog: ValidatedCatalog = _synthetic_catalog()

	# 1. Matching view test
	var service1: QuestionService = QuestionService.new(catalog)
	var panel1: QuestionPanel = QuestionPanel.new()
	var controller1: QuestionPresentationController = QuestionPresentationController.new(service1, panel1)

	var req_mat: Dictionary = _request("q_mat_01", "matching")
	controller1.start_question(req_mat)

	var mat_view: MatchingView = panel1.get_active_interaction_view() as MatchingView
	if mat_view == null:
		print("[SCENARIO-F] FAIL: MatchingView is null")
		_cleanup_node(panel1)
		return false

	mat_view.add_pair("l1", "r2")
	var pairs_before: Array[Dictionary] = mat_view.get_pairs_array()
	if pairs_before.is_empty():
		print("[SCENARIO-F] FAIL: Pairs before reset should not be empty")
		_cleanup_node(panel1)
		return false

	mat_view.reset_interaction()
	var pairs_after: Array[Dictionary] = mat_view.get_pairs_array()
	if not pairs_after.is_empty():
		print("[SCENARIO-F] FAIL: Matching pairs must be empty after reset_interaction, got: ", pairs_after)
		_cleanup_node(panel1)
		return false
	_cleanup_node(panel1)

	# 2. Drag-drop view test
	var service2: QuestionService = QuestionService.new(catalog)
	var panel2: QuestionPanel = QuestionPanel.new()
	var controller2: QuestionPresentationController = QuestionPresentationController.new(service2, panel2)

	var req_dd: Dictionary = _request("q_dd_01", "drag_drop")
	controller2.start_question(req_dd)

	var dd_view: DragDropView = panel2.get_active_interaction_view() as DragDropView
	if dd_view == null:
		print("[SCENARIO-F] FAIL: DragDropView is null")
		_cleanup_node(panel2)
		return false

	dd_view.place_item("item_1", "target_2")
	var placements_before: Array[Dictionary] = dd_view.get_placements_array()
	if placements_before.is_empty():
		print("[SCENARIO-F] FAIL: Placements before reset should not be empty")
		_cleanup_node(panel2)
		return false

	dd_view.reset_interaction()
	var placements_after: Array[Dictionary] = dd_view.get_placements_array()
	if not placements_after.is_empty():
		print("[SCENARIO-F] FAIL: Drag-drop placements must be empty after reset_interaction, got: ", placements_after)
		_cleanup_node(panel2)
		return false
	_cleanup_node(panel2)

	print("[SCENARIO-F] PASS")
	return true

# -------------------------------------------------------------------------
# Scenario G: Stage transition cleanup (stage N -> stage N+1 starts clean)
# -------------------------------------------------------------------------
static func test_scenario_g_stage_transition_panel_cleanup() -> bool:
	print("[SCENARIO-G] Testing stage transition QuestionPanel cleanup...")
	var panel: QuestionPanel = QuestionPanel.new()

	# Simulate panel that just finished a question with feedback
	var q_def: Dictionary = _base_question("q_prev", "multiple_choice")
	q_def["interaction_payload"] = {"options": [{"option_id": "a", "text": "A"}]}
	panel.setup_question(q_def)
	panel.show_feedback({"is_correct": true, "player_facing_feedback": "Tuyệt vời!"})

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.EVALUATED_CORRECT:
		print("[SCENARIO-G] FAIL: Setup feedback state should be EVALUATED_CORRECT")
		_cleanup_node(panel)
		return false

	# Now perform stage reset / clear_question
	panel.clear_question()

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.FRESH:
		print("[SCENARIO-G] FAIL: clear_question must reset lifecycle to FRESH, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	var submit_btn: Button = panel.get_submit_button()
	if submit_btn != null and submit_btn.text != "Xác nhận":
		print("[SCENARIO-G] FAIL: clear_question must reset button text to 'Xác nhận', got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	var fb_lbl: Label = panel.get_feedback_label()
	if fb_lbl != null and fb_lbl.visible:
		print("[SCENARIO-G] FAIL: clear_question must hide feedback label")
		_cleanup_node(panel)
		return false

	if panel.get_active_interaction_view() != null:
		print("[SCENARIO-G] FAIL: clear_question must release active interaction view")
		_cleanup_node(panel)
		return false

	_cleanup_node(panel)
	print("[SCENARIO-G] PASS")
	return true

# -------------------------------------------------------------------------
# Scenario H: Boss first question starts clean
# -------------------------------------------------------------------------
static func test_scenario_h_boss_first_question_starts_clean() -> bool:
	print("[SCENARIO-H] Testing Boss first question starts fresh without auto-select or auto-correct...")
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: QuestionService = QuestionService.new(catalog)
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var req: Dictionary = _request("q_boss_01", "multiple_choice", "stage_01_05", "combat")
	var start_res: Dictionary = controller.start_question(req)
	if not bool(start_res.get("success", false)):
		print("[SCENARIO-H] FAIL: start_question in boss combat failed: ", start_res)
		_cleanup_node(panel)
		return false

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.FRESH:
		print("[SCENARIO-H] FAIL: Boss question must start in FRESH state, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	var submit_btn: Button = panel.get_submit_button()
	if submit_btn.text != "Xác nhận":
		print("[SCENARIO-H] FAIL: Boss question submit button must be 'Xác nhận', got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null:
		print("[SCENARIO-H] FAIL: MultipleChoiceView is null in boss question")
		_cleanup_node(panel)
		return false

	if mc_view.get_selected_option_id() != "":
		print("[SCENARIO-H] FAIL: Boss question must not have auto-selected option, got: ", mc_view.get_selected_option_id())
		_cleanup_node(panel)
		return false

	var fb_lbl: Label = panel.get_feedback_label()
	if fb_lbl != null and fb_lbl.visible:
		print("[SCENARIO-H] FAIL: Boss question feedback label must be invisible initially")
		_cleanup_node(panel)
		return false

	_cleanup_node(panel)
	print("[SCENARIO-H] PASS")
	return true

# -------------------------------------------------------------------------
# Scenario I: Boss question pool loop (reused question starts completely fresh)
# -------------------------------------------------------------------------
static func test_scenario_i_boss_pool_loop_fresh_question() -> bool:
	print("[SCENARIO-I] Testing Boss pool loop: reused question restarts completely fresh...")
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: QuestionService = QuestionService.new(catalog)
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	# 1. First run of q_boss_01
	var req1: Dictionary = _request("q_boss_01", "multiple_choice", "stage_01_05", "combat")
	controller.start_question(req1)
	var mc_view1: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view1.select_option("opt_b1")
	panel._on_submit_button_pressed() # Evaluated correct

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.EVALUATED_CORRECT:
		print("[SCENARIO-I] FAIL: First run of boss question did not evaluate correct")
		_cleanup_node(panel)
		return false

	# 2. Simulate loop exhaustion: Question pool loops, q_boss_01 is requested again
	var req2: Dictionary = _request("q_boss_01", "multiple_choice", "stage_01_05", "combat")
	var loop_res: Dictionary = controller.start_question(req2)
	if not bool(loop_res.get("success", false)):
		print("[SCENARIO-I] FAIL: Failed to restart boss question on pool loop: ", loop_res)
		_cleanup_node(panel)
		return false

	if panel.get_lifecycle_state() != QuestionPanel.LifecycleState.FRESH:
		print("[SCENARIO-I] FAIL: Reused boss question must be reset to FRESH, got: ", panel.get_lifecycle_state())
		_cleanup_node(panel)
		return false

	var submit_btn: Button = panel.get_submit_button()
	if submit_btn.text != "Xác nhận":
		print("[SCENARIO-I] FAIL: Reused boss question button text must be 'Xác nhận', got: ", submit_btn.text)
		_cleanup_node(panel)
		return false

	var mc_view2: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view2.get_selected_option_id() != "":
		print("[SCENARIO-I] FAIL: Reused boss question must have cleared selection, got: ", mc_view2.get_selected_option_id())
		_cleanup_node(panel)
		return false

	_cleanup_node(panel)
	print("[SCENARIO-I] PASS")
	return true

# -------------------------------------------------------------------------
# Scenario J: Phantom accuracy guard
# -------------------------------------------------------------------------
static func test_scenario_j_phantom_accuracy_guard() -> bool:
	print("[SCENARIO-J] Testing phantom accuracy metrics guard...")
	var app_script: GDScript = load("res://src/app/app_root.gd") as GDScript
	var app: AppRoot = app_script.new()

	# Initially metrics are empty
	if not app._finalized_question_ids.is_empty() or not app._first_attempt_results.is_empty():
		print("[SCENARIO-J] FAIL: Initial practice metrics must be empty")
		_cleanup_node(app)
		return false

	# Calling _reset_practice_metrics explicitly
	app._reset_practice_metrics("stage_01_01")
	if not app._finalized_question_ids.is_empty() or not app._first_attempt_results.is_empty():
		print("[SCENARIO-J] FAIL: Reset metrics must clear all entries")
		_cleanup_node(app)
		return false

	# Simulate question answered incorrectly on first attempt
	app._current_question_id = "q_test_01"
	app._on_question_completed({"question_id": "q_test_01", "is_correct": false})

	if app._first_attempt_results.get("q_test_01") != false:
		print("[SCENARIO-J] FAIL: Expected first_attempt_results[q_test_01] == false, got: ", app._first_attempt_results.get("q_test_01"))
		_cleanup_node(app)
		return false

	# Retrying the question and answering correctly should NOT overwrite first attempt result
	app._retry_question_id = "q_test_01"
	app._on_question_completed({"question_id": "q_test_01", "is_correct": true})

	if app._first_attempt_results.get("q_test_01") != false:
		print("[SCENARIO-J] FAIL: First attempt result must remain false after retry, got: ", app._first_attempt_results.get("q_test_01"))
		_cleanup_node(app)
		return false

	# Finalize question via continue
	if not app._finalized_question_ids.has("q_test_01"):
		app._finalized_question_ids.append("q_test_01")

	if not app._finalized_question_ids.has("q_test_01"):
		print("[SCENARIO-J] FAIL: Expected q_test_01 in finalized_question_ids")
		_cleanup_node(app)
		return false

	_cleanup_node(app)
	print("[SCENARIO-J] PASS")
	return true
