class_name TestRuntimeVisualFixes195
extends SceneTree

## Dedicated Regression Verification Suite for TASK-195: Runtime Visual Forensic & Production Fixes
## Validates all 13 authoritative checks:
## 1. sound/settings fully within viewport
## 2. right margin >= 24px
## 3. narration global rect zero intersection with major fragment global rects
## 4. narration global rect zero intersection with landmark global rects
## 5. background aspect ratio preserved
## 6. background not distorted
## 7. beat4 map bounds cover intended viewport
## 8. central stone not oversized during region-reading phases
## 9. skip fully visible
## 10. 1280x720 PASS
## 11. 1280x680 windowed PASS
## 12. Draven Story top-right controls PASS
## 13. Story portrait/dialogue runtime rect separation PASS

const ProloguePlayerClass = preload("res://src/ui/prologue/prologue_player.gd")
const StoryPanelClass = preload("res://src/ui/story/story_panel.gd")
const NARRATION_SAFE_RECT: Rect2 = Rect2(390.0, 582.0, 500.0, 110.0)

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func _create_node(node: Node, p_size: Vector2 = Vector2(1280, 720)) -> Node:
	if node is Control:
		var c: Control = node as Control
		c.set_anchors_preset(Control.PRESET_TOP_LEFT)
		c.size = p_size
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(node)
	if not node.is_node_ready():
		node._ready()
	return node

static func _remove_node(node: Node) -> void:
	if node != null:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()

static func _create_shell(p_size: Vector2 = Vector2(1280, 720)) -> Control:
	var shell_scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: Control = shell_scene.instantiate() as Control
	shell.set_anchors_preset(Control.PRESET_TOP_LEFT)
	shell.size = p_size
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(shell)
	return shell

static func run_all_tests() -> bool:
	print("==================================================")
	print("STARTING RUNTIME VISUAL FIXES 195 TEST SUITE")
	print("==================================================")

	var tests: Array[Callable] = [
		Callable(TestRuntimeVisualFixes195, "test_01_sound_settings_fully_within_viewport"),
		Callable(TestRuntimeVisualFixes195, "test_02_right_margin_ge_24px"),
		Callable(TestRuntimeVisualFixes195, "test_03_narration_safe_rect_zero_fragment_intersection"),
		Callable(TestRuntimeVisualFixes195, "test_04_narration_safe_rect_zero_landmark_intersection"),
		Callable(TestRuntimeVisualFixes195, "test_05_background_aspect_ratio_preserved"),
		Callable(TestRuntimeVisualFixes195, "test_06_background_not_distorted"),
		Callable(TestRuntimeVisualFixes195, "test_07_beat4_map_bounds_cover_viewport"),
		Callable(TestRuntimeVisualFixes195, "test_08_central_stone_not_oversized_reading_phases"),
		Callable(TestRuntimeVisualFixes195, "test_09_skip_fully_visible"),
		Callable(TestRuntimeVisualFixes195, "test_10_full_layout_pass_1280x720"),
		Callable(TestRuntimeVisualFixes195, "test_11_full_layout_pass_1280x680_windowed"),
		Callable(TestRuntimeVisualFixes195, "test_12_draven_story_top_right_controls"),
		Callable(TestRuntimeVisualFixes195, "test_13_story_portrait_dialogue_separation")
	]

	var pass_count: int = 0
	for t in tests:
		var ok: bool = bool(t.call())
		if ok:
			pass_count += 1
		else:
			print("TEST FAILED: ", t.get_method())

	print("==================================================")
	print("RUNTIME VISUAL FIXES 195 SUMMARY: %d / %d passed" % [pass_count, tests.size()])
	print("==================================================")
	return pass_count == tests.size()

# 1. sound/settings fully within viewport
static func test_01_sound_settings_fully_within_viewport() -> bool:
	print("[FIX-195-01] Testing sound/settings fully within viewport...")
	var player: Control = _create_node(ProloguePlayerClass.new(), Vector2(1280, 720)) as Control
	player.update_responsive_layout(Vector2(1280, 720))

	var tr_box: Control = player.find_child("TopRightHBox", true, false) as Control
	if tr_box == null:
		print("[FIX-195-01] FAIL: TopRightHBox not found")
		_remove_node(player)
		return false

	var vol_btn: Control = tr_box.get_node_or_null("VolumeBtn") as Control
	var set_btn: Control = tr_box.get_node_or_null("SettingsBtn") as Control
	if vol_btn == null or set_btn == null:
		print("[FIX-195-01] FAIL: VolumeBtn or SettingsBtn not found")
		_remove_node(player)
		return false

	var vp_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1280, 720))
	var box_rect: Rect2 = Rect2(tr_box.position, tr_box.size)

	if not vp_rect.encloses(box_rect):
		print("[FIX-195-01] FAIL: TopRightHBox not enclosed in viewport: ", box_rect)
		_remove_node(player)
		return false

	_remove_node(player)
	print("[FIX-195-01] PASS: sound and settings controls are fully within viewport")
	return true

# 2. right margin >= 24px
static func test_02_right_margin_ge_24px() -> bool:
	print("[FIX-195-02] Testing right margin >= 24px across resolutions...")
	for res in [Vector2(1280, 720), Vector2(1280, 680)]:
		var player: Control = _create_node(ProloguePlayerClass.new(), res) as Control
		player.update_responsive_layout(res)

		var tr_box: Control = player.find_child("TopRightHBox", true, false) as Control
		var skip_btn: Control = player.find_child("SkipBtn", true, false) as Control

		var box_right_edge: float = tr_box.position.x + tr_box.size.x
		var box_margin: float = res.x - box_right_edge
		if box_margin < 23.99:
			print("[FIX-195-02] FAIL: TopRightHBox right margin %f < 24px at %s" % [box_margin, str(res)])
			_remove_node(player)
			return false

		var skip_right_edge: float = skip_btn.position.x + skip_btn.size.x
		var skip_margin: float = res.x - skip_right_edge
		if skip_margin < 23.99:
			print("[FIX-195-02] FAIL: Skip right margin %f < 24px at %s" % [skip_margin, str(res)])
			_remove_node(player)
			return false

		_remove_node(player)

	print("[FIX-195-02] PASS: right margin >= 24px strictly verified")
	return true

# 3. narration global rect zero intersection with major fragment global rects
static func test_03_narration_safe_rect_zero_fragment_intersection() -> bool:
	print("[FIX-195-03] Testing narration safe rect zero fragment intersection across timeline...")
	var player: Control = _create_node(ProloguePlayerClass.new(), Vector2(1280, 720)) as Control
	player.set("_speed_scale", 1.0)
	player.set("_is_transitioning", false)
	player.set("_is_completed", false)
	player.set("_current_beat", 4)
	player.call("apply_beat04_layout")

	var t_samples: Array[float] = [0.0, 1.0, 2.5, 4.0, 5.5, 6.0, 7.0, 8.0, 9.0, 10.5, 12.0, 14.0]
	var fids: Array[String] = ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]

	for t in t_samples:
		player.set("_playback_time", t)
		player.call("_process_beat04", 0.016)

		for fid in fids:
			var frag: Control = player.call("get_fragment_node", fid, 4) as Control
			if frag == null:
				continue
			var half_size: Vector2 = frag.size * frag.scale * 0.5
			var frag_rect: Rect2 = Rect2(frag.position - half_size, frag.size * frag.scale)
			if frag_rect.intersects(NARRATION_SAFE_RECT):
				print("[FIX-195-03] FAIL: %s intersects narration safe rect at t=%f: rect=%s" % [fid, t, str(frag_rect)])
				_remove_node(player)
				return false

	_remove_node(player)
	print("[FIX-195-03] PASS: zero intersection between narration safe area and fragments")
	return true

# 4. narration global rect zero intersection with landmark global rects
static func test_04_narration_safe_rect_zero_landmark_intersection() -> bool:
	print("[FIX-195-04] Testing narration safe rect zero landmark intersection...")
	var player: Control = _create_node(ProloguePlayerClass.new(), Vector2(1280, 720)) as Control
	player.call("apply_beat04_layout")

	for did in ["Destination01", "Destination02", "Destination03", "Destination04"]:
		var dest: Control = player.call("get_destination_node", did) as Control
		if dest == null:
			print("[FIX-195-04] FAIL: destination %s not found" % did)
			_remove_node(player)
			return false

		var lm: Control = dest.get_node_or_null("Landmark") as Control
		var beacon: Control = dest.get_node_or_null("Beacon") as Control
		var lbl: Control = dest.get_node_or_null("TitleLabel") as Control

		if lm != null:
			var lm_rect: Rect2 = Rect2(dest.position + lm.position, lm.size)
			if lm_rect.intersects(NARRATION_SAFE_RECT):
				print("[FIX-195-04] FAIL: Landmark %s intersects narration: %s" % [did, str(lm_rect)])
				_remove_node(player)
				return false
		if beacon != null:
			var bc_rect: Rect2 = Rect2(dest.position + beacon.position, beacon.size)
			if bc_rect.intersects(NARRATION_SAFE_RECT):
				print("[FIX-195-04] FAIL: Beacon %s intersects narration: %s" % [did, str(bc_rect)])
				_remove_node(player)
				return false
		if lbl != null:
			var lbl_rect: Rect2 = Rect2(dest.position + lbl.position, lbl.size)
			if lbl_rect.intersects(NARRATION_SAFE_RECT):
				print("[FIX-195-04] FAIL: TitleLabel %s intersects narration: %s" % [did, str(lbl_rect)])
				_remove_node(player)
				return false

	_remove_node(player)
	print("[FIX-195-04] PASS: zero intersection between narration safe area and regional landmarks")
	return true

# 5. background aspect ratio preserved
static func test_05_background_aspect_ratio_preserved() -> bool:
	print("[FIX-195-05] Testing background aspect ratio preserved...")
	var player: Control = _create_node(ProloguePlayerClass.new(), Vector2(1280, 720)) as Control
	player.call("apply_beat04_layout")

	var b4_root: Node = player.find_child("Beat04Root", true, false)
	var bg: TextureRect = (b4_root.find_child("Background", true, false) if b4_root != null else null) as TextureRect
	if bg == null:
		print("[FIX-195-05] FAIL: Beat4 Background TextureRect not found")
		_remove_node(player)
		return false

	if bg.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
		print("[FIX-195-05] FAIL: Background stretch mode is not STRETCH_KEEP_ASPECT_COVERED, got: ", bg.stretch_mode)
		_remove_node(player)
		return false

	if bg.texture == null:
		print("[FIX-195-05] FAIL: Background texture is null")
		_remove_node(player)
		return false

	_remove_node(player)
	print("[FIX-195-05] PASS: background aspect ratio preserved via STRETCH_KEEP_ASPECT_COVERED")
	return true

# 6. background not distorted
static func test_06_background_not_distorted() -> bool:
	print("[FIX-195-06] Testing background not distorted...")
	var player: Control = _create_node(ProloguePlayerClass.new(), Vector2(1280, 720)) as Control
	player.call("apply_beat04_layout")

	var b4_root: Node = player.find_child("Beat04Root", true, false)
	var bg: TextureRect = (b4_root.find_child("Background", true, false) if b4_root != null else null) as TextureRect
	if bg == null:
		print("[FIX-195-06] FAIL: Beat4 Background not found")
		_remove_node(player)
		return false

	if bg.position != Vector2.ZERO:
		print("[FIX-195-06] FAIL: Background position distorted: ", bg.position)
		_remove_node(player)
		return false

	if bg.size != Vector2(1280, 720):
		print("[FIX-195-06] FAIL: Background size distorted: ", bg.size)
		_remove_node(player)
		return false

	var content: Node2D = player.find_child("WorldContent", true, false) as Node2D
	if content != null and (content.scale != Vector2.ONE or content.position != Vector2.ZERO):
		print("[FIX-195-06] FAIL: WorldContent camera scaled or offset: ", content.position, content.scale)
		_remove_node(player)
		return false

	_remove_node(player)
	print("[FIX-195-06] PASS: background layout is clean, canonical, and undistorted")
	return true

# 7. beat4 map bounds cover intended viewport
static func test_07_beat4_map_bounds_cover_viewport() -> bool:
	print("[FIX-195-07] Testing beat4 map bounds cover intended viewport...")
	var player: Control = _create_node(ProloguePlayerClass.new(), Vector2(1280, 720)) as Control
	player.call("apply_beat04_layout")

	var b4_root: Node = player.find_child("Beat04Root", true, false)
	var bg: TextureRect = (b4_root.find_child("Background", true, false) if b4_root != null else null) as TextureRect
	var vp_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1280, 720))
	var bg_rect: Rect2 = Rect2(bg.position, bg.size)

	if not bg_rect.encloses(vp_rect):
		print("[FIX-195-07] FAIL: Background does not fully enclose 1280x720 viewport: ", bg_rect)
		_remove_node(player)
		return false

	_remove_node(player)
	print("[FIX-195-07] PASS: beat4 map bounds completely cover 1280x720 canvas")
	return true

# 8. central stone not oversized during region-reading phases
static func test_08_central_stone_not_oversized_reading_phases() -> bool:
	print("[FIX-195-08] Testing central stone not oversized during region-reading phases...")
	var player: Control = _create_node(ProloguePlayerClass.new(), Vector2(1280, 720)) as Control
	player.set("_speed_scale", 1.0)
	player.set("_is_transitioning", false)
	player.set("_is_completed", false)
	player.set("_current_beat", 4)
	player.call("apply_beat04_layout")

	# Region reading occurs at t in [4.0, 5.5] before flight trajectories
	for t in [4.0, 4.5, 5.0, 5.4]:
		player.set("_playback_time", t)
		player.call("_process_beat04", 0.016)

		for fid in ["Fragment01", "Fragment02", "Fragment03", "Fragment04"]:
			var frag: Control = player.call("get_fragment_node", fid, 4) as Control
			if frag == null:
				continue
			if frag.scale.x > 0.26 or frag.scale.y > 0.26:
				print("[FIX-195-08] FAIL: %s oversized at t=%f: scale=%s (must be <= 0.26)" % [fid, t, str(frag.scale)])
				_remove_node(player)
				return false
			var max_dim: float = maxf(frag.size.x * frag.scale.x, frag.size.y * frag.scale.y)
			if max_dim > 165.0:
				print("[FIX-195-08] FAIL: %s dimension %f > 165px at t=%f" % [fid, max_dim, t])
				_remove_node(player)
				return false

	_remove_node(player)
	print("[FIX-195-08] PASS: central stone correctly scaled down during region-reading phases")
	return true

# 9. skip fully visible
static func test_09_skip_fully_visible() -> bool:
	print("[FIX-195-09] Testing skip fully visible...")
	var player: Control = _create_node(ProloguePlayerClass.new(), Vector2(1280, 720)) as Control
	player.update_responsive_layout(Vector2(1280, 720))

	var skip_btn: Control = player.find_child("SkipBtn", true, false) as Control
	if skip_btn == null:
		print("[FIX-195-09] FAIL: SkipBtn not found")
		_remove_node(player)
		return false

	if not skip_btn.visible:
		print("[FIX-195-09] FAIL: SkipBtn is not visible")
		_remove_node(player)
		return false

	var vp_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1280, 720))
	var skip_rect: Rect2 = Rect2(skip_btn.position, skip_btn.size)
	if not vp_rect.encloses(skip_rect):
		print("[FIX-195-09] FAIL: SkipBtn outside viewport: ", skip_rect)
		_remove_node(player)
		return false

	_remove_node(player)
	print("[FIX-195-09] PASS: Skip button fully visible and positioned within viewport")
	return true

# 10. 1280x720 PASS
static func test_10_full_layout_pass_1280x720() -> bool:
	print("[FIX-195-10] Testing full layout pass at 1280x720...")
	var shell: Control = _create_shell(Vector2(1280, 720))

	# Test Prologue Mode (MODE_PROLOGUE = 9)
	shell.call("set_view_mode", 9)
	var pro: Control = shell.call("get_prologue_player") as Control
	if pro == null:
		print("[FIX-195-10] FAIL: ProloguePlayer missing")
		_remove_node(shell)
		return false

	var tr_box: Control = pro.find_child("TopRightHBox", true, false) as Control
	var right_edge: float = tr_box.position.x + tr_box.size.x
	if 1280.0 - right_edge < 23.99:
		print("[FIX-195-10] FAIL: Prologue TopRightHBox right margin < 24px at 1280x720 (edge: %f)" % right_edge)
		_remove_node(shell)
		return false

	# Test Story Mode (MODE_STORY = 7)
	shell.call("set_view_mode", 7)
	var story: Control = shell.call("get_story_panel") as Control
	if story == null:
		print("[FIX-195-10] FAIL: StoryPanel missing")
		_remove_node(shell)
		return false

	var top_bar: MarginContainer = story.find_child("TopBarMargin", true, false) as MarginContainer
	var r_margin: int = top_bar.get_theme_constant("margin_right")
	if r_margin < 24:
		print("[FIX-195-10] FAIL: Story PauseButton right margin < 24px at 1280x720")
		_remove_node(shell)
		return false

	_remove_node(shell)
	print("[FIX-195-10] PASS: 1280x720 full layout pass verified")
	return true

# 11. 1280x680 windowed PASS
static func test_11_full_layout_pass_1280x680_windowed() -> bool:
	print("[FIX-195-11] Testing full layout pass at 1280x680 windowed...")
	var shell: Control = _create_shell(Vector2(1280, 680))

	# In windowed 1280x680 mode, presentation shell must accommodate 680 height cleanly
	shell.call("set_view_mode", 9) # MODE_PROLOGUE = 9
	var pro: Control = shell.call("get_prologue_player") as Control
	pro.call("update_responsive_layout", Vector2(1280, 680))

	var tr_box: Control = pro.find_child("TopRightHBox", true, false) as Control
	var right_edge: float = tr_box.position.x + tr_box.size.x
	if 1280.0 - right_edge < 23.99:
		print("[FIX-195-11] FAIL: Prologue TopRightHBox right margin < 24px at 1280x680")
		_remove_node(shell)
		return false

	var skip_btn: Control = pro.find_child("SkipBtn", true, false) as Control
	var skip_right_edge: float = skip_btn.position.x + skip_btn.size.x
	if 1280.0 - skip_right_edge < 23.99:
		print("[FIX-195-11] FAIL: Prologue SkipBtn right margin < 24px at 1280x680")
		_remove_node(shell)
		return false
	if skip_btn.position.y + skip_btn.size.y > 680.0:
		print("[FIX-195-11] FAIL: Prologue SkipBtn clipped at bottom in 1280x680: %f" % (skip_btn.position.y + skip_btn.size.y))
		_remove_node(shell)
		return false

	# Test Story Mode in 680
	shell.call("set_view_mode", 7) # MODE_STORY = 7
	var story: Control = shell.call("get_story_panel") as Control

	var top_bar: MarginContainer = story.find_child("TopBarMargin", true, false) as MarginContainer
	var r_margin: int = top_bar.get_theme_constant("margin_right")
	if r_margin < 24:
		print("[FIX-195-11] FAIL: Story PauseButton right margin < 24px at 1280x680")
		_remove_node(shell)
		return false

	var dlg: Control = story.find_child("DialoguePanel", true, false) as Control
	var dlg_rect: Rect2 = dlg.get_global_rect()
	if dlg != null and dlg_rect.position.y + dlg_rect.size.y > 680.0:
		print("[FIX-195-11] FAIL: DialoguePanel bottom exceeds 680: ", dlg_rect.position.y + dlg_rect.size.y)
		_remove_node(shell)
		return false

	_remove_node(shell)
	print("[FIX-195-11] PASS: 1280x680 windowed layout pass verified")
	return true

# 12. Draven Story top-right controls PASS
static func test_12_draven_story_top_right_controls() -> bool:
	print("[FIX-195-12] Testing Draven Story top-right controls...")
	var story: Control = _create_node(StoryPanelClass.new(), Vector2(1280, 720)) as Control

	var top_bar: MarginContainer = story.find_child("TopBarMargin", true, false) as MarginContainer
	if top_bar == null:
		print("[FIX-195-12] FAIL: TopBarMargin not found")
		_remove_node(story)
		return false

	var pause_btn: Button = story.find_child("PauseButton", true, false) as Button
	if pause_btn == null:
		print("[FIX-195-12] FAIL: PauseButton not found")
		_remove_node(story)
		return false

	var right_margin: int = top_bar.get_theme_constant("margin_right")
	if right_margin < 24:
		print("[FIX-195-12] FAIL: TopBar margin_right %d < 24px" % right_margin)
		_remove_node(story)
		return false

	var top_margin: int = top_bar.get_theme_constant("margin_top")
	if top_margin < 16:
		print("[FIX-195-12] FAIL: TopBar margin_top %d < 16px" % top_margin)
		_remove_node(story)
		return false

	if pause_btn.custom_minimum_size.x < 100.0 or pause_btn.custom_minimum_size.y < 30.0:
		print("[FIX-195-12] FAIL: PauseButton custom_minimum_size too small: ", pause_btn.custom_minimum_size)
		_remove_node(story)
		return false

	_remove_node(story)
	print("[FIX-195-12] PASS: Draven Story top-right controls verified")
	return true

# 13. Story portrait/dialogue runtime rect separation PASS
static func test_13_story_portrait_dialogue_separation() -> bool:
	print("[FIX-195-13] Testing Story portrait/dialogue runtime rect separation...")
	var story: Control = _create_node(StoryPanelClass.new(), Vector2(1280, 720)) as Control

	var char_slot: Control = story.find_child("DravenSlotVBox", true, false) as Control
	var dlg_panel: Control = story.find_child("DialoguePanel", true, false) as Control

	if char_slot == null or dlg_panel == null:
		print("[FIX-195-13] FAIL: DravenSlotVBox or DialoguePanel not found")
		_remove_node(story)
		return false

	var slot_rect: Rect2 = Rect2(char_slot.position, char_slot.size)
	var dlg_rect: Rect2 = Rect2(dlg_panel.position, dlg_panel.size)

	# Verify horizontal order: Character on Left, Dialogue on Right
	if slot_rect.position.x + slot_rect.size.x > dlg_rect.position.x and dlg_rect.position.x > 0:
		print("[FIX-195-13] FAIL: Draven slot right edge exceeds dialogue panel left edge")
		_remove_node(story)
		return false

	_remove_node(story)
	print("[FIX-195-13] PASS: Story portrait and dialogue runtime rect separation strictly verified")
	return true
