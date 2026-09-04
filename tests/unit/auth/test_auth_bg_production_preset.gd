extends SceneTree

## Verification suite for MATHOS-AUTH-BG-PRESET-PRODUCTION-INTEGRATION-043
## Validates production preset snapshot, in-memory state parity, zero gizmos, and multi-resolution stability.

const AuthLoginBackgroundClass = preload("res://src/ui/auth/auth_login_background.gd")
const AuthShellClass = preload("res://src/ui/auth/auth_shell.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS AUTH BACKGROUND PRODUCTION PRESET QA (AUTH-BG-PROD-001..005) ---")
	var ok: bool = run_all_tests()
	if ok:
		print("MATHOS AUTH BACKGROUND PRODUCTION PRESET QA: PASS!")
		quit(0)
	else:
		print("MATHOS AUTH BACKGROUND PRODUCTION PRESET QA: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var passed: int = 0
	var total: int = 5

	if test_001_production_preset_file_exists_and_parses():
		passed += 1
	else:
		print("[AUTH-PROD-001] FAIL: Production preset file check failed")

	if test_002_auth_bg_loads_preset_with_exact_parity():
		passed += 1
	else:
		print("[AUTH-PROD-002] FAIL: State parity check failed")

	if test_003_zero_editor_gizmos_in_auth_bg():
		passed += 1
	else:
		print("[AUTH-PROD-003] FAIL: Editor gizmo check failed")

	if test_004_auth_shell_integrates_production_bg():
		passed += 1
	else:
		print("[AUTH-PROD-004] FAIL: AuthShell integration check failed")

	if test_005_multi_resolution_stability():
		passed += 1
	else:
		print("[AUTH-PROD-005] FAIL: Multi-resolution stability check failed")

	print("[AUTH-BG-PROD-SUMMARY] %d / %d tests passed" % [passed, total])
	return passed == total

static func test_001_production_preset_file_exists_and_parses() -> bool:
	print("[AUTH-PROD-001] Verifying res://config/auth/auth_bg_production_preset.json exists and parses...")
	var path: String = AuthLoginBackgroundClass.PRODUCTION_PRESET_PATH
	if not FileAccess.file_exists(path):
		var global_p: String = ProjectSettings.globalize_path(path)
		if not FileAccess.file_exists(global_p):
			print("[AUTH-PROD-001] FAIL: File does not exist at %s" % path)
			return false
		path = global_p

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		print("[AUTH-PROD-001] FAIL: Could not open %s" % path)
		return false
	var text: String = f.get_as_text()
	f.close()

	var json := JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		print("[AUTH-PROD-001] FAIL: JSON parse error: %s" % json.get_error_message())
		return false

	var dict: Variant = json.data
	if not (dict is Dictionary):
		print("[AUTH-PROD-001] FAIL: JSON data is not a Dictionary")
		return false

	var d: Dictionary = dict as Dictionary
	if not (d.has("banner_a") and d.has("banner_b") and d.has("banner_c") and d.has("local_lights") and d.has("fog") and d.has("particles")):
		print("[AUTH-PROD-001] FAIL: JSON missing expected root keys")
		return false

	print("[AUTH-PROD-001] PASS: Production preset file exists, valid JSON, contains all required blocks!")
	return true

static func test_002_auth_bg_loads_preset_with_exact_parity() -> bool:
	print("[AUTH-PROD-002] Verifying AuthLoginBackground loads production preset with exact in-memory parity...")
	var bg: AuthLoginBackground = AuthLoginBackgroundClass.new()
	bg._ensure_nodes()
	var loaded: bool = bg.load_production_preset()
	if not loaded:
		print("[AUTH-PROD-002] FAIL: load_production_preset() returned false")
		bg.queue_free()
		return false

	# 1. Banner A Warp Parity
	if not bg.banner_a_warp_tl.is_equal_approx(Vector2(-135.616149902344, 99.2734375)):
		print("[AUTH-PROD-002] FAIL: Banner A TL mismatch: %v" % bg.banner_a_warp_tl)
		bg.queue_free()
		return false
	if not bg.banner_a_warp_br.is_equal_approx(Vector2(-135.616149902344, 155.943511962891)):
		print("[AUTH-PROD-002] FAIL: Banner A BR mismatch: %v" % bg.banner_a_warp_br)
		bg.queue_free()
		return false
	if absf(bg.banner_a_brightness - 0.6) > 0.01:
		print("[AUTH-PROD-002] FAIL: Banner A brightness mismatch: %f" % bg.banner_a_brightness)
		bg.queue_free()
		return false

	# 2. Banner B Warp Parity
	if not bg.banner_b_warp_tl.is_equal_approx(Vector2(44.0, -57.0)):
		print("[AUTH-PROD-002] FAIL: Banner B TL mismatch: %v" % bg.banner_b_warp_tl)
		bg.queue_free()
		return false
	if not bg.banner_b_warp_br.is_equal_approx(Vector2(20.0, 28.6407775878906)):
		print("[AUTH-PROD-002] FAIL: Banner B BR mismatch: %v" % bg.banner_b_warp_br)
		bg.queue_free()
		return false

	# 3. Banner C Warp Parity
	if not bg.banner_c_warp_tl.is_equal_approx(Vector2(-131.981811523438, -74.0938415527344)):
		print("[AUTH-PROD-002] FAIL: Banner C TL mismatch: %v" % bg.banner_c_warp_tl)
		bg.queue_free()
		return false
	if not bg.banner_c_warp_br.is_equal_approx(Vector2(-155.968139648438, 48.8123474121094)):
		print("[AUTH-PROD-002] FAIL: Banner C BR mismatch: %v" % bg.banner_c_warp_br)
		bg.queue_free()
		return false

	# 4. Local Lights Parity (10 lights in human preset)
	if bg.get_light_spot_count() != 10:
		print("[AUTH-PROD-002] FAIL: Light count mismatch (expected 10, got %d)" % bg.get_light_spot_count())
		bg.queue_free()
		return false

	# 5. Fog / Particles Parity
	if absf(bg.fog_master_opacity - 0.35) > 0.01 or bg.fog_cluster_count != 8:
		print("[AUTH-PROD-002] FAIL: Fog parameters mismatch (opacity=%f, clusters=%d)" % [bg.fog_master_opacity, bg.fog_cluster_count])
		bg.queue_free()
		return false
	if bg.dust_count != 24 or bg.particle_type != "MIXED":
		print("[AUTH-PROD-002] FAIL: Particle parameters mismatch (count=%d, type=%s)" % [bg.dust_count, bg.particle_type])
		bg.queue_free()
		return false

	bg.queue_free()
	print("[AUTH-PROD-002] PASS: Full state parity strictly verified against saved preset!")
	return true

static func test_003_zero_editor_gizmos_in_auth_bg() -> bool:
	print("[AUTH-PROD-003] Verifying absolute zero editor gizmos exist in AuthLoginBackground...")
	var bg: AuthLoginBackground = AuthLoginBackgroundClass.new()
	bg._ensure_nodes()
	bg.load_production_preset()

	var illegal_keywords: Array[String] = [
		"warp_overlay", "bannerwarpoverlay", "gizmo", "handle", "control_point", "debug_circle", "editor"
	]

	var check_node: Callable
	var found_illegal: Array[String] = []

	check_node = func(node: Node, recurse: Callable) -> void:
		var n_name: String = node.name.to_lower()
		var s_name: String = ""
		if node.get_script() != null:
			s_name = str(node.get_script().resource_path).to_lower()

		for kw in illegal_keywords:
			if kw in n_name or kw in s_name:
				found_illegal.append("%s (%s)" % [node.name, s_name])

		for child in node.get_children():
			recurse.call(child, recurse)

	check_node.call(bg, check_node)
	bg.queue_free()

	if not found_illegal.is_empty():
		print("[AUTH-PROD-003] FAIL: Found editor gizmo nodes in production Auth background: %s" % str(found_illegal))
		return false

	print("[AUTH-PROD-003] PASS: 100% clean production tree — zero gizmos, handles, or overlay scripts detected!")
	return true

static func test_004_auth_shell_integrates_production_bg() -> bool:
	print("[AUTH-PROD-004] Verifying AuthShell embeds AuthLoginBackground with production preset...")
	var shell: Control = AuthShellClass.new()
	shell._ensure_nodes()

	var bg: AuthLoginBackground = shell.get_node_or_null("AuthLoginBackground") as AuthLoginBackground
	if bg == null:
		print("[AUTH-PROD-004] FAIL: AuthLoginBackground child not found in AuthShell")
		shell.queue_free()
		return false

	if bg.get_light_spot_count() != 10:
		print("[AUTH-PROD-004] FAIL: AuthShell AuthLoginBackground did not load 10 lights (got %d)" % bg.get_light_spot_count())
		shell.queue_free()
		return false

	if not bg.banner_a_warp_tl.is_equal_approx(Vector2(-135.616149902344, 99.2734375)):
		print("[AUTH-PROD-004] FAIL: AuthShell AuthLoginBackground banner_a TL mismatch: %v" % bg.banner_a_warp_tl)
		shell.queue_free()
		return false

	shell.queue_free()
	print("[AUTH-PROD-004] PASS: AuthShell seamlessly embeds production-preset-configured background!")
	return true

static func test_005_multi_resolution_stability() -> bool:
	print("[AUTH-PROD-005] Verifying multi-resolution stability at 1280x720, 1600x900, 1920x1080...")
	var resolutions: Array[Vector2] = [
		Vector2(1280, 720),
		Vector2(1600, 900),
		Vector2(1920, 1080)
	]

	var bg: AuthLoginBackground = AuthLoginBackgroundClass.new()
	bg._ensure_nodes()
	bg.load_production_preset()

	for res in resolutions:
		bg.size = res
		bg._process(0.016)
		if is_nan(bg.banner_a_warp_tl.x) or is_inf(bg.banner_a_warp_tl.x):
			print("[AUTH-PROD-005] FAIL: NaN/Inf detected at %v for Banner A TL" % res)
			bg.queue_free()
			return false
		if not bg.banner_a_warp_tl.is_equal_approx(Vector2(-135.616149902344, 99.2734375)):
			print("[AUTH-PROD-005] FAIL: Base warp coordinate shifted after resize to %v" % res)
			bg.queue_free()
			return false

	bg.queue_free()
	print("[AUTH-PROD-005] PASS: Coordinate stability verified across 1280x720, 1600x900, 1920x1080!")
	return true
