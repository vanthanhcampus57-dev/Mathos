class_name TestFlowFoundation
extends RefCounted

## Unit and integration tests for Mathos GameFlowService and StageOrchestrator foundation.
## Verifies FLOW-001..011, StageContext lifecycle, Continue restoration, and Next Stage transitions.

static func run_all_tests() -> bool:
	print("--- RUNNING GAMEFLOW & STAGEORCHESTRATOR FOUNDATION TESTS ---")
	var all_ok: bool = true

	all_ok = test_flow_001_new_game_entry() and all_ok
	all_ok = test_flow_002_locked_stage_rejection() and all_ok
	all_ok = test_flow_003_practice_question_scope_session() and all_ok
	all_ok = test_flow_004_one_shot_stage_clear_handoff() and all_ok
	all_ok = test_flow_009_callback_idempotency_guard() and all_ok
	all_ok = test_flow_010_no_combat_or_intent_in_d1() and all_ok
	all_ok = test_flow_011_explicit_invalid_stage_or_content() and all_ok
	all_ok = test_flow_stage_context_lifecycle() and all_ok
	all_ok = test_flow_continue_restore_lifecycle() and all_ok
	all_ok = test_flow_next_stage_transition() and all_ok

	return all_ok

static func _build_test_harness(restored_progress_state: ProgressState = null) -> Dictionary:
	var cat_script = preload("res://src/content/repositories/validated_catalog.gd")
	var config: Dictionary = {
		"initial_dungeon_id": "dungeon_01",
		"initial_stage_id": "stage_01_01",
		"performance_grade_thresholds": {"S": 0.9, "A": 0.8, "B": 0.7, "C": 0.6}
	}
	var dungeon: Dictionary = {
		"dungeon_01": {
			"dungeon_id": "dungeon_01",
			"title": "Trial Dungeon",
			"stage_ids": ["stage_01_01", "stage_01_02", "stage_01_03"],
			"fragment_id": "fragment_01"
		}
	}
	var stage_scope: Dictionary = {
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_ids": ["sample_space"],
		"difficulty_min": 1,
		"difficulty_max": 3,
		"interaction_types": ["multiple_choice"]
	}
	var stages: Dictionary = {
		"stage_01_01": {
			"stage_id": "stage_01_01",
			"dungeon_id": "dungeon_01",
			"practice_id": "practice_01_01",
			"lesson_id": "lesson_01_01",
			"reward_id": "reward_01_01",
			"encounter_mode": "puzzle_onboarding",
			"intent_enabled": false
		},
		"stage_01_02": {
			"stage_id": "stage_01_02",
			"dungeon_id": "dungeon_01",
			"practice_id": "practice_01_02",
			"lesson_id": "lesson_01_02",
			"reward_id": "reward_01_02",
			"encounter_mode": "puzzle_onboarding",
			"intent_enabled": false
		},
		"stage_01_03": {
			"stage_id": "stage_01_03",
			"dungeon_id": "dungeon_01",
			"practice_id": "practice_01_03",
			"lesson_id": "lesson_01_03",
			"reward_id": "reward_01_03",
			"encounter_mode": "puzzle_onboarding",
			"intent_enabled": false
		}
	}
	var rewards: Dictionary = {
		"reward_01_01": {"reward_id": "reward_01_01", "stage_id": "stage_01_01", "coin_delta": 10, "exp_delta": 20},
		"reward_01_02": {"reward_id": "reward_01_02", "stage_id": "stage_01_02", "coin_delta": 10, "exp_delta": 20},
		"reward_01_03": {"reward_id": "reward_01_03", "stage_id": "stage_01_03", "coin_delta": 10, "exp_delta": 20}
	}
	var lessons: Dictionary = {
		"lesson_01_01": {
			"lesson_id": "lesson_01_01",
			"title": "Intro to Probability",
			"sections": [{"header": "Welcome", "body": "Basic concepts"}]
		},
		"lesson_01_02": {
			"lesson_id": "lesson_01_02",
			"title": "Sample Spaces",
			"sections": [{"header": "Definition", "body": "All possible outcomes"}]
		}
	}
	var practice: Dictionary = {
		"practice_01_01": {
			"practice_id": "practice_01_01",
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"question_scope": stage_scope
		},
		"practice_01_02": {
			"practice_id": "practice_01_02",
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"question_scope": stage_scope
		},
		"practice_01_03": {
			"practice_id": "practice_01_03",
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"question_scope": stage_scope
		}
	}
	var mc_q: Dictionary = {
		"question_id": "q_mc_01",
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "sample_space",
		"difficulty": 1,
		"interaction_type": "multiple_choice",
		"prompt": "Pick A",
		"explanation": "Sample explanation",
		"allowed_contexts": ["practice", "combat"],
		"interaction_payload": {
			"options": [{"option_id": "opt_a", "text": "Option A"}]
		},
		"answer_spec": {"correct_option_id": "opt_a"}
	}
	var questions: Dictionary = {"q_mc_01": mc_q}

	var player_state: PlayerPersistentState = PlayerPersistentState.new()
	var catalog: ValidatedCatalog = cat_script.new(config, dungeon, stages, {}, lessons, practice, questions, {}, {}, rewards)
	var q_service: QuestionService = QuestionService.new(catalog)
	var prog_service: ProgressService = ProgressService.new(catalog, player_state, restored_progress_state)
	var flow_service: GameFlowService = GameFlowService.new(catalog, q_service, prog_service)

	return {
		"catalog": catalog,
		"question_service": q_service,
		"progress_service": prog_service,
		"flow_service": flow_service
	}

# FLOW-001 — Legal New Game Entry
static func test_flow_001_new_game_entry() -> bool:
	print("[FLOW-001] Testing legal New Game entry...")
	var harness: Dictionary = _build_test_harness()
	var flow: GameFlowService = harness["flow_service"] as GameFlowService

	var res: Dictionary = flow.start_new_game()
	if not bool(res.get("success", false)):
		print("[FLOW-001] FAIL: start_new_game failed: ", res)
		return false
	if String(res.get("stage_id", "")) != "stage_01_01":
		print("[FLOW-001] FAIL: Unexpected stage_id: ", res.get("stage_id"))
		return false
	if flow.get_flow_state() != "NEW_GAME":
		print("[FLOW-001] FAIL: Unexpected flow state: ", flow.get_flow_state())
		return false
	print("[FLOW-001] PASS")
	return true

# FLOW-002 — Locked Stage Entry Rejection
static func test_flow_002_locked_stage_rejection() -> bool:
	print("[FLOW-002] Testing locked stage entry rejection...")
	var harness: Dictionary = _build_test_harness()
	var flow: GameFlowService = harness["flow_service"] as GameFlowService

	var res: Dictionary = flow.start_stage("stage_01_03")
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != FlowErrorCodes.STAGE_LOCKED:
		print("[FLOW-002] FAIL: Locked stage not rejected: ", res)
		return false
	print("[FLOW-002] PASS")
	return true

# FLOW-003 — Valid Practice Question Scope Session Activation & Completion Handoff
static func test_flow_003_practice_question_scope_session() -> bool:
	print("[FLOW-003] Testing Question session activation and completion handoff...")
	var harness: Dictionary = _build_test_harness()
	var flow: GameFlowService = harness["flow_service"] as GameFlowService
	flow.start_new_game()

	var orch: StageOrchestrator = flow.get_orchestrator()
	var adv_res: Dictionary = orch.advance_to_question_phase()
	if not bool(adv_res.get("success", false)):
		print("[FLOW-003] FAIL: advance_to_question_phase failed: ", adv_res)
		return false
	if orch.get_current_phase() != "QUESTION_ACTIVE":
		print("[FLOW-003] FAIL: Phase is not QUESTION_ACTIVE: ", orch.get_current_phase())
		return false

	var sub_res: Dictionary = orch.submit_question_answer({
		"session_id": String(adv_res.get("session", {}).get("session_id", "")),
		"interaction_type": "multiple_choice",
		"payload": {"selected_option_id": "opt_a"}
	})
	if not bool(sub_res.get("success", false)):
		print("[FLOW-003] FAIL: submit_question_answer failed: ", sub_res)
		return false
	if orch.get_current_phase() != "QUESTION_COMPLETE":
		print("[FLOW-003] FAIL: Phase is not QUESTION_COMPLETE: ", orch.get_current_phase())
		return false

	print("[FLOW-003] PASS")
	return true

# FLOW-004 — One-Shot Stage-Clear Handoff Boundary
static func test_flow_004_one_shot_stage_clear_handoff() -> bool:
	print("[FLOW-004] Testing one-shot stage-clear handoff boundary...")
	var harness: Dictionary = _build_test_harness()
	var flow: GameFlowService = harness["flow_service"] as GameFlowService
	flow.start_new_game()
	var orch: StageOrchestrator = flow.get_orchestrator()

	var adv_res: Dictionary = orch.advance_to_question_phase()
	var session_id: String = String((adv_res.get("session", {}) as Dictionary).get("session_id", ""))
	orch.submit_question_answer({
		"session_id": session_id,
		"interaction_type": "multiple_choice",
		"payload": {"selected_option_id": "opt_a"}
	})

	var prep_res: Dictionary = orch.prepare_stage_clear_commit()
	if not bool(prep_res.get("success", false)):
		print("[FLOW-004] FAIL: First prepare_stage_clear_commit failed: ", prep_res)
		return false
	if orch.get_current_phase() != "COMPLETED":
		print("[FLOW-004] FAIL: Phase is not COMPLETED: ", orch.get_current_phase())
		return false

	var dup_res: Dictionary = orch.prepare_stage_clear_commit()
	if bool(dup_res.get("success", false)) or String(dup_res.get("error_code", "")) != FlowErrorCodes.DUPLICATE_CALLBACK:
		print("[FLOW-004] FAIL: Duplicate stage clear handoff not rejected: ", dup_res)
		return false

	print("[FLOW-004] PASS")
	return true

# FLOW-009 — Callback Idempotency Guard
static func test_flow_009_callback_idempotency_guard() -> bool:
	print("[FLOW-009] Testing callback idempotency guard...")
	var harness: Dictionary = _build_test_harness()
	var flow: GameFlowService = harness["flow_service"] as GameFlowService
	flow.start_new_game()
	var orch: StageOrchestrator = flow.get_orchestrator()

	var err_sub: Dictionary = orch.submit_question_answer({"submitted_payload": {}})
	if bool(err_sub.get("success", false)) or String(err_sub.get("error_code", "")) != FlowErrorCodes.DUPLICATE_CALLBACK:
		print("[FLOW-009] FAIL: Invalid phase submission not rejected with DUPLICATE_CALLBACK: ", err_sub)
		return false

	print("[FLOW-009] PASS")
	return true

# FLOW-010 — Stages 1.1-1.3 No Combat / Intent
static func test_flow_010_no_combat_or_intent_in_d1() -> bool:
	print("[FLOW-010] Testing Stages 1.1-1.3 no Combat/Intent restriction...")
	var harness: Dictionary = _build_test_harness()
	var flow: GameFlowService = harness["flow_service"] as GameFlowService
	flow.start_new_game()
	var orch: StageOrchestrator = flow.get_orchestrator()

	var combat_res: Dictionary = orch.advance_to_question_phase({"context": "combat"})
	if bool(combat_res.get("success", false)) or String(combat_res.get("error_code", "")) != FlowErrorCodes.COMBAT_NOT_ALLOWED:
		print("[FLOW-010] FAIL: Combat context allowed in Stage 1.1: ", combat_res)
		return false

	print("[FLOW-010] PASS")
	return true

# FLOW-011 — Explicit Invalid Stage or Content Failure
static func test_flow_011_explicit_invalid_stage_or_content() -> bool:
	print("[FLOW-011] Testing explicit invalid stage or content failure...")
	var harness: Dictionary = _build_test_harness()
	var flow: GameFlowService = harness["flow_service"] as GameFlowService

	var empty_res: Dictionary = flow.start_stage("")
	if bool(empty_res.get("success", false)) or String(empty_res.get("error_code", "")) != FlowErrorCodes.INVALID_STAGE_ID:
		print("[FLOW-011] FAIL: Empty stage ID not rejected: ", empty_res)
		return false

	var unk_res: Dictionary = flow.start_stage("stage_unknown")
	if bool(unk_res.get("success", false)) or String(unk_res.get("error_code", "")) != FlowErrorCodes.INVALID_STAGE_ID:
		print("[FLOW-011] FAIL: Unknown stage ID not rejected: ", unk_res)
		return false

	print("[FLOW-011] PASS")
	return true

# STAGECONTEXT LIFECYCLE
static func test_flow_stage_context_lifecycle() -> bool:
	print("[FLOW-STAGE-CONTEXT] Testing StageContext lifecycle creation...")
	var harness: Dictionary = _build_test_harness()
	var flow: GameFlowService = harness["flow_service"] as GameFlowService
	flow.start_new_game()

	var ctx: Dictionary = flow.get_stage_context(false)
	if ctx.is_empty() or String(ctx.get("stage_id", "")) != "stage_01_01":
		print("[FLOW-STAGE-CONTEXT] FAIL: Invalid stage context: ", ctx)
		return false
	if not ctx.has("lesson_steps") or not (ctx["lesson_steps"] is Array):
		print("[FLOW-STAGE-CONTEXT] FAIL: Missing lesson_steps in stage context")
		return false
	if bool(ctx.get("is_restored_context", true)) != false:
		print("[FLOW-STAGE-CONTEXT] FAIL: is_restored_context expected false")
		return false

	print("[FLOW-STAGE-CONTEXT] PASS")
	return true

# CONTINUE RESTORE LIFECYCLE
static func test_flow_continue_restore_lifecycle() -> bool:
	print("[FLOW-CONTINUE-RESTORE] Testing Continue restore lifecycle...")
	var unl_d: Array[String] = ["dungeon_01"]
	var unl_s: Array[String] = ["stage_01_01", "stage_01_02"]
	var clr_s: Array[String] = ["stage_01_01"]
	var frags: Array[String] = []
	var prog_state: ProgressState = ProgressState.new(unl_d, unl_s, clr_s, frags, false)
	var harness: Dictionary = _build_test_harness(prog_state)
	var flow: GameFlowService = harness["flow_service"] as GameFlowService

	var save_snapshot: Dictionary = {
		"progress": {
			"unlocked_stage_ids": ["stage_01_01", "stage_01_02"],
			"cleared_stage_ids": ["stage_01_01"]
		}
	}

	var res: Dictionary = flow.restore_from_save(save_snapshot)
	if not bool(res.get("success", false)):
		print("[FLOW-CONTINUE-RESTORE] FAIL: restore_from_save failed: ", res)
		return false
	if String(res.get("target_stage_id", "")) != "stage_01_02":
		print("[FLOW-CONTINUE-RESTORE] FAIL: Unexpected target stage ID: ", res.get("target_stage_id"))
		return false

	var ctx: Dictionary = res.get("stage_context", {}) as Dictionary
	if bool(ctx.get("is_restored_context", false)) != true:
		print("[FLOW-CONTINUE-RESTORE] FAIL: is_restored_context expected true in context")
		return false

	print("[FLOW-CONTINUE-RESTORE] PASS")
	return true

# NEXT STAGE TRANSITION LIFECYCLE
static func test_flow_next_stage_transition() -> bool:
	print("[FLOW-NEXT-STAGE] Testing Next-Stage transition lifecycle...")
	var harness: Dictionary = _build_test_harness()
	var flow: GameFlowService = harness["flow_service"] as GameFlowService
	var prog: ProgressService = harness["progress_service"] as ProgressService

	flow.start_new_game() # stage_01_01
	var grant_1: RewardGrant = RewardGrant.new("reward_01_01", "stage_01_01", 10, 20, [])
	prog.commit_stage_clear("stage_01_01", grant_1) # unlocks stage_01_02

	var adv_1: Dictionary = flow.advance_to_next_stage()
	if not bool(adv_1.get("success", false)) or String(flow.get_current_stage_id()) != "stage_01_02":
		print("[FLOW-NEXT-STAGE] FAIL: Advance from stage_01_01 to stage_01_02 failed: ", adv_1)
		return false

	var grant_2: RewardGrant = RewardGrant.new("reward_01_02", "stage_01_02", 10, 20, [])
	prog.commit_stage_clear("stage_01_02", grant_2) # unlocks stage_01_03
	var adv_2: Dictionary = flow.advance_to_next_stage()
	if not bool(adv_2.get("success", false)) or String(flow.get_current_stage_id()) != "stage_01_03":
		print("[FLOW-NEXT-STAGE] FAIL: Advance from stage_01_02 to stage_01_03 failed: ", adv_2)
		return false

	print("[FLOW-NEXT-STAGE] PASS")
	return true
