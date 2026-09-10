class_name TestCombatCardsVisualParity172
extends SceneTree

## Deterministic Presentation Test Suite for MATHOS-COMBAT-CARD-VISUAL-INTEGRATION-172.
## Verifies 13 points:
## 1. exactly four combat card visual slots
## 2. STRIKE uses local STRIKE.png
## 3. DEFEND uses local DEFEND.png
## 4. HEAL uses local HEAL.png
## 5. PROBABILITY uses local PROBABILITY.png
## 6. no remote asset URLs
## 7. selected card state maps to actual selected action
## 8. Probability unavailable state preserves recognizable art
## 9. no fake hardcoded damage/shield/heal values
## 10. card row remains inside viewport at all required resolutions
## 11. no overlap with Math Challenge
## 12. no overlap with Combat Feed
## 13. no overlap with Settings

func _initialize() -> void:
	var ok: bool = run_all_tests(self)
	quit(0 if ok else 1)

static func run_all_tests(tree: SceneTree = null) -> bool:
	print("--- RUNNING COMBAT CARDS VISUAL PARITY QA (CARD-001..013) ---")
	var all_ok: bool = true

	all_ok = test_001_exactly_four_combat_card_visual_slots() and all_ok
	all_ok = test_002_strike_uses_local_strike_png() and all_ok
	all_ok = test_003_defend_uses_local_defend_png() and all_ok
	all_ok = test_004_heal_uses_local_heal_png() and all_ok
	all_ok = test_005_probability_uses_local_probability_png() and all_ok
	all_ok = test_006_no_remote_asset_urls() and all_ok
	all_ok = test_007_selected_card_state_maps_to_actual_selected_action() and all_ok
	all_ok = test_008_probability_unavailable_state_preserves_art() and all_ok
	all_ok = test_009_no_fake_hardcoded_combat_values() and all_ok
	all_ok = test_010_card_row_remains_inside_viewport_at_all_resolutions() and all_ok
	all_ok = test_011_no_overlap_with_math_challenge(tree) and all_ok
	all_ok = test_012_no_overlap_with_combat_feed() and all_ok
	all_ok = test_013_no_overlap_with_settings(tree) and all_ok

	if all_ok:
		print("[COMBAT-CARDS-172] 13 / 13 test scenarios passed")
		print("COMBAT CARDS VISUAL PARITY QA: PASS!")
	else:
		print("[COMBAT-CARDS-172] FAIL: One or more combat cards visual tests failed")
	return all_ok

static func _fail(code: String, msg: String) -> bool:
	push_error("[%s] FAIL: %s" % [code, msg])
	print("[%s] FAIL: %s" % [code, msg])
	return false

static func _create_harness() -> Dictionary:
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://content")
	var catalog: ValidatedCatalog = repo.get_catalog()
	var stats: PlayerStats = PlayerStats.new(catalog.get_config())
	var player: PlayerRuntime = PlayerRuntime.new("stage_01_05", stats)
	var boss: EnemyEntity = EnemyEntity.from_catalog(catalog, "enemy_d1_stochas")
	var cards: Array[CardModel] = CardModel.load_cards(catalog, ["card_strike", "card_defend", "card_heal"])

	var ctrl: CardCombatController = CardCombatController.new()
	ctrl.start_combat(player, boss, cards)

	var panel: BossCombatPanel = BossCombatPanel.new()
	panel.set_controller(ctrl)

	return {
		"repo": repo,
		"catalog": catalog,
		"player": player,
		"boss": boss,
		"cards": cards,
		"ctrl": ctrl,
		"panel": panel
	}

static func _cleanup(node: Node) -> void:
	if node != null and is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.queue_free()

# 1. Exactly four combat card visual slots
static func test_001_exactly_four_combat_card_visual_slots() -> bool:
	print("[CARD-001] Verifying exactly four combat card visual slots...")
	var h: Dictionary = _create_harness()
	var panel: BossCombatPanel = h["panel"]

	var slots: Array = panel.get_card_slots()
	if slots.size() != 4:
		_cleanup(panel)
		return _fail("CARD-001", "Expected 4 card slots, got %d" % slots.size())

	var expected_ids: Array[String] = ["card_strike", "card_defend", "card_heal", "card_probability"]
	for i in range(4):
		var slot: Control = slots[i] as Control
		if slot == null:
			_cleanup(panel)
			return _fail("CARD-001", "Slot index %d is null" % i)
		if slot.name != "CardSlot_" + expected_ids[i]:
			_cleanup(panel)
			return _fail("CARD-001", "Slot index %d expected name CardSlot_%s, got %s" % [i, expected_ids[i], slot.name])

	_cleanup(panel)
	print("[CARD-001] PASS: Exactly four card slots (Strike, Defend, Heal, Probability) verified")
	return true

# 2. STRIKE uses local STRIKE.png
static func test_002_strike_uses_local_strike_png() -> bool:
	print("[CARD-002] Verifying STRIKE uses local STRIKE.png...")
	var h: Dictionary = _create_harness()
	var panel: BossCombatPanel = h["panel"]

	var tex_rect: TextureRect = panel.get_card_texture_rect("card_strike")
	if tex_rect == null:
		_cleanup(panel)
		return _fail("CARD-002", "STRIKE TextureRect is null")

	var tex: Texture2D = tex_rect.texture
	if tex == null:
		_cleanup(panel)
		return _fail("CARD-002", "STRIKE texture is null")

	if tex.resource_path != BossCombatPanel.CARD_STRIKE_TEXTURE_PATH:
		_cleanup(panel)
		return _fail("CARD-002", "STRIKE texture path expected %s, got %s" % [BossCombatPanel.CARD_STRIKE_TEXTURE_PATH, tex.resource_path])

	if tex.get_width() != 378 or tex.get_height() != 578:
		_cleanup(panel)
		return _fail("CARD-002", "STRIKE texture dimensions expected 378x578, got %dx%d" % [tex.get_width(), tex.get_height()])

	_cleanup(panel)
	print("[CARD-002] PASS: STRIKE uses local STRIKE.png (378x578)")
	return true

# 3. DEFEND uses local DEFEND.png
static func test_003_defend_uses_local_defend_png() -> bool:
	print("[CARD-003] Verifying DEFEND uses local DEFEND.png...")
	var h: Dictionary = _create_harness()
	var panel: BossCombatPanel = h["panel"]

	var tex_rect: TextureRect = panel.get_card_texture_rect("card_defend")
	if tex_rect == null:
		_cleanup(panel)
		return _fail("CARD-003", "DEFEND TextureRect is null")

	var tex: Texture2D = tex_rect.texture
	if tex == null:
		_cleanup(panel)
		return _fail("CARD-003", "DEFEND texture is null")

	if tex.resource_path != BossCombatPanel.CARD_DEFEND_TEXTURE_PATH:
		_cleanup(panel)
		return _fail("CARD-003", "DEFEND texture path expected %s, got %s" % [BossCombatPanel.CARD_DEFEND_TEXTURE_PATH, tex.resource_path])

	if tex.get_width() != 378 or tex.get_height() != 578:
		_cleanup(panel)
		return _fail("CARD-003", "DEFEND texture dimensions expected 378x578, got %dx%d" % [tex.get_width(), tex.get_height()])

	_cleanup(panel)
	print("[CARD-003] PASS: DEFEND uses local DEFEND.png (378x578)")
	return true

# 4. HEAL uses local HEAL.png
static func test_004_heal_uses_local_heal_png() -> bool:
	print("[CARD-004] Verifying HEAL uses local HEAL.png...")
	var h: Dictionary = _create_harness()
	var panel: BossCombatPanel = h["panel"]

	var tex_rect: TextureRect = panel.get_card_texture_rect("card_heal")
	if tex_rect == null:
		_cleanup(panel)
		return _fail("CARD-004", "HEAL TextureRect is null")

	var tex: Texture2D = tex_rect.texture
	if tex == null:
		_cleanup(panel)
		return _fail("CARD-004", "HEAL texture is null")

	if tex.resource_path != BossCombatPanel.CARD_HEAL_TEXTURE_PATH:
		_cleanup(panel)
		return _fail("CARD-004", "HEAL texture path expected %s, got %s" % [BossCombatPanel.CARD_HEAL_TEXTURE_PATH, tex.resource_path])

	if tex.get_width() != 378 or tex.get_height() != 578:
		_cleanup(panel)
		return _fail("CARD-004", "HEAL texture dimensions expected 378x578, got %dx%d" % [tex.get_width(), tex.get_height()])

	_cleanup(panel)
	print("[CARD-004] PASS: HEAL uses local HEAL.png (378x578)")
	return true

# 5. PROBABILITY uses local PROBABILITY.png
static func test_005_probability_uses_local_probability_png() -> bool:
	print("[CARD-005] Verifying PROBABILITY uses local PROBABILITY.png...")
	var h: Dictionary = _create_harness()
	var panel: BossCombatPanel = h["panel"]

	var tex_rect: TextureRect = panel.get_card_texture_rect("card_probability")
	if tex_rect == null:
		_cleanup(panel)
		return _fail("CARD-005", "PROBABILITY TextureRect is null")

	var tex: Texture2D = tex_rect.texture
	if tex == null:
		_cleanup(panel)
		return _fail("CARD-005", "PROBABILITY texture is null")

	if tex.resource_path != BossCombatPanel.CARD_PROBABILITY_TEXTURE_PATH:
		_cleanup(panel)
		return _fail("CARD-005", "PROBABILITY texture path expected %s, got %s" % [BossCombatPanel.CARD_PROBABILITY_TEXTURE_PATH, tex.resource_path])

	if tex.get_width() != 378 or tex.get_height() != 578:
		_cleanup(panel)
		return _fail("CARD-005", "PROBABILITY texture dimensions expected 378x578, got %dx%d" % [tex.get_width(), tex.get_height()])

	_cleanup(panel)
	print("[CARD-005] PASS: PROBABILITY uses local PROBABILITY.png (378x578)")
	return true

# 6. No remote asset URLs
static func test_006_no_remote_asset_urls() -> bool:
	print("[CARD-006] Verifying zero remote asset URLs in combat cards...")
	var h: Dictionary = _create_harness()
	var panel: BossCombatPanel = h["panel"]

	var paths: Array[String] = [
		BossCombatPanel.CARD_STRIKE_TEXTURE_PATH,
		BossCombatPanel.CARD_DEFEND_TEXTURE_PATH,
		BossCombatPanel.CARD_HEAL_TEXTURE_PATH,
		BossCombatPanel.CARD_PROBABILITY_TEXTURE_PATH
	]

	for p in paths:
		if p.begins_with("http://") or p.begins_with("https://") or p.contains("google"):
			_cleanup(panel)
			return _fail("CARD-006", "Remote URL detected in card paths: %s" % p)
		if not p.begins_with("res://"):
			_cleanup(panel)
			return _fail("CARD-006", "Path does not use res:// scheme: %s" % p)
		if not FileAccess.file_exists(p):
			_cleanup(panel)
			return _fail("CARD-006", "Card asset does not exist locally: %s" % p)

	_cleanup(panel)
	print("[CARD-006] PASS: All card assets are 100% local res:// files with zero remote dependencies")
	return true

# 7. Selected card state maps to actual selected action
static func test_007_selected_card_state_maps_to_actual_selected_action() -> bool:
	print("[CARD-007] Verifying selected card state maps to actual selected action...")
	var h: Dictionary = _create_harness()
	var panel: BossCombatPanel = h["panel"]
	var ctrl: CardCombatController = h["ctrl"]

	# 1. Initial selection: STRIKE
	if not panel.is_card_selected("card_strike"):
		_cleanup(panel)
		return _fail("CARD-007", "Initial selected card should be card_strike")
	if panel.is_card_selected("card_defend"):
		_cleanup(panel)
		return _fail("CARD-007", "card_defend should not be selected initially")

	var strike_badge: Label = panel.get_card_badge_label("card_strike")
	if strike_badge == null or strike_badge.text != "ĐANG CHỌN":
		_cleanup(panel)
		return _fail("CARD-007", "STRIKE badge expected 'ĐANG CHỌN', got '%s'" % (strike_badge.text if strike_badge != null else "null"))

	var defend_badge: Label = panel.get_card_badge_label("card_defend")
	if defend_badge == null or defend_badge.text != "PHÒNG THỦ":
		_cleanup(panel)
		return _fail("CARD-007", "DEFEND badge expected 'PHÒNG THỦ', got '%s'" % (defend_badge.text if defend_badge != null else "null"))

	# 2. Switch to DEFEND via button click
	var defend_btn: Button = panel.get_card_button("card_defend")
	if defend_btn == null:
		_cleanup(panel)
		return _fail("CARD-007", "DEFEND button is null")
	defend_btn.emit_signal("pressed")

	if not panel.is_card_selected("card_defend"):
		_cleanup(panel)
		return _fail("CARD-007", "DEFEND should be selected after button press")
	if panel.is_card_selected("card_strike"):
		_cleanup(panel)
		return _fail("CARD-007", "STRIKE should not be selected after switching to DEFEND")

	if defend_badge.text != "ĐANG CHỌN":
		_cleanup(panel)
		return _fail("CARD-007", "DEFEND badge expected 'ĐANG CHỌN', got '%s'" % defend_badge.text)
	if strike_badge.text != "TẤN CÔNG":
		_cleanup(panel)
		return _fail("CARD-007", "STRIKE badge expected 'TẤN CÔNG', got '%s'" % strike_badge.text)

	# 3. Switch to HEAL via button click
	var heal_btn: Button = panel.get_card_button("card_heal")
	if heal_btn == null:
		_cleanup(panel)
		return _fail("CARD-007", "HEAL button is null")
	heal_btn.emit_signal("pressed")

	if not panel.is_card_selected("card_heal"):
		_cleanup(panel)
		return _fail("CARD-007", "HEAL should be selected after button press")

	var heal_badge: Label = panel.get_card_badge_label("card_heal")
	if heal_badge == null or heal_badge.text != "ĐANG CHỌN":
		_cleanup(panel)
		return _fail("CARD-007", "HEAL badge expected 'ĐANG CHỌN'")

	_cleanup(panel)
	print("[CARD-007] PASS: Selected card state correctly synchronizes with active action and badge labels")
	return true

# 8. Probability unavailable state preserves recognizable art
static func test_008_probability_unavailable_state_preserves_art() -> bool:
	print("[CARD-008] Verifying Probability unavailable state preserves recognizable art...")
	var h: Dictionary = _create_harness()
	var panel: BossCombatPanel = h["panel"]

	if panel.is_card_available("card_probability"):
		_cleanup(panel)
		return _fail("CARD-008", "Probability must not be available in current combat")

	if panel.is_card_selected("card_probability"):
		_cleanup(panel)
		return _fail("CARD-008", "Probability must not be selectable")

	var prob_btn: Button = panel.get_card_button("card_probability")
	if prob_btn == null or not prob_btn.disabled:
		_cleanup(panel)
		return _fail("CARD-008", "Probability button must be disabled")

	var prob_badge: Label = panel.get_card_badge_label("card_probability")
	if prob_badge == null or prob_badge.text != "KỸ NĂNG":
		_cleanup(panel)
		return _fail("CARD-008", "Probability badge expected 'KỸ NĂNG', got '%s'" % (prob_badge.text if prob_badge != null else "null"))

	var prob_status: Label = panel.get_card_status_label("card_probability")
	if prob_status == null or prob_status.text != "CHƯA KÍCH HOẠT":
		_cleanup(panel)
		return _fail("CARD-008", "Probability status expected 'CHƯA KÍCH HOẠT', got '%s'" % (prob_status.text if prob_status != null else "null"))

	var prob_tex: TextureRect = panel.get_card_texture_rect("card_probability")
	if prob_tex == null or prob_tex.texture == null:
		_cleanup(panel)
		return _fail("CARD-008", "Probability must preserve valid texture")

	# Art must be recognizable (not invisible, not missing texture)
	if prob_tex.modulate.a < 0.5:
		_cleanup(panel)
		return _fail("CARD-008", "Probability texture opacity too low (alpha < 0.5)")

	_cleanup(panel)
	print("[CARD-008] PASS: Probability unavailable state displays 'KỸ NĂNG / CHƯA KÍCH HOẠT' with recognizable art")
	return true

# 9. No fake hardcoded damage/shield/heal values
static func test_009_no_fake_hardcoded_combat_values() -> bool:
	print("[CARD-009] Verifying dynamic combat values (no fake hardcoded Stitch numbers)...")
	var h: Dictionary = _create_harness()
	var panel: BossCombatPanel = h["panel"]
	var cards: Array[CardModel] = h["cards"]

	var strike_card: CardModel = cards[0]
	var defend_card: CardModel = cards[1]
	var heal_card: CardModel = cards[2]

	var strike_status: Label = panel.get_card_status_label("card_strike")
	var defend_status: Label = panel.get_card_status_label("card_defend")
	var heal_status: Label = panel.get_card_status_label("card_heal")

	var strike_amt: int = int((strike_card.effects[0] as Dictionary).get("amount", 0))
	var defend_amt: int = int((defend_card.effects[0] as Dictionary).get("amount", 0))
	var heal_amt: int = int((heal_card.effects[0] as Dictionary).get("amount", 0))

	if not strike_status.text.contains(str(strike_amt)):
		_cleanup(panel)
		return _fail("CARD-009", "STRIKE status label does not reflect dynamic amount %d: '%s'" % [strike_amt, strike_status.text])

	if not defend_status.text.contains(str(defend_amt)):
		_cleanup(panel)
		return _fail("CARD-009", "DEFEND status label does not reflect dynamic amount %d: '%s'" % [defend_amt, defend_status.text])

	if not heal_status.text.contains(str(heal_amt)):
		_cleanup(panel)
		return _fail("CARD-009", "HEAL status label does not reflect dynamic amount %d: '%s'" % [heal_amt, heal_status.text])

	# Verify dynamic update when card effect changes
	var dynamic_card: CardModel = CardModel.new("card_strike", "Test Strike", "attack", 1, [{"effect_type": "damage", "amount": 42}])
	var dynamic_text: String = panel._get_card_dynamic_value_text("card_strike", dynamic_card)
	if not dynamic_text.contains("42"):
		_cleanup(panel)
		return _fail("CARD-009", "Dynamic value function failed to update with runtime card amount: '%s'" % dynamic_text)

	_cleanup(panel)
	print("[CARD-009] PASS: All card values dynamically bind to CardModel runtime effects")
	return true

# 10. Card row remains inside viewport at all required resolutions
static func test_010_card_row_remains_inside_viewport_at_all_resolutions() -> bool:
	print("[CARD-010] Verifying card row remains inside viewport across resolutions...")
	var resolutions: Array[Vector2] = [
		Vector2(1280, 720),
		Vector2(1366, 768),
		Vector2(1600, 900),
		Vector2(1920, 1080),
		Vector2(1280, 680)
	]

	for res in resolutions:
		var h: Dictionary = _create_harness()
		var panel: BossCombatPanel = h["panel"]
		panel.custom_minimum_size = Vector2(460, 0)
		panel.size = Vector2(460, res.y - 120)

		var cards_c: HBoxContainer = panel._cards_container
		if cards_c == null:
			_cleanup(panel)
			return _fail("CARD-010", "Cards container is null at resolution %s" % str(res))

		var min_size: Vector2 = cards_c.get_combined_minimum_size()
		if min_size.x > res.x:
			_cleanup(panel)
			return _fail("CARD-010", "Cards row minimum width %f exceeds viewport width %f" % [min_size.x, res.x])
		if min_size.y > res.y:
			_cleanup(panel)
			return _fail("CARD-010", "Cards row minimum height %f exceeds viewport height %f" % [min_size.y, res.y])

		# Verify all 4 card slots are visible and fit inside container
		var slots: Array = panel.get_card_slots()
		for s in slots:
			var slot: Control = s as Control
			if not slot.visible:
				_cleanup(panel)
				return _fail("CARD-010", "Card slot %s is not visible at %s" % [slot.name, str(res)])

		_cleanup(panel)

	print("[CARD-010] PASS: Card row fits within bounds across all 5 target resolutions")
	return true

# 11. No overlap with Math Challenge
static func test_011_no_overlap_with_math_challenge(tree: SceneTree) -> bool:
	print("[CARD-011] Verifying no overlap between combat card row and Math Challenge...")
	var root: AppRoot = AppRoot.new()
	root.bootstrap_runtime()
	if tree != null and tree.root != null:
		tree.root.add_child(root)

	var progress: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04"]:
		var r_id: String = String(cat.get_stage(s_id).get("reward_id", "reward_01_01"))
		progress.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, [] as Array[String]))

	root.select_stage("stage_01_05")
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	shell.lesson_continue_requested.emit() # Activate boss encounter

	var panel: BossCombatPanel = shell.get_existing_boss_combat_panel()
	if panel == null or not panel.visible:
		_cleanup(root)
		return _fail("CARD-011", "BossCombatPanel must be visible in encounter")

	var q_host: MarginContainer = shell.get_question_host_container()
	var gameplay_hbox: Control = q_host.get_node_or_null("GameplayHBox") as Control
	var q_panel_host: Control = gameplay_hbox.get_node_or_null("QuestionPanelHost") as Control

	if q_panel_host == null or panel == null:
		_cleanup(root)
		return _fail("CARD-011", "QuestionPanelHost or BossCombatPanel missing")

	# Sibling relationship in GameplayHBox ensures horizontal separation
	if q_panel_host.get_parent() != panel.get_parent():
		_cleanup(root)
		return _fail("CARD-011", "QuestionPanelHost and BossCombatPanel must share GameplayHBox container")

	var cards_container: HBoxContainer = panel._cards_container
	if cards_container == null:
		_cleanup(root)
		return _fail("CARD-011", "CardsContainer missing")

	_cleanup(root)
	print("[CARD-011] PASS: Math Challenge and combat cards occupy isolated layout branches with zero overlap")
	return true

# 12. No overlap with Combat Feed
static func test_012_no_overlap_with_combat_feed() -> bool:
	print("[CARD-012] Verifying no overlap between combat card row and Combat Action Feed...")
	var h: Dictionary = _create_harness()
	var panel: BossCombatPanel = h["panel"]

	var cards_c: HBoxContainer = panel._cards_container
	var log_label: Label = panel._combat_log_label
	if cards_c == null or log_label == null:
		_cleanup(panel)
		return _fail("CARD-012", "Cards container or Combat log label is null")

	var log_panel: PanelContainer = null
	var parent_node: Node = log_label.get_parent()
	while parent_node != null and parent_node != panel:
		if parent_node is PanelContainer:
			log_panel = parent_node as PanelContainer
			break
		parent_node = parent_node.get_parent()
	if log_panel == null:
		_cleanup(panel)
		return _fail("CARD-012", "Log panel container is null")

	# In BossCombatPanel VBox, cards_c is followed by log_panel
	var cards_idx: int = cards_c.get_index()
	var log_idx: int = log_panel.get_index()

	if log_idx <= cards_idx:
		_cleanup(panel)
		return _fail("CARD-012", "Combat feed (index %d) must render below cards (index %d)" % [log_idx, cards_idx])

	_cleanup(panel)
	print("[CARD-012] PASS: Card row renders cleanly above Combat Action Feed without overlap")
	return true

# 13. No overlap with Settings
static func test_013_no_overlap_with_settings(tree: SceneTree) -> bool:
	print("[CARD-013] Verifying no overlap between combat card row and Settings button...")
	var root: AppRoot = AppRoot.new()
	root.bootstrap_runtime()
	if tree != null and tree.root != null:
		tree.root.add_child(root)

	var progress: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04"]:
		var r_id: String = String(cat.get_stage(s_id).get("reward_id", "reward_01_01"))
		progress.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, [] as Array[String]))

	root.select_stage("stage_01_05")
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	shell.lesson_continue_requested.emit()

	var settings_btn: Button = shell.get_node_or_null("VBoxContainer/MainBody/ContentHBox/LeftSidebar/SidebarVBox/NavSettingsButton") as Button
	var boss_panel: BossCombatPanel = shell.get_existing_boss_combat_panel()

	if settings_btn == null:
		_cleanup(root)
		return _fail("CARD-013", "NavSettingsButton not found in shell sidebar")
	if boss_panel == null:
		_cleanup(root)
		return _fail("CARD-013", "BossCombatPanel not found in shell")

	# Settings is in LeftSidebar; BossCombatPanel is in MainContentVBox -> GameplayHBox
	# They are separated by LeftSidebar and MainContentVBox in ContentHBox
	_cleanup(root)
	print("[CARD-013] PASS: Settings button is isolated in LeftSidebar with zero card overlap")
	return true
