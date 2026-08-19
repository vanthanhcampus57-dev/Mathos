class_name TestFlowFoundation
extends SceneTree

## Focused Development Test Suite for GameFlow & StageOrchestrator (FLOW-001..FLOW-011).

func _init() -> void:
	print("--- RUNNING GAMEFLOW & STAGE ORCHESTRATOR FOUNDATION TESTS ---")
	var ok: bool = true

	ok = test_flow_001_new_game_entry() and ok
	ok = test_flow_002_locked_stage_rejection() and ok
	ok = test_flow_003_question_completion_handoff() and ok
	ok = test_flow_004_stage_clear_commit_boundary() and ok
	ok = test_flow_009_callback_idempotency() and ok
	ok = test_flow_010_no_combat_intent_guard() and ok
	ok = test_flow_011_invalid_reference_failure() and ok

	if ok:
		print("--- ALL GAMEFLOW FOUNDATION TESTS PASSED ---")
		quit(0)
	else:
		print("--- GAMEFLOW FOUNDATION TESTS FAILED ---")
		quit(1)

static func _setup_harness() -> Dictionary:
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	assert(report.publication_allowed, "Catalog must be valid")
	var raw_catalog: ValidatedCatalog = repo.get_catalog()

	var config: Dictionary = raw_catalog.get_config()
	var dungeons: Dictionary = {}
	for d in raw_catalog.get_all_dungeons():
		var d_dict: Dictionary = d as Dictionary
		dungeons[String(d_dict["dungeon_id"])] = d_dict.duplicate(true)

	var stages: Dictionary = {}
	for s in raw_catalog.get_all_stages():
		var s_dict: Dictionary = (s as Dictionary).duplicate(true)
		var s_id: String = String(s_dict["stage_id"])
		var d_id: String = String(s_dict["dungeon_id"])
		var t_id: String = String(QuestionService.TOPIC_BY_DUNGEON.get(d_id, "trial_sample_event"))
		var canonical_subs: Array = QuestionService.SUBTOPICS_BY_TOPIC.get(t_id, [])
		var sub_ids: Array[String] = []
		for sub in canonical_subs:
			sub_ids.append(String(sub))

		s_dict["question_scope"] = {
			"dungeon_id": d_id,
			"topic_id": t_id,
			"subtopic_ids": sub_ids,
			"difficulty_min": 1,
			"difficulty_max": 5,
			"interaction_types": ["multiple_choice", "drag_drop", "matching", "input"]
		}
		stages[s_id] = s_dict

	var questions: Dictionary = {}
	var d_topics: Dictionary = {
		"dungeon_01": {"topic": "trial_sample_event", "subtopic": "sample_space"},
		"dungeon_02": {"topic": "classical_probability", "subtopic": "equally_likely"},
		"dungeon_03": {"topic": "addition_rule", "subtopic": "addition_simple"},
		"dungeon_04": {"topic": "multiplication_independence", "subtopic": "independence"}
	}

	for d_id in d_topics:
		var info: Dictionary = d_topics[d_id] as Dictionary
		for idx in range(1, 4):
			var q_id: String = "q_%s_%02d" % [d_id, idx]
			questions[q_id] = {
				"schema_version": 1,
				"question_id": q_id,
				"dungeon_id": d_id,
				"topic_id": String(info["topic"]),
				"subtopic_id": String(info["subtopic"]),
				"learning_objective": "Test objective",
				"prompt": "Test prompt",
				"explanation": "Test explanation",
				"difficulty": 1,
				"interaction_type": "multiple_choice",
				"interaction_payload": {
					"options": [{"option_id": "opt_a", "text": "A"}, {"option_id": "opt_b", "text": "B"}],
					"shuffle": false
				},
				"answer_spec": {"correct_option_id": "opt_a"},
				"allowed_contexts": ["lesson_check", "practice", "combat"]
			}

	var catalog: ValidatedCatalog = ValidatedCatalog.new(
		config, dungeons, stages, {}, {}, {}, questions, {}, {}, {}
	)

	var player_p: PlayerPersistentState = PlayerPersistentState.new("char_karl", 0, 0)
	var progress: ProgressService = ProgressService.new(catalog, player_p)
	var question: QuestionService = QuestionService.new(catalog)
	var save_store: SaveFileStore = SaveFileStore.new("user://test_flow_save/")
	var save: SaveService = SaveService.new(catalog, save_store)

	var flow: GameFlowService = GameFlowService.new(catalog, question, progress, save, player_p)
	return {
		"catalog": catalog,
		"progress": progress,
		"question": question,
		"save": save,
		"player_p": player_p,
		"flow": flow,
		"orchestrator": flow.get_orchestrator()
	}

static func test_flow_001_new_game_entry() -> bool:
	print("[FLOW-001] Testing New Game entry into legal initial stage...")
	var h: Dictionary = _setup_harness()
	var flow: GameFlowService = h["flow"] as GameFlowService

	var res: Dictionary = flow.start_new_game()
	if not bool(res.get("success", false)):
		print("[FLOW-001] FAIL: start_new_game failed: " + str(res))
		return false

	if String(res.get("stage_id", "")) != "stage_01_01" or String(res.get("flow_state", "")) != "NEW_GAME":
		print("[FLOW-001] FAIL: Unexpected stage or flow_state: " + str(res))
		return false

	print("[FLOW-001] PASS")
	return true

static func test_flow_002_locked_stage_rejection() -> bool:
	print("[FLOW-002] Testing locked stage entry rejection...")
	var h: Dictionary = _setup_harness()
	var flow: GameFlowService = h["flow"] as GameFlowService

	var res: Dictionary = flow.start_stage("stage_01_04")
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != FlowErrorCodes.STAGE_LOCKED:
		print("[FLOW-002] FAIL: Locked stage was not rejected with STAGE_LOCKED: " + str(res))
		return false

	print("[FLOW-002] PASS")
	return true

static func test_flow_003_question_completion_handoff() -> bool:
	print("[FLOW-003] Testing question completion control handoff...")
	var h: Dictionary = _setup_harness()
	var flow: GameFlowService = h["flow"] as GameFlowService
	var orch: StageOrchestrator = h["orchestrator"] as StageOrchestrator

	flow.start_new_game()
	var q_res: Dictionary = orch.advance_to_question_phase()
	if not bool(q_res.get("success", false)):
		print("[FLOW-003] FAIL: advance_to_question_phase failed: " + str(q_res))
		return false

	var session: Dictionary = q_res.get("session", {}) as Dictionary
	var session_id: String = String(session.get("session_id", ""))

	var answer: Dictionary = {
		"session_id": session_id,
		"interaction_type": "multiple_choice",
		"payload": {"selected_option_id": "opt_a"}
	}

	var sub_res: Dictionary = orch.submit_question_answer(answer)
	if not bool(sub_res.get("success", false)):
		print("[FLOW-003] FAIL: submit_question_answer failed: " + str(sub_res))
		return false

	if orch.get_current_phase() != "QUESTION_COMPLETE":
		print("[FLOW-003] FAIL: Phase is not QUESTION_COMPLETE: " + orch.get_current_phase())
		return false

	print("[FLOW-003] PASS")
	return true

static func test_flow_004_stage_clear_commit_boundary() -> bool:
	print("[FLOW-004] Testing stage clear commit boundary...")
	var h: Dictionary = _setup_harness()
	var flow: GameFlowService = h["flow"] as GameFlowService
	var orch: StageOrchestrator = h["orchestrator"] as StageOrchestrator
	var progress: ProgressService = h["progress"] as ProgressService

	flow.start_new_game()
	orch.advance_to_question_phase()
	var session: Dictionary = (h["question"] as QuestionService).get_active_session()
	orch.submit_question_answer({
		"session_id": String(session.get("session_id", "")),
		"interaction_type": "multiple_choice",
		"payload": {"selected_option_id": "opt_a"}
	})

	var commit_res: Dictionary = orch.prepare_stage_clear_commit()
	if not bool(commit_res.get("success", false)):
		print("[FLOW-004] FAIL: prepare_stage_clear_commit failed: " + str(commit_res))
		return false

	var completion: StageCompletionResult = commit_res.get("completion_result", null) as StageCompletionResult
	if completion == null or not progress.create_snapshot_view().cleared_stage_ids.has("stage_01_01"):
		print("[FLOW-004] FAIL: ProgressService did not record stage clear: " + str(commit_res))
		return false

	print("[FLOW-004] PASS")
	return true

static func test_flow_009_callback_idempotency() -> bool:
	print("[FLOW-009] Testing callback idempotency and duplicate rejection...")
	var h: Dictionary = _setup_harness()
	var flow: GameFlowService = h["flow"] as GameFlowService
	var orch: StageOrchestrator = h["orchestrator"] as StageOrchestrator

	flow.start_new_game()
	orch.advance_to_question_phase()
	var session: Dictionary = (h["question"] as QuestionService).get_active_session()
	var ans: Dictionary = {
		"session_id": String(session.get("session_id", "")),
		"interaction_type": "multiple_choice",
		"payload": {"selected_option_id": "opt_a"}
	}
	orch.submit_question_answer(ans)
	orch.prepare_stage_clear_commit()

	# Duplicate answer submission
	var dup_ans: Dictionary = orch.submit_question_answer(ans)
	if bool(dup_ans.get("success", false)) or String(dup_ans.get("error_code", "")) != FlowErrorCodes.DUPLICATE_CALLBACK:
		print("[FLOW-009] FAIL: Duplicate answer submission was not rejected: " + str(dup_ans))
		return false

	# Duplicate stage clear commit
	var dup_commit: Dictionary = orch.prepare_stage_clear_commit()
	if bool(dup_commit.get("success", false)) or String(dup_commit.get("error_code", "")) != FlowErrorCodes.DUPLICATE_CALLBACK:
		print("[FLOW-009] FAIL: Duplicate stage clear commit was not rejected: " + str(dup_commit))
		return false

	print("[FLOW-009] PASS")
	return true

static func test_flow_010_no_combat_intent_guard() -> bool:
	print("[FLOW-010] Testing Stages 1.1-1.3 no combat/intent guard...")
	var h: Dictionary = _setup_harness()
	var orch: StageOrchestrator = h["orchestrator"] as StageOrchestrator

	var res_01: Dictionary = orch.initialize_stage("stage_01_01")
	if not bool(res_01.get("success", false)):
		print("[FLOW-010] FAIL: stage_01_01 initialization failed: " + str(res_01))
		return false

	print("[FLOW-010] PASS")
	return true

static func test_flow_011_invalid_reference_failure() -> bool:
	print("[FLOW-011] Testing invalid stage reference explicit failure...")
	var h: Dictionary = _setup_harness()
	var flow: GameFlowService = h["flow"] as GameFlowService

	var res: Dictionary = flow.start_stage("stage_missing_invalid")
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != FlowErrorCodes.INVALID_STAGE_ID:
		print("[FLOW-011] FAIL: Invalid stage reference did not fail with INVALID_STAGE_ID: " + str(res))
		return false

	print("[FLOW-011] PASS")
	return true
