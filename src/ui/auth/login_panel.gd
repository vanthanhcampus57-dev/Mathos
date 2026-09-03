class_name LoginPanel
extends Control

## Production Login Panel Component for Mathos Auth UI.
## Provides Email & Password inputs (secret mode), Log In submission,
## Forgot Password link, Sign Up link, Guest entry, and Google OAuth placeholder.

signal login_submitted(email: String, password: String)
signal forgot_password_requested()
signal sign_up_requested()
signal guest_login_requested()
signal google_login_requested()

var _email_input: LineEdit = null
var _password_input: LineEdit = null
var _error_label: Label = null
var _login_button: Button = null
var _forgot_button: Button = null
var _google_button: Button = null
var _guest_button: Button = null
var _signup_button: Button = null

var _is_pending: bool = false

func _ready() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if _email_input == null:
		_build_ui_programmatically()
		_connect_signals()

func _connect_signals() -> void:
	if _login_button != null and not _login_button.pressed.is_connected(_on_login_pressed):
		_login_button.pressed.connect(_on_login_pressed)
	if _forgot_button != null and not _forgot_button.pressed.is_connected(_on_forgot_pressed):
		_forgot_button.pressed.connect(_on_forgot_pressed)
	if _signup_button != null and not _signup_button.pressed.is_connected(_on_signup_pressed):
		_signup_button.pressed.connect(_on_signup_pressed)
	if _guest_button != null and not _guest_button.pressed.is_connected(_on_guest_pressed):
		_guest_button.pressed.connect(_on_guest_pressed)
	if _google_button != null and not _google_button.pressed.is_connected(_on_google_pressed):
		_google_button.pressed.connect(_on_google_pressed)

	if _email_input != null and not _email_input.text_submitted.is_connected(_on_text_submitted):
		_email_input.text_submitted.connect(_on_text_submitted)
	if _password_input != null and not _password_input.text_submitted.is_connected(_on_text_submitted):
		_password_input.text_submitted.connect(_on_text_submitted)

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
	title.text = "ĐĂNG NHẬP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))
	vbox.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "Chào mừng bạn trở lại với Mathos Engine"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.8))
	vbox.add_child(subtitle)

	# Spacer
	var spacer1: Control = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer1)

	# Email Input
	var email_lbl: Label = Label.new()
	email_lbl.text = "Email"
	email_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(email_lbl)

	_email_input = LineEdit.new()
	_email_input.name = "EmailInput"
	_email_input.placeholder_text = "nhap@email.com"
	_email_input.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(_email_input)

	# Password Input
	var pass_lbl: Label = Label.new()
	pass_lbl.text = "Mật khẩu"
	pass_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(pass_lbl)

	_password_input = LineEdit.new()
	_password_input.name = "PasswordInput"
	_password_input.placeholder_text = "••••••••"
	_password_input.secret = true
	_password_input.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(_password_input)

	# Error Label
	_error_label = Label.new()
	_error_label.name = "ErrorLabel"
	_error_label.visible = false
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	_error_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_error_label)

	# Forgot Password Link
	_forgot_button = Button.new()
	_forgot_button.name = "ForgotButton"
	_forgot_button.text = "Quên mật khẩu?"
	_forgot_button.flat = true
	_forgot_button.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	_forgot_button.add_theme_font_size_override("font_size", 13)
	_forgot_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_forgot_button)

	# Login Button
	_login_button = Button.new()
	_login_button.name = "LoginButton"
	_login_button.text = "Đăng Nhập"
	_login_button.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(_login_button)

	# Separator
	var sep: HBoxContainer = HBoxContainer.new()
	sep.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(sep)

	var line1: ColorRect = ColorRect.new()
	line1.custom_minimum_size = Vector2(80, 1)
	line1.color = Color(1.0, 1.0, 1.0, 0.2)
	line1.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sep.add_child(line1)

	var or_lbl: Label = Label.new()
	or_lbl.text = "  hoặc  "
	or_lbl.add_theme_font_size_override("font_size", 12)
	or_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
	sep.add_child(or_lbl)

	var line2: ColorRect = ColorRect.new()
	line2.custom_minimum_size = Vector2(80, 1)
	line2.color = Color(1.0, 1.0, 1.0, 0.2)
	line2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sep.add_child(line2)

	# Google Button (Placeholder)
	_google_button = Button.new()
	_google_button.name = "GoogleButton"
	_google_button.text = "🌐 Tiếp tục với Google"
	_google_button.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(_google_button)

	# Guest Button
	_guest_button = Button.new()
	_guest_button.name = "GuestButton"
	_guest_button.text = "🎮 Chơi Ngay (Khách)"
	_guest_button.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(_guest_button)

	# Sign Up Button
	_signup_button = Button.new()
	_signup_button.name = "SignUpButton"
	_signup_button.text = "Chưa có tài khoản? Đăng ký ngay"
	_signup_button.flat = true
	_signup_button.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.9))
	_signup_button.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_signup_button)

func set_pending(pending: bool) -> void:
	_ensure_nodes()
	_is_pending = pending
	_email_input.editable = not pending
	_password_input.editable = not pending
	_login_button.disabled = pending
	_google_button.disabled = pending
	_guest_button.disabled = pending
	_signup_button.disabled = pending
	_forgot_button.disabled = pending

	if pending:
		_login_button.text = "Đang xử lý..."
	else:
		_login_button.text = "Đăng Nhập"

func show_error(msg: String) -> void:
	_ensure_nodes()
	_error_label.text = msg
	_error_label.visible = not msg.is_empty()

func clear_form() -> void:
	_ensure_nodes()
	if _email_input != null: _email_input.text = ""
	if _password_input != null: _password_input.text = ""
	show_error("")

func set_email(email: String) -> void:
	_ensure_nodes()
	if _email_input != null:
		_email_input.text = email

func get_email() -> String:
	_ensure_nodes()
	return _email_input.text.strip_edges() if _email_input != null else ""

func get_password() -> String:
	_ensure_nodes()
	return _password_input.text if _password_input != null else ""

func _on_text_submitted(_new_text: String) -> void:
	if not _is_pending:
		_on_login_pressed()

func _on_login_pressed() -> void:
	show_error("")
	var email: String = get_email()
	var password: String = get_password()

	if email.is_empty():
		show_error("Vui lòng nhập địa chỉ Email.")
		return
	if password.is_empty():
		show_error("Vui lòng nhập Mật khẩu.")
		return

	login_submitted.emit(email, password)

func _on_forgot_pressed() -> void:
	show_error("")
	forgot_password_requested.emit()

func _on_signup_pressed() -> void:
	show_error("")
	sign_up_requested.emit()

func _on_guest_pressed() -> void:
	show_error("")
	guest_login_requested.emit()

func _on_google_pressed() -> void:
	show_error("Tính năng đăng nhập Google đang được phát triển.")
	google_login_requested.emit()
