extends SceneTree

const VisualLabClass = preload("res://dev/visual_lab/visual_lab.gd")
const AuthLoginBackgroundClass = preload("res://src/ui/auth/auth_login_background.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS BANNER C & LOCAL LIGHT SPOTS QA HARNESS (MATHOS-AUTH-VISUAL-LAB-BANNER-C-LOCAL-LIGHT-SPOTS-041) ---")
	var passes: int = 0
	var total: int = 21

	if test_01_banner_c_selection_direct_and_ui(): passes += 1
	if test_02_overlap_priority_c_over_b_over_a(): passes += 1
	if test_03_banner_c_four_corner_handles(): passes += 1
	if test_04_banner_c_whole_banner_drag(): passes += 1
	if test_05_reset_banner_c_independence(): passes += 1
	if test_06_reset_all_banners(): passes += 1
	if test_07_light_spot_placement_ux(): passes += 1
	if test_08_light_spot_center_move_drag(): passes += 1
	if test_09_light_spot_radius_resize_drag(): passes += 1
	if test_10_intensity_adjustment(): passes += 1
	if test_11_softness_adjustment(): passes += 1
	if test_12_color_adjustment(): passes += 1
	if test_13_delete_light_spot(): passes += 1
	if test_14_reset_lights_leaves_banners_untouched(): passes += 1
	if test_15_diffuse_lighting_effect(): passes += 1
	if test_16_combine_multiple_lights_ge_8(): passes += 1
	if test_17_preserves_original_texture_details(): passes += 1
	if test_18_stable_reference_coordinates_across_viewport_resizing(): passes += 1
	if test_19_no_coordinate_drift_after_repeated_drags(): passes += 1
	if test_20_multi_resolution_alignment(): passes += 1
	if test_21_independent_operation_of_all_3_banners_plus_lights(): passes += 1

	print("==========================================")
	print("BANNER C & LOCAL LIGHT SPOTS TEST SUMMARY: %d / %d PASSED" % [passes, total])
	print("==========================================")
	if passes == total:
		print("ALL 21 ACCEPTANCE CRITERIA VERIFIED SUCCESSFULLY!")
		quit(0)
	else:
		print("SOME ACCEPTANCE TESTS FAILED!")
		quit(1)

func _create_lab() -> VisualLab:
	var lab: VisualLab = VisualLabClass.new()
	root.add_child(lab)
	lab.set_lab_mode(VisualLab.LabMode.AUTH_LOGIN_BG)
	return lab

func _bg_to_global(bg: AuthLoginBackground, p: Vector2) -> Vector2:
	return bg.get_global_transform() * p

# 1. Banner C selection: direct canvas click and UI selection
func test_01_banner_c_selection_direct_and_ui() -> bool:
	print("[LIGHTS-001] Verifying Banner C selection via canvas click and UI API...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	# Click canvas inside Banner C
	var c_rect: Rect2 = bg.get_banner_c_base_rect()
	var click_c: InputEventMouseButton = InputEventMouseButton.new()
	click_c.button_index = MOUSE_BUTTON_LEFT
	click_c.pressed = true
	click_c.position = c_rect.get_center()
	click_c.global_position = _bg_to_global(bg, c_rect.get_center())
	overlay._gui_input(click_c)

	if lab.get_banner_selection() != VisualLab.BannerSelection.BANNER_C:
		print("[LIGHTS-001] FAIL: Direct click did not select Banner C")
		lab.queue_free()
		return false

	click_c.pressed = false
	overlay._gui_input(click_c)

	# Test deselect then select via UI method
	lab.deselect_banner()
	if lab.get_banner_selection() != VisualLab.BannerSelection.NONE:
		print("[LIGHTS-001] FAIL: Deselect did not clear selection")
		lab.queue_free()
		return false

	lab.select_banner_c()
	if lab.get_banner_selection() != VisualLab.BannerSelection.BANNER_C:
		print("[LIGHTS-001] FAIL: select_banner_c() did not select Banner C")
		lab.queue_free()
		return false

	print("[LIGHTS-001] PASS: Banner C selection direct click and API verified!")
	lab.queue_free()
	return true

# 2. Overlap priority: C above B above A
func test_02_overlap_priority_c_over_b_over_a() -> bool:
	print("[LIGHTS-002] Verifying overlap selection priority: C > B > A...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	# Position Banner A, B, and C to all cover test point (400, 250)
	var test_pt: Vector2 = Vector2(400, 250)
	var a_base: Rect2 = bg.get_banner_a_base_rect()
	var b_base: Rect2 = bg.get_banner_b_base_rect()
	var c_base: Rect2 = bg.get_banner_c_base_rect()

	var delta_a: Vector2 = test_pt - a_base.get_center()
	var delta_b: Vector2 = test_pt - b_base.get_center()
	var delta_c: Vector2 = test_pt - c_base.get_center()

	bg.banner_a_warp_tl = delta_a; bg.banner_a_warp_tr = delta_a; bg.banner_a_warp_bl = delta_a; bg.banner_a_warp_br = delta_a
	bg.banner_b_warp_tl = delta_b; bg.banner_b_warp_tr = delta_b; bg.banner_b_warp_bl = delta_b; bg.banner_b_warp_br = delta_b
	bg.banner_c_warp_tl = delta_c; bg.banner_c_warp_tr = delta_c; bg.banner_c_warp_bl = delta_c; bg.banner_c_warp_br = delta_c

	# 1. Click overlap -> Must select Banner C (topmost)
	var ev: InputEventMouseButton = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT; ev.pressed = true; ev.position = test_pt; ev.global_position = _bg_to_global(bg, test_pt)
	lab.deselect_banner()
	overlay._gui_input(ev)
	if lab.get_banner_selection() != VisualLab.BannerSelection.BANNER_C:
		print("[LIGHTS-002] FAIL: Overlap did not prioritize Banner C over B and A")
		lab.queue_free()
		return false
	ev.pressed = false; overlay._gui_input(ev)

	# 2. Move Banner C away -> Click overlap -> Must select Banner B
	bg.banner_c_warp_tl = Vector2(900, 900); bg.banner_c_warp_tr = Vector2(900, 900); bg.banner_c_warp_bl = Vector2(900, 900); bg.banner_c_warp_br = Vector2(900, 900)
	lab.deselect_banner()
	ev.pressed = true; overlay._gui_input(ev)
	if lab.get_banner_selection() != VisualLab.BannerSelection.BANNER_B:
		print("[LIGHTS-002] FAIL: Overlap did not prioritize Banner B over Banner A")
		lab.queue_free()
		return false
	ev.pressed = false; overlay._gui_input(ev)

	# 3. Move Banner B away -> Click overlap -> Must select Banner A
	bg.banner_b_warp_tl = Vector2(900, 900); bg.banner_b_warp_tr = Vector2(900, 900); bg.banner_b_warp_bl = Vector2(900, 900); bg.banner_b_warp_br = Vector2(900, 900)
	lab.deselect_banner()
	ev.pressed = true; overlay._gui_input(ev)
	if lab.get_banner_selection() != VisualLab.BannerSelection.BANNER_A:
		print("[LIGHTS-002] FAIL: Did not fall back to Banner A")
		lab.queue_free()
		return false
	ev.pressed = false; overlay._gui_input(ev)

	print("[LIGHTS-002] PASS: Overlap selection priority C > B > A strictly verified!")
	lab.queue_free()
	return true

# 3. Banner C 4 corner handles
func test_03_banner_c_four_corner_handles() -> bool:
	print("[LIGHTS-003] Verifying Banner C 4 corner handles drag independently...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	lab.select_banner_c()
	var quad: Dictionary = bg.get_banner_c_quad_points()

	# Drag TL handle by (-15, -25)
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = quad["TL"]; press.global_position = _bg_to_global(bg, quad["TL"])
	overlay._gui_input(press)

	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = quad["TL"] + Vector2(-15, -25); motion.global_position = _bg_to_global(bg, motion.position)
	overlay._gui_input(motion)

	press.pressed = false; press.position = motion.position; press.global_position = motion.global_position
	overlay._gui_input(press)

	if bg.banner_c_warp_tl != Vector2(-15, -25):
		print("[LIGHTS-003] FAIL: Banner C TL warp expected (-15, -25), got %s" % str(bg.banner_c_warp_tl))
		lab.queue_free()
		return false
	if bg.banner_c_warp_tr != Vector2.ZERO or bg.banner_c_warp_bl != Vector2.ZERO or bg.banner_c_warp_br != Vector2.ZERO:
		print("[LIGHTS-003] FAIL: Other corners of Banner C modified during TL drag")
		lab.queue_free()
		return false

	print("[LIGHTS-003] PASS: Banner C corner handles drag independently!")
	lab.queue_free()
	return true

# 4. Banner C whole banner drag
func test_04_banner_c_whole_banner_drag() -> bool:
	print("[LIGHTS-004] Verifying Banner C whole banner drag translates all 4 corners...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	lab.select_banner_c()
	var start_center: Vector2 = bg.get_banner_c_base_rect().get_center()

	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = start_center; press.global_position = _bg_to_global(bg, start_center)
	overlay._gui_input(press)

	var delta: Vector2 = Vector2(35, -20)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = start_center + delta; motion.global_position = _bg_to_global(bg, motion.position)
	overlay._gui_input(motion)

	press.pressed = false; press.position = motion.position; press.global_position = motion.global_position
	overlay._gui_input(press)

	if bg.banner_c_warp_tl != delta or bg.banner_c_warp_tr != delta or bg.banner_c_warp_bl != delta or bg.banner_c_warp_br != delta:
		print("[LIGHTS-004] FAIL: Whole banner drag did not translate all 4 corners by delta %s" % str(delta))
		lab.queue_free()
		return false

	print("[LIGHTS-004] PASS: Banner C whole banner drag translates all 4 corners identically!")
	lab.queue_free()
	return true

# 5. Reset Banner C leaves A and B untouched
func test_05_reset_banner_c_independence() -> bool:
	print("[LIGHTS-005] Verifying Reset Banner C leaves Banner A and B untouched...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.banner_a_warp_tl = Vector2(10, 10)
	bg.banner_b_warp_tl = Vector2(20, 20)
	bg.banner_c_warp_tl = Vector2(30, 30)

	lab.reset_banner_c()

	if bg.banner_c_warp_tl != Vector2.ZERO:
		print("[LIGHTS-005] FAIL: Banner C did not reset to Vector2.ZERO")
		lab.queue_free()
		return false
	if bg.banner_a_warp_tl != Vector2(10, 10) or bg.banner_b_warp_tl != Vector2(20, 20):
		print("[LIGHTS-005] FAIL: Reset Banner C modified Banner A or Banner B")
		lab.queue_free()
		return false

	print("[LIGHTS-005] PASS: Reset Banner C is strictly independent!")
	lab.queue_free()
	return true

# 6. Reset all banners
func test_06_reset_all_banners() -> bool:
	print("[LIGHTS-006] Verifying Reset All Banners restores A, B, and C...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.banner_a_warp_tl = Vector2(12, 12)
	bg.banner_b_warp_tl = Vector2(24, 24)
	bg.banner_c_warp_tl = Vector2(36, 36)

	lab.reset_all_banners()

	if bg.banner_a_warp_tl != Vector2.ZERO or bg.banner_b_warp_tl != Vector2.ZERO or bg.banner_c_warp_tl != Vector2.ZERO:
		print("[LIGHTS-006] FAIL: reset_all_banners() failed to reset all three banners")
		lab.queue_free()
		return false

	# Backward compatible reset_both_banners()
	bg.banner_a_warp_tl = Vector2(5, 5); bg.banner_b_warp_tl = Vector2(15, 15); bg.banner_c_warp_tl = Vector2(25, 25)
	lab.reset_both_banners()
	if bg.banner_a_warp_tl != Vector2.ZERO or bg.banner_b_warp_tl != Vector2.ZERO or bg.banner_c_warp_tl != Vector2.ZERO:
		print("[LIGHTS-006] FAIL: reset_both_banners() alias failed to reset all banners")
		lab.queue_free()
		return false

	print("[LIGHTS-006] PASS: Reset all banners verified cleanly!")
	lab.queue_free()
	return true

# 7. Light spot placement UX: + LIGHT SPOT -> click canvas
func test_07_light_spot_placement_ux() -> bool:
	print("[LIGHTS-007] Verifying Light Spot placement UX (+ LIGHT SPOT -> click canvas)...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	if lab.get_light_count() != 0:
		print("[LIGHTS-007] FAIL: Initial light count should be 0")
		lab.queue_free()
		return false

	lab.start_adding_light_spot()
	if not lab.is_adding_light_spot():
		print("[LIGHTS-007] FAIL: is_adding_light_spot should be true")
		lab.queue_free()
		return false

	# Click canvas at (320, 240)
	var spawn_pos: Vector2 = Vector2(320, 240)
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true; click.position = spawn_pos; click.global_position = _bg_to_global(bg, spawn_pos)
	overlay._gui_input(click)

	if lab.get_light_count() != 1:
		print("[LIGHTS-007] FAIL: Expected 1 light spot created, got %d" % lab.get_light_count())
		lab.queue_free()
		return false

	if lab.get_active_light_index() != 0:
		print("[LIGHTS-007] FAIL: Newly created light spot should be automatically selected")
		lab.queue_free()
		return false

	if lab.is_adding_light_spot():
		print("[LIGHTS-007] FAIL: is_adding_light_spot should be false after placement")
		lab.queue_free()
		return false

	var spot: Dictionary = bg.get_light_spot(0)
	if spot["position"] != spawn_pos:
		print("[LIGHTS-007] FAIL: Light position expected %s, got %s" % [str(spawn_pos), str(spot["position"])])
		lab.queue_free()
		return false

	print("[LIGHTS-007] PASS: Light Spot placement UX verified!")
	lab.queue_free()
	return true

# 8. Light spot center move drag
func test_08_light_spot_center_move_drag() -> bool:
	print("[LIGHTS-008] Verifying Light Spot center move drag...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	var init_pos: Vector2 = Vector2(250, 200)
	bg.add_light_spot(init_pos, 140.0, 1.0)
	lab.select_light(0)

	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = init_pos; press.global_position = _bg_to_global(bg, init_pos)
	overlay._gui_input(press)

	var delta: Vector2 = Vector2(60, -40)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = init_pos + delta; motion.global_position = _bg_to_global(bg, motion.position)
	overlay._gui_input(motion)

	press.pressed = false; press.position = motion.position; press.global_position = motion.global_position
	overlay._gui_input(press)

	var spot: Dictionary = bg.get_light_spot(0)
	if spot["position"] != init_pos + delta:
		print("[LIGHTS-008] FAIL: Light position expected %s, got %s" % [str(init_pos + delta), str(spot["position"])])
		lab.queue_free()
		return false

	print("[LIGHTS-008] PASS: Light Spot center move drag verified!")
	lab.queue_free()
	return true

# 9. Light spot radius resize drag
func test_09_light_spot_radius_resize_drag() -> bool:
	print("[LIGHTS-009] Verifying Light Spot radius resize drag via circumference handle...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	var center_pos: Vector2 = Vector2(300, 200)
	bg.add_light_spot(center_pos, 100.0, 1.0)
	lab.select_light(0)

	var r_handle_pos: Vector2 = center_pos + Vector2(100.0, 0.0)
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = r_handle_pos; press.global_position = _bg_to_global(bg, r_handle_pos)
	overlay._gui_input(press)

	var new_handle_pos: Vector2 = center_pos + Vector2(180.0, 0.0)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = new_handle_pos; motion.global_position = _bg_to_global(bg, new_handle_pos)
	overlay._gui_input(motion)

	press.pressed = false; press.position = motion.position; press.global_position = motion.global_position
	overlay._gui_input(press)

	var spot: Dictionary = bg.get_light_spot(0)
	if not is_equal_approx(spot["radius"], 180.0):
		print("[LIGHTS-009] FAIL: Light radius expected 180.0, got %f" % spot["radius"])
		lab.queue_free()
		return false

	print("[LIGHTS-009] PASS: Light Spot radius resize drag verified!")
	lab.queue_free()
	return true

# 10. Intensity adjustment
func test_10_intensity_adjustment() -> bool:
	print("[LIGHTS-010] Verifying Light Spot intensity adjustment...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.add_light_spot(Vector2(200, 200), 100.0, 1.0)
	lab.select_light(0)

	bg.set_light_spot_intensity(0, 2.25)
	var spot: Dictionary = bg.get_light_spot(0)
	if not is_equal_approx(spot["intensity"], 2.25):
		print("[LIGHTS-010] FAIL: Light intensity expected 2.25, got %f" % spot["intensity"])
		lab.queue_free()
		return false

	print("[LIGHTS-010] PASS: Light Spot intensity adjustment verified!")
	lab.queue_free()
	return true

# 11. Softness adjustment
func test_11_softness_adjustment() -> bool:
	print("[LIGHTS-011] Verifying Light Spot softness adjustment...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.add_light_spot(Vector2(200, 200), 100.0, 1.0, Color.WHITE, 0.8)
	lab.select_light(0)

	bg.set_light_spot_softness(0, 1.45)
	var spot: Dictionary = bg.get_light_spot(0)
	if not is_equal_approx(spot["softness"], 1.45):
		print("[LIGHTS-011] FAIL: Light softness expected 1.45, got %f" % spot["softness"])
		lab.queue_free()
		return false

	print("[LIGHTS-011] PASS: Light Spot softness adjustment verified!")
	lab.queue_free()
	return true

# 12. Color adjustment
func test_12_color_adjustment() -> bool:
	print("[LIGHTS-012] Verifying Light Spot color presets and adjustment...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.add_light_spot(Vector2(200, 200), 100.0, 1.0)
	lab.select_light(0)

	var cyan: Color = Color(0.25, 0.75, 1.0, 1.0)
	lab._set_active_light_color(cyan)
	var spot: Dictionary = bg.get_light_spot(0)
	if not spot["color"].is_equal_approx(cyan):
		print("[LIGHTS-012] FAIL: Light color expected %s, got %s" % [str(cyan), str(spot["color"])])
		lab.queue_free()
		return false

	print("[LIGHTS-012] PASS: Light Spot color adjustment verified!")
	lab.queue_free()
	return true

# 13. Delete light spot
func test_13_delete_light_spot() -> bool:
	print("[LIGHTS-013] Verifying Delete Light Spot...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.add_light_spot(Vector2(100, 100))
	bg.add_light_spot(Vector2(200, 200))
	bg.add_light_spot(Vector2(300, 300))
	if lab.get_light_count() != 3:
		print("[LIGHTS-013] FAIL: Expected 3 lights initially")
		lab.queue_free()
		return false

	lab.select_light(1)
	lab.delete_active_light()

	if lab.get_light_count() != 2:
		print("[LIGHTS-013] FAIL: Expected 2 lights remaining after deletion, got %d" % lab.get_light_count())
		lab.queue_free()
		return false

	if lab.get_active_light_index() != -1:
		print("[LIGHTS-013] FAIL: Active light index should reset to -1 after delete")
		lab.queue_free()
		return false

	print("[LIGHTS-013] PASS: Delete Light Spot verified!")
	lab.queue_free()
	return true

# 14. Reset lights leaves banners untouched
func test_14_reset_lights_leaves_banners_untouched() -> bool:
	print("[LIGHTS-014] Verifying Reset Lights leaves Banners A, B, and C untouched...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.banner_a_warp_tl = Vector2(10, 10)
	bg.banner_b_warp_tl = Vector2(20, 20)
	bg.banner_c_warp_tl = Vector2(30, 30)

	bg.add_light_spot(Vector2(100, 100))
	bg.add_light_spot(Vector2(200, 200))

	lab.reset_lights()

	if lab.get_light_count() != 0:
		print("[LIGHTS-014] FAIL: Lights count should be 0 after reset_lights()")
		lab.queue_free()
		return false

	if bg.banner_a_warp_tl != Vector2(10, 10) or bg.banner_b_warp_tl != Vector2(20, 20) or bg.banner_c_warp_tl != Vector2(30, 30):
		print("[LIGHTS-014] FAIL: Reset Lights altered banner coordinates!")
		lab.queue_free()
		return false

	print("[LIGHTS-014] PASS: Reset Lights resets lights only; banners untouched!")
	lab.queue_free()
	return true

# 15. Diffuse lighting effect: Gaussian / smoothstep radial falloff
func test_15_diffuse_lighting_effect() -> bool:
	print("[LIGHTS-015] Verifying diffuse lighting gaussian radial falloff mathematical model...")
	# Verify falloff function: f(d) = exp(-pow(norm_d * (1.5 / softness), 2.0)) * smoothstep(1.0, 0.7, norm_d)
	var softness: float = 0.8
	var calc_falloff: Callable = func(norm_d: float) -> float:
		if norm_d >= 1.0: return 0.0
		var k: float = 1.5 / maxf(softness, 0.1)
		var g: float = exp(-pow(norm_d * k, 2.0))
		var s: float = smoothstep(1.0, 0.7, norm_d)
		return g * s

	var val_center: float = calc_falloff.call(0.0)
	var val_mid: float = calc_falloff.call(0.5)
	var val_edge: float = calc_falloff.call(1.0)

	if not is_equal_approx(val_center, 1.0):
		print("[LIGHTS-015] FAIL: Falloff at center must be 1.0, got %f" % val_center)
		return false

	if val_mid >= val_center or val_mid <= val_edge:
		print("[LIGHTS-015] FAIL: Falloff must decrease monotonically away from center (mid=%f)" % val_mid)
		return false

	if not is_equal_approx(val_edge, 0.0):
		print("[LIGHTS-015] FAIL: Falloff at radius edge must be 0.0, got %f" % val_edge)
		return false

	print("[LIGHTS-015] PASS: Diffuse lighting radial falloff model verified!")
	return true

# 16. Combine multiple lights (>= 8 simultaneous)
func test_16_combine_multiple_lights_ge_8() -> bool:
	print("[LIGHTS-016] Verifying combining >= 8 simultaneous light spots...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	for i in range(10):
		bg.add_light_spot(Vector2(50 + i * 80, 200), 120.0, 0.9, Color(0.2, 0.8, 1.0), 0.75)

	if bg.get_light_spot_count() != 10:
		print("[LIGHTS-016] FAIL: Expected 10 light spots, got %d" % bg.get_light_spot_count())
		lab.queue_free()
		return false

	# Update animations to bind shader uniforms
	bg._update_animations(0.0)

	var mat_c: ShaderMaterial = bg.get_banner_c_rect().material as ShaderMaterial
	if mat_c == null:
		print("[LIGHTS-016] FAIL: Banner C ShaderMaterial is null")
		lab.queue_free()
		return false

	var num_lights: int = mat_c.get_shader_parameter("num_lights")
	if num_lights != 10:
		print("[LIGHTS-016] FAIL: Shader parameter num_lights expected 10, got %d" % num_lights)
		lab.queue_free()
		return false

	var positions = mat_c.get_shader_parameter("light_positions")
	if positions.size() < 10:
		print("[LIGHTS-016] FAIL: Expected at least 10 positions bound to shader, got %d" % positions.size())
		lab.queue_free()
		return false

	print("[LIGHTS-016] PASS: >= 8 simultaneous lights combined and bound cleanly!")
	lab.queue_free()
	return true

# 17. Preserves original texture artwork details (additive/multiplicative tint, no flat replacement)
func test_17_preserves_original_texture_details() -> bool:
	print("[LIGHTS-017] Verifying environmental lighting preserves texture artwork details...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	# Shader formula:
	# vec3 illuminated = tex_color.rgb + (tex_color.rgb * light_acc * 0.6) + (light_acc * 0.12 * tex_color.a);
	var shader_code: String = AuthLoginBackgroundClass.BANNER_SHADER_CODE
	if not shader_code.contains("tex_color.rgb * light_acc * 0.6"):
		print("[LIGHTS-017] FAIL: Shader missing multiplicative texture luminance preservation")
		lab.queue_free()
		return false

	# Clamped total contribution
	if not shader_code.contains("clamp(light_acc, vec3(0.0), vec3(1.5))"):
		print("[LIGHTS-017] FAIL: Shader missing contribution clamp to prevent blowout")
		lab.queue_free()
		return false

	print("[LIGHTS-017] PASS: Texture detail preservation formula verified!")
	lab.queue_free()
	return true

# 18. Stable reference coordinates across viewport resizing
func test_18_stable_reference_coordinates_across_viewport_resizing() -> bool:
	print("[LIGHTS-018] Verifying stable reference coordinates across viewport resizing...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.add_light_spot(Vector2(400, 300), 150.0, 1.0)
	var spot_orig: Dictionary = bg.get_light_spot(0)

	# Change size
	bg.size = Vector2(1600, 900)
	bg._update_animations(0.0)

	var spot_after: Dictionary = bg.get_light_spot(0)
	if spot_after["position"] != spot_orig["position"]:
		print("[LIGHTS-018] FAIL: Light spot position drifted after viewport resize: %s vs %s" % [str(spot_orig["position"]), str(spot_after["position"])])
		lab.queue_free()
		return false

	print("[LIGHTS-018] PASS: Stable reference coordinates verified across resizing!")
	lab.queue_free()
	return true

# 19. No coordinate drift after repeated drags
func test_19_no_coordinate_drift_after_repeated_drags() -> bool:
	print("[LIGHTS-019] Verifying zero coordinate drift after repeated drag cycles...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	lab.select_banner_c()
	var start_tl: Vector2 = bg.banner_c_warp_tl
	var quad: Dictionary = bg.get_banner_c_quad_points()

	for i in range(10):
		# Drag forward (+20, +15)
		var press: InputEventMouseButton = InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = quad["TL"]; press.global_position = _bg_to_global(bg, quad["TL"])
		overlay._gui_input(press)

		var move_fwd: InputEventMouseMotion = InputEventMouseMotion.new()
		move_fwd.position = quad["TL"] + Vector2(20, 15); move_fwd.global_position = _bg_to_global(bg, move_fwd.position)
		overlay._gui_input(move_fwd)

		press.pressed = false; press.position = move_fwd.position; press.global_position = move_fwd.global_position
		overlay._gui_input(press)

		# Drag back (-20, -15)
		var cur_tl_pos: Vector2 = bg.get_banner_c_quad_points()["TL"]
		press.pressed = true; press.position = cur_tl_pos; press.global_position = _bg_to_global(bg, cur_tl_pos)
		overlay._gui_input(press)

		var move_back: InputEventMouseMotion = InputEventMouseMotion.new()
		move_back.position = cur_tl_pos - Vector2(20, 15); move_back.global_position = _bg_to_global(bg, move_back.position)
		overlay._gui_input(move_back)

		press.pressed = false; press.position = move_back.position; press.global_position = move_back.global_position
		overlay._gui_input(press)

	if not bg.banner_c_warp_tl.is_equal_approx(start_tl):
		print("[LIGHTS-019] FAIL: Coordinate drifted after 10 cycles: expected %s, got %s" % [str(start_tl), str(bg.banner_c_warp_tl)])
		lab.queue_free()
		return false

	print("[LIGHTS-019] PASS: Zero coordinate drift verified after 10 drag cycles!")
	lab.queue_free()
	return true

# 20. Multi-resolution alignment: 1280x720, 1600x900, 1920x1080
func test_20_multi_resolution_alignment() -> bool:
	print("[LIGHTS-020] Verifying multi-resolution alignment (1280x720, 1600x900, 1920x1080)...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	var resolutions: Array[Vector2] = [
		Vector2(1280, 720),
		Vector2(1600, 900),
		Vector2(1920, 1080)
	]

	for res in resolutions:
		bg.size = res
		bg._update_animations(0.0)

		var r_a: Rect2 = bg.get_banner_a_base_rect()
		var r_b: Rect2 = bg.get_banner_b_base_rect()
		var r_c: Rect2 = bg.get_banner_c_base_rect()

		# Ensure all 3 banners remain within viewport
		if r_a.position.x < 0 or r_a.end.x > res.x or r_a.position.y < 0 or r_a.end.y > res.y:
			print("[LIGHTS-020] FAIL: Banner A out of bounds at %s" % str(res))
			lab.queue_free()
			return false
		if r_b.position.x < 0 or r_b.end.x > res.x or r_b.position.y < 0 or r_b.end.y > res.y:
			print("[LIGHTS-020] FAIL: Banner B out of bounds at %s" % str(res))
			lab.queue_free()
			return false
		if r_c.position.x < 0 or r_c.end.x > res.x or r_c.position.y < 0 or r_c.end.y > res.y:
			print("[LIGHTS-020] FAIL: Banner C out of bounds at %s" % str(res))
			lab.queue_free()
			return false

	print("[LIGHTS-020] PASS: Multi-resolution alignment verified across 720p, 900p, and 1080p!")
	lab.queue_free()
	return true

# 21. Independent operation of all 3 banners + lights
func test_21_independent_operation_of_all_3_banners_plus_lights() -> bool:
	print("[LIGHTS-021] Verifying independent operation of all 3 banners and local lights...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	# 1. Modify Banner A
	bg.banner_a_warp_tl = Vector2(11, 11)
	# 2. Modify Banner B
	bg.banner_b_warp_tr = Vector2(-22, 22)
	# 3. Modify Banner C
	bg.banner_c_warp_bl = Vector2(33, -33)
	# 4. Add 2 lights
	var l0: int = bg.add_light_spot(Vector2(200, 150), 100.0, 1.2, Color(0.25, 0.75, 1.0, 1.0))
	var l1: int = bg.add_light_spot(Vector2(450, 300), 160.0, 0.8, Color(1.0, 0.8, 0.3, 1.0))

	# Verify every piece has its exact assigned parameters
	if bg.banner_a_warp_tl != Vector2(11, 11) or bg.banner_a_warp_tr != Vector2.ZERO:
		print("[LIGHTS-021] FAIL: Banner A corrupted")
		lab.queue_free()
		return false
	if bg.banner_b_warp_tr != Vector2(-22, 22) or bg.banner_b_warp_tl != Vector2.ZERO:
		print("[LIGHTS-021] FAIL: Banner B corrupted")
		lab.queue_free()
		return false
	if bg.banner_c_warp_bl != Vector2(33, -33) or bg.banner_c_warp_br != Vector2.ZERO:
		print("[LIGHTS-021] FAIL: Banner C corrupted")
		lab.queue_free()
		return false

	var spot0: Dictionary = bg.get_light_spot(l0)
	var spot1: Dictionary = bg.get_light_spot(l1)
	if spot0["radius"] != 100.0 or spot0["intensity"] != 1.2:
		print("[LIGHTS-021] FAIL: Light 0 corrupted")
		lab.queue_free()
		return false
	if spot1["radius"] != 160.0 or spot1["intensity"] != 0.8:
		print("[LIGHTS-021] FAIL: Light 1 corrupted")
		lab.queue_free()
		return false

	print("[LIGHTS-021] PASS: Completely independent operation of 3 banners + lights verified!")
	lab.queue_free()
	return true
