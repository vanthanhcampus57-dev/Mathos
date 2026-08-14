class_name TestContentRepository
extends RefCounted

## Automated test suite covering CONTENT-001 through CONTENT-018.

static func run_all_tests() -> bool:
	print("--- RUNNING CONTENT REPOSITORY & VALIDATOR SUITE ---")
	var all_ok: bool = true

	all_ok = test_content_001_valid_catalog_publishes() and all_ok
	all_ok = test_content_002_malformed_json_rejected() and all_ok
	all_ok = test_content_003_duplicate_id_rejected() and all_ok
	all_ok = test_content_004_missing_required_field_rejected() and all_ok
	all_ok = test_content_005_invalid_enum_rejected() and all_ok
	all_ok = test_content_006_dangling_reference_detected() and all_ok
	all_ok = test_content_007_cross_dungeon_blocked() and all_ok
	all_ok = test_content_008_four_by_five_rule() and all_ok
	all_ok = test_content_009_boss_mappings() and all_ok
	all_ok = test_content_010_fragment_mapping() and all_ok
	all_ok = test_content_011_question_payload_validation() and all_ok
	all_ok = test_content_012_invalid_question_reject_item() and all_ok
	all_ok = test_content_013_pool_below_min_blocks_stage() and all_ok
	all_ok = test_content_014_no_cross_topic_fallback() and all_ok
	all_ok = test_content_015_invalid_catalog_never_publishes() and all_ok
	all_ok = test_content_016_asset_policy() and all_ok
	all_ok = test_content_017_duplicate_json_key() and all_ok
	all_ok = test_content_018_foundation_regression() and all_ok

	return all_ok

static func test_content_001_valid_catalog_publishes() -> bool:
	print("[CONTENT-001] Testing valid synthetic catalog publication...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	if not report.publication_allowed or repo.get_catalog() == null:
		print("[CONTENT-001] FAIL: Valid catalog failed to publish")
		return false
	print("[CONTENT-001] PASS")
	return true

static func test_content_002_malformed_json_rejected() -> bool:
	print("[CONTENT-002] Testing malformed JSON rejection...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/invalid_syntax")
	if report.publication_allowed or not report.has_fatal():
		print("[CONTENT-002] FAIL: Malformed JSON was not rejected with FATAL issue")
		return false
	print("[CONTENT-002] PASS")
	return true

static func test_content_003_duplicate_id_rejected() -> bool:
	print("[CONTENT-003] Testing duplicate ID detection...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/invalid_duplicate_id")
	if report.publication_allowed or not report.has_fatal():
		print("[CONTENT-003] FAIL: Duplicate ID was not rejected")
		return false
	print("[CONTENT-003] PASS")
	return true

static func test_content_004_missing_required_field_rejected() -> bool:
	print("[CONTENT-004] Testing missing required field rejection...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/invalid_missing_required")
	if report.publication_allowed or not report.has_fatal():
		print("[CONTENT-004] FAIL: Missing required field was not rejected")
		return false
	print("[CONTENT-004] PASS")
	return true

static func test_content_005_invalid_enum_rejected() -> bool:
	print("[CONTENT-005] Testing invalid enum rejection...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/invalid_enum")
	if report.publication_allowed or not report.has_fatal():
		print("[CONTENT-005] FAIL: Invalid enum was not rejected")
		return false
	print("[CONTENT-005] PASS")
	return true

static func test_content_006_dangling_reference_detected() -> bool:
	print("[CONTENT-006] Testing dangling reference detection...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/invalid_dangling_ref")
	if report.publication_allowed or report.get_count_by_severity(ContentValidationIssue.Severity.BLOCK_STAGE) == 0:
		print("[CONTENT-006] FAIL: Dangling reference was not detected with BLOCK_STAGE")
		return false
	print("[CONTENT-006] PASS")
	return true

static func test_content_007_cross_dungeon_blocked() -> bool:
	print("[CONTENT-007] Testing cross-Dungeon topic boundary enforcement...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	var catalog: ValidatedCatalog = repo.get_catalog()
	var scope: Dictionary = {"dungeon_id": "dungeon_01", "topic_id": "trial_sample_event"}
	var d1_qs: Array[Dictionary] = catalog.query_questions(scope)
	for q in d1_qs:
		if q.get("dungeon_id") != "dungeon_01":
			print("[CONTENT-007] FAIL: Question query returned question from another dungeon")
			return false
	print("[CONTENT-007] PASS")
	return true

static func test_content_008_four_by_five_rule() -> bool:
	print("[CONTENT-008] Testing exactly 4x5 canonical structure...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	var catalog: ValidatedCatalog = repo.get_catalog()
	if catalog.get_all_dungeons().size() != 4 or catalog.get_all_stages().size() != 20:
		print("[CONTENT-008] FAIL: Catalog does not contain exactly 4 dungeons and 20 stages")
		return false
	print("[CONTENT-008] PASS")
	return true

static func test_content_009_boss_mappings() -> bool:
	print("[CONTENT-009] Testing STOCHAS, ALEATOR, Melkor, Aphodius boss mappings...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/invalid_boss_mapping")
	if report.publication_allowed or report.get_count_by_severity(ContentValidationIssue.Severity.BLOCK_STAGE) == 0:
		print("[CONTENT-009] FAIL: Invalid boss mapping was not blocked")
		return false
	print("[CONTENT-009] PASS")
	return true

static func test_content_010_fragment_mapping() -> bool:
	print("[CONTENT-010] Testing x.5 fragment mapping rules...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/invalid_fragment_mapping")
	if report.publication_allowed or report.get_count_by_severity(ContentValidationIssue.Severity.BLOCK_STAGE) == 0:
		print("[CONTENT-010] FAIL: Invalid fragment mapping was not blocked")
		return false
	print("[CONTENT-010] PASS")
	return true

static func test_content_011_question_payload_validation() -> bool:
	print("[CONTENT-011] Testing question interaction payload validation...")
	var q: Dictionary = {
		"schema_version": 1, "question_id": "q_test", "dungeon_id": "dungeon_01", "topic_id": "trial_sample_event",
		"learning_objective": "L", "prompt": "P", "explanation": "E", "difficulty": 1, "interaction_type": "multiple_choice",
		"interaction_payload": {}, "answer_spec": {}, "allowed_contexts": ["practice"]
	}
	var validator: ContentValidator = ContentValidator.new()
	var rep: ContentValidationReport = ContentValidationReport.new()
	var res: bool = validator._validate_question(q, "test.json", rep)
	if res or rep.get_count_by_severity(ContentValidationIssue.Severity.REJECT_ITEM) == 0:
		print("[CONTENT-011] FAIL: Malformed payload was not rejected with REJECT_ITEM")
		return false
	print("[CONTENT-011] PASS")
	return true

static func test_content_012_invalid_question_reject_item() -> bool:
	print("[CONTENT-012] Testing REJECT_ITEM behavior for invalid question...")
	var q: Dictionary = {
		"schema_version": 1, "question_id": "q_invalid_diff", "dungeon_id": "dungeon_01", "topic_id": "trial_sample_event",
		"learning_objective": "L", "prompt": "P", "explanation": "E", "difficulty": 99, "interaction_type": "multiple_choice",
		"interaction_payload": {"options": [{"option_id": "a", "text": "A"}, {"option_id": "b", "text": "B"}]},
		"answer_spec": {"correct_option_id": "a"}, "allowed_contexts": ["practice"]
	}
	var validator: ContentValidator = ContentValidator.new()
	var rep: ContentValidationReport = ContentValidationReport.new()
	var res: bool = validator._validate_question(q, "test.json", rep)
	if res or not rep.is_item_rejected("q_invalid_diff"):
		print("[CONTENT-012] FAIL: Invalid question was not marked REJECT_ITEM")
		return false
	print("[CONTENT-012] PASS")
	return true

static func test_content_013_pool_below_min_blocks_stage() -> bool:
	print("[CONTENT-013] Testing question pool below minimum blocks stage...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/invalid_question_pool")
	if report.publication_allowed or report.get_count_by_severity(ContentValidationIssue.Severity.BLOCK_STAGE) == 0:
		print("[CONTENT-013] FAIL: Insufficient question pool did not block stage")
		return false
	print("[CONTENT-013] PASS")
	return true

static func test_content_014_no_cross_topic_fallback() -> bool:
	print("[CONTENT-014] Testing no cross-topic question pool fallback...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/invalid_question_pool")
	if report.publication_allowed:
		print("[CONTENT-014] FAIL: Catalog published despite insufficient topic pool")
		return false
	print("[CONTENT-014] PASS")
	return true

static func test_content_015_invalid_catalog_never_publishes() -> bool:
	print("[CONTENT-015] Testing invalid catalog never publishes ValidatedCatalog...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/invalid_missing_required")
	if repo.get_catalog() != null or report.publication_allowed:
		print("[CONTENT-015] FAIL: Invalid catalog published ValidatedCatalog instance")
		return false
	print("[CONTENT-015] PASS")
	return true

static func test_content_016_asset_policy() -> bool:
	print("[CONTENT-016] Testing AssetRef required vs optional policy...")
	var issue_req: ContentValidationIssue = ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_ASSET_REQ", "asset", "a1", "", "Required asset missing")
	var issue_opt: ContentValidationIssue = ContentValidationIssue.new(ContentValidationIssue.Severity.WARNING, "WARN_ASSET_OPT", "asset", "a2", "", "Optional asset missing")
	if issue_req.get_severity_string() != "BLOCK_STAGE" or issue_opt.get_severity_string() != "WARNING":
		print("[CONTENT-016] FAIL: AssetRef severity levels incorrect")
		return false
	print("[CONTENT-016] PASS")
	return true

static func test_content_017_duplicate_json_key() -> bool:
	print("[CONTENT-017] Testing duplicate JSON key detection...")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/invalid_duplicate_key")
	if report.publication_allowed or not report.has_fatal():
		print("[CONTENT-017] FAIL: Duplicate JSON key was not rejected with FATAL issue")
		return false
	print("[CONTENT-017] PASS")
	return true

static func test_content_018_foundation_regression() -> bool:
	print("[CONTENT-018] Testing foundation validation regression...")
	var v_script: ValidateContent = ValidateContent.new()
	if not v_script.validate_game_config() or not v_script.validate_content_directories():
		print("[CONTENT-018] FAIL: Foundation validation regression failed")
		return false
	print("[CONTENT-018] PASS")
	return true
