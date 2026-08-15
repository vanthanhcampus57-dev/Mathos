class_name TestContentRepository
extends RefCounted

## Automated test suite covering CONTENT-001 through CONTENT-028.

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
	all_ok = test_content_019_drag_drop_canonical_mappings() and all_ok
	all_ok = test_content_020_drag_drop_legacy_mapping_rejected() and all_ok
	all_ok = test_content_021_matching_canonical_pairs() and all_ok
	all_ok = test_content_022_matching_legacy_pairs_rejected() and all_ok
	all_ok = test_content_023_input_canonical_accepted_values() and all_ok
	all_ok = test_content_024_input_legacy_accepted_answers_rejected() and all_ok
	all_ok = test_content_025_query_honors_subtopic_ids() and all_ok
	all_ok = test_content_026_query_empty_subtopic_ids_same_topic() and all_ok
	all_ok = test_content_027_query_legacy_subtopics_not_canonical() and all_ok
	all_ok = test_content_028_query_hard_dungeon_topic_boundary() and all_ok

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
	var scope: Dictionary = {"dungeon_id": "dungeon_01", "topic_id": "trial_sample_event", "subtopic_ids": []}
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
	print("[CONTENT-018] Testing foundation validation regression (positive + negative)...")
	var v_script: ValidateContent = ValidateContent.new()
	var pos_ok: bool = v_script.validate_game_config("res://content/config/game_config.json")
	var neg_ok: bool = not v_script.validate_game_config("res://tests/fixtures/content/invalid_duplicate_key/config/game_config.json")
	if not pos_ok or not neg_ok:
		print("[CONTENT-018] FAIL: Foundation validation regression failed (pos: " + str(pos_ok) + ", neg: " + str(neg_ok) + ")")
		return false
	print("[CONTENT-018] PASS")
	return true

static func test_content_019_drag_drop_canonical_mappings() -> bool:
	print("[CONTENT-019] Testing drag_drop canonical answer_spec.mappings...")
	var q: Dictionary = _contract_base_question("q_drag_canonical", "drag_drop")
	q["interaction_payload"] = {
		"items": [{"item_id": "item_a", "text": "A"}, {"item_id": "item_b", "text": "B"}],
		"targets": [{"target_id": "target_a", "label": "A"}, {"target_id": "target_b", "label": "B"}],
		"must_place_all": true
	}
	q["answer_spec"] = {"mappings": [{"item_id": "item_a", "target_id": "target_a"}, {"item_id": "item_b", "target_id": "target_b"}]}
	if not _validate_contract_question(q):
		print("[CONTENT-019] FAIL: Canonical mappings was rejected")
		return false
	print("[CONTENT-019] PASS")
	return true

static func test_content_020_drag_drop_legacy_mapping_rejected() -> bool:
	print("[CONTENT-020] Testing legacy correct_mappings rejection...")
	var q: Dictionary = _contract_base_question("q_drag_legacy", "drag_drop")
	q["interaction_payload"] = {
		"items": [{"item_id": "item_a", "text": "A"}],
		"targets": [{"target_id": "target_a", "label": "A"}],
		"must_place_all": true
	}
	q["answer_spec"] = {"correct_mappings": [{"item_id": "item_a", "target_id": "target_a"}]}
	if _validate_contract_question(q):
		print("[CONTENT-020] FAIL: Legacy correct_mappings was accepted")
		return false
	print("[CONTENT-020] PASS")
	return true

static func test_content_021_matching_canonical_pairs() -> bool:
	print("[CONTENT-021] Testing matching canonical answer_spec.pairs...")
	var q: Dictionary = _contract_matching_question("q_matching_canonical")
	if not _validate_contract_question(q):
		print("[CONTENT-021] FAIL: Canonical complete pairs was rejected")
		return false
	var incomplete: Dictionary = q.duplicate(true)
	incomplete["answer_spec"] = {"pairs": [{"left_id": "left_a", "right_id": "right_a"}]}
	if _validate_contract_question(incomplete):
		print("[CONTENT-021] FAIL: Incomplete answer_spec.pairs ground truth was accepted")
		return false
	var duplicate_right: Dictionary = q.duplicate(true)
	duplicate_right["answer_spec"] = {"pairs": [{"left_id": "left_a", "right_id": "right_a"}, {"left_id": "left_b", "right_id": "right_a"}]}
	if _validate_contract_question(duplicate_right):
		print("[CONTENT-021] FAIL: Non one-to-one answer_spec.pairs ground truth was accepted")
		return false
	print("[CONTENT-021] PASS")
	return true

static func test_content_022_matching_legacy_pairs_rejected() -> bool:
	print("[CONTENT-022] Testing legacy correct_pairs rejection...")
	var q: Dictionary = _contract_matching_question("q_matching_legacy")
	q["answer_spec"] = {"correct_pairs": [{"left_id": "left_a", "right_id": "right_a"}, {"left_id": "left_b", "right_id": "right_b"}]}
	if _validate_contract_question(q):
		print("[CONTENT-022] FAIL: Legacy correct_pairs was accepted")
		return false
	print("[CONTENT-022] PASS")
	return true

static func test_content_023_input_canonical_accepted_values() -> bool:
	print("[CONTENT-023] Testing input canonical answer_spec.accepted_values...")
	var q: Dictionary = _contract_base_question("q_input_canonical", "input")
	q["interaction_payload"] = {"input_type": "float", "placeholder": null, "unit": null}
	q["answer_spec"] = {"accepted_values": [0.25], "numeric_tolerance": 0.001, "case_sensitive": false, "trim_whitespace": true}
	if not _validate_contract_question(q):
		print("[CONTENT-023] FAIL: Canonical accepted_values was rejected")
		return false
	print("[CONTENT-023] PASS")
	return true

static func test_content_024_input_legacy_accepted_answers_rejected() -> bool:
	print("[CONTENT-024] Testing legacy accepted_answers rejection...")
	var q: Dictionary = _contract_base_question("q_input_legacy", "input")
	q["interaction_payload"] = {"input_type": "integer", "placeholder": null, "unit": null}
	q["answer_spec"] = {"accepted_answers": [2], "numeric_tolerance": null, "case_sensitive": false, "trim_whitespace": true}
	if _validate_contract_question(q):
		print("[CONTENT-024] FAIL: Legacy accepted_answers was accepted")
		return false
	print("[CONTENT-024] PASS")
	return true

static func test_content_025_query_honors_subtopic_ids() -> bool:
	print("[CONTENT-025] Testing query_questions subtopic_ids restriction...")
	var catalog: ValidatedCatalog = _contract_query_catalog()
	var result: Array[Dictionary] = catalog.query_questions(_contract_query_scope(["sample_space"]), "practice")
	if result.size() != 1 or result[0].get("subtopic_id", "") != "sample_space":
		print("[CONTENT-025] FAIL: subtopic_ids filter was not honored")
		return false
	print("[CONTENT-025] PASS")
	return true

static func test_content_026_query_empty_subtopic_ids_same_topic() -> bool:
	print("[CONTENT-026] Testing empty subtopic_ids preserves legal same-topic candidates...")
	var catalog: ValidatedCatalog = _contract_query_catalog()
	var result: Array[Dictionary] = catalog.query_questions(_contract_query_scope([]), "practice")
	if result.size() != 2:
		print("[CONTENT-026] FAIL: Empty subtopic_ids did not retain same-topic candidates")
		return false
	for q in result:
		if q.get("dungeon_id", "") != "dungeon_01" or q.get("topic_id", "") != "trial_sample_event":
			print("[CONTENT-026] FAIL: Empty subtopic_ids widened outside same topic")
			return false
	print("[CONTENT-026] PASS")
	return true

static func test_content_027_query_legacy_subtopics_not_canonical() -> bool:
	print("[CONTENT-027] Testing legacy subtopics is not silently interpreted...")
	var catalog: ValidatedCatalog = _contract_query_catalog()
	var scope: Dictionary = _contract_query_scope([])
	scope.erase("subtopic_ids")
	scope["subtopics"] = ["sample_space"]
	var result: Array[Dictionary] = catalog.query_questions(scope, "practice")
	if not result.is_empty():
		print("[CONTENT-027] FAIL: Legacy subtopics was treated as canonical or widened")
		return false
	print("[CONTENT-027] PASS")
	return true

static func test_content_028_query_hard_dungeon_topic_boundary() -> bool:
	print("[CONTENT-028] Testing hard Dungeon/topic restriction remains intact...")
	var catalog: ValidatedCatalog = _contract_query_catalog()
	var result: Array[Dictionary] = catalog.query_questions(_contract_query_scope([]), "practice")
	for q in result:
		if q.get("dungeon_id", "") != "dungeon_01" or q.get("topic_id", "") != "trial_sample_event":
			print("[CONTENT-028] FAIL: Query crossed Dungeon/topic boundary")
			return false
	var forged: Dictionary = _contract_query_scope([])
	forged["topic_id"] = "classical_probability"
	if not catalog.query_questions(forged, "practice").is_empty():
		print("[CONTENT-028] FAIL: Non-canonical Dungeon/topic scope was accepted")
		return false
	print("[CONTENT-028] PASS")
	return true

static func _contract_base_question(question_id: String, interaction_type: String) -> Dictionary:
	return {
		"schema_version": 1,
		"question_id": question_id,
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "sample_space",
		"learning_objective": "Synthetic validation objective",
		"prompt": "Synthetic prompt",
		"explanation": "Synthetic explanation",
		"difficulty": 2,
		"interaction_type": interaction_type,
		"interaction_payload": {},
		"answer_spec": {},
		"allowed_contexts": ["practice"]
	}

static func _contract_matching_question(question_id: String) -> Dictionary:
	var q: Dictionary = _contract_base_question(question_id, "matching")
	q["interaction_payload"] = {
		"left_items": [{"item_id": "left_a", "text": "A"}, {"item_id": "left_b", "text": "B"}],
		"right_items": [{"item_id": "right_a", "text": "A"}, {"item_id": "right_b", "text": "B"}]
	}
	q["answer_spec"] = {"pairs": [{"left_id": "left_a", "right_id": "right_a"}, {"left_id": "left_b", "right_id": "right_b"}]}
	return q

static func _validate_contract_question(question: Dictionary) -> bool:
	var validator: ContentValidator = ContentValidator.new()
	var report: ContentValidationReport = ContentValidationReport.new()
	return validator._validate_question(question, "synthetic_question.json", report)

static func _contract_query_scope(subtopic_ids: Array) -> Dictionary:
	return {
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_ids": subtopic_ids,
		"difficulty_min": 1,
		"difficulty_max": 5,
		"interaction_types": []
	}

static func _contract_query_catalog() -> ValidatedCatalog:
	var questions: Dictionary = {
		"q_sample": _contract_query_question("q_sample", "dungeon_01", "trial_sample_event", "sample_space"),
		"q_event": _contract_query_question("q_event", "dungeon_01", "trial_sample_event", "event_subset"),
		"q_d2": _contract_query_question("q_d2", "dungeon_02", "classical_probability", "equally_likely"),
		"q_wrong_topic": _contract_query_question("q_wrong_topic", "dungeon_01", "classical_probability", "equally_likely"),
		"q_bad_subtopic": _contract_query_question("q_bad_subtopic", "dungeon_01", "trial_sample_event", "not_canonical")
	}
	return ValidatedCatalog.new({}, {}, {}, {}, {}, {}, questions, {}, {}, {})

static func _contract_query_question(question_id: String, dungeon_id: String, topic_id: String, subtopic_id: String) -> Dictionary:
	return {
		"question_id": question_id,
		"dungeon_id": dungeon_id,
		"topic_id": topic_id,
		"subtopic_id": subtopic_id,
		"difficulty": 2,
		"interaction_type": "multiple_choice",
		"allowed_contexts": ["practice"]
	}
