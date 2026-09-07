class_name TestStageBossLifecycle080
extends SceneTree

## Dedicated QA Verification Suite for MATHOS-P0-STAGE-BOSS-LIFECYCLE-080.
## Verifies correct Boss UI lifecycle, stage/mode gating, and layout composition.

func _initialize() -> void:
	var ok: bool = run_all_tests(self)
	if ok:
		quit(0)
	else:
		quit(1)

static func run_all_tests(tree: SceneTree = null) -> bool:
	print("--- RUNNING STAGE BOSS LIFECYCLE 080 TEST SUITE ---")
	var all_ok: bool = true

	all_ok = test_stage_01_04_has_no_boss_panel(tree) and all_ok
	all_ok = test_stage_01_05_pre_combat_gating(tree) and all_ok
	all_ok = test_stage_01_05_canonical_boss_encounter_activation(tree) and all_ok
	all_ok = test_boss_panel_initializes_once_and_controller_guard() and all_ok
	all_ok = test_cards_hidden_outside_active_combat() and all_ok
	all_ok = test_question_cleared_on_mode_transition() and all_ok
	all_ok = test_restored_state_badge_has_no_player_facing_text() and all_ok
	all_ok = test_stage_1_4_to_1_5_to_1_4_transition_isolation(tree) and all_ok

	if all_ok:
		print("[BOSS-LIFECYCLE-080] 8 / 8 test scenarios passed")
		print("STAGE BOSS LIFECYCLE 080 QA HARNESS: PASS!")
	else:
		print("[BOSS-LIFECYCLE-080] FAIL: One or more stage boss lifecycle tests failed")
	return all_ok

static func _fail(code: String, msg: String) -> bool:
	push_error("[%s] FAIL: %s" % [code, msg])
	print("[%s] FAIL: %s" % [code, msg])
	return false

static func _cleanup(node: Node) -> void:
	if node != null:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		if node.is_inside_tree():
			node.queue_free()
		else:
			node.free()

static func test_stage_01_04_has_no_boss_panel(tree: SceneTree) -> bool:
	print("[LIFECYCLE-001] Verifying Stage 1.4 never displays BossCombatPanel and keeps AdvisorPanel...")
	var root: AppRoot = AppRoot.new()
	root.bootstrap_runtime()
	if tree != null and tree.root != null:
		tree.root.add_child(root)

	# Unlock up to stage_01_04
	var progress: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03"]:
		var r_id: String = String(cat.get_stage(s_id).get("reward_id", "reward_01_01"))
		progress.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, [] as Array[String]))

	var sel_res: Dictionary = root.select_stage("stage_01_04")
	if not bool(sel_res.get("success", false)):
		_cleanup(root)
		return _fail("LIFECYCLE-001", "Failed to select stage_01_04: %s" % str(sel_res))

	# Stage 1.4 must NOT have active combat controller
	if root.get_active_combat_controller() != null:
		_cleanup(root)
		return _fail("LIFECYCLE-001", "AppRoot._active_combat_controller must be null for stage_01_04")

	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	if shell == null:
		_cleanup(root)
		return _fail("LIFECYCLE-001", "StagePresentationShell is null")

	if shell.is_boss_stage():
		_cleanup(root)
		return _fail("LIFECYCLE-001", "shell.is_boss_stage() must return false for stage_01_04")

	# Enter MODE_QUESTION_HOST (practice questions)
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)

	var existing_boss: BossCombatPanel = shell.get_existing_boss_combat_panel()
	if existing_boss != null and existing_boss.visible:
		_cleanup(root)
		return _fail("LIFECYCLE-001", "BossCombatPanel must NOT be visible during Stage 1.4 Practice mode")

	var advisor: Control = shell.get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer/GameplayHBox/AdvisorPanel") as Control
	if advisor == null or not advisor.visible:
		_cleanup(root)
		return _fail("LIFECYCLE-001", "AdvisorPanel must be visible during Stage 1.4 Practice mode")

	_cleanup(root)
	print("[LIFECYCLE-001] PASS: Stage 1.4 does not show Boss panel and shows Advisor panel")
	return true

static func test_stage_01_05_pre_combat_gating(tree: SceneTree) -> bool:
	print("[LIFECYCLE-002] Verifying Stage 1.5 hides Boss UI during Story and Lesson modes...")
	var root: AppRoot = AppRoot.new()
	root.bootstrap_runtime()
	if tree != null and tree.root != null:
		tree.root.add_child(root)

	var progress: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04"]:
		var r_id: String = String(cat.get_stage(s_id).get("reward_id", "reward_01_01"))
		progress.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, [] as Array[String]))

	var sel_res: Dictionary = root.select_stage("stage_01_05")
	if not bool(sel_res.get("success", false)):
		_cleanup(root)
		return _fail("LIFECYCLE-002", "Failed to select stage_01_05: %s" % str(sel_res))

	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	if shell == null:
		_cleanup(root)
		return _fail("LIFECYCLE-002", "StagePresentationShell is null")

	if not shell.is_boss_stage():
		_cleanup(root)
		return _fail("LIFECYCLE-002", "shell.is_boss_stage() must return true for stage_01_05")

	# Mode Story: q_host and BossCombatPanel must not be visible
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_STORY)
	var q_host: Control = shell.get_question_host_container()
	if q_host != null and q_host.visible:
		_cleanup(root)
		return _fail("LIFECYCLE-002", "QuestionHostContainer must NOT be visible during MODE_STORY")

	var existing_boss: BossCombatPanel = shell.get_existing_boss_combat_panel()
	if existing_boss != null and existing_boss.visible:
		_cleanup(root)
		return _fail("LIFECYCLE-002", "BossCombatPanel must NOT be visible during MODE_STORY")

	# Mode Lesson: q_host and BossCombatPanel must not be visible
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_LESSON)
	if q_host != null and q_host.visible:
		_cleanup(root)
		return _fail("LIFECYCLE-002", "QuestionHostContainer must NOT be visible during MODE_LESSON")

	if existing_boss != null and existing_boss.visible:
		_cleanup(root)
		return _fail("LIFECYCLE-002", "BossCombatPanel must NOT be visible during MODE_LESSON")

	_cleanup(root)
	print("[LIFECYCLE-002] PASS: Boss UI gated exclusively until question encounter")
	return true

static func test_stage_01_05_canonical_boss_encounter_activation(tree: SceneTree) -> bool:
	print("[LIFECYCLE-003] Verifying canonical Boss encounter activation on 'Bắt đầu giải đố'...")
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

	# Advance from Lesson to Question phase (simulating 'Bắt đầu giải đố' pressed)
	shell.lesson_continue_requested.emit()

	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_QUESTION_HOST:
		_cleanup(root)
		return _fail("LIFECYCLE-003", "Expected MODE_QUESTION_HOST after lesson_continue_requested")

	var boss_panel: BossCombatPanel = shell.get_boss_combat_panel()
	if boss_panel == null or not boss_panel.visible:
		_cleanup(root)
		return _fail("LIFECYCLE-003", "BossCombatPanel must be visible upon Boss encounter")

	var advisor: Control = shell.get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer/GameplayHBox/AdvisorPanel") as Control
	if advisor != null and advisor.visible:
		_cleanup(root)
		return _fail("LIFECYCLE-003", "AdvisorPanel must be hidden during Boss encounter")

	_cleanup(root)
	print("[LIFECYCLE-003] PASS: Canonical Boss encounter activates correctly")
	return true

static func test_boss_panel_initializes_once_and_controller_guard() -> bool:
	print("[LIFECYCLE-004] Verifying BossCombatPanel set_controller idempotency...")
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

	if panel.get_controller() != ctrl:
		_cleanup(panel)
		return _fail("LIFECYCLE-004", "Controller not stored in panel")

	# Call set_controller again with same controller (must be idempotent no-op)
	panel.set_controller(ctrl)
	if panel.get_controller() != ctrl:
		_cleanup(panel)
		return _fail("LIFECYCLE-004", "Idempotent set_controller corrupted controller")

	# Disconnect with null
	panel.set_controller(null)
	if panel.get_controller() != null:
		_cleanup(panel)
		return _fail("LIFECYCLE-004", "Setting controller to null failed")

	_cleanup(panel)
	print("[LIFECYCLE-004] PASS: BossCombatPanel set_controller is idempotent and safe")
	return true

static func test_cards_hidden_outside_active_combat() -> bool:
	print("[LIFECYCLE-005] Verifying Boss cards hidden when not in active combat...")
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

	# When in combat, cards are visible
	if panel._cards_container != null and not panel._cards_container.visible:
		_cleanup(panel)
		return _fail("LIFECYCLE-005", "Cards should be visible in active combat")

	# When boss is defeated, cards should be hidden
	boss.apply_damage(100)
	boss.is_defeated = true
	ctrl.is_in_combat = false
	panel._on_boss_defeated()

	if panel._cards_container != null and panel._cards_container.visible:
		_cleanup(panel)
		return _fail("LIFECYCLE-005", "Cards should be hidden when Boss is defeated")

	_cleanup(panel)
	print("[LIFECYCLE-005] PASS: Boss cards visible only in active combat")
	return true

static func test_question_cleared_on_mode_transition() -> bool:
	print("[LIFECYCLE-006] Verifying QuestionPanel cleared upon exiting MODE_QUESTION_HOST...")
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell

	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)
	var q_panel: QuestionPanel = shell.get_question_panel()
	if q_panel == null:
		var host: Control = shell.get_question_host_container().get_node("GameplayHBox/QuestionPanelHost") as Control
		q_panel = QuestionPanel.new()
		q_panel.name = "QuestionPanel"
		host.add_child(q_panel)

	# Simulate setup question
	var q_data: Dictionary = {
		"question_id": "q_test_01",
		"interaction_type": "multiple_choice",
		"prompt": "Test Prompt?",
		"interaction_payload": {
			"options": [{"id": "opt_a", "content": "Option A"}],
			"correct_option_id": "opt_a"
		}
	}
	q_panel.setup_question(q_data)

	if q_panel.get_prompt_text().is_empty():
		_cleanup(shell)
		return _fail("LIFECYCLE-006", "Failed to setup test question")

	# Transition to MODE_STAGE_COMPLETE
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE)

	# Prompt text should now be cleared
	if not q_panel.get_prompt_text().is_empty():
		_cleanup(shell)
		return _fail("LIFECYCLE-006", "QuestionPanel prompt text was not cleared on mode transition")

	_cleanup(shell)
	print("[LIFECYCLE-006] PASS: QuestionPanel is cleanly cleared on mode transition")
	return true

static func test_restored_state_badge_has_no_player_facing_text() -> bool:
	print("[LIFECYCLE-007] Verifying [RESTORED STATE] marker is not visible to player...")
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell

	var restored_ctx: PresentationModels.StageContextInfo = PresentationModels.StageContextInfo.new(
		"stage_01_02", "Stage 1.2", "Dungeon 1", [], true
	)
	shell.set_stage_context(restored_ctx)
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_LESSON)

	var badge: Label = shell._get_restored_badge_label()
	if badge == null:
		_cleanup(shell)
		return _fail("LIFECYCLE-007", "RestoredBadgeLabel is null")

	# Existing contract: badge.visible is true for restored context
	if not badge.visible:
		_cleanup(shell)
		return _fail("LIFECYCLE-007", "RestoredBadgeLabel.visible should be true for test assertions")

	# Requirement 5: developer marker text must NOT be displayed to player
	if not badge.text.is_empty():
		_cleanup(shell)
		return _fail("LIFECYCLE-007", "RestoredBadgeLabel.text must be empty, got: '%s'" % badge.text)

	_cleanup(shell)
	print("[LIFECYCLE-007] PASS: RestoredBadgeLabel satisfies headless contracts with empty text")
	return true

static func test_stage_1_4_to_1_5_to_1_4_transition_isolation(tree: SceneTree) -> bool:
	print("[LIFECYCLE-008] Verifying Stage 1.4 -> 1.5 -> 1.4 leaves no lingering Boss UI...")
	var root: AppRoot = AppRoot.new()
	root.bootstrap_runtime()
	if tree != null and tree.root != null:
		tree.root.add_child(root)

	var progress: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03"]:
		var r_id: String = String(cat.get_stage(s_id).get("reward_id", "reward_01_01"))
		progress.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, [] as Array[String]))

	# 1. Select Stage 1.4
	root.select_stage("stage_01_04")
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)

	# Unlock Stage 1.5
	progress.commit_stage_clear("stage_01_04", RewardGrant.new("reward_01_04", "stage_01_04", 10, 10, [] as Array[String]))

	# 2. Select Stage 1.5
	root.select_stage("stage_01_05")
	shell.lesson_continue_requested.emit() # Enters Boss combat

	var boss_panel: BossCombatPanel = shell.get_existing_boss_combat_panel()
	if boss_panel == null or not boss_panel.visible:
		_cleanup(root)
		return _fail("LIFECYCLE-008", "BossCombatPanel should be visible in Stage 1.5 Boss encounter")

	# 3. Re-select Stage 1.4
	root.select_stage("stage_01_04")
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)

	if boss_panel.visible:
		_cleanup(root)
		return _fail("LIFECYCLE-008", "BossCombatPanel must NOT linger when re-entering Stage 1.4")

	if boss_panel.get_controller() != null:
		_cleanup(root)
		return _fail("LIFECYCLE-008", "BossCombatPanel controller should be disconnected in Stage 1.4")

	var advisor: Control = shell.get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer/GameplayHBox/AdvisorPanel") as Control
	if advisor == null or not advisor.visible:
		_cleanup(root)
		return _fail("LIFECYCLE-008", "AdvisorPanel must be visible in Stage 1.4 Practice mode")

	_cleanup(root)
	print("[LIFECYCLE-008] PASS: Clean stage switching with no lingering Boss state")
	return true
