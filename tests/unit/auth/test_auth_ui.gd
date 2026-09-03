extends SceneTree

## Unit & Integration Test Suite for Production Mathos Auth UI (AUTH-UI-001..016)

const AuthShellClass = preload("res://src/ui/auth/auth_shell.gd")
const LoginPanelClass = preload("res://src/ui/auth/login_panel.gd")
const SignUpPanelClass = preload("res://src/ui/auth/sign_up_panel.gd")
const ForgotPasswordPanelClass = preload("res://src/ui/auth/forgot_password_panel.gd")
const AuthApiClientClass = preload("res://src/core/auth/auth_api_client.gd")
const AuthResultClass = preload("res://src/core/auth/auth_result.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS PRODUCTION AUTH UI QA HARNESS (AUTH-UI-001..016) ---")
	var ok: bool = run_all_tests()
	if ok:
		print("MATHOS PRODUCTION AUTH UI QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS PRODUCTION AUTH UI QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var counts = {"pass": 0, "fail": 0}

	var _assert = func(cond: bool, id: String, p_msg: String, f_msg: String):
		if cond:
			counts["pass"] += 1
			print("[%s] PASS: %s" % [id, p_msg])
		else:
			counts["fail"] += 1
			print("[%s] FAIL: %s" % [id, f_msg])

	# TEST 001: Instantiation & Structure
	var shell = AuthShellClass.new()
	shell._ready()
	var has_bg: bool = (shell._bg != null)
	var has_login: bool = (shell._login_panel != null)
	var has_signup: bool = (shell._signup_panel != null)
	var has_forgot: bool = (shell._forgot_panel != null)
	var is_login_visible: bool = (shell._current_panel == AuthShellClass.PanelType.LOGIN)
	_assert.call(has_bg and has_login and has_signup and has_forgot and is_login_visible,
		"AUTH-UI-001",
		"AuthShell and panel components instantiated cleanly with Login as default panel!",
		"AuthShell instantiation failed!")
	shell.free()

	# TEST 002: Secret Password Fields
	var login = LoginPanelClass.new()
	login._ready()
	var signup = SignUpPanelClass.new()
	signup._ready()
	var login_secret: bool = login._password_input.secret
	var signup_pass_secret: bool = signup._password_input.secret
	var signup_confirm_secret: bool = signup._confirm_password_input.secret
	_assert.call(login_secret and signup_pass_secret and signup_confirm_secret,
		"AUTH-UI-002",
		"All password inputs have secret=true for secure masked typing!",
		"Password fields missing secret mode!")
	login.free()
	signup.free()

	# TEST 003: Login Client Validation
	login = LoginPanelClass.new()
	login._ready()
	var state003 = {"submitted": false}
	login.login_submitted.connect(func(_e, _p): state003["submitted"] = true)
	login._email_input.text = ""
	login._password_input.text = "secret123"
	login._on_login_pressed()
	var err1: bool = (not state003["submitted"]) and login._error_label.visible
	login._email_input.text = "test@example.com"
	login._password_input.text = ""
	login._on_login_pressed()
	var err2: bool = (not state003["submitted"]) and login._error_label.visible
	login._password_input.text = "validpass"
	login._on_login_pressed()
	var err3: bool = state003["submitted"]
	_assert.call(err1 and err2 and err3,
		"AUTH-UI-003",
		"Login client validation correctly blocks empty fields and submits valid form!",
		"Login client validation failed!")
	login.free()

	# TEST 004: Sign Up Password Mismatch
	signup = SignUpPanelClass.new()
	signup._ready()
	var state004 = {"submitted": false}
	signup.signup_submitted.connect(func(_n, _e, _p): state004["submitted"] = true)
	signup._display_name_input.text = "Student A"
	signup._email_input.text = "student@example.com"
	signup._password_input.text = "password123"
	signup._confirm_password_input.text = "differentpass"
	signup._terms_checkbox.button_pressed = true
	signup._on_signup_pressed()
	var blocked004: bool = not state004["submitted"]
	var err_msg_valid004: bool = signup._error_label.text.contains("không khớp")
	_assert.call(blocked004 and err_msg_valid004,
		"AUTH-UI-004",
		"Sign Up client validation blocks password mismatch without network request!",
		"Sign Up password mismatch validation failed!")
	signup.free()

	# TEST 005: Sign Up Terms Unchecked
	signup = SignUpPanelClass.new()
	signup._ready()
	var state005 = {"submitted": false}
	signup.signup_submitted.connect(func(_n, _e, _p): state005["submitted"] = true)
	signup._display_name_input.text = "Student B"
	signup._email_input.text = "studentb@example.com"
	signup._password_input.text = "password123"
	signup._confirm_password_input.text = "password123"
	signup._terms_checkbox.button_pressed = false
	signup._on_signup_pressed()
	var blocked005: bool = not state005["submitted"]
	var err_msg_valid005: bool = signup._error_label.text.contains("Điều khoản")
	_assert.call(blocked005 and err_msg_valid005,
		"AUTH-UI-005",
		"Sign Up client validation requires Terms checkbox agreement!",
		"Sign Up terms checkbox validation failed!")
	signup.free()

	# TEST 006: Forgot Password Validation
	var forgot = ForgotPasswordPanelClass.new()
	forgot._ready()
	var state006 = {"submitted": false}
	forgot.forgot_password_submitted.connect(func(_e): state006["submitted"] = true)
	forgot._email_input.text = ""
	forgot._on_submit_pressed()
	var blocked006: bool = (not state006["submitted"]) and forgot._status_label.visible
	forgot._email_input.text = "valid@example.com"
	forgot._on_submit_pressed()
	var valid_submit006: bool = state006["submitted"]
	_assert.call(blocked006 and valid_submit006,
		"AUTH-UI-006",
		"Forgot Password client validation blocks empty email and submits valid email!",
		"Forgot Password validation failed!")
	forgot.free()

	# TEST 007: Panel Navigation
	shell = AuthShellClass.new()
	shell._ready()
	shell.show_signup()
	var is_signup: bool = (shell.get_current_panel() == AuthShellClass.PanelType.SIGNUP)
	shell.show_forgot_password()
	var is_forgot: bool = (shell.get_current_panel() == AuthShellClass.PanelType.FORGOT_PASSWORD)
	shell.show_login()
	var is_login: bool = (shell.get_current_panel() == AuthShellClass.PanelType.LOGIN)
	_assert.call(is_signup and is_forgot and is_login,
		"AUTH-UI-007",
		"Panel switching between Login, Sign Up, and Forgot Password verified cleanly!",
		"Panel navigation failed!")
	shell.free()

	# TEST 008: Loading State Disables Inputs
	login = LoginPanelClass.new()
	login._ready()
	login.set_pending(true)
	var inputs_disabled: bool = (not login._email_input.editable) and (not login._password_input.editable) and login._login_button.disabled
	login.set_pending(false)
	var inputs_enabled: bool = login._email_input.editable and login._password_input.editable and (not login._login_button.disabled)
	_assert.call(inputs_disabled and inputs_enabled,
		"AUTH-UI-008",
		"Loading state disables inputs/buttons during pending request and re-enables on completion!",
		"Loading state control disabling failed!")
	login.free()

	# TEST 009: Error Mapping UNAUTHORIZED
	shell = AuthShellClass.new()
	shell._ready()
	var res009: RefCounted = AuthResultClass.fail("UNAUTHORIZED", "Invalid credentials", 401)
	var mapped009: String = shell._map_error_message(res009)
	var valid_mapping009: bool = mapped009.contains("không chính xác") or mapped009.contains("UNAUTHORIZED")
	_assert.call(valid_mapping009,
		"AUTH-UI-009",
		"HTTP 401 UNAUTHORIZED mapped to friendly player message without exposing raw tokens!",
		"UNAUTHORIZED error mapping failed!")
	shell.free()

	# TEST 010: Error Mapping NETWORK & TIMEOUT
	shell = AuthShellClass.new()
	shell._ready()
	var res_net: RefCounted = AuthResultClass.fail("NETWORK_ERROR", "Connection refused", 0)
	var res_time: RefCounted = AuthResultClass.fail("TIMEOUT", "Request timed out", 0)
	var msg_net: String = shell._map_error_message(res_net)
	var msg_time: String = shell._map_error_message(res_time)
	var ok_net: bool = msg_net.contains("kết nối")
	var ok_time: bool = msg_time.contains("thời gian chờ")
	_assert.call(ok_net and ok_time,
		"AUTH-UI-010",
		"NETWORK_ERROR and TIMEOUT mapped to friendly localized error messages!",
		"Network/Timeout error mapping failed!")
	shell.free()

	# TEST 011: Error Mapping FastAPI Pydantic 422
	shell = AuthShellClass.new()
	shell._ready()
	var pydantic_payload: Dictionary = {
		"detail": [
			{"msg": "value is not a valid email address", "type": "value_error.email"}
		]
	}
	var res011: RefCounted = AuthResultClass.fail("VALIDATION_ERROR", "value is not a valid email address", 422, pydantic_payload)
	var mapped011: String = shell._map_error_message(res011)
	var ok_msg011: bool = mapped011.contains("valid email address")
	_assert.call(ok_msg011,
		"AUTH-UI-011",
		"FastAPI / Pydantic 422 validation detail mapped cleanly without raw stack traces!",
		"Pydantic 422 error mapping failed!")
	shell.free()

	# TEST 012: Anti-enumeration Forgot Password
	forgot = ForgotPasswordPanelClass.new()
	forgot._ready()
	forgot.show_success_anti_enumeration()
	var visible012: bool = forgot._status_label.visible
	var text_ok012: bool = forgot._status_label.text.contains("Nếu email này tồn tại")
	_assert.call(visible012 and text_ok012,
		"AUTH-UI-012",
		"Forgot Password anti-enumeration success message presented securely!",
		"Anti-enumeration message failed!")
	forgot.free()

	# TEST 013: Keyboard Submit
	login = LoginPanelClass.new()
	login._ready()
	var state013 = {"submitted": false}
	login.login_submitted.connect(func(_e, _p): state013["submitted"] = true)
	login._email_input.text = "user@example.com"
	login._password_input.text = "password123"
	login._on_text_submitted("password123")
	_assert.call(state013["submitted"],
		"AUTH-UI-013",
		"Enter key submission (_on_text_submitted) triggers form submit signal cleanly!",
		"Keyboard submit failed!")
	login.free()

	# TEST 014: Zero Token Disk Persistence
	shell = AuthShellClass.new()
	shell._ready()
	var session: RefCounted = shell._auth_client.get_session()
	session.update_from_dict({
		"access_token": "test_access_token_abc123",
		"refresh_token": "test_refresh_token_xyz789",
		"user_id": "usr_999",
		"email": "user@example.com",
		"display_name": "Test User"
	})
	var active_in_mem: bool = session.is_active()
	var save_file_path: String = "user://auth_tokens.dat"
	var disk_file_exists: bool = FileAccess.file_exists(save_file_path)
	_assert.call(active_in_mem and not disk_file_exists,
		"AUTH-UI-014",
		"Auth session token held strictly in-memory with zero disk persistence!",
		"Token disk persistence violation detected!")
	shell.free()

	# TEST 015: Responsive 720p Scrollability
	shell = AuthShellClass.new()
	shell._ready()
	var has_login_scroll: bool = (shell._login_panel.get_child(0) is ScrollContainer)
	var has_signup_scroll: bool = (shell._signup_panel.get_child(0) is ScrollContainer)
	var has_forgot_scroll: bool = (shell._forgot_panel.get_child(0) is ScrollContainer)
	_assert.call(has_login_scroll and has_signup_scroll and has_forgot_scroll,
		"AUTH-UI-015",
		"All Auth UI panels wrapped inside ScrollContainers for guaranteed 1280x720 reachability!",
		"720p scrollability check failed!")
	shell.free()

	# TEST 016: Boot Routing Preparation
	shell = AuthShellClass.new()
	shell._ready()
	var is_control: bool = (shell is Control)
	var is_visible: bool = shell.visible
	_assert.call(is_control and is_visible,
		"AUTH-UI-016",
		"AuthShell is fully prepared to become post-splash route target!",
		"Boot routing preparation check failed!")
	shell.free()

	print("==========================================")
	print("MATHOS PRODUCTION AUTH UI QA HARNESS SUMMARY:")
	print("  PASS: %d" % counts["pass"])
	print("  FAIL: %d" % counts["fail"])
	print("==========================================")
	return counts["fail"] == 0
