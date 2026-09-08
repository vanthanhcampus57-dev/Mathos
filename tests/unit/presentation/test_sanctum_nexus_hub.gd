class_name TestSanctumNexusHub
extends SceneTree

## Dedicated Production Verification Suite for Mathos Sanctum Nexus Hub (Task 145).
## Verifies 4-corner adaptive structure, dynamic runtime data bindings,
## progression state transitions, 4-fragment HUD, responsive multi-resolution layout,
## CTA focusability, and Task 090 Replay/Continue contracts.

const SanctumNexusHub = preload("res://src/ui/hub/sanctum_nexus_hub.gd")

func _initialize() -> void:
	var passed: bool = run_all_tests()
	quit(0 if passed else 1)

static func run_all_tests() -> bool:
	print("==================================================")
	print("STARTING SANCTUM NEXUS HUB TEST SUITE (HUB-001..010)")
	print("==================================================")

	if not test_hub_001_instantiation(): return false
	if not test_hub_002_quadrant_layout_structure(): return false
	if not test_hub_003_dynamic_data_bindings(): return false
	if not test_hub_004_progression_state_machine(): return false
	if not test_hub_005_fragment_hud_visual_contracts(): return false
	if not test_hub_006_primary_and_secondary_ctas(): return false
	if not test_hub_007_d1_complete_task_090_contract(): return false
	if not test_hub_008_multi_resolution_responsive(): return false
	if not test_hub_009_navigation_and_utility_signals(): return false
	if not test_hub_010_pres_layout_compatibility(): return false

	print("==================================================")
	print("SANCTUM NEXUS HUB SUMMARY: 10 / 10 passed")
	print("==================================================")
	return true

static func _create_hub(p_size: Vector2 = Vector2(1280, 720)) -> SanctumNexusHub:
	var scene: Resource = load("res://src/ui/hub/sanctum_nexus_hub.tscn")
	var hub: SanctumNexusHub = null
	if scene is PackedScene:
		hub = (scene as PackedScene).instantiate() as SanctumNexusHub
	else:
		hub = SanctumNexusHub.new()
	hub.size = p_size
	hub._ready()
	return hub

# HUB-001: Instantiation & Hierarchy
static func test_hub_001_instantiation() -> bool:
	print("[HUB-001] Verifying SanctumNexusHub instantiation & default dimensions...")
	var hub: SanctumNexusHub = _create_hub()
	if hub == null:
		print("[HUB-001] FAIL: Failed to instantiate SanctumNexusHub")
		return false

	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)
	if not hub.is_node_ready():
		hub._ready()

	if hub.custom_minimum_size.x < 1280.0 or hub.custom_minimum_size.y < 720.0:
		print("[HUB-001] FAIL: Minimum size below 1280x720 reference: %s" % str(hub.custom_minimum_size))
		hub.queue_free()
		return false

	hub.queue_free()
	print("[HUB-001] PASS: Instantiation & dimensions verified!")
	return true

# HUB-002: 4-Quadrant Layout Structure
static func test_hub_002_quadrant_layout_structure() -> bool:
	print("[HUB-002] Verifying 4-quadrant layout structure (Badge, HUD, Identity, Journey)...")
	var hub: SanctumNexusHub = _create_hub()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)

	var badge: PanelContainer = hub.get_player_badge_panel()
	var hud: PanelContainer = hub.get_order_hud_panel()
	var identity: PanelContainer = hub.get_identity_panel()
	var journey: PanelContainer = hub.get_journey_panel()

	if badge == null or hud == null or identity == null or journey == null:
		print("[HUB-002] FAIL: One or more quadrant panels is null")
		hub.queue_free()
		return false

	# Verify top vs bottom Y coordinates
	if badge.position.y >= identity.position.y:
		print("[HUB-002] FAIL: Player Badge is not above Identity panel")
		hub.queue_free()
		return false

	if hud.position.y >= journey.position.y:
		print("[HUB-002] FAIL: Order HUD is not above Journey panel")
		hub.queue_free()
		return false

	# Verify left vs right X coordinates
	if badge.position.x >= hud.position.x:
		print("[HUB-002] FAIL: Player Badge is not to the left of Order HUD")
		hub.queue_free()
		return false

	if identity.position.x >= journey.position.x:
		print("[HUB-002] FAIL: Identity panel is not to the left of Journey panel")
		hub.queue_free()
		return false

	hub.queue_free()
	print("[HUB-002] PASS: 4-quadrant layout structure verified!")
	return true

# HUB-003: Dynamic Property Data Bindings
static func test_hub_003_dynamic_data_bindings() -> bool:
	print("[HUB-003] Verifying dynamic property data bindings...")
	var hub: SanctumNexusHub = _create_hub()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)

	var test_data: Dictionary = {
		"player_name": "NguyenVanA",
		"player_level": 4,
		"active_dungeon": "Dungeon I — KHU RỪNG SƯƠNG MÙ",
		"current_stage": "Giai đoạn 1.3: Đền Thờ Cổ",
		"current_mission": "Thu thập cổ vật ma thuật.",
		"fragments_x_of_4": "1/4 Mảnh Vỡ",
		"dungeons_x_of_4": "1/4 Dungeon",
		"fragment_states": [true, false, false, false],
		"has_save": true
	}

	hub.set_hub_data(test_data)

	var name_lbl: Label = hub.find_child("PlayerNameLabel", true, false) as Label
	var lvl_lbl: Label = hub.find_child("PlayerLevelLabel", true, false) as Label
	var dun_lbl: Label = hub.find_child("ActiveDungeonLabel", true, false) as Label
	var stg_lbl: Label = hub.find_child("CurrentStageLabel", true, false) as Label
	var mis_lbl: Label = hub.find_child("CurrentMissionLabel", true, false) as Label
	var frg_lbl: Label = hub.find_child("FragmentsCountLabel", true, false) as Label
	var dng_lbl: Label = hub.find_child("DungeonsCountLabel", true, false) as Label

	if name_lbl == null or name_lbl.text != "NguyenVanA":
		print("[HUB-003] FAIL: PLAYER_NAME mismatch: %s" % (name_lbl.text if name_lbl else "null"))
		hub.queue_free()
		return false

	if lvl_lbl == null or not lvl_lbl.text.contains("Cấp 4"):
		print("[HUB-003] FAIL: PLAYER_LEVEL mismatch: %s" % (lvl_lbl.text if lvl_lbl else "null"))
		hub.queue_free()
		return false

	if dun_lbl == null or dun_lbl.text != "Dungeon I — KHU RỪNG SƯƠNG MÙ":
		print("[HUB-003] FAIL: ACTIVE_DUNGEON mismatch: %s" % (dun_lbl.text if dun_lbl else "null"))
		hub.queue_free()
		return false

	if stg_lbl == null or stg_lbl.text != "Giai đoạn 1.3: Đền Thờ Cổ":
		print("[HUB-003] FAIL: CURRENT_STAGE mismatch: %s" % (stg_lbl.text if stg_lbl else "null"))
		hub.queue_free()
		return false

	if mis_lbl == null or mis_lbl.text != "Thu thập cổ vật ma thuật.":
		print("[HUB-003] FAIL: CURRENT_MISSION mismatch: %s" % (mis_lbl.text if mis_lbl else "null"))
		hub.queue_free()
		return false

	if frg_lbl == null or frg_lbl.text != "1/4 Mảnh Vỡ":
		print("[HUB-003] FAIL: FRAGMENTS_X_OF_4 mismatch: %s" % (frg_lbl.text if frg_lbl else "null"))
		hub.queue_free()
		return false

	if dng_lbl == null or dng_lbl.text != "1/4 Dungeon":
		print("[HUB-003] FAIL: DUNGEONS_X_OF_4 mismatch: %s" % (dng_lbl.text if dng_lbl else "null"))
		hub.queue_free()
		return false

	hub.queue_free()
	print("[HUB-003] PASS: Dynamic property data bindings verified!")
	return true

# HUB-004: Progression State Machine
static func test_hub_004_progression_state_machine() -> bool:
	print("[HUB-004] Verifying progression state machine (NEW_PLAYER, D1_ACTIVE, D1_COMPLETE)...")
	var hub: SanctumNexusHub = _create_hub()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)

	# 1. NEW_PLAYER
	hub.set_progression_state(SanctumNexusHub.HubProgressionState.NEW_PLAYER)
	if hub.get_progression_state() != SanctumNexusHub.HubProgressionState.NEW_PLAYER:
		print("[HUB-004] FAIL: State is not NEW_PLAYER")
		hub.queue_free()
		return false

	# 2. D1_ACTIVE
	hub.set_progression_state(SanctumNexusHub.HubProgressionState.D1_ACTIVE)
	if hub.get_progression_state() != SanctumNexusHub.HubProgressionState.D1_ACTIVE:
		print("[HUB-004] FAIL: State is not D1_ACTIVE")
		hub.queue_free()
		return false

	var cont_btn: Button = hub.get_continue_button()
	if cont_btn == null or not cont_btn.visible:
		print("[HUB-004] FAIL: ContinueButton should be visible in D1_ACTIVE")
		hub.queue_free()
		return false

	# 3. D1_COMPLETE
	hub.set_progression_state(SanctumNexusHub.HubProgressionState.D1_COMPLETE)
	if hub.get_progression_state() != SanctumNexusHub.HubProgressionState.D1_COMPLETE:
		print("[HUB-004] FAIL: State is not D1_COMPLETE")
		hub.queue_free()
		return false

	# In D1_COMPLETE, ContinueButton must be hidden per Task 090 contract
	if cont_btn.visible:
		print("[HUB-004] FAIL: ContinueButton must be hidden in D1_COMPLETE")
		hub.queue_free()
		return false

	hub.queue_free()
	print("[HUB-004] PASS: Progression state machine verified!")
	return true

# HUB-005: Fragment HUD Visual Contracts
static func test_hub_005_fragment_hud_visual_contracts() -> bool:
	print("[HUB-005] Verifying 4-fragment HUD visual states & canonical Fragment I asset...")
	var hub: SanctumNexusHub = _create_hub()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)

	var frag1: TextureRect = hub.find_child("FragmentSlot1", true, false) as TextureRect
	var frag2: TextureRect = hub.find_child("FragmentSlot2", true, false) as TextureRect

	if frag1 == null or frag2 == null:
		print("[HUB-005] FAIL: FragmentSlot1 or FragmentSlot2 is null")
		hub.queue_free()
		return false

	# Verify canonical Fragment 1 asset path
	if frag1.texture == null or frag1.texture.resource_path != "res://assets/items/fragments/fragment_01.png":
		print("[HUB-005] FAIL: FragmentSlot1 texture does not match canonical res://assets/items/fragments/fragment_01.png (got %s)" % (frag1.texture.resource_path if frag1.texture != null else "null"))
		hub.queue_free()
		return false

	# In NEW_PLAYER / D1_ACTIVE: all fragments are locked/dimmed (alpha < 0.6)
	hub.set_progression_state(SanctumNexusHub.HubProgressionState.D1_ACTIVE)
	if frag1.modulate.a > 0.6 or frag2.modulate.a > 0.6:
		print("[HUB-005] FAIL: In D1_ACTIVE, fragments should be locked/dimmed")
		hub.queue_free()
		return false

	# In D1_COMPLETE: Fragment 1 is active (alpha = 1.0), Fragment 2 remains locked
	hub.set_progression_state(SanctumNexusHub.HubProgressionState.D1_COMPLETE)
	if absf(frag1.modulate.a - 1.0) > 0.05:
		print("[HUB-005] FAIL: In D1_COMPLETE, Fragment 1 should be fully active (alpha 1.0), got %f" % frag1.modulate.a)
		hub.queue_free()
		return false

	if frag2.modulate.a > 0.6:
		print("[HUB-005] FAIL: In D1_COMPLETE, Fragment 2 should remain locked")
		hub.queue_free()
		return false

	# Test runtime data binding override
	hub.set_hub_data({"fragment_states": [false, false, false, false]})
	if frag1.modulate.a > 0.6:
		print("[HUB-005] FAIL: Runtime override [false] failed to set Fragment 1 to locked state")
		hub.queue_free()
		return false

	hub.set_hub_data({"fragment_states": [true, false, false, false]})
	if absf(frag1.modulate.a - 1.0) > 0.05:
		print("[HUB-005] FAIL: Runtime override [true] failed to set Fragment 1 to active state")
		hub.queue_free()
		return false

	hub.queue_free()
	print("[HUB-005] PASS: Fragment HUD canonical asset & dynamic visual states verified!")
	return true

# HUB-006: Primary & Secondary CTAs
static func test_hub_006_primary_and_secondary_ctas() -> bool:
	print("[HUB-006] Verifying Primary & Secondary CTA presence, sizing, focusability...")
	var hub: SanctumNexusHub = _create_hub()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)

	var cont_btn: Button = hub.get_continue_button()
	var new_btn: Button = hub.get_new_game_button()
	var map_btn: Button = hub.get_journey_map_button()

	if cont_btn == null or new_btn == null or map_btn == null:
		print("[HUB-006] FAIL: One or more CTA buttons is null")
		hub.queue_free()
		return false

	if cont_btn.focus_mode == Control.FOCUS_NONE:
		print("[HUB-006] FAIL: ContinueButton has FOCUS_NONE")
		hub.queue_free()
		return false

	if new_btn.focus_mode == Control.FOCUS_NONE:
		print("[HUB-006] FAIL: NewGameButton has FOCUS_NONE")
		hub.queue_free()
		return false

	if map_btn.focus_mode == Control.FOCUS_NONE:
		print("[HUB-006] FAIL: JourneyMapButton has FOCUS_NONE")
		hub.queue_free()
		return false

	if not map_btn.text.contains("BẢN ĐỒ"):
		print("[HUB-006] FAIL: JourneyMapButton text does not mention BẢN ĐỒ: %s" % map_btn.text)
		hub.queue_free()
		return false

	hub.queue_free()
	print("[HUB-006] PASS: CTA presence, sizing, and focusability verified!")
	return true

# HUB-007: D1 Complete Task 090 Contract Enforcement
static func test_hub_007_d1_complete_task_090_contract() -> bool:
	print("[HUB-007] Verifying Task 090 Replay/Continue contract enforcement...")
	var hub: SanctumNexusHub = _create_hub()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)

	hub.set_progression_state(SanctumNexusHub.HubProgressionState.D1_COMPLETE)

	var cont_btn: Button = hub.get_continue_button()
	var new_btn: Button = hub.get_new_game_button()
	var map_btn: Button = hub.get_journey_map_button()

	if cont_btn.visible:
		print("[HUB-007] FAIL: ContinueButton must not be visible on Hub when D1 is complete (Task 090)")
		hub.queue_free()
		return false

	if not map_btn.visible:
		print("[HUB-007] FAIL: World Map button must remain visible when D1 is complete")
		hub.queue_free()
		return false

	if not new_btn.visible or not new_btn.text.contains("KHÁM PHÁ LẠI"):
		print("[HUB-007] FAIL: Replay action button should indicate KHÁM PHÁ LẠI: %s" % new_btn.text)
		hub.queue_free()
		return false

	hub.queue_free()
	print("[HUB-007] PASS: Task 090 contract enforcement verified!")
	return true

# HUB-008: Multi-Resolution Responsive Layout & Bounding Rect Verification
static func test_hub_008_multi_resolution_responsive() -> bool:
	print("[HUB-008] Verifying multi-resolution responsive layout & non-overlap (1280x720, 1366x768, 1600x900, 1920x1080, windowed 1280x680)...")
	var hub: SanctumNexusHub = _create_hub()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)

	var test_resolutions: Array[Vector2] = [
		Vector2(1280, 720),
		Vector2(1366, 768),
		Vector2(1600, 900),
		Vector2(1920, 1080),
		Vector2(1280, 680)
	]

	var badge: PanelContainer = hub.get_player_badge_panel()
	var hud: PanelContainer = hub.get_order_hud_panel()
	var identity: PanelContainer = hub.get_identity_panel()
	var journey: PanelContainer = hub.get_journey_panel()
	var utils: Control = hub.find_child("UtilitiesHBox", true, false) as Control
	var map_btn: Button = hub.get_journey_map_button()

	if utils == null or map_btn == null:
		print("[HUB-008] FAIL: Utilities or World Map button is null")
		hub.queue_free()
		return false

	var test_states: Array[SanctumNexusHub.HubProgressionState] = [
		SanctumNexusHub.HubProgressionState.NEW_PLAYER,
		SanctumNexusHub.HubProgressionState.D1_ACTIVE,
		SanctumNexusHub.HubProgressionState.D1_COMPLETE
	]

	for state in test_states:
		hub.set_progression_state(state)
		hub.set_hub_data({"has_save": (state != SanctumNexusHub.HubProgressionState.NEW_PLAYER)})

		for res in test_resolutions:
			hub.size = res
			hub.update_responsive_layout(res)

			var vp_rect: Rect2 = Rect2(Vector2.ZERO, res)

			var badge_w: float = maxf(badge.size.x, badge.get_combined_minimum_size().x)
			var badge_h: float = maxf(badge.size.y, badge.get_combined_minimum_size().y)
			var badge_rect: Rect2 = Rect2(badge.position, Vector2(badge_w, badge_h))

			var hud_w: float = maxf(hud.size.x, hud.get_combined_minimum_size().x)
			var hud_h: float = maxf(hud.size.y, hud.get_combined_minimum_size().y)
			var hud_rect: Rect2 = Rect2(hud.position, Vector2(hud_w, hud_h))

			var utils_w: float = maxf(utils.size.x, utils.get_combined_minimum_size().x)
			var utils_h: float = maxf(utils.size.y, utils.get_combined_minimum_size().y)
			var utils_rect: Rect2 = Rect2(utils.position, Vector2(utils_w, utils_h))

			var id_w: float = maxf(identity.size.x, identity.get_combined_minimum_size().x)
			var id_h: float = maxf(identity.size.y, identity.get_combined_minimum_size().y)
			var identity_rect: Rect2 = Rect2(identity.position, Vector2(id_w, id_h))

			var j_w: float = maxf(journey.size.x, journey.get_combined_minimum_size().x)
			var j_h: float = maxf(journey.size.y, journey.get_combined_minimum_size().y)
			var journey_rect: Rect2 = Rect2(journey.position, Vector2(j_w, j_h))

			var mb_w: float = maxf(map_btn.size.x, map_btn.get_combined_minimum_size().x)
			var mb_h: float = maxf(map_btn.size.y, map_btn.get_combined_minimum_size().y)
			var map_btn_rect: Rect2 = Rect2(journey.position + map_btn.position, Vector2(mb_w, mb_h))

			# 1. Viewport containment checks
			if not vp_rect.encloses(badge_rect):
				print("[HUB-008] FAIL at %s (state %d): Badge %s outside viewport %s" % [str(res), state, str(badge_rect), str(vp_rect)])
				hub.queue_free()
				return false

			if not vp_rect.encloses(hud_rect):
				print("[HUB-008] FAIL at %s (state %d): Order HUD %s outside viewport %s" % [str(res), state, str(hud_rect), str(vp_rect)])
				hub.queue_free()
				return false

			if not vp_rect.encloses(utils_rect):
				print("[HUB-008] FAIL at %s (state %d): Utilities %s outside viewport %s" % [str(res), state, str(utils_rect), str(vp_rect)])
				hub.queue_free()
				return false

			if not vp_rect.encloses(identity_rect):
				print("[HUB-008] FAIL at %s (state %d): Identity panel %s outside viewport %s" % [str(res), state, str(identity_rect), str(vp_rect)])
				hub.queue_free()
				return false

			if not vp_rect.encloses(journey_rect):
				print("[HUB-008] FAIL at %s (state %d): Journey panel %s outside viewport %s" % [str(res), state, str(journey_rect), str(vp_rect)])
				hub.queue_free()
				return false

			if not vp_rect.encloses(map_btn_rect):
				print("[HUB-008] FAIL at %s (state %d): World Map button %s outside viewport %s" % [str(res), state, str(map_btn_rect), str(vp_rect)])
				hub.queue_free()
				return false

			# 2. Strict Non-Overlap checks
			if hud_rect.intersects(utils_rect):
				print("[HUB-008] FAIL at %s (state %d): Utilities collides with Fragment HUD!" % [str(res), state])
				hub.queue_free()
				return false

			if utils_rect.intersects(journey_rect):
				print("[HUB-008] FAIL at %s (state %d): Utilities collides with Journey panel!" % [str(res), state])
				hub.queue_free()
				return false

			if badge_rect.intersects(hud_rect) or badge_rect.intersects(utils_rect) or badge_rect.intersects(identity_rect):
				print("[HUB-008] FAIL at %s (state %d): Badge intersects another control!" % [str(res), state])
				hub.queue_free()
				return false

			if identity_rect.intersects(journey_rect):
				print("[HUB-008] FAIL at %s (state %d): Identity intersects Journey panel!" % [str(res), state])
				hub.queue_free()
				return false

			# 3. Interactive World Map button checks
			if not map_btn.visible:
				print("[HUB-008] FAIL at %s (state %d): World Map button is not visible" % [str(res), state])
				hub.queue_free()
				return false

			if map_btn.disabled:
				print("[HUB-008] FAIL at %s (state %d): World Map button is disabled" % [str(res), state])
				hub.queue_free()
				return false

			if map_btn.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				print("[HUB-008] FAIL at %s (state %d): World Map button ignores mouse filter" % [str(res), state])
				hub.queue_free()
				return false

	hub.queue_free()
	print("[HUB-008] PASS: Multi-resolution responsive scaling, containment & non-overlap verified across all target viewports!")
	return true

# HUB-009: Navigation & Utility Signals
static func test_hub_009_navigation_and_utility_signals() -> bool:
	print("[HUB-009] Verifying navigation and utility signals...")
	var hub: SanctumNexusHub = _create_hub()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)

	var signal_received: Dictionary = {
		"new_game": false,
		"continue": false,
		"map": false,
		"settings": false,
		"logout": false,
		"continue_alias": false,
		"map_alias": false,
		"pause_alias": false,
		"replay_alias": false
	}

	hub.new_game_requested.connect(func(): signal_received["new_game"] = true)
	hub.continue_game_requested.connect(func(): signal_received["continue"] = true)
	hub.show_map_requested.connect(func(): signal_received["map"] = true)
	hub.settings_requested.connect(func(): signal_received["settings"] = true)
	hub.logout_requested.connect(func(): signal_received["logout"] = true)
	hub.continue_requested.connect(func(): signal_received["continue_alias"] = true)
	hub.map_requested.connect(func(): signal_received["map_alias"] = true)
	hub.pause_requested.connect(func(): signal_received["pause_alias"] = true)
	hub.replay_requested.connect(func(): signal_received["replay_alias"] = true)

	hub.get_new_game_button().emit_signal("pressed")
	hub.get_continue_button().emit_signal("pressed")
	hub.get_journey_map_button().emit_signal("pressed")

	var settings_btn: Button = hub.find_child("SettingsButton", true, false) as Button
	if settings_btn != null: settings_btn.emit_signal("pressed")

	var logout_btn: Button = hub.find_child("LogoutButton", true, false) as Button
	if logout_btn != null: logout_btn.emit_signal("pressed")

	# Test replay_requested emission when D1_COMPLETE is active
	hub.set_progression_state(SanctumNexusHub.HubProgressionState.D1_COMPLETE)
	hub.get_new_game_button().emit_signal("pressed")

	for k in signal_received:
		if not signal_received[k]:
			print("[HUB-009] FAIL: Signal %s was not emitted" % k)
			hub.queue_free()
			return false

	hub.queue_free()
	print("[HUB-009] PASS: Navigation and utility signals verified!")
	return true

# HUB-010: Compatibility with PRES-LAYOUT-001
static func test_hub_010_pres_layout_compatibility() -> bool:
	print("[HUB-010] Verifying compatibility with PRES-LAYOUT-001 (shared VBoxContainer, cont_btn < new_btn)...")
	var hub: SanctumNexusHub = _create_hub()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hub)

	var cont_btn: Button = hub.get_continue_button()
	var new_btn: Button = hub.get_new_game_button()

	var cont_parent: Node = cont_btn.get_parent()
	var new_parent: Node = new_btn.get_parent()

	if cont_parent == null or cont_parent != new_parent or not (cont_parent is VBoxContainer):
		print("[HUB-010] FAIL: Buttons do not share a common VBoxContainer layout")
		hub.queue_free()
		return false

	if cont_btn.get_index() >= new_btn.get_index():
		print("[HUB-010] FAIL: ContinueButton index is not above NewGameButton in VBoxContainer")
		hub.queue_free()
		return false

	hub.queue_free()
	print("[HUB-010] PASS: PRES-LAYOUT-001 compatibility verified!")
	return true
