class_name TestQuestionPresentation
extends RefCounted

## Unit test suite for QuestionPresentationController, QuestionPanel, and Interaction Views (PRES-001..008, PRES-012..018).

static func run_all_tests() -> bool:
	print("--- RUNNING QUESTION PRESENTATION SUITE ---")
	var all_ok: bool = true
	all_ok = pres_001_multiple_choice_render_and_submit() and all_ok
	all_ok = pres_002_input_render_and_submit() and all_ok
	all_ok = pres_003_drag_drop_canonical_mappings() and all_ok
	all_ok = pres_004_matching_canonical_pairs() and all_ok
	all_ok = pres_005_feedback_uses_attempt_result() and all_ok
	all_ok = pres_006_completion_event_exactly_once() and all_ok
	all_ok = pres_008_invalid_question_definition_fails_explicitly() and all_ok
	all_ok = pres_012_question_mount_and_ui_visibility_regression() and all_ok
	all_ok = pres_013_bind_existing_session_success() and all_ok
	all_ok = pres_014_bind_existing_session_no_active_session() and all_ok
	all_ok = pres_015_bind_existing_session_mismatched_session_id() and all_ok
	all_ok = pres_016_bind_existing_session_invalid_question_payload() and all_ok
	all_ok = pres_017_bind_existing_session_duplicate_bind_after_completion() and all_ok
	all_ok = pres_018_bind_existing_session_mismatched_question_id() and all_ok
	return all_ok

static func pres_001_multiple_choice_render_and_submit() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request: Dictionary = _request("multiple_choice")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-001] FAIL: start_question failed: ", start_res)
		return false

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null:
		print("[PRES-001] FAIL: MultipleChoiceView was not instantiated")
		return false

	if not mc_view.select_option("opt_a"):
		print("[PRES-001] FAIL: select_option opt_a failed")
		return false

	var payload: Dictionary = panel.get_current_interaction_payload()
	if String(payload.get("selected_option_id", "")) != "opt_a":
		print("[PRES-001] FAIL: canonical payload selected_option_id != opt_a")
		return false

	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)) or not bool((submit_res["result"] as Dictionary).get("is_correct", false)):
		print("[PRES-001] FAIL: submit_answer for correct option failed: ", submit_res)
		return false

	print("[PRES-001] PASS")
	return true

static func pres_002_input_render_and_submit() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request: Dictionary = _request("input")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-002] FAIL: start_question failed")
		return false

	var inp_view: InputView = panel.get_active_interaction_view() as InputView
	if inp_view == null:
		print("[PRES-002] FAIL: InputView was not instantiated")
		return false

	inp_view.set_input_value("4")
	var payload: Dictionary = panel.get_current_interaction_payload()
	if not payload.has("value") or int(payload["value"]) != 4:
		print("[PRES-002] FAIL: Input payload value != 4")
		return false

	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)) or not bool((submit_res["result"] as Dictionary).get("is_correct", false)):
		print("[PRES-002] FAIL: submit_answer for input failed: ", submit_res)
		return false

	print("[PRES-002] PASS")
	return true

static func pres_003_drag_drop_canonical_mappings() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request: Dictionary = _request("drag_drop")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-003] FAIL: start_question failed")
		return false

	var dd_view: DragDropView = panel.get_active_interaction_view() as DragDropView
	if dd_view == null:
		print("[PRES-003] FAIL: DragDropView was not instantiated")
		return false

	dd_view.place_item("item_a", "target_a")
	dd_view.place_item("item_b", "target_b")

	var payload: Dictionary = panel.get_current_interaction_payload()
	if not payload.has("placements") or not (payload["placements"] is Array):
		print("[PRES-003] FAIL: drag_drop payload missing canonical placements array")
		return false

	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)) or not bool((submit_res["result"] as Dictionary).get("is_correct", false)):
		print("[PRES-003] FAIL: submit_answer for drag_drop failed: ", submit_res)
		return false

	print("[PRES-003] PASS")
	return true

static func pres_004_matching_canonical_pairs() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request: Dictionary = _request("matching")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-004] FAIL: start_question failed")
		return false

	var mat_view: MatchingView = panel.get_active_interaction_view() as MatchingView
	if mat_view == null:
		print("[PRES-004] FAIL: MatchingView was not instantiated")
		return false

	mat_view.add_pair("left_a", "right_a")
	mat_view.add_pair("left_b", "right_b")

	var payload: Dictionary = panel.get_current_interaction_payload()
	if not payload.has("pairs") or not (payload["pairs"] is Array):
		print("[PRES-004] FAIL: matching payload missing canonical pairs array")
		return false

	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)) or not bool((submit_res["result"] as Dictionary).get("is_correct", false)):
		print("[PRES-004] FAIL: submit_answer for matching failed: ", submit_res)
		return false

	print("[PRES-004] PASS")
	return true

static func pres_005_feedback_uses_attempt_result() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	controller.start_question(_request("multiple_choice"))
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_b") # Wrong option

	var submit_res: Dictionary = controller.submit_answer(panel.get_current_interaction_payload())
	if not bool(submit_res.get("success", false)):
		print("[PRES-005] FAIL: submit_answer failed")
		return false

	if not panel.has_feedback() or panel.is_correct() != false or panel.get_feedback_text().is_empty():
		print("[PRES-005] FAIL: QuestionPanel feedback was not updated from AttemptResult")
		return false

	print("[PRES-005] PASS")
	return true

static func pres_006_completion_event_exactly_once() -> bool:
	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var panel: QuestionPanel = QuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var tracker: Array = [0]
	controller.question_completed.connect(func(_res: Dictionary) -> void: tracker[0] = int(tracker[0]) + 1)

	controller.start_question(_request("multiple_choice"))
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_a")

	var payload: Dictionary = panel.get_current_interaction_payload()
	var first_submit: Dictionary = controller.submit_answer(payload)
	var second_submit: Dictionary = controller.submit_answer(payload)

	if not bool(first_submit.get("success", false)):
		print("[PRES-006] FAIL: First submission failed")
		return false

	if bool(second_submit.get("success", false)) or String(second_submit.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION_SESSION:
		print("[PRES-006] FAIL: Second submission was not rejected")
		return false

	if int(tracker[0]) != 1:
		print("[PRES-006] FAIL: question_completed emitted %d times (expected 1)" % int(tracker[0]))
		return false

	print("[PRES-006] PASS")
	return true

static func pres_008_invalid_question_definition_fails_explicitly() -> bool:
	var panel: QuestionPanel = QuestionPanel.new()
	var malformed_question: Dictionary = {
		"question_id": "q_invalid",
		"interaction_type": "multiple_choice",
		"prompt": "Malformed question",
		"interaction_payload": {} # Missing options
	}
	var setup_ok: bool = panel.setup_question(malformed_question)
	if setup_ok:
		print("[PRES-008] FAIL: Malformed question_view setup succeeded unexpectedly")
		return false

	# Test answer_spec leak rejection
	var leaking_question: Dictionary = malformed_question.duplicate(true)
	leaking_question["interaction_payload"] = {"options": [{"option_id": "a", "text": "A"}]}
	leaking_question["answer_spec"] = {"correct_option_id": "a"}
	var leak_ok: bool = panel.setup_question(leaking_question)
	if leak_ok:
		print("[PRES-008] FAIL: QuestionPanel accepted leaking answer_spec")
		return false

	print("[PRES-008] PASS")
	return true

static func pres_012_question_mount_and_ui_visibility_regression() -> bool:
	# 1. Verify production scene resource exists and instantiates cleanly
	var scene_res: Resource = load("res://src/ui/question/question_panel.tscn")
	if not (scene_res is PackedScene):
		print("[PRES-012] FAIL: res://src/ui/question/question_panel.tscn resource missing or not a PackedScene")
		return false

	var panel: QuestionPanel = (scene_res as PackedScene).instantiate() as QuestionPanel
	if panel == null:
		print("[PRES-012] FAIL: Failed to instantiate QuestionPanel from res://src/ui/question/question_panel.tscn")
		return false

	var service: QuestionService = QuestionService.new(_synthetic_catalog())
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	# 2. Mount inside a realistic QuestionHostContainer at standard project viewport size (1280x720)
	var host: MarginContainer = MarginContainer.new()
	host.name = "QuestionHostContainer"
	host.custom_minimum_size = Vector2(1248, 661)
	host.size = Vector2(1248, 661)
	host.position = Vector2(16, 43)
	host.add_child(panel)

	var added_to_root: bool = false
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(host)
		added_to_root = true

	var request: Dictionary = _request("multiple_choice")
	var start_res: Dictionary = controller.start_question(request)
	if not bool(start_res.get("success", false)):
		print("[PRES-012] FAIL: start_question failed: ", start_res)
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	if not controller.has_active_session():
		print("[PRES-012] FAIL: QuestionPresentationController does not own active session")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	var host_rect: Rect2 = host.get_global_rect()
	if host_rect.size.x <= 0 or host_rect.size.y <= 0:
		host_rect = Rect2(Vector2(16, 43), Vector2(1248, 661))

	# Verify Prompt Label
	var prompt_label: Label = panel.get_node_or_null("MainVBox/PromptLabel") as Label
	if prompt_label == null:
		print("[PRES-012] FAIL: PromptLabel node does not exist in QuestionPanel scene tree")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	if prompt_label.text.is_empty():
		print("[PRES-012] FAIL: PromptLabel text is empty")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	if not prompt_label.visible:
		print("[PRES-012] FAIL: PromptLabel is not visible")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	var prompt_size: Vector2 = prompt_label.size if (prompt_label.size.x > 0 and prompt_label.size.y > 0) else prompt_label.get_minimum_size()
	var prompt_rect: Rect2 = Rect2(prompt_label.global_position, prompt_size)
	var prompt_inter: Rect2 = prompt_rect.intersection(host_rect)
	if prompt_inter.size.x <= 0 or prompt_inter.size.y <= 0:
		print("[PRES-012] FAIL: PromptLabel viewport intersection area is zero: ", prompt_rect)
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	# Verify Interaction View
	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null:
		print("[PRES-012] FAIL: MultipleChoiceView does not exist on QuestionPanel")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	if mc_view.get_parent() == null:
		print("[PRES-012] FAIL: MultipleChoiceView interaction node is not mounted under parent container")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	if not mc_view.visible:
		print("[PRES-012] FAIL: MultipleChoiceView interaction node is not visible")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	var mc_size: Vector2 = mc_view.size if (mc_view.size.x > 0 and mc_view.size.y > 0) else mc_view.custom_minimum_size
	var mc_rect: Rect2 = Rect2(mc_view.global_position, mc_size)
	var mc_inter: Rect2 = mc_rect.intersection(host_rect)
	if mc_inter.size.x <= 0 or mc_inter.size.y <= 0:
		print("[PRES-012] FAIL: MultipleChoiceView viewport intersection area is zero: ", mc_rect)
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	# Verify Option Buttons for all options returned in payload
	var opt_a_btn: Button = mc_view.get_node_or_null("OptionsVBox/OptionButton_opt_a") as Button
	var opt_b_btn: Button = mc_view.get_node_or_null("OptionsVBox/OptionButton_opt_b") as Button

	if opt_a_btn == null or opt_b_btn == null:
		print("[PRES-012] FAIL: Option buttons opt_a or opt_b not created inside MultipleChoiceView")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	if not opt_a_btn.visible or not opt_b_btn.visible:
		print("[PRES-012] FAIL: Option buttons opt_a or opt_b are not visible")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	if opt_a_btn.disabled or opt_b_btn.disabled:
		print("[PRES-012] FAIL: Option buttons are disabled")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	if opt_a_btn.mouse_filter == Control.MOUSE_FILTER_IGNORE or opt_b_btn.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		print("[PRES-012] FAIL: Option buttons ignore mouse input")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	var opt_a_size: Vector2 = opt_a_btn.size if (opt_a_btn.size.x > 0 and opt_a_btn.size.y > 0) else opt_a_btn.custom_minimum_size
	var opt_b_size: Vector2 = opt_b_btn.size if (opt_b_btn.size.x > 0 and opt_b_btn.size.y > 0) else opt_b_btn.custom_minimum_size
	var opt_a_inter: Rect2 = Rect2(opt_a_btn.global_position, opt_a_size).intersection(host_rect)
	var opt_b_inter: Rect2 = Rect2(opt_b_btn.global_position, opt_b_size).intersection(host_rect)
	if opt_a_inter.size.x <= 0 or opt_a_inter.size.y <= 0 or opt_b_inter.size.x <= 0 or opt_b_inter.size.y <= 0:
		print("[PRES-012] FAIL: Option button viewport intersection area is zero")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	# Simulate option selection via button press
	opt_a_btn.pressed.emit()
	var payload: Dictionary = panel.get_current_interaction_payload()
	if String(payload.get("selected_option_id", "")) != "opt_a":
		print("[PRES-012] FAIL: Option selection via button press did not update payload")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	# Verify Submit Button
	var submit_btn: Button = panel.get_node_or_null("MainVBox/SubmitButton") as Button
	if submit_btn == null or not submit_btn.visible:
		print("[PRES-012] FAIL: QuestionPanel does not have a visible SubmitButton path")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	var submit_size: Vector2 = submit_btn.size if (submit_btn.size.x > 0 and submit_btn.size.y > 0) else submit_btn.custom_minimum_size
	var submit_inter: Rect2 = Rect2(submit_btn.global_position, submit_size).intersection(host_rect)
	if submit_inter.size.x <= 0 or submit_inter.size.y <= 0:
		print("[PRES-012] FAIL: SubmitButton viewport intersection area is zero")
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	# Simulate Submit press
	var submit_res: Dictionary = controller.submit_answer(payload)
	if not bool(submit_res.get("success", false)):
		print("[PRES-012] FAIL: Submit press failed: ", submit_res)
		if added_to_root: tree.root.remove_child(host)
		host.free()
		return false

	if added_to_root:
		tree.root.remove_child(host)
	host.free()

	print("[PRES-012] PASS")
	return true

# --- TEST SPY HELPERS ---
class CountingQuestionService extends QuestionService:
	var request_question_count: int = 0
	func _init(p_cat: ValidatedCatalog) -> void:
		super._init(p_cat)
	func request_question(req: Dictionary, rec: Dictionary = {}) -> Dictionary:
		request_question_count += 1
		return super.request_question(req, rec)

class CountingQuestionPanel extends QuestionPanel:
	var setup_question_count: int = 0
	func setup_question(q_view: Dictionary) -> bool:
		setup_question_count += 1
		return super.setup_question(q_view)

static func pres_013_bind_existing_session_success() -> bool:
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: CountingQuestionService = CountingQuestionService.new(catalog)
	var panel: CountingQuestionPanel = CountingQuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var request_count_before_creation: int = service.request_question_count
	if request_count_before_creation != 0:
		print("[PRES-013] FAIL: request_question_count before session creation != 0")
		return false

	# Simulate FLOW creating an active session
	var flow_req: Dictionary = _request("multiple_choice")
	var qs_res: Dictionary = service.request_question(flow_req)
	if not bool(qs_res.get("success", false)):
		print("[PRES-013] FAIL: FLOW-like request_question failed: ", qs_res)
		return false

	var request_count_after_creation: int = service.request_question_count
	if request_count_after_creation != 1:
		print("[PRES-013] FAIL: request_question_count after session creation != 1")
		return false

	var session: Dictionary = qs_res.get("session", {}) as Dictionary
	var question: Dictionary = qs_res.get("question", {}) as Dictionary

	var completion_count: Array = [0]
	controller.question_completed.connect(func(_res: Dictionary) -> void: completion_count[0] += 1)

	var request_count_before_handoff: int = service.request_question_count
	var bind_res: Dictionary = controller.bind_existing_session(session, question)
	var request_count_after_handoff: int = service.request_question_count
	var handoff_contribution: int = request_count_after_handoff - request_count_before_handoff

	if handoff_contribution != 0:
		print("[PRES-013] FAIL: handoff request_question contribution != 0 (got %d)" % handoff_contribution)
		return false

	if not bool(bind_res.get("success", false)):
		print("[PRES-013] FAIL: bind_existing_session returned failure: ", bind_res)
		return false

	if not controller.has_active_session():
		print("[PRES-013] FAIL: controller has_active_session == false after bind")
		return false

	if controller.get_active_session_id() != String(session["session_id"]):
		print("[PRES-013] FAIL: controller session ID mismatch")
		return false

	if panel.setup_question_count != 1:
		print("[PRES-013] FAIL: QuestionPanel setup_question_count != 1 (got %d)" % panel.setup_question_count)
		return false

	if panel.get_prompt_text().is_empty():
		print("[PRES-013] FAIL: panel prompt_text is empty")
		return false

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null:
		print("[PRES-013] FAIL: MultipleChoiceView null after bind")
		return false

	mc_view.select_option("opt_a")
	var payload: Dictionary = panel.get_current_interaction_payload()
	var submit_res: Dictionary = controller.submit_answer(payload)

	if not bool(submit_res.get("success", false)):
		print("[PRES-013] FAIL: submit_answer failed: ", submit_res)
		return false

	if completion_count[0] != 1:
		print("[PRES-013] FAIL: question_completed emitted %d times (expected 1)" % completion_count[0])
		return false

	print("[PRES-013] PASS")
	return true

static func pres_014_bind_existing_session_no_active_session() -> bool:
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: CountingQuestionService = CountingQuestionService.new(catalog)
	var panel: CountingQuestionPanel = CountingQuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var fake_session: Dictionary = {"session_id": "sess_fake_001", "question_id": "q_mc"}
	var fake_question: Dictionary = {"question_id": "q_mc", "interaction_type": "multiple_choice", "prompt": "Prompt", "interaction_payload": {"options": [{"option_id": "opt_a", "text": "A"}]}}

	var initial_requests: int = service.request_question_count
	var bind_res: Dictionary = controller.bind_existing_session(fake_session, fake_question)
	var end_requests: int = service.request_question_count

	if bool(bind_res.get("success", false)):
		print("[PRES-014] FAIL: bind_existing_session succeeded unexpectedly without active session")
		return false

	if String(bind_res.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION_SESSION:
		print("[PRES-014] FAIL: unexpected error code: ", bind_res.get("error_code", ""))
		return false

	if (end_requests - initial_requests) != 0:
		print("[PRES-014] FAIL: request_question called during rejection")
		return false

	if panel.setup_question_count != 0:
		print("[PRES-014] FAIL: setup_question called during rejection")
		return false

	print("[PRES-014] PASS")
	return true

static func pres_015_bind_existing_session_mismatched_session_id() -> bool:
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: CountingQuestionService = CountingQuestionService.new(catalog)
	var panel: CountingQuestionPanel = CountingQuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	# Create real session
	var qs_res: Dictionary = service.request_question(_request("multiple_choice"))
	var real_question: Dictionary = qs_res.get("question", {}) as Dictionary

	var mismatched_session: Dictionary = {"session_id": "session_mismatched_999", "question_id": "q_mc"}

	var requests_before: int = service.request_question_count
	var bind_res: Dictionary = controller.bind_existing_session(mismatched_session, real_question)
	var requests_after: int = service.request_question_count

	if bool(bind_res.get("success", false)):
		print("[PRES-015] FAIL: bind_existing_session succeeded with mismatched session ID")
		return false

	if String(bind_res.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION_SESSION:
		print("[PRES-015] FAIL: unexpected error_code: ", bind_res.get("error_code", ""))
		return false

	if (requests_after - requests_before) != 0:
		print("[PRES-015] FAIL: request_question called during rejection")
		return false

	if panel.setup_question_count != 0:
		print("[PRES-015] FAIL: setup_question called during rejection")
		return false

	print("[PRES-015] PASS")
	return true

static func pres_016_bind_existing_session_invalid_question_payload() -> bool:
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: CountingQuestionService = CountingQuestionService.new(catalog)
	var panel: CountingQuestionPanel = CountingQuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	# Create real session
	var qs_res: Dictionary = service.request_question(_request("multiple_choice"))
	var real_session: Dictionary = qs_res.get("session", {}) as Dictionary

	# 1. Missing fields
	var invalid_q1: Dictionary = {"question_id": "q_mc"}
	var bind_res1: Dictionary = controller.bind_existing_session(real_session, invalid_q1)
	if bool(bind_res1.get("success", false)) or String(bind_res1.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION:
		print("[PRES-016] FAIL: missing fields check failed: ", bind_res1)
		return false

	# 2. Leaking answer_spec
	var invalid_q2: Dictionary = (qs_res.get("question", {}) as Dictionary).duplicate(true)
	invalid_q2["answer_spec"] = {"correct_option_id": "opt_a"}
	var bind_res2: Dictionary = controller.bind_existing_session(real_session, invalid_q2)
	if bool(bind_res2.get("success", false)) or String(bind_res2.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION:
		print("[PRES-016] FAIL: answer_spec leak check failed: ", bind_res2)
		return false

	if panel.setup_question_count != 0:
		print("[PRES-016] FAIL: setup_question called during invalid question rejection")
		return false

	print("[PRES-016] PASS")
	return true

static func pres_017_bind_existing_session_duplicate_bind_after_completion() -> bool:
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: CountingQuestionService = CountingQuestionService.new(catalog)
	var panel: CountingQuestionPanel = CountingQuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	var qs_res: Dictionary = service.request_question(_request("multiple_choice"))
	var session: Dictionary = qs_res.get("session", {}) as Dictionary
	var question: Dictionary = qs_res.get("question", {}) as Dictionary

	var bind_res: Dictionary = controller.bind_existing_session(session, question)
	if not bool(bind_res.get("success", false)):
		print("[PRES-017] FAIL: initial bind failed")
		return false

	var mc_view: MultipleChoiceView = panel.get_active_interaction_view() as MultipleChoiceView
	mc_view.select_option("opt_a")
	controller.submit_answer(panel.get_current_interaction_payload())

	# Now active session in QuestionService has completed and cleared
	var requests_before: int = service.request_question_count
	var reb_res: Dictionary = controller.bind_existing_session(session, question)
	var requests_after: int = service.request_question_count

	if bool(reb_res.get("success", false)):
		print("[PRES-017] FAIL: bind after completion succeeded unexpectedly")
		return false

	if String(reb_res.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION_SESSION:
		print("[PRES-017] FAIL: unexpected error_code on completed re-bind: ", reb_res.get("error_code", ""))
		return false

	if (requests_after - requests_before) != 0:
		print("[PRES-017] FAIL: request_question called during duplicate bind rejection")
		return false

	print("[PRES-017] PASS")
	return true

static func pres_018_bind_existing_session_mismatched_question_id() -> bool:
	var catalog: ValidatedCatalog = _synthetic_catalog()
	var service: CountingQuestionService = CountingQuestionService.new(catalog)
	var panel: CountingQuestionPanel = CountingQuestionPanel.new()
	var controller: QuestionPresentationController = QuestionPresentationController.new(service, panel)

	# Create real session (creates active session with question_id = "q_mc")
	var qs_res: Dictionary = service.request_question(_request("multiple_choice"))
	var real_session: Dictionary = qs_res.get("session", {}) as Dictionary

	# Construct structurally valid question definition with a DIFFERENT question_id
	var mismatched_question: Dictionary = {
		"schema_version": 1,
		"question_id": "q_different_999",
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "sample_space",
		"learning_objective": "Test objective",
		"difficulty": 2,
		"interaction_type": "multiple_choice",
		"prompt": "Mismatched question prompt",
		"interaction_payload": {"options": [{"option_id": "opt_a", "text": "A"}]}
	}

	var requests_before: int = service.request_question_count
	var completion_count: Array = [0]
	controller.question_completed.connect(func(_res: Dictionary) -> void: completion_count[0] += 1)

	var bind_res: Dictionary = controller.bind_existing_session(real_session, mismatched_question)
	var requests_after: int = service.request_question_count

	if bool(bind_res.get("success", false)):
		print("[PRES-018] FAIL: bind_existing_session succeeded with mismatched question_id")
		return false

	if String(bind_res.get("error_code", "")) != QuestionErrorCodes.INVALID_QUESTION:
		print("[PRES-018] FAIL: unexpected error_code: ", bind_res.get("error_code", ""))
		return false

	if (requests_after - requests_before) != 0:
		print("[PRES-018] FAIL: request_question called during rejection")
		return false

	if panel.setup_question_count != 0:
		print("[PRES-018] FAIL: setup_question called during rejection")
		return false

	if not service.has_active_session() or String(service.get_active_session().get("session_id", "")) != String(real_session["session_id"]):
		print("[PRES-018] FAIL: active QuestionService session changed after rejection")
		return false

	if controller.has_active_session():
		print("[PRES-018] FAIL: controller reports active session after rejection")
		return false

	if completion_count[0] != 0:
		print("[PRES-018] FAIL: question_completed emitted during rejection")
		return false

	print("[PRES-018] PASS")
	return true

static func _request(interaction_type: String) -> Dictionary:
	return {
		"request_id": "req_pres_test",
		"stage_id": "stage_01_01",
		"scope": {
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"subtopic_ids": ["sample_space"],
			"difficulty_min": 1,
			"difficulty_max": 5,
			"interaction_types": [interaction_type]
		},
		"context": "practice",
		"preferred_difficulty": 2,
		"exclude_question_ids": []
	}

static func _synthetic_catalog() -> ValidatedCatalog:
	var config: Dictionary = {
		"performance_grade_thresholds": {
			"a_max_time_ratio": 0.75,
			"b_max_time_ratio": 1.25
		}
	}
	var stage_scope: Dictionary = {
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_ids": [],
		"difficulty_min": 1,
		"difficulty_max": 5,
		"interaction_types": []
	}
	var stages: Dictionary = {"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01", "practice_id": "practice_01_01", "question_scope": stage_scope}}
	var practices: Dictionary = {"practice_01_01": {"practice_id": "practice_01_01", "question_scope": stage_scope}}

	var mc_q: Dictionary = _base_question("q_mc", "multiple_choice")
	mc_q["interaction_payload"] = {"options": [{"option_id": "opt_a", "text": "A"}, {"option_id": "opt_b", "text": "B"}]}
	mc_q["answer_spec"] = {"correct_option_id": "opt_a"}

	var inp_q: Dictionary = _base_question("q_inp", "input")
	inp_q["interaction_payload"] = {"input_type": "integer"}
	inp_q["answer_spec"] = {"accepted_values": [4]}

	var dd_q: Dictionary = _base_question("q_dd", "drag_drop")
	dd_q["interaction_payload"] = {
		"items": [{"item_id": "item_a", "text": "A"}, {"item_id": "item_b", "text": "B"}],
		"targets": [{"target_id": "target_a", "label": "A"}, {"target_id": "target_b", "label": "B"}]
	}
	dd_q["answer_spec"] = {"mappings": [{"item_id": "item_a", "target_id": "target_a"}, {"item_id": "item_b", "target_id": "target_b"}]}

	var mat_q: Dictionary = _base_question("q_mat", "matching")
	mat_q["interaction_payload"] = {
		"left_items": [{"item_id": "left_a", "text": "A"}, {"item_id": "left_b", "text": "B"}],
		"right_items": [{"item_id": "right_a", "text": "A"}, {"item_id": "right_b", "text": "B"}]
	}
	mat_q["answer_spec"] = {"pairs": [{"left_id": "left_a", "right_id": "right_a"}, {"left_id": "left_b", "right_id": "right_b"}]}

	var questions: Dictionary = {"q_mc": mc_q, "q_inp": inp_q, "q_dd": dd_q, "q_mat": mat_q}
	return ValidatedCatalog.new(config, {}, stages, {}, {}, practices, questions, {}, {}, {})

static func _base_question(qid: String, interaction_type: String) -> Dictionary:
	return {
		"schema_version": 1,
		"question_id": qid,
		"dungeon_id": "dungeon_01",
		"topic_id": "trial_sample_event",
		"subtopic_id": "sample_space",
		"learning_objective": "Test objective",
		"difficulty": 2,
		"interaction_type": interaction_type,
		"prompt": "Test prompt",
		"explanation": "Test explanation",
		"hints": [],
		"estimated_time_seconds": 20,
		"tags": [],
		"allowed_contexts": ["practice", "combat"]
	}
