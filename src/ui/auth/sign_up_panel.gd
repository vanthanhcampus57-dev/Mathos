class_name SignUpPanel
extends Control

## Production Sign Up Panel Component for Mathos Auth UI.
## Provides Display Name, Email, Password, Confirm Password (with show/hide toggles),
## Terms Checkbox, client-side validation, Create Account submission,
## and Navigation back to Login styled in dark fantasy academic RPG visual direction.

signal signup_submitted(display_name: String, email: String, password: String)
signal login_nav_requested()
signal google_login_requested()

const AuthUiThemeClass = preload("res://src/ui/auth/auth_ui_theme.gd")

var _display_name_input: LineEdit = null
var _email_input: LineEdit = null
var _password_input: LineEdit = null
var _confirm_password_input: LineEdit = null
var _password_toggle_button: Button = null
var _confirm_toggle_button: Button = null
var _terms_checkbox: CheckBox = null
var _error_container: Control = null
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

	if _password_toggle_button != null and not _password_toggle_button.pressed.is_connected(_on_toggle_password_pressed):
		_password_toggle_button.pressed.connect(_on_toggle_password_pressed)
	if _confirm_toggle_button != null and not _confirm_toggle_button.pressed.is_connected(_on_toggle_confirm_pressed):
		_confirm_toggle_button.pressed.connect(_on_toggle_confirm_pressed)

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
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 9)
	margin.add_child(vbox)

	# 1. Official Logo
	var logo_rect: TextureRect = TextureRect.new()
	logo_rect.name = "LogoRect"
	logo_rect.custom_minimum_size = Vector2(0, 44)
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
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_GOLD_PRIMARY)
	vbox.add_child(subtitle)

	var secondary_lbl: Label = Label.new()
	secondary_lbl.name = "SecondaryLabel"
	secondary_lbl.text = "Khởi tạo hồ sơ học viên & pháp sư"
	secondary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secondary_lbl.add_theme_font_size_override("font_size", 11)
	secondary_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_CYAN_MUTED)
	vbox.add_child(secondary_lbl)

	# 3. Display Name
	var name_lbl: Label = Label.new()
	name_lbl.text = "TÊN HIỂN THỊ"
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_TEXT_MUTED)
	vbox.add_child(name_lbl)

	_display_name_input = LineEdit.new()
	_display_name_input.name = "DisplayNameInput"
	_display_name_input.placeholder_text = "Họ và Tên / Biệt danh"
	_display_name_input.custom_minimum_size = Vector2(0, 38)
	AuthUiThemeClass.style_line_edit(_display_name_input)
	vbox.add_child(_display_name_input)

	# 4. Email
	var email_lbl: Label = Label.new()
	email_lbl.text = "EMAIL"
	email_lbl.add_theme_font_size_override("font_size", 11)
	email_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_TEXT_MUTED)
	vbox.add_child(email_lbl)

	_email_input = LineEdit.new()
	_email_input.name = "EmailInput"
	_email_input.placeholder_text = "nhap@email.com"
	_email_input.custom_minimum_size = Vector2(0, 38)
	AuthUiThemeClass.style_line_edit(_email_input)
	vbox.add_child(_email_input)

	# 5. Password (with Toggle)
	var pass_lbl: Label = Label.new()
	pass_lbl.text = "MẬT KHẨU"
	pass_lbl.add_theme_font_size_override("font_size", 11)
	pass_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_TEXT_MUTED)
	vbox.add_child(pass_lbl)

	var pass_container: HBoxContainer = HBoxContainer.new()
	pass_container.add_theme_constant_override("separation", 6)
	vbox.add_child(pass_container)

	_password_input = LineEdit.new()
	_password_input.name = "PasswordInput"
	_password_input.placeholder_text = "••••••••"
	_password_input.secret = true
	_password_input.custom_minimum_size = Vector2(0, 38)
	_password_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	AuthUiThemeClass.style_line_edit(_password_input)
	pass_container.add_child(_password_input)

	_password_toggle_button = Button.new()
	_password_toggle_button.name = "PasswordToggleButton"
	_password_toggle_button.text = "👁"
	_password_toggle_button.custom_minimum_size = Vector2(38, 38)
	AuthUiThemeClass.style_secondary_button(_password_toggle_button)
	_password_toggle_button.tooltip_text = "Hiện / Ẩn mật khẩu"
	pass_container.add_child(_password_toggle_button)

	# 6. Confirm Password (with Toggle)
	var confirm_lbl: Label = Label.new()
	confirm_lbl.text = "XÁC NHẬN MẬT KHẨU"
	confirm_lbl.add_theme_font_size_override("font_size", 11)
	confirm_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_TEXT_MUTED)
	vbox.add_child(confirm_lbl)

	var confirm_container: HBoxContainer = HBoxContainer.new()
	confirm_container.add_theme_constant_override("separation", 6)
	vbox.add_child(confirm_container)

	_confirm_password_input = LineEdit.new()
	_confirm_password_input.name = "ConfirmPasswordInput"
	_confirm_password_input.placeholder_text = "••••••••"
	_confirm_password_input.secret = true
	_confirm_password_input.custom_minimum_size = Vector2(0, 38)
	_confirm_password_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	AuthUiThemeClass.style_line_edit(_confirm_password_input)
	confirm_container.add_child(_confirm_password_input)

	_confirm_toggle_button = Button.new()
	_confirm_toggle_button.name = "ConfirmToggleButton"
	_confirm_toggle_button.text = "👁"
	_confirm_toggle_button.custom_minimum_size = Vector2(38, 38)
	AuthUiThemeClass.style_secondary_button(_confirm_toggle_button)
	_confirm_toggle_button.tooltip_text = "Hiện / Ẩn mật khẩu"
	confirm_container.add_child(_confirm_toggle_button)

	# 7. Terms Checkbox
	_terms_checkbox = CheckBox.new()
	_terms_checkbox.name = "TermsCheckBox"
	_terms_checkbox.text = "Tôi đồng ý với Điều khoản & Quy tắc Học viện"
	_terms_checkbox.button_pressed = true
	_terms_checkbox.add_theme_font_size_override("font_size", 11)
	_terms_checkbox.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_TEXT_BODY)
	vbox.add_child(_terms_checkbox)

	# 8. Reserved Error Space Container (Prevents vertical jumps)
	_error_container = Control.new()
	_error_container.name = "ErrorContainer"
	_error_container.custom_minimum_size = Vector2(0, 30)
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

	# 9. Primary Button: TẠO TÀI KHOẢN
	_signup_button = Button.new()
	_signup_button.name = "SignUpButton"
	_signup_button.text = "TẠO TÀI KHOẢN"
	_signup_button.custom_minimum_size = Vector2(0, 44)
	AuthUiThemeClass.style_primary_button(_signup_button)
	vbox.add_child(_signup_button)

	# 10. Secondary Button: Google
	_google_button = Button.new()
	_google_button.name = "GoogleButton"
	_google_button.text = "🌐  TIẾP TỤC VỚI GOOGLE"
	_google_button.custom_minimum_size = Vector2(0, 38)
	AuthUiThemeClass.style_secondary_button(_google_button)
	vbox.add_child(_google_button)

	# 11. Footer: Đã có tài khoản? ĐĂNG NHẬP
	var footer_box: HBoxContainer = HBoxContainer.new()
	footer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_box.add_theme_constant_override("separation", 6)
	vbox.add_child(footer_box)

	var footer_lbl: Label = Label.new()
	footer_lbl.text = "Đã có tài khoản?"
	footer_lbl.add_theme_font_size_override("font_size", 12)
	footer_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_TEXT_MUTED)
	footer_box.add_child(footer_lbl)

	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = "ĐĂNG NHẬP"
	AuthUiThemeClass.style_text_button(_back_button, true)
	_back_button.add_theme_font_size_override("font_size", 12)
	footer_box.add_child(_back_button)

func _on_toggle_password_pressed() -> void:
	if _password_input != null:
		_password_input.secret = not _password_input.secret
		if _password_toggle_button != null:
			_password_toggle_button.text = "🔒" if not _password_input.secret else "👁"

func _on_toggle_confirm_pressed() -> void:
	if _confirm_password_input != null:
		_confirm_password_input.secret = not _confirm_password_input.secret
		if _confirm_toggle_button != null:
			_confirm_toggle_button.text = "🔒" if not _confirm_password_input.secret else "👁"

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
	if _password_toggle_button != null:
		_password_toggle_button.disabled = pending
	if _confirm_toggle_button != null:
		_confirm_toggle_button.disabled = pending

	if pending:
		_signup_button.text = "Đang tạo tài khoản..."
	else:
		_signup_button.text = "TẠO TÀI KHOẢN"

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

func _on_text_submitted(_new_text: String) -> void:
	if not _is_pending:
		_on_signup_pressed()

func _on_signup_pressed() -> void:
	show_error("")
	var dname: String = _display_name_input.text.strip_edges()
	var email: String = _email_input.text.strip_edges()
	var pass_str: String = _password_input.text
	var confirm_str: String = _confirm_password_input.text

	if dname.is_empty():
		show_error("Vui lòng nhập Tên hiển thị.")
		return
	if email.is_empty():
		show_error("Vui lòng nhập Email.")
		return
	if pass_str.is_empty():
		show_error("Vui lòng nhập Mật khẩu.")
		return
	if confirm_str.is_empty():
		show_error("Vui lòng xác nhận lại Mật khẩu.")
		return
	if pass_str != confirm_str:
		show_error("Mật khẩu xác nhận không khớp.")
		return
	if not _terms_checkbox.button_pressed:
		show_error("Vui lòng đồng ý với Điều khoản & Quy tắc Học viện.")
		return

	signup_submitted.emit(dname, email, pass_str)

func _on_back_pressed() -> void:
	show_error("")
	login_nav_requested.emit()

func _on_google_pressed() -> void:
	show_error("Tính năng đăng ký Google đang được phát triển.")
	google_login_requested.emit()
