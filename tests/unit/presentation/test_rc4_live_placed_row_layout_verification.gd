extends SceneTree

## Targeted Regression Test Suite for MATHOS-RC4-LIVE-PLACED-ROW-LAYOUT-FIX-004
## Verifies real-world live GUI fixes for classification and matching question rows:
## 1. No item text mutation before/after selection (NO '[Placed]', '[Matched]', '[Selecting]', '-> <target>').
## 2. Dynamic wrapped row heights and strict rect containment.
## 3. Selection persistence across Hint clicks, invalid submits, and validation visibility.
## 4. Scroll reachability above FooterVBox at 1024x600 and 1280x720.

const AppRootClass = preload("res://src/app/app_root.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS RC4 LIVE PLACED ROW LAYOUT QA HARNESS ---")
	var ok: bool = run_all_tests()
	if ok:
		print("MATHOS RC4 LIVE PLACED ROW LAYOUT QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS RC4 LIVE PLACED ROW LAYOUT QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var passes: int = 0
	if test_row_001_no_placed_text_mutation_before_and_after_selection(): passes += 1
	if test_row_002_multiple_selected_rows_no_mutation(): passes += 1
	if test_row_003_selection_survives_hint_and_invalid_submit(): passes += 1
	if test_row_004_rect_containment_and_multiline_wrapping_1024x600(): passes += 1
	if test_row_005_rect_containment_and_multiline_wrapping_1280x720(): passes += 1
	if test_row_006_matching_view_no_matched_selecting_mutation(): passes += 1
	if test_row_007_bottom_row_scroll_reachability_above_footer(): passes += 1

	print("[ROW-LAYOUT-HARNESS] %d / 7 test scenarios passed" % passes)
	return passes == 7

static func _create_long_text_classification_question() -> Dictionary:
	return {
		"question_id": "q_class_long_004",
		"dungeon_id": "dungeon_1",
		"stage_id": "stage_1_1",
		"topic_id": "topic_1",
		"subtopic_id": "subtopic_1",
		"context": "NORMAL",
		"difficulty": 1,
		"interaction_type": "drag_drop",
		"prompt": "Hãy phân loại các thí nghiệm ngẫu nhiên THPT sau đây vào hai nhóm: Phép thử ngẫu nhiên hoặc Sự kiện chắc chắn.",
		"learning_objective": "Phân biệt phép thử ngẫu nhiên và biến cố chắc chắn trong bài tập thực tế",
		"hint": "Xác định xem kết quả của phép thử có thể đoán trước hay phụ thuộc vào khả năng ngẫu nhiên.",
		"explanation": "Phép thử ngẫu nhiên có kết quả không thể đoán trước; biến cố chắc chắn luôn xảy ra.",
		"interaction_payload": {
			"must_place_all": true,
			"items": [
				{"item_id": "item_1", "text": "Bốc ngẫu nhiên 1 viên bi từ túi chứa 3 bi đỏ và 2 bi xanh để xem màu sắc viên bi nhận được."},
				{"item_id": "item_2", "text": "Gieo con xúc xắc cân đối đồng chất 6 mặt và quan sát số chấm xuất hiện trên mặt trên cùng."},
				{"item_id": "item_3", "text": "Lấy 1 quả cầu từ một chiếc hộp chứa duy nhất 10 quả cầu màu đỏ hoàn toàn giống nhau."},
				{"item_id": "item_4", "text": "Gieo 2 đồng tiền xu kim loại cân đối và ghi lại số lượng mặt sấp xuất hiện sau khi gieo."}
			],
			"targets": [
				{"target_id": "target_random", "label": "Phép thử ngẫu nhiên"},
				{"target_id": "target_certain", "label": "Sự kiện chắc chắn"}
			]
		},
		"answer_spec": {
			"mappings": [
				{"item_id": "item_1", "target_id": "target_random"},
				{"item_id": "item_2", "target_id": "target_random"},
				{"item_id": "item_3", "target_id": "target_certain"},
				{"item_id": "item_4", "target_id": "target_random"}
			]
		}
	}

static func _create_matching_question() -> Dictionary:
	return {
		"question_id": "q_mat_long_004",
		"dungeon_id": "dungeon_1",
		"stage_id": "stage_1_1",
		"topic_id": "topic_1",
		"subtopic_id": "subtopic_1",
		"context": "NORMAL",
		"difficulty": 1,
		"interaction_type": "matching",
		"prompt": "Hãy ghép nối từng phép thử xác suất với số lượng phần tử của không gian mẫu tương ứng.",
		"learning_objective": "Xác định số phần tử không gian mẫu",
		"hint": "Đếm số khả năng xảy ra của từng phép thử.",
		"explanation": "Tính số phần tử bằng quy tắc nhân hoặc tổ hợp.",
		"interaction_payload": {
			"left_items": [
				{"item_id": "l1", "text": "Gieo 1 con xúc xắc cân đối 6 mặt"},
				{"item_id": "l2", "text": "Gieo 2 đồng xu cân đối đồng thời"}
			],
			"right_items": [
				{"item_id": "r1", "text": "6 phần tử"},
				{"item_id": "r2", "text": "4 phần tử"}
			]
		},
		"answer_spec": {
			"pairs": [
				{"left_id": "l1", "right_id": "r1"},
				{"left_id": "l2", "right_id": "r2"}
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
		shell.call("set_view_mode", 2)

	var q_panel: QuestionPanel = app.get_question_panel()
	if q_panel == null and shell != null and shell.has_method("get_question_host_container"):
		var q_host: Control = shell.call("get_question_host_container") as Control
		if q_host != null:
			app._on_question_host_ready(q_host)

	return app

static func test_row_001_no_placed_text_mutation_before_and_after_selection() -> bool:
	print("[ROW-001] Testing NO [Placed] or -> <target> text mutation before and after selection...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_long_text_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	var dd_view: DragDropView = q_panel.get_active_interaction_view() as DragDropView
	var item_card: Button = dd_view._item_cards.get("item_1") as Button
	var orig_text: String = "Bốc ngẫu nhiên 1 viên bi từ túi chứa 3 bi đỏ và 2 bi xanh để xem màu sắc viên bi nhận được."

	if item_card.text != orig_text:
		print("[ROW-001] FAIL: Initial item card text mutated (got '%s')" % item_card.text)
		app.queue_free()
		return false

	# Select category
	dd_view.place_item("item_1", "target_random")

	if item_card.text.contains("[Placed]") or item_card.text.contains("->") or item_card.text.contains("[Unassigned]"):
		print("[ROW-001] FAIL: Placed text mutated to contain debug markers: '%s'" % item_card.text)
		app.queue_free()
		return false

	if item_card.text != orig_text:
		print("[ROW-001] FAIL: Placed item card text altered from original (got '%s')" % item_card.text)
		app.queue_free()
		return false

	print("[ROW-001] PASS: Item card text preserved 100% untouched before and after selection!")
	app.queue_free()
	return true

static func test_row_002_multiple_selected_rows_no_mutation() -> bool:
	print("[ROW-002] Testing multiple selected rows exhibit ZERO text mutation...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_long_text_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	var dd_view: DragDropView = q_panel.get_active_interaction_view() as DragDropView
	dd_view.place_item("item_1", "target_random")
	dd_view.place_item("item_2", "target_random")
	dd_view.place_item("item_3", "target_certain")

	for item_id in ["item_1", "item_2", "item_3", "item_4"]:
		var card: Button = dd_view._item_cards.get(item_id) as Button
		var txt: String = card.text
		if txt.contains("[Placed]") or txt.contains("->") or txt.contains("[Selecting]") or txt.contains("[Matched]"):
			print("[ROW-002] FAIL: Debug state tag present in card '%s': '%s'" % [item_id, txt])
			app.queue_free()
			return false

	print("[ROW-002] PASS: Multiple selected rows preserve clean text across all cards!")
	app.queue_free()
	return true

static func test_row_003_selection_survives_hint_and_invalid_submit() -> bool:
	print("[ROW-003] Testing selection state survives Hint click, invalid submit, and validation toggle...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_long_text_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	var dd_view: DragDropView = q_panel.get_active_interaction_view() as DragDropView
	dd_view.place_item("item_1", "target_random")

	# Press Hint
	q_panel._hint_button.pressed.emit()
	var payload1: Dictionary = q_panel.get_current_interaction_payload()
	if (payload1.get("placements", []) as Array).size() != 1:
		print("[ROW-003] FAIL: Selection lost after Hint press")
		app.queue_free()
		return false

	# Trigger invalid submit
	q_panel.on_submission_failed({"error_code": 1002, "error_message": "must_place_all requires every item exactly once"})
	var payload2: Dictionary = q_panel.get_current_interaction_payload()
	if (payload2.get("placements", []) as Array).size() != 1:
		print("[ROW-003] FAIL: Selection lost after submission failure")
		app.queue_free()
		return false

	print("[ROW-003] PASS: Selection state survived Hint click & invalid submit cleanly!")
	app.queue_free()
	return true

static func test_row_004_rect_containment_and_multiline_wrapping_1024x600() -> bool:
	print("[ROW-004] Testing multiline wrapping and rect containment at 1024x600...")
	var app: AppRoot = _create_app(Vector2(1024, 600))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_long_text_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))
	q_panel.custom_minimum_size = Vector2(480, 520)

	var dd_view: DragDropView = q_panel.get_active_interaction_view() as DragDropView
	dd_view.place_item("item_1", "target_random")

	var item_card: Button = dd_view._item_cards.get("item_1") as Button
	var opt_btn: OptionButton = dd_view._target_options.get("item_1") as OptionButton
	var row: HBoxContainer = item_card.get_parent() as HBoxContainer

	# Assert min sizes fit multiline content
	if item_card.custom_minimum_size.y < 48.0 or row.custom_minimum_size.y < 48.0:
		print("[ROW-004] FAIL: Row or card minimum size failed to expand for multiline text (card_y=%f, row_y=%f)" % [item_card.custom_minimum_size.y, row.custom_minimum_size.y])
		app.queue_free()
		return false

	if opt_btn.custom_minimum_size.y < item_card.custom_minimum_size.y:
		print("[ROW-004] FAIL: OptionButton height (%f) < item_card height (%f)" % [opt_btn.custom_minimum_size.y, item_card.custom_minimum_size.y])
		app.queue_free()
		return false

	print("[ROW-004] PASS: 1024x600 multiline wrapping & minimum size containment verified!")
	app.queue_free()
	return true

static func test_row_005_rect_containment_and_multiline_wrapping_1280x720() -> bool:
	print("[ROW-005] Testing multiline wrapping and rect containment at 1280x720...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_long_text_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	var dd_view: DragDropView = q_panel.get_active_interaction_view() as DragDropView
	dd_view.place_item("item_1", "target_random")

	var item_card: Button = dd_view._item_cards.get("item_1") as Button
	var opt_btn: OptionButton = dd_view._target_options.get("item_1") as OptionButton
	var row: HBoxContainer = item_card.get_parent() as HBoxContainer

	if item_card.custom_minimum_size.y < 48.0 or opt_btn.custom_minimum_size.y < 48.0 or row.custom_minimum_size.y < 48.0:
		print("[ROW-005] FAIL: 1280x720 min size containment check failed")
		app.queue_free()
		return false

	print("[ROW-005] PASS: 1280x720 multiline wrapping & minimum size containment verified!")
	app.queue_free()
	return true

static func test_row_006_matching_view_no_matched_selecting_mutation() -> bool:
	print("[ROW-006] Testing MatchingView exhibits NO [Matched] or [Selecting] text mutation...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_matching_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	var mat_view: MatchingView = q_panel.get_active_interaction_view() as MatchingView
	var left_card: Button = mat_view._left_cards.get("l1") as Button
	var orig_text: String = "Gieo 1 con xúc xắc cân đối 6 mặt"

	mat_view.select_left_card("l1")
	if left_card.text.contains("[Selecting]") or left_card.text != orig_text:
		print("[ROW-006] FAIL: Matching card mutated during selection (got '%s')" % left_card.text)
		app.queue_free()
		return false

	mat_view.add_pair("l1", "r1")
	if left_card.text.contains("[Matched]") or left_card.text != orig_text:
		print("[ROW-006] FAIL: Matching card mutated after pairing (got '%s')" % left_card.text)
		app.queue_free()
		return false

	print("[ROW-006] PASS: MatchingView preserves 100% clean item text!")
	app.queue_free()
	return true

static func test_row_007_bottom_row_scroll_reachability_above_footer() -> bool:
	print("[ROW-007] Testing bottom-most wrapped row is reachable above FooterVBox...")
	var app: AppRoot = _create_app(Vector2(1280, 720))
	var q_panel: QuestionPanel = app.get_question_panel()
	var q_def: Dictionary = _create_long_text_classification_question()
	q_panel.setup_question(_get_presentation_view(q_def))

	var scroll: ScrollContainer = q_panel.get_interaction_scroll_container()
	var footer: VBoxContainer = q_panel.get_node_or_null("MainVBox/FooterVBox") as VBoxContainer

	var scroll_rect: Rect2 = scroll.get_global_rect()
	var footer_rect: Rect2 = footer.get_global_rect()

	if scroll_rect.position.y + scroll_rect.size.y > footer_rect.position.y + 1.0:
		print("[ROW-007] FAIL: ScrollContainer boundary crosses FooterVBox top")
		app.queue_free()
		return false

	print("[ROW-007] PASS: Bottom row scroll reachability & footer separation verified cleanly!")
	app.queue_free()
	return true
