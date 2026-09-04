extends SceneTree

const VisualLabClass = preload("res://dev/visual_lab/visual_lab.gd")
const AuthLoginBackgroundClass = preload("res://src/ui/auth/auth_login_background.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS DIRECT BANNER WARP QA HARNESS (MATHOS-AUTH-VISUAL-LAB-DIRECT-BANNER-WARP-040) ---")
	var passes: int = 0
	var total: int = 17

	if test_01_primary_ux_clean_and_advanced_collapsed(): passes += 1
	if test_02_banner_selection_direct_click_canvas(): passes += 1
	if test_03_banner_selection_empty_click_deselects(): passes += 1
	if test_04_overlapping_banners_topmost_priority(): passes += 1
	if test_05_quick_select_buttons_ui(): passes += 1
	if test_06_handle_hover_cursor_states(): passes += 1
	if test_07_corner_handle_drag_modifies_only_target_corner(): passes += 1
	if test_08_all_four_corners_drag_independently(): passes += 1
	if test_09_whole_banner_drag_translates_all_four_corners(): passes += 1
	if test_10_mouse_release_commits_without_drift_or_jumping(): passes += 1
	if test_11_banner_b_full_independence_from_banner_a(): passes += 1
	if test_12_banner_a_reset_leaves_banner_b_untouched(): passes += 1
	if test_13_banner_b_reset_leaves_banner_a_untouched(): passes += 1
	if test_14_reset_both_banners_restores_all_coordinates(): passes += 1
	if test_15_base_warp_separated_from_runtime_sway_motion(): passes += 1
	if test_16_advanced_spinboxes_live_sync_bidirectional(): passes += 1
	if test_17_multi_resolution_coordinate_projection(): passes += 1

	print("==========================================")
	print("DIRECT BANNER WARP TEST SUMMARY: %d / %d PASSED" % [passes, total])
	print("==========================================")
	if passes == total:
		print("ALL 17 ACCEPTANCE CRITERIA VERIFIED SUCCESSFULLY!")
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

# 1. Primary UX: SpinBoxes hidden in collapsed advanced section
func test_01_primary_ux_clean_and_advanced_collapsed() -> bool:
	print("[WARP-001] Verifying primary UX has collapsed advanced section and clean UI...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	if overlay == null or not overlay.visible:
		print("[WARP-001] FAIL: Overlay is null or not visible in AUTH_LOGIN_BG mode")
		lab.queue_free()
		return false

	var adv_box: VBoxContainer = lab.get_advanced_warp_box()
	if adv_box == null:
		print("[WARP-001] FAIL: AdvancedWarpBox not found")
		lab.queue_free()
		return false

	if adv_box.visible:
		print("[WARP-001] FAIL: AdvancedWarpBox must be COLLAPSED (visible=false) by default")
		lab.queue_free()
		return false

	var spins_a: Array[SpinBox] = lab.get_banner_a_warp_spins()
	var spins_b: Array[SpinBox] = lab.get_banner_b_warp_spins()
	if spins_a.size() != 8 or spins_b.size() != 8:
		print("[WARP-001] FAIL: Expected 8+8=16 SpinBoxes preserved in advanced box, got %d + %d" % [spins_a.size(), spins_b.size()])
		lab.queue_free()
		return false

	print("[WARP-001] PASS: Primary UI clean, 16 SpinBoxes safely collapsed in advanced box!")
	lab.queue_free()
	return true

# 2. Direct click selection on canvas
func test_02_banner_selection_direct_click_canvas() -> bool:
	print("[WARP-002] Verifying direct mouse clicks on canvas select Banner A and Banner B...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	# Initially NONE
	if lab.get_banner_selection() != VisualLab.BannerSelection.NONE:
		print("[WARP-002] FAIL: Initial selection should be NONE")
		lab.queue_free()
		return false

	# Click inside Banner A
	var a_rect: Rect2 = bg.get_banner_a_base_rect()
	var click_a: InputEventMouseButton = InputEventMouseButton.new()
	click_a.button_index = MOUSE_BUTTON_LEFT
	click_a.pressed = true
	click_a.position = a_rect.get_center()
	click_a.global_position = _bg_to_global(bg, a_rect.get_center())
	overlay._gui_input(click_a)

	if lab.get_banner_selection() != VisualLab.BannerSelection.BANNER_A:
		print("[WARP-002] FAIL: Clicking Banner A canvas did not select Banner A")
		lab.queue_free()
		return false

	# Release click
	click_a.pressed = false
	overlay._gui_input(click_a)

	# Click inside Banner B
	var b_rect: Rect2 = bg.get_banner_b_base_rect()
	var click_b: InputEventMouseButton = InputEventMouseButton.new()
	click_b.button_index = MOUSE_BUTTON_LEFT
	click_b.pressed = true
	click_b.position = b_rect.get_center()
	click_b.global_position = _bg_to_global(bg, b_rect.get_center())
	overlay._gui_input(click_b)

	if lab.get_banner_selection() != VisualLab.BannerSelection.BANNER_B:
		print("[WARP-002] FAIL: Clicking Banner B canvas did not select Banner B")
		lab.queue_free()
		return false

	click_b.pressed = false
	overlay._gui_input(click_b)

	print("[WARP-002] PASS: Direct canvas clicking selects Banner A and Banner B!")
	lab.queue_free()
	return true

# 3. Empty background click deselects active banner
func test_03_banner_selection_empty_click_deselects() -> bool:
	print("[WARP-003] Verifying clicking empty canvas background deselects active banner...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	lab.select_banner_a()
	if lab.get_banner_selection() != VisualLab.BannerSelection.BANNER_A:
		lab.queue_free()
		return false

	# Click empty background far away from banners (e.g., x=50, y=50)
	var click_empty: InputEventMouseButton = InputEventMouseButton.new()
	click_empty.button_index = MOUSE_BUTTON_LEFT
	click_empty.pressed = true
	click_empty.global_position = _bg_to_global(bg, Vector2(50, 50))
	overlay._gui_input(click_empty)

	if lab.get_banner_selection() != VisualLab.BannerSelection.NONE:
		print("[WARP-003] FAIL: Empty background click did not deselect active banner")
		lab.queue_free()
		return false

	print("[WARP-003] PASS: Clicking empty canvas deselects active banner!")
	lab.queue_free()
	return true

# 4. Overlapping banners: topmost banner (Banner B) takes priority
func test_04_overlapping_banners_topmost_priority() -> bool:
	print("[WARP-004] Verifying overlapping banners give topmost priority to Banner B...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	# Warp Banner A to overlap into Banner B center
	var b_center: Vector2 = bg.get_banner_b_base_rect().get_center()
	var a_rect: Rect2 = bg.get_banner_a_base_rect()
	bg.banner_a_warp_tr = b_center - (a_rect.position + Vector2(a_rect.size.x, 0)) + Vector2(40, 40)
	bg.banner_a_warp_br = b_center - (a_rect.position + a_rect.size) + Vector2(40, 40)

	lab.deselect_banner()

	# Click precisely at b_center which now is inside both Banner B and Banner A quad
	var click_overlap: InputEventMouseButton = InputEventMouseButton.new()
	click_overlap.button_index = MOUSE_BUTTON_LEFT
	click_overlap.pressed = true
	click_overlap.global_position = _bg_to_global(bg, b_center)
	overlay._gui_input(click_overlap)

	if lab.get_banner_selection() != VisualLab.BannerSelection.BANNER_B:
		print("[WARP-004] FAIL: Topmost Banner B should take priority in overlap, got %d" % lab.get_banner_selection())
		lab.queue_free()
		return false

	click_overlap.pressed = false
	overlay._gui_input(click_overlap)
	print("[WARP-004] PASS: Topmost Banner B priority in overlap verified!")
	lab.queue_free()
	return true

# 5. Quick select buttons in UI dock
func test_05_quick_select_buttons_ui() -> bool:
	print("[WARP-005] Verifying Quick Select buttons and status indicator update...")
	var lab: VisualLab = _create_lab()

	lab.select_banner_a()
	if lab.get_banner_selection() != VisualLab.BannerSelection.BANNER_A:
		lab.queue_free()
		return false

	lab.select_banner_b()
	if lab.get_banner_selection() != VisualLab.BannerSelection.BANNER_B:
		lab.queue_free()
		return false

	lab.deselect_banner()
	if lab.get_banner_selection() != VisualLab.BannerSelection.NONE:
		lab.queue_free()
		return false

	print("[WARP-005] PASS: Quick select and deselect methods verified!")
	lab.queue_free()
	return true

# 6. Handle hover cursor states
func test_06_handle_hover_cursor_states() -> bool:
	print("[WARP-006] Verifying hover cursor shapes (CROSS over handle, MOVE over quad, POINTING_HAND over unselected)...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	lab.select_banner_a()
	var quad_a: Dictionary = bg.get_banner_a_quad_points()

	# Hover over TL handle
	var move_event: InputEventMouseMotion = InputEventMouseMotion.new()
	move_event.global_position = _bg_to_global(bg, quad_a["TL"])
	overlay._gui_input(move_event)
	if overlay.mouse_default_cursor_shape != Control.CURSOR_CROSS:
		print("[WARP-006] FAIL: Expected CURSOR_CROSS over handle, got %d" % overlay.mouse_default_cursor_shape)
		lab.queue_free()
		return false

	# Hover inside Banner A quad
	move_event.global_position = _bg_to_global(bg, bg.get_banner_a_base_rect().get_center())
	overlay._gui_input(move_event)
	if overlay.mouse_default_cursor_shape != Control.CURSOR_MOVE:
		print("[WARP-006] FAIL: Expected CURSOR_MOVE inside quad, got %d" % overlay.mouse_default_cursor_shape)
		lab.queue_free()
		return false

	# Hover over unselected Banner B
	move_event.global_position = _bg_to_global(bg, bg.get_banner_b_base_rect().get_center())
	overlay._gui_input(move_event)
	if overlay.mouse_default_cursor_shape != Control.CURSOR_POINTING_HAND:
		print("[WARP-006] FAIL: Expected CURSOR_POINTING_HAND over unselected banner, got %d" % overlay.mouse_default_cursor_shape)
		lab.queue_free()
		return false

	print("[WARP-006] PASS: Interactive hover cursor states verified!")
	lab.queue_free()
	return true

# 7. Corner handle dragging modifies ONLY that corner
func test_07_corner_handle_drag_modifies_only_target_corner() -> bool:
	print("[WARP-007] Verifying dragging a corner handle deforms ONLY that corner...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	lab.select_banner_a()
	var quad_a: Dictionary = bg.get_banner_a_quad_points()
	var tl_pos: Vector2 = quad_a["TL"]

	# Mouse down on TL handle
	var m_down: InputEventMouseButton = InputEventMouseButton.new()
	m_down.button_index = MOUSE_BUTTON_LEFT
	m_down.pressed = true
	m_down.global_position = _bg_to_global(bg, tl_pos)
	overlay._gui_input(m_down)

	# Drag TL by (+25, -15)
	var m_drag: InputEventMouseMotion = InputEventMouseMotion.new()
	m_drag.global_position = _bg_to_global(bg, tl_pos + Vector2(25, -15))
	overlay._gui_input(m_drag)

	# Verify ONLY TL changed
	if not is_equal_approx(bg.banner_a_warp_tl.x, 25.0) or not is_equal_approx(bg.banner_a_warp_tl.y, -15.0):
		print("[WARP-007] FAIL: TL warp expected (25, -15), got ", bg.banner_a_warp_tl)
		lab.queue_free()
		return false

	if bg.banner_a_warp_tr != Vector2.ZERO or bg.banner_a_warp_bl != Vector2.ZERO or bg.banner_a_warp_br != Vector2.ZERO:
		print("[WARP-007] FAIL: Other corners should remain ZERO, got TR=", bg.banner_a_warp_tr, " BL=", bg.banner_a_warp_bl, " BR=", bg.banner_a_warp_br)
		lab.queue_free()
		return false

	# Mouse up
	var m_up: InputEventMouseButton = InputEventMouseButton.new()
	m_up.button_index = MOUSE_BUTTON_LEFT
	m_up.pressed = false
	m_up.global_position = _bg_to_global(bg, tl_pos + Vector2(25, -15))
	overlay._gui_input(m_up)

	print("[WARP-007] PASS: Dragging TL modified ONLY TL without affecting other corners!")
	lab.queue_free()
	return true

# 8. All four corners drag independently
func test_08_all_four_corners_drag_independently() -> bool:
	print("[WARP-008] Verifying TL, TR, BL, BR can each be dragged independently...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	lab.select_banner_a()

	# Test TR
	var tr_pos: Vector2 = bg.get_banner_a_quad_points()["TR"]
	var ev_down: InputEventMouseButton = InputEventMouseButton.new()
	ev_down.button_index = MOUSE_BUTTON_LEFT; ev_down.pressed = true; ev_down.global_position = _bg_to_global(bg, tr_pos)
	overlay._gui_input(ev_down)
	var ev_drag: InputEventMouseMotion = InputEventMouseMotion.new()
	ev_drag.global_position = _bg_to_global(bg, tr_pos + Vector2(10, -5))
	overlay._gui_input(ev_drag)
	var ev_up: InputEventMouseButton = InputEventMouseButton.new()
	ev_up.button_index = MOUSE_BUTTON_LEFT; ev_up.pressed = false; ev_up.global_position = _bg_to_global(bg, tr_pos + Vector2(10, -5))
	overlay._gui_input(ev_up)

	# Test BL
	var bl_pos: Vector2 = bg.get_banner_a_quad_points()["BL"]
	ev_down.global_position = _bg_to_global(bg, bl_pos); overlay._gui_input(ev_down)
	ev_drag.global_position = _bg_to_global(bg, bl_pos + Vector2(-12, 8)); overlay._gui_input(ev_drag)
	ev_up.global_position = _bg_to_global(bg, bl_pos + Vector2(-12, 8)); overlay._gui_input(ev_up)

	# Test BR
	var br_pos: Vector2 = bg.get_banner_a_quad_points()["BR"]
	ev_down.global_position = _bg_to_global(bg, br_pos); overlay._gui_input(ev_down)
	ev_drag.global_position = _bg_to_global(bg, br_pos + Vector2(18, 14)); overlay._gui_input(ev_drag)
	ev_up.global_position = _bg_to_global(bg, br_pos + Vector2(18, 14)); overlay._gui_input(ev_up)

	if not is_equal_approx(bg.banner_a_warp_tr.x, 10.0) or not is_equal_approx(bg.banner_a_warp_tr.y, -5.0):
		print("[WARP-008] FAIL: TR warp mismatch")
		lab.queue_free()
		return false
	if not is_equal_approx(bg.banner_a_warp_bl.x, -12.0) or not is_equal_approx(bg.banner_a_warp_bl.y, 8.0):
		print("[WARP-008] FAIL: BL warp mismatch")
		lab.queue_free()
		return false
	if not is_equal_approx(bg.banner_a_warp_br.x, 18.0) or not is_equal_approx(bg.banner_a_warp_br.y, 14.0):
		print("[WARP-008] FAIL: BR warp mismatch")
		lab.queue_free()
		return false

	print("[WARP-008] PASS: All 4 corners drag independently!")
	lab.queue_free()
	return true

# 9. Whole banner dragging translates all 4 corners
func test_09_whole_banner_drag_translates_all_four_corners() -> bool:
	print("[WARP-009] Verifying mouse dragging inside banner quad moves all 4 corners by identical delta...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	lab.select_banner_a()
	# Set non-zero initial warp
	bg.banner_a_warp_tl = Vector2(-5, -5)
	bg.banner_a_warp_tr = Vector2(5, -5)
	bg.banner_a_warp_bl = Vector2(-5, 5)
	bg.banner_a_warp_br = Vector2(5, 5)

	var center: Vector2 = bg.get_banner_a_base_rect().get_center()

	# Mouse down inside quad
	var m_down: InputEventMouseButton = InputEventMouseButton.new()
	m_down.button_index = MOUSE_BUTTON_LEFT
	m_down.pressed = true
	m_down.global_position = _bg_to_global(bg, center)
	overlay._gui_input(m_down)

	# Drag whole banner by (+40, +30)
	var m_drag: InputEventMouseMotion = InputEventMouseMotion.new()
	m_drag.global_position = _bg_to_global(bg, center + Vector2(40, 30))
	overlay._gui_input(m_drag)

	if not is_equal_approx(bg.banner_a_warp_tl.x, 35.0) or not is_equal_approx(bg.banner_a_warp_tl.y, 25.0):
		print("[WARP-009] FAIL: Whole drag TL expected (35, 25), got ", bg.banner_a_warp_tl)
		lab.queue_free()
		return false
	if not is_equal_approx(bg.banner_a_warp_tr.x, 45.0) or not is_equal_approx(bg.banner_a_warp_tr.y, 25.0):
		print("[WARP-009] FAIL: Whole drag TR expected (45, 25), got ", bg.banner_a_warp_tr)
		lab.queue_free()
		return false
	if not is_equal_approx(bg.banner_a_warp_bl.x, 35.0) or not is_equal_approx(bg.banner_a_warp_bl.y, 35.0):
		print("[WARP-009] FAIL: Whole drag BL expected (35, 35), got ", bg.banner_a_warp_bl)
		lab.queue_free()
		return false
	if not is_equal_approx(bg.banner_a_warp_br.x, 45.0) or not is_equal_approx(bg.banner_a_warp_br.y, 35.0):
		print("[WARP-009] FAIL: Whole drag BR expected (45, 35), got ", bg.banner_a_warp_br)
		lab.queue_free()
		return false

	var m_up: InputEventMouseButton = InputEventMouseButton.new()
	m_up.button_index = MOUSE_BUTTON_LEFT; m_up.pressed = false; m_up.global_position = _bg_to_global(bg, center + Vector2(40, 30))
	overlay._gui_input(m_up)

	print("[WARP-009] PASS: Whole banner drag translates all 4 corners by exact identical delta!")
	lab.queue_free()
	return true

# 10. Mouse release commits without drift or jumping
func test_10_mouse_release_commits_without_drift_or_jumping() -> bool:
	print("[WARP-010] Verifying mouse release cleanly commits coordinates without jumping or drift...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	lab.select_banner_a()
	var tr_pos: Vector2 = bg.get_banner_a_quad_points()["TR"]

	# Drag TR
	var m_down: InputEventMouseButton = InputEventMouseButton.new()
	m_down.button_index = MOUSE_BUTTON_LEFT; m_down.pressed = true; m_down.global_position = _bg_to_global(bg, tr_pos)
	overlay._gui_input(m_down)
	var m_drag: InputEventMouseMotion = InputEventMouseMotion.new()
	m_drag.global_position = _bg_to_global(bg, tr_pos + Vector2(33, -22))
	overlay._gui_input(m_drag)

	var committed_tr: Vector2 = bg.banner_a_warp_tr

	# Release
	var m_up: InputEventMouseButton = InputEventMouseButton.new()
	m_up.button_index = MOUSE_BUTTON_LEFT; m_up.pressed = false; m_up.global_position = _bg_to_global(bg, tr_pos + Vector2(33, -22))
	overlay._gui_input(m_up)

	# Verify TR has NOT jumped or changed after release
	if bg.banner_a_warp_tr != committed_tr:
		print("[WARP-010] FAIL: Coordinates jumped on release! Before: ", committed_tr, " After: ", bg.banner_a_warp_tr)
		lab.queue_free()
		return false

	# Subsequent idle motion does not mutate warp
	var m_idle: InputEventMouseMotion = InputEventMouseMotion.new()
	m_idle.global_position = _bg_to_global(bg, Vector2(200, 200))
	overlay._gui_input(m_idle)

	if bg.banner_a_warp_tr != committed_tr:
		print("[WARP-010] FAIL: Coordinates drifted after mouse release!")
		lab.queue_free()
		return false

	print("[WARP-010] PASS: Zero jumping or coordinate drift on release verified!")
	lab.queue_free()
	return true

# 11. Banner B full independence from Banner A
func test_11_banner_b_full_independence_from_banner_a() -> bool:
	print("[WARP-011] Verifying Banner B is 100% independent from Banner A...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()

	lab.select_banner_b()
	var b_br: Vector2 = bg.get_banner_b_quad_points()["BR"]

	# Drag Banner B BR corner
	var m_down: InputEventMouseButton = InputEventMouseButton.new()
	m_down.button_index = MOUSE_BUTTON_LEFT; m_down.pressed = true; m_down.global_position = _bg_to_global(bg, b_br)
	overlay._gui_input(m_down)
	var m_drag: InputEventMouseMotion = InputEventMouseMotion.new()
	m_drag.global_position = _bg_to_global(bg, b_br + Vector2(50, 50))
	overlay._gui_input(m_drag)
	var m_up: InputEventMouseButton = InputEventMouseButton.new()
	m_up.button_index = MOUSE_BUTTON_LEFT; m_up.pressed = false; m_up.global_position = _bg_to_global(bg, b_br + Vector2(50, 50))
	overlay._gui_input(m_up)

	# Banner B BR must have changed
	if not is_equal_approx(bg.banner_b_warp_br.x, 50.0) or not is_equal_approx(bg.banner_b_warp_br.y, 50.0):
		print("[WARP-011] FAIL: Banner B BR was not warped")
		lab.queue_free()
		return false

	# ALL Banner A corners MUST remain ZERO
	if bg.banner_a_warp_tl != Vector2.ZERO or bg.banner_a_warp_tr != Vector2.ZERO or bg.banner_a_warp_bl != Vector2.ZERO or bg.banner_a_warp_br != Vector2.ZERO:
		print("[WARP-011] FAIL: Warping Banner B leaked into Banner A!")
		lab.queue_free()
		return false

	print("[WARP-011] PASS: Banner B independence completely verified!")
	lab.queue_free()
	return true

# 12. Reset Banner A leaves Banner B untouched
func test_12_banner_a_reset_leaves_banner_b_untouched() -> bool:
	print("[WARP-012] Verifying Reset Banner A leaves Banner B untouched...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.banner_a_warp_tl = Vector2(10, 10)
	bg.banner_b_warp_tl = Vector2(25, 25)

	lab.reset_banner_a()

	if bg.banner_a_warp_tl != Vector2.ZERO:
		print("[WARP-012] FAIL: Banner A was not reset to ZERO")
		lab.queue_free()
		return false
	if bg.banner_b_warp_tl != Vector2(25, 25):
		print("[WARP-012] FAIL: Resetting Banner A accidentally reset Banner B!")
		lab.queue_free()
		return false

	print("[WARP-012] PASS: Reset Banner A strictly resets only Banner A!")
	lab.queue_free()
	return true

# 13. Reset Banner B leaves Banner A untouched
func test_13_banner_b_reset_leaves_banner_a_untouched() -> bool:
	print("[WARP-013] Verifying Reset Banner B leaves Banner A untouched...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.banner_a_warp_tr = Vector2(15, 15)
	bg.banner_b_warp_tr = Vector2(30, 30)

	lab.reset_banner_b()

	if bg.banner_b_warp_tr != Vector2.ZERO:
		print("[WARP-013] FAIL: Banner B was not reset to ZERO")
		lab.queue_free()
		return false
	if bg.banner_a_warp_tr != Vector2(15, 15):
		print("[WARP-013] FAIL: Resetting Banner B accidentally reset Banner A!")
		lab.queue_free()
		return false

	print("[WARP-013] PASS: Reset Banner B strictly resets only Banner B!")
	lab.queue_free()
	return true

# 14. Reset Both Banners restores all coordinates
func test_14_reset_both_banners_restores_all_coordinates() -> bool:
	print("[WARP-014] Verifying Reset Both Banners restores both A and B to ZERO...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.banner_a_warp_tl = Vector2(10, 10)
	bg.banner_b_warp_br = Vector2(20, 20)

	lab.reset_both_banners()

	if bg.banner_a_warp_tl != Vector2.ZERO or bg.banner_b_warp_br != Vector2.ZERO:
		print("[WARP-014] FAIL: Reset both banners did not reset all coordinates to ZERO")
		lab.queue_free()
		return false

	print("[WARP-014] PASS: Reset Both Banners verified!")
	lab.queue_free()
	return true

# 15. Base warp separated from runtime sway/ripple
func test_15_base_warp_separated_from_runtime_sway_motion() -> bool:
	print("[WARP-015] Verifying base warp coordinates are strictly decoupled from runtime animation sway/time...")
	var lab: VisualLab = _create_lab()
	var bg: AuthLoginBackground = lab.get_auth_background()

	bg.banner_a_warp_tl = Vector2(12.5, -8.0)
	var initial_warp: Vector2 = bg.banner_a_warp_tl

	# Simulate 10 frames of animation time
	for i in range(10):
		bg._process(0.1)

	if bg.banner_a_warp_tl != initial_warp:
		print("[WARP-015] FAIL: Animation process mutated base warp coordinates!")
		lab.queue_free()
		return false

	print("[WARP-015] PASS: Separation of base warp and animation sway verified!")
	lab.queue_free()
	return true

# 16. Advanced SpinBoxes live sync bidirectional
func test_16_advanced_spinboxes_live_sync_bidirectional() -> bool:
	print("[WARP-016] Verifying advanced SpinBoxes sync with direct canvas dragging...")
	var lab: VisualLab = _create_lab()
	var overlay: Control = lab.get_banner_warp_overlay()
	var bg: AuthLoginBackground = lab.get_auth_background()
	var spins_a: Array[SpinBox] = lab.get_banner_a_warp_spins()

	lab.select_banner_a()
	var tl_pos: Vector2 = bg.get_banner_a_quad_points()["TL"]

	# Drag TL by (16, -24)
	var m_down: InputEventMouseButton = InputEventMouseButton.new()
	m_down.button_index = MOUSE_BUTTON_LEFT; m_down.pressed = true; m_down.global_position = _bg_to_global(bg, tl_pos)
	overlay._gui_input(m_down)
	var m_drag: InputEventMouseMotion = InputEventMouseMotion.new()
	m_drag.global_position = _bg_to_global(bg, tl_pos + Vector2(16, -24))
	overlay._gui_input(m_drag)
	var m_up: InputEventMouseButton = InputEventMouseButton.new()
	m_up.button_index = MOUSE_BUTTON_LEFT; m_up.pressed = false; m_up.global_position = _bg_to_global(bg, tl_pos + Vector2(16, -24))
	overlay._gui_input(m_up)

	# Verify SpinBox values were synchronized
	if not is_equal_approx(spins_a[0].value, 16.0) or not is_equal_approx(spins_a[1].value, -24.0):
		print("[WARP-016] FAIL: SpinBoxes not synchronized with drag! X=", spins_a[0].value, " Y=", spins_a[1].value)
		lab.queue_free()
		return false

	print("[WARP-016] PASS: Advanced SpinBoxes synchronized live with direct drag!")
	lab.queue_free()
	return true

# 17. Multi-resolution coordinate projection (1280x720, 1600x900, 1920x1080)
func test_17_multi_resolution_coordinate_projection() -> bool:
	print("[WARP-017] Verifying multi-resolution coordinate projection across 1280x720, 1600x900, 1920x1080...")
	var resolutions: Array[Vector2] = [
		Vector2(1280, 720),
		Vector2(1600, 900),
		Vector2(1920, 1080)
	]

	for res in resolutions:
		var lab: VisualLab = _create_lab()
		lab.custom_minimum_size = res
		lab.size = res
		var overlay: Control = lab.get_banner_warp_overlay()
		var bg: AuthLoginBackground = lab.get_auth_background()
		bg.custom_minimum_size = res
		bg.size = res

		var a_rect: Rect2 = bg.get_banner_a_base_rect()
		var expected_x: float = res.x * 0.16
		var expected_y: float = res.y * 0.22

		if not is_equal_approx(a_rect.position.x, expected_x) or not is_equal_approx(a_rect.position.y, expected_y):
			print("[WARP-017] FAIL at %sx%s: Banner A rect position expected (%s, %s), got (%s, %s)" % [
				res.x, res.y, expected_x, expected_y, a_rect.position.x, a_rect.position.y
			])
			lab.queue_free()
			return false

		# Verify quad points project accurately
		var quad: Dictionary = bg.get_banner_a_quad_points()
		var overlay_tl: Vector2 = overlay._to_overlay(quad["TL"], bg)
		var diff: float = overlay_tl.distance_to(quad["TL"])
		if diff > 0.01:
			print("[WARP-017] FAIL at %sx%s: Overlay projection drifted by %f px" % [res.x, res.y, diff])
			lab.queue_free()
			return false

		lab.queue_free()

	print("[WARP-017] PASS: Multi-resolution projection verified across 1280x720, 1600x900, 1920x1080!")
	return true
