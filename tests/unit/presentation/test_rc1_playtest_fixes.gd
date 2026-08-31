extends SceneTree

## Unit & QA test suite for MATHOS-RC1-PLAYTEST-FIX-BATCH-001
## Verifies RC1 Playtest Bug Fixes:
## - BUG RC1-003: Wrong -> Retry -> Correct -> Submit succeeds (no submission lock/block)
## - BUG RC1-004: Advisor panel opacity restored on retry
## - BUG RC1-002: Internal question IDs and raw option prefixes (opt_a) hidden from player presentation while preserving evaluator IDs
## - BUG RC1-001: Internal NPC ID (npc_arithmos) hidden from player presentation (displays 'CỐ VẤN')

const AppRootClass = preload("res://src/app/app_root.gd")
const StagePresentationShellClass = preload("res://src/ui/stage/stage_presentation_shell.gd")
const QuestionPanelClass = preload("res://src/ui/question/question_panel.gd")
const LessonPanelClass = preload("res://src/ui/lesson/lesson_panel.gd")
const MultipleChoiceViewClass = preload("res://src/ui/question/interactions/multiple_choice_view.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS RC1 PLAYTEST FIXES QA HARNESS ---")
	var ok: bool = run_all_tests()
	if ok:
		print("MATHOS RC1 PLAYTEST FIXES QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS RC1 PLAYTEST FIXES QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var passes: int = 0
	if test_rc1_003_retry_submit_succeeds_end_to_end(): passes += 1
	if test_rc1_003_retry_resets_every_submit_lock(): passes += 1
	if test_rc1_004_advisor_opacity_restored_on_retry(): passes += 1
	if test_rc1_002_question_id_hidden_from_presentation(): passes += 1
	if test_rc1_002_option_internal_ids_hidden_evaluator_intact(): passes += 1
	if test_rc1_001_npc_internal_id_hidden(): passes += 1

	print("[RC1-FIX-HARNESS] %d / 6 test scenarios passed" % passes)
	return passes == 6

static func test_rc1_003_retry_submit_succeeds_end_to_end() -> bool:
	print("[RC1-003-01] Testing wrong -> retry -> correct -> submit succeeds end-to-end...")
	var app: AppRoot = AppRootClass.new()
	app._ready()
	app.start_new_game()
	app._on_lesson_continue_requested()

	# 1. First attempt: Submit wrong answer via controller (real player flow)
	var q_res: Dictionary = app._active_question_res
	var q_def: Resource = q_res.get("question_definition") as Resource
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

	app.get_question_controller().submit_answer({"selected_option_id": wrong_opt})

	var host: MarginContainer = app.get_presentation_shell().get_question_host_container()
	var q_panel: QuestionPanel = host.get_node_or_null("QuestionPanel") as QuestionPanel
	if q_panel == null or not q_panel.has_feedback():
		print("[RC1-003-01] FAIL: QuestionPanel does not show feedback after wrong answer")
		app.free()
		return false

	# 2. Player presses "THỬ LẠI" button on QuestionPanel
	q_panel._on_submit_button_pressed()

	# Verify active question session & controller state
	if not app.get_question_controller().has_active_session():
		print("[RC1-003-01] FAIL: Controller has no active session after retry")
		app.free()
		return false

	# 3. Second attempt: Submit correct answer
	var submit_res: Dictionary = app.get_question_controller().submit_answer({"selected_option_id": correct_opt})
	if not bool(submit_res.get("success", false)):
		print("[RC1-003-01] FAIL: Submission failed on retry attempt")
		app.free()
		return false

	print("[RC1-003-01] PASS: Wrong -> Retry -> Correct -> Submit succeeded end-to-end!")
	app.free()
	return true

static func test_rc1_003_retry_resets_every_submit_lock() -> bool:
	print("[RC1-003-02] Testing retry resets every submit lock in QuestionPanel...")
	var panel: QuestionPanel = QuestionPanelClass.new()
	panel._ready()

	var q_view: Dictionary = {
		"question_id": "q_test_01",
		"interaction_type": "multiple_choice",
		"prompt": "Test Prompt",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "Option A"},
				{"option_id": "opt_b", "text": "Option B"}
			]
		}
	}
	panel.setup_question(q_view)

	# Submit wrong
	panel.show_feedback({"is_correct": false, "feedback_text": "Chưa đúng"})
	if panel._submit_button.text != "THỬ LẠI":
		print("[RC1-003-02] FAIL: Submit button text not 'THỬ LẠI' after incorrect feedback")
		panel.free()
		return false

	# Press retry
	panel._on_submit_button_pressed()

	if panel._is_submitting:
		print("[RC1-003-02] FAIL: _is_submitting is true after retry")
		panel.free()
		return false

	if panel._has_feedback:
		print("[RC1-003-02] FAIL: _has_feedback is true after retry")
		panel.free()
		return false

	if panel._submit_button.text != "Xác nhận":
		print("[RC1-003-02] FAIL: Submit button text not 'Xác nhận' after retry")
		panel.free()
		return false

	print("[RC1-003-02] PASS: Retry reset every submit lock cleanly")
	panel.free()
	return true

static func test_rc1_004_advisor_opacity_restored_on_retry() -> bool:
	print("[RC1-004] Testing retry restores advisor opacity and readability...")
	var scene_res: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn") as PackedScene
	var shell: StagePresentationShell = scene_res.instantiate() as StagePresentationShell
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)

	var question_host: MarginContainer = shell.get_question_host_container()
	if question_host == null or question_host.modulate.a < 0.9:
		print("[RC1-004] FAIL: Question host container is dim on initial setup")
		shell.free()
		return false

	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_FEEDBACK_HOST)
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)

	if question_host.modulate.a < 0.9:
		print("[RC1-004] FAIL: Advisor/question host container is dim after retry transition")
		shell.free()
		return false

	print("[RC1-004] PASS: Advisor panel opacity restored cleanly")
	shell.free()
	return true

static func test_rc1_002_question_id_hidden_from_presentation() -> bool:
	print("[RC1-002-01] Testing question_id hidden from presentation...")
	var raw_objective: String = "Khái niệm và bài tập q_d1_01_1"
	var sanitized: String = QuestionPanelClass.sanitize_presentation_text(raw_objective)

	if sanitized.contains("q_d1_01_1") or sanitized.contains("q_"):
		print("[RC1-002-01] FAIL: Sanitized text still contains internal ID: '%s'" % sanitized)
		return false

	if sanitized != "Khái niệm và bài tập":
		print("[RC1-002-01] FAIL: Unexpected sanitized output: '%s'" % sanitized)
		return false

	print("[RC1-002-01] PASS: question_id hidden from presentation cleanly")
	return true

static func test_rc1_002_option_internal_ids_hidden_evaluator_intact() -> bool:
	print("[RC1-002-02] Testing option internal IDs hidden while evaluator IDs remain intact...")
	var mc_view: MultipleChoiceView = MultipleChoiceViewClass.new()
	mc_view.setup({
		"options": [
			{"option_id": "opt_a", "text": "Gieo con xúc xắc"},
			{"option_id": "opt_b", "text": "Đun sôi nước"}
		]
	})

	var btn_a: UiOptionCard = mc_view._option_buttons.get("opt_a") as UiOptionCard
	var btn_b: UiOptionCard = mc_view._option_buttons.get("opt_b") as UiOptionCard

	if btn_a == null or not btn_a.text.contains("A. Gieo con xúc xắc") or btn_a.text.contains("opt_a"):
		print("[RC1-002-02] FAIL: Option A text does not display 'A.' or still contains 'opt_a': '%s'" % (btn_a.text if btn_a else "null"))
		mc_view.free()
		return false

	if btn_b == null or not btn_b.text.contains("B. Đun sôi nước") or btn_b.text.contains("opt_b"):
		print("[RC1-002-02] FAIL: Option B text does not display 'B.' or still contains 'opt_b': '%s'" % (btn_b.text if btn_b else "null"))
		mc_view.free()
		return false

	mc_view.select_option("opt_a")
	var payload: Dictionary = mc_view.get_interaction_payload()
	if String(payload.get("selected_option_id", "")) != "opt_a":
		print("[RC1-002-02] FAIL: Evaluator payload option_id altered: '%s'" % String(payload.get("selected_option_id", "")))
		mc_view.free()
		return false

	print("[RC1-002-02] PASS: Option internal IDs hidden from player while evaluator option_ids intact")
	mc_view.free()
	return true

static func test_rc1_001_npc_internal_id_hidden() -> bool:
	print("[RC1-001] Testing NPC internal ID hidden from presentation...")
	var display_name: String = LessonPanelClass.get_player_facing_speaker_name("npc_arithmos")
	if display_name == "npc_arithmos" or display_name.contains("npc_"):
		print("[RC1-001] FAIL: Speaker label contains raw npc_id: '%s'" % display_name)
		return false

	if display_name != "CỐ VẤN":
		print("[RC1-001] FAIL: Speaker label is not 'CỐ VẤN': '%s'" % display_name)
		return false

	print("[RC1-001] PASS: NPC internal ID hidden from player presentation")
	return true
