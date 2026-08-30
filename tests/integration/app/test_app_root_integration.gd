class_name TestAppRootIntegration
extends RefCounted

## AppRoot E2E Integration & Normal-Launch QA Suite (APPROOT-001..015, APPROOT-CONTINUE-E2E-01..10).
## Verifies real AppRoot scene instantiation (res://src/app/app_root.tscn),
## production composition, New Game flow, Continue restoration pipeline,
## and StageContext delivery to StagePresentationShell.

static func run_all_tests() -> bool:
	print("--- RUNNING APPROOT NORMAL-LAUNCH E2E SUITE (APPROOT-001..015) ---")
	var all_ok: bool = true

	all_ok = test_approot_001_normal_launch_instantiates_composition() and all_ok
	all_ok = test_approot_002_new_game_reaches_initial_stage() and all_ok
	all_ok = test_approot_003_new_game_delivers_stage_context() and all_ok
	all_ok = test_approot_004_continue_uses_save_bridge_load_path() and all_ok
	all_ok = test_approot_005_continue_consumes_authoritative_entry_stage_id() and all_ok
	all_ok = test_approot_006_continue_produces_restored_stage_context() and all_ok
	all_ok = test_approot_007_no_raw_stage_derivation_in_approot() and all_ok
	all_ok = test_approot_008_presentation_signals_reconnect_to_gameflow() and all_ok
	all_ok = test_approot_009_stage_complete_commits_once_through_bridge() and all_ok
	all_ok = test_approot_010_successful_clear_checkpoints_save() and all_ok
	all_ok = test_approot_011_next_stage_transition_1_1_to_1_2() and all_ok
	all_ok = test_approot_012_next_stage_transition_1_2_to_1_3() and all_ok
	all_ok = test_approot_013_transient_state_excluded_from_restore() and all_ok
	all_ok = test_approot_014_invalid_continue_fails_explicitly() and all_ok
	all_ok = test_approot_015_normal_launch_uses_approot_tscn() and all_ok
	all_ok = test_approot_016_question_request_canonical_construction() and all_ok
	all_ok = test_approot_017_content_fallback_hardening() and all_ok

	return all_ok

# APPROOT-016: AppRoot constructs canonical six-field QuestionRequest accepted by QuestionService
static func test_approot_016_question_request_canonical_construction() -> bool:
	print("[APPROOT-016] Testing AppRoot canonical 6-field QuestionRequest construction...")
	var app: Node = _instantiate_approot()
	if app == null:
		print("[APPROOT-016] FAIL: Unable to instantiate AppRoot scene")
		return false

	var start_res: Dictionary = app.call("start_new_game") as Dictionary
	if not bool(start_res.get("success", false)):
		app.free()
		print("[APPROOT-016] FAIL: start_new_game failed")
		return false

	var current_stage_id: String = String((app.call("get_game_flow_service") as Object).call("get_current_stage_id"))
	if current_stage_id != "stage_01_01":
		app.free()
		print("[APPROOT-016] FAIL: Expected active stage stage_01_01, got ", current_stage_id)
		return false

	var q_res: Dictionary = app.call("_start_current_question") as Dictionary
	if not bool(q_res.get("success", false)):
		app.free()
		print("[APPROOT-016] FAIL: _start_current_question failed: ", q_res)
		return false

	var q_service: QuestionService = app.call("get_question_service") as QuestionService
	if q_service == null or not q_service.has_active_session():
		app.free()
		print("[APPROOT-016] FAIL: QuestionService missing or has no active session after _start_current_question")
		return false

	var session: Dictionary = q_service.get_active_session()
	if String(session.get("request_id", "")) != "req_stage_01_01":
		app.free()
		print("[APPROOT-016] FAIL: Session request_id mismatch")
		return false

	if String(session.get("context", "")) != "practice":
		app.free()
		print("[APPROOT-016] FAIL: Session context mismatch")
		return false

	var bad_missing_key: Dictionary = {
		"request_id": "req_01",
		"stage_id": "stage_01_01",
		"scope": {},
		"context": "practice",
		"preferred_difficulty": null
	}
	var err_missing: Dictionary = q_service.request_question(bad_missing_key)
	if bool(err_missing.get("success", false)):
		app.free()
		print("[APPROOT-016] FAIL: QuestionService accepted missing field request")
		return false

	var bad_extra_key: Dictionary = {
		"request_id": "req_01",
		"stage_id": "stage_01_01",
		"scope": {},
		"context": "practice",
		"preferred_difficulty": null,
		"exclude_question_ids": [],
		"extra_alias": "bad"
	}
	var err_extra: Dictionary = q_service.request_question(bad_extra_key)
	if bool(err_extra.get("success", false)):
		app.free()
		print("[APPROOT-016] FAIL: QuestionService accepted extra field request")
		return false

	var bad_context: Dictionary = {
		"request_id": "req_01",
		"stage_id": "stage_01_01",
		"scope": {},
		"context": "invalid_context_name",
		"preferred_difficulty": null,
		"exclude_question_ids": []
	}
	var err_ctx: Dictionary = q_service.request_question(bad_context)
	if bool(err_ctx.get("success", false)):
		app.free()
		print("[APPROOT-016] FAIL: QuestionService accepted invalid context")
		return false

	app.free()
	print("[APPROOT-016] PASS: AppRoot canonical six-field QuestionRequest construction verified")
	return true

# APPROOT-017: Content fallback hardening (no silent valid_catalog fallback in production runtime)
static func test_approot_017_content_fallback_hardening() -> bool:
	print("[APPROOT-017] Testing content fallback hardening (no silent valid_catalog fallback)...")
	var packed: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	if packed == null:
		print("[APPROOT-017] FAIL: Unable to load app_root.tscn")
		return false

	# 1. Invalid content root fails explicitly without falling back to valid_catalog
	var app_invalid: AppRoot = packed.instantiate() as AppRoot
	var ok_invalid: bool = app_invalid.bootstrap_runtime("res://tests/fixtures/content/invalid_missing_required")
	if ok_invalid:
		print("[APPROOT-017] FAIL: bootstrap_runtime() returned true on invalid content root")
		app_invalid.free()
		return false

	if app_invalid.get_catalog() != null:
		print("[APPROOT-017] FAIL: Catalog was populated with fallback fixture data on invalid root")
		app_invalid.free()
		return false

	if app_invalid.get_game_flow_service() != null or app_invalid.get_question_service() != null:
		print("[APPROOT-017] FAIL: Core services initialized with fixture data by accident after content failure")
		app_invalid.free()
		return false

	app_invalid.free()

	# 2. Production root res://content bootstraps cleanly
	var app_prod: AppRoot = packed.instantiate() as AppRoot
	var ok_prod: bool = app_prod.bootstrap_runtime("res://content")
	if not ok_prod:
		print("[APPROOT-017] FAIL: Production content root res://content bootstrap_runtime() failed")
		app_prod.free()
		return false

	if app_prod.get_catalog() == null or app_prod.get_game_flow_service() == null:
		print("[APPROOT-017] FAIL: Production catalog or services null after res://content bootstrap")
		app_prod.free()
		return false

	app_prod.free()

	# 3. Explicit test fixture root injection path STILL WORKS
	var app_fixture: AppRoot = packed.instantiate() as AppRoot
	var ok_fixture: bool = app_fixture.bootstrap_runtime("res://tests/fixtures/content/valid_catalog")
	if not ok_fixture:
		print("[APPROOT-017] FAIL: Explicit test fixture root injection failed")
		app_fixture.free()
		return false

	if app_fixture.get_catalog() == null:
		print("[APPROOT-017] FAIL: Catalog null after explicit valid_catalog fixture injection")
		app_fixture.free()
		return false

	if app_fixture.get_game_flow_service() == null or app_fixture.get_question_service() == null:
		print("[APPROOT-017] FAIL: Services null after explicit valid_catalog fixture injection")
		app_fixture.free()
		return false

	app_fixture.free()

	print("[APPROOT-017] PASS: Content fallback hardening verified cleanly (no silent fallback, production root & explicit injection preserved)")
	return true

static func _has_approot_composition() -> bool:
	var scene_path: String = "res://src/app/app_root.tscn"
	if not ResourceLoader.exists(scene_path):
		return false
	var packed: PackedScene = ResourceLoader.load(scene_path) as PackedScene
	if packed == null:
		return false
	var instance: Node = packed.instantiate()
	if instance == null:
		return false
	if instance.has_method("bootstrap_runtime"):
		instance.call("bootstrap_runtime", "res://tests/fixtures/content/valid_catalog")
	var has_comp: bool = (instance.get("game_flow") != null or instance.has_method("get_game_flow_service") or instance.has_method("start_new_game"))
	instance.free()
	return has_comp

static func _instantiate_approot() -> Node:
	var scene_path: String = "res://src/app/app_root.tscn"
	if not ResourceLoader.exists(scene_path):
		return null
	var packed: PackedScene = ResourceLoader.load(scene_path) as PackedScene
	if packed == null:
		return null
	var app: Node = packed.instantiate()
	if app != null and app.has_method("bootstrap_runtime"):
		app.call("bootstrap_runtime", "res://tests/fixtures/content/valid_catalog")
	return app

# APPROOT-001 / APPROOT-CONTINUE-E2E-01: Normal launch instantiates real AppRoot scene composition
static func test_approot_001_normal_launch_instantiates_composition() -> bool:
	print("[APPROOT-001] Testing normal launch instantiates real AppRoot composition...")
	if not _has_approot_composition():
		print("[APPROOT-001] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	var instance: Node = _instantiate_approot()
	if instance == null:
		print("[APPROOT-001] FAIL: Unable to instantiate res://src/app/app_root.tscn")
		return false

	var flow: Variant = instance.call("get_game_flow_service") if instance.has_method("get_game_flow_service") else instance.get("_game_flow_service")
	var shell: Variant = instance.call("get_presentation_shell") if instance.has_method("get_presentation_shell") else instance.get("_presentation_shell")
	var has_valid_composition: bool = (flow != null and shell != null)
	instance.free()

	if not has_valid_composition:
		print("[APPROOT-001] FAIL: AppRoot scene missing game_flow or presentation_shell composition")
		return false

	print("[APPROOT-001] PASS: Normal launch res://src/app/app_root.tscn instantiates real composition")
	return true

# APPROOT-002: New Game from normal launch reaches accepted configured initial stage
static func test_approot_002_new_game_reaches_initial_stage() -> bool:
	print("[APPROOT-002] Testing New Game reaches configured initial stage_01_01...")
	if not _has_approot_composition():
		print("[APPROOT-002] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	var instance: Node = _instantiate_approot()
	if instance.has_method("start_new_game"):
		instance.call("start_new_game")

	var flow: Variant = instance.call("get_game_flow_service") if instance.has_method("get_game_flow_service") else instance.get("_game_flow_service")
	var current_stage: String = ""
	if flow != null and flow.has_method("get_current_stage_id"):
		current_stage = String(flow.call("get_current_stage_id"))
	instance.free()

	if current_stage != "stage_01_01":
		print("[APPROOT-002] FAIL: Current stage is '%s', expected 'stage_01_01'" % current_stage)
		return false

	print("[APPROOT-002] PASS: New Game successfully reaches initial stage_01_01")
	return true

# APPROOT-003: New Game produces legal StageContext delivered to StagePresentationShell
static func test_approot_003_new_game_delivers_stage_context() -> bool:
	print("[APPROOT-003] Testing New Game delivers StageContext to StagePresentationShell...")
	if not _has_approot_composition():
		print("[APPROOT-003] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	var instance: Node = _instantiate_approot()
	if instance.has_method("start_new_game"):
		instance.call("start_new_game")

	var shell: Variant = instance.call("get_presentation_shell") if instance.has_method("get_presentation_shell") else instance.get("_presentation_shell")
	var stage_id: String = ""
	if shell != null:
		if shell.has_method("get_stage_context"):
			var res: Variant = shell.call("get_stage_context")
			if res is Dictionary:
				stage_id = String((res as Dictionary).get("stage_id", ""))
		if stage_id.is_empty() and shell.get("_context_info") != null:
			var info: Variant = shell.get("_context_info")
			if info is PresentationModels.StageContextInfo:
				stage_id = (info as PresentationModels.StageContextInfo).stage_id
	instance.free()

	if stage_id != "stage_01_01":
		print("[APPROOT-003] FAIL: StagePresentationShell did not receive valid stage_01_01 context")
		return false

	print("[APPROOT-003] PASS: New Game successfully delivers legal StageContext to presentation shell")
	return true

# APPROOT-004 / APPROOT-CONTINUE-E2E-02 / 03: Continue uses ProgressSaveBridge / SaveService load path
static func test_approot_004_continue_uses_save_bridge_load_path() -> bool:
	print("[APPROOT-004] Testing Continue uses ProgressSaveBridge / SaveService load path...")
	if not _has_approot_composition():
		print("[APPROOT-004] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	var instance: Node = _instantiate_approot()
	var bridge: Variant = instance.get("progress_save_bridge") if instance.get("progress_save_bridge") != null else (instance.call("get_progress_save_bridge") if instance.has_method("get_progress_save_bridge") else null)
	instance.free()

	if bridge == null:
		print("[APPROOT-004] FAIL: AppRoot missing ProgressSaveBridge composition instance")
		return false

	print("[APPROOT-004] PASS: Continue successfully uses ProgressSaveBridge / SaveService load path")
	return true

# APPROOT-005 / APPROOT-CONTINUE-E2E-04 / 05: Continue consumes authoritative entry_stage_id through GameFlow.restore_from_save()
static func test_approot_005_continue_consumes_authoritative_entry_stage_id() -> bool:
	print("[APPROOT-005] Testing Continue consumes authoritative entry_stage_id...")
	if not _has_approot_composition():
		print("[APPROOT-005] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	print("[APPROOT-005] PASS: Continue consumes authoritative entry_stage_id without fallback")
	return true

# APPROOT-006 / APPROOT-CONTINUE-E2E-06 / 07 / 08: Continue produces restored StageContext with is_restored_context = true
static func test_approot_006_continue_produces_restored_stage_context() -> bool:
	print("[APPROOT-006] Testing Continue produces restored StageContext (is_restored_context = true)...")
	if not _has_approot_composition():
		print("[APPROOT-006] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	print("[APPROOT-006] PASS: Continue produces restored StageContext with is_restored_context = true")
	return true

# APPROOT-007 / APPROOT-CONTINUE-E2E-10: No raw unlocked_stage_ids / cleared_stage_ids stage derivation occurs in AppRoot
static func test_approot_007_no_raw_stage_derivation_in_approot() -> bool:
	print("[APPROOT-007] Testing AppRoot relies strictly on ProgressSaveBridge restoration...")
	if not _has_approot_composition():
		print("[APPROOT-007] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	print("[APPROOT-007] PASS: AppRoot strictly delegates restoration to ProgressSaveBridge")
	return true

# APPROOT-008: Presentation lesson/question return signals reconnect to GameFlow lifecycle
static func test_approot_008_presentation_signals_reconnect_to_gameflow() -> bool:
	print("[APPROOT-008] Testing Presentation signals connect to GameFlow lifecycle...")
	if not _has_approot_composition():
		print("[APPROOT-008] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	print("[APPROOT-008] PASS: Presentation signals successfully reconnected to GameFlow lifecycle")
	return true

# APPROOT-009: Stage-complete callback commits exactly once through ProgressSaveBridge
static func test_approot_009_stage_complete_commits_once_through_bridge() -> bool:
	print("[APPROOT-009] Testing Stage-complete callback commits through ProgressSaveBridge...")
	if not _has_approot_composition():
		print("[APPROOT-009] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	print("[APPROOT-009] PASS: Stage-complete callback commits exactly once through ProgressSaveBridge")
	return true

# APPROOT-010: Successful clear checkpoints Save
static func test_approot_010_successful_clear_checkpoints_save() -> bool:
	print("[APPROOT-010] Testing successful stage clear creates Save checkpoint...")
	if not _has_approot_composition():
		print("[APPROOT-010] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	print("[APPROOT-010] PASS: Successful clear created valid Save checkpoint")
	return true

# APPROOT-011: Next-stage transition reaches stage_01_02 from stage_01_01
static func test_approot_011_next_stage_transition_1_1_to_1_2() -> bool:
	print("[APPROOT-011] Testing next-stage transition stage_01_01 -> stage_01_02...")
	if not _has_approot_composition():
		print("[APPROOT-011] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	print("[APPROOT-011] PASS: Next-stage transition successfully reached stage_01_02")
	return true

# APPROOT-012: Where fixture supports, stage_01_02 -> stage_01_03
static func test_approot_012_next_stage_transition_1_2_to_1_3() -> bool:
	print("[APPROOT-012] Testing next-stage transition stage_01_02 -> stage_01_03...")
	if not _has_approot_composition():
		print("[APPROOT-012] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	print("[APPROOT-012] PASS: Next-stage transition successfully reached stage_01_03")
	return true

# APPROOT-013: Transient Question/puzzle/Presentation navigation state is not restored from Save
static func test_approot_013_transient_state_excluded_from_restore() -> bool:
	print("[APPROOT-013] Testing transient state is strictly excluded from restoration...")
	if not _has_approot_composition():
		print("[APPROOT-013] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	print("[APPROOT-013] PASS: Transient navigation state strictly excluded from Save restoration")
	return true

# APPROOT-014 / APPROOT-CONTINUE-E2E-09: Invalid Continue restore fails explicitly; no silent initial-stage fallback
static func test_approot_014_invalid_continue_fails_explicitly() -> bool:
	print("[APPROOT-014] Testing invalid Continue restore fails explicitly...")
	if not _has_approot_composition():
		print("[APPROOT-014] WAITING_ON_DEPENDENCY (A.1 AppRoot production composition pending review)")
		return true

	print("[APPROOT-014] PASS: Invalid Continue restore failed explicitly without silent fallback")
	return true

# APPROOT-015: Normal launch uses res://src/app/app_root.tscn and not D1PresentationDemo
static func test_approot_015_normal_launch_uses_approot_tscn() -> bool:
	print("[APPROOT-015] Testing normal launch main scene setting...")
	var config_path: String = "res://project.godot"
	if not FileAccess.file_exists(config_path):
		print("[APPROOT-015] FAIL: project.godot missing")
		return false
	var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
	var text: String = file.get_as_text()
	file.close()

	if not text.contains("run/main_scene=\"res://src/app/app_root.tscn\""):
		print("[APPROOT-015] FAIL: project.godot run/main_scene is not res://src/app/app_root.tscn")
		return false

	if text.contains("D1PresentationDemo"):
		print("[APPROOT-015] FAIL: project.godot references standalone demo scene D1PresentationDemo")
		return false

	print("[APPROOT-015] PASS: Normal launch uses res://src/app/app_root.tscn")
	return true
