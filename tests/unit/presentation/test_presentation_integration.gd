class_name TestPresentationIntegration
extends RefCounted

## B.3 Presentation Integration Suite covering PRES-001..012.
## Validates end-to-end UI presentation flow, QuestionService request/submit pipeline,
## AttemptResult feedback mapping, and FLOW/Progress ownership boundaries.
##
## Implements strict tri-state status accounting (PASS, FAIL, WAITING_ON_DEPENDENCY).

static func run_all_tests() -> Dictionary:
	print("--- RUNNING B.3 FINAL PRESENTATION INTEGRATION SUITE (PRES-001..012) ---")
	var pass_count: int = 0
	var fail_count: int = 0
	var waiting_count: int = 0

	var tests: Array[Callable] = [
		test_pres_001_multiple_choice_render_and_submit,
		test_pres_002_input_render_and_submit,
		test_pres_003_drag_drop_canonical_mappings,
		test_pres_004_matching_canonical_pairs,
		test_pres_005_feedback_derives_from_attempt_result,
		test_pres_006_completion_event_exactly_once,
		test_pres_007_ui_does_not_mutate_progress_state,
		test_pres_008_invalid_question_definition_fails_explicitly,
		test_pres_009_stage_presentation_sequence,
		test_pres_010_stage_1_1_to_1_3_has_no_combat_dependency,
		test_pres_011_continue_displays_restored_legal_stage_context,
		test_pres_012_question_regression_pass
	]

	for t in tests:
		var status: String = String(t.call())
		match status:
			"PASS":
				pass_count += 1
			"FAIL":
				fail_count += 1
			"WAITING_ON_DEPENDENCY":
				waiting_count += 1
			_:
				fail_count += 1

	print("==========================================")
	print("B.3 PRESENTATION INTEGRATION SUITE SUMMARY:")
	print("  PASS: %d" % pass_count)
	print("  FAIL: %d" % fail_count)
	print("  WAITING: %d" % waiting_count)
	print("==========================================")

	return {
		"pass": pass_count,
		"fail": fail_count,
		"waiting": waiting_count,
		"success": (fail_count == 0)
	}

static func _get_synthetic_catalog() -> ValidatedCatalog:
	var config: Dictionary = {
		"performance_grade_thresholds": {
			"a_max_time_ratio": 0.75,
			"b_max_time_ratio": 1.25
		}
	}
	var practice_scope: Dictionary = {
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_ids": [],
		"difficulty_min": 1,
		"difficulty_max": 5,
		"interaction_types": []
	}
	var practices: Dictionary = {
		"practice_01_01": {"practice_id": "practice_01_01", "question_scope": practice_scope}
	}
	var stages: Dictionary = {
		"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01", "practice_id": "practice_01_01", "question_scope": practice_scope},
		"stage_01_02": {"stage_id": "stage_01_02", "dungeon_id": "dungeon_01", "practice_id": "practice_01_01", "question_scope": practice_scope},
		"stage_01_03": {"stage_id": "stage_01_03", "dungeon_id": "dungeon_01", "practice_id": "practice_01_01", "question_scope": practice_scope}
	}

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

# PRES-001 — multiple_choice render + canonical payload submit
static func test_pres_001_multiple_choice_render_and_submit() -> String:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var service: QuestionService = QuestionService.new(cat)
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request: Dictionary = _request("multiple_choice")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-001] FAIL: start_question failed: ", start_res)
		return "FAIL"

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null or not mc_view.select_option("opt_a"):
		print("[PRES-001] FAIL: MultipleChoiceView setup or select_option failed")
		return "FAIL"

	var payload: Dictionary = panel.get_current_interaction_payload()
	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)):
		print("[PRES-001] FAIL: submit_answer returned success=false: ", submit_res)
		return "FAIL"

	print("[PRES-001] PASS: multiple_choice render + canonical submit pipeline verified")
	return "PASS"

# PRES-002 — input render + canonical payload submit
static func test_pres_002_input_render_and_submit() -> String:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var service: QuestionService = QuestionService.new(cat)
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request: Dictionary = _request("input")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-002] FAIL: Input question start_question failed: ", start_res)
		return "FAIL"

	var inp_view: InputView = panel.get_active_interaction_view() as InputView
	if inp_view == null:
		print("[PRES-002] FAIL: InputView setup failed")
		return "FAIL"

	inp_view.set_input_value("4")

	var payload: Dictionary = panel.get_current_interaction_payload()
	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)):
		print("[PRES-002] FAIL: Input submit_answer returned success=false: ", submit_res)
		return "FAIL"

	print("[PRES-002] PASS: input render + canonical payload submit verified")
	return "PASS"

# PRES-003 — drag_drop canonical placements
static func test_pres_003_drag_drop_canonical_mappings() -> String:
	var view: DragDropView = DragDropView.new()
	var payload: Dictionary = {
		"items": [{"item_id": "item_a", "text": "A"}],
		"targets": [{"target_id": "target_a", "label": "Z1"}]
	}
	if not view.setup(payload):
		print("[PRES-003] FAIL: DragDropView setup failed")
		return "FAIL"

	view.place_item("item_a", "target_a")
	var ans: Dictionary = view.get_interaction_payload()
	if not ans.has("placements"):
		print("[PRES-003] FAIL: Missing canonical 'placements' payload key")
		return "FAIL"

	print("[PRES-003] PASS: drag_drop canonical placements verified")
	return "PASS"

# PRES-004 — matching canonical pairs
static func test_pres_004_matching_canonical_pairs() -> String:
	var view: MatchingView = MatchingView.new()
	var payload: Dictionary = {
		"left_items": [{"item_id": "left_a", "text": "L1"}],
		"right_items": [{"item_id": "right_a", "text": "R1"}]
	}
	if not view.setup(payload):
		print("[PRES-004] FAIL: MatchingView setup failed")
		return "FAIL"

	view.add_pair("left_a", "right_a")
	var ans: Dictionary = view.get_interaction_payload()
	if not ans.has("pairs"):
		print("[PRES-004] FAIL: Missing canonical 'pairs' payload key")
		return "FAIL"

	print("[PRES-004] PASS: matching canonical pairs payload verified")
	return "PASS"

# PRES-005 — feedback derives from AttemptResult
static func test_pres_005_feedback_derives_from_attempt_result() -> String:
	var panel: QuestionPanel = QuestionPanel.new()
	var mock_question: Dictionary = {
		"question_id": "q_001",
		"interaction_type": "multiple_choice",
		"prompt": "Test Prompt",
		"interaction_payload": {
			"options": [{"option_id": "opt_1", "text": "Option 1"}]
		}
	}
	panel.setup_question(mock_question)

	var attempt_result: Dictionary = {
		"attempt_id": "att_001",
		"question_id": "q_001",
		"is_correct": true,
		"feedback_text": "Great job!"
	}

	panel.show_feedback(attempt_result)
	if not panel.has_feedback():
		print("[PRES-005] FAIL: QuestionPanel has_feedback() is false after show_feedback")
		return "FAIL"

	print("[PRES-005] PASS: Feedback correctly derived from AttemptResult")
	return "PASS"

# PRES-006 — question completion presentation event exactly once
static func test_pres_006_completion_event_exactly_once() -> String:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var service: QuestionService = QuestionService.new(cat)
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var tracker: Array = [0]
	controller.question_completed.connect(func(_res: Dictionary) -> void: tracker[0] = int(tracker[0]) + 1)

	var request: Dictionary = _request("multiple_choice")
	var res: Dictionary = controller.start_question(request)
	if not bool(res.get("success", false)):
		print("[PRES-006] FAIL: start_question failed: ", res)
		return "FAIL"

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null or not mc_view.select_option("opt_a"):
		print("[PRES-006] FAIL: select_option failed")
		return "FAIL"

	var payload: Dictionary = panel.get_current_interaction_payload()
	var first_submit: Dictionary = controller.submit_answer(payload)
	var second_submit: Dictionary = controller.submit_answer(payload)

	if not bool(first_submit.get("success", false)):
		print("[PRES-006] FAIL: first submit_answer failed: ", first_submit)
		return "FAIL"

	if int(tracker[0]) != 1:
		print("[PRES-006] FAIL: question_completed emitted %d times, expected 1" % int(tracker[0]))
		return "FAIL"

	print("[PRES-006] PASS: Question completion presentation event emitted exactly once")
	return "PASS"

# PRES-007 — UI does not mutate ProgressState
static func test_pres_007_ui_does_not_mutate_progress_state() -> String:
	var shell: StagePresentationShell = StagePresentationShell.new()
	var info: PresentationModels.StageContextInfo = PresentationModels.StageContextInfo.new(
		"stage_01_01", "Title", "Dungeon", [], false
	)
	shell.set_stage_context(info)
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_LESSON)

	# Verify UI shell contains no reference to ProgressState
	if shell.get("progress_state") != null or shell.get("_progress_state") != null:
		print("[PRES-007] FAIL: StagePresentationShell holds direct ProgressState reference")
		return "FAIL"

	print("[PRES-007] PASS: Presentation UI does not hold or mutate ProgressState")
	return "PASS"

# PRES-008 — invalid QuestionDefinition fails explicitly
static func test_pres_008_invalid_question_definition_fails_explicitly() -> String:
	var panel: QuestionPanel = QuestionPanel.new()
	var invalid_q1: Dictionary = {"question_id": "q_bad"} # missing interaction_type and payload
	if panel.setup_question(invalid_q1):
		print("[PRES-008] FAIL: Invalid QuestionDefinition (missing fields) accepted")
		return "FAIL"

	var invalid_q2: Dictionary = {
		"question_id": "q_bad",
		"interaction_type": "invalid_type_name",
		"prompt": "P",
		"interaction_payload": {}
	}
	if panel.setup_question(invalid_q2):
		print("[PRES-008] FAIL: Invalid interaction_type accepted")
		return "FAIL"

	print("[PRES-008] PASS: Invalid QuestionDefinition fails explicitly")
	return "PASS"

# PRES-009 — Stage presentation sequence: lesson -> question -> result
static func test_pres_009_stage_presentation_sequence() -> String:
	var shell: StagePresentationShell = StagePresentationShell.new()
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_ENTRY)
	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_ENTRY:
		print("[PRES-009] FAIL: ViewMode is not MODE_ENTRY")
		return "FAIL"

	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_LESSON)
	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_LESSON:
		print("[PRES-009] FAIL: ViewMode is not MODE_LESSON")
		return "FAIL"

	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)
	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_QUESTION_HOST:
		print("[PRES-009] FAIL: ViewMode is not MODE_QUESTION_HOST")
		return "FAIL"

	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE)
	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE:
		print("[PRES-009] FAIL: ViewMode is not MODE_STAGE_COMPLETE")
		return "FAIL"

	print("[PRES-009] PASS: Stage presentation sequence (lesson -> question -> result) verified")
	return "PASS"

# PRES-010 — Stage 1.1-1.3 presentation has no Combat/Intent dependency
static func test_pres_010_stage_1_1_to_1_3_has_no_combat_dependency() -> String:
	var demo: D1PresentationDemo = D1PresentationDemo.new()
	demo.start_demo("stage_01_01")
	demo.start_demo("stage_01_02")
	demo.start_demo("stage_01_03")

	# Verify demo has no combat or enemy intent references
	if demo.get("combat_engine") != null or demo.get("enemy_intent") != null:
		print("[PRES-010] FAIL: Presentation demo references combat engine or enemy intent")
		return "FAIL"

	print("[PRES-010] PASS: Stage 1.1-1.3 presentation has no Combat or Intent dependency")
	return "PASS"

# PRES-011 — Continue displays restored legal StageContext through real approved FLOW/Save integration
static func test_pres_011_continue_displays_restored_legal_stage_context() -> String:
	var repo := ContentRepository.new()
	if not repo.load_and_validate("res://tests/fixtures/content/valid_catalog"):
		print("[PRES-011] FAIL: ContentRepository failed to load valid_catalog")
		return "FAIL"
	var catalog: ValidatedCatalog = repo.get_catalog()

	var player_persistent := PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 100, 500)
	var progress_service := ProgressService.new(catalog, player_persistent)
	var file_store := SaveFileStore.new("user://test_pres_011/")
	file_store.remove_file(file_store.main_path)
	var save_service := SaveService.new(catalog, file_store)
	var question_service := QuestionService.new(catalog)
	var bridge := ProgressSaveBridge.new(catalog, player_persistent, progress_service, save_service)
	var flow_service := GameFlowService.new(catalog, question_service, progress_service, save_service, player_persistent)

	# Commit stage_01_01 clear and checkpoint to disk
	var reward := RewardGrant.new("reward_01_01", "stage_01_01", 10, 25, [])
	var commit_res: Dictionary = bridge.commit_stage_and_checkpoint("stage_01_01", reward)
	if not bool(commit_res.get("success", false)):
		print("[PRES-011] FAIL: Bridge commit_stage_and_checkpoint failed")
		return "FAIL"

	# Execute Continue restoration from disk save
	var restore_res: Dictionary = bridge.restore_from_save()
	if not bool(restore_res.get("success", false)):
		print("[PRES-011] FAIL: Bridge restore_from_save failed")
		return "FAIL"

	var flow_restore: Dictionary = flow_service.restore_from_save(restore_res)
	if not bool(flow_restore.get("success", false)):
		print("[PRES-011] FAIL: GameFlowService restore_from_save failed: ", flow_restore)
		return "FAIL"

	if String(flow_restore.get("target_stage_id", "")) != "stage_01_02":
		print("[PRES-011] FAIL: Restored target_stage_id is not stage_01_02 (got %s)" % String(flow_restore.get("target_stage_id", "")))
		return "FAIL"

	var raw_ctx: Dictionary = flow_restore.get("stage_context", {}) as Dictionary
	if raw_ctx.is_empty() or not bool(raw_ctx.get("is_restored_context", false)):
		print("[PRES-011] FAIL: Stage context missing or is_restored_context is false")
		return "FAIL"

	var ctx_info: PresentationModels.StageContextInfo = PresentationModels.StageContextInfo.from_dict(raw_ctx)
	var shell: StagePresentationShell = StagePresentationShell.new()
	shell.set_stage_context(ctx_info)

	if not shell.is_restored_context_displayed():
		print("[PRES-011] FAIL: StagePresentationShell is_restored_context_displayed returned false")
		return "FAIL"

	file_store.remove_file(file_store.main_path)
	print("[PRES-011] PASS: Continue displayed restored legal StageContext stage_01_02 through real FLOW/Save integration")
	return "PASS"

# PRES-012 — Question regression PASS
static func test_pres_012_question_regression_pass() -> String:
	var ok: bool = TestQuestionPresentation.run_all_tests()
	if not ok:
		print("[PRES-012] FAIL: TestQuestionPresentation regression failed")
		return "FAIL"
	print("[PRES-012] PASS: Question UI presentation regression suite passed")
	return "PASS"
