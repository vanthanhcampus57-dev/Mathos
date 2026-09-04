class_name ResetPasswordPanel
extends Control

## Production Reset Password Panel Component for Mathos Auth UI.
## Provides New Password & Confirm New Password inputs (secret mode with show/hide toggle),
## reset token storage supplied externally via typed setup method,
## client-side matching validation, reset submission,
## and Navigation back to Login styled in dark fantasy academic RPG visual direction.

signal reset_password_submitted(token: String, new_password: String)
signal login_nav_requested()
signal reset_password_succeeded()

const AuthUiThemeClass = preload("res://src/ui/auth/auth_ui_theme.gd")

var _reset_token: String = ""

var _password_input: LineEdit = null
var _confirm_password_input: LineEdit = null
var _password_toggle_button: Button = null
var _confirm_toggle_button: Button = null
var _status_container: Control = null
var _status_label: Label = null
var _submit_button: Button = null
var _back_button: Button = null

var _is_pending: bool = false

func _ready() -> void:
	_ensure_nodes()

func set_reset_token(token: String) -> void:
	_reset_token = token.strip_edges()

func get_reset_token() -> String:
	return _reset_token

func has_reset_token() -> bool:
	return not _reset_token.is_empty()

func _ensure_nodes() -> void:
	if _password_input == null:
		_build_ui_programmatically()
		_connect_signals()

func _connect_signals() -> void:
	if _submit_button != null and not _submit_button.pressed.is_connected(_on_submit_pressed):
		_submit_button.pressed.connect(_on_submit_pressed)
	if _back_button != null and not _back_button.pressed.is_connected(_on_back_pressed):
		_back_button.pressed.connect(_on_back_pressed)

	if _password_toggle_button != null and not _password_toggle_button.pressed.is_connected(_on_toggle_password_pressed):
		_password_toggle_button.pressed.connect(_on_toggle_password_pressed)
	if _confirm_toggle_button != null and not _confirm_toggle_button.pressed.is_connected(_on_toggle_confirm_pressed):
		_confirm_toggle_button.pressed.connect(_on_toggle_confirm_pressed)

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
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
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
	secondary_lbl.text = "ĐẶT LẠI MẬT KHẨU BẢO MẬT"
	secondary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secondary_lbl.add_theme_font_size_override("font_size", 11)
	secondary_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_CYAN_MUTED)
	vbox.add_child(secondary_lbl)

	# Description
	var desc_lbl: Label = Label.new()
	desc_lbl.text = "Thiết lập mật khẩu mới cho tài khoản pháp sư của bạn."
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_TEXT_BODY)
	vbox.add_child(desc_lbl)

	# 3. New Password Label & Input (with Toggle)
	var pass_lbl: Label = Label.new()
	pass_lbl.text = "MẬT KHẨU MỚI"
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

	# 4. Confirm New Password Label & Input (with Toggle)
	var confirm_lbl: Label = Label.new()
	confirm_lbl.text = "XÁC NHẬN MẬT KHẨU MỚI"
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
	_confirm_password_input.custom_minimum_size = Vector2(0, 42)
	_confirm_password_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	AuthUiThemeClass.style_line_edit(_confirm_password_input)
	confirm_container.add_child(_confirm_password_input)

	_confirm_toggle_button = Button.new()
	_confirm_toggle_button.name = "ConfirmToggleButton"
	_confirm_toggle_button.text = "👁"
	_confirm_toggle_button.custom_minimum_size = Vector2(42, 42)
	AuthUiThemeClass.style_secondary_button(_confirm_toggle_button)
	_confirm_toggle_button.tooltip_text = "Hiện / Ẩn mật khẩu"
	confirm_container.add_child(_confirm_toggle_button)

	# 5. Reserved Error / Status Space Container (Prevents vertical jumping)
	_status_container = Control.new()
	_status_container.name = "StatusContainer"
	_status_container.custom_minimum_size = Vector2(0, 36)
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

	# 6. Action: ĐẶT LẠI MẬT KHẨU
	_submit_button = Button.new()
	_submit_button.name = "SubmitButton"
	_submit_button.text = "ĐẶT LẠI MẬT KHẨU"
	_submit_button.custom_minimum_size = Vector2(0, 46)
	AuthUiThemeClass.style_primary_button(_submit_button)
	vbox.add_child(_submit_button)

	# 7. Action: QUAY LẠI ĐĂNG NHẬP
	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = "QUAY LẠI ĐĂNG NHẬP"
	_back_button.custom_minimum_size = Vector2(0, 34)
	AuthUiThemeClass.style_text_button(_back_button, true)
	vbox.add_child(_back_button)

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
	_password_input.editable = not pending
	_confirm_password_input.editable = not pending
	_submit_button.disabled = pending
	_back_button.disabled = pending
	if _password_toggle_button != null:
		_password_toggle_button.disabled = pending
	if _confirm_toggle_button != null:
		_confirm_toggle_button.disabled = pending

	if pending:
		_submit_button.text = "Đang cập nhật mật khẩu..."
	else:
		_submit_button.text = "ĐẶT LẠI MẬT KHẨU"

func show_error(msg: String) -> void:
	_ensure_nodes()
	_status_label.text = msg
	_status_label.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_ERROR_TEXT)
	_status_label.visible = not msg.is_empty()

func show_success(msg: String) -> void:
	_ensure_nodes()
	_status_label.text = msg
	_status_label.add_theme_color_override("font_color", AuthUiThemeClass.COLOR_SUCCESS_TEXT)
	_status_label.visible = not msg.is_empty()

func clear_form() -> void:
	_ensure_nodes()
	if _password_input != null: _password_input.text = ""
	if _confirm_password_input != null: _confirm_password_input.text = ""
	_status_label.visible = false

func _on_text_submitted(_new_text: String) -> void:
	if not _is_pending:
		_on_submit_pressed()

func _on_submit_pressed() -> void:
	_ensure_nodes()
	show_error("")

	if _reset_token.is_empty():
		show_error("Mã xác thực (Token) không hợp lệ hoặc bị thiếu.")
		return

	var pass_str: String = _password_input.text
	var confirm_str: String = _confirm_password_input.text

	if pass_str.is_empty():
		show_error("Vui lòng nhập Mật khẩu mới.")
		return
	if confirm_str.is_empty():
		show_error("Vui lòng xác nhận lại Mật khẩu mới.")
		return
	if pass_str != confirm_str:
		show_error("Mật khẩu xác nhận không khớp.")
		return

	reset_password_submitted.emit(_reset_token, pass_str)

func _on_back_pressed() -> void:
	_ensure_nodes()
	show_error("")
	login_nav_requested.emit()
