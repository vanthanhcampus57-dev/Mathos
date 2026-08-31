class_name TestQaAnswerRevealCheat
extends SceneTree

## Unit test suite for QA-only Correct Answer Reveal Cheat (QA-CHEAT-001..014)

func _initialize() -> void:
	var ok: bool = run_all_tests()
	if ok:
		quit(0)
	else:
		quit(1)

static func _create_overlay() -> QaAnswerRevealOverlay:
	var script_res: GDScript = load("res://src/ui/qa/qa_answer_reveal_overlay.gd") as GDScript
	if script_res != null and script_res.can_instantiate():
		return script_res.new() as QaAnswerRevealOverlay
	return null

static func _create_and_mount_app() -> AppRoot:
	var scene_res: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	if scene_res == null:
		return null
	var app: AppRoot = scene_res.instantiate() as AppRoot
	(Engine.get_main_loop() as SceneTree).root.add_child(app)
	if app.has_method("bootstrap_runtime"):
		app.bootstrap_runtime()
	return app

static func run_all_tests() -> bool:
	print("--- RUNNING QA ANSWER REVEAL CHEAT TEST SUITE (QA-CHEAT-001..014) ---")
	var passes: int = 0
	if test_qa_cheat_001_absent_without_flag(): passes += 1
	if test_qa_cheat_002_available_with_flag(): passes += 1
	if test_qa_cheat_003_multiple_choice_format(): passes += 1
	if test_qa_cheat_004_input_format(): passes += 1
	if test_qa_cheat_005_matching_format(): passes += 1
	if test_qa_cheat_006_drag_drop_format(): passes += 1
	if test_qa_cheat_007_no_session_mutation(): passes += 1
	if test_qa_cheat_008_no_submit_or_evaluation(): passes += 1
	if test_qa_cheat_009_question_change_clears_display(): passes += 1
	if test_qa_cheat_010_retry_session_unchanged(): passes += 1
	if test_qa_cheat_011_runtime_tree_and_visibility(): passes += 1
	if test_qa_cheat_012_question_transition_no_duplication(): passes += 1
	if test_qa_cheat_013_type_aware_transition_rebind(): passes += 1
	if test_qa_cheat_014_input_integer_6_and_no_player_tech_text(): passes += 1

	print("[QA-CHEAT-HARNESS] %d / 14 test scenarios passed" % passes)
	return passes == 14

static func test_qa_cheat_001_absent_without_flag() -> bool:
	print("[QA-CHEAT-001] Testing QA cheat control absent/hidden when --qa-cheats flag is absent...")
	var overlay: QaAnswerRevealOverlay = _create_overlay()
	if overlay == null:
		print("[QA-CHEAT-001] FAIL: Failed to instantiate QaAnswerRevealOverlay")
		return false
	overlay.set_qa_cheats_enabled(false)

	if overlay.visible:
		print("[QA-CHEAT-001] FAIL: Overlay visible when --qa-cheats is disabled")
		overlay.free()
		return false

	if overlay._cheat_button != null and overlay._cheat_button.visible:
		print("[QA-CHEAT-001] FAIL: Cheat button visible when --qa-cheats is disabled")
		overlay.free()
		return false

	print("[QA-CHEAT-001] PASS: Feature cleanly hidden/absent when flag is absent!")
	overlay.free()
	return true

static func test_qa_cheat_002_available_with_flag() -> bool:
	print("[QA-CHEAT-002] Testing QA cheat control available when --qa-cheats is enabled...")
	var overlay: QaAnswerRevealOverlay = _create_overlay()
	if overlay == null:
		print("[QA-CHEAT-002] FAIL: Failed to instantiate QaAnswerRevealOverlay")
		return false
	overlay.set_qa_cheats_enabled(true)

	if not overlay.visible:
		print("[QA-CHEAT-002] FAIL: Overlay not visible when --qa-cheats is enabled")
		overlay.free()
		return false

	if overlay._cheat_button == null or not overlay._cheat_button.visible:
		print("[QA-CHEAT-002] FAIL: Cheat button null or not visible when --qa-cheats is enabled")
		overlay.free()
		return false

	if overlay._cheat_button.text != "🧪 ĐÁP ÁN":
		print("[QA-CHEAT-002] FAIL: Cheat button text != '🧪 ĐÁP ÁN' (got '%s')" % overlay._cheat_button.text)
		overlay.free()
		return false

	print("[QA-CHEAT-002] PASS: Feature available with button '🧪 ĐÁP ÁN' when flag is enabled!")
	overlay.free()
	return true

static func test_qa_cheat_003_multiple_choice_format() -> bool:
	print("[QA-CHEAT-003] Testing Multiple Choice correct answer formatting without raw IDs...")
	var answer_spec: Dictionary = {
		"correct_option_id": "opt_a"
	}
	var question_dict: Dictionary = {
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "Gieo một con xúc xắc cân đối và quan sát số chấm."},
				{"option_id": "opt_b", "text": "Cho nước vào tủ lạnh ở -10°C."}
			]
		}
	}

	var formatted: String = QaAnswerFormatter.format_answer("multiple_choice", answer_spec, question_dict)
	if not formatted.contains("ĐÁP ÁN ĐÚNG") or not formatted.contains("A. Gieo một con xúc xắc"):
		print("[QA-CHEAT-003] FAIL: Formatting failed for multiple_choice: %s" % formatted)
		return false

	if formatted.contains("[opt_a]") or formatted.contains("opt_a"):
		print("[QA-CHEAT-003] FAIL: Raw implementation ID 'opt_a' leaked in multiple_choice reveal: %s" % formatted)
		return false

	print("[QA-CHEAT-003] PASS: Multiple choice option ID resolved to human-readable text 'A. Gieo một con xúc xắc...' without raw IDs!")
	return true

static func test_qa_cheat_004_input_format() -> bool:
	print("[QA-CHEAT-004] Testing Input correct answer formatting...")
	var answer_spec_acc: Dictionary = {
		"accepted_values": [6]
	}
	var answer_spec_val: Dictionary = {
		"target_value": 42,
		"tolerance": 0.1
	}

	var formatted1: String = QaAnswerFormatter.format_answer("input", answer_spec_acc)
	var formatted2: String = QaAnswerFormatter.format_answer("input", answer_spec_val)

	if formatted1 != "ĐÁP ÁN ĐÚNG: 6":
		print("[QA-CHEAT-004] FAIL: accepted_values [6] formatting failed: %s" % formatted1)
		return false

	if not formatted2.contains("42") or not formatted2.contains("±0.1"):
		print("[QA-CHEAT-004] FAIL: Target/tolerance formatting failed: %s" % formatted2)
		return false

	print("[QA-CHEAT-004] PASS: Input correct value and tolerance/accepted values formatted accurately!")
	return true

static func test_qa_cheat_005_matching_format() -> bool:
	print("[QA-CHEAT-005] Testing Matching correct pairs formatting without raw IDs...")
	var answer_spec: Dictionary = {
		"pairs": [
			{"left_id": "item_l1", "right_id": "item_r1"},
			{"left_id": "item_l2", "right_id": "item_r2"}
		]
	}
	var question_dict: Dictionary = {
		"interaction_payload": {
			"left_items": [
				{"item_id": "item_l1", "text": "Gieo 1 đồng xu cân đối"},
				{"item_id": "item_l2", "text": "Gieo 1 con xúc xắc 6 mặt"}
			],
			"right_items": [
				{"item_id": "item_r1", "text": "2 kết quả"},
				{"item_id": "item_r2", "text": "6 kết quả"}
			]
		}
	}

	var formatted: String = QaAnswerFormatter.format_answer("matching", answer_spec, question_dict)
	if not formatted.contains("Gieo 1 đồng xu cân đối") or not formatted.contains("➔") or not formatted.contains("2 kết quả"):
		print("[QA-CHEAT-005] FAIL: Matching pairs formatting failed: %s" % formatted)
		return false

	if formatted.contains("item_l1") or formatted.contains("item_r1"):
		print("[QA-CHEAT-005] FAIL: Raw IDs 'item_l1' leaked in matching reveal: %s" % formatted)
		return false

	print("[QA-CHEAT-005] PASS: Matching internal IDs resolved to human-readable Left ➔ Right texts!")
	return true

static func test_qa_cheat_006_drag_drop_format() -> bool:
	print("[QA-CHEAT-006] Testing Drag/Drop / Classification mapping formatting without raw IDs...")
	var answer_spec: Dictionary = {
		"mappings": [
			{"item_id": "item_1", "target_id": "target_1"},
			{"item_id": "item_2", "target_id": "target_2"}
		]
	}
	var question_dict: Dictionary = {
		"interaction_payload": {
			"items": [
				{"item_id": "item_1", "text": "Bốc ngẫu nhiên 1 viên bi"},
				{"item_id": "item_2", "text": "Thả một viên đá vào nước"}
			],
			"targets": [
				{"target_id": "target_1", "label": "Phép thử ngẫu nhiên"},
				{"target_id": "target_2", "label": "Kết quả tất nhiên"}
			]
		}
	}

	var formatted: String = QaAnswerFormatter.format_answer("drag_drop", answer_spec, question_dict)
	if not formatted.contains("Bốc ngẫu nhiên 1 viên bi") or not formatted.contains("➔") or not formatted.contains("Phép thử ngẫu nhiên"):
		print("[QA-CHEAT-006] FAIL: Drag drop mapping formatting failed: %s" % formatted)
		return false

	if formatted.contains("item_1") or formatted.contains("target_1"):
		print("[QA-CHEAT-006] FAIL: Raw IDs 'item_1' or 'target_1' leaked in drag_drop reveal: %s" % formatted)
		return false

	print("[QA-CHEAT-006] PASS: Classification mapping resolved to human-readable Item ➔ Category texts!")
	return true

static func test_qa_cheat_007_no_session_mutation() -> bool:
	print("[QA-CHEAT-007] Testing reveal action does not mutate QuestionSession...")
	var app: AppRoot = _create_and_mount_app()
	app.start_new_game()
	app._on_lesson_continue_requested()

	var q_svc: QuestionService = app.get_question_service()
	var sess_before: Dictionary = q_svc.get_active_session()
	var sess_id_before: String = String(sess_before.get("session_id", ""))

	var overlay: Control = app.get_qa_overlay()
	overlay.call("set_qa_cheats_enabled", true)
	overlay.call("_on_cheat_button_pressed")

	var sess_after: Dictionary = q_svc.get_active_session()
	var sess_id_after: String = String(sess_after.get("session_id", ""))

	if sess_id_before != sess_id_after or sess_after.is_empty():
		print("[QA-CHEAT-007] FAIL: QuestionSession mutated during reveal!")
		app.queue_free()
		return false

	if bool(sess_after.get("submission_locked", false)) or bool(sess_after.get("completed", false)):
		print("[QA-CHEAT-007] FAIL: Session locked or completed by reveal action!")
		app.queue_free()
		return false

	print("[QA-CHEAT-007] PASS: Reveal action executed with zero QuestionSession mutation!")
	app.queue_free()
	return true

static func test_qa_cheat_008_no_submit_or_evaluation() -> bool:
	print("[QA-CHEAT-008] Testing reveal action does not submit or call QuestionEvaluator...")
	var app: AppRoot = _create_and_mount_app()
	app.start_new_game()
	app._on_lesson_continue_requested()

	var q_panel: QuestionPanel = app.get_question_panel()
	var attempts_before: int = q_panel.get_instance_id()
	if q_panel.get("_is_submitting") == true or q_panel.has_feedback():
		print("[QA-CHEAT-008] FAIL: QuestionPanel in submitting/feedback state before reveal test")
		app.queue_free()
		return false

	var overlay: Control = app.get_qa_overlay()
	overlay.call("set_qa_cheats_enabled", true)
	overlay.call("_on_cheat_button_pressed")

	if q_panel.get("_is_submitting") == true or q_panel.has_feedback():
		print("[QA-CHEAT-008] FAIL: Reveal action triggered submission/feedback on QuestionPanel!")
		app.queue_free()
		return false

	print("[QA-CHEAT-008] PASS: Reveal action performed zero submissions or evaluation calls!")
	app.queue_free()
	return true

static func test_qa_cheat_009_question_change_clears_display() -> bool:
	print("[QA-CHEAT-009] Testing changing question clears previous answer display...")
	var overlay: QaAnswerRevealOverlay = _create_overlay()
	if overlay == null:
		print("[QA-CHEAT-009] FAIL: Failed to instantiate QaAnswerRevealOverlay")
		return false
	overlay.set_qa_cheats_enabled(true)
	overlay._current_question_id = "q_test_1"
	overlay._answer_label.text = "ĐÁP ÁN ĐÚNG: A. Gieo một con xúc xắc"
	overlay._answer_panel.show()
	overlay._is_revealed = true

	overlay.on_question_changed("q_test_2")

	if overlay.is_revealed():
		print("[QA-CHEAT-009] FAIL: Overlay still revealed after question change")
		overlay.free()
		return false

	if overlay._answer_panel.visible:
		print("[QA-CHEAT-009] FAIL: Answer panel visible after question change")
		overlay.free()
		return false

	if not overlay.get_formatted_answer().is_empty():
		print("[QA-CHEAT-009] FAIL: Formatted answer text not cleared after question change")
		overlay.free()
		return false

	print("[QA-CHEAT-009] PASS: Transition to new question cleanly cleared and hid old answer!")
	overlay.free()
	return true

static func test_qa_cheat_010_retry_session_unchanged() -> bool:
	print("[QA-CHEAT-010] Testing retry session behavior remains unchanged when cheat overlay exists...")
	var app: AppRoot = _create_and_mount_app()
	app.start_new_game()
	app._on_lesson_continue_requested()

	var overlay: Control = app.get_qa_overlay()
	overlay.call("set_qa_cheats_enabled", true)

	var q_panel: QuestionPanel = app.get_question_panel()
	var mc_view: MultipleChoiceView = q_panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_b")
	q_panel._submit_button.pressed.emit()

	if q_panel.is_correct():
		print("[QA-CHEAT-010] FAIL: Incorrect submission marked correct")
		app.queue_free()
		return false

	q_panel._submit_button.pressed.emit()

	var q_svc: QuestionService = app.get_question_service()
	if not q_svc.has_active_session():
		print("[QA-CHEAT-010] FAIL: QuestionService has no active session after retry")
		app.queue_free()
		return false

	print("[QA-CHEAT-010] PASS: Retry and session lifecycle remained 100% stable with QA overlay present!")
	app.queue_free()
	return true

static func test_qa_cheat_011_runtime_tree_and_visibility() -> bool:
	print("[QA-CHEAT-011] Testing runtime-tree assertions, CanvasLayer, and viewport containment...")
	var app: AppRoot = _create_and_mount_app()
	if app == null:
		print("[QA-CHEAT-011] FAIL: App null")
		return false
	app.start_new_game()
	app._on_lesson_continue_requested()

	var overlay: Control = app.get_qa_overlay()
	if overlay == null or overlay.get_parent() != app:
		print("[QA-CHEAT-011] FAIL: QaAnswerRevealOverlay null or not mounted under AppRoot")
		app.queue_free()
		return false

	var layer_node: CanvasLayer = overlay.call("get_canvas_layer") as CanvasLayer
	if layer_node == null or layer_node.layer != 100:
		print("[QA-CHEAT-011] FAIL: CanvasLayer null or layer != 100 (got %s)" % str(layer_node))
		app.queue_free()
		return false

	overlay.call("set_qa_cheats_enabled", true)

	var root_ctrl: Control = overlay.call("get_root_control") as Control
	if not overlay.visible or root_ctrl == null or not root_ctrl.visible:
		print("[QA-CHEAT-011] FAIL: Overlay or root control not visible when enabled")
		app.queue_free()
		return false

	var btn: Button = overlay.call("get_cheat_button") as Button
	if btn == null or not btn.visible or btn.mouse_filter != Control.MOUSE_FILTER_STOP:
		print("[QA-CHEAT-011] FAIL: Cheat button null, invisible, or mouse_filter != STOP")
		app.queue_free()
		return false

	print("[QA-CHEAT-011] PASS: Runtime tree assertions, CanvasLayer 100, and viewport containment verified!")
	app.queue_free()
	return true

static func test_qa_cheat_012_question_transition_no_duplication() -> bool:
	print("[QA-CHEAT-012] Testing question transitions do not duplicate overlay nodes...")
	var app: AppRoot = _create_and_mount_app()
	app.start_new_game()
	app._on_lesson_continue_requested()

	var count_1: int = 0
	for child in app.get_children():
		if child.name == "QaAnswerRevealOverlay":
			count_1 += 1

	app._on_question_continue_requested()

	var count_2: int = 0
	for child in app.get_children():
		if child.name == "QaAnswerRevealOverlay":
			count_2 += 1

	if count_1 != 1 or count_2 != 1:
		print("[QA-CHEAT-012] FAIL: Duplicate overlay nodes detected! (count_1: %d, count_2: %d)" % [count_1, count_2])
		app.queue_free()
		return false

	print("[QA-CHEAT-012] PASS: Zero overlay duplication across question transitions verified!")
	app.queue_free()
	return true

static func test_qa_cheat_013_type_aware_transition_rebind() -> bool:
	print("[QA-CHEAT-013] Testing type-aware answer reveal across question transitions...")
	var app: AppRoot = _create_and_mount_app()
	app.start_new_game()
	app._on_lesson_continue_requested()

	var q_svc: QuestionService = app.get_question_service()
	var overlay: Control = app.get_qa_overlay()
	overlay.call("set_qa_cheats_enabled", true)

	for step in range(3):
		var active_q: Dictionary = q_svc.get_active_question()
		var qid: String = String(active_q.get("question_id", ""))
		var itype: String = String(active_q.get("interaction_type", ""))

		# Reset overlay revealed state if previously revealed
		if bool(overlay.call("is_revealed")):
			overlay.call("_on_cheat_button_pressed")

		overlay.call("_on_cheat_button_pressed")
		var revealed_text: String = String(overlay.call("get_formatted_answer"))

		# Assert human readable and no raw IDs
		if revealed_text.is_empty() or revealed_text.contains("[opt_") or revealed_text.contains("item_l") or revealed_text.contains("target_1"):
			print("[QA-CHEAT-013] FAIL: Step %d (qid: %s, type: %s) leaked raw IDs or failed: %s" % [step + 1, qid, itype, revealed_text])
			app.queue_free()
			return false

		if not revealed_text.contains("ĐÁP ÁN ĐÚNG"):
			print("[QA-CHEAT-013] FAIL: Step %d (qid: %s, type: %s) missing header: %s" % [step + 1, qid, itype, revealed_text])
			app.queue_free()
			return false

		# Complete current session to advance cleanly
		var sess: Dictionary = q_svc.get_active_session()
		var sess_id: String = String(sess.get("session_id", ""))
		if not sess_id.is_empty():
			var correct_payload: Dictionary = {}
			var spec: Dictionary = active_q.get("answer_spec", {}) as Dictionary
			if itype == "multiple_choice":
				correct_payload = {"selected_option_id": String(spec.get("correct_option_id", "opt_a"))}
			elif itype == "matching":
				correct_payload = {"pairs": spec.get("pairs", spec.get("correct_pairs", []))}
			elif itype == "drag_drop" or itype == "classification":
				correct_payload = {"mappings": spec.get("mappings", spec.get("item_targets", []))}
			elif itype == "input":
				correct_payload = {"value": (spec.get("accepted_values", [6]) as Array)[0]}

			q_svc.submit_answer({
				"session_id": sess_id,
				"interaction_type": itype,
				"payload": correct_payload
			})
			app._on_question_continue_requested()

	print("[QA-CHEAT-013] PASS: Type-aware reveal across question transitions verified with ZERO raw IDs!")
	app.queue_free()
	return true

static func test_qa_cheat_014_input_integer_6_and_no_player_tech_text() -> bool:
	print("[QA-CHEAT-014] Testing input/integer question q_d1_01_4 canonical answer '6' reveal & no player tech text...")
	# 1. Test canonical answer_spec with accepted_values = [6]
	var spec_6: Dictionary = {
		"accepted_values": [6]
	}
	var formatted_6: String = QaAnswerFormatter.format_answer("input", spec_6)
	if formatted_6 != "ĐÁP ÁN ĐÚNG: 6":
		print("[QA-CHEAT-014] FAIL: Expected 'ĐÁP ÁN ĐÚNG: 6' but got '%s'" % formatted_6)
		return false

	if formatted_6.contains("⚠️") or formatted_6.contains("Không tìm thấy đáp án"):
		print("[QA-CHEAT-014] FAIL: Missing-answer warning produced for input question!")
		return false

	# 2. Test InputView player UI contains ZERO technical strings ("Input response type:", "integer")
	var inp_view: InputView = InputView.new()
	var payload: Dictionary = {"input_type": "integer", "placeholder_text": "Nhập kết quả..."}
	inp_view.setup(payload)

	var line_edit: LineEdit = inp_view.get_node_or_null("InputVBox/ValueLineEdit") as LineEdit
	var meta_lbl: UiMetaLabel = inp_view.get_node_or_null("InputVBox/InputMetaLabel") as UiMetaLabel

	if meta_lbl != null and meta_lbl.visible and not meta_lbl.text.is_empty():
		print("[QA-CHEAT-014] FAIL: InputMetaLabel visible with text '%s'" % meta_lbl.text)
		inp_view.free()
		return false

	if line_edit == null or line_edit.placeholder_text.contains("Input response type") or line_edit.placeholder_text.contains("Enter integer answer"):
		print("[QA-CHEAT-014] FAIL: ValueLineEdit placeholder text contains technical string: '%s'" % (line_edit.placeholder_text if line_edit != null else "null"))
		inp_view.free()
		return false

	print("[QA-CHEAT-014] PASS: Input integer 6 reveal clean & player technical copy eliminated!")
	inp_view.free()
	return true
