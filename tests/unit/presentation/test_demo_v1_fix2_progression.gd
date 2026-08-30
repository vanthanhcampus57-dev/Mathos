class_name TestDemoV1Fix2Progression
extends SceneTree

# Regression test suite for MATHOS-DIRECT-DEMO-BUILD-V1-001-FIX-2 & FIX-3
# Validates runtime progression semantics & safety:
# A: wrong -> retry -> correct does not Stage Complete prematurely
# B: 4 unique questions with one first-attempt miss/retry -> count = 4, accuracy = 75%
# C: new stage resets metrics
# D: all correct first attempt -> count = N, accuracy = 100%
# E: unexpected QuestionService error does NOT trigger practice completion / stage clear

func _initialize() -> void:
	var res: bool = run_all_tests()
	quit(0 if res else 1)

static func run_all_tests() -> bool:
	print("--- RUNNING DEMO BUILD V1 FIX-2/FIX-3 PROGRESSION & SAFETY SUITE ---")
	var ok: bool = true
	ok = ok and test_a_wrong_retry_does_not_prematurely_complete()
	ok = ok and test_b_4_questions_one_miss_retry_accuracy_75()
	ok = ok and test_c_new_stage_resets_metrics()
	ok = ok and test_d_all_correct_first_attempt_100()
	ok = ok and test_e_unexpected_question_service_error_does_not_clear_stage()
	print("==========================================")
	print("DEMO V1 FIX-2/FIX-3 PROGRESSION SUITE SUMMARY: ", "PASS" if ok else "FAIL")
	print("==========================================")
	return ok

static func test_a_wrong_retry_does_not_prematurely_complete() -> bool:
	print("[DEMO-FIX2-A] Testing wrong -> retry -> correct does not Stage Complete prematurely...")
	var app_root = AppRoot.new()
	if not app_root.bootstrap_runtime("res://content"):
		print("[DEMO-FIX2-A] FAIL: AppRoot bootstrap failed")
		return false

	app_root.start_new_game()
	var shell = app_root.get_presentation_shell() as StagePresentationShell
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)

	var q_host = shell.get_question_host_container()
	var panel = q_host.get_node_or_null("QuestionPanel") as QuestionPanel
	if panel == null:
		print("[DEMO-FIX2-A] FAIL: QuestionPanel null")
		return false

	# Submit wrong answer (Option B is incorrect for Q1)
	var mc_view = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null:
		print("[DEMO-FIX2-A] FAIL: MultipleChoiceView null")
		return false

	mc_view.select_option("B")
	panel.request_submit()

	# Verify shell is STILL in QUESTION_HOST / FEEDBACK view mode, NOT STAGE_COMPLETE
	var current_mode = shell.get_view_mode()
	if current_mode == StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE:
		print("[DEMO-FIX2-A] FAIL: Incorrect submission prematurely triggered STAGE_COMPLETE mode!")
		return false

	# Click THỬ LẠI (Retry)
	panel._on_submit_button_pressed()

	# Verify interaction view re-enabled for same question
	if mc_view.is_disabled():
		print("[DEMO-FIX2-A] FAIL: Retry did not re-enable interaction view")
		return false

	# Submit correct answer (Option A)
	mc_view.select_option("A")
	panel.request_submit()

	# Verify shell is STILL in QUESTION_HOST / FEEDBACK view mode until TIẾP TỤC is clicked
	if shell.get_view_mode() == StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE:
		print("[DEMO-FIX2-A] FAIL: Retry correct submission prematurely triggered STAGE_COMPLETE before continue click!")
		return false

	print("[DEMO-FIX2-A] PASS: Wrong -> retry does not trigger premature Stage Complete")
	return true

static func test_b_4_questions_one_miss_retry_accuracy_75() -> bool:
	print("[DEMO-FIX2-B] Testing 4 unique questions with 1 first-attempt miss + retry gives count=4, accuracy=75%...")
	var app_root = AppRoot.new()
	if not app_root.bootstrap_runtime("res://content"):
		print("[DEMO-FIX2-B] FAIL: AppRoot bootstrap failed")
		return false

	app_root.start_new_game()
	var shell = app_root.get_presentation_shell() as StagePresentationShell

	app_root._reset_practice_metrics("stage_01_01")

	# Q1
	app_root._current_question_id = "q_d1_01_1"
	app_root._on_question_completed({"question_id": "q_d1_01_1", "is_correct": true})
	app_root._finalized_question_ids.append("q_d1_01_1")

	# Q2: wrong first attempt
	app_root._current_question_id = "q_d1_01_2"
	app_root._on_question_completed({"question_id": "q_d1_01_2", "is_correct": false})
	# Retry: second attempt correct
	app_root._on_question_completed({"question_id": "q_d1_01_2", "is_correct": true})
	app_root._finalized_question_ids.append("q_d1_01_2")

	# Q3
	app_root._current_question_id = "q_d1_01_3"
	app_root._on_question_completed({"question_id": "q_d1_01_3", "is_correct": true})
	app_root._finalized_question_ids.append("q_d1_01_3")

	# Q4
	app_root._current_question_id = "q_d1_01_4"
	app_root._on_question_completed({"question_id": "q_d1_01_4", "is_correct": true})
	app_root._finalized_question_ids.append("q_d1_01_4")

	# Finish practice
	app_root._finish_stage_practice()

	var complete_panel = shell.get_stage_complete_panel()
	if complete_panel == null:
		print("[DEMO-FIX2-B] FAIL: StageCompletePanel null")
		return false

	var count_lbl = complete_panel.get_node_or_null("MarginContainer/VBoxContainer/StatsHBox/QuestionCountPanel/VBox/Value") as Label
	var acc_lbl = complete_panel.get_node_or_null("MarginContainer/VBoxContainer/StatsHBox/AccuracyPanel/VBox/Value") as Label

	if count_lbl == null or acc_lbl == null:
		print("[DEMO-FIX2-B] FAIL: Metric labels null")
		return false

	var count_val: int = int(count_lbl.text)
	var acc_val: String = acc_lbl.text

	if count_val != 4 or acc_val != "75%":
		print("[DEMO-FIX2-B] FAIL: Expected count 4 and accuracy 75%%, got count=%d, acc='%s'" % [count_val, acc_val])
		return false

	print("[DEMO-FIX2-B] PASS: 4 unique questions with 1 miss+retry produces count=4, accuracy=75%")
	return true

static func test_c_new_stage_resets_metrics() -> bool:
	print("[DEMO-FIX2-C] Testing new stage resets metrics...")
	var app_root = AppRoot.new()
	if not app_root.bootstrap_runtime("res://content"):
		print("[DEMO-FIX2-C] FAIL: AppRoot bootstrap failed")
		return false

	app_root.start_new_game()
	var arr: Array[String] = ["q1", "q2", "q3"]
	app_root._finalized_question_ids = arr
	app_root._first_attempt_results = {"q1": true, "q2": false, "q3": true}

	# Move to next stage
	app_root._reset_practice_metrics("stage_01_02")

	if not app_root._finalized_question_ids.is_empty() or not app_root._first_attempt_results.is_empty():
		print("[DEMO-FIX2-C] FAIL: Practice metrics not reset on new stage boundary")
		return false

	print("[DEMO-FIX2-C] PASS: New stage boundary resets metrics cleanly")
	return true

static func test_d_all_correct_first_attempt_100() -> bool:
	print("[DEMO-FIX2-D] Testing all correct first attempt produces count=N and accuracy=100%...")
	var app_root = AppRoot.new()
	if not app_root.bootstrap_runtime("res://content"):
		print("[DEMO-FIX2-D] FAIL: AppRoot bootstrap failed")
		return false

	app_root.start_new_game()
	var shell = app_root.get_presentation_shell() as StagePresentationShell

	app_root._reset_practice_metrics("stage_01_01")
	for i in range(1, 5):
		var qid: String = "q_d1_01_%d" % i
		app_root._on_question_completed({"question_id": qid, "is_correct": true})
		app_root._finalized_question_ids.append(qid)

	app_root._finish_stage_practice()

	var complete_panel = shell.get_stage_complete_panel()
	var count_lbl = complete_panel.get_node_or_null("MarginContainer/VBoxContainer/StatsHBox/QuestionCountPanel/VBox/Value") as Label
	var acc_lbl = complete_panel.get_node_or_null("MarginContainer/VBoxContainer/StatsHBox/AccuracyPanel/VBox/Value") as Label

	if int(count_lbl.text) != 4 or acc_lbl.text != "100%":
		print("[DEMO-FIX2-D] FAIL: Expected count 4 and acc 100%%, got count=%s, acc=%s" % [count_lbl.text, acc_lbl.text])
		return false

	print("[DEMO-FIX2-D] PASS: All correct first attempt produces count=4 and accuracy=100%")
	return true

static func test_e_unexpected_question_service_error_does_not_clear_stage() -> bool:
	print("[DEMO-FIX3-SAFETY] Testing unexpected QuestionService error does NOT trigger practice completion / stage clear...")
	var app_root = AppRoot.new()
	if not app_root.bootstrap_runtime("res://content"):
		print("[DEMO-FIX3-SAFETY] FAIL: AppRoot bootstrap failed")
		return false

	app_root.start_new_game()
	var shell = app_root.get_presentation_shell() as StagePresentationShell
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)

	# Set active practice stage ID to invalid string so QuestionService returns INVALID_QUESTION error
	app_root._active_practice_stage_id = "invalid_stage_non_existent"

	app_root._on_question_continue_requested()

	# Verify shell is NOT in MODE_STAGE_COMPLETE
	if shell.get_view_mode() == StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE:
		print("[DEMO-FIX3-SAFETY] FAIL: Unexpected QuestionService error inappropriately awarded Stage Complete!")
		return false

	print("[DEMO-FIX3-SAFETY] PASS: Unexpected QuestionService error safely aborted stage clear")
	return true
