class_name AuthShell
extends Control

## Production Auth Shell Component for Mathos Engine.
## Houses AuthLoginBackground, manages responsive right-hand form container,
## handles panel switching (Login, Sign Up, Forgot Password),
## binds to typed AuthApiClient, and enforces zero token persistence and clean error UX.

signal auth_completed(result: RefCounted)
signal guest_entered()

enum PanelType {
	LOGIN,
	SIGNUP,
	FORGOT_PASSWORD,
	RESET_PASSWORD
}

const AuthApiClientClass = preload("res://src/core/auth/auth_api_client.gd")
const AuthLoginBgClass = preload("res://src/ui/auth/auth_login_background.gd")
const LoginPanelClass = preload("res://src/ui/auth/login_panel.gd")
const SignUpPanelClass = preload("res://src/ui/auth/sign_up_panel.gd")
const ForgotPasswordPanelClass = preload("res://src/ui/auth/forgot_password_panel.gd")
const ResetPasswordPanelClass = preload("res://src/ui/auth/reset_password_panel.gd")

const AuthUiThemeClass = preload("res://src/ui/auth/auth_ui_theme.gd")

# Minimal mock boundary class for ResetPasswordPanel contract when Agent3 panel is not yet present
class MinimalResetPasswordPanelBoundary extends Control:
	signal reset_password_submitted(token: String, new_password: String)
	signal login_nav_requested()

	var _token: String = ""

	func set_reset_token(token: String) -> void:
		_token = token

	func get_reset_token() -> String:
		return _token

	var _last_error: String = ""

	func clear_form() -> void:
		_token = ""
		_last_error = ""

	func set_pending(_pending: bool) -> void:
		pass

	func show_error(msg: String) -> void:
		_last_error = msg

	func get_error_message() -> String:
		return _last_error

# Nodes
var _bg: Control = null
var _form_container: PanelContainer = null
var _login_panel: Control = null
var _signup_panel: Control = null
var _forgot_panel: Control = null
var _reset_panel: Control = null
var _dev_inspector: PanelContainer = null
var _dev_inspector_enabled: bool = false

# Auth API Client Instance
var _auth_client: RefCounted = null
var _current_panel: PanelType = PanelType.LOGIN

func _ready() -> void:
	if _auth_client == null:
		_auth_client = AuthApiClientClass.new()
	_ensure_nodes()

func set_auth_client(client: RefCounted) -> void:
	if client != null:
		_auth_client = client

func get_auth_client() -> RefCounted:
	return _auth_client

func set_dev_inspector_visible(enable: bool) -> void:
	_dev_inspector_enabled = enable
	if _dev_inspector != null:
		_dev_inspector.visible = enable

func is_dev_inspector_visible() -> bool:
	return _dev_inspector != null and _dev_inspector.visible

func _ensure_nodes() -> void:
	if _bg != null:
		return

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 1. Background Component (Production asset with parallax/particles)
	_bg = AuthLoginBgClass.new()
	_bg.name = "AuthLoginBackground"
	add_child(_bg)

	# 2. Right-Side Form Overlay Safe Area Container
	var overlay: Control = Control.new()
	overlay.name = "AuthOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(overlay)

	_form_container = PanelContainer.new()
	_form_container.name = "FormSafeContainer"
	_form_container.custom_minimum_size = Vector2(400, 520)
	_form_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	_form_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# Position in right safe zone (x in [0.56, 0.96]), leaving academy focal art visible on left/center
	_form_container.anchor_left = 0.56
	_form_container.anchor_top = 0.05
	_form_container.anchor_right = 0.96
	_form_container.anchor_bottom = 0.95
	_form_container.offset_left = 0
	_form_container.offset_top = 0
	_form_container.offset_right = 0
	_form_container.offset_bottom = 0

	# Dark Navy Translucent Panel with Arcane Border & Subtle Glow
	_form_container.add_theme_stylebox_override("panel", AuthUiThemeClass.create_auth_panel_stylebox())
	overlay.add_child(_form_container)

	# 3. Instantiate Panels
	_login_panel = LoginPanelClass.new()
	_login_panel.name = "LoginPanel"
	_login_panel._ensure_nodes()
	_form_container.add_child(_login_panel)

	_signup_panel = SignUpPanelClass.new()
	_signup_panel.name = "SignUpPanel"
	_signup_panel._ensure_nodes()
	_form_container.add_child(_signup_panel)

	_forgot_panel = ForgotPasswordPanelClass.new()
	_forgot_panel.name = "ForgotPasswordPanel"
	_forgot_panel._ensure_nodes()
	_form_container.add_child(_forgot_panel)

	if _reset_panel == null:
		_reset_panel = ResetPasswordPanelClass.new()
	_reset_panel.name = "ResetPasswordPanel"
	if _reset_panel.has_method("_ensure_nodes"):
		_reset_panel.call("_ensure_nodes")
	if _reset_panel.get_parent() != _form_container:
		_form_container.add_child(_reset_panel)

	# 4. Dev State Inspector (Strictly hidden by default in production)
	_build_dev_inspector(overlay)

	_connect_panel_signals()
	show_panel(PanelType.LOGIN)

func _build_dev_inspector(parent: Control) -> void:
	if _dev_inspector != null:
		return

	_dev_inspector = PanelContainer.new()
	_dev_inspector.name = "DevStateInspector"
	_dev_inspector.custom_minimum_size = Vector2(260, 220)
	_dev_inspector.anchor_left = 0.02
	_dev_inspector.anchor_top = 0.04
	_dev_inspector.anchor_right = 0.26
	_dev_inspector.anchor_bottom = 0.42
	_dev_inspector.offset_left = 0
	_dev_inspector.offset_top = 0
	_dev_inspector.offset_right = 0
	_dev_inspector.offset_bottom = 0

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.09, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.5, 0.7, 0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	_dev_inspector.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_dev_inspector.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.name = "InspectorTitle"
	title.text = "GODOT STATE INSPECTOR: PRODUCTION AUTH CONTROLLER"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
	vbox.add_child(title)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	var btn_names: Array[String] = [
		"Default", "Email Focus",
		"Pass Focus", "Bad Creds",
		"Validation", "Network Err",
		"Loading UI"
	]

	for b_name in btn_names:
		var btn: Button = Button.new()
		btn.name = "Btn_" + b_name.replace(" ", "")
		btn.text = b_name
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_dev_inspector_button_pressed.bind(b_name))
		grid.add_child(btn)

	parent.add_child(_dev_inspector)

	# Production requirement: Gated behind dev flag or test harness toggle.
	var cmdline: PackedStringArray = OS.get_cmdline_args()
	var flag_enabled: bool = cmdline.has("--auth-dev-inspector") or cmdline.has("--dev")
	_dev_inspector.visible = flag_enabled or _dev_inspector_enabled

func _on_dev_inspector_button_pressed(action: String) -> void:
	match action:
		"Default":
			if _login_panel != null:
				_login_panel.clear_form()
				_login_panel.set_pending(false)
		"Email Focus":
			if _login_panel != null and _login_panel._email_input != null:
				_login_panel._email_input.grab_focus()
		"Pass Focus":
			if _login_panel != null and _login_panel._password_input != null:
				_login_panel._password_input.grab_focus()
		"Bad Creds":
			if _login_panel != null:
				_login_panel.show_error("Email hoặc mật khẩu không chính xác.")
		"Validation":
			if _login_panel != null:
				_login_panel.show_error("Vui lòng nhập địa chỉ Email.")
		"Network Err":
			if _login_panel != null:
				_login_panel.show_error("Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.")
		"Loading UI":
			if _login_panel != null:
				_login_panel.set_pending(not _login_panel._is_pending)

func _connect_panel_signals() -> void:
	# Login Signals
	if not _login_panel.login_submitted.is_connected(_on_login_submitted):
		_login_panel.login_submitted.connect(_on_login_submitted)
	if not _login_panel.forgot_password_requested.is_connected(show_forgot_password):
		_login_panel.forgot_password_requested.connect(show_forgot_password)
	if not _login_panel.sign_up_requested.is_connected(show_signup):
		_login_panel.sign_up_requested.connect(show_signup)
	if not _login_panel.guest_login_requested.is_connected(_on_guest_login_requested):
		_login_panel.guest_login_requested.connect(_on_guest_login_requested)

	# Sign Up Signals
	if not _signup_panel.signup_submitted.is_connected(_on_signup_submitted):
		_signup_panel.signup_submitted.connect(_on_signup_submitted)
	if not _signup_panel.login_nav_requested.is_connected(show_login):
		_signup_panel.login_nav_requested.connect(show_login)

	# Forgot Password Signals
	if not _forgot_panel.forgot_password_submitted.is_connected(_on_forgot_password_submitted):
		_forgot_panel.forgot_password_submitted.connect(_on_forgot_password_submitted)
	if not _forgot_panel.login_nav_requested.is_connected(show_login):
		_forgot_panel.login_nav_requested.connect(show_login)

	# Reset Password Signals
	if _reset_panel != null:
		if _reset_panel.has_signal("reset_password_submitted") and not _reset_panel.is_connected("reset_password_submitted", _on_reset_password_submitted):
			_reset_panel.connect("reset_password_submitted", _on_reset_password_submitted)
		if _reset_panel.has_signal("login_nav_requested") and not _reset_panel.is_connected("login_nav_requested", _on_reset_login_nav_requested):
			_reset_panel.connect("login_nav_requested", _on_reset_login_nav_requested)

func show_panel(panel_type: PanelType) -> void:
	_ensure_nodes()
	_current_panel = panel_type

	_login_panel.visible = (panel_type == PanelType.LOGIN)
	_signup_panel.visible = (panel_type == PanelType.SIGNUP)
	_forgot_panel.visible = (panel_type == PanelType.FORGOT_PASSWORD)
	if _reset_panel != null:
		_reset_panel.visible = (panel_type == PanelType.RESET_PASSWORD)

func show_login() -> void:
	clear_reset_token()
	show_panel(PanelType.LOGIN)

func show_signup() -> void:
	clear_reset_token()
	show_panel(PanelType.SIGNUP)

func show_forgot_password() -> void:
	clear_reset_token()
	show_panel(PanelType.FORGOT_PASSWORD)

func show_reset_password(token: String = "") -> void:
	_ensure_nodes()
	if not token.is_empty():
		set_reset_token(token)
	show_panel(PanelType.RESET_PASSWORD)

func set_reset_token(token: String) -> void:
	_ensure_nodes()
	if _reset_panel != null and _reset_panel.has_method("set_reset_token"):
		_reset_panel.call("set_reset_token", token)

func get_reset_token() -> String:
	_ensure_nodes()
	if _reset_panel != null and _reset_panel.has_method("get_reset_token"):
		return String(_reset_panel.call("get_reset_token"))
	return ""

func clear_reset_token() -> void:
	_ensure_nodes()
	if _reset_panel != null:
		if _reset_panel.has_method("set_reset_token"):
			_reset_panel.call("set_reset_token", "")
		if _reset_panel.has_method("clear_form"):
			_reset_panel.call("clear_form")

func get_reset_panel() -> Control:
	_ensure_nodes()
	return _reset_panel

func set_reset_panel(panel: Control) -> void:
	_ensure_nodes()
	if _reset_panel != null and _reset_panel != panel:
		if _reset_panel.get_parent() == _form_container:
			_form_container.remove_child(_reset_panel)
		_reset_panel.queue_free()
	_reset_panel = panel
	if _reset_panel != null:
		_reset_panel.name = "ResetPasswordPanel"
		if _reset_panel.get_parent() != _form_container:
			_form_container.add_child(_reset_panel)
		_connect_panel_signals()

func get_current_panel() -> PanelType:
	return _current_panel

func _on_reset_login_nav_requested() -> void:
	clear_reset_token()
	show_login()

func _on_reset_password_submitted(token: String, new_pass: String) -> void:
	_ensure_nodes()
	if _reset_panel != null and _reset_panel.has_method("set_pending"):
		_reset_panel.call("set_pending", true)

	var result = await _auth_client.reset_password(token, new_pass)

	if _reset_panel != null and _reset_panel.has_method("set_pending"):
		_reset_panel.call("set_pending", false)

	if result != null and result.success:
		clear_reset_token()
		show_login()
	else:
		var err_msg: String = _map_error_message(result)
		if _reset_panel != null and _reset_panel.has_method("show_error"):
			_reset_panel.call("show_error", err_msg)

# --- API HANDLERS ---
func _on_login_submitted(email: String, pass_str: String) -> void:
	_ensure_nodes()
	_login_panel.set_pending(true)
	var result = await _auth_client.login(email, pass_str)
	_login_panel.set_pending(false)

	if result.success:
		_login_panel.clear_form()
		auth_completed.emit(result)
	else:
		var err_msg: String = _map_error_message(result)
		_login_panel.show_error(err_msg)

func _on_signup_submitted(dname: String, email: String, pass_str: String) -> void:
	_ensure_nodes()
	_signup_panel.set_pending(true)
	var result = await _auth_client.register_account(dname, email, pass_str)
	_signup_panel.set_pending(false)

	if result.success:
		_signup_panel.clear_form()
		_login_panel.set_email(email)
		show_login()
		_login_panel.show_error("")
		_on_login_submitted(email, pass_str)
	else:
		var err_msg: String = _map_error_message(result)
		_signup_panel.show_error(err_msg)

func _on_forgot_password_submitted(email: String) -> void:
	_ensure_nodes()
	_forgot_panel.set_pending(true)
	var result = await _auth_client.forgot_password(email)
	_forgot_panel.set_pending(false)

	_forgot_panel.show_success_anti_enumeration()

func _on_guest_login_requested() -> void:
	guest_entered.emit()

# --- BACKEND ERROR UX MAPPER ---
func _map_error_message(result: RefCounted) -> String:
	if result == null:
		return "Đã xảy ra lỗi không xác định."

	var code: String = result.error_code if "error_code" in result else ""
	var status: int = result.http_status if "http_status" in result else 0
	var msg: String = result.message if "message" in result else ""

	if msg.to_lower().contains("expired") or msg.to_lower().contains("invalid token") or code == "INVALID_TOKEN":
		return "Mã khôi phục không hợp lệ hoặc đã hết hạn."

	match code:
		"NETWORK_ERROR":
			return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng."
		"TIMEOUT":
			return "Yêu cầu quá thời gian chờ (Timeout). Vui lòng thử lại."
		"UNAUTHORIZED":
			return "Email hoặc mật khẩu không chính xác."
		"VALIDATION_ERROR":
			return msg if not msg.is_empty() else "Thông tin tài khoản không hợp lệ."
		"SERVER_ERROR":
			return "Lỗi máy chủ (%d). Vui lòng thử lại sau." % status
		_:
			return msg if not msg.is_empty() else "Yêu cầu thất bại."
