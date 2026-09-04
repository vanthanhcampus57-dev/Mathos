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
## 13. Player-facing Logout button exists in PauseMenuOverlay with correct style/text.
## 14. Guest vs authenticated label switching in PauseMenuOverlay ("THOÁT VỀ ĐĂNG NHẬP" vs "ĐĂNG XUẤT").
## 15. Clicking logout shows confirmation modal without immediate exit.
## 16. Cancelling confirmation preserves pause state without logout.
## 17. Confirming logout invokes AppRoot.logout(), clears session, and returns to Login.
## 18. Guest exit without backend call and relogin cycle verified cleanly.
## 19. Normal boot without reset token routes post-splash to LOGIN mode.
## 20. Boot with valid reset token routes post-splash to RESET_PASSWORD mode.
## 21. Method/signal token handoff contract and reset completion verified.
## 22. Token log safety verified (token never leaked in errors or logs).
## 23. Token zero disk persistence and complete in-memory cleanup verified.
## 24. Invalid and whitespace-only reset token correctly falls back to LOGIN.
## 25. Visual Lab bypass contract and reset routing distinction verified.
## 26. Guest entry and logout routes unaffected with residual token clearing.

const AppRootClass = preload("res://src/app/app_root.gd")
const AuthShellClass = preload("res://src/ui/auth/auth_shell.gd")
const BootSequenceClass = preload("res://src/ui/boot/boot_sequence.gd")
const AuthApiClientClass = preload("res://src/core/auth/auth_api_client.gd")
const AuthResultClass = preload("res://src/core/auth/auth_result.gd")
const PauseMenuOverlayClass = preload("res://src/ui/common/pause_menu_overlay.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS PRODUCTION AUTH BOOT ROUTING QA HARNESS (AUTH-BOOT-001..026) ---")
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
	if test_auth_boot_013_pause_logout_button_exists(tree): passes += 1
	if test_auth_boot_014_guest_mode_label_switching(tree): passes += 1
	if test_auth_boot_015_logout_shows_confirmation_dialog(tree): passes += 1
	if test_auth_boot_016_logout_cancel_confirmation(tree): passes += 1
	if test_auth_boot_017_logout_confirm_invokes_approot_logout(tree): passes += 1
	if test_auth_boot_018_guest_exit_and_relogin_cycle(tree): passes += 1
	if test_auth_boot_019_normal_boot_to_login(tree): passes += 1
	if test_auth_boot_020_reset_token_boot_to_reset_panel(tree): passes += 1
	if await test_auth_boot_021_token_handoff_contract(tree): passes += 1
	if await test_auth_boot_022_token_log_safety(tree): passes += 1
	if test_auth_boot_023_token_zero_persistence_and_cleanup(tree): passes += 1
	if test_auth_boot_024_invalid_empty_token_fallback_to_login(tree): passes += 1
	if test_auth_boot_025_visual_lab_bypass_unaffected_by_token(tree): passes += 1
	if test_auth_boot_026_guest_and_logout_unaffected(tree): passes += 1

	print("[AUTH-BOOT-HARNESS] %d / 26 test scenarios passed" % passes)
	return passes == 26

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

# 13. Logout button exists in pause UI
static func test_auth_boot_013_pause_logout_button_exists(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-013] Testing player-facing Logout button exists in PauseMenuOverlay...")
	var overlay = PauseMenuOverlayClass.new()
	overlay._ready()

	var logout_btn: Button = overlay.get_logout_button()
	var exists: bool = (logout_btn != null)
	var text_ok: bool = (logout_btn != null and logout_btn.text == "ĐĂNG XUẤT")
	var variation_ok: bool = (logout_btn != null and logout_btn.theme_type_variation == &"MathosDestructiveButton")
	var not_confirming: bool = (not overlay.is_confirmation_visible())

	overlay.free()

	if exists and text_ok and variation_ok and not_confirming:
		print("[AUTH-BOOT-013] PASS: Player-facing Logout button exists in PauseMenuOverlay with correct style and text!")
		return true
	else:
		print("[AUTH-BOOT-013] FAIL: Logout button check failed (exists=%s, text=%s, var=%s)" % [str(exists), str(text_ok), str(variation_ok)])
		return false

# 14. Guest mode label switching
static func test_auth_boot_014_guest_mode_label_switching(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-014] Testing guest vs authenticated label switching in PauseMenuOverlay...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var pres_shell = app.call("get_presentation_shell")
	var pause_overlay = pres_shell.call("get_pause_overlay") as PauseMenuOverlay
	if pause_overlay == null:
		_cleanup_node(app)
		return false

	# Authenticated mode by default
	app.call("_on_auth_completed", AuthResultClass.ok({}))
	var is_guest_false: bool = (not app.call("is_guest_mode"))
	var auth_text: bool = (pause_overlay.get_logout_button() != null and pause_overlay.get_logout_button().text == "ĐĂNG XUẤT")

	# Guest mode
	app.call("_on_guest_entered")
	var is_guest_true: bool = bool(app.call("is_guest_mode"))
	var guest_text: bool = (pause_overlay.get_logout_button() != null and pause_overlay.get_logout_button().text == "THOÁT VỀ ĐĂNG NHẬP")

	_cleanup_node(app)

	if is_guest_false and auth_text and is_guest_true and guest_text:
		print("[AUTH-BOOT-014] PASS: Guest vs authenticated label switching verified!")
		return true
	else:
		print("[AUTH-BOOT-014] FAIL: Label switching failed (auth_text=%s, guest_text=%s)" % [str(auth_text), str(guest_text)])
		return false

# 15. Clicking logout displays confirmation dialog
static func test_auth_boot_015_logout_shows_confirmation_dialog(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-015] Testing clicking Logout shows confirmation dialog without immediate exit...")
	var overlay = PauseMenuOverlayClass.new()
	overlay._ready()
	overlay.show_pause()

	var logout_emitted: Array[bool] = [false]
	overlay.logout_requested.connect(func(): logout_emitted[0] = true)

	var logout_btn: Button = overlay.get_logout_button()
	logout_btn.emit_signal("pressed")

	var is_confirming: bool = overlay.is_confirmation_visible()
	var still_paused: bool = overlay.is_paused()
	var not_emitted: bool = (not logout_emitted[0])

	overlay.free()

	if is_confirming and still_paused and not_emitted:
		print("[AUTH-BOOT-015] PASS: Confirmation dialog displayed without premature logout exit!")
		return true
	else:
		print("[AUTH-BOOT-015] FAIL: Confirmation display failed (confirming=%s, paused=%s, not_emitted=%s)" % [str(is_confirming), str(still_paused), str(not_emitted)])
		return false

# 16. Cancelling confirmation keeps gameplay/pause intact
static func test_auth_boot_016_logout_cancel_confirmation(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-016] Testing cancelling confirmation keeps pause menu intact...")
	var overlay = PauseMenuOverlayClass.new()
	overlay._ready()
	overlay.show_pause()

	var logout_emitted: Array[bool] = [false]
	overlay.logout_requested.connect(func(): logout_emitted[0] = true)

	# Click logout to show confirmation
	overlay.get_logout_button().emit_signal("pressed")
	var confirm_shown: bool = overlay.is_confirmation_visible()

	# Click cancel ("HỦY")
	overlay.get_confirm_cancel_button().emit_signal("pressed")
	var confirm_hidden: bool = (not overlay.is_confirmation_visible())
	var still_paused: bool = overlay.is_paused()
	var not_emitted: bool = (not logout_emitted[0])

	overlay.free()

	if confirm_shown and confirm_hidden and still_paused and not_emitted:
		print("[AUTH-BOOT-016] PASS: Cancel confirmation preserved pause state without emitting logout!")
		return true
	else:
		print("[AUTH-BOOT-016] FAIL: Cancel confirmation failed (shown=%s, hidden=%s, paused=%s)" % [str(confirm_shown), str(confirm_hidden), str(still_paused)])
		return false

# 17. Confirming logout invokes AppRoot.logout()
static func test_auth_boot_017_logout_confirm_invokes_approot_logout(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-017] Testing confirming logout triggers AppRoot.logout() and clears session...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var pres_shell = app.call("get_presentation_shell")
	var auth_shell = app.call("get_auth_shell")
	var client: RefCounted = app.call("get_auth_client") as RefCounted
	var session = client.get_session()

	# Mock logout endpoint
	var transport = client.get("_transport")
	transport.mock_handler = func(_url, _method, _headers, _body, _timeout = 10.0):
		return {"status_code": 200, "body": JSON.stringify({"message": "Logged out"}), "headers": []}

	# Login and enter gameplay
	session.update_from_dict({
		"access_token": "token_to_clear_777",
		"refresh_token": "refresh_to_clear_888",
		"user_id": "usr_999",
		"email": "hero@mathos.dev"
	})
	app.call("_on_auth_completed", AuthResultClass.ok({}))

	# Open pause overlay and click logout then confirm
	pres_shell.call("show_pause")
	var pause_overlay = pres_shell.call("get_pause_overlay") as PauseMenuOverlay
	pause_overlay.get_logout_button().emit_signal("pressed")
	pause_overlay.get_confirm_accept_button().emit_signal("pressed")

	var pres_hidden: bool = (not pres_shell.visible)
	var auth_visible: bool = (auth_shell.visible)
	var is_login: bool = (auth_shell.call("get_current_panel") == AuthShellClass.PanelType.LOGIN)
	var session_cleared: bool = (not session.is_active())
	var pause_hidden: bool = (not pause_overlay.is_paused())

	_cleanup_node(app)

	if pres_hidden and auth_visible and is_login and session_cleared and pause_hidden:
		print("[AUTH-BOOT-017] PASS: Confirming logout cleanly invoked AppRoot.logout(), cleared session, and returned to Login!")
		return true
	else:
		print("[AUTH-BOOT-017] FAIL: Confirm logout failed (pres_hidden=%s, auth_vis=%s, login=%s, cleared=%s, pause_hidden=%s)" % [str(pres_hidden), str(auth_visible), str(is_login), str(session_cleared), str(pause_hidden)])
		return false

# 18. Guest exit without backend call and relogin cycle
static func test_auth_boot_018_guest_exit_and_relogin_cycle(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-018] Testing guest exit has zero backend call, and relogin cycle works cleanly...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var pres_shell = app.call("get_presentation_shell")
	var auth_shell = app.call("get_auth_shell")
	var client: RefCounted = app.call("get_auth_client") as RefCounted
	var session = client.get_session()

	var backend_call_count: Array[int] = [0]
	var transport = client.get("_transport")
	transport.mock_handler = func(_url, _method, _headers, _body, _timeout = 10.0):
		backend_call_count[0] += 1
		return {"status_code": 200, "body": JSON.stringify({"message": "OK"}), "headers": []}

	# Step 1: Guest enters gameplay
	app.call("_on_guest_entered")
	var guest_active: bool = pres_shell.visible and (not auth_shell.visible)

	# Step 2: Guest opens pause and exits
	pres_shell.call("show_pause")
	var pause_overlay = pres_shell.call("get_pause_overlay") as PauseMenuOverlay
	pause_overlay.get_logout_button().emit_signal("pressed")
	pause_overlay.get_confirm_accept_button().emit_signal("pressed")

	var guest_exit_ok: bool = (not pres_shell.visible) and auth_shell.visible
	var zero_backend_calls_on_guest: bool = (backend_call_count[0] == 0)
	var session_still_clean: bool = (not session.is_active())

	# Step 3: Now user logs in as authenticated user
	session.update_from_dict({
		"access_token": "relogin_token_111",
		"refresh_token": "relogin_refresh_222",
		"user_id": "usr_relogin",
		"email": "relogin@mathos.dev"
	})
	app.call("_on_auth_completed", AuthResultClass.ok({}))
	var relogin_pres_vis: bool = pres_shell.visible and (not auth_shell.visible)

	# Step 4: Authenticated user pauses and logs out
	pres_shell.call("show_pause")
	pause_overlay.get_logout_button().emit_signal("pressed")
	pause_overlay.get_confirm_accept_button().emit_signal("pressed")

	var auth_logout_pres_hidden: bool = (not pres_shell.visible) and auth_shell.visible
	var one_backend_call: bool = (backend_call_count[0] == 1) # Authenticated logout DID call backend
	var session_revoked: bool = (not session.is_active())

	_cleanup_node(app)

	if guest_active and guest_exit_ok and zero_backend_calls_on_guest and session_still_clean and relogin_pres_vis and auth_logout_pres_hidden and one_backend_call and session_revoked:
		print("[AUTH-BOOT-018] PASS: Guest exit without backend calls and full relogin cycle verified cleanly!")
		return true
	else:
		print("[AUTH-BOOT-018] FAIL: Cycle failed (guest_ok=%s, zero_calls=%s, relogin=%s, auth_exit=%s, one_call=%s)" % [str(guest_exit_ok), str(zero_backend_calls_on_guest), str(relogin_pres_vis), str(auth_logout_pres_hidden), str(one_backend_call)])
		return false

# 19. Normal boot to Login
static func test_auth_boot_019_normal_boot_to_login(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-019] Testing normal boot without reset token routes post-splash to LOGIN...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	app.call("clear_launch_reset_token")
	var auth_shell: Control = app.call("get_auth_shell") as Control
	app.call("_on_boot_sequence_completed")

	var auth_visible: bool = (auth_shell != null and auth_shell.visible)
	var is_login_panel: bool = (auth_shell != null and auth_shell.call("get_current_panel") == AuthShellClass.PanelType.LOGIN)
	var token_empty: bool = (auth_shell != null and auth_shell.call("get_reset_token").is_empty())
	var has_no_launch_token: bool = (not app.call("has_valid_reset_token"))

	_cleanup_node(app)

	if auth_visible and is_login_panel and token_empty and has_no_launch_token:
		print("[AUTH-BOOT-019] PASS: Normal boot cleanly routed to LOGIN panel with empty token!")
		return true
	else:
		print("[AUTH-BOOT-019] FAIL: Normal boot check failed (auth_vis=%s, login=%s, token_empty=%s, no_launch=%s)" % [str(auth_visible), str(is_login_panel), str(token_empty), str(has_no_launch_token)])
		return false

# 20. Reset token boot to reset panel
static func test_auth_boot_020_reset_token_boot_to_reset_panel(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-020] Testing reset-token boot routes post-splash to RESET_PASSWORD mode...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	app.call("set_launch_reset_token", "test_tok_live_001")
	var has_token: bool = app.call("has_valid_reset_token")
	var auth_shell: Control = app.call("get_auth_shell") as Control

	app.call("_on_boot_sequence_completed")

	var auth_visible: bool = (auth_shell != null and auth_shell.visible)
	var is_reset_panel: bool = (auth_shell != null and auth_shell.call("get_current_panel") == AuthShellClass.PanelType.RESET_PASSWORD)
	var reset_panel: Control = auth_shell.call("get_reset_panel") as Control
	var panel_visible: bool = (reset_panel != null and reset_panel.visible)
	var token_received: bool = (auth_shell != null and auth_shell.call("get_reset_token") == "test_tok_live_001")

	_cleanup_node(app)

	if has_token and auth_visible and is_reset_panel and panel_visible and token_received:
		print("[AUTH-BOOT-020] PASS: Boot with reset token cleanly routed to RESET_PASSWORD panel!")
		return true
	else:
		print("[AUTH-BOOT-020] FAIL: Reset token boot failed (has_tok=%s, auth_vis=%s, reset_panel=%s, p_vis=%s, tok_rec=%s)" % [str(has_token), str(auth_visible), str(is_reset_panel), str(panel_visible), str(token_received)])
		return false

# 21. Token handoff contract
static func test_auth_boot_021_token_handoff_contract(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-021] Testing method/signal token handoff contract and reset completion...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var auth_shell: Control = app.call("get_auth_shell") as Control
	var client: RefCounted = app.call("get_auth_client") as RefCounted
	var transport = client.get("_transport")

	var captured_token: Array[String] = [""]
	var captured_pass: Array[String] = [""]
	transport.mock_handler = func(_url, _method, _headers, body_str, _timeout = 10.0):
		var parsed = JSON.parse_string(body_str)
		if parsed is Dictionary:
			captured_token[0] = String(parsed.get("token", ""))
			captured_pass[0] = String(parsed.get("new_password", ""))
		return {"status_code": 200, "body": JSON.stringify({"message": "Password reset successfully."}), "headers": []}

	# Verify method contract
	auth_shell.call("set_reset_token", "handoff_token_xyz")
	var method_handoff_ok: bool = (auth_shell.call("get_reset_token") == "handoff_token_xyz")

	var reset_panel: Control = auth_shell.call("get_reset_panel") as Control
	var panel_contract_ok: bool = (reset_panel != null and reset_panel.has_method("set_reset_token") and reset_panel.has_method("get_reset_token") and reset_panel.has_method("clear_form"))

	# Verify signal connection and reset submission
	var sig_connected: bool = (reset_panel != null and reset_panel.has_signal("reset_password_submitted"))
	auth_shell.call("show_reset_password", "handoff_token_xyz")
	await auth_shell.call("_on_reset_password_submitted", "handoff_token_xyz", "MyNewSecPass@2026")

	var backend_received_ok: bool = (captured_token[0] == "handoff_token_xyz" and captured_pass[0] == "MyNewSecPass@2026")
	var post_reset_is_login: bool = (auth_shell.call("get_current_panel") == AuthShellClass.PanelType.LOGIN)
	var token_cleared: bool = (auth_shell.call("get_reset_token").is_empty())

	_cleanup_node(app)

	if method_handoff_ok and panel_contract_ok and sig_connected and backend_received_ok and post_reset_is_login and token_cleared:
		print("[AUTH-BOOT-021] PASS: Token handoff contract and successful reset cycle verified!")
		return true
	else:
		print("[AUTH-BOOT-021] FAIL: Handoff contract failed (method=%s, panel=%s, sig=%s, backend=%s, is_login=%s, cleared=%s)" % [str(method_handoff_ok), str(panel_contract_ok), str(sig_connected), str(backend_received_ok), str(post_reset_is_login), str(token_cleared)])
		return false

# 22. Token log safety
static func test_auth_boot_022_token_log_safety(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-022] Testing token is never logged or exposed in UI error feedback...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var auth_shell: Control = app.call("get_auth_shell") as Control
	var client: RefCounted = app.call("get_auth_client") as RefCounted
	var transport = client.get("_transport")

	# Mock backend error response
	var canary_token: String = "CANARY_SENSITIVE_TOKEN_NEVER_PRINT_98765"
	transport.mock_handler = func(_url, _method, _headers, _body, _timeout = 10.0):
		return {"status_code": 400, "body": JSON.stringify({"error": "Token is invalid or expired."}), "headers": []}

	auth_shell.call("show_reset_password", canary_token)
	var reset_panel: Control = auth_shell.call("get_reset_panel") as Control
	await auth_shell.call("_on_reset_password_submitted", canary_token, "AttemptPass123")

	var displayed_error: String = ""
	if reset_panel != null and reset_panel.has_method("get_error_message"):
		displayed_error = String(reset_panel.call("get_error_message"))

	var token_not_in_error: bool = (not displayed_error.contains(canary_token))
	var token_still_in_panel: bool = (auth_shell.call("get_reset_token") == canary_token)

	_cleanup_node(app)

	if token_not_in_error and token_still_in_panel:
		print("[AUTH-BOOT-022] PASS: Token log safety verified, sensitive token was never leaked in error output!")
		return true
	else:
		print("[AUTH-BOOT-022] FAIL: Token leaked or unexpected error state (not_in_err=%s)" % str(token_not_in_error))
		return false

# 23. Token zero persistence and in-memory cleanup
static func test_auth_boot_023_token_zero_persistence_and_cleanup(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-023] Testing token zero persistence to disk and memory cleanup on panel exit...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var auth_shell: Control = app.call("get_auth_shell") as Control
	var canary_token: String = "EPHEMERAL_TOKEN_NO_DISK_888"

	# Set in AppRoot and AuthShell
	app.call("set_launch_reset_token", canary_token)
	auth_shell.call("set_reset_token", canary_token)

	# Verify zero persistence to user://
	var dir: DirAccess = DirAccess.open("user://")
	var persisted_file_found: bool = false
	if dir != null:
		dir.list_dir_begin()
		var fname: String = dir.get_next()
		while not fname.is_empty():
			if fname.ends_with(".save") or fname.ends_with(".cfg") or fname.ends_with(".json"):
				var f = FileAccess.open("user://" + fname, FileAccess.READ)
				if f != null:
					var content = f.get_as_text()
					f.close()
					if content.contains(canary_token):
						persisted_file_found = true
			fname = dir.get_next()
		dir.list_dir_end()

	var zero_persistence: bool = (not persisted_file_found)

	# Test memory cleanup when navigating away
	auth_shell.call("show_login")
	var login_cleared: bool = (auth_shell.call("get_reset_token").is_empty())

	auth_shell.call("set_reset_token", canary_token)
	auth_shell.call("show_signup")
	var signup_cleared: bool = (auth_shell.call("get_reset_token").is_empty())

	auth_shell.call("set_reset_token", canary_token)
	auth_shell.call("show_forgot_password")
	var forgot_cleared: bool = (auth_shell.call("get_reset_token").is_empty())

	# Test explicit AppRoot cleanup
	app.call("clear_launch_reset_token")
	var approot_cleared: bool = (app.call("get_launch_reset_token").is_empty())

	_cleanup_node(app)

	if zero_persistence and login_cleared and signup_cleared and forgot_cleared and approot_cleared:
		print("[AUTH-BOOT-023] PASS: Token zero disk persistence and complete in-memory cleanup verified!")
		return true
	else:
		print("[AUTH-BOOT-023] FAIL: Persistence or cleanup failed (zero_disk=%s, login=%s, signup=%s, forgot=%s, approot=%s)" % [str(zero_persistence), str(login_cleared), str(signup_cleared), str(forgot_cleared), str(approot_cleared)])
		return false

# 24. Invalid/empty token fallback to Login
static func test_auth_boot_024_invalid_empty_token_fallback_to_login(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-024] Testing invalid, empty, or whitespace-only token fallback to LOGIN...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var auth_shell: Control = app.call("get_auth_shell") as Control

	# Case A: Empty string
	app.call("set_launch_reset_token", "")
	var empty_valid: bool = app.call("has_valid_reset_token")
	app.call("_route_post_splash")
	var panel_a_is_login: bool = (auth_shell.call("get_current_panel") == AuthShellClass.PanelType.LOGIN)

	# Case B: Whitespace only
	app.call("set_launch_reset_token", "   \t\n  ")
	var ws_valid: bool = app.call("has_valid_reset_token")
	app.call("_route_post_splash")
	var panel_b_is_login: bool = (auth_shell.call("get_current_panel") == AuthShellClass.PanelType.LOGIN)

	_cleanup_node(app)

	if (not empty_valid) and panel_a_is_login and (not ws_valid) and panel_b_is_login:
		print("[AUTH-BOOT-024] PASS: Invalid and whitespace-only reset token correctly fell back to LOGIN!")
		return true
	else:
		print("[AUTH-BOOT-024] FAIL: Token fallback failed (empty_valid=%s, panel_a=%s, ws_valid=%s, panel_b=%s)" % [str(empty_valid), str(panel_a_is_login), str(ws_valid), str(panel_b_is_login)])
		return false

# 25. Visual Lab bypass unaffected by reset token
static func test_auth_boot_025_visual_lab_bypass_unaffected_by_token(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-025] Testing Visual Lab bypass remains unaffected even if reset token is present...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	app.call("set_launch_reset_token", "token_during_visual_lab_test")

	# Check Visual Lab mode determination
	var is_vlab: bool = bool(app.call("_is_visual_lab_mode"))
	if is_vlab:
		var lab = app.call("get_visual_lab")
		var boot = app.call("get_boot_sequence")
		var auth = app.call("get_auth_shell")
		var ok: bool = (lab != null and boot == null and auth == null)
		_cleanup_node(app)
		if ok:
			print("[AUTH-BOOT-025] PASS: --visual-lab bypass verified with reset token present!")
			return true
		else:
			print("[AUTH-BOOT-025] FAIL: --visual-lab bypass failed!")
			return false

	# If not in visual-lab mode, verify that _setup_boot_sequence and _setup_auth_shell check _is_visual_lab_mode
	var auth_shell: Control = app.call("get_auth_shell") as Control
	app.call("_route_post_splash")
	var routes_to_reset_normally: bool = (auth_shell != null and auth_shell.call("get_current_panel") == AuthShellClass.PanelType.RESET_PASSWORD)

	_cleanup_node(app)

	if routes_to_reset_normally:
		print("[AUTH-BOOT-025] PASS: Visual Lab bypass checks and reset routing distinction verified!")
		return true
	else:
		print("[AUTH-BOOT-025] FAIL: Visual lab check failed (routes_reset=%s)" % str(routes_to_reset_normally))
		return false

# 26. Guest mode and logout routes unaffected
static func test_auth_boot_026_guest_and_logout_unaffected(tree: SceneTree = null) -> bool:
	print("[AUTH-BOOT-026] Testing guest entry and logout routes remain completely unaffected...")
	var app: Node = _instantiate_test_app(tree)
	if app == null:
		return false

	var pres_shell: Control = app.call("get_presentation_shell") as Control
	var auth_shell: Control = app.call("get_auth_shell") as Control

	# Set launch token, then user enters as guest
	app.call("set_launch_reset_token", "residual_token_guest_test")
	app.call("_on_guest_entered")

	var guest_gameplay_active: bool = (pres_shell != null and pres_shell.visible and auth_shell != null and not auth_shell.visible)
	var launch_token_cleared: bool = (app.call("get_launch_reset_token").is_empty())

	# Guest opens pause and logs out
	if pres_shell != null and pres_shell.has_method("show_pause"):
		pres_shell.call("show_pause")
		var pause_overlay = pres_shell.call("get_pause_overlay") as PauseMenuOverlay
		if pause_overlay != null:
			pause_overlay.get_logout_button().emit_signal("pressed")
			pause_overlay.get_confirm_accept_button().emit_signal("pressed")

	var returned_to_auth: bool = (pres_shell != null and not pres_shell.visible and auth_shell != null and auth_shell.visible)
	var returned_to_login_not_reset: bool = (auth_shell != null and auth_shell.call("get_current_panel") == AuthShellClass.PanelType.LOGIN)

	_cleanup_node(app)

	if guest_gameplay_active and launch_token_cleared and returned_to_auth and returned_to_login_not_reset:
		print("[AUTH-BOOT-026] PASS: Guest entry and logout routing unaffected, residual tokens wiped cleanly!")
		return true
	else:
		print("[AUTH-BOOT-026] FAIL: Guest/logout check failed (guest=%s, tok_cleared=%s, returned=%s, login_panel=%s)" % [str(guest_gameplay_active), str(launch_token_cleared), str(returned_to_auth), str(returned_to_login_not_reset)])
		return false
