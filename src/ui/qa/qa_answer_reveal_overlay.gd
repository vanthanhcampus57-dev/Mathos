class_name QaAnswerRevealOverlay
extends Control

## QA-only overlay component providing the "🧪 ĐÁP ÁN" reveal cheat.
## Gated behind the command-line flag --qa-cheats or explicit set_qa_cheats_enabled(true).
## Uses internal CanvasLayer (layer = 100) to guarantee top z-order rendering in live Windows GUI.

signal qa_answer_revealed(formatted_text: String)

const QaAnswerFormatterClass = preload("res://src/ui/qa/qa_answer_formatter.gd")

var _qa_cheats_enabled: bool = false
var _catalog: RefCounted = null
var _app_root: Node = null
var _current_question_id: String = ""

var _canvas_layer: CanvasLayer = null
var _root_control: Control = null
var _cheat_button: Button = null
var _answer_panel: PanelContainer = null
var _answer_label: RichTextLabel = null
var _is_revealed: bool = false

func _init() -> void:
	name = "QaAnswerRevealOverlay"
	mouse_filter = MOUSE_FILTER_IGNORE

func _ready() -> void:
	_ensure_ui_built()
	set_qa_cheats_enabled(detect_qa_cheats_flag())

static func detect_qa_cheats_flag() -> bool:
	var args: Array = OS.get_cmdline_args()
	for a in args:
		var sa: String = String(a).strip_edges()
		if sa == "--qa-cheats" or sa == "-qa-cheats":
			return true
	var user_args: Array = OS.get_cmdline_user_args()
	for ua in user_args:
		var sua: String = String(ua).strip_edges()
		if sua == "--qa-cheats" or sua == "-qa-cheats":
			return true
	return false

func set_qa_cheats_enabled(enabled: bool) -> void:
	_ensure_ui_built()
	_qa_cheats_enabled = enabled
	visible = enabled
	if _canvas_layer != null:
		_canvas_layer.visible = enabled
	if _root_control != null:
		_root_control.visible = enabled
	if _cheat_button != null:
		_cheat_button.visible = enabled
		_cheat_button.mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE
	if not enabled and _answer_panel != null:
		_answer_panel.hide()
		_is_revealed = false

	_log_diagnostic_evidence()

func is_qa_cheats_enabled() -> bool:
	return _qa_cheats_enabled

func get_canvas_layer() -> CanvasLayer:
	_ensure_ui_built()
	return _canvas_layer

func get_root_control() -> Control:
	_ensure_ui_built()
	return _root_control

func get_cheat_button() -> Button:
	_ensure_ui_built()
	return _cheat_button

func set_catalog(p_catalog: RefCounted) -> void:
	_catalog = p_catalog

func set_app_root(p_app: Node) -> void:
	_app_root = p_app

func on_question_changed(new_question_id: String = "") -> void:
	_current_question_id = new_question_id
	hide_answer()

func hide_answer() -> void:
	_is_revealed = false
	if _answer_panel != null:
		_answer_panel.hide()
	if _answer_label != null:
		_answer_label.text = ""

func is_revealed() -> bool:
	return _is_revealed

func get_formatted_answer() -> String:
	if _answer_label != null:
		return _answer_label.text
	return ""

func _log_diagnostic_evidence() -> void:
	print("[QA-CHEAT-DIAG] QA_CHEATS_FLAG=%s" % str(_qa_cheats_enabled))
	print("[QA-CHEAT-DIAG] OVERLAY_CREATED=true")
	print("[QA-CHEAT-DIAG] OVERLAY_IN_TREE=%s" % str(is_inside_tree()))
	print("[QA-CHEAT-DIAG] OVERLAY_VISIBLE=%s" % str(visible and (_root_control != null and _root_control.visible)))
	if _cheat_button != null and _cheat_button.is_inside_tree():
		print("[QA-CHEAT-DIAG] OVERLAY_GLOBAL_RECT=%s" % str(_cheat_button.get_global_rect()))

func _ensure_ui_built() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	if _canvas_layer == null:
		_canvas_layer = CanvasLayer.new()
		_canvas_layer.name = "QaCanvasLayer"
		_canvas_layer.layer = 100
		add_child(_canvas_layer)

	if _root_control == null:
		_root_control = Control.new()
		_root_control.name = "RootControl"
		_root_control.set_anchors_preset(PRESET_FULL_RECT)
		_root_control.mouse_filter = MOUSE_FILTER_IGNORE
		_canvas_layer.add_child(_root_control)

	if _cheat_button == null:
		_cheat_button = Button.new()
		_cheat_button.name = "QaCheatButton"
		_cheat_button.text = "🧪 ĐÁP ÁN"
		_cheat_button.custom_minimum_size = Vector2(110, 36)
		_cheat_button.anchor_left = 1.0
		_cheat_button.anchor_top = 0.0
		_cheat_button.anchor_right = 1.0
		_cheat_button.anchor_bottom = 0.0
		_cheat_button.offset_left = -260.0
		_cheat_button.offset_top = 16.0
		_cheat_button.offset_right = -136.0
		_cheat_button.offset_bottom = 52.0
		_cheat_button.theme_type_variation = &"MathosSecondaryButton"
		_cheat_button.pressed.connect(_on_cheat_button_pressed)
		_root_control.add_child(_cheat_button)

	if _answer_panel == null:
		_answer_panel = PanelContainer.new()
		_answer_panel.name = "QaAnswerPanel"
		_answer_panel.custom_minimum_size = Vector2(340, 120)
		_answer_panel.anchor_left = 1.0
		_answer_panel.anchor_top = 0.0
		_answer_panel.anchor_right = 1.0
		_answer_panel.anchor_bottom = 0.0
		_answer_panel.offset_left = -380.0
		_answer_panel.offset_top = 60.0
		_answer_panel.offset_right = -16.0
		_answer_panel.offset_bottom = 220.0
		_answer_panel.hide()

		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		_answer_panel.add_child(margin)

		_answer_label = RichTextLabel.new()
		_answer_label.name = "QaAnswerLabel"
		_answer_label.bbcode_enabled = false
		_answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_answer_label.selection_enabled = true
		margin.add_child(_answer_label)

		_root_control.add_child(_answer_panel)

func _on_cheat_button_pressed() -> void:
	if not _qa_cheats_enabled:
		return

	if _is_revealed:
		hide_answer()
		return

	var formatted: String = _fetch_and_format_current_answer()
	if _answer_label != null:
		_answer_label.text = formatted
	if _answer_panel != null:
		_answer_panel.show()

	_is_revealed = true
	qa_answer_revealed.emit(formatted)

func _fetch_and_format_current_answer() -> String:
	var qid: String = _current_question_id
	var q_dict: Dictionary = {}
	var answer_spec: Dictionary = {}
	var interaction_type: String = "multiple_choice"

	# 1. Check if AppRoot holds active question resource (e.g. static or procedurally generated QGen)
	if _app_root != null:
		var q_res: Dictionary = _app_root.get("_active_question_res") if _app_root.get("_active_question_res") is Dictionary else {}
		if not q_res.is_empty():
			var q_def: Resource = q_res.get("question_definition") as Resource
			if q_def != null and q_def.get("answer_spec") is Dictionary:
				var itype: Variant = q_def.get("interaction_type")
				if itype != null:
					interaction_type = String(itype)
				if qid.is_empty():
					var def_qid: Variant = q_def.get("question_id")
					if def_qid != null:
						qid = String(def_qid)

	# 2. Separate QA lookup path: Query catalog directly by question_id
	if answer_spec.is_empty() and not qid.is_empty() and _catalog != null and _catalog.has_method("get_question"):
		q_dict = _catalog.call("get_question", qid) as Dictionary
		if not q_dict.is_empty():
			answer_spec = q_dict.get("answer_spec", {}) as Dictionary
			interaction_type = String(q_dict.get("interaction_type", "multiple_choice"))

	# 3. Fallback: Check QuestionService active session question ID if catalog has it
	if answer_spec.is_empty() and _app_root != null and _app_root.has_method("get_question_service"):
		var q_svc: RefCounted = _app_root.call("get_question_service") as RefCounted
		if q_svc != null and q_svc.has_method("get_active_session"):
			var sess: Dictionary = q_svc.call("get_active_session") as Dictionary
			var sess_qid: String = String(sess.get("question_id", ""))
			if not sess_qid.is_empty() and _catalog != null and _catalog.has_method("get_question"):
				q_dict = _catalog.call("get_question", sess_qid) as Dictionary
				if not q_dict.is_empty():
					answer_spec = q_dict.get("answer_spec", {}) as Dictionary
					interaction_type = String(q_dict.get("interaction_type", "multiple_choice"))

	if answer_spec.is_empty():
		return "⚠️ Không tìm thấy đáp án hợp lệ cho câu hỏi hiện tại (id: '%s')" % qid

	return QaAnswerFormatterClass.format_answer(interaction_type, answer_spec, q_dict)
