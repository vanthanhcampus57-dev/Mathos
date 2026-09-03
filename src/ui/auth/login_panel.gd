class_name LoginPanel
extends Control

## Production Login Panel Component for Mathos Auth UI.
## Provides Email & Password inputs (secret mode with show/hide toggle),
## Log In submission, Forgot Password link, Sign Up link, Guest entry,
## and Google OAuth placeholder styled in dark fantasy academic RPG visual direction.

signal login_submitted(email: String, password: String)
signal forgot_password_requested()
signal sign_up_requested()
signal guest_login_requested()
signal google_login_requested()

const AuthUiThemeClass = preload("res://src/ui/auth/auth_ui_theme.gd")

var _email_input: LineEdit = null
var _password_input: LineEdit = null
var _password_toggle_button: Button = null
var _error_container: Control = null
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

	if _password_toggle_button != null and not _password_toggle_button.pressed.is_connected(_on_toggle_password_pressed):
		_password_toggle_button.pressed.connect(_on_toggle_password_pressed)

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
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# 1. Official MATHOS Logo
	var logo_rect: TextureRect = TextureRect.new()
	logo_rect.name = "LogoRect"
	logo_rect.custom_minimum_size = Vector2(0, 52)
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var logo_tex: Texture2D = load("res://assets/branding/mathos_logo_main.png") as Texture2D
	if logo_tex != null:
		logo_rect.texture = logo_tex
	vbox.add_child(logo_rect)

	# 2. Academy Subtitle
	var subtitle: Label = Label.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "CỔNG XÁC THỰC HỌC VIỆN"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_GOLD_PRIMARY)
	vbox.add_child(subtitle)

	# 3. Secondary Subtitle
	var secondary_lbl: Label = Label.new()
	secondary_lbl.name = "SecondaryLabel"
	secondary_lbl.text = "Magical Archive & Authentication Portal"
	secondary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secondary_lbl.add_theme_font_size_override("font_size", 11)
	secondary_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_CYAN_MUTED)
	vbox.add_child(secondary_lbl)

	# Rune Accent Line
	var rune_line: Control = Control.new()
	rune_line.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(rune_line)

	# 4. Email Label & Input
	var email_lbl: Label = Label.new()
	email_lbl.text = "EMAIL"
	email_lbl.add_theme_font_size_override("font_size", 11)
	email_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_TEXT_MUTED)
	vbox.add_child(email_lbl)

	_email_input = LineEdit.new()
	_email_input.name = "EmailInput"
	_email_input.placeholder_text = "nhap@email.com"
	_email_input.custom_minimum_size = Vector2(0, 42)
	AuthUiThemeClass.style_line_edit(_email_input)
	vbox.add_child(_email_input)

	# 5. Password Label & Input (with Show/Hide Toggle)
	var pass_header: HBoxContainer = HBoxContainer.new()
	var pass_lbl: Label = Label.new()
	pass_lbl.text = "MẬT KHẨU"
	pass_lbl.add_theme_font_size_override("font_size", 11)
	pass_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_TEXT_MUTED)
	pass_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pass_header.add_child(pass_lbl)

	_forgot_button = Button.new()
	_forgot_button.name = "ForgotButton"
	_forgot_button.text = "QUÊN MẬT KHẨU?"
	AuthUiThemeClass.style_text_button(_forgot_button, true)
	_forgot_button.add_theme_font_size_override("font_size", 11)
	pass_header.add_child(_forgot_button)
	vbox.add_child(pass_header)

	var pass_container: HBoxContainer = HBoxContainer.new()
	pass_container.add_theme_constant_override("separation", 6)
	vbox.add_child(pass_container)

	_password_input = LineEdit.new()
	_password_input.name = "PasswordInput"
	_password_input.placeholder_text = "••••••••"
	_password_input.secret = true
	_password_input.custom_minimum_size = Vector2(0, 42)
	_password_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	AuthUiThemeClass.style_line_edit(_password_input)
	pass_container.add_child(_password_input)

	_password_toggle_button = Button.new()
	_password_toggle_button.name = "PasswordToggleButton"
	_password_toggle_button.text = "👁"
	_password_toggle_button.custom_minimum_size = Vector2(42, 42)
	AuthUiThemeClass.style_secondary_button(_password_toggle_button)
	_password_toggle_button.tooltip_text = "Hiện / Ẩn mật khẩu"
	pass_container.add_child(_password_toggle_button)

	# 6. Reserved Error Space Container (Guarantees zero vertical panel jumping)
	_error_container = Control.new()
	_error_container.name = "ErrorContainer"
	_error_container.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(_error_container)

	_error_label = Label.new()
	_error_label.name = "ErrorLabel"
	_error_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_ERROR_TEXT)
	_error_label.add_theme_font_size_override("font_size", 12)
	_error_label.visible = false
	_error_container.add_child(_error_label)

	# 7. Primary Action: ĐĂNG NHẬP · LOG IN
	_login_button = Button.new()
	_login_button.name = "LoginButton"
	_login_button.text = "ĐĂNG NHẬP · LOG IN"
	_login_button.custom_minimum_size = Vector2(0, 46)
	AuthUiThemeClass.style_primary_button(_login_button)
	vbox.add_child(_login_button)

	# 8. Divider: HOẶC · OR
	var divider: HBoxContainer = AuthUiThemeClass.create_rune_divider("HOẶC · OR")
	vbox.add_child(divider)

	# 9. Secondary Action: TIẾP TỤC VỚI GOOGLE
	_google_button = Button.new()
	_google_button.name = "GoogleButton"
	_google_button.text = "🌐  TIẾP TỤC VỚI GOOGLE"
	_google_button.custom_minimum_size = Vector2(0, 42)
	AuthUiThemeClass.style_secondary_button(_google_button)
	vbox.add_child(_google_button)

	# 10. Text Action: CHƠI VỚI TƯ CÁCH KHÁCH · GUEST MODE
	_guest_button = Button.new()
	_guest_button.name = "GuestButton"
	_guest_button.text = "CHƠI VỚI TƯ CÁCH KHÁCH · GUEST MODE"
	_guest_button.custom_minimum_size = Vector2(0, 34)
	AuthUiThemeClass.style_text_button(_guest_button, false)
	vbox.add_child(_guest_button)

	# 11. Footer: Chưa có tài khoản? TẠO TÀI KHOẢN
	var footer_box: HBoxContainer = HBoxContainer.new()
	footer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_box.add_theme_constant_override("separation", 6)
	vbox.add_child(footer_box)

	var footer_lbl: Label = Label.new()
	footer_lbl.text = "Chưa có tài khoản?"
	footer_lbl.add_theme_font_size_override("font_size", 12)
	footer_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_TEXT_MUTED)
	footer_box.add_child(footer_lbl)

	_signup_button = Button.new()
	_signup_button.name = "SignUpButton"
	_signup_button.text = "TẠO TÀI KHOẢN"
	AuthUiThemeClass.style_text_button(_signup_button, true)
	_signup_button.add_theme_font_size_override("font_size", 12)
	footer_box.add_child(_signup_button)

func _on_toggle_password_pressed() -> void:
	if _password_input != null:
		_password_input.secret = not _password_input.secret
		if _password_toggle_button != null:
			_password_toggle_button.text = "🔒" if not _password_input.secret else "👁"

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
	if _password_toggle_button != null:
		_password_toggle_button.disabled = pending

	if pending:
		_login_button.text = "Đang xác thực..."
	else:
		_login_button.text = "ĐĂNG NHẬP · LOG IN"

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
