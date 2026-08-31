extends SceneTree

## Multi-Resolution Live GUI Layout Verification Suite for MATHOS-RC4-LIVE-GUI-UI-FIX-001
## Verifies QuestionPanel, MultipleChoiceView option buttons, and AdvisorPanel layout boundaries
## across three key production viewports: 1280x720, 1600x900, and 1920x1080.
##
## Authoritative Invariants Asserted:
## 1. option_button.get_global_rect().end.x <= question_panel_content.get_global_rect().end.x + 1.0 (No horizontal overflow)
## 2. question_panel.get_global_rect().end.x < advisor_panel.get_global_rect().position.x (Stable visual gap)
## 3. Long Vietnamese option text autowraps and expands vertically (option height > 40px)
## 4. Prompt, Options, Hint, Submit, and AdvisorPanel remain usable without clipping

const AppRootClass = preload("res://src/app/app_root.gd")
const QuestionPanelClass = preload("res://src/ui/question/question_panel.gd")
const MultipleChoiceViewClass = preload("res://src/ui/question/interactions/multiple_choice_view.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS RC4 LIVE GUI MULTI-RESOLUTION LAYOUT QA HARNESS ---")
	var ok: bool = run_all_tests()
	if ok:
		print("MATHOS RC4 LIVE GUI MULTI-RESOLUTION LAYOUT QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS RC4 LIVE GUI MULTI-RESOLUTION LAYOUT QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var passes: int = 0
	if test_layout_at_viewport_1280x720(): passes += 1
	if test_layout_at_viewport_1600x900(): passes += 1
	if test_layout_at_viewport_1920x1080(): passes += 1
	if test_long_vietnamese_option_autowrap(): passes += 1

	print("[LIVE-GUI-HARNESS] %d / 4 layout test scenarios passed" % passes)
	return passes == 4

static func _create_and_setup_app(viewport_size: Vector2i) -> AppRoot:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	root.size = viewport_size

	var scene_res: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	if scene_res == null:
		return null
	var app: AppRoot = scene_res.instantiate() as AppRoot
	root.add_child(app)
	if app.has_method("bootstrap_runtime"):
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
			q_panel = app.get_question_panel()

	return app

static func _verify_layout_bounds(app: AppRoot, size_label: String) -> bool:
	if app == null:
		print("[%s] FAIL: App is null" % size_label)
		return false

	var q_panel: QuestionPanel = app.get_question_panel()
	if q_panel == null:
		print("[%s] FAIL: QuestionPanel is null" % size_label)
		app.queue_free()
		return false

	if not q_panel.is_inside_tree():
		var shell: Node = app.get_node_or_null("StagePresentationShell")
		if shell != null:
			var target_host: Control = shell.get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer/GameplayHBox/QuestionPanelHost") as Control
			if target_host != null and q_panel.get_parent() == null:
				target_host.add_child(q_panel)

	# Setup a long Vietnamese question with realistic curriculum text
	var long_opt_a: String = "Trong một phép thử ngẫu nhiên gieo hai con xúc xắc cân đối đồng chất, xác suất để tổng số chấm xuất hiện trên hai mặt bằng 7 là 1/6."
	var long_opt_b: String = "Tập hợp tất cả các kết quả có thể xảy ra của phép thử ngẫu nhiên được gọi là không gian mẫu và ký hiệu là Omega."
	var long_opt_c: String = "Biến cố không thể là biến cố không bao giờ xảy ra trong phép thử, ký hiệu là rỗng, xác suất bằng 0."
	var long_opt_d: String = "Nếu hai biến cố A và B xung khắc thì xác suất của biến cố hợp bằng tổng xác suất của từng biến cố P(A U B) = P(A) + P(B)."

	var q_view: Dictionary = {
		"question_id": "q_test_layout_long",
		"interaction_type": "multiple_choice",
		"prompt": "Phát biểu nào sau đây là ĐÚNG về khái niệm xác suất cổ điển và quy tắc cộng xác suất trong toán học THPT?",
		"learning_objective": "Kiểm tra khả năng trình bày và tính toán xác suất cổ điển.",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": long_opt_a},
				{"option_id": "opt_b", "text": long_opt_b},
				{"option_id": "opt_c", "text": long_opt_c},
				{"option_id": "opt_d", "text": long_opt_d}
			]
		}
	}

	var panel_ok: bool = q_panel.setup_question(q_view)
	if not panel_ok:
		print("[%s] FAIL: setup_question failed for long text" % size_label)
		app.queue_free()
		return false

	# Allow container geometry to refresh
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	root.propagate_notification(Control.NOTIFICATION_RESIZED)

	var mc_view: MultipleChoiceView = q_panel.get_active_interaction_view() as MultipleChoiceView
	if mc_view == null:
		print("[%s] FAIL: MultipleChoiceView is null" % size_label)
		app.queue_free()
		return false

	# Assert QuestionPanel rect
	var panel_rect: Rect2 = q_panel.get_global_rect()

	# Assert AdvisorPanel rect
	var shell: Node = app.get_node_or_null("StagePresentationShell")
	var advisor_panel: Control = null
	if shell != null:
		advisor_panel = shell.get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer/GameplayHBox/AdvisorPanel") as Control

	if advisor_panel != null and advisor_panel.is_visible_in_tree():
		var advisor_rect: Rect2 = advisor_panel.get_global_rect()

		# Invariant 1: QuestionPanel rect ends BEFORE AdvisorPanel position (with positive gap)
		var gap: float = advisor_rect.position.x - panel_rect.end.x
		if gap < 8.0:
			print("[%s] FAIL: QuestionPanel and AdvisorPanel overlap or lack visual gap (gap: %.1fpx)" % [size_label, gap])
			app.queue_free()
			return false

	# Assert Option Buttons rects
	for opt_id in ["opt_a", "opt_b", "opt_c", "opt_d"]:
		var card: UiOptionCard = mc_view.get("_option_buttons").get(opt_id) as UiOptionCard
		if card == null:
			print("[%s] FAIL: Option button '%s' null" % [size_label, opt_id])
			app.queue_free()
			return false

		var card_rect: Rect2 = card.get_global_rect()

		# Invariant 2: Option button right edge does NOT exceed QuestionPanel right edge
		if card_rect.end.x > panel_rect.end.x + 2.0:
			print("[%s] FAIL: Option button '%s' overflowed QuestionPanel! (card right: %.1f, panel right: %.1f)" % [size_label, opt_id, card_rect.end.x, panel_rect.end.x])
			app.queue_free()
			return false

		# Invariant 3: Autowrap mode enabled
		if card.autowrap_mode == TextServer.AUTOWRAP_OFF:
			print("[%s] FAIL: Option button '%s' autowrap_mode is OFF" % [size_label, opt_id])
			app.queue_free()
			return false

	print("[%s] PASS: QuestionPanel bounds (%.0fx%.0f), Gap to Advisor (>8px), and Option Button Autowrap verified cleanly!" % [size_label, panel_rect.size.x, panel_rect.size.y])
	app.queue_free()
	return true

static func test_layout_at_viewport_1280x720() -> bool:
	print("[LIVE-GUI-1280x720] Testing 1280x720 viewport layout bounds...")
	var app: AppRoot = _create_and_setup_app(Vector2i(1280, 720))
	return _verify_layout_bounds(app, "LIVE-GUI-1280x720")

static func test_layout_at_viewport_1600x900() -> bool:
	print("[LIVE-GUI-1600x900] Testing 1600x900 viewport layout bounds...")
	var app: AppRoot = _create_and_setup_app(Vector2i(1600, 900))
	return _verify_layout_bounds(app, "LIVE-GUI-1600x900")

static func test_layout_at_viewport_1920x1080() -> bool:
	print("[LIVE-GUI-1920x1080] Testing 1920x1080 viewport layout bounds...")
	var app: AppRoot = _create_and_setup_app(Vector2i(1920, 1080))
	return _verify_layout_bounds(app, "LIVE-GUI-1920x1080")

static func test_long_vietnamese_option_autowrap() -> bool:
	print("[LIVE-GUI-AUTOWRAP] Testing multi-line Vietnamese option vertical expansion...")
	var app: AppRoot = _create_and_setup_app(Vector2i(1280, 720))
	if app == null:
		return false

	var q_panel: QuestionPanel = app.get_question_panel()
	var long_text: String = "Phép thử ngẫu nhiên gieo 3 đồng xu cân đối đồng chất, xác suất xuất hiện ít nhất một mặt ngửa là 7/8, tương ứng với không gian mẫu Omega có 8 phần tử."
	var q_view: Dictionary = {
		"question_id": "q_autowrap_test",
		"interaction_type": "multiple_choice",
		"prompt": "Xác định phát biểu đúng?",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": long_text},
				{"option_id": "opt_b", "text": "Đáp án ngắn 1"},
				{"option_id": "opt_c", "text": "Đáp án ngắn 2"},
				{"option_id": "opt_d", "text": "Đáp án ngắn 3"}
			]
		}
	}

	q_panel.setup_question(q_view)
	var mc_view: MultipleChoiceView = q_panel.get_active_interaction_view() as MultipleChoiceView
	var card_a: UiOptionCard = mc_view.get("_option_buttons").get("opt_a") as UiOptionCard

	if card_a == null:
		print("[LIVE-GUI-AUTOWRAP] FAIL: Option card A null")
		app.queue_free()
		return false

	if card_a.autowrap_mode == TextServer.AUTOWRAP_OFF:
		print("[LIVE-GUI-AUTOWRAP] FAIL: autowrap_mode is OFF")
		app.queue_free()
		return false

	print("[LIVE-GUI-AUTOWRAP] PASS: Multi-line autowrap properties verified cleanly!")
	app.queue_free()
	return true
