class_name StageOrchestrator
extends RefCounted

## Owns stage-lifetime execution lifecycle, phase transitions, question session
## integration, and stage-completion handoff boundary for Mathos V1.
## Note: Actual ProgressService.commit_stage_clear and SaveService persistence
## are owned by A.2 integration bridge. StageOrchestrator exposes the prepared
## handoff payload exactly once.

var _catalog: ValidatedCatalog
var _question_service: QuestionService
var _progress_service: ProgressService

var _current_stage_id: String = ""
var _current_stage_data: Dictionary = {}
var _current_phase: String = "UNINITIALIZED"
var _active_question_session_id: String = ""
var _stage_clear_committed: bool = false

func _init(
	catalog: ValidatedCatalog,
	question_service: QuestionService,
	progress_service: ProgressService
) -> void:
	assert(catalog != null, "StageOrchestrator requires ValidatedCatalog")
	assert(question_service != null, "StageOrchestrator requires QuestionService")
	assert(progress_service != null, "StageOrchestrator requires ProgressService")
	_catalog = catalog
	_question_service = question_service
	_progress_service = progress_service

func initialize_stage(stage_id: String) -> Dictionary:
	if stage_id.is_empty():
		return _error(FlowErrorCodes.INVALID_STAGE_ID, "Stage ID cannot be empty")

	var stage_data: Dictionary = _catalog.get_stage(stage_id)
	if stage_data.is_empty():
		return _error(FlowErrorCodes.INVALID_STAGE_ID, "Unknown stage ID '%s'" % stage_id)

	if not _progress_service.can_enter(stage_id):
		return _error(FlowErrorCodes.STAGE_LOCKED, "Stage '%s' is locked by ProgressService" % stage_id)

	# FLOW-010: Stages 1.1-1.3 hard boundary check (puzzle_onboarding, no combat/intent)
	var encounter_mode: String = String(stage_data.get("encounter_mode", ""))
	var intent_enabled: bool = bool(stage_data.get("intent_enabled", false))
	if _is_v1_puzzle_onboarding_stage(stage_id):
		if encounter_mode == "combat" or intent_enabled:
			return _error(FlowErrorCodes.COMBAT_NOT_ALLOWED, "Stages 1.1-1.3 cannot route into Combat or Intent")

	_current_stage_id = stage_id
	_current_stage_data = stage_data.duplicate(true)
	_current_phase = "LESSON_DIALOGUE_PUZZLE"
	_active_question_session_id = ""
	_stage_clear_committed = false

	return {
		"success": true,
		"stage_id": _current_stage_id,
		"phase": _current_phase,
		"stage": _current_stage_data
	}

func advance_to_question_phase(request_params: Dictionary = {}, adaptive_recommendation: Dictionary = {}) -> Dictionary:
	if _current_phase != "LESSON_DIALOGUE_PUZZLE":
		return _error(
			FlowErrorCodes.INVALID_LIFECYCLE_TRANSITION,
			"Cannot advance to question phase from state '%s'" % _current_phase
		)

	var context: String = String(request_params.get("context", "practice"))
	if _is_v1_puzzle_onboarding_stage(_current_stage_id) and context == "combat":
		return _error(FlowErrorCodes.COMBAT_NOT_ALLOWED, "Stages 1.1-1.3 cannot use combat context")

	var scope: Dictionary = request_params.get("scope", _extract_question_scope(_current_stage_data)) as Dictionary
	if scope.is_empty():
		return _error(
			FlowErrorCodes.INVALID_CONTENT_REFERENCE,
			"Stage '%s' lacks valid practice_id or PracticeDefinition question_scope" % _current_stage_id
		)

	var request_id: String = String(request_params.get("request_id", "req_%s_01" % _current_stage_id))
	var preferred_diff: int = int(request_params.get("preferred_difficulty", 1))
	var exclude_ids: Array = request_params.get("exclude_question_ids", []) as Array

	var request: Dictionary = {
		"request_id": request_id,
		"stage_id": _current_stage_id,
		"scope": scope,
		"context": context,
		"preferred_difficulty": preferred_diff,
		"exclude_question_ids": exclude_ids
	}

	var q_res: Dictionary = _question_service.request_question(request, adaptive_recommendation)
	if not bool(q_res.get("success", false)):
		return {
			"success": false,
			"error_code": q_res.get("error_code", FlowErrorCodes.QUESTION_SESSION_FAILED),
			"error_message": q_res.get("error_message", "Failed to initialize question session"),
			"details": q_res
		}

	var session_dict: Dictionary = q_res.get("session", {}) as Dictionary
	_active_question_session_id = String(session_dict.get("session_id", ""))
	_current_phase = "QUESTION_ACTIVE"

	return {
		"success": true,
		"phase": _current_phase,
		"session": session_dict,
		"question": q_res.get("question", {})
	}

func submit_question_answer(answer_payload: Dictionary) -> Dictionary:
	if _current_phase != "QUESTION_ACTIVE":
		return _error(
			FlowErrorCodes.DUPLICATE_CALLBACK,
			"Question completion callback rejected: stage is in state '%s'" % _current_phase
		)

	var sub_res: Dictionary = _question_service.submit_answer(answer_payload)
	if not bool(sub_res.get("success", false)):
		return sub_res

	_current_phase = "QUESTION_COMPLETE"
	return {
		"success": true,
		"phase": _current_phase,
		"result": sub_res.get("result", {})
	}

## Exposes the typed stage-clear handoff boundary exactly once.
## Does NOT execute ProgressService.commit_stage_clear itself (owned by A.2 integration bridge).
func prepare_stage_clear_commit(reward_grant: RewardGrant = null) -> Dictionary:
	if _stage_clear_committed or _current_phase == "COMPLETED":
		return _error(
			FlowErrorCodes.DUPLICATE_CALLBACK,
			"Stage clear commit handoff already prepared for stage '%s'" % _current_stage_id
		)

	if _current_phase != "QUESTION_COMPLETE" and _current_phase != "LESSON_DIALOGUE_PUZZLE":
		return _error(
			FlowErrorCodes.INVALID_LIFECYCLE_TRANSITION,
			"Cannot prepare stage clear handoff from state '%s'" % _current_phase
		)

	var grant: RewardGrant = reward_grant
	if grant == null:
		grant = _build_default_reward_grant(_current_stage_id)

	_stage_clear_committed = true
	_current_phase = "COMPLETED"

	return {
		"success": true,
		"phase": _current_phase,
		"stage_id": _current_stage_id,
		"reward_grant": grant
	}

func get_current_phase() -> String:
	return _current_phase

func get_current_stage_id() -> String:
	return _current_stage_id

func is_stage_active() -> bool:
	return _current_phase != "UNINITIALIZED" and _current_phase != "COMPLETED" and _current_phase != "FAILED"

func create_stage_context(is_restored: bool = false) -> Dictionary:
	if _current_stage_id.is_empty() or _current_stage_data.is_empty():
		return {}

	var dungeon_id: String = String(_current_stage_data.get("dungeon_id", ""))
	if dungeon_id.is_empty():
		return {}

	var dungeon: Dictionary = _catalog.get_dungeon(dungeon_id)
	if dungeon.is_empty():
		return {}

	var dungeon_title: String = String(dungeon.get("display_name", ""))
	if dungeon_title.is_empty():
		return {}

	var stage_title: String = String(_current_stage_data.get("title", ""))
	if stage_title.is_empty():
		return {}

	var lesson_id: String = String(_current_stage_data.get("lesson_id", ""))
	if lesson_id.is_empty():
		return {}

	var lesson: Dictionary = _catalog.get_lesson(lesson_id)
	if lesson.is_empty():
		return {}

	var raw_sections: Array = lesson.get("sections", []) as Array
	if raw_sections.is_empty():
		return {}

	var steps: Array[Dictionary] = []
	var total: int = raw_sections.size()
	for idx in range(total):
		var sec_var: Variant = raw_sections[idx]
		if not (sec_var is Dictionary):
			return {}
		var sec: Dictionary = sec_var as Dictionary
		var header: String = String(sec.get("header", ""))
		var speaker: String = String(sec.get("speaker", header))
		var body: String = String(sec.get("body", ""))
		if body.is_empty() or speaker.is_empty():
			return {}
		steps.append({
			"speaker_label": speaker,
			"body_text": body,
			"context_title": stage_title,
			"step_index": idx + 1,
			"total_steps": total
		})

	var story_id: String = String(_current_stage_data.get("story_id", ""))
	var story_steps: Array[Dictionary] = []
	if not story_id.is_empty():
		var story: Dictionary = _catalog.get_story(story_id)
		var dialogues: Array = story.get("dialogue_steps", []) as Array
		var s_total: int = dialogues.size()
		for s_idx in range(s_total):
			var d_step: Dictionary = dialogues[s_idx] as Dictionary
			var s_speaker: String = String(d_step.get("speaker", ""))
			var s_text: String = String(d_step.get("text", ""))
			story_steps.append({
				"speaker_label": s_speaker,
				"body_text": s_text,
				"context_title": stage_title,
				"step_index": s_idx + 1,
				"total_steps": s_total
			})

	var stage_advisor_text: String = String(_current_stage_data.get("learning_objective", ""))
	if stage_advisor_text.is_empty() and not raw_sections.is_empty():
		var sec0: Dictionary = raw_sections[0] as Dictionary
		stage_advisor_text = String(sec0.get("body", ""))

	return {
		"stage_id": _current_stage_id,
		"stage_title": stage_title,
		"dungeon_title": dungeon_title,
		"lesson_steps": steps,
		"story_steps": story_steps,
		"stage_advisor_text": stage_advisor_text,
		"encounter_mode": str(_current_stage_data.get("encounter_mode", "puzzle_onboarding")),
		"enemy_id": "" if _current_stage_data.get("enemy_id") == null else str(_current_stage_data.get("enemy_id")),
		"card_pool_ids": (_current_stage_data.get("card_pool_ids", []) as Array).duplicate() if _current_stage_data.get("card_pool_ids") != null else [],
		"intent_enabled": bool(_current_stage_data.get("intent_enabled", false)),
		"is_restored_context": is_restored
	}

func _is_v1_puzzle_onboarding_stage(stage_id: String) -> bool:
	return stage_id == "stage_01_01" or stage_id == "stage_01_02" or stage_id == "stage_01_03"

func _extract_question_scope(stage_data: Dictionary) -> Dictionary:
	var practice_id: String = String(stage_data.get("practice_id", ""))
	if practice_id.is_empty():
		return {}

	var practice: Dictionary = _catalog.get_practice(practice_id)
	if practice.is_empty() or not practice.has("question_scope") or not (practice["question_scope"] is Dictionary):
		return {}

	var raw_scope: Dictionary = practice["question_scope"] as Dictionary
	var dungeon_id: String = String(raw_scope.get("dungeon_id", stage_data.get("dungeon_id", "dungeon_01")))
	var topic_id: String = String(raw_scope.get("topic_id", QuestionService.TOPIC_BY_DUNGEON.get(dungeon_id, "trial_sample_event")))

	var canonical_subs: Array = QuestionService.SUBTOPICS_BY_TOPIC.get(topic_id, [])
	var subtopics: Array[String] = []
	var raw_sub: Variant = raw_scope.get("subtopic_ids", raw_scope.get("subtopics", []))
	if raw_sub is Array and not (raw_sub as Array).is_empty():
		for s in raw_sub as Array:
			subtopics.append(String(s))
	else:
		for s in canonical_subs:
			subtopics.append(String(s))

	var diff_min: int = int(raw_scope.get("difficulty_min", 1))
	var diff_max: int = int(raw_scope.get("difficulty_max", 5))

	var interaction_types: Array[String] = ["multiple_choice", "drag_drop", "matching", "input"]
	if raw_scope.has("interaction_types") and (raw_scope["interaction_types"] is Array) and not (raw_scope["interaction_types"] as Array).is_empty():
		interaction_types.clear()
		for t in raw_scope["interaction_types"] as Array:
			interaction_types.append(String(t))

	return {
		"dungeon_id": dungeon_id,
		"topic_id": topic_id,
		"subtopic_ids": subtopics,
		"difficulty_min": diff_min,
		"difficulty_max": diff_max,
		"interaction_types": interaction_types
	}

func _build_default_reward_grant(stage_id: String) -> RewardGrant:
	var reward_id: String = String(_current_stage_data.get("reward_id", "reward_%s" % stage_id))

	var dungeon_id: String = String(_current_stage_data.get("dungeon_id", ""))
	var dungeon: Dictionary = _catalog.get_dungeon(dungeon_id)
	var stage_ids: Array = dungeon.get("stage_ids", []) as Array
	var is_final_stage: bool = not stage_ids.is_empty() and String(stage_ids[stage_ids.size() - 1]) == stage_id

	var frags: Array[String] = []
	if is_final_stage and dungeon.has("fragment_id"):
		frags.append(String(dungeon["fragment_id"]))

	return RewardGrant.new(reward_id, stage_id, 10, 20, frags)

func _error(code: String, message: String) -> Dictionary:
	return {
		"success": false,
		"error_code": code,
		"error_message": message
	}
