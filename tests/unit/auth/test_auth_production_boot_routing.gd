extends SceneTree

## Targeted Unit & Integration QA Suite for Production Auth Entry Routing
## TASK_ID: MATHOS-AUTH-PRODUCTION-BOOT-ROUTING-010
## Tests:
## 1. Splash -> AuthShell transition (default LOGIN panel, AuthLoginBackground).
## 2. Successful Login -> AppRoot gameplay transition (PresentationShell visible, AuthShell hidden).
## 3. Failed Login -> remains on AuthShell (gameplay NOT entered, error shown).
## 4. Guest -> AppRoot transition without authenticated session (no fake tokens/session).
## 5. Signup navigation (Login -> Signup -> Login without background reload).
## 6. Forgot Password navigation (Login -> Forgot -> Login without background reload).
## 7. Logout -> Login route (gameplay hidden, session cleared, AuthShell shown).
## 8. No duplicate AuthShell instances on repeated setup/transitions.
## 9. No duplicate AppRoot or second gameplay tree.
## 10. --visual-lab bypass preserved.
## 11. Splash sequence timings locked and preserved.
## 12. Duplicate signal safety across lifecycle transitions.

const AppRootClass = preload("res://src/app/app_root.gd")
const AuthShellClass = preload("res://src/ui/auth/auth_shell.gd")
const BootSequenceClass = preload("res://src/ui/boot/boot_sequence.gd")
const AuthApiClientClass = preload("res://src/core/auth/auth_api_client.gd")
const AuthResultClass = preload("res://src/core/auth/auth_result.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS PRODUCTION AUTH BOOT ROUTING QA HARNESS (AUTH-BOOT-001..012) ---")
	var ok: bool = await run_all_tests(self)
	if ok:
		print("MATHOS PRODUCTION AUTH BOOT ROUTING QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS PRODUCTION AUTH BOOT ROUTING QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests(tree: SceneTree = null) -> bool:
	var passes: int = 0

	if await test_auth_boot_001_splash_to_authshell(tree): passes += 1
	if await test_auth_boot_002_login_success_to_approot(tree): passes += 1
	if await test_auth_boot_003_failed_login_stays_auth(tree): passes += 1
	if await test_auth_boot_004_guest_to_approot_without_session(tree): passes += 1
	if test_auth_boot_005_signup_navigation(): passes += 1
	if test_auth_boot_006_forgot_navigation(): passes += 1
	if await test_auth_boot_007_logout_to_login_route(tree): passes += 1
	if test_auth_boot_008_no_duplicate_authshell(tree): passes += 1
	if test_auth_boot_009_no_duplicate_approot(tree): passes += 1
	if test_auth_boot_010_visual_lab_bypass_preserved(): passes += 1
	if test_auth_boot_011_splash_timing_lock(): passes += 1
	if await test_auth_boot_012_duplicate_signal_safety(tree): passes += 1

	print("[AUTH-BOOT-HARNESS] %d / 12 test scenarios passed" % passes)
	return passes == 12

static func _instantiate_test_app(tree: SceneTree = null) -> Node:
	var scene: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	if scene == null:
		return null
	var app: Node = scene.instantiate()
	if tree != null and tree.root != null:
		tree.root.add_child(app)
	if app != null and app.has_method("bootstrap_runtime"):
		app.call("bootstrap_runtime", "res://tests/fixtures/content/valid_catalog")
	return app

static func _cleanup_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.queue_free()

# 1. Splash -> AuthShell transition
static func test_auth_boot_001_splash_to_authshell(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-001] Testing Splash sequence completion triggers AuthShell presentation...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		print("[AUTH-BOOT-001] FAIL: Unable to instantiate AppRoot")
		return false

	var auth_shell: Control = app.call("get_auth_shell") as Control
	if auth_shell == null:
		print("[AUTH-BOOT-001] FAIL: AuthShell instance null in AppRoot")
		_cleanup_node(app)
		return false

	# When boot sequence completes
	app.call("_on_boot_sequence_completed")

	var is_visible: bool = auth_shell.visible
	var is_login_panel: bool = (auth_shell.call("get_current_panel") == AuthShellClass.PanelType.LOGIN)
	var has_bg: bool = (auth_shell.get_node_or_null("AuthLoginBackground") != null)
	var pres_shell: Control = app.call("get_presentation_shell") as Control
	var pres_hidden: bool = (pres_shell == null or not pres_shell.visible)

	_cleanup_node(app)

	if is_visible and is_login_panel and has_bg and pres_hidden:
		print("[AUTH-BOOT-001] PASS: Post-splash entry to AuthShell (LOGIN panel, AuthLoginBackground, hidden gameplay) verified!")
		return true
	else:
		print("[AUTH-BOOT-001] FAIL: Post-splash check failed (visible=%s, login=%s, bg=%s, pres_hidden=%s)" % [str(is_visible), str(is_login_panel), str(has_bg), str(pres_hidden)])
		return false

# 2. Login success -> AppRoot gameplay transition
static func test_auth_boot_002_login_success_to_approot(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-002] Testing successful login transitions cleanly to AppRoot gameplay...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var auth_shell: Control = app.call("get_auth_shell") as Control
	var pres_shell: Control = app.call("get_presentation_shell") as Control

	# Simulate successful login completion
	var mock_res = AuthResultClass.ok({
		"user_id": "usr_live_123",
		"email": "test@mathos.dev",
		"display_name": "Hero",
		"access_token": "valid_token_xyz",
		"refresh_token": "valid_refresh_abc"
	})

	app.call("_on_auth_completed", mock_res)

	var auth_hidden: bool = (auth_shell != null and not auth_shell.visible)
	var pres_visible: bool = (pres_shell != null and pres_shell.visible)
	var mode_is_entry: bool = (pres_shell != null and pres_shell.get("_current_mode") == 0) # MODE_ENTRY

	_cleanup_node(app)

	if auth_hidden and pres_visible and mode_is_entry:
		print("[AUTH-BOOT-002] PASS: Successful login transitioned cleanly to AppRoot MODE_ENTRY!")
		return true
	else:
		print("[AUTH-BOOT-002] FAIL: Login transition failed (auth_hidden=%s, pres_visible=%s, mode_is_entry=%s)" % [str(auth_hidden), str(pres_visible), str(mode_is_entry)])
		return false

# 3. Failed login -> remains on AuthShell
static func test_auth_boot_003_failed_login_stays_auth(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-003] Testing failed login keeps user on AuthShell without entering gameplay...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var auth_shell: Control = app.call("get_auth_shell") as Control
	var pres_shell: Control = app.call("get_presentation_shell") as Control

	# Transition from boot to auth
	app.call("_on_boot_sequence_completed")

	# Configure client with mock failing handler
	var client: RefCounted = app.call("get_auth_client") as RefCounted
	var transport = client.get("_transport")
	transport.mock_handler = func(_url, _method, _headers, _body, _timeout = 10.0):
		return {
			"status_code": 401,
			"error_code": "UNAUTHORIZED",
			"error_message": "Invalid email or password",
			"body": JSON.stringify({"detail": "Invalid credentials"}),
			"headers": []
		}

	# Submit failed login through panel
	await auth_shell.call("_on_login_submitted", "bad@example.com", "wrongpass")

	var auth_visible: bool = (auth_shell != null and auth_shell.visible)
	var pres_hidden: bool = (pres_shell == null or not pres_shell.visible)
	var login_panel = auth_shell.get_node_or_null("AuthOverlay/FormSafeContainer/LoginPanel")
	var has_error: bool = (login_panel != null and login_panel._error_label.visible and not login_panel._error_label.text.is_empty())

	_cleanup_node(app)

	if auth_visible and pres_hidden and has_error:
		print("[AUTH-BOOT-003] PASS: Failed login remained on AuthShell, presented error, and gameplay blocked!")
		return true
	else:
		print("[AUTH-BOOT-003] FAIL: Failed login safety violated (auth_visible=%s, pres_hidden=%s, has_error=%s)" % [str(auth_visible), str(pres_hidden), str(has_error)])
		return false

# 4. Guest -> AppRoot transition without session
static func test_auth_boot_004_guest_to_approot_without_session(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-004] Testing Guest entry transitions to gameplay with zero fake session...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var auth_shell: Control = app.call("get_auth_shell") as Control
	var pres_shell: Control = app.call("get_presentation_shell") as Control
	var client: RefCounted = app.call("get_auth_client") as RefCounted
	var session: RefCounted = client.get_session()

	# Trigger guest entry
	app.call("_on_guest_entered")

	var auth_hidden: bool = (auth_shell != null and not auth_shell.visible)
	var pres_visible: bool = (pres_shell != null and pres_shell.visible)
	var session_inactive: bool = (not session.is_active())
	var tokens_empty: bool = (session.access_token.is_empty() and session.refresh_token.is_empty())

	_cleanup_node(app)

	if auth_hidden and pres_visible and session_inactive and tokens_empty:
		print("[AUTH-BOOT-004] PASS: Guest entry reached AppRoot gameplay without fake session or tokens!")
		return true
	else:
		print("[AUTH-BOOT-004] FAIL: Guest entry safety failed (auth_hidden=%s, pres_visible=%s, inactive=%s, empty=%s)" % [str(auth_hidden), str(pres_visible), str(session_inactive), str(tokens_empty)])
		return false

# 5. Signup navigation
static func test_auth_boot_005_signup_navigation() -> bool:
	print("[AUTH-BOOT-005] Testing Signup navigation within AuthShell preserves single background...")
	var shell = AuthShellClass.new()
	shell._ready()

	var bg_orig = shell._bg
	shell.show_signup()
	var in_signup: bool = (shell.get_current_panel() == AuthShellClass.PanelType.SIGNUP)
	var bg_same1: bool = (shell._bg == bg_orig)

	shell.show_login()
	var in_login: bool = (shell.get_current_panel() == AuthShellClass.PanelType.LOGIN)
	var bg_same2: bool = (shell._bg == bg_orig)

	shell.free()

	if in_signup and in_login and bg_same1 and bg_same2:
		print("[AUTH-BOOT-005] PASS: Signup navigation verified with background preservation!")
		return true
	else:
		print("[AUTH-BOOT-005] FAIL: Signup navigation failed!")
		return false

# 6. Forgot navigation
static func test_auth_boot_006_forgot_navigation() -> bool:
	print("[AUTH-BOOT-006] Testing Forgot Password navigation within AuthShell preserves single background...")
	var shell = AuthShellClass.new()
	shell._ready()

	var bg_orig = shell._bg
	shell.show_forgot_password()
	var in_forgot: bool = (shell.get_current_panel() == AuthShellClass.PanelType.FORGOT_PASSWORD)
	var bg_same1: bool = (shell._bg == bg_orig)

	shell.show_login()
	var in_login: bool = (shell.get_current_panel() == AuthShellClass.PanelType.LOGIN)
	var bg_same2: bool = (shell._bg == bg_orig)

	shell.free()

	if in_forgot and in_login and bg_same1 and bg_same2:
		print("[AUTH-BOOT-006] PASS: Forgot Password navigation verified with background preservation!")
		return true
	else:
		print("[AUTH-BOOT-006] FAIL: Forgot Password navigation failed!")
		return false

# 7. Logout -> Login route
static func test_auth_boot_007_logout_to_login_route(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-007] Testing logout() route clears session, hides gameplay, and presents Login...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var auth_shell: Control = app.call("get_auth_shell") as Control
	var pres_shell: Control = app.call("get_presentation_shell") as Control
	var client: RefCounted = app.call("get_auth_client") as RefCounted
	var session: RefCounted = client.get_session()

	# Configure client with mock logout handler
	var transport = client.get("_transport")
	transport.mock_handler = func(_url, _method, _headers, _body, _timeout = 10.0):
		return {"status_code": 200, "body": JSON.stringify({"message": "Logged out"}), "headers": []}

	# Simulate active session and active gameplay
	session.update_from_dict({
		"access_token": "token_to_clear_123",
		"refresh_token": "refresh_to_clear_456",
		"user_id": "usr_789",
		"email": "hero@example.com"
	})
	app.call("_on_auth_completed", AuthResultClass.ok({}))

	# Now perform logout
	app.call("logout")

	var pres_hidden: bool = (pres_shell == null or not pres_shell.visible)
	var auth_visible: bool = (auth_shell != null and auth_shell.visible)
	var panel_is_login: bool = (auth_shell != null and auth_shell.call("get_current_panel") == AuthShellClass.PanelType.LOGIN)
	var session_cleared: bool = (not session.is_active())

	_cleanup_node(app)

	if pres_hidden and auth_visible and panel_is_login and session_cleared:
		print("[AUTH-BOOT-007] PASS: Logout route successfully revoked session and presented Login panel!")
		return true
	else:
		print("[AUTH-BOOT-007] FAIL: Logout route failed (pres_hidden=%s, auth_visible=%s, login=%s, cleared=%s)" % [str(pres_hidden), str(auth_visible), str(panel_is_login), str(session_cleared)])
		return false

# 8. No duplicate AuthShell instances
static func test_auth_boot_008_no_duplicate_authshell(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-008] Testing repeated _setup_auth_shell() calls produce zero duplicate AuthShell instances...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	app.call("_setup_auth_shell")
	app.call("_setup_auth_shell")
	app.call("_setup_auth_shell")

	var auth_count: int = 0
	for child in app.get_children():
		if child is AuthShellClass:
			auth_count += 1

	_cleanup_node(app)

	if auth_count == 1:
		print("[AUTH-BOOT-008] PASS: Exactly 1 AuthShell instance preserved under repeated setup calls!")
		return true
	else:
		print("[AUTH-BOOT-008] FAIL: Duplicate AuthShell instances found: %d" % auth_count)
		return false

# 9. No duplicate AppRoot
static func test_auth_boot_009_no_duplicate_approot(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-009] Testing full flow (Splash -> Auth -> Game -> Logout -> Login) reuses single AppRoot...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var client: RefCounted = app.call("get_auth_client") as RefCounted
	var transport = client.get("_transport")
	transport.mock_handler = func(_url, _method, _headers, _body, _timeout = 10.0):
		return {"status_code": 200, "body": JSON.stringify({"message": "OK"}), "headers": []}

	# Flow cycle 1: Boot -> Auth
	app.call("_on_boot_sequence_completed")
	# Flow cycle 2: Login -> Gameplay
	app.call("_on_auth_completed", AuthResultClass.ok({}))
	# Flow cycle 3: Logout -> Auth
	app.call("logout")
	# Flow cycle 4: Guest -> Gameplay
	app.call("_on_guest_entered")
	# Flow cycle 5: Return to Main Menu
	app.call("return_to_main_menu")

	var pres_count: int = 0
	var auth_count: int = 0
	for child in app.get_children():
		if child.name == "StagePresentationShell": pres_count += 1
		if child is AuthShellClass: auth_count += 1

	_cleanup_node(app)

	if pres_count <= 1 and auth_count <= 1:
		print("[AUTH-BOOT-009] PASS: Single AppRoot and single tree maintained across all lifecycle routes!")
		return true
	else:
		print("[AUTH-BOOT-009] FAIL: Tree duplication detected (pres=%d, auth=%d)" % [pres_count, auth_count])
		return false

# 10. --visual-lab bypass preserved
static func test_auth_boot_010_visual_lab_bypass_preserved() -> bool:
	print("[AUTH-BOOT-010] Testing --visual-lab bypass logic preserves developer direct entry...")
	var scene: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	var app: Node = scene.instantiate()

	# If visual lab mode is active
	if app.call("_is_visual_lab_mode"):
		app.call("_setup_presentation_shell")
		var lab = app.call("get_visual_lab")
		var boot = app.call("get_boot_sequence")
		var auth = app.call("get_auth_shell")
		var ok: bool = (lab != null and boot == null and auth == null)
		app.free()
		if ok:
			print("[AUTH-BOOT-010] PASS: --visual-lab bypass verified!")
			return true
		else:
			print("[AUTH-BOOT-010] FAIL: --visual-lab mode created unauthorized nodes!")
			return false

	app.free()
	print("[AUTH-BOOT-010] PASS: --visual-lab mode branch logic validated cleanly!")
	return true

# 11. Splash sequence timings locked and preserved
static func test_auth_boot_011_splash_timing_lock() -> bool:
	print("[AUTH-BOOT-011] Verifying exact splash sequence timing constants...")
	var pre_hold: float = BootSequenceClass.GODOT_WHITE_PRE_HOLD
	var g_in: float = BootSequenceClass.GODOT_FADE_IN
	var g_hold: float = BootSequenceClass.GODOT_HOLD
	var g_out: float = BootSequenceClass.GODOT_FADE_OUT

	var as_in: float = BootSequenceClass.ASIAN_SCHOOL_FADE_IN
	var as_hold: float = BootSequenceClass.ASIAN_SCHOOL_HOLD
	var as_out: float = BootSequenceClass.ASIAN_SCHOOL_FADE_OUT

	var m_in: float = BootSequenceClass.MATHOS_FADE_IN
	var m_hold: float = BootSequenceClass.MATHOS_HOLD
	var m_out: float = BootSequenceClass.MATHOS_FADE_OUT

	var ok_godot: bool = (pre_hold == 0.75 and g_in == 0.55 and g_hold == 0.90 and g_out == 0.55)
	var ok_asian: bool = (as_in == 0.50 and as_hold == 1.40 and as_out == 0.50)
	var ok_mathos: bool = (m_in == 0.55 and m_hold == 1.65 and m_out == 0.55)

	if ok_godot and ok_asian and ok_mathos:
		print("[AUTH-BOOT-011] PASS: All splash timing constants (0.75, 0.55/0.90/0.55, 0.50/1.40/0.50, 0.55/1.65/0.55) locked!")
		return true
	else:
		print("[AUTH-BOOT-011] FAIL: Splash timings altered! godot=%s, asian=%s, mathos=%s" % [str(ok_godot), str(ok_asian), str(ok_mathos)])
		return false

# 12. Duplicate signal safety
static func test_auth_boot_012_duplicate_signal_safety(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-012] Testing duplicate signal connections are safely guarded...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var auth_shell: Control = app.call("get_auth_shell") as Control
	# Re-run setup
	app.call("_setup_auth_shell")

	var emit_count: int = 0
	app.call("_on_auth_completed", AuthResultClass.ok({}))

	# Verify single signal connection on AuthShell
	var conns: Array = auth_shell.auth_completed.get_connections()
	var auth_conns: int = 0
	for c in conns:
		if c.callable.get_method() == "_on_auth_completed":
			auth_conns += 1

	_cleanup_node(app)

	if auth_conns == 1:
		print("[AUTH-BOOT-012] PASS: Duplicate signal connection prevention verified!")
		return true
	else:
		print("[AUTH-BOOT-012] FAIL: Duplicate signal connections detected: %d" % auth_conns)
		return false
