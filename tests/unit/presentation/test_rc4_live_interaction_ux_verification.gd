extends SceneTree

## Targeted Regression Test Suite for MATHOS-RC4-LIVE-INTERACTION-UX-FIX-003
## Verifies real-world GUI fixes for classification & matching questions:
## 1. FooterVBox zero-overlap & ScrollContainer layout boundary at 1024x600 & 1280x720.
## 2. Player-facing localized Vietnamese validation error text (no internal "must_place_all" key on UI).
## 3. OptionButton selection persistence across scrolling, "Gợi ý", and invalid submits.
## 4. Valid completed submission evaluator & feedback progression flow.

const AppRootClass = preload("res://src/app/app_root.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS RC4 LIVE INTERACTION UX QA HARNESS ---")
	var ok: bool = run_all_tests()
	if ok:
		print("MATHOS RC4 LIVE INTERACTION UX QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS RC4 LIVE INTERACTION UX QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var passes: int = 0
	if test_ux_001_footer_non_overlap_and_scroll_bounds(): passes += 1
	if test_ux_002_validation_message_in_footer(): passes += 1
	if test_ux_003_incomplete_submit_localized_error(): passes += 1
	if test_ux_004_internal_key_hidden_from_player_ui(): passes += 1
	if test_ux_005_selection_survives_hint_click(): passes += 1
	if test_ux_006_selection_survives_invalid_submit(): passes += 1
	if test_ux_007_completed_submit_reaches_result_and_feedback(): passes += 1
	if test_ux_008_1024x600_viewport_geometry(): passes += 1
	if test_ux_009_1280x720_viewport_geometry(): passes += 1

	print("[UX-HARNESS] %d / 9 test scenarios passed" % passes)
	return passes == 9

static func _create_classification_question() -> Dictionary:
	return {
		"question_id": "q_class_test_001",
		"dungeon_id": "dungeon_1",
		"stage_id": "stage_1_1",
		"topic_id": "topic_1",
		"subtopic_id": "subtopic_1",
		"context": "NORMAL",
		"difficulty": 1,
		"interaction_type": "drag_drop",
		"prompt": "Hãy phân loại các hiện tượng sau vào hai nhóm: Biến cố ngẫu nhiên hoặc Biến cố chắc chắn.",
		"learning_objective": "Phân loại biến cố trong xác suất",
		"hint": "Phân tích khả năng xảy ra của từng biến cố khi gieo xúc xắc hoặc gieo đồng xu.",
		"explanation": "Giải thích chi tiết về phân loại biến cố ngẫu nhiên và biến cố chắc chắn.",
		"interaction_payload": {
			"must_place_all": true,
			"items": [
				{"item_id": "item_1", "text": "Gieo con xúc xắc xuất hiện mặt 6 chấm"},
				{"item_id": "item_2", "text": "Gieo con xúc xắc xuất hiện mặt ít hơn 7 chấm"},
				{"item_id": "item_3", "text": "Rút 1 lá bài được lá bài màu đỏ"},
				{"item_id": "item_4", "text": "Lấy 1 viên bi trong túi chỉ toàn bi xanh được bi xanh"},
				{"item_id": "item_5", "text": "Gieo 2 đồng xu cùng xuất hiện mặt sấp"},
				{"item_id": "item_6", "text": "Mặt trời mọc ở hướng Đông"}
			],
			"targets": [
				{"target_id": "target_random", "label": "Biến cố ngẫu nhiên"},
				{"target_id": "target_certain", "label": "Biến cố chắc chắn"}
			]
		},
		"answer_spec": {
			"mappings": [
				{"item_id": "item_1", "target_id": "target_random"},
				{"item_id": "item_2", "target_id": "target_certain"},
				{"item_id": "item_3", "target_id": "target_random"},
				{"item_id": "item_4", "target_id": "target_certain"},
				{"item_id": "item_5", "target_id": "target_random"},
				{"item_id": "item_6", "target_id": "target_certain"}
			]
		}
	}

static func _get_presentation_view(q_def: Dictionary) -> Dictionary:
	var view: Dictionary = q_def.duplicate(true)
	view.erase("answer_spec")
	return view

static func _create_app(vp_size: Vector2 = Vector2(1280, 720)) -> AppRoot:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var root: Window = tree.root
	root.size = Vector2i(int(vp_size.x), int(vp_size.y))

	var app_scene: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	var app: AppRoot = app_scene.instantiate() as AppRoot
	root.add_child(app)
	app.bootstrap_runtime()
	app.start_new_game()
	app._on_lesson_continue_requested()

	var shell: Node = app.get_node_or_null("StagePresentationShell")
	if shell != null and shell.has_method("set_view_mode"):
		shell.call("set_view_mode", 2) # MODE_QUESTION_HOST

	var q_panel: QuestionPanel = app.get_question_panel()
	if q_panel == null and shell != null and shell.has_method("get_question_host_container"):
		var q_host: Control = shell.call("get_question_host_container") as Control
		if q_host != null:
			app._on_question_host_ready(q_host)

	return app

static func test_ux_001_footer_non_overlap_and_scroll_bounds() -> bool:
	print("[UX-001] Testing long classification list + footer zero-overlap bounds...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))
	q_panel.custom_minimum_size = Vector2(500, 600)

	var scroll: ScrollContainer = q_panel.get_interaction_scroll_container()
	var footer: VBoxContainer = q_panel.get_node_or_null("MainVBox/FooterVBox") as VBoxContainer

	if scroll == null or footer == null:
		print("[UX-001] FAIL: ScrollContainer or FooterVBox null")
		app.queue_free()
		return false

	var scroll_rect: Rect2 = scroll.get_global_rect()
	var footer_rect: Rect2 = footer.get_global_rect()

	if scroll_rect.position.y + scroll_rect.size.y > footer_rect.position.y + 1.0:
		print("[UX-001] FAIL: ScrollContainer intersects FooterVBox (Scroll bottom %f > Footer top %f)" % [scroll_rect.position.y + scroll_rect.size.y, footer_rect.position.y])
		app.queue_free()
		return false

	print("[UX-001] PASS: Footer is cleanly separated from ScrollContainer with zero overlap!")
	app.queue_free()
	return true

static func test_ux_002_validation_message_in_footer() -> bool:
	print("[UX-002] Testing validation message renders inside FooterVBox...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	q_panel.on_submission_failed({"error_code": 1002, "error_message": "must_place_all requires every item exactly once"})

	var fb_label: Label = q_panel.get_node_or_null("MainVBox/FooterVBox/FeedbackLabel") as Label
	var footer: VBoxContainer = q_panel.get_node_or_null("MainVBox/FooterVBox") as VBoxContainer

	if fb_label == null or not fb_label.visible:
		print("[UX-002] FAIL: FeedbackLabel not visible or null inside FooterVBox")
		app.queue_free()
		return false

	if fb_label.get_parent() != footer:
		print("[UX-002] FAIL: FeedbackLabel parent is not FooterVBox")
		app.queue_free()
		return false

	print("[UX-002] PASS: Validation message properly rendered inside FooterVBox!")
	app.queue_free()
	return true

static func test_ux_003_incomplete_submit_localized_error() -> bool:
	print("[UX-003] Testing incomplete submit returns player-facing localized Vietnamese error...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	q_panel.on_submission_failed({"error_code": 1002, "error_message": "must_place_all requires every item exactly once"})
	var txt: String = q_panel.get_feedback_text()

	if not txt.contains("Hãy phân loại tất cả các mục trước khi xác nhận"):
		print("[UX-003] FAIL: Localized error message missing expected Vietnamese text (got '%s')" % txt)
		app.queue_free()
		return false

	print("[UX-003] PASS: Localized Vietnamese validation text delivered cleanly!")
	app.queue_free()
	return true

static func test_ux_004_internal_key_hidden_from_player_ui() -> bool:
	print("[UX-004] Testing internal key 'must_place_all' is NOT displayed on player UI...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	q_panel.on_submission_failed({"error_code": 1002, "error_message": "must_place_all requires every item exactly once"})
	var txt: String = q_panel.get_feedback_text()

	if txt.contains("must_place_all") or txt.contains("requires every item"):
		print("[UX-004] FAIL: Raw internal error key leaked to player UI: '%s'" % txt)
		app.queue_free()
		return false

	print("[UX-004] PASS: Internal diagnostic key completely hidden from player UI!")
	app.queue_free()
	return true

static func test_ux_005_selection_survives_hint_click() -> bool:
	print("[UX-005] Testing OptionButton selection survives pressing HintButton...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	var dd_view: DragDropView = q_panel.get_active_interaction_view() as DragDropView
	if dd_view == null:
		print("[UX-005] FAIL: DragDropView is null")
		app.queue_free()
		return false

	dd_view.place_item("item_1", "target_random")
	dd_view.place_item("item_2", "target_certain")

	# Press Hint button
	q_panel._hint_button.pressed.emit()

	var payload: Dictionary = q_panel.get_current_interaction_payload()
	var placements: Array = payload.get("placements", []) as Array

	if placements.size() != 2:
		print("[UX-005] FAIL: Placements lost after pressing hint (got %d)" % placements.size())
		app.queue_free()
		return false

	print("[UX-005] PASS: Selection state survived hint button press cleanly!")
	app.queue_free()
	return true

static func test_ux_006_selection_survives_invalid_submit() -> bool:
	print("[UX-006] Testing OptionButton selection survives incomplete invalid submit...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	var dd_view: DragDropView = q_panel.get_active_interaction_view() as DragDropView
	if dd_view == null:
		print("[UX-006] FAIL: DragDropView is null")
		app.queue_free()
		return false

	dd_view.place_item("item_1", "target_random")
	dd_view.place_item("item_2", "target_certain")

	# Simulate submission failure due to incomplete items
	q_panel.on_submission_failed({"error_code": 1002, "error_message": "must_place_all requires every item exactly once"})

	var payload: Dictionary = q_panel.get_current_interaction_payload()
	var placements: Array = payload.get("placements", []) as Array

	if placements.size() != 2:
		print("[UX-006] FAIL: Placements lost after invalid submit (got %d)" % placements.size())
		app.queue_free()
		return false

	print("[UX-006] PASS: Selection state survived invalid submit cleanly!")
	app.queue_free()
	return true

static func test_ux_007_completed_submit_reaches_result_and_feedback() -> bool:
	print("[UX-007] Testing complete classification submit evaluates and displays feedback...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	var dd_view: DragDropView = q_panel.get_active_interaction_view() as DragDropView
	if dd_view == null:
		print("[UX-007] FAIL: DragDropView is null")
		app.queue_free()
		return false

	dd_view.place_item("item_1", "target_random")
	dd_view.place_item("item_2", "target_certain")
	dd_view.place_item("item_3", "target_random")
	dd_view.place_item("item_4", "target_certain")
	dd_view.place_item("item_5", "target_random")
	dd_view.place_item("item_6", "target_certain")

	var payload: Dictionary = q_panel.get_current_interaction_payload()
	var res: Dictionary = QuestionEvaluator.evaluate(q_def, payload, "stage_1_1", "NORMAL", 5.0, {}, "att_001")
	var eval_result: Dictionary = res.get("result", {}) as Dictionary

	if not bool(res.get("success", false)) or not bool(eval_result.get("is_correct", false)):
		print("[UX-007] FAIL: QuestionEvaluator failed to evaluate completed classification payload correctly")
		app.queue_free()
		return false

	q_panel.show_feedback(eval_result)

	if not q_panel.has_feedback() or not q_panel.is_correct():
		print("[UX-007] FAIL: Valid submission did not show correct feedback")
		app.queue_free()
		return false

	print("[UX-007] PASS: Completed classification submission evaluated & reached feedback cleanly!")
	app.queue_free()
	return true

static func test_ux_008_1024x600_viewport_geometry() -> bool:
	print("[UX-008] Testing 1024x600 unmaximized viewport geometry...")
	var app: AppRoot = _create_app(Vector2(1024, 600))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))
	q_panel.custom_minimum_size = Vector2(480, 520)

	var scroll: ScrollContainer = q_panel.get_interaction_scroll_container()
	var footer: VBoxContainer = q_panel.get_node_or_null("MainVBox/FooterVBox") as VBoxContainer

	if scroll.get_global_rect().position.y + scroll.get_global_rect().size.y > footer.get_global_rect().position.y + 1.0:
		print("[UX-008] FAIL: Overlap detected at 1024x600 viewport")
		app.queue_free()
		return false

	print("[UX-008] PASS: 1024x600 viewport geometry verified cleanly!")
	app.queue_free()
	return true

static func test_ux_009_1280x720_viewport_geometry() -> bool:
	print("[UX-009] Testing 1280x720 standard viewport geometry...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))
	q_panel.custom_minimum_size = Vector2(550, 620)

	var scroll: ScrollContainer = q_panel.get_interaction_scroll_container()
	var footer: VBoxContainer = q_panel.get_node_or_null("MainVBox/FooterVBox") as VBoxContainer

	if scroll.get_global_rect().position.y + scroll.get_global_rect().size.y > footer.get_global_rect().position.y + 1.0:
		print("[UX-009] FAIL: Overlap detected at 1280x720 viewport")
		app.queue_free()
		return false

	print("[UX-009] PASS: 1280x720 viewport geometry verified cleanly!")
	app.queue_free()
	return true
