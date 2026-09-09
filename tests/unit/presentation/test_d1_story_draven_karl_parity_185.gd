class_name TestD1StoryDravenKarlParity185
extends SceneTree

## Dedicated Verification Suite for TASK-185: Story / Draven & Karl Runtime Parity Fix
## Validates all 10 acceptance checks:
## 1. Story character slot bounds (340x480, clip_contents)
## 2. Dialogue panel bounds (>= 840x210, dark translucent styling)
## 3. No Draven / dialogue overlap (distance >= 24px, zero intersection)
## 4. No lower white artifact (shader discard, no opaque white in gradient)
## 5. Karl avatar != Draven asset (in SanctumNexusHub)
## 6. Zero remote URL use (no http/https)
## 7. CTA button visible ("VÀO BÀI HỌC", >= 166x38)
## 8. Multi-resolution responsiveness (1280x720, 1366x768, 1600x900, 1920x1080, 1280x680)
## 9. Story -> Lesson transition intact
## 10. Canonical story content strictly preserved

const StoryPanel = preload("res://src/ui/story/story_panel.gd")
const SanctumNexusHub = preload("res://src/ui/hub/sanctum_nexus_hub.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func _create_story_panel(p_size: Vector2 = Vector2(1280, 720)) -> StoryPanel:
	var scene: PackedScene = load("res://src/ui/story/story_panel.tscn") as PackedScene
	var panel: StoryPanel = null
	if scene != null:
		panel = scene.instantiate() as StoryPanel
	else:
		panel = StoryPanel.new()
	panel.size = p_size
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(panel)
	if not panel.is_node_ready():
		panel._ready()
	return panel

static func _remove_panel(panel: Node) -> void:
	if panel != null:
		if panel.get_parent() != null:
			panel.get_parent().remove_child(panel)
		panel.free()

static func run_all_tests() -> bool:
	print("==================================================")
	print("D1 STORY DRAVEN & KARL PARITY VERIFICATION (TASK-185)")
	print("==================================================")
	var pass_count: int = 0

	if test_01_story_character_slot_bounds(): pass_count += 1
	if test_02_dialogue_panel_bounds(): pass_count += 1
	if test_03_no_draven_dialogue_overlap(): pass_count += 1
	if test_04_no_lower_white_artifact(): pass_count += 1
	if test_05_karl_avatar_not_draven(): pass_count += 1
	if test_06_zero_remote_url_use(): pass_count += 1
	if test_07_cta_button_visible(): pass_count += 1
	if test_08_responsive_resolutions(): pass_count += 1
	if test_09_story_to_lesson_transition(): pass_count += 1
	if test_10_canonical_story_content_preserved(): pass_count += 1

	print("==================================================")
	print("TASK-185 PARITY SUMMARY: %d / 10 passed" % pass_count)
	print("==================================================")
	return pass_count == 10

static func test_01_story_character_slot_bounds() -> bool:
	print("[PARITY-185-01] Testing story character slot bounds...")
	var panel: StoryPanel = _create_story_panel()

	var slot: Control = panel.get_character_slot()
	if slot == null:
		print("[PARITY-185-01] FAIL: Character slot is null")
		_remove_panel(panel)
		return false

	if slot.custom_minimum_size.x != 340.0 or slot.custom_minimum_size.y != 480.0:
		print("[PARITY-185-01] FAIL: Slot custom_minimum_size is %s, expected (340, 480)" % str(slot.custom_minimum_size))
		_remove_panel(panel)
		return false

	if not slot.clip_contents:
		print("[PARITY-185-01] FAIL: Slot clip_contents should be true")
		_remove_panel(panel)
		return false

	_remove_panel(panel)
	print("[PARITY-185-01] PASS: Character slot bounds verified (340x480, clip_contents=true)")
	return true

static func test_02_dialogue_panel_bounds() -> bool:
	print("[PARITY-185-02] Testing dialogue panel bounds & styling...")
	var panel: StoryPanel = _create_story_panel()

	var dlg: Control = panel.get_dialogue_panel()
	if dlg == null:
		print("[PARITY-185-02] FAIL: Dialogue panel is null")
		_remove_panel(panel)
		return false

	if dlg.custom_minimum_size.x < 840.0 or dlg.custom_minimum_size.y < 210.0:
		print("[PARITY-185-02] FAIL: Dialogue custom_minimum_size is %s, expected >= (840, 210)" % str(dlg.custom_minimum_size))
		_remove_panel(panel)
		return false

	var sb: StyleBox = dlg.get_theme_stylebox("panel")
	if not (sb is StyleBoxFlat):
		print("[PARITY-185-02] FAIL: Dialogue stylebox is not StyleBoxFlat")
		_remove_panel(panel)
		return false

	var sbf: StyleBoxFlat = sb as StyleBoxFlat
	if sbf.bg_color.r > 0.15 or sbf.bg_color.a >= 1.0:
		print("[PARITY-185-02] FAIL: Dialogue bg_color is not dark translucent: %s" % str(sbf.bg_color))
		_remove_panel(panel)
		return false

	_remove_panel(panel)
	print("[PARITY-185-02] PASS: Dialogue panel bounds & styling verified (>= 840x210, dark glass)")
	return true

static func test_03_no_draven_dialogue_overlap() -> bool:
	print("[PARITY-185-03] Testing Draven and dialogue non-overlap...")
	var panel: StoryPanel = _create_story_panel()

	if panel.has_draven_dialogue_overlap():
		print("[PARITY-185-03] FAIL: has_draven_dialogue_overlap returned true")
		_remove_panel(panel)
		return false

	var stage_margin: Control = panel.get_node_or_null("CharacterAndDialogueStage") as Control
	if stage_margin != null:
		var stage_hbox: HBoxContainer = stage_margin.get_node_or_null("StageHBox") as HBoxContainer
		if stage_hbox != null:
			var sep: int = stage_hbox.get_theme_constant("separation")
			if sep < 24:
				print("[PARITY-185-03] FAIL: StageHBox separation is %d, expected >= 24" % sep)
				_remove_panel(panel)
				return false

	_remove_panel(panel)
	print("[PARITY-185-03] PASS: Draven and dialogue are strictly separated without overlap")
	return true

static func test_04_no_lower_white_artifact() -> bool:
	print("[PARITY-185-04] Testing no lower white artifact in portrait...")
	var panel: StoryPanel = _create_story_panel()

	var mat: ShaderMaterial = panel.get_draven_shader_material()
	if mat == null or mat.shader == null:
		print("[PARITY-185-04] FAIL: Draven shader material or shader is null")
		_remove_panel(panel)
		return false

	var shader_code: String = mat.shader.code
	if not shader_code.contains("discard;"):
		print("[PARITY-185-04] FAIL: Fragment shader missing discard statement")
		_remove_panel(panel)
		return false

	var portrait_container: Control = panel.get_node_or_null("CharacterAndDialogueStage/StageHBox/DravenSlotVBox/PortraitContainer") as Control
	if portrait_container != null:
		var grad_rect: TextureRect = portrait_container.get_node_or_null("DravenLowerFadeGradient") as TextureRect
		if grad_rect != null and grad_rect.texture is GradientTexture2D:
			var grad: Gradient = (grad_rect.texture as GradientTexture2D).gradient
			if grad != null:
				for col in grad.colors:
					if col.r > 0.8 and col.g > 0.8 and col.b > 0.8 and col.a > 0.5:
						print("[PARITY-185-04] FAIL: Gradient contains white artifact color: %s" % str(col))
						_remove_panel(panel)
						return false

	_remove_panel(panel)
	print("[PARITY-185-04] PASS: Portrait shader discards transparent fragments and gradient has zero white artifacts")
	return true

static func test_05_karl_avatar_not_draven() -> bool:
	print("[PARITY-185-05] Testing Karl avatar binding in SanctumNexusHub...")
	var hub_script: GDScript = load("res://src/ui/hub/sanctum_nexus_hub.gd") as GDScript
	if hub_script == null:
		print("[PARITY-185-05] FAIL: Could not load sanctum_nexus_hub.gd")
		return false

	var src: String = hub_script.source_code
	if src.contains("DRAVEN_PORTRAIT_PATH"):
		print("[PARITY-185-05] FAIL: sanctum_nexus_hub.gd still references DRAVEN_PORTRAIT_PATH")
		return false

	if not src.contains("KARL_PORTRAIT_PATH"):
		print("[PARITY-185-05] FAIL: sanctum_nexus_hub.gd does not define KARL_PORTRAIT_PATH")
		return false

	var hub: SanctumNexusHub = SanctumNexusHub.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)
	if not hub.is_node_ready():
		hub._ready()

	var avatar_rect: TextureRect = hub.get_node_or_null("VBox/TopBarMargin/TopBarHBox/LeftPlayerCard/AvatarMargin/AvatarContainer/AvatarTexture") as TextureRect
	if avatar_rect != null and avatar_rect.texture != null:
		var draven_tex: Texture2D = load("res://assets/characters/story/draven/draven_portrait.png") as Texture2D
		if avatar_rect.texture == draven_tex or (avatar_rect.texture.resource_path != "" and avatar_rect.texture.resource_path.contains("draven")):
			print("[PARITY-185-05] FAIL: Karl avatar texture is Draven's portrait!")
			_remove_panel(hub)
			return false

	_remove_panel(hub)
	print("[PARITY-185-05] PASS: Karl avatar is correctly decoupled from Draven portrait")
	return true

static func test_06_zero_remote_url_use() -> bool:
	print("[PARITY-185-06] Testing zero remote URL use...")
	var files_to_check: Array[String] = [
		"res://src/ui/story/story_panel.gd",
		"res://src/ui/hub/sanctum_nexus_hub.gd"
	]
	for fpath in files_to_check:
		var script: GDScript = load(fpath) as GDScript
		if script != null:
			var code: String = script.source_code
			if code.contains("http://") or code.contains("https://"):
				print("[PARITY-185-06] FAIL: Found remote URL in %s" % fpath)
				return false

	print("[PARITY-185-06] PASS: Zero remote URL references detected")
	return true

static func test_07_cta_button_visible() -> bool:
	print("[PARITY-185-07] Testing CTA button configuration...")
	var panel: StoryPanel = _create_story_panel()

	var btn: Button = panel.get_continue_button()
	if btn == null:
		print("[PARITY-185-07] FAIL: Continue button is null")
		_remove_panel(panel)
		return false

	if btn.text != "VÀO BÀI HỌC":
		print("[PARITY-185-07] FAIL: Button text is '%s', expected 'VÀO BÀI HỌC'" % btn.text)
		_remove_panel(panel)
		return false

	if btn.custom_minimum_size.x < 166.0 or btn.custom_minimum_size.y < 38.0:
		print("[PARITY-185-07] FAIL: Button size is %s, expected >= (166, 38)" % str(btn.custom_minimum_size))
		_remove_panel(panel)
		return false

	_remove_panel(panel)
	print("[PARITY-185-07] PASS: CTA button text ('VÀO BÀI HỌC') and dimensions verified")
	return true

static func test_08_responsive_resolutions() -> bool:
	print("[PARITY-185-08] Testing responsive layouts...")
	var resolutions: Array[Vector2] = [
		Vector2(1280, 720),
		Vector2(1366, 768),
		Vector2(1600, 900),
		Vector2(1920, 1080),
		Vector2(1280, 680)
	]
	for res in resolutions:
		var panel: StoryPanel = _create_story_panel(res)

		if panel.has_draven_dialogue_overlap():
			print("[PARITY-185-08] FAIL: Overlap detected at resolution %s" % str(res))
			_remove_panel(panel)
			return false

		var slot: Control = panel.get_character_slot()
		var dlg: Control = panel.get_dialogue_panel()
		if slot == null or dlg == null:
			print("[PARITY-185-08] FAIL: Slot or dlg null at resolution %s" % str(res))
			_remove_panel(panel)
			return false

		_remove_panel(panel)

	print("[PARITY-185-08] PASS: All 5 resolutions maintain clean non-overlapping layout")
	return true

static func test_09_story_to_lesson_transition() -> bool:
	print("[PARITY-185-09] Testing story to lesson transition signal...")
	var panel: StoryPanel = _create_story_panel()

	var signal_emitted: Array[bool] = [false]
	panel.continue_requested.connect(func(): signal_emitted[0] = true)

	panel._on_continue_pressed()

	if not signal_emitted[0]:
		print("[PARITY-185-09] FAIL: continue_requested signal was not emitted")
		_remove_panel(panel)
		return false

	_remove_panel(panel)
	print("[PARITY-185-09] PASS: Story to lesson transition cleanly emits continue_requested")
	return true

static func test_10_canonical_story_content_preserved() -> bool:
	print("[PARITY-185-10] Testing canonical story copy & badges...")
	var panel: StoryPanel = _create_story_panel()

	var body: RichTextLabel = panel.get_body_text_label()
	var expected_text: String = "Karl! Rừng Mù Sương bị bao phủ bởi Ma Thuật Ngẫu Nhiên. Mọi hành động ở đây đều là một phép thử — ta không thể biết trước kết quả, nhưng có thể lường trước mọi khả năng!"
	if body == null or body.text != expected_text:
		print("[PARITY-185-10] FAIL: Body text mismatch: '%s'" % (body.text if body != null else "null"))
		_remove_panel(panel)
		return false

	var speaker: Label = panel.get_speaker_label()
	if speaker == null or speaker.text != "DRAVEN":
		print("[PARITY-185-10] FAIL: Speaker label is '%s', expected 'DRAVEN'" % (speaker.text if speaker != null else "null"))
		_remove_panel(panel)
		return false

	var badge: Label = panel.get_phase_badge_label()
	if badge == null or badge.text != "CỐT TRUYỆN":
		print("[PARITY-185-10] FAIL: Phase badge is '%s', expected 'CỐT TRUYỆN'" % (badge.text if badge != null else "null"))
		_remove_panel(panel)
		return false

	var nameplate_name: Label = panel.get_nameplate_name_label()
	if nameplate_name == null or nameplate_name.text != "DRAVEN":
		print("[PARITY-185-10] FAIL: Nameplate name is '%s', expected 'DRAVEN'" % (nameplate_name.text if nameplate_name != null else "null"))
		_remove_panel(panel)
		return false

	var subtitle: Label = panel.get_nameplate_subtitle_label()
	if subtitle == null or subtitle.text != "ĐẠI PHÁP SƯ HƯỚNG DẪN":
		print("[PARITY-185-10] FAIL: Nameplate subtitle is '%s', expected 'ĐẠI PHÁP SƯ HƯỚNG DẪN'" % (subtitle.text if subtitle != null else "null"))
		_remove_panel(panel)
		return false

	_remove_panel(panel)
	print("[PARITY-185-10] PASS: All canonical story texts and badges strictly preserved")
	return true
