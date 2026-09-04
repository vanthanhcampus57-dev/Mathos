extends SceneTree

## Comprehensive Production Smoke Test for MATHOS-AUTH-BG-PRESET-PRODUCTION-INTEGRATION-043
## Tests:
## 1. Splash sequence bootstrap & completion
## 2. Login screen presentation with approved production animated background (verified preset values)
## 3. Navigation: Login -> SignUp -> ForgotPassword -> ResetPassword -> Login
## 4. Guest entry transition
## 5. Reach Dungeon 1 safely (Story / Lesson mode)

const AppRootClass = preload("res://src/app/app_root.gd")
const AuthShellClass = preload("res://src/ui/auth/auth_shell.gd")
const AuthLoginBackgroundClass = preload("res://src/ui/auth/auth_login_background.gd")

func _initialize() -> void:
	print("--- STARTING TASK-043 PRODUCTION SMOKE FLOW HARNESS ---")
	var ok: bool = run_smoke_flow()
	if ok:
		print("TASK-043 PRODUCTION SMOKE FLOW HARNESS: PASS!")
		quit(0)
	else:
		print("TASK-043 PRODUCTION SMOKE FLOW HARNESS: FAIL!")
		quit(1)

static func run_smoke_flow() -> bool:
	var app: Node = AppRootClass.new()
	Engine.get_main_loop().root.add_child(app)

	# Clean save state for pristine smoke run
	var u_dir := DirAccess.open("user://")
	if u_dir != null and u_dir.file_exists("save_v1.json"):
		u_dir.remove("save_v1.json")

	# 1. SPLASH SEQUENCE & BOOTSTRAP
	print("[SMOKE-STEP-1] Initializing AppRoot bootstrap & boot sequence...")
	app.call("bootstrap_runtime")

	var boot_seq: Control = app.call("get_boot_sequence") as Control
	if boot_seq == null:
		print("[SMOKE-STEP-1] FAIL: BootSequence node is null")
		app.queue_free()
		return false

	# Advance splash completion
	app.call("_on_boot_sequence_completed")
	print("[SMOKE-STEP-1] PASS: Splash completed cleanly.")

	# 2. LOGIN SCREEN PRESENTATION WITH APPROVED PRODUCTION ANIMATED BACKGROUND
	print("[SMOKE-STEP-2] Verifying AuthShell and production animated background...")
	var auth_shell: Control = app.call("get_auth_shell") as Control
	if auth_shell == null or not auth_shell.visible:
		print("[SMOKE-STEP-2] FAIL: AuthShell is null or not visible")
		app.queue_free()
		return false

	if auth_shell.call("get_current_panel") != AuthShellClass.PanelType.LOGIN:
		print("[SMOKE-STEP-2] FAIL: AuthShell did not start on LOGIN panel")
		app.queue_free()
		return false

	var bg: AuthLoginBackground = auth_shell.get_node_or_null("AuthLoginBackground") as AuthLoginBackground
	if bg == null:
		print("[SMOKE-STEP-2] FAIL: AuthLoginBackground node is null in AuthShell")
		app.queue_free()
		return false

	# Parity check on production background:
	if not bg.banner_a_warp_tl.is_equal_approx(Vector2(-135.616149902344, 99.2734375)):
		print("[SMOKE-STEP-2] FAIL: Production preset not applied to AuthLoginBackground: %v" % bg.banner_a_warp_tl)
		app.queue_free()
		return false

	if bg.get_light_spot_count() != 10:
		print("[SMOKE-STEP-2] FAIL: Production preset light count mismatch: %d" % bg.get_light_spot_count())
		app.queue_free()
		return false

	# Gizmo check: ensure no editor gizmos exist
	var has_gizmo: bool = false
	for c in bg.get_children():
		if "overlay" in c.name.to_lower() or "gizmo" in c.name.to_lower():
			has_gizmo = true
			break
	if has_gizmo:
		print("[SMOKE-STEP-2] FAIL: Gizmo detected in background")
		app.queue_free()
		return false

	print("[SMOKE-STEP-2] PASS: Login presented with approved production animated background (10 lights, exact warp parity, zero gizmos).")

	# 3. NAVIGATE SIGNUP -> FORGOT -> RESET -> LOGIN
	print("[SMOKE-STEP-3] Testing panel navigation: Login -> Signup -> Forgot -> Reset -> Login...")

	# Navigate to Signup
	auth_shell.call("show_panel", AuthShellClass.PanelType.SIGNUP)
	if auth_shell.call("get_current_panel") != AuthShellClass.PanelType.SIGNUP:
		print("[SMOKE-STEP-3] FAIL: Failed to switch to SIGNUP")
		app.queue_free()
		return false

	# Navigate to Forgot Password
	auth_shell.call("show_panel", AuthShellClass.PanelType.FORGOT_PASSWORD)
	if auth_shell.call("get_current_panel") != AuthShellClass.PanelType.FORGOT_PASSWORD:
		print("[SMOKE-STEP-3] FAIL: Failed to switch to FORGOT_PASSWORD")
		app.queue_free()
		return false

	# Navigate to Reset Password
	auth_shell.call("show_panel", AuthShellClass.PanelType.RESET_PASSWORD)
	if auth_shell.call("get_current_panel") != AuthShellClass.PanelType.RESET_PASSWORD:
		print("[SMOKE-STEP-3] FAIL: Failed to switch to RESET_PASSWORD")
		app.queue_free()
		return false

	# Navigate back to Login
	auth_shell.call("show_panel", AuthShellClass.PanelType.LOGIN)
	if auth_shell.call("get_current_panel") != AuthShellClass.PanelType.LOGIN:
		print("[SMOKE-STEP-3] FAIL: Failed to return to LOGIN")
		app.queue_free()
		return false

	# Verify background is still intact and singular
	if auth_shell.get_node_or_null("AuthLoginBackground") != bg:
		print("[SMOKE-STEP-3] FAIL: Background node was replaced or lost during navigation")
		app.queue_free()
		return false

	print("[SMOKE-STEP-3] PASS: Navigation through Signup -> Forgot -> Reset -> Login verified cleanly with background preserved.")

	# 4. GUEST ENTRY
	print("[SMOKE-STEP-4] Triggering Guest Entry...")
	app.call("_on_guest_entered")

	if auth_shell.visible:
		print("[SMOKE-STEP-4] FAIL: AuthShell remained visible after guest entry")
		app.queue_free()
		return false

	var pres_shell: Control = app.call("get_presentation_shell") as Control
	if pres_shell == null or not pres_shell.visible:
		print("[SMOKE-STEP-4] FAIL: Presentation shell not visible after guest entry")
		app.queue_free()
		return false

	print("[SMOKE-STEP-4] PASS: Guest entry transition successful, gameplay presentation shell visible.")

	# 5. REACH DUNGEON 1 SAFELY
	print("[SMOKE-STEP-5] Starting new game to enter Dungeon 1...")
	app.call("start_new_game")

	var view_mode: int = pres_shell.call("get_view_mode")
	# View mode 7 = MODE_STORY, 1 = MODE_LESSON
	if view_mode != 7 and view_mode != 1:
		print("[SMOKE-STEP-5] FAIL: Unexpected view mode upon entering D1: %d" % view_mode)
		app.queue_free()
		return false

	print("[SMOKE-STEP-5] PASS: Dungeon 1 reached safely in mode %d (Story/Lesson)!" % view_mode)

	app.queue_free()
	return true
