class_name TestMathosTheme
extends RefCounted

## Unit test suite for MathosTokens, MathosTheme, and Theme Resources (A.1 Theme Foundation).

static func run_all_tests() -> bool:
	print("--- RUNNING MATHOS THEME FOUNDATION SUITE ---")
	var all_ok: bool = true
	all_ok = test_001_tokens_constants_validity() and all_ok
	all_ok = test_002_theme_resource_loads_cleanly() and all_ok
	all_ok = test_003_semantic_button_variations_exist() and all_ok
	all_ok = test_004_semantic_panel_variations_exist() and all_ok
	all_ok = test_005_semantic_label_variations_exist() and all_ok
	all_ok = test_006_showcase_scene_instantiates_at_1280x720() and all_ok
	return all_ok

static func test_001_tokens_constants_validity() -> bool:
	if MathosTokens.BG_APP.a <= 0.0 or MathosTokens.SURFACE_PRIMARY.a <= 0.0:
		print("[THEME-001] FAIL: Surface background alpha invalid")
		return false

	if MathosTokens.COLOR_GOLD_PRIMARY.r <= 0.0 or MathosTokens.COLOR_CYAN_MANA.b <= 0.0:
		print("[THEME-001] FAIL: Brand colors invalid")
		return false

	if MathosTokens.SPACING_MD != 12 or MathosTokens.SPACING_LG != 16:
		print("[THEME-001] FAIL: Spacing scale invalid")
		return false

	if MathosTokens.RADIUS_MD != 8 or MathosTokens.RADIUS_LG != 12:
		print("[THEME-001] FAIL: Radius scale invalid")
		return false

	if MathosTokens.FONT_SIZE_TITLE != 28 or MathosTokens.FONT_SIZE_BODY != 16:
		print("[THEME-001] FAIL: Font size scale invalid")
		return false

	print("[THEME-001] PASS: MathosTokens design system constants verified")
	return true

static func test_002_theme_resource_loads_cleanly() -> bool:
	var theme_res: Resource = load("res://src/ui/theme/mathos_theme.tres")
	if not (theme_res is Theme):
		print("[THEME-002] FAIL: res://src/ui/theme/mathos_theme.tres missing or invalid Theme resource")
		return false

	var theme: Theme = theme_res as Theme
	if not theme.has_stylebox("panel", "PanelContainer"):
		print("[THEME-002] FAIL: Theme missing default PanelContainer panel stylebox")
		return false

	if not theme.has_stylebox("normal", "Button"):
		print("[THEME-002] FAIL: Theme missing default Button normal stylebox")
		return false

	print("[THEME-002] PASS: res://src/ui/theme/mathos_theme.tres loads cleanly")
	return true

static func test_003_semantic_button_variations_exist() -> bool:
	var theme: Theme = MathosTheme.create_theme()
	var button_vars: Array[String] = ["MathosPrimaryButton", "MathosSecondaryButton", "MathosDestructiveButton"]

	for var_name in button_vars:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			if not theme.has_stylebox(state, var_name):
				print("[THEME-003] FAIL: Variation %s missing stylebox for state %s" % [var_name, state])
				return false
		if not theme.has_color("font_color", var_name):
			print("[THEME-003] FAIL: Variation %s missing font_color" % var_name)
			return false

	print("[THEME-003] PASS: Semantic button variations (Primary, Secondary, Destructive) verified")
	return true

static func test_004_semantic_panel_variations_exist() -> bool:
	var theme: Theme = MathosTheme.create_theme()
	var panel_vars: Array[String] = ["MathosPanelPrimary", "MathosPanelSecondary", "MathosPanelElevated", "MathosPanelModal", "MathosCard"]

	for var_name in panel_vars:
		if not theme.has_stylebox("panel", var_name):
			print("[THEME-004] FAIL: Panel variation %s missing stylebox" % var_name)
			return false

	for opt_state in ["panel", "hover", "selected", "correct", "incorrect", "disabled"]:
		if not theme.has_stylebox(opt_state, "MathosOption"):
			print("[THEME-004] FAIL: MathosOption missing stylebox state %s" % opt_state)
			return false

	print("[THEME-004] PASS: Semantic panel & option card variations verified")
	return true

static func test_005_semantic_label_variations_exist() -> bool:
	var theme: Theme = MathosTheme.create_theme()
	var label_vars: Array[String] = ["MathosTitle", "MathosHeading", "MathosSubtitle", "MathosBody", "MathosMeta", "MathosSuccess", "MathosError"]

	for var_name in label_vars:
		if not theme.has_color("font_color", var_name):
			print("[THEME-005] FAIL: Label variation %s missing font_color" % var_name)
			return false
		if not theme.has_font_size("font_size", var_name):
			print("[THEME-005] FAIL: Label variation %s missing font_size" % var_name)
			return false

	print("[THEME-005] PASS: Typography hierarchy variations verified")
	return true

static func test_006_showcase_scene_instantiates_at_1280x720() -> bool:
	var scene_res: Resource = load("res://src/ui/theme/showcase/mathos_theme_showcase.tscn")
	if not (scene_res is PackedScene):
		print("[THEME-006] FAIL: res://src/ui/theme/showcase/mathos_theme_showcase.tscn missing or invalid")
		return false

	var showcase: MathosThemeShowcase = (scene_res as PackedScene).instantiate() as MathosThemeShowcase
	if showcase == null:
		print("[THEME-006] FAIL: Failed to instantiate MathosThemeShowcase")
		return false

	if showcase.get_target_viewport_size() != Vector2(1280, 720):
		print("[THEME-006] FAIL: Showcase target viewport size != 1280x720")
		showcase.free()
		return false

	showcase.free()
	print("[THEME-006] PASS: MathosThemeShowcase scene instantiates cleanly at 1280x720")
	return true
