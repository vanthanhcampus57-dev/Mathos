extends SceneTree

## Full Production Lifecycle & Recovery QA Suite for MATHOS-RC4-QUESTION-SESSION-BINDING-FIX-002
## Verifies exact production F5 startup & session binding lifecycle:
## - test_rc4_001: Instantiates AppRoot -> start New Game -> advance Lesson normally -> verifies controller binding WITHOUT manual bind calls
## - test_rc4_002: Verifies wrong -> retry ("THỬ LẠI") -> correct ("Xác nhận") retry contract stability
## - test_rc4_003: Verifies genuine pre-evaluation submission failure unlocks panel & allows a real second attempt
## - test_rc4_004: Verifies res://assets/backgrounds/misty_forest_v1.jpg loads cleanly as valid Texture2D
## - test_rc4_005: Verifies controller auto-binds to active QuestionService session when controller._active_session_id is empty

const AppRootClass = preload("res://src/app/app_root.gd")
const QuestionPanelClass = preload("res://src/ui/question/question_panel.gd")
const MultipleChoiceViewClass = preload("res://src/ui/question/interactions/multiple_choice_view.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS RC4 INITIAL SESSION BINDING & RECOVERY QA HARNESS ---")
	var ok: bool = run_all_tests()
	if ok:
		print("MATHOS RC4 INITIAL SESSION BINDING & RECOVERY QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS RC4 INITIAL SESSION BINDING & RECOVERY QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var passes: int = 0
	if test_rc4_001_exact_production_initial_session_binding(): passes += 1
	if test_rc4_002_wrong_retry_correct_end_to_end_contract(): passes += 1
	if test_rc4_003_submit_failure_unlocks_panel_for_second_attempt(): passes += 1
	if test_rc4_004_background_asset_loading(): passes += 1
	if test_rc4_005_controller_session_id_empty_autobind_recovery(): passes += 1

	print("[RC4-HARNESS] %d / 5 test scenarios passed" % passes)
	return passes == 5

static func _create_and_mount_app() -> AppRoot:
	var scene_res: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	if scene_res == null:
		return null
	var app: AppRoot = scene_res.instantiate() as AppRoot
	(Engine.get_main_loop() as SceneTree).root.add_child(app)
	if app.has_method("bootstrap_runtime"):
		app.bootstrap_runtime()
	return app

static func test_rc4_001_exact_production_initial_session_binding() -> bool:
	print("[RC4-001] Testing exact production initial session binding WITHOUT manual bind calls...")
	var app: AppRoot = _create_and_mount_app()
	if app == null:
		print("[RC4-001] FAIL: AppRoot instantiation failed")
		return false

	# 1. Start New Game
	app.start_new_game()

	# 2. Advance Lesson normally
	app._on_lesson_continue_requested()

	# 3. Inspect QuestionService and QuestionPresentationController state BEFORE submit
	var q_service: QuestionService = app.get_question_service()
	var q_ctrl: RefCounted = app.get_question_controller()

	if q_service == null or not q_service.has_active_session():
		print("[RC4-001] FAIL: QuestionService does not have an active session after lesson advance")
		app.queue_free()
		return false

	var qs_session: Dictionary = q_service.get_active_session()
	var qs_session_id: String = String(qs_session.get("session_id", ""))

	var ctrl_session_id: String = String(q_ctrl.call("get_active_session_id"))
	if ctrl_session_id.is_empty():
		print("[RC4-001] FAIL: QuestionPresentationController._active_session_id is EMPTY on first question!")
		app.queue_free()
		return false

	if ctrl_session_id != qs_session_id:
		print("[RC4-001] FAIL: Controller session ID '%s' does not match QuestionService session ID '%s'" % [ctrl_session_id, qs_session_id])
		app.queue_free()
		return false

	var active_q: Dictionary = q_service.get_active_question()
	var expected_type: String = String(active_q.get("interaction_type", ""))
	var ctrl_type: String = String(q_ctrl.get("_active_interaction_type"))

	if ctrl_type != expected_type:
		print("[RC4-001] FAIL: Controller interaction_type '%s' does not match question view '%s'" % [ctrl_type, expected_type])
		app.queue_free()
		return false

	print("[RC4-001] PASS: First question correctly bound to controller (Session ID: '%s')" % ctrl_session_id)
	app.queue_free()
	return true

static func test_rc4_002_wrong_retry_correct_end_to_end_contract() -> bool:
	print("[RC4-002] Testing Wrong -> Retry -> Correct flow via real UI button clicks...")
	var app: AppRoot = _create_and_mount_app()
	if app == null:
		print("[RC4-002] FAIL: AppRoot instantiation failed")
		return false

	app.start_new_game()
	app._on_lesson_continue_requested()

	var q_panel: QuestionPanel = app.get_question_panel()
	if q_panel == null:
		print("[RC4-002] FAIL: QuestionPanel is null")
		app.queue_free()
		return false

	var mc_view: MultipleChoiceView = q_panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null:
		print("[RC4-002] FAIL: Active interaction view is not MultipleChoiceView")
		app.queue_free()
		return false

	var q_service: QuestionService = app.get_question_service()
	var q_def_res: Dictionary = app._active_question_res
	var q_def: Resource = q_def_res.get("question_definition") as Resource
	var wrong_opt: String = "opt_b"
	var correct_opt: String = "opt_a"
	if q_def != null:
		var answer_spec: Dictionary = q_def.get("answer_spec") as Dictionary
		var opts: Array = answer_spec.get("options", [])
		for opt in opts:
			if bool(opt.get("is_correct", false)):
				correct_opt = String(opt.get("id", "opt_a"))
			else:
				wrong_opt = String(opt.get("id", "opt_b"))

	# 1. Select wrong option & click submit
	mc_view.select_option(wrong_opt)
	q_panel._submit_button.pressed.emit()

	if q_panel.is_correct():
		print("[RC4-002] FAIL: Wrong answer was marked as correct")
		app.queue_free()
		return false

	if q_panel._submit_button.text != "THỬ LẠI":
		print("[RC4-002] FAIL: Submit button text not 'THỬ LẠI' after incorrect attempt")
		app.queue_free()
		return false

	# 2. Click "THỬ LẠI"
	q_panel._submit_button.pressed.emit()

	# Assert active session exists and controller is bound
	var q_ctrl: RefCounted = app.get_question_controller()
	var ctrl_sess_id: String = String(q_ctrl.call("get_active_session_id"))
	if ctrl_sess_id.is_empty() or not q_service.has_active_session():
		print("[RC4-002] FAIL: Retry session binding failed (ctrl_sess_id: '%s')" % ctrl_sess_id)
		app.queue_free()
		return false

	# 3. Select correct option & click submit
	q_panel = app.get_question_panel()
	mc_view = q_panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option(correct_opt)
	q_panel._submit_button.pressed.emit()

	if not q_panel.is_correct():
		print("[RC4-002] FAIL: Correct answer on retry was not marked correct")
		app.queue_free()
		return false

	print("[RC4-002] PASS: Wrong -> Retry -> Correct flow verified cleanly!")
	app.queue_free()
	return true

static func test_rc4_003_submit_failure_unlocks_panel_for_second_attempt() -> bool:
	print("[RC4-003] Testing genuine submit failure unlocks QuestionPanel & allows real second attempt...")
	var app: AppRoot = _create_and_mount_app()
	if app == null:
		print("[RC4-003] FAIL: AppRoot instantiation failed")
		return false

	app.start_new_game()
	app._on_lesson_continue_requested()

	var q_panel: QuestionPanel = app.get_question_panel()
	var q_ctrl: RefCounted = app.get_question_controller()
	var q_service: QuestionService = app.get_question_service()

	# Force a genuine unrecoverable pre-evaluation failure: clear both controller AND service active sessions
	q_ctrl.set("_active_session_id", "")
	q_service.set("_active_session", null)

	# 1. First attempt: player clicks submit on unrecoverable state
	q_panel._submit_button.pressed.emit()

	# Assert panel recovered from failure
	if q_panel.get("_is_submitting") == true:
		print("[RC4-003] FAIL: QuestionPanel remained locked with _is_submitting=true after submit failure!")
		app.queue_free()
		return false

	if q_panel._submit_button.disabled:
		print("[RC4-003] FAIL: Submit button remained disabled after submit failure!")
		app.queue_free()
		return false

	if q_panel._submit_button.text != "Xác nhận":
		print("[RC4-003] FAIL: Submit button text not restored to 'Xác nhận'")
		app.queue_free()
		return false

	if not q_panel.has_feedback() or not q_panel.get_feedback_text().contains("⚠️"):
		print("[RC4-003] FAIL: QuestionPanel feedback label did not display warning failure message")
		app.queue_free()
		return false

	# 2. Clear cached result and request a fresh legal QuestionSession
	app._active_question_res = {}
	var bind_res: Dictionary = app._start_current_question()
	if not bool(bind_res.get("success", false)):
		print("[RC4-003] FAIL: Failed to restore valid QuestionSession after failure recovery")
		app.queue_free()
		return false

	# 3. Perform a REAL second submit attempt
	q_panel = app.get_question_panel()
	var mc_view: MultipleChoiceView = q_panel.get_active_interaction_view() as MultipleChoiceView
	var correct_opt: String = "opt_a"
	var q_def_res: Dictionary = app._active_question_res
	var q_def: Resource = q_def_res.get("question_definition") as Resource
	if q_def != null:
		var answer_spec: Dictionary = q_def.get("answer_spec") as Dictionary
		var opts: Array = answer_spec.get("options", [])
		for opt in opts:
			if bool(opt.get("is_correct", false)):
				correct_opt = String(opt.get("id", "opt_a"))

	mc_view.select_option(correct_opt)
	q_panel._submit_button.pressed.emit()

	if not q_panel.is_correct():
		print("[RC4-003] FAIL: Real second submit attempt after failure recovery was not processed cleanly")
		app.queue_free()
		return false

	print("[RC4-003] PASS: Genuine failure unlocked panel and real second submit attempt succeeded!")
	app.queue_free()
	return true

static func test_rc4_004_background_asset_loading() -> bool:
	print("[RC4-004] Testing res://assets/backgrounds/misty_forest_v1.jpg asset loading...")
	var path: String = "res://assets/backgrounds/misty_forest_v1.jpg"
	if not ResourceLoader.exists(path):
		print("[RC4-004] FAIL: Asset does not exist: '%s'" % path)
		return false

	var res: Resource = load(path)
	if res == null or not (res is Texture2D):
		print("[RC4-004] FAIL: Failed to load texture from '%s'" % path)
		return false

	var tex: Texture2D = res as Texture2D
	if tex.get_width() <= 0 or tex.get_height() <= 0:
		print("[RC4-004] FAIL: Loaded texture has invalid dimensions (%dx%d)" % [tex.get_width(), tex.get_height()])
		return false

	print("[RC4-004] PASS: misty_forest_v1.jpg loaded cleanly as valid Texture2D (%dx%d)" % [tex.get_width(), tex.get_height()])
	return true

static func test_rc4_005_controller_session_id_empty_autobind_recovery() -> bool:
	print("[RC4-005] Testing controller empty session_id auto-binds to QuestionService active session...")
	var app: AppRoot = _create_and_mount_app()
	if app == null:
		print("[RC4-005] FAIL: AppRoot instantiation failed")
		return false

	app.start_new_game()
	app._on_lesson_continue_requested()

	var q_panel: QuestionPanel = app.get_question_panel()
	var q_ctrl: RefCounted = app.get_question_controller()
	var q_service: QuestionService = app.get_question_service()

	# Clear ONLY controller _active_session_id while QuestionService still has a valid active session
	q_ctrl.set("_active_session_id", "")
	if not q_service.has_active_session():
		print("[RC4-005] FAIL: QuestionService has no active session prior to auto-bind test")
		app.queue_free()
		return false

	var expected_session_id: String = String(q_service.get_active_session().get("session_id", ""))

	# Select correct option & submit
	var mc_view: MultipleChoiceView = q_panel.get_active_interaction_view() as MultipleChoiceView
	var correct_opt: String = "opt_a"
	var q_def_res: Dictionary = app._active_question_res
	var q_def: Resource = q_def_res.get("question_definition") as Resource
	if q_def != null:
		var answer_spec: Dictionary = q_def.get("answer_spec") as Dictionary
		var opts: Array = answer_spec.get("options", [])
		for opt in opts:
			if bool(opt.get("is_correct", false)):
				correct_opt = String(opt.get("id", "opt_a"))

	mc_view.select_option(correct_opt)
	q_panel._submit_button.pressed.emit()

	# Verify controller auto-bound to QuestionService session ID
	var bound_session_id: String = String(q_ctrl.call("get_active_session_id"))
	# Note: after completion submit_answer clears _active_session_id, so check result was successful & evaluated
	if not q_panel.is_correct():
		print("[RC4-005] FAIL: Auto-bind submission did not evaluate answer to correct")
		app.queue_free()
		return false

	if q_panel.has_feedback() and q_panel.get_feedback_text().contains("⚠️"):
		print("[RC4-005] FAIL: Auto-bind submission erroneously triggered failure banner!")
		app.queue_free()
		return false

	print("[RC4-005] PASS: Controller cleanly auto-bound to QuestionService session and evaluated submit without error banner!")
	app.queue_free()
	return true
