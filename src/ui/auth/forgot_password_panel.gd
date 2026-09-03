class_name ForgotPasswordPanel
extends Control

## Production Forgot Password Panel Component for Mathos Auth UI.
## Provides Email input, password reset request submission,
## anti-enumeration friendly message presentation, and Navigation back to Login.

signal forgot_password_submitted(email: String)
signal login_nav_requested()

var _email_input: LineEdit = null
var _status_label: Label = null
var _submit_button: Button = null
var _back_button: Button = null

var _is_pending: bool = false

func _ready() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if _email_input == null:
		_build_ui_programmatically()
		_connect_signals()

func _connect_signals() -> void:
	if _submit_button != null and not _submit_button.pressed.is_connected(_on_submit_pressed):
		_submit_button.pressed.connect(_on_submit_pressed)
	if _back_button != null and not _back_button.pressed.is_connected(_on_back_pressed):
		_back_button.pressed.connect(_on_back_pressed)
	if _email_input != null and not _email_input.text_submitted.is_connected(_on_text_submitted):
		_email_input.text_submitted.connect(_on_text_submitted)

func _build_ui_programmatically() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title: Label = Label.new()
	title.text = "QUÊN MẬT KHẨU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))
	vbox.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "Nhập email của bạn để nhận hướng dẫn khôi phục mật khẩu"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.8))
	vbox.add_child(subtitle)

	# Email Input
	var email_lbl: Label = Label.new()
	email_lbl.text = "Email đăng ký"
	email_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(email_lbl)

	_email_input = LineEdit.new()
	_email_input.name = "EmailInput"
	_email_input.placeholder_text = "nhap@email.com"
	_email_input.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(_email_input)

	# Status / Success Message Label
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.visible = false
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_status_label)

	# Submit Button
	_submit_button = Button.new()
	_submit_button.name = "SubmitButton"
	_submit_button.text = "Gửi Yêu Cầu Khôi Phục"
	_submit_button.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(_submit_button)

	# Back Button
	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = "Quay lại Đăng nhập"
	_back_button.flat = true
	_back_button.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.9))
	_back_button.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_back_button)

func set_pending(pending: bool) -> void:
	_ensure_nodes()
	_is_pending = pending
	_email_input.editable = not pending
	_submit_button.disabled = pending
	_back_button.disabled = pending

	if pending:
		_submit_button.text = "Đang gửi yêu cầu..."
	else:
		_submit_button.text = "Gửi Yêu Cầu Khôi Phục"

func show_error(msg: String) -> void:
	_ensure_nodes()
	_status_label.text = msg
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	_status_label.visible = not msg.is_empty()

func show_success_anti_enumeration(msg: String = "") -> void:
	_ensure_nodes()
	var final_msg: String = msg if not msg.is_empty() else "Nếu email này tồn tại trong hệ thống, hướng dẫn đặt lại mật khẩu đã được gửi đến hòm thư của bạn."
	_status_label.text = final_msg
	_status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1.0))
	_status_label.visible = true

func clear_form() -> void:
	_ensure_nodes()
	if _email_input != null: _email_input.text = ""
	_status_label.visible = false

func get_email() -> String:
	_ensure_nodes()
	return _email_input.text.strip_edges() if _email_input != null else ""

func set_email(email: String) -> void:
	_ensure_nodes()
	if _email_input != null:
		_email_input.text = email

func _on_text_submitted(_new_text: String) -> void:
	if not _is_pending:
		_on_submit_pressed()

func _on_submit_pressed() -> void:
	_status_label.visible = false
	var email: String = get_email()
	if email.is_empty():
		show_error("Vui lòng nhập địa chỉ Email.")
		return

	forgot_password_submitted.emit(email)

func _on_back_pressed() -> void:
	_status_label.visible = false
	login_nav_requested.emit()
