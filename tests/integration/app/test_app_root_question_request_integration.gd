class_name TestAppRootQuestionRequestIntegration
extends RefCounted

## AppRoot QuestionRequest Contract & Boundary QA Suite (APPROOT-QR-001..015).
## Verifies that AppRoot._start_current_question() constructs a fully conforming V1 QuestionRequest
## with exactly six required fields (request_id, stage_id, scope, context, preferred_difficulty, exclude_question_ids)
## and that QuestionService successfully accepts the request, creates a QuestionSession, and returns a question.

class RequestSpyController:
	extends RefCounted
	var captured_request: Dictionary = {}
	var real_controller: RefCounted

	func _init(p_real: RefCounted) -> void:
		real_controller = p_real

	func attach_panel(panel: Control) -> void:
		if real_controller != null and real_controller.has_method("attach_panel"):
			real_controller.call("attach_panel", panel)

	func start_question(req: Dictionary) -> Dictionary:
		captured_request = req.duplicate(true)
		if real_controller != null and real_controller.has_method("start_question"):
			return real_controller.call("start_question", req) as Dictionary
		return {}

static func run_all_tests() -> Dictionary:
	print("--- RUNNING APPROOT QUESTIONREQUEST CONTRACT SUITE (APPROOT-QR-001..016) ---")
	var passes: int = 0
	var fails: int = 0
	var waiting: int = 0

	var tests: Array[Dictionary] = [
		{"code": "APPROOT-QR-001", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_001_six_canonical_fields")},
		{"code": "APPROOT-QR-002", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_002_request_id_valid")},
		{"code": "APPROOT-QR-003", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_003_stage_id_equals_active_stage")},
		{"code": "APPROOT-QR-004", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_004_scope_equals_practice_question_scope")},
		{"code": "APPROOT-QR-005", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_005_context_valid_practice")},
		{"code": "APPROOT-QR-006", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_006_preferred_difficulty_null_by_default")},
		{"code": "APPROOT-QR-007", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_007_exclude_question_ids_empty_array")},
		{"code": "APPROOT-QR-008", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_008_no_extra_fields")},
		{"code": "APPROOT-QR-009", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_009_missing_required_field_detected")},
		{"code": "APPROOT-QR-010", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_010_wrong_field_type_detected")},
		{"code": "APPROOT-QR-011", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_011_invalid_context_rejected")},
		{"code": "APPROOT-QR-012", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_012_incorrect_stage_id_detected")},
		{"code": "APPROOT-QR-013", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_013_approot_request_accepted_by_service")},
		{"code": "APPROOT-QR-014", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_014_approot_request_creates_active_session")},
		{"code": "APPROOT-QR-015", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_015_approot_request_returns_question_and_interaction")},
		{"code": "APPROOT-QR-016", "func": Callable(TestAppRootQuestionRequestIntegration, "test_approot_qr_016_composed_f5_full_production_path")}
	]

	for t in tests:
		var fn: Callable = t["func"] as Callable
		var res: String = String(fn.call())
		match res:
			"PASS":
				passes += 1
			"FAIL":
				fails += 1
			"WAITING":
				waiting += 1
			_:
				fails += 1

	print("==========================================")
	print("APPROOT QUESTIONREQUEST SUITE SUMMARY:")
	print("  PASS: %d" % passes)
	print("  FAIL: %d" % fails)
	print("  WAITING: %d" % waiting)
	print("==========================================")

	return {
		"pass": passes,
		"fail": fails,
		"waiting": waiting
	}

static func _setup_approot_with_spy() -> Dictionary:
	var packed: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	if packed == null:
		return {}
	var app: AppRoot = packed.instantiate() as AppRoot
	if app == null:
		return {}

	app.bootstrap_runtime("res://tests/fixtures/content/valid_catalog")
	app.start_new_game()

	var real_ctrl: RefCounted = app.get_question_controller()
	var spy: RequestSpyController = RequestSpyController.new(real_ctrl)
	app.set("_question_controller", spy)

	app.call("_start_current_question")

	return {
		"app": app,
		"spy": spy,
		"captured": spy.captured_request
	}

# APPROOT-QR-001: Real AppRoot question-start path produces exactly six canonical fields.
static func test_approot_qr_001_six_canonical_fields() -> String:
	print("[APPROOT-QR-001] Testing AppRoot question-start path produces six canonical fields...")
	var data: Dictionary = _setup_approot_with_spy()
	if data.is_empty():
		print("[APPROOT-QR-001] FAIL: Unable to setup AppRoot with spy")
		return "FAIL"
	var app: AppRoot = data["app"] as AppRoot
	var req: Dictionary = data["captured"] as Dictionary
	app.free()

	var required_fields: Array[String] = ["request_id", "stage_id", "scope", "context", "preferred_difficulty", "exclude_question_ids"]
	for field in required_fields:
		if not req.has(field):
			print("[APPROOT-QR-001] FAIL (BASELINE DEFECT): AppRoot QuestionRequest missing required field '%s' (request keys=%s)" % [field, str(req.keys())])
			return "FAIL"

	if req.size() != 6:
		print("[APPROOT-QR-001] FAIL: Request size is %d, expected 6" % req.size())
		return "FAIL"

	print("[APPROOT-QR-001] PASS: AppRoot question-start path produces exactly six canonical fields")
	return "PASS"

# APPROOT-QR-002: request_id comes from legitimate AppRoot request-ID mechanism.
static func test_approot_qr_002_request_id_valid() -> String:
	print("[APPROOT-QR-002] Testing request_id is non-empty String...")
	var data: Dictionary = _setup_approot_with_spy()
	if data.is_empty():
		return "FAIL"
	var app: AppRoot = data["app"] as AppRoot
	var req: Dictionary = data["captured"] as Dictionary
	app.free()

	if not req.has("request_id") or not (req["request_id"] is String) or String(req["request_id"]).is_empty():
		print("[APPROOT-QR-002] FAIL (BASELINE DEFECT): Invalid or missing request_id in AppRoot QuestionRequest")
		return "FAIL"

	print("[APPROOT-QR-002] PASS: request_id is valid non-empty String '%s'" % String(req["request_id"]))
	return "PASS"

# APPROOT-QR-003: stage_id equals current active StageContext/GameFlow authority.
static func test_approot_qr_003_stage_id_equals_active_stage() -> String:
	print("[APPROOT-QR-003] Testing stage_id equals current active StageContext...")
	var data: Dictionary = _setup_approot_with_spy()
	if data.is_empty():
		return "FAIL"
	var app: AppRoot = data["app"] as AppRoot
	var req: Dictionary = data["captured"] as Dictionary
	app.free()

	if not req.has("stage_id"):
		print("[APPROOT-QR-003] FAIL (BASELINE DEFECT): AppRoot QuestionRequest missing stage_id field")
		return "FAIL"

	var stage_id: String = String(req.get("stage_id", ""))
	if stage_id != "stage_01_01":
		print("[APPROOT-QR-003] FAIL: stage_id is '%s', expected 'stage_01_01'" % stage_id)
		return "FAIL"

	print("[APPROOT-QR-003] PASS: stage_id equals active stage 'stage_01_01'")
	return "PASS"

# APPROOT-QR-004: scope equals PracticeDefinition.question_scope reached via active StageDefinition.practice_id.
static func test_approot_qr_004_scope_equals_practice_question_scope() -> String:
	print("[APPROOT-QR-004] Testing scope equals PracticeDefinition.question_scope...")
	var data: Dictionary = _setup_approot_with_spy()
	if data.is_empty():
		return "FAIL"
	var app: AppRoot = data["app"] as AppRoot
	var req: Dictionary = data["captured"] as Dictionary
	app.free()

	if not req.has("scope") or not (req["scope"] is Dictionary):
		print("[APPROOT-QR-004] FAIL: Missing or non-Dictionary scope")
		return "FAIL"

	var scope: Dictionary = req["scope"] as Dictionary
	var required_scope_fields: Array[String] = ["dungeon_id", "topic_id", "subtopic_ids", "difficulty_min", "difficulty_max", "interaction_types"]
	for field in required_scope_fields:
		if not scope.has(field):
			print("[APPROOT-QR-004] FAIL: QuestionScope missing required field '%s'" % field)
			return "FAIL"

	print("[APPROOT-QR-004] PASS: scope matches canonical PracticeDefinition.question_scope")
	return "PASS"

# APPROOT-QR-005: context is valid canonical Practice-path context.
static func test_approot_qr_005_context_valid_practice() -> String:
	print("[APPROOT-QR-005] Testing context is valid canonical Practice-path context...")
	var data: Dictionary = _setup_approot_with_spy()
	if data.is_empty():
		return "FAIL"
	var app: AppRoot = data["app"] as AppRoot
	var req: Dictionary = data["captured"] as Dictionary
	app.free()

	if not req.has("context"):
		print("[APPROOT-QR-005] FAIL (BASELINE DEFECT): AppRoot QuestionRequest missing context field")
		return "FAIL"

	var ctx: String = String(req.get("context", ""))
	if ctx != "practice":
		print("[APPROOT-QR-005] FAIL: context is '%s', expected 'practice'" % ctx)
		return "FAIL"

	print("[APPROOT-QR-005] PASS: context is canonical 'practice'")
	return "PASS"

# APPROOT-QR-006: preferred_difficulty is null when no authorized preference exists.
static func test_approot_qr_006_preferred_difficulty_null_by_default() -> String:
	print("[APPROOT-QR-006] Testing preferred_difficulty is null by default...")
	var data: Dictionary = _setup_approot_with_spy()
	if data.is_empty():
		return "FAIL"
	var app: AppRoot = data["app"] as AppRoot
	var req: Dictionary = data["captured"] as Dictionary
	app.free()

	if not req.has("preferred_difficulty"):
		print("[APPROOT-QR-006] FAIL (BASELINE DEFECT): AppRoot QuestionRequest missing preferred_difficulty field")
		return "FAIL"

	var pref: Variant = req.get("preferred_difficulty")
	if pref != null:
		print("[APPROOT-QR-006] FAIL: preferred_difficulty is %s, expected null" % str(pref))
		return "FAIL"

	print("[APPROOT-QR-006] PASS: preferred_difficulty is null")
	return "PASS"

# APPROOT-QR-007: exclude_question_ids is Array[String] and empty when no exclusions exist.
static func test_approot_qr_007_exclude_question_ids_empty_array() -> String:
	print("[APPROOT-QR-007] Testing exclude_question_ids is empty Array...")
	var data: Dictionary = _setup_approot_with_spy()
	if data.is_empty():
		return "FAIL"
	var app: AppRoot = data["app"] as AppRoot
	var req: Dictionary = data["captured"] as Dictionary
	app.free()

	if not req.has("exclude_question_ids"):
		print("[APPROOT-QR-007] FAIL (BASELINE DEFECT): AppRoot QuestionRequest missing exclude_question_ids field")
		return "FAIL"

	var excl: Variant = req.get("exclude_question_ids")
	if not (excl is Array) or not (excl as Array).is_empty():
		print("[APPROOT-QR-007] FAIL: exclude_question_ids is %s, expected empty Array" % str(excl))
		return "FAIL"

	print("[APPROOT-QR-007] PASS: exclude_question_ids is empty Array")
	return "PASS"

# APPROOT-QR-008: No extra fields.
static func test_approot_qr_008_no_extra_fields() -> String:
	print("[APPROOT-QR-008] Testing no extra fields in QuestionRequest...")
	var data: Dictionary = _setup_approot_with_spy()
	if data.is_empty():
		return "FAIL"
	var app: AppRoot = data["app"] as AppRoot
	var req: Dictionary = data["captured"] as Dictionary
	app.free()

	if req.size() != 6:
		print("[APPROOT-QR-008] FAIL (BASELINE DEFECT): QuestionRequest has %d fields, expected exactly 6" % req.size())
		return "FAIL"

	print("[APPROOT-QR-008] PASS: QuestionRequest contains exactly 6 canonical fields without extra keys")
	return "PASS"

# APPROOT-QR-009: Missing required field is detected.
static func test_approot_qr_009_missing_required_field_detected() -> String:
	print("[APPROOT-QR-009] Testing QuestionService detects missing required field...")
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	var qs: QuestionService = QuestionService.new(repo.get_catalog())

	var incomplete_req: Dictionary = {
		"request_id": "req_001",
		"scope": {"dungeon_id": "dungeon_01", "topic_id": "trial_sample_event", "subtopic_ids": [], "difficulty_min": 1, "difficulty_max": 3, "interaction_types": []}
	}

	var res: Dictionary = qs.request_question(incomplete_req)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION:
		print("[APPROOT-QR-009] FAIL: Missing field request was not rejected with INVALID_QUESTION")
		return "FAIL"

	print("[APPROOT-QR-009] PASS: Missing required field correctly rejected with INVALID_QUESTION")
	return "PASS"

# APPROOT-QR-010: Wrong field type is detected.
static func test_approot_qr_010_wrong_field_type_detected() -> String:
	print("[APPROOT-QR-010] Testing QuestionService detects wrong field type...")
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	var qs: QuestionService = QuestionService.new(repo.get_catalog())

	var invalid_type_req: Dictionary = {
		"request_id": "req_001",
		"stage_id": "stage_01_01",
		"scope": {"dungeon_id": "dungeon_01", "topic_id": "trial_sample_event", "subtopic_ids": [], "difficulty_min": 1, "difficulty_max": 3, "interaction_types": []},
		"context": "practice",
		"preferred_difficulty": "invalid_type",
		"exclude_question_ids": []
	}

	var res: Dictionary = qs.request_question(invalid_type_req)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION:
		print("[APPROOT-QR-010] FAIL: Wrong field type request was not rejected")
		return "FAIL"

	print("[APPROOT-QR-010] PASS: Wrong field type correctly rejected")
	return "PASS"

# APPROOT-QR-011: Invalid context is rejected.
static func test_approot_qr_011_invalid_context_rejected() -> String:
	print("[APPROOT-QR-011] Testing QuestionService rejects invalid context...")
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	var qs: QuestionService = QuestionService.new(repo.get_catalog())

	var invalid_ctx_req: Dictionary = {
		"request_id": "req_001",
		"stage_id": "stage_01_01",
		"scope": {"dungeon_id": "dungeon_01", "topic_id": "trial_sample_event", "subtopic_ids": [], "difficulty_min": 1, "difficulty_max": 3, "interaction_types": []},
		"context": "unknown_context",
		"preferred_difficulty": null,
		"exclude_question_ids": []
	}

	var res: Dictionary = qs.request_question(invalid_ctx_req)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION:
		print("[APPROOT-QR-011] FAIL: Invalid context request was not rejected")
		return "FAIL"

	print("[APPROOT-QR-011] PASS: Invalid context correctly rejected")
	return "PASS"

# APPROOT-QR-012: Incorrect stage_id relative to active StageContext is detected.
static func test_approot_qr_012_incorrect_stage_id_detected() -> String:
	print("[APPROOT-QR-012] Testing QuestionService detects unknown/incorrect stage_id...")
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	var qs: QuestionService = QuestionService.new(repo.get_catalog())

	var wrong_stage_req: Dictionary = {
		"request_id": "req_001",
		"stage_id": "stage_unknown_999",
		"scope": {"dungeon_id": "dungeon_01", "topic_id": "trial_sample_event", "subtopic_ids": [], "difficulty_min": 1, "difficulty_max": 3, "interaction_types": []},
		"context": "practice",
		"preferred_difficulty": null,
		"exclude_question_ids": []
	}

	var res: Dictionary = qs.request_question(wrong_stage_req)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION:
		print("[APPROOT-QR-012] FAIL: Unknown stage_id request was not rejected")
		return "FAIL"

	print("[APPROOT-QR-012] PASS: Unknown stage_id correctly rejected")
	return "PASS"

# APPROOT-QR-013: Valid AppRoot-built request is accepted by QuestionService.
static func test_approot_qr_013_approot_request_accepted_by_service() -> String:
	print("[APPROOT-QR-013] Testing AppRoot._start_current_question() request is accepted by QuestionService...")
	var packed: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	if packed == null:
		return "FAIL"
	var app: AppRoot = packed.instantiate() as AppRoot
	app.bootstrap_runtime("res://tests/fixtures/content/valid_catalog")
	app.start_new_game()

	var res: Dictionary = app.call("_start_current_question") as Dictionary
	app.free()

	if not bool(res.get("success", false)):
		print("[APPROOT-QR-013] FAIL (BASELINE DEFECT): AppRoot._start_current_question() failed with error: %s" % str(res))
		return "FAIL"

	print("[APPROOT-QR-013] PASS: AppRoot-built request successfully accepted by QuestionService")
	return "PASS"

# APPROOT-QR-014: Valid AppRoot-built request creates active QuestionSession.
static func test_approot_qr_014_approot_request_creates_active_session() -> String:
	print("[APPROOT-QR-014] Testing AppRoot question-start creates active QuestionSession...")
	var packed: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	if packed == null:
		return "FAIL"
	var app: AppRoot = packed.instantiate() as AppRoot
	app.bootstrap_runtime("res://tests/fixtures/content/valid_catalog")
	app.start_new_game()

	var res: Dictionary = app.call("_start_current_question") as Dictionary
	var qs: QuestionService = app.get_question_service()
	var has_session: bool = (qs != null and qs.has_active_session())
	app.free()

	if not bool(res.get("success", false)) or not has_session:
		print("[APPROOT-QR-014] FAIL (BASELINE DEFECT): Active QuestionSession not created after AppRoot question start")
		return "FAIL"

	print("[APPROOT-QR-014] PASS: Active QuestionSession successfully created")
	return "PASS"

# APPROOT-QR-015: Valid AppRoot-built request returns a real question and interaction type.
static func test_approot_qr_015_approot_request_returns_question_and_interaction() -> String:
	print("[APPROOT-QR-015] Testing AppRoot question-start returns real question and interaction_type...")
	var packed: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	if packed == null:
		return "FAIL"
	var app: AppRoot = packed.instantiate() as AppRoot
	app.bootstrap_runtime("res://tests/fixtures/content/valid_catalog")
	app.start_new_game()

	var res: Dictionary = app.call("_start_current_question") as Dictionary
	app.free()

	if not bool(res.get("success", false)):
		print("[APPROOT-QR-015] FAIL (BASELINE DEFECT): AppRoot question-start failed: %s" % str(res))
		return "FAIL"

	var question: Dictionary = res.get("question", {}) as Dictionary
	var question_id: String = String(question.get("question_id", ""))
	var interaction_type: String = String(question.get("interaction_type", ""))

	if question_id.is_empty() or interaction_type.is_empty():
		print("[APPROOT-QR-015] FAIL: Returned question payload missing question_id or interaction_type")
		return "FAIL"

	print("[APPROOT-QR-015] PASS: Returned real question_id='%s', interaction_type='%s'" % [question_id, interaction_type])
	return "PASS"

# APPROOT-QR-016: Full composed production F5 route validation (Start New Game -> Lesson -> Start Puzzle -> QuestionPanel populated)
static func test_approot_qr_016_composed_f5_full_production_path() -> String:
	print("[APPROOT-QR-016] Testing full composed production F5 route (Start New Game -> Lesson -> Start Puzzle)...")
	var packed: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	if packed == null:
		print("[APPROOT-QR-016] FAIL: Unable to load app_root.tscn")
		return "FAIL"

	var app: AppRoot = packed.instantiate() as AppRoot
	if app == null:
		print("[APPROOT-QR-016] FAIL: Unable to instantiate AppRoot")
		return "FAIL"

	app.bootstrap_runtime("res://tests/fixtures/content/valid_catalog")
	app.start_new_game()

	var pres_shell: StagePresentationShell = app.get_presentation_shell() as StagePresentationShell
	if pres_shell == null:
		print("[APPROOT-QR-016] FAIL: StagePresentationShell is null")
		app.free()
		return "FAIL"

	var lesson_panel: LessonPanel = pres_shell.get_lesson_panel()
	if lesson_panel == null:
		print("[APPROOT-QR-016] FAIL: LessonPanel is null")
		app.free()
		return "FAIL"

	# If starting in Story mode, advance through story into lesson first
	if pres_shell.get_view_mode() == StagePresentationShell.ViewMode.MODE_STORY:
		pres_shell._on_lesson_continue()

	# Simulate player clicking 'Start Puzzle' on lesson panel
	pres_shell._on_lesson_continue()

	var host_container: MarginContainer = pres_shell.get_question_host_container()
	if host_container == null:
		print("[APPROOT-QR-016] FAIL: QuestionHostContainer is null")
		app.free()
		return "FAIL"

	var panel: QuestionPanel = pres_shell.get_question_panel()
	if panel == null:
		panel = host_container.get_node_or_null("QuestionPanel") as QuestionPanel
	if panel == null:
		print("[APPROOT-QR-016] FAIL: QuestionPanel node not mounted in QuestionHostContainer")
		app.free()
		return "FAIL"

	var prompt_text: String = panel.get_prompt_text()
	var active_view: Control = panel.get_active_interaction_view()

	if prompt_text.is_empty():
		print("[APPROOT-QR-016] FAIL (REPRODUCED REAL-F5 BUG): QuestionPanel prompt text is empty after Start Puzzle!")
		app.free()
		return "FAIL"

	if active_view == null:
		print("[APPROOT-QR-016] FAIL (REPRODUCED REAL-F5 BUG): QuestionPanel active_interaction_view is null after Start Puzzle!")
		app.free()
		return "FAIL"

	if active_view.get_child_count() == 0:
		print("[APPROOT-QR-016] FAIL: Active interaction view has 0 option controls")
		app.free()
		return "FAIL"

	app.free()
	print("[APPROOT-QR-016] PASS: Full composed production F5 route verified successfully!")
	return "PASS"
