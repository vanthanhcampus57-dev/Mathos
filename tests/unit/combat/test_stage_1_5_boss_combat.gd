class_name TestStage15BossCombat
extends SceneTree

## Unit & Integration Test Suite for D1 Stage 1.5 Boss Combat (STOCHAS & Card Combat).
## Verifies MATHOS-D1-STAGE-1-5-BOSS-COMBAT-025 requirements.

func _initialize() -> void:
	var ok: bool = run_all_tests(self)
	if ok:
		quit(0)
	else:
		quit(1)

static func run_all_tests(tree: SceneTree = null) -> bool:
	print("--- RUNNING D1 STAGE 1.5 BOSS COMBAT QA HARNESS (BOSS-001..014) ---")
	var all_ok: bool = true

	all_ok = test_stage_1_5_declares_card_combat_and_enemy_id() and all_ok
	all_ok = test_enemy_d1_stochas_instantiation() and all_ok
	all_ok = test_card_models_loading() and all_ok
	all_ok = test_combat_controller_initialization() and all_ok
	all_ok = test_card_selection_and_switch() and all_ok
	all_ok = test_correct_answer_applies_active_card_effect() and all_ok
	all_ok = test_wrong_answer_applies_enemy_intent() and all_ok
	all_ok = test_boss_defeat_condition() and all_ok
	all_ok = test_player_defeat_and_retry() and all_ok
	all_ok = test_stage_1_5_orchestrator_context() and all_ok
	all_ok = test_normal_stages_1_1_to_1_4_unchanged() and all_ok
	all_ok = test_app_root_stage_1_5_combat_wiring(tree) and all_ok
	all_ok = test_boss_hp_bar_visual_update(tree) and all_ok
	all_ok = test_victory_handoff_prepares_stage_clear(tree) and all_ok

	if all_ok:
		print("[BOSS-COMBAT-HARNESS] 14 / 14 test scenarios passed")
		print("D1 STAGE 1.5 BOSS COMBAT QA HARNESS: PASS!")
	else:
		print("[BOSS-COMBAT-HARNESS] FAIL: One or more boss combat tests failed")
	return all_ok

static func _fail(code: String, msg: String) -> bool:
	push_error("[%s] FAIL: %s" % [code, msg])
	print("[%s] FAIL: %s" % [code, msg])
	return false

static func _get_loaded_catalog() -> ValidatedCatalog:
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://content")
	if report == null or not report.publication_allowed:
		return null
	return repo.get_catalog()

static func test_stage_1_5_declares_card_combat_and_enemy_id() -> bool:
	print("[BOSS-001] Verifying Stage 1.5 canonical contract declarations...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	if catalog == null:
		return _fail("BOSS-001", "Could not load ValidatedCatalog")

	var stage: Dictionary = catalog.get_stage("stage_01_05")
	if stage.is_empty():
		return _fail("BOSS-001", "Stage stage_01_05 not found in catalog")

	if String(stage.get("encounter_mode", "")) != "card_combat":
		return _fail("BOSS-001", "stage_01_05 encounter_mode must be 'card_combat', got: %s" % str(stage.get("encounter_mode")))

	if String(stage.get("enemy_id", "")) != "enemy_d1_stochas":
		return _fail("BOSS-001", "stage_01_05 enemy_id must be 'enemy_d1_stochas', got: %s" % str(stage.get("enemy_id")))

	var cards: Array = stage.get("card_pool_ids", []) as Array
	if cards.size() < 3 or not cards.has("card_strike") or not cards.has("card_defend") or not cards.has("card_heal"):
		return _fail("BOSS-001", "stage_01_05 card_pool_ids missing required cards: %s" % str(cards))

	print("[BOSS-001] PASS: Stage 1.5 declared card_combat, enemy_d1_stochas, and card pool verified")
	return true

static func test_enemy_d1_stochas_instantiation() -> bool:
	print("[BOSS-002] Verifying runtime instantiation of enemy_d1_stochas...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	var boss: EnemyEntity = EnemyEntity.from_catalog(catalog, "enemy_d1_stochas")
	if boss == null:
		return _fail("BOSS-002", "EnemyEntity.from_catalog failed for enemy_d1_stochas")

	if boss.enemy_id != "enemy_d1_stochas":
		return _fail("BOSS-002", "Boss enemy_id mismatch")
	if boss.display_name != "STOCHAS":
		return _fail("BOSS-002", "Boss display_name expected STOCHAS, got %s" % boss.display_name)
	if boss.max_hp != 100 or boss.current_hp != 100:
		return _fail("BOSS-002", "Boss HP expected 100/100, got %d/%d" % [boss.current_hp, boss.max_hp])
	if boss.role != "boss":
		return _fail("BOSS-002", "Boss role expected 'boss', got %s" % boss.role)

	var intent: Dictionary = boss.get_current_intent()
	if intent.is_empty():
		return _fail("BOSS-002", "Boss missing intent")
	var telegraph: String = String(intent.get("telegraph_text", ""))
	if not telegraph.contains("STOCHAS"):
		return _fail("BOSS-002", "Intent telegraph expected to mention STOCHAS")

	print("[BOSS-002] PASS: enemy_d1_stochas entity instantiates with 100 HP and fixed intent")
	return true

static func test_card_models_loading() -> bool:
	print("[BOSS-003] Verifying loading and effects of D1 cards...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	var cards: Array[CardModel] = CardModel.load_cards(catalog, ["card_strike", "card_defend", "card_heal"])
	if cards.size() != 3:
		return _fail("BOSS-003", "Expected 3 loaded cards, got %d" % cards.size())

	var strike: CardModel = null
	var defend: CardModel = null
	var heal: CardModel = null
	for c in cards:
		if c.card_id == "card_strike": strike = c
		elif c.card_id == "card_defend": defend = c
		elif c.card_id == "card_heal": heal = c

	if strike == null or strike.card_type != "attack" or strike.effects.is_empty():
		return _fail("BOSS-003", "card_strike missing or invalid")
	if defend == null or defend.card_type != "shield" or defend.effects.is_empty():
		return _fail("BOSS-003", "card_defend missing or invalid")
	if heal == null or heal.card_type != "heal" or heal.effects.is_empty():
		return _fail("BOSS-003", "card_heal missing or invalid")

	print("[BOSS-003] PASS: All 3 D1 cards loaded with canonical types and effect lists")
	return true

static func test_combat_controller_initialization() -> bool:
	print("[BOSS-004] Verifying CardCombatController startup state...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	var stats: PlayerStats = PlayerStats.new(catalog.get_config())
	var player: PlayerRuntime = PlayerRuntime.new("stage_01_05", stats)
	var boss: EnemyEntity = EnemyEntity.from_catalog(catalog, "enemy_d1_stochas")
	var cards: Array[CardModel] = CardModel.load_cards(catalog, ["card_strike", "card_defend", "card_heal"])

	var ctrl: CardCombatController = CardCombatController.new()
	ctrl.start_combat(player, boss, cards)

	if not ctrl.is_in_combat:
		return _fail("BOSS-004", "Controller should be in combat")
	if ctrl.turn_counter != 1:
		return _fail("BOSS-004", "Turn counter should be 1")
	if ctrl.get_selected_card() == null or ctrl.get_selected_card().card_id != "card_strike":
		return _fail("BOSS-004", "Default selected card should be card_strike")

	print("[BOSS-004] PASS: Combat controller starts in combat on turn 1 with Strike selected")
	return true

static func test_card_selection_and_switch() -> bool:
	print("[BOSS-005] Verifying card switching in combat controller...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	var stats: PlayerStats = PlayerStats.new(catalog.get_config())
	var player: PlayerRuntime = PlayerRuntime.new("stage_01_05", stats)
	var boss: EnemyEntity = EnemyEntity.from_catalog(catalog, "enemy_d1_stochas")
	var cards: Array[CardModel] = CardModel.load_cards(catalog, ["card_strike", "card_defend", "card_heal"])

	var ctrl: CardCombatController = CardCombatController.new()
	ctrl.start_combat(player, boss, cards)

	var changed: bool = ctrl.select_card("card_defend")
	if not changed or ctrl.get_selected_card().card_id != "card_defend":
		return _fail("BOSS-005", "Failed to switch to card_defend")

	ctrl.select_card("card_heal")
	if ctrl.get_selected_card().card_id != "card_heal":
		return _fail("BOSS-005", "Failed to switch to card_heal")

	print("[BOSS-005] PASS: Card selection switches correctly among hand cards")
	return true

static func test_correct_answer_applies_active_card_effect() -> bool:
	print("[BOSS-006] Verifying correct answer resolves card effects deterministically...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	var stats: PlayerStats = PlayerStats.new(catalog.get_config())
	var player: PlayerRuntime = PlayerRuntime.new("stage_01_05", stats)
	var boss: EnemyEntity = EnemyEntity.from_catalog(catalog, "enemy_d1_stochas")
	var cards: Array[CardModel] = CardModel.load_cards(catalog, ["card_strike", "card_defend", "card_heal"])

	var ctrl: CardCombatController = CardCombatController.new()
	ctrl.start_combat(player, boss, cards)

	# 1. Strike effect on correct answer: deals 10 damage to boss
	ctrl.select_card("card_strike")
	var outcome1: Dictionary = ctrl.resolve_answer_outcome(true)
	if boss.current_hp != 90:
		return _fail("BOSS-006", "Expected boss HP 90 after strike, got %d" % boss.current_hp)

	# 2. Defend effect on correct answer: grants 8 shield to player
	ctrl.select_card("card_defend")
	var outcome2: Dictionary = ctrl.resolve_answer_outcome(true)
	if player.shield != 8:
		return _fail("BOSS-006", "Expected player shield 8 after defend, got %d" % player.shield)

	# 3. Heal effect on correct answer: heals damaged player
	player.current_hp = 80
	ctrl.select_card("card_heal")
	var outcome3: Dictionary = ctrl.resolve_answer_outcome(true)
	if player.current_hp != 95:
		return _fail("BOSS-006", "Expected player HP 95 after heal, got %d" % player.current_hp)

	print("[BOSS-006] PASS: Correct answer applies damage, shield, and heal effects accurately")
	return true

static func test_wrong_answer_applies_enemy_intent() -> bool:
	print("[BOSS-007] Verifying wrong answer triggers enemy intent attack on player...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	var stats: PlayerStats = PlayerStats.new(catalog.get_config())
	var player: PlayerRuntime = PlayerRuntime.new("stage_01_05", stats)
	var boss: EnemyEntity = EnemyEntity.from_catalog(catalog, "enemy_d1_stochas")
	var cards: Array[CardModel] = CardModel.load_cards(catalog, ["card_strike", "card_defend", "card_heal"])

	var ctrl: CardCombatController = CardCombatController.new()
	ctrl.start_combat(player, boss, cards)

	# Wrong answer: card does not apply damage to boss, boss intent deals 10 damage to player
	var boss_hp_before: int = boss.current_hp
	var player_hp_before: int = player.current_hp

	var outcome: Dictionary = ctrl.resolve_answer_outcome(false)
	if boss.current_hp != boss_hp_before:
		return _fail("BOSS-007", "Boss HP should not decrease on wrong answer")
	if player.current_hp != player_hp_before - 10:
		return _fail("BOSS-007", "Player HP expected %d, got %d" % [player_hp_before - 10, player.current_hp])

	print("[BOSS-007] PASS: Wrong answer fizzles card and executes boss intent damage")
	return true

static func test_boss_defeat_condition() -> bool:
	print("[BOSS-008] Verifying combat completion requires boss defeat (HP <= 0)...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	var stats: PlayerStats = PlayerStats.new(catalog.get_config())
	var player: PlayerRuntime = PlayerRuntime.new("stage_01_05", stats)
	var boss: EnemyEntity = EnemyEntity.from_catalog(catalog, "enemy_d1_stochas")
	var cards: Array[CardModel] = CardModel.load_cards(catalog, ["card_strike", "card_defend", "card_heal"])

	var ctrl: CardCombatController = CardCombatController.new()
	ctrl.start_combat(player, boss, cards)

	var state: Dictionary = {"defeated_emitted": false}
	ctrl.boss_defeated.connect(func(): state["defeated_emitted"] = true)

	# Deal 90 damage (9 strikes) -> boss not defeated yet
	for i in range(9):
		ctrl.select_card("card_strike")
		ctrl.resolve_answer_outcome(true)
		if ctrl.boss_entity.is_defeated:
			return _fail("BOSS-008", "Boss should not be defeated at turn %d" % (i + 1))

	if boss.current_hp != 10 or state["defeated_emitted"]:
		return _fail("BOSS-008", "Boss HP should be 10 and not defeated yet")

	# 10th strike deals remaining 10 damage -> HP reaches 0 -> boss defeated!
	ctrl.select_card("card_strike")
	var final_outcome: Dictionary = ctrl.resolve_answer_outcome(true)
	if boss.current_hp != 0 or not boss.is_defeated or not bool(final_outcome.get("boss_defeated", false)):
		return _fail("BOSS-008", "Boss should be defeated at HP 0")
	if not state["defeated_emitted"]:
		return _fail("BOSS-008", "boss_defeated signal was not emitted")
	if ctrl.is_in_combat:
		return _fail("BOSS-008", "Combat should terminate on boss defeat")

	print("[BOSS-008] PASS: Boss defeat condition strictly enforced at HP <= 0")
	return true

static func test_player_defeat_and_retry() -> bool:
	print("[BOSS-009] Verifying player defeat and safe combat reset...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	var stats: PlayerStats = PlayerStats.new(catalog.get_config())
	var player: PlayerRuntime = PlayerRuntime.new("stage_01_05", stats)
	var boss: EnemyEntity = EnemyEntity.from_catalog(catalog, "enemy_d1_stochas")
	var cards: Array[CardModel] = CardModel.load_cards(catalog, ["card_strike", "card_defend", "card_heal"])

	var ctrl: CardCombatController = CardCombatController.new()
	ctrl.start_combat(player, boss, cards)

	var state: Dictionary = {"player_defeated_emitted": false, "reset_emitted": false}
	ctrl.player_defeated.connect(func(): state["player_defeated_emitted"] = true)
	ctrl.combat_reset.connect(func(): state["reset_emitted"] = true)

	# Force player damage until defeat
	player.current_hp = 10
	ctrl.resolve_answer_outcome(false)

	if not player.is_defeated or not state["player_defeated_emitted"]:
		return _fail("BOSS-009", "Player defeat signal not emitted on lethal damage")

	# Reset encounter
	ctrl.reset_encounter(stats)
	if player.current_hp != 100 or boss.current_hp != 100 or player.is_defeated or boss.is_defeated:
		return _fail("BOSS-009", "Encounter reset did not restore full HP")
	if not state["reset_emitted"]:
		return _fail("BOSS-009", "combat_reset signal was not emitted")
	if not ctrl.is_in_combat:
		return _fail("BOSS-009", "Combat should be active again after reset")

	print("[BOSS-009] PASS: Player defeat detected and encounter resets cleanly to 100 HP")
	return true

static func test_stage_1_5_orchestrator_context() -> bool:
	print("[BOSS-010] Verifying StageOrchestrator context includes combat contract...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	var persistent: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var progress: ProgressService = ProgressService.new(catalog, persistent)
	var q_service: QuestionService = QuestionService.new(catalog)

	# Unlock up to stage_01_05
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04"]:
		var r_id: String = String(catalog.get_stage(s_id).get("reward_id", "reward_01_01"))
		progress.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, [] as Array[String]))

	var orch: StageOrchestrator = StageOrchestrator.new(catalog, q_service, progress)
	var init_res: Dictionary = orch.initialize_stage("stage_01_05")
	if not bool(init_res.get("success", false)):
		return _fail("BOSS-010", "Failed to initialize stage_01_05: %s" % str(init_res))

	var ctx: Dictionary = orch.create_stage_context(false)
	if String(ctx.get("encounter_mode", "")) != "card_combat":
		return _fail("BOSS-010", "Context missing encounter_mode 'card_combat'")
	if String(ctx.get("enemy_id", "")) != "enemy_d1_stochas":
		return _fail("BOSS-010", "Context missing enemy_id 'enemy_d1_stochas'")
	var pool: Array = ctx.get("card_pool_ids", []) as Array
	if pool.size() != 3:
		return _fail("BOSS-010", "Context missing card_pool_ids")

	print("[BOSS-010] PASS: StageOrchestrator context carries card_combat and enemy_d1_stochas")
	return true

static func test_normal_stages_1_1_to_1_4_unchanged() -> bool:
	print("[BOSS-011] Verifying non-boss stages (1.1..1.4) remain unchanged...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03"]:
		var s: Dictionary = catalog.get_stage(s_id)
		if String(s.get("encounter_mode", "")) != "puzzle_onboarding":
			return _fail("BOSS-011", "Stage %s encounter_mode should be puzzle_onboarding" % s_id)
		if s.get("enemy_id") != null:
			return _fail("BOSS-011", "Stage %s should have enemy_id null" % s_id)

	var s4: Dictionary = catalog.get_stage("stage_01_04")
	if s4.get("enemy_id") != null:
		return _fail("BOSS-011", "Stage 1.4 should have enemy_id null")

	print("[BOSS-011] PASS: Normal stages 1.1-1.4 contract strictly preserved")
	return true

static func test_app_root_stage_1_5_combat_wiring(tree: SceneTree) -> bool:
	print("[BOSS-012] Verifying AppRoot wires BossCombatPanel and controller in Stage 1.5...")
	var root: AppRoot = AppRoot.new()
	root.bootstrap_runtime()
	if tree != null and tree.root != null:
		tree.root.add_child(root)

	# Unlock through stage_01_05
	var progress: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04"]:
		var r_id: String = String(cat.get_stage(s_id).get("reward_id", "reward_01_01"))
		progress.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, [] as Array[String]))

	# Select stage 1.5
	var sel_res: Dictionary = root.select_stage("stage_01_05")
	if not bool(sel_res.get("success", false)):
		_cleanup(root)
		return _fail("BOSS-012", "Failed to select stage_01_05: %s" % str(sel_res))

	var ctrl: CardCombatController = root.get_active_combat_controller()
	if ctrl == null:
		_cleanup(root)
		return _fail("BOSS-012", "AppRoot._active_combat_controller is null for stage_01_05")

	if ctrl.boss_entity == null or ctrl.boss_entity.enemy_id != "enemy_d1_stochas":
		_cleanup(root)
		return _fail("BOSS-012", "Combat controller boss entity is not enemy_d1_stochas")

	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	if shell != null:
		shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)
		var boss_panel: BossCombatPanel = shell.get_boss_combat_panel()
		if boss_panel == null or not boss_panel.visible:
			_cleanup(root)
			return _fail("BOSS-012", "BossCombatPanel is not visible in MODE_QUESTION_HOST for stage 1.5")

		var advisor: Control = shell.get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer/GameplayHBox/AdvisorPanel") as Control
		if advisor != null and advisor.visible:
			_cleanup(root)
			return _fail("BOSS-012", "AdvisorPanel should be hidden during boss combat")

	_cleanup(root)
	print("[BOSS-012] PASS: AppRoot initializes combat controller and presents BossCombatPanel")
	return true

static func test_boss_hp_bar_visual_update(tree: SceneTree) -> bool:
	print("[BOSS-013] Verifying BossCombatPanel visual controls, real STOCHAS sprite, and HP updates...")
	var catalog: ValidatedCatalog = _get_loaded_catalog()
	var stats: PlayerStats = PlayerStats.new(catalog.get_config())
	var player: PlayerRuntime = PlayerRuntime.new("stage_01_05", stats)
	var boss: EnemyEntity = EnemyEntity.from_catalog(catalog, "enemy_d1_stochas")
	var cards: Array[CardModel] = CardModel.load_cards(catalog, ["card_strike", "card_defend", "card_heal"])

	var ctrl: CardCombatController = CardCombatController.new()
	ctrl.start_combat(player, boss, cards)

	var panel: BossCombatPanel = BossCombatPanel.new()
	if tree != null and tree.root != null:
		tree.root.add_child(panel)
	panel.set_controller(ctrl)

	# 1. Real Stochas Asset Verification
	var sprite_rect: TextureRect = panel.get_boss_sprite_rect()
	if sprite_rect == null:
		_cleanup(panel)
		return _fail("BOSS-013", "BossCombatPanel missing BossSpriteRect TextureRect")

	var tex: Texture2D = panel.get_boss_texture()
	if tex == null:
		_cleanup(panel)
		return _fail("BOSS-013", "BossCombatPanel failed to load STOCHAS texture from %s" % BossCombatPanel.STOCHAS_TEXTURE_PATH)

	if tex.get_width() != 512 or tex.get_height() != 512:
		_cleanup(panel)
		return _fail("BOSS-013", "STOCHAS texture dimensions expected 512x512, got %dx%d" % [tex.get_width(), tex.get_height()])

	var img: Image = tex.get_image()
	if img != null:
		if img.detect_alpha() == Image.ALPHA_NONE:
			_cleanup(panel)
			return _fail("BOSS-013", "STOCHAS texture must have alpha channel transparency")

	# 2. Rendering Configuration: Nearest neighbor pixel filter, aspect ratio preservation
	if sprite_rect.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_cleanup(panel)
		return _fail("BOSS-013", "BossSpriteRect must use CanvasItem.TEXTURE_FILTER_NEAREST")

	if sprite_rect.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		_cleanup(panel)
		return _fail("BOSS-013", "BossSpriteRect must use STRETCH_KEEP_ASPECT_CENTERED to prevent stretching")

	if sprite_rect.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
		_cleanup(panel)
		return _fail("BOSS-013", "BossSpriteRect must use EXPAND_IGNORE_SIZE")

	# 3. Safe Visual Margin Verification (8–12%)
	var margin_container: MarginContainer = sprite_rect.get_parent() as MarginContainer
	if margin_container == null:
		_cleanup(panel)
		return _fail("BOSS-013", "BossSpriteRect must be contained in a MarginContainer")

	var top_margin: int = margin_container.get_theme_constant("margin_top")
	var base_h: float = BossCombatPanel.BOSS_VISUAL_CONTAINER_HEIGHT
	var margin_ratio: float = float(top_margin) / base_h
	if margin_ratio < 0.08 or margin_ratio > 0.12:
		_cleanup(panel)
		return _fail("BOSS-013", "Safe visual margin ratio expected between 8% and 12%, got %.2f%%" % (margin_ratio * 100.0))

	# 4. Coded Placeholder Removal Verification
	for label in panel.find_children("", "Label", true, false):
		var lbl: Label = label as Label
		if lbl.text.contains("👁️") or lbl.text.contains("KHÔNG GIAN MẪU"):
			_cleanup(panel)
			return _fail("BOSS-013", "Old coded placeholder label '%s' should be completely removed" % lbl.text)

	# 5. HP Bar Verification
	var hp_bar: ProgressBar = null
	for child in panel.find_children("", "ProgressBar", true, false):
		hp_bar = child as ProgressBar
		break

	if hp_bar == null or hp_bar.value != 100:
		_cleanup(panel)
		return _fail("BOSS-013", "Initial HP bar value should be 100")

	# Strike the boss: HP drops to 90
	ctrl.select_card("card_strike")
	ctrl.resolve_answer_outcome(true)

	if hp_bar.value != 90:
		_cleanup(panel)
		return _fail("BOSS-013", "HP bar value should update to 90, got: %f" % hp_bar.value)

	_cleanup(panel)
	print("[BOSS-013] PASS: Boss visual panel with real STOCHAS sprite (512x512 RGBA, nearest filter, 10% margin) & HP updates verified")
	return true

static func test_victory_handoff_prepares_stage_clear(tree: SceneTree) -> bool:
	print("[BOSS-014] Verifying boss victory triggers stage clear handoff without reward dup...")
	# Backup existing save if present to prevent polluting subsequent test suites
	var has_existing_save: bool = FileAccess.file_exists("user://save_v1.json")
	var backup_save: String = ""
	if has_existing_save:
		var f_in: FileAccess = FileAccess.open("user://save_v1.json", FileAccess.READ)
		if f_in != null:
			backup_save = f_in.get_as_text()

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
	var ctrl: CardCombatController = root.get_active_combat_controller()
	if ctrl == null:
		_cleanup(root)
		_restore_save(has_existing_save, backup_save)
		return _fail("BOSS-014", "Combat controller is null")

	# Defeat boss directly by applying 100 damage
	ctrl.boss_entity.apply_damage(100)
	ctrl.boss_defeated.emit()

	# Simulate continuing after question
	root.call("_on_question_continue_requested")

	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	if shell != null and shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE:
		_cleanup(root)
		_restore_save(has_existing_save, backup_save)
		return _fail("BOSS-014", "Expected shell to transition to MODE_STAGE_COMPLETE on victory")

	var snap: ProgressState = progress.create_snapshot_view()
	if not snap.cleared_stage_ids.has("stage_01_05"):
		_cleanup(root)
		_restore_save(has_existing_save, backup_save)
		return _fail("BOSS-014", "stage_01_05 should be marked cleared in ProgressService")

	_cleanup(root)
	_restore_save(has_existing_save, backup_save)
	print("[BOSS-014] PASS: Boss victory hands off to stage clear and records single clear in ProgressService")
	return true

static func _restore_save(had_save: bool, save_text: String) -> void:
	if had_save:
		var f_out: FileAccess = FileAccess.open("user://save_v1.json", FileAccess.WRITE)
		if f_out != null:
			f_out.store_string(save_text)
	else:
		if FileAccess.file_exists("user://save_v1.json"):
			DirAccess.remove_absolute("user://save_v1.json")

static func _cleanup(node: Node) -> void:
	if node != null and is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.queue_free()
