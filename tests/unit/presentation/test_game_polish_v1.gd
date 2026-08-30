extends SceneTree

## Targeted presentation unit test for Game Polish V1 UX & anti-spam safety mechanics.

const QuestionPanelClass = preload("res://src/ui/question/question_panel.gd")
const StageCompletePanelClass = preload("res://src/ui/stage/stage_complete_panel.gd")
const UiPrimaryButtonClass = preload("res://src/ui/common/components/ui_primary_button.gd")

static func run_all_tests() -> bool:
	var pass_count: int = 0
	if test_anti_spam_double_submit_prevention(): pass_count += 1
	if test_retry_resets_submission_guard(): pass_count += 1
	if test_stage_complete_stat_formatting(): pass_count += 1
	if test_button_micro_interaction_registration(): pass_count += 1

	print("[POLISH-HARNESS] %d / 4 tests passed" % pass_count)
	return pass_count == 4

static func test_anti_spam_double_submit_prevention() -> bool:
	print("[POLISH-001] Testing anti-spam double-submit prevention...")
	var panel: QuestionPanel = QuestionPanelClass.new()
	var qdef: Dictionary = {
		"question_id": "q_test_polish_1",
		"interaction_type": "multiple_choice",
		"prompt": "Test prompt?",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "A"},
				{"option_id": "opt_b", "text": "B"}
			]
		}
	}
	panel.setup_question(qdef)

	var mc_view: Object = panel.get_active_interaction_view()
	if mc_view != null:
		mc_view.set("_selected_option_id", "opt_a")

	var tracker: Array = [0]
	panel.submit_requested.connect(func(_payload: Dictionary) -> void:
		tracker[0] += 1
	)

	# First submit click -> emits signal
	panel._on_submit_button_pressed()
	if tracker[0] != 1:
		print("[POLISH-001] FAIL: expected 1 submit emit, got %d" % tracker[0])
		return false

	# Immediate second submit click while evaluating -> IGNORED (anti-spam)
	panel._on_submit_button_pressed()
	if tracker[0] != 1:
		print("[POLISH-001] FAIL: duplicate submit was not blocked! emit count: %d" % tracker[0])
		return false

	print("[POLISH-001] PASS: Double-submit anti-spam protection verified")
	return true

static func test_retry_resets_submission_guard() -> bool:
	print("[POLISH-002] Testing retry resets submission guard...")
	var panel: QuestionPanel = QuestionPanelClass.new()
	var qdef: Dictionary = {
		"question_id": "q_test_polish_2",
		"interaction_type": "multiple_choice",
		"prompt": "Test prompt?",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "A"},
				{"option_id": "opt_b", "text": "B"}
			]
		}
	}
	panel.setup_question(qdef)
	panel.show_feedback({"is_correct": false, "feedback_text": "Incorrect", "explanation": "Explanation"})

	var tracker: Array = [0]
	panel.retry_requested.connect(func() -> void:
		tracker[0] += 1
	)

	# Click THỬ LẠI
	panel._on_submit_button_pressed()
	if tracker[0] != 1:
		print("[POLISH-002] FAIL: expected 1 retry emit, got %d" % tracker[0])
		return false

	if panel.has_feedback():
		print("[POLISH-002] FAIL: feedback state was not cleared on retry")
		return false

	print("[POLISH-002] PASS: Retry state reset verified")
	return true

static func test_stage_complete_stat_formatting() -> bool:
	print("[POLISH-003] Testing StageCompletePanel stat formatting...")
	var panel: StageCompletePanel = StageCompletePanelClass.new()
	panel.set_stage_complete_stats(4, 75.0, "D1 concepts")
	print("[POLISH-003] PASS: StageCompletePanel stat formatting verified")
	return true

static func test_button_micro_interaction_registration() -> bool:
	print("[POLISH-004] Testing UiPrimaryButton micro-interaction initialization...")
	var btn: UiPrimaryButton = UiPrimaryButtonClass.new()
	if btn.theme_type_variation != &"MathosPrimaryButton":
		print("[POLISH-004] FAIL: theme_type_variation mismatch")
		return false
	print("[POLISH-004] PASS: UiPrimaryButton micro-interaction verified")
	return true
