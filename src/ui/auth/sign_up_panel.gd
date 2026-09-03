class_name SignUpPanel
extends Control

## Production Sign Up Panel Component for Mathos Auth UI.
## Provides Display Name, Email, Password, Confirm Password, and Terms Checkbox inputs,
## client-side password matching verification, Create Account submission, and Navigation back to Login.

signal signup_submitted(display_name: String, email: String, password: String)
signal login_nav_requested()
signal google_login_requested()

var _display_name_input: LineEdit = null
var _email_input: LineEdit = null
var _password_input: LineEdit = null
var _confirm_password_input: LineEdit = null
var _terms_checkbox: CheckBox = null
var _error_label: Label = null
var _signup_button: Button = null
var _google_button: Button = null
var _back_button: Button = null

var _is_pending: bool = false

func _ready() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if _display_name_input == null:
		_build_ui_programmatically()
		_connect_signals()

func _connect_signals() -> void:
	if _signup_button != null and not _signup_button.pressed.is_connected(_on_signup_pressed):
		_signup_button.pressed.connect(_on_signup_pressed)
	if _back_button != null and not _back_button.pressed.is_connected(_on_back_pressed):
		_back_button.pressed.connect(_on_back_pressed)
	if _google_button != null and not _google_button.pressed.is_connected(_on_google_pressed):
		_google_button.pressed.connect(_on_google_pressed)

	if _display_name_input != null and not _display_name_input.text_submitted.is_connected(_on_text_submitted):
		_display_name_input.text_submitted.connect(_on_text_submitted)
	if _email_input != null and not _email_input.text_submitted.is_connected(_on_text_submitted):
		_email_input.text_submitted.connect(_on_text_submitted)
	if _password_input != null and not _password_input.text_submitted.is_connected(_on_text_submitted):
		_password_input.text_submitted.connect(_on_text_submitted)
	if _confirm_password_input != null and not _confirm_password_input.text_submitted.is_connected(_on_text_submitted):
		_confirm_password_input.text_submitted.connect(_on_text_submitted)

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
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title
	var title: Label = Label.new()
	title.text = "TẠO TÀI KHOẢN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))
	vbox.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "Bắt đầu hành trình học tập cùng Mathos"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.8))
	vbox.add_child(subtitle)

	# Display Name
	var name_lbl: Label = Label.new()
	name_lbl.text = "Tên hiển thị"
	name_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(name_lbl)

	_display_name_input = LineEdit.new()
	_display_name_input.name = "DisplayNameInput"
	_display_name_input.placeholder_text = "Họ và Tên / Biệt danh"
	_display_name_input.custom_minimum_size = Vector2(0, 38)
	vbox.add_child(_display_name_input)

	# Email
	var email_lbl: Label = Label.new()
	email_lbl.text = "Email"
	email_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(email_lbl)

	_email_input = LineEdit.new()
	_email_input.name = "EmailInput"
	_email_input.placeholder_text = "nhap@email.com"
	_email_input.custom_minimum_size = Vector2(0, 38)
	vbox.add_child(_email_input)

	# Password
	var pass_lbl: Label = Label.new()
	pass_lbl.text = "Mật khẩu"
	pass_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(pass_lbl)

	_password_input = LineEdit.new()
	_password_input.name = "PasswordInput"
	_password_input.placeholder_text = "••••••••"
	_password_input.secret = true
	_password_input.custom_minimum_size = Vector2(0, 38)
	vbox.add_child(_password_input)

	# Confirm Password
	var confirm_lbl: Label = Label.new()
	confirm_lbl.text = "Xác nhận mật khẩu"
	confirm_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(confirm_lbl)

	_confirm_password_input = LineEdit.new()
	_confirm_password_input.name = "ConfirmPasswordInput"
	_confirm_password_input.placeholder_text = "••••••••"
	_confirm_password_input.secret = true
	_confirm_password_input.custom_minimum_size = Vector2(0, 38)
	vbox.add_child(_confirm_password_input)

	# Terms Checkbox
	_terms_checkbox = CheckBox.new()
	_terms_checkbox.name = "TermsCheckBox"
	_terms_checkbox.text = "Tôi đồng ý với Điều khoản & Chính sách"
	_terms_checkbox.button_pressed = true
	_terms_checkbox.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_terms_checkbox)

	# Error Label
	_error_label = Label.new()
	_error_label.name = "ErrorLabel"
	_error_label.visible = false
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	_error_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_error_label)

	# Create Account Button
	_signup_button = Button.new()
	_signup_button.name = "SignUpButton"
	_signup_button.text = "Đăng Ký Tài Khoản"
	_signup_button.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(_signup_button)

	# Google Button Placeholder
	_google_button = Button.new()
	_google_button.name = "GoogleButton"
	_google_button.text = "🌐 Đăng ký bằng Google"
	_google_button.custom_minimum_size = Vector2(0, 38)
	vbox.add_child(_google_button)

	# Back Button
	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = "Đã có tài khoản? Quay lại Đăng nhập"
	_back_button.flat = true
	_back_button.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.9))
	_back_button.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_back_button)

func set_pending(pending: bool) -> void:
	_ensure_nodes()
	_is_pending = pending
	_display_name_input.editable = not pending
	_email_input.editable = not pending
	_password_input.editable = not pending
	_confirm_password_input.editable = not pending
	_terms_checkbox.disabled = pending
	_signup_button.disabled = pending
	_google_button.disabled = pending
	_back_button.disabled = pending

	if pending:
		_signup_button.text = "Đang khởi tạo tài khoản..."
	else:
		_signup_button.text = "Đăng Ký Tài Khoản"

func show_error(msg: String) -> void:
	_ensure_nodes()
	_error_label.text = msg
	_error_label.visible = not msg.is_empty()

func clear_form() -> void:
	_ensure_nodes()
	if _display_name_input != null: _display_name_input.text = ""
	if _email_input != null: _email_input.text = ""
	if _password_input != null: _password_input.text = ""
	if _confirm_password_input != null: _confirm_password_input.text = ""
	if _terms_checkbox != null: _terms_checkbox.button_pressed = true
	show_error("")

func get_display_name() -> String:
	_ensure_nodes()
	return _display_name_input.text.strip_edges() if _display_name_input != null else ""

func get_email() -> String:
	_ensure_nodes()
	return _email_input.text.strip_edges() if _email_input != null else ""

func get_password() -> String:
	_ensure_nodes()
	return _password_input.text if _password_input != null else ""

func get_confirm_password() -> String:
	_ensure_nodes()
	return _confirm_password_input.text if _confirm_password_input != null else ""

func _on_text_submitted(_new_text: String) -> void:
	if not _is_pending:
		_on_signup_pressed()

func _on_signup_pressed() -> void:
	show_error("")
	var dname: String = get_display_name()
	var email: String = get_email()
	var pass_str: String = get_password()
	var confirm_str: String = get_confirm_password()

	if dname.is_empty():
		show_error("Vui lòng nhập Tên hiển thị.")
		return
	if email.is_empty():
		show_error("Vui lòng nhập địa chỉ Email.")
		return
	if pass_str.is_empty():
		show_error("Vui lòng nhập Mật khẩu.")
		return
	if pass_str != confirm_str:
		show_error("Mật khẩu xác nhận không khớp.")
		return
	if not _terms_checkbox.button_pressed:
		show_error("Bạn cần đồng ý với Điều khoản dịch vụ để đăng ký.")
		return

	signup_submitted.emit(dname, email, pass_str)

func _on_back_pressed() -> void:
	show_error("")
	login_nav_requested.emit()

func _on_google_pressed() -> void:
	show_error("Tính năng đăng ký Google đang được phát triển.")
	google_login_requested.emit()
