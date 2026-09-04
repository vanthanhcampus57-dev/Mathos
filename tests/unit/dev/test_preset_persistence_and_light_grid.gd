extends SceneTree

const VisualLabClass = preload("res://dev/visual_lab/visual_lab.gd")
const AuthLoginBackgroundClass = preload("res://src/ui/auth/auth_login_background.gd")

const TEST_PRESET_DIR: String = "user://test_auth_presets"

func _initialize() -> void:
	print("--- RUNNING MATHOS VISUAL LAB PRESET PERSISTENCE & LIGHT GRID QA HARNESS (MATHOS-AUTH-VISUAL-LAB-PRESET-PERSISTENCE-042) ---")
	var passes: int = 0
	var total: int = 11

	if test_01_save_current_creates_last_session(): passes += 1
	if test_02_load_preset_restores_complete_state(): passes += 1
	if test_03_save_as_custom_named_preset(): passes += 1
	if test_04_timestamped_backup_created_before_overwrite(): passes += 1
	if test_05_backup_pruning_limits_to_15_files(): passes += 1
	if test_06_debounced_autosave_lifecycle(): passes += 1
	if test_07_startup_rule_loads_last_session_if_exists(): passes += 1
	if test_08_reset_defaults_does_not_destroy_saved_preset(): passes += 1
	if test_09_light_grid_layout_columns_5_and_l10_accessible(): passes += 1
	if test_10_production_mode_has_zero_editor_gizmos(): passes += 1
	if test_11_human_preset_reference_and_l10_flow(): passes += 1

	print("==========================================")
	print("PRESET PERSISTENCE & LIGHT GRID TEST SUMMARY: %d / %d PASSED" % [passes, total])
	print("==========================================")
	_cleanup_test_dir()
	if passes == total:
		print("ALL 11 ACCEPTANCE CRITERIA VERIFIED SUCCESSFULLY!")
		quit(0)
	else:
		print("SOME ACCEPTANCE TESTS FAILED!")
		quit(1)

func _cleanup_test_dir() -> void:
	var global_dir: String = ProjectSettings.globalize_path(TEST_PRESET_DIR)
	if DirAccess.dir_exists_absolute(global_dir):
		var dir := DirAccess.open(global_dir)
		if dir != null:
			dir.list_dir_begin()
			var f := dir.get_next()
			while f != "":
				if not dir.current_is_dir():
					dir.remove(f)
				f = dir.get_next()
			dir.list_dir_end()
			DirAccess.remove_absolute(global_dir)

func _create_lab(custom_dir: String = "") -> VisualLab:
	var lab: VisualLab = VisualLabClass.new()
	root.add_child(lab)
	if not custom_dir.is_empty():
		lab.set_preset_dir(custom_dir)
	lab.set_lab_mode(VisualLab.LabMode.AUTH_LOGIN_BG)
	return lab

# 1. SAVE CURRENT creates last_session.json with all fields
func test_01_save_current_creates_last_session() -> bool:
	print("[PERSIST-001] Verifying SAVE CURRENT serializes complete Auth BG state to last_session.json...")
	var global_dir: String = ProjectSettings.globalize_path(TEST_PRESET_DIR)
	_cleanup_test_dir()

	var lab: VisualLab = _create_lab(global_dir)
	var bg: AuthLoginBackground = lab.get_auth_background()

	# Modify state across Banners, Lights, Fog, Particles
	bg.banner_a_warp_tl = Vector2(-25.0, 15.0)
	bg.banner_a_warp_br = Vector2(30.0, -10.0)
	bg.banner_a_brightness = 1.25
	bg.banner_b_warp_tr = Vector2(12.0, -8.0)
	bg.banner_c_warp_bl = Vector2(-15.0, 20.0)
	bg.fog_master_opacity = 0.65
	bg.fog_brightness = 0.95
	bg.dust_count = 32

	bg.clear_light_spots()
	bg.add_light_spot(Vector2(200, 150), 120.0, 1.5, Color(0.2, 0.8, 1.0, 1.0), 0.9)
	bg.add_light_spot(Vector2(400, 300), 160.0, 0.8, Color(1.0, 0.9, 0.4, 1.0), 0.7)

	var ok: bool = lab.save_current()
	if not ok:
		print("[PERSIST-001] FAIL: save_current() returned false")
		lab.queue_free()
		return false

	var target_file: String = global_dir.path_join("last_session.json")
	if not FileAccess.file_exists(target_file):
		print("[PERSIST-001] FAIL: last_session.json does not exist on disk at %s" % target_file)
		lab.queue_free()
		return false

	var f := FileAccess.open(target_file, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()

	if not (parsed is Dictionary):
		print("[PERSIST-001] FAIL: last_session.json is not a valid JSON Dictionary")
		lab.queue_free()
		return false

	var d: Dictionary = parsed as Dictionary
	if not d.has("banner_a") or not d.has("banner_b") or not d.has("banner_c") or not d.has("local_lights") or not d.has("fog") or not d.has("particles"):
		print("[PERSIST-001] FAIL: last_session.json missing core sections")
		lab.queue_free()
		return false

	if float(d["banner_a"]["warp_tl"]["x"]) != -25.0 or float(d["banner_a"]["warp_br"]["x"]) != 30.0:
		print("[PERSIST-001] FAIL: Banner A warp values not preserved")
		lab.queue_free()
		return false

	if (d["local_lights"] as Array).size() != 2:
		print("[PERSIST-001] FAIL: Local lights count mismatch")
		lab.queue_free()
		return false

	lab.queue_free()
	print("[PERSIST-001] PASS: SAVE CURRENT serializes complete Auth BG state cleanly!")
	return true

# 2. LOAD PRESET / RESTORE restores complete state into AuthLoginBackground and UI
func test_02_load_preset_restores_complete_state() -> bool:
	print("[PERSIST-002] Verifying LOAD PRESET / RESTORE LAST SESSION restores state and syncs UI...")
	var global_dir: String = ProjectSettings.globalize_path(TEST_PRESET_DIR)

	var lab: VisualLab = _create_lab(global_dir)
	var bg: AuthLoginBackground = lab.get_auth_background()

	# Reset to defaults in memory
	bg.reset_defaults()
	if bg.banner_a_warp_tl != Vector2.ZERO:
		print("[PERSIST-002] FAIL: Reset failed to clear warp")
		lab.queue_free()
		return false

	var ok: bool = lab.restore_last_session()
	if not ok:
		print("[PERSIST-002] FAIL: restore_last_session() returned false")
		lab.queue_free()
		return false

	if bg.banner_a_warp_tl.x != -25.0 or bg.banner_a_warp_br.x != 30.0:
		print("[PERSIST-002] FAIL: Banner A warp not restored (got %v)" % bg.banner_a_warp_tl)
		lab.queue_free()
		return false

	if absf(bg.fog_master_opacity - 0.65) > 0.01:
		print("[PERSIST-002] FAIL: Fog opacity not restored (got %f)" % bg.fog_master_opacity)
		lab.queue_free()
		return false

	if bg.get_light_spot_count() != 2:
		print("[PERSIST-002] FAIL: Light spot count not restored")
		lab.queue_free()
		return false

	var spins: Array[SpinBox] = lab.get_banner_a_warp_spins()
	if spins.size() >= 2 and spins[0].value != -25.0:
		print("[PERSIST-002] FAIL: UI SpinBox not synchronized with loaded preset")
		lab.queue_free()
		return false

	lab.queue_free()
	print("[PERSIST-002] PASS: Complete state restored into background node and UI controls!")
	return true

# 3. SAVE AS creates a named preset file
func test_03_save_as_custom_named_preset() -> bool:
	print("[PERSIST-003] Verifying SAVE AS creates independent named preset...")
	var global_dir: String = ProjectSettings.globalize_path(TEST_PRESET_DIR)

	var lab: VisualLab = _create_lab(global_dir)
	var ok: bool = lab.save_as_preset("custom_lab_setup")
	if not ok:
		print("[PERSIST-003] FAIL: save_as_preset() returned false")
		lab.queue_free()
		return false

	var custom_path: String = global_dir.path_join("custom_lab_setup.json")
	if not FileAccess.file_exists(custom_path):
		print("[PERSIST-003] FAIL: custom_lab_setup.json not found on disk")
		lab.queue_free()
		return false

	var presets: Array[String] = lab.get_available_presets()
	if not ("custom_lab_setup.json" in presets):
		print("[PERSIST-003] FAIL: custom preset not listed in get_available_presets()")
		lab.queue_free()
		return false

	lab.queue_free()
	print("[PERSIST-003] PASS: SAVE AS created independent named preset file cleanly!")
	return true

# 4. Safe Backups before overwriting last_session.json
func test_04_timestamped_backup_created_before_overwrite() -> bool:
	print("[PERSIST-004] Verifying timestamped backup is created before overwriting last_session.json...")
	var global_dir: String = ProjectSettings.globalize_path(TEST_PRESET_DIR)

	var lab: VisualLab = _create_lab(global_dir)
	var bg: AuthLoginBackground = lab.get_auth_background()

	# Change values and save again
	bg.banner_a_warp_tl = Vector2(55.0, 66.0)
	var ok: bool = lab.save_current()
	if not ok:
		print("[PERSIST-004] FAIL: save_current() returned false")
		lab.queue_free()
		return false

	# Look for auth_bg_*.json backup file
	var dir := DirAccess.open(global_dir)
	var backup_found: bool = false
	var backup_file: String = ""
	if dir != null:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if not dir.current_is_dir() and fname.begins_with("auth_bg_") and fname.ends_with(".json"):
				backup_found = true
				backup_file = fname
				break
			fname = dir.get_next()
		dir.list_dir_end()

	if not backup_found:
		print("[PERSIST-004] FAIL: No timestamped backup auth_bg_*.json found in %s" % global_dir)
		lab.queue_free()
		return false

	# Verify backup contains previous data (-25.0)
	var f := FileAccess.open(global_dir.path_join(backup_file), FileAccess.READ)
	var content: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(content)
	if not (parsed is Dictionary) or float(parsed["banner_a"]["warp_tl"]["x"]) != -25.0:
		print("[PERSIST-004] FAIL: Backup did not preserve previous state")
		lab.queue_free()
		return false

	lab.queue_free()
	print("[PERSIST-004] PASS: Timestamped backup created before overwrite with previous state!")
	return true

# 5. Backup pruning limits to recent backups (max 15)
func test_05_backup_pruning_limits_to_15_files() -> bool:
	print("[PERSIST-005] Verifying backup pruning limits old backups to at most 15 files...")
	var global_dir: String = ProjectSettings.globalize_path(TEST_PRESET_DIR)

	var lab: VisualLab = _create_lab(global_dir)

	# Generate 20 dummy backups
	for i in range(20):
		var fname: String = "auth_bg_2026-09-04_12%02d.json" % i
		var f := FileAccess.open(global_dir.path_join(fname), FileAccess.WRITE)
		f.store_string('{"dummy": %d}' % i)
		f.close()

	lab._prune_old_backups(15)

	var dir := DirAccess.open(global_dir)
	var count: int = 0
	if dir != null:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if not dir.current_is_dir() and fname.begins_with("auth_bg_") and fname.ends_with(".json"):
				count += 1
			fname = dir.get_next()
		dir.list_dir_end()

	if count != 15:
		print("[PERSIST-005] FAIL: Expected exactly 15 backups after pruning, got %d" % count)
		lab.queue_free()
		return false

	lab.queue_free()
	print("[PERSIST-005] PASS: Backup pruning safely limits old backups to 15 files!")
	return true

# 6. Debounced Autosave Lifecycle
func test_06_debounced_autosave_lifecycle() -> bool:
	print("[PERSIST-006] Verifying debounced autosave lifecycle (timer, cancel, delayed write)...")
	var global_dir: String = ProjectSettings.globalize_path(TEST_PRESET_DIR)
	_cleanup_test_dir()

	var lab: VisualLab = _create_lab(global_dir)
	var bg: AuthLoginBackground = lab.get_auth_background()
	bg.banner_a_warp_tl = Vector2(77.0, 88.0)

	lab.schedule_autosave()
	if not lab.is_autosave_pending():
		print("[PERSIST-006] FAIL: Autosave should be pending after schedule")
		lab.queue_free()
		return false

	# Advance 0.5s (less than 1.0s delay)
	lab._process(0.5)
	if not lab.is_autosave_pending():
		print("[PERSIST-006] FAIL: Autosave fired prematurely before 1.0s delay")
		lab.queue_free()
		return false
	if FileAccess.file_exists(global_dir.path_join("last_session.json")):
		print("[PERSIST-006] FAIL: File written before delay expired")
		lab.queue_free()
		return false

	# Advance remaining 0.6s (total 1.1s)
	lab._process(0.6)
	if lab.is_autosave_pending():
		print("[PERSIST-006] FAIL: Autosave should no longer be pending after delay")
		lab.queue_free()
		return false

	if not FileAccess.file_exists(global_dir.path_join("last_session.json")):
		print("[PERSIST-006] FAIL: File not written after delay expired")
		lab.queue_free()
		return false

	# Test cancel_autosave()
	lab.schedule_autosave()
	lab.cancel_autosave()
	if lab.is_autosave_pending():
		print("[PERSIST-006] FAIL: cancel_autosave() failed to clear pending state")
		lab.queue_free()
		return false

	lab.queue_free()
	print("[PERSIST-006] PASS: Debounced autosave lifecycle verified cleanly!")
	return true

# 7. Startup Rule: Load last_session.json if exists, else production defaults
func test_07_startup_rule_loads_last_session_if_exists() -> bool:
	print("[PERSIST-007] Verifying Startup Rule: loads last_session.json if present, defaults if missing...")
	var global_dir: String = ProjectSettings.globalize_path(TEST_PRESET_DIR)
	_cleanup_test_dir()

	# Case A: Empty dir -> production defaults
	var lab_a: VisualLab = _create_lab(global_dir)
	var bg_a: AuthLoginBackground = lab_a.get_auth_background()
	if bg_a.banner_a_warp_tl != Vector2.ZERO:
		print("[PERSIST-007] FAIL: Expected Vector2.ZERO default in empty dir")
		lab_a.queue_free()
		return false
	lab_a.queue_free()

	# Create a known session file
	var test_data: Dictionary = {
		"version": 1,
		"banner_a": {"warp_tl": {"x": 42.0, "y": 24.0}, "visible": true},
		"banner_b": {"warp_tl": {"x": 0.0, "y": 0.0}, "visible": true},
		"banner_c": {"warp_tl": {"x": 0.0, "y": 0.0}, "visible": true}
	}
	DirAccess.make_dir_recursive_absolute(global_dir)
	var f := FileAccess.open(global_dir.path_join("last_session.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(test_data))
	f.close()

	# Case B: Re-open Lab -> automatically loads last_session.json on startup
	var lab_b: VisualLab = _create_lab(global_dir)
	var bg_b: AuthLoginBackground = lab_b.get_auth_background()
	if bg_b.banner_a_warp_tl != Vector2(42.0, 24.0):
		print("[PERSIST-007] FAIL: Expected auto-loaded warp (42, 24), got %v" % bg_b.banner_a_warp_tl)
		lab_b.queue_free()
		return false

	lab_b.queue_free()
	print("[PERSIST-007] PASS: Startup rule correctly loads existing session or keeps defaults!")
	return true

# 8. RESET DEFAULTS does not destroy saved preset on disk
func test_08_reset_defaults_does_not_destroy_saved_preset() -> bool:
	print("[PERSIST-008] Verifying RESET DEFAULTS does NOT overwrite saved preset on disk...")
	var global_dir: String = ProjectSettings.globalize_path(TEST_PRESET_DIR)

	var lab: VisualLab = _create_lab(global_dir)
	var bg: AuthLoginBackground = lab.get_auth_background()

	# Confirm loaded value is 42
	if bg.banner_a_warp_tl.x != 42.0:
		print("[PERSIST-008] FAIL: Initial value mismatch")
		lab.queue_free()
		return false

	# User resets defaults in UI
	lab.reset_defaults()
	if bg.banner_a_warp_tl != Vector2.ZERO:
		print("[PERSIST-008] FAIL: In-memory values not reset to defaults")
		lab.queue_free()
		return false

	# Check disk: file must still contain 42.0!
	var f := FileAccess.open(global_dir.path_join("last_session.json"), FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()

	if float(parsed["banner_a"]["warp_tl"]["x"]) != 42.0:
		print("[PERSIST-008] FAIL: Saved preset on disk was overwritten by reset_defaults()!")
		lab.queue_free()
		return false

	lab.queue_free()
	print("[PERSIST-008] PASS: RESET DEFAULTS leaves on-disk preset completely intact!")
	return true

# 9. Light Grid Layout (columns = 5) and L10 Accessible
func test_09_light_grid_layout_columns_5_and_l10_accessible() -> bool:
	print("[PERSIST-009] Verifying wrapped light grid layout (5 cols) and L1..L16 accessibility...")
	var global_dir: String = ProjectSettings.globalize_path(TEST_PRESET_DIR)

	var lab: VisualLab = _create_lab(global_dir)
	var bg: AuthLoginBackground = lab.get_auth_background()
	bg.clear_light_spots()

	# Add 16 lights
	for i in range(16):
		lab.add_light_spot(Vector2(100 + i * 20, 100 + i * 15), 140.0, 1.0)

	var container: Control = lab.get_light_list_container()
	if not (container is GridContainer):
		print("[PERSIST-009] FAIL: _light_list_container is not a GridContainer")
		lab.queue_free()
		return false

	var grid: GridContainer = container as GridContainer
	if grid.columns != 5:
		print("[PERSIST-009] FAIL: GridContainer columns expected 5, got %d" % grid.columns)
		lab.queue_free()
		return false

	var children: Array[Node] = grid.get_children()
	if children.size() != 16:
		print("[PERSIST-009] FAIL: Expected 16 light buttons in grid, got %d" % children.size())
		lab.queue_free()
		return false

	# Verify L10 button specifically
	var btn_l10: Button = grid.get_node_or_null("LightBtn_10") as Button
	if btn_l10 == null:
		btn_l10 = children[9] as Button
	if btn_l10 == null or btn_l10.text != "L10":
		print("[PERSIST-009] FAIL: Button L10 not found or wrong label")
		lab.queue_free()
		return false

	# Click L10 button and verify it selects light 9
	btn_l10.emit_signal("pressed")
	if lab.get_active_light_index() != 9:
		print("[PERSIST-009] FAIL: Clicking L10 failed to select light index 9 (got %d)" % lab.get_active_light_index())
		lab.queue_free()
		return false

	lab.queue_free()
	print("[PERSIST-009] PASS: Wrapped light grid (5 columns) with all 16 slots and L10 accessible verified!")
	return true

# 10. Production Mode Safety: zero editor gizmos in Auth
func test_10_production_mode_has_zero_editor_gizmos() -> bool:
	print("[PERSIST-010] Verifying production Auth mode contains ZERO editor gizmos or overlays...")
	var prod_bg: AuthLoginBackground = AuthLoginBackgroundClass.new()
	root.add_child(prod_bg)

	# Ensure scene is fully initialized
	prod_bg._ensure_nodes()

	# Check children of prod_bg
	for child in prod_bg.get_children():
		if child.get_class() == "BannerWarpOverlay" or child.name == "BannerWarpOverlay":
			print("[PERSIST-010] FAIL: BannerWarpOverlay found in production AuthLoginBackground!")
			prod_bg.queue_free()
			return false

	# Confirm prod_bg itself does not have gizmo custom draw routines
	if prod_bg.has_method("get_banner_warp_overlay"):
		print("[PERSIST-010] FAIL: Production background exposes lab overlay methods")
		prod_bg.queue_free()
		return false

	prod_bg.queue_free()
	print("[PERSIST-010] PASS: Production Auth mode confirmed 100% free of editor gizmos!")
	return true

# 11. Human Preset Reference & L10 workflow
func test_11_human_preset_reference_and_l10_flow() -> bool:
	print("[PERSIST-011] Verifying human reference session values in D:/Mathos_Visual_Presets/AuthBackground/last_session.json and L10 flow...")
	var lab: VisualLab = _create_lab("D:/Mathos_Visual_Presets/AuthBackground")
	var bg: AuthLoginBackground = lab.get_auth_background()

	if not lab.has_last_session():
		print("[PERSIST-011] FAIL: last_session.json not found in D:/Mathos_Visual_Presets/AuthBackground")
		lab.queue_free()
		return false

	var ok: bool = lab.restore_last_session()
	if not ok:
		print("[PERSIST-011] FAIL: restore_last_session() failed")
		lab.queue_free()
		return false

	# Verify exact reference values from canonical last_session.json:
	# Banner A: TL(-135.616, 99.273), BR(-135.616, 155.944)
	if not bg.banner_a_warp_tl.is_equal_approx(Vector2(-135.616149902344, 99.2734375)) or not bg.banner_a_warp_br.is_equal_approx(Vector2(-135.616149902344, 155.943511962891)):
		print("[PERSIST-011] FAIL: Banner A reference warp mismatch: %v, %v" % [bg.banner_a_warp_tl, bg.banner_a_warp_br])
		lab.queue_free()
		return false

	# Banner B: TL(44.0, -57.0), BR(20.0, 28.641)
	if not bg.banner_b_warp_tl.is_equal_approx(Vector2(44.0, -57.0)) or not bg.banner_b_warp_br.is_equal_approx(Vector2(20.0, 28.6407775878906)):
		print("[PERSIST-011] FAIL: Banner B reference warp mismatch: %v, %v" % [bg.banner_b_warp_tl, bg.banner_b_warp_br])
		lab.queue_free()
		return false

	# Banner C: TL(-131.982, -74.094), BR(-155.968, 48.812)
	if not bg.banner_c_warp_tl.is_equal_approx(Vector2(-131.981811523438, -74.0938415527344)) or not bg.banner_c_warp_br.is_equal_approx(Vector2(-155.968139648438, 48.8123474121094)):
		print("[PERSIST-011] FAIL: Banner C reference warp mismatch: %v, %v" % [bg.banner_c_warp_tl, bg.banner_c_warp_br])
		lab.queue_free()
		return false

	# Observed lights L1..L10 in saved human preset:
	if bg.get_light_spot_count() != 10:
		print("[PERSIST-011] FAIL: Expected 10 lights in saved session, got %d" % bg.get_light_spot_count())
		lab.queue_free()
		return false

	var expected_radii: Array[float] = [134.0, 140.0, 83.0, 169.0, 183.22, 45.0, 81.0, 192.0, 137.0, 82.96]
	for i in range(10):
		var lspot: Dictionary = bg.get_light_spot(i)
		if absf(float(lspot["radius"]) - expected_radii[i]) > 0.5:
			print("[PERSIST-011] FAIL: Light %d radius mismatch (expected %f, got %f)" % [i + 1, expected_radii[i], float(lspot["radius"])])
			lab.queue_free()
			return false

	# Test adding an additional light in memory and clean removal without mutating last_session.json
	var test_light_idx: int = lab.add_light_spot(Vector2(640, 360), 150.0, 1.0)
	if bg.get_light_spot_count() != 11:
		print("[PERSIST-011] FAIL: Expected 11 lights after adding temporary light")
		lab.queue_free()
		return false

	bg.remove_light_spot(test_light_idx)
	if bg.get_light_spot_count() != 10:
		print("[PERSIST-011] FAIL: Expected 10 lights after removing temporary light")
		lab.queue_free()
		return false

	lab.queue_free()
	print("[PERSIST-011] PASS: Human reference values verified and L10 workflow verified!")
	return true
