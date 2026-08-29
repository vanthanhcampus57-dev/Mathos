class_name TestContentSchemaPresentation
extends RefCounted

## Unit tests for Production Content Player-Facing Schema Contract (MATHOS-DIRECT-CONTENT-SCHEMA-PRESENTATION-001).

static func run_all_tests() -> bool:
	var all_ok: bool = true
	all_ok = test_valid_stage_title_accepted() and all_ok
	all_ok = test_missing_stage_title_rejected() and all_ok
	all_ok = test_empty_stage_title_rejected() and all_ok
	all_ok = test_valid_lesson_speaker_header_body_accepted() and all_ok
	all_ok = test_missing_lesson_section_body_rejected() and all_ok
	all_ok = test_empty_lesson_speaker_rejected() and all_ok
	all_ok = test_stage_orchestrator_uses_schema_fields_not_raw_ids() and all_ok
	all_ok = test_stage_orchestrator_no_synthetic_copy() and all_ok
	return all_ok

static func _build_valid_stage_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"stage_id": "stage_01_01",
		"dungeon_id": "dungeon_01",
		"order_in_dungeon": 1,
		"title": "Thử Thách Biến Cố",
		"learning_objective": "Identify outcomes in sample space",
		"learning_scope": {
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"subtopics": [],
			"difficulty_min": 1,
			"difficulty_max": 5
		},
		"phase_sequence": ["story", "lesson", "practice", "combat", "reward"],
		"story_id": null,
		"lesson_id": "lesson_01_01",
		"practice_id": "practice_01_01",
		"encounter_mode": "puzzle_onboarding",
		"completion_rule": "encounter_victory",
		"reward_id": "reward_01_01",
		"card_pool_ids": [],
		"enemy_id": null,
		"intent_enabled": false
	}

static func test_valid_stage_title_accepted() -> bool:
	print("[SCHEMA-001] Testing valid stage title accepted...")
	var validator: ContentValidator = ContentValidator.new()
	var report: ContentValidationReport = ContentValidationReport.new()
	var stage: Dictionary = _build_valid_stage_dict()

	var ok: bool = validator._validate_stage(stage, "stages.json", report)
	if not ok or report.has_fatal() or report.blocked_stage_ids.size() > 0:
		print("[SCHEMA-001] FAIL: Valid stage title was rejected")
		return false
	print("[SCHEMA-001] PASS: Valid stage title accepted")
	return true

static func test_missing_stage_title_rejected() -> bool:
	print("[SCHEMA-002] Testing missing stage title rejected...")
	var validator: ContentValidator = ContentValidator.new()
	var report: ContentValidationReport = ContentValidationReport.new()
	var stage: Dictionary = _build_valid_stage_dict()
	stage.erase("title")

	var ok: bool = validator._validate_stage(stage, "stages.json", report)
	if ok and not report.has_issues():
		print("[SCHEMA-002] FAIL: Missing stage title was not rejected")
		return false
	print("[SCHEMA-002] PASS: Missing stage title correctly rejected")
	return true

static func test_empty_stage_title_rejected() -> bool:
	print("[SCHEMA-003] Testing empty stage title string rejected...")
	var validator: ContentValidator = ContentValidator.new()
	var report: ContentValidationReport = ContentValidationReport.new()
	var stage: Dictionary = _build_valid_stage_dict()
	stage["title"] = ""

	var ok: bool = validator._validate_stage(stage, "stages.json", report)
	if ok and report.blocked_stage_ids.is_empty():
		print("[SCHEMA-003] FAIL: Empty stage title string was not rejected")
		return false
	print("[SCHEMA-003] PASS: Empty stage title string correctly rejected")
	return true

static func test_valid_lesson_speaker_header_body_accepted() -> bool:
	print("[SCHEMA-004] Testing valid lesson speaker, header, body accepted...")
	var validator: ContentValidator = ContentValidator.new()
	var report: ContentValidationReport = ContentValidationReport.new()
	var lesson: Dictionary = {
		"schema_version": 1,
		"lesson_id": "lesson_01_01",
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"title": "Không Gian Mẫu Và Biến Cố",
		"sections": [
			{
				"speaker": "Giáo Sư Karl",
				"header": "Khái Niệm Phép Thử",
				"body": "Phép thử ngẫu nhiên là một thí nghiệm có thể lặp lại trong cùng điều kiện."
			}
		]
	}

	var ok: bool = validator._validate_lesson(lesson, "lessons.json", report)
	if not ok or report.has_fatal():
		print("[SCHEMA-004] FAIL: Valid lesson section was rejected")
		return false
	print("[SCHEMA-004] PASS: Valid lesson section accepted")
	return true

static func test_missing_lesson_section_body_rejected() -> bool:
	print("[SCHEMA-005] Testing missing lesson section body rejected...")
	var validator: ContentValidator = ContentValidator.new()
	var report: ContentValidationReport = ContentValidationReport.new()
	var lesson: Dictionary = {
		"schema_version": 1,
		"lesson_id": "lesson_01_01",
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"title": "Lesson Title",
		"sections": [
			{
				"header": "Intro"
			}
		]
	}

	var ok: bool = validator._validate_lesson(lesson, "lessons.json", report)
	if ok and not report.has_fatal():
		print("[SCHEMA-005] FAIL: Missing section body was not rejected")
		return false
	print("[SCHEMA-005] PASS: Missing section body correctly rejected")
	return true

static func test_empty_lesson_speaker_rejected() -> bool:
	print("[SCHEMA-006] Testing empty lesson speaker rejected...")
	var validator: ContentValidator = ContentValidator.new()
	var report: ContentValidationReport = ContentValidationReport.new()
	var lesson: Dictionary = {
		"schema_version": 1,
		"lesson_id": "lesson_01_01",
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"title": "Lesson Title",
		"sections": [
			{
				"speaker": "",
				"header": "Intro",
				"body": "Body text"
			}
		]
	}

	var ok: bool = validator._validate_lesson(lesson, "lessons.json", report)
	if ok and not report.has_fatal():
		print("[SCHEMA-006] FAIL: Empty lesson speaker string was not rejected")
		return false
	print("[SCHEMA-006] PASS: Empty lesson speaker string correctly rejected")
	return true

static func test_stage_orchestrator_uses_schema_fields_not_raw_ids() -> bool:
	print("[SCHEMA-007] Testing StageOrchestrator uses canonical schema fields (display_name, title)...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	var catalog: ValidatedCatalog = repo.get_catalog()
	if catalog == null:
		print("[SCHEMA-007] FAIL: Catalog failed to load")
		return false

	var q_service: QuestionService = QuestionService.new(catalog)
	var p_state: PlayerPersistentState = PlayerPersistentState.new("p1", 0, 0)
	var p_service: ProgressService = ProgressService.new(catalog, p_state)
	var orch: StageOrchestrator = StageOrchestrator.new(catalog, q_service, p_service)

	var init_res: Dictionary = orch.initialize_stage("stage_01_01")
	if not bool(init_res.get("success", false)):
		print("[SCHEMA-007] FAIL: Could not initialize stage_01_01")
		return false

	var ctx: Dictionary = orch.create_stage_context(false)
	var dungeon_title: String = String(ctx.get("dungeon_title", ""))
	var stage_title: String = String(ctx.get("stage_title", ""))

	# Should match dungeon display_name ("Khu Rừng Mù Sương") and stage title ("Title for stage_01_01")
	if dungeon_title == "dungeon_01" or dungeon_title.is_empty():
		print("[SCHEMA-007] FAIL: dungeon_title used raw ID or was empty: '%s'" % dungeon_title)
		return false
	if stage_title == "stage_01_01" or stage_title.is_empty():
		print("[SCHEMA-007] FAIL: stage_title used raw ID or was empty: '%s'" % stage_title)
		return false

	print("[SCHEMA-007] PASS: StageOrchestrator mapped dungeon_title='%s', stage_title='%s'" % [dungeon_title, stage_title])
	return true

static func test_stage_orchestrator_no_synthetic_copy() -> bool:
	print("[SCHEMA-008] Testing StageOrchestrator produces zero synthesized fallback copy when data missing...")
	# Construct synthetic catalog missing stage title
	var config: Dictionary = {
		"schema_version": 1, "game_version": "0.1.0", "content_version": "1.0",
		"initial_dungeon_id": "dungeon_01", "initial_stage_id": "stage_01_01",
		"difficulty_min": 1, "difficulty_max": 5, "minimum_valid_candidates_per_required_scope": 1,
		"default_practice_question_count": 3, "adaptive_recent_record_limit": 5,
		"player_stats": {}, "performance_grade_thresholds": {}, "supported_interaction_types": []
	}
	var dungeons: Dictionary = {"dungeon_01": {"dungeon_id": "dungeon_01", "display_name": "Test Dungeon"}}
	var stages: Dictionary = {"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01"}} # missing title and lesson_id
	var catalog: ValidatedCatalog = ValidatedCatalog.new(config, dungeons, stages, {}, {}, {}, {}, {}, {}, {})

	var q_service: QuestionService = QuestionService.new(catalog)
	var p_state: PlayerPersistentState = PlayerPersistentState.new("p1", 0, 0)
	var p_service: ProgressService = ProgressService.new(catalog, p_state)
	var orch: StageOrchestrator = StageOrchestrator.new(catalog, q_service, p_service)
	orch.initialize_stage("stage_01_01")

	var ctx: Dictionary = orch.create_stage_context(false)
	if not ctx.is_empty():
		print("[SCHEMA-008] FAIL: create_stage_context did not return empty dict when stage title was missing")
		return false

	print("[SCHEMA-008] PASS: Zero synthesized fallback copy produced for invalid/incomplete stage")
	return true
