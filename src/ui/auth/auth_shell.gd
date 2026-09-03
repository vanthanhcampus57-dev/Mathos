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
	FORGOT_PASSWORD
}

const AuthApiClientClass = preload("res://src/core/auth/auth_api_client.gd")
const AuthLoginBgClass = preload("res://src/ui/auth/auth_login_background.gd")
const LoginPanelClass = preload("res://src/ui/auth/login_panel.gd")
const SignUpPanelClass = preload("res://src/ui/auth/sign_up_panel.gd")
const ForgotPasswordPanelClass = preload("res://src/ui/auth/forgot_password_panel.gd")

# Nodes
var _bg: Control = null
var _form_container: PanelContainer = null
var _login_panel: Control = null
var _signup_panel: Control = null
var _forgot_panel: Control = null

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

func _ensure_nodes() -> void:
	if _bg != null:
		return

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 1. Background Component
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
	_form_container.custom_minimum_size = Vector2(420, 520)
	_form_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	_form_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# Position in right 45% safe zone
	_form_container.anchor_left = 0.52
	_form_container.anchor_top = 0.08
	_form_container.anchor_right = 0.94
	_form_container.anchor_bottom = 0.92
	_form_container.offset_left = 0
	_form_container.offset_top = 0
	_form_container.offset_right = 0
	_form_container.offset_bottom = 0

	# Dark Translucent Panel Styling
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.14, 0.90)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.5, 0.8, 0.4)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 12
	_form_container.add_theme_stylebox_override("panel", style)
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

	_connect_panel_signals()
	show_panel(PanelType.LOGIN)

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

func show_panel(panel_type: PanelType) -> void:
	_ensure_nodes()
	_current_panel = panel_type

	_login_panel.visible = (panel_type == PanelType.LOGIN)
	_signup_panel.visible = (panel_type == PanelType.SIGNUP)
	_forgot_panel.visible = (panel_type == PanelType.FORGOT_PASSWORD)

func show_login() -> void:
	show_panel(PanelType.LOGIN)

func show_signup() -> void:
	show_panel(PanelType.SIGNUP)

func show_forgot_password() -> void:
	show_panel(PanelType.FORGOT_PASSWORD)

func get_current_panel() -> PanelType:
	return _current_panel

# --- API HANDLERS ---
func _on_login_submitted(email: String, pass_str: String) -> void:
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

	match code:
		"NETWORK_ERROR":
			return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng."
		"TIMEOUT":
			return "Yêu cầu quá thời gian chờ (Timeout). Vui lòng thử lại."
		"UNAUTHORIZED":
			return "Email hoặc mật khẩu không chính xác."
		"VALIDATION_ERROR":
			return result.message if not result.message.is_empty() else "Thông tin tài khoản không hợp lệ."
		"SERVER_ERROR":
			return "Lỗi máy chủ (%d). Vui lòng thử lại sau." % status
		_:
			return result.message if not result.message.is_empty() else "Yêu cầu thất bại."
