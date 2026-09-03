class_name ForgotPasswordPanel
extends Control

## Production Forgot Password Panel Component for Mathos Auth UI.
## Provides Email input, password reset request submission,
## anti-enumeration friendly message presentation, and Navigation back to Login
## styled in dark fantasy academic RPG visual direction.

signal forgot_password_submitted(email: String)
signal login_nav_requested()

const AuthUiThemeClass = preload("res://src/ui/auth/auth_ui_theme.gd")

var _email_input: LineEdit = null
var _status_container: Control = null
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
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# 1. Official Logo
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

	var secondary_lbl: Label = Label.new()
	secondary_lbl.name = "SecondaryLabel"
	secondary_lbl.text = "KHÔI PHỤC MẬT KHẨU TÀI KHOẢN"
	secondary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secondary_lbl.add_theme_font_size_override("font_size", 11)
	secondary_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_CYAN_MUTED)
	vbox.add_child(secondary_lbl)

	# Description
	var desc_lbl: Label = Label.new()
	desc_lbl.text = "Nhập email đăng ký của bạn để nhận liên kết khôi phục quyền truy cập vào Học viện."
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_TEXT_BODY)
	vbox.add_child(desc_lbl)

	# 3. Email Input
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

	# 4. Reserved Status / Message Container (Prevents vertical jumping)
	_status_container = Control.new()
	_status_container.name = "StatusContainer"
	_status_container.custom_minimum_size = Vector2(0, 48)
	vbox.add_child(_status_container)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.visible = false
	_status_container.add_child(_status_label)

	# 5. Submit Button
	_submit_button = Button.new()
	_submit_button.name = "SubmitButton"
	_submit_button.text = "GỬI LIÊN KẾT KHÔI PHỤC"
	_submit_button.custom_minimum_size = Vector2(0, 44)
	AuthUiThemeClass.style_primary_button(_submit_button)
	vbox.add_child(_submit_button)

	# 6. Back Button
	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = "QUAY LẠI ĐĂNG NHẬP"
	_back_button.custom_minimum_size = Vector2(0, 36)
	AuthUiThemeClass.style_text_button(_back_button, true)
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
		_submit_button.text = "GỬI LIÊN KẾT KHÔI PHỤC"

func show_error(msg: String) -> void:
	_ensure_nodes()
	_status_label.text = msg
	_status_label.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_ERROR_TEXT)
	_status_label.visible = not msg.is_empty()

func show_success_anti_enumeration(msg: String = "") -> void:
	_ensure_nodes()
	var final_msg: String = msg if not msg.is_empty() else "Nếu email này tồn tại trong hệ thống, hướng dẫn đặt lại mật khẩu đã được gửi đến hòm thư của bạn."
	_status_label.text = final_msg
	_status_label.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_SUCCESS_TEXT)
	_status_label.visible = true

func clear_form() -> void:
	_ensure_nodes()
	if _email_input != null: _email_input.text = ""
	_status_label.visible = false

func _on_text_submitted(_new_text: String) -> void:
	if not _is_pending:
		_on_submit_pressed()

func _on_submit_pressed() -> void:
	_ensure_nodes()
	show_error("")
	var email: String = _email_input.text.strip_edges()
	if email.is_empty():
		show_error("Vui lòng nhập địa chỉ Email.")
		return

	forgot_password_submitted.emit(email)

func _on_back_pressed() -> void:
	_ensure_nodes()
	show_error("")
	login_nav_requested.emit()
