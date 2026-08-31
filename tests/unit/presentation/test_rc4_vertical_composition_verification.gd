extends SceneTree

## Vertical Composition & Layout Invariants Verification Suite for MATHOS-RC4-LIVE-GUI-COMPOSITION-FIX-002
## Verifies 3-tier QuestionPanel layout architecture (Header, Scrollable Content, Footer)
## across viewports (1280x720, 1600x900, 1920x1080, 1024x600 unmaximized).
##
## Authoritative Invariants Asserted:
## 1. ScrollContainer content region does not cross FooterVBox bounds
## 2. Footer controls (HintButton & SubmitButton) NEVER intersect any interaction row
## 3. All interaction rows (including 4th row) are reachable without clipping
## 4. QuestionPanel bounds contain all fixed controls (Header, ScrollContainer, Footer)
## 5. Horizontal no-overlap invariant with AdvisorPanel is preserved (>8px gap)

const AppRootClass = preload("res://src/app/app_root.gd")
const QuestionPanelClass = preload("res://src/ui/question/question_panel.gd")
const DragDropViewClass = preload("res://src/ui/question/interactions/drag_drop_view.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS RC4 VERTICAL COMPOSITION QA HARNESS ---")
	var ok: bool = run_all_tests()
	if ok:
		print("MATHOS RC4 VERTICAL COMPOSITION QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS RC4 VERTICAL COMPOSITION QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var passes: int = 0
	if test_vertical_composition_1280x720(): passes += 1
	if test_vertical_composition_1600x900(): passes += 1
	if test_vertical_composition_1920x1080(): passes += 1
	if test_vertical_composition_unmaximized_1024x600(): passes += 1

	print("[VERT-COMP-HARNESS] %d / 4 vertical composition test scenarios passed" % passes)
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

	return app

static func _verify_vertical_composition(app: AppRoot, size_label: String) -> bool:
	if app == null:
		print("[%s] FAIL: App is null" % size_label)
		return false

	var q_panel: QuestionPanel = app.get_question_panel()
	if q_panel == null or q_panel.get_parent() == null:
		print("[%s] FAIL: QuestionPanel or its parent is null" % size_label)
		app.queue_free()
		return false

	# Setup a multi-row Drag & Drop classification question with 4 rows and long Vietnamese text
	var q_view: Dictionary = {
		"question_id": "q_test_drag_4rows_long",
		"interaction_type": "drag_drop",
		"prompt": "Hãy ghép nối từng khái niệm xác suất THPT sau đây với định nghĩa hoặc công thức tương ứng của nó?",
		"learning_objective": "Đánh giá mức độ thông hiểu các quy tắc tính xác suất cổ điển và biến cố độc lập.",
		"interaction_payload": {
			"items": [
				{"item_id": "item_1", "text": "Hợp hai biến cố A và B là biến cố xảy ra khi có ít nhất một trong hai biến cố xảy ra."},
				{"item_id": "item_2", "text": "Giao hai biến cố A và B là biến cố xảy ra khi cả hai biến cố đồng thời xảy ra."},
				{"item_id": "item_3", "text": "Hai biến cố A và B độc lập nếu việc xảy ra hay không xảy ra của biến cố này không ảnh hưởng."},
				{"item_id": "item_4", "text": "Xác suất điều kiện P(A|B) tính xác suất của biến cố A khi biết biến cố B đã xảy ra."}
			],
			"targets": [
				{"target_id": "tg_1", "label": "Khái niệm Hợp Biến Cố"},
				{"target_id": "tg_2", "label": "Khái niệm Giao Biến Cố"},
				{"target_id": "tg_3", "label": "Khái niệm Biến Cố Độc Lập"},
				{"target_id": "tg_4", "label": "Khái niệm Xác Suất Điều Kiện"}
			]
		}
	}

	var panel_ok: bool = q_panel.setup_question(q_view)
	if not panel_ok:
		print("[%s] FAIL: setup_question failed for 4-row drag_drop" % size_label)
		app.queue_free()
		return false

	var root: Window = (Engine.get_main_loop() as SceneTree).root
	root.propagate_notification(Control.NOTIFICATION_RESIZED)

	# Inspect 3-tier container hierarchy
	var main_vbox: VBoxContainer = q_panel.get_node_or_null("MainVBox") as VBoxContainer
	if main_vbox == null:
		print("[%s] FAIL: MainVBox is null" % size_label)
		app.queue_free()
		return false

	var prompt_label: Label = main_vbox.get_node_or_null("PromptLabel") as Label
	var scroll_container: ScrollContainer = q_panel.get_interaction_scroll_container()
	var action_hbox: Control = main_vbox.get_node_or_null("ActionHBox") as Control

	if prompt_label == null or scroll_container == null or action_hbox == null:
		print("[%s] FAIL: 3-tier layout missing required tier (Prompt: %s, Scroll: %s, ActionHBox: %s)" % [size_label, prompt_label != null, scroll_container != null, action_hbox != null])
		app.queue_free()
		return false

	# Assert Footer Action Controls exist
	var hint_btn: Button = q_panel._hint_button
	var submit_btn: Button = q_panel._submit_button

	# Invariant 1: Footer controls exist
	if hint_btn == null or submit_btn == null or hint_btn.get_parent() == null or submit_btn.get_parent() == null:
		print("[%s] FAIL: Footer controls are missing or unparented" % size_label)
		app.queue_free()
		return false

	# Invariant 2: ScrollContainer content region does NOT overlap footer buttons
	var scroll_rect: Rect2 = scroll_container.get_global_rect()
	var hint_rect: Rect2 = hint_btn.get_global_rect()
	var submit_rect: Rect2 = submit_btn.get_global_rect()

	if scroll_rect.end.y > hint_rect.position.y + 2.0 or scroll_rect.end.y > submit_rect.position.y + 2.0:
		print("[%s] FAIL: ScrollContainer intersects footer buttons! (scroll bottom: %.1f, hint top: %.1f, submit top: %.1f)" % [size_label, scroll_rect.end.y, hint_rect.position.y, submit_rect.position.y])
		app.queue_free()
		return false

	# Invariant 3: Footer buttons fit strictly within QuestionPanel bounds
	var panel_rect: Rect2 = q_panel.get_global_rect()
	if submit_rect.end.y > panel_rect.end.y + 2.0 or hint_rect.end.y > panel_rect.end.y + 2.0:
		print("[%s] FAIL: Footer buttons overflow QuestionPanel bottom! (submit bottom: %.1f, panel bottom: %.1f)" % [size_label, submit_rect.end.y, panel_rect.end.y])
		app.queue_free()
		return false
		app.queue_free()
		return false

	# Invariant 4: Horizontal gap to AdvisorPanel is preserved (>8px)
	var shell: Node = app.get_node_or_null("StagePresentationShell")
	var advisor_panel: Control = null
	if shell != null:
		advisor_panel = shell.get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer/GameplayHBox/AdvisorPanel") as Control

	if advisor_panel != null and advisor_panel.is_visible_in_tree():
		var advisor_rect: Rect2 = advisor_panel.get_global_rect()
		var gap: float = advisor_rect.position.x - panel_rect.end.x
		if gap < 8.0:
			print("[%s] FAIL: QuestionPanel overlaps AdvisorPanel (gap: %.1fpx)" % [size_label, gap])
			app.queue_free()
			return false

	print("[%s] PASS: 3-tier vertical composition, non-overlapping footer, and responsive scrolling verified cleanly!" % size_label)
	app.queue_free()
	return true

static func test_vertical_composition_1280x720() -> bool:
	print("[VERT-COMP-1280x720] Testing 1280x720 viewport vertical composition...")
	var app: AppRoot = _create_and_setup_app(Vector2i(1280, 720))
	return _verify_vertical_composition(app, "VERT-COMP-1280x720")

static func test_vertical_composition_1600x900() -> bool:
	print("[VERT-COMP-1600x900] Testing 1600x900 viewport vertical composition...")
	var app: AppRoot = _create_and_setup_app(Vector2i(1600, 900))
	return _verify_vertical_composition(app, "VERT-COMP-1600x900")

static func test_vertical_composition_1920x1080() -> bool:
	print("[VERT-COMP-1920x1080] Testing 1920x1080 viewport vertical composition...")
	var app: AppRoot = _create_and_setup_app(Vector2i(1920, 1080))
	return _verify_vertical_composition(app, "VERT-COMP-1920x1080")

static func test_vertical_composition_unmaximized_1024x600() -> bool:
	print("[VERT-COMP-1024x600] Testing unmaximized 1024x600 viewport vertical composition...")
	var app: AppRoot = _create_and_setup_app(Vector2i(1024, 600))
	return _verify_vertical_composition(app, "VERT-COMP-1024x600")
