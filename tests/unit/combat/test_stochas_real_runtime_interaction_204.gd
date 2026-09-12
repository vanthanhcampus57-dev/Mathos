class_name TestStochasRealRuntimeInteraction204
extends SceneTree

## TASK-204: Real Mounted Runtime Combat Verification Test Suite
## Verifies that on a real mounted tree under AppRoot:
## 1. Multi-stage play (Stage 1.4 -> Stage 1.5) connects combat controller properly
## 2. Card switching via Button.pressed signals works and updates QuestionPanel CTA button
## 3. Submitting correct answers applies card effect (Boss HP reduced from 100 to 90)
## 4. Submitting wrong answers triggers Boss retaliation (Player HP reduced)
## 5. Submitting correct DEFEND increases Player shield and updates Player HUD
## 6. Layout hierarchy (compact QuestionPanelHost, unboxed BossVisualContainer, enlarged cards)

func _initialize() -> void:
	var ok: bool = run_all_tests(self)
	quit(0 if ok else 1)

static func run_all_tests(tree: SceneTree = null) -> bool:
	print("--- RUNNING TASK-204 REAL MOUNTED RUNTIME COMBAT TESTS (RR-001..006) ---")
	var all_ok: bool = true

	all_ok = test_rr_001_multi_stage_combat_controller_wiring(tree) and all_ok
	all_ok = test_rr_002_card_switching_and_cta_updates(tree) and all_ok
	all_ok = test_rr_003_correct_answer_damages_boss(tree) and all_ok
	all_ok = test_rr_004_wrong_answer_boss_retaliates(tree) and all_ok
	all_ok = test_rr_005_correct_defend_adds_shield(tree) and all_ok
	all_ok = test_rr_006_layout_hierarchy_and_dimensions(tree) and all_ok

	if all_ok:
		print("[TASK-204-RUNTIME] 6 / 6 test scenarios passed!")
		print("TASK-204 REAL MOUNTED RUNTIME QA: PASS!")
	else:
		print("[TASK-204-RUNTIME] FAIL: One or more runtime combat tests failed")
	return all_ok

static func _fail(code: String, msg: String) -> bool:
	push_error("[%s] FAIL: %s" % [code, msg])
	print("[%s] FAIL: %s" % [code, msg])
	return false

static func _cleanup(node: Node) -> void:
	if node != null and is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.queue_free()

static func _setup_app_root_at_stage_1_5(tree: SceneTree) -> AppRoot:
	var root: AppRoot = AppRoot.new()
	root.bootstrap_runtime()
	if tree != null and tree.root != null:
		tree.root.add_child(root)

	var progress: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04"]:
		var r_id: String = String(cat.get_stage(s_id).get("reward_id", "reward_01_01"))
		progress.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, [] as Array[String]))

	# Play stage 1.4 first to simulate realistic session
	root.select_stage("stage_01_04")
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	shell.lesson_continue_requested.emit()

	# Now enter Stage 1.5
	root.select_stage("stage_01_05")
	shell.lesson_continue_requested.emit()

	return root

# ---------- RR-001: Multi-stage combat controller wiring ----------
static func test_rr_001_multi_stage_combat_controller_wiring(tree: SceneTree) -> bool:
	print("[RR-001] Verifying combat controller wiring after multi-stage play...")
	var root: AppRoot = _setup_app_root_at_stage_1_5(tree)
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	var boss_panel: BossCombatPanel = shell.get_existing_boss_combat_panel()

	if boss_panel == null:
		_cleanup(root)
		return _fail("RR-001", "BossCombatPanel is null")

	if not boss_panel.visible:
		_cleanup(root)
		return _fail("RR-001", "BossCombatPanel is not visible in question host mode")

	var ctrl: CardCombatController = boss_panel._combat_controller
	if ctrl == null:
		_cleanup(root)
		return _fail("RR-001", "BossCombatPanel._combat_controller is null after multi-stage transition")

	if not ctrl.is_in_combat:
		_cleanup(root)
		return _fail("RR-001", "CardCombatController.is_in_combat is false")

	_cleanup(root)
	print("[RR-001] PASS: Combat controller properly wired after multi-stage transition")
	return true

# ---------- RR-002: Card switching and CTA updates ----------
static func test_rr_002_card_switching_and_cta_updates(tree: SceneTree) -> bool:
	print("[RR-002] Verifying card switching via button clicks and QuestionPanel CTA updates...")
	var root: AppRoot = _setup_app_root_at_stage_1_5(tree)
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	var boss_panel: BossCombatPanel = shell.get_existing_boss_combat_panel()
	var q_panel: QuestionPanel = shell.get_question_panel()

	if boss_panel == null or q_panel == null:
		_cleanup(root)
		return _fail("RR-002", "BossCombatPanel or QuestionPanel is null")

	# Initial: STRIKE selected
	if not boss_panel.is_card_selected("card_strike"):
		_cleanup(root)
		return _fail("RR-002", "Initial card is not STRIKE")

	var cta_text: String = q_panel.get_combat_action_text()
	if not cta_text.contains("TẤN CÔNG"):
		_cleanup(root)
		return _fail("RR-002", "CTA text does not reflect initial STRIKE: '%s'" % cta_text)

	# Click DEFEND button
	var def_btn: Button = boss_panel.get_card_button("card_defend")
	if def_btn == null:
		_cleanup(root)
		return _fail("RR-002", "DEFEND button is null")
	def_btn.emit_signal("pressed")

	if not boss_panel.is_card_selected("card_defend"):
		_cleanup(root)
		return _fail("RR-002", "DEFEND is not selected after pressing button")

	cta_text = q_panel.get_combat_action_text()
	if not cta_text.contains("PHÒNG THỦ"):
		_cleanup(root)
		return _fail("RR-002", "CTA text did not update to PHÒNG THỦ: '%s'" % cta_text)

	# Click HEAL button
	var heal_btn: Button = boss_panel.get_card_button("card_heal")
	if heal_btn == null:
		_cleanup(root)
		return _fail("RR-002", "HEAL button is null")
	heal_btn.emit_signal("pressed")

	if not boss_panel.is_card_selected("card_heal"):
		_cleanup(root)
		return _fail("RR-002", "HEAL is not selected after pressing button")

	cta_text = q_panel.get_combat_action_text()
	if not cta_text.contains("HỒI PHỤC"):
		_cleanup(root)
		return _fail("RR-002", "CTA text did not update to HỒI PHỤC: '%s'" % cta_text)

	# Click STRIKE button back
	var strike_btn: Button = boss_panel.get_card_button("card_strike")
	strike_btn.emit_signal("pressed")
	if not boss_panel.is_card_selected("card_strike"):
		_cleanup(root)
		return _fail("RR-002", "STRIKE is not selected after pressing button back")

	_cleanup(root)
	print("[RR-002] PASS: Card switching via buttons properly updates controller selection and CTA")
	return true

# ---------- RR-003: Correct answer damages Boss ----------
static func test_rr_003_correct_answer_damages_boss(tree: SceneTree) -> bool:
	print("[RR-003] Verifying correct answer with STRIKE reduces Boss HP...")
	var root: AppRoot = _setup_app_root_at_stage_1_5(tree)
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	var boss_panel: BossCombatPanel = shell.get_existing_boss_combat_panel()

	var ctrl: CardCombatController = boss_panel._combat_controller
	var boss_entity: EnemyEntity = ctrl.boss_entity
	if boss_entity == null:
		_cleanup(root)
		return _fail("RR-003", "boss_entity is null")

	if boss_entity.current_hp != 100:
		_cleanup(root)
		return _fail("RR-003", "Initial boss HP is %d, expected 100" % boss_entity.current_hp)

	# Ensure STRIKE is selected via real UI button press
	boss_panel.get_card_button("card_strike").emit_signal("pressed")

	# Emit question completed with is_correct = true through QuestionPresentationController
	var q_ctrl: QuestionPresentationController = root.get_question_controller()
	q_ctrl.question_completed.emit({"is_correct": true, "question_id": "q_test"})

	if boss_entity.current_hp != 90:
		_cleanup(root)
		return _fail("RR-003", "Boss HP is %d after correct STRIKE, expected 90" % boss_entity.current_hp)

	if boss_panel._boss_hp_bar.value != 90:
		_cleanup(root)
		return _fail("RR-003", "Boss HP bar value is %f, expected 90" % boss_panel._boss_hp_bar.value)

	_cleanup(root)
	print("[RR-003] PASS: Correct STRIKE immediately reduces Boss HP to 90 and updates HUD")
	return true

# ---------- RR-004: Wrong answer triggers Boss retaliation ----------
static func test_rr_004_wrong_answer_boss_retaliates(tree: SceneTree) -> bool:
	print("[RR-004] Verifying wrong answer triggers Boss retaliation against player...")
	var root: AppRoot = _setup_app_root_at_stage_1_5(tree)
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	var boss_panel: BossCombatPanel = shell.get_existing_boss_combat_panel()

	var ctrl: CardCombatController = boss_panel._combat_controller
	var p_rt: PlayerRuntime = ctrl.player_runtime
	if p_rt == null:
		_cleanup(root)
		return _fail("RR-004", "player_runtime is null")

	if p_rt.current_hp != 100:
		_cleanup(root)
		return _fail("RR-004", "Initial player HP is %d, expected 100" % p_rt.current_hp)

	# Emit question completed with is_correct = false through QuestionPresentationController
	var q_ctrl: QuestionPresentationController = root.get_question_controller()
	q_ctrl.question_completed.emit({"is_correct": false, "question_id": "q_test"})

	if p_rt.current_hp >= 100:
		_cleanup(root)
		return _fail("RR-004", "Player HP is %d after wrong answer, expected < 100" % p_rt.current_hp)

	if boss_panel._player_hp_bar.value >= 100:
		_cleanup(root)
		return _fail("RR-004", "Player HP bar value is %f, expected < 100" % boss_panel._player_hp_bar.value)

	_cleanup(root)
	print("[RR-004] PASS: Wrong answer triggers Boss retaliation damaging player HP")
	return true

# ---------- RR-005: Correct DEFEND adds shield ----------
static func test_rr_005_correct_defend_adds_shield(tree: SceneTree) -> bool:
	print("[RR-005] Verifying correct answer with DEFEND increases player shield...")
	var root: AppRoot = _setup_app_root_at_stage_1_5(tree)
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	var boss_panel: BossCombatPanel = shell.get_existing_boss_combat_panel()

	var ctrl: CardCombatController = boss_panel._combat_controller
	var p_rt: PlayerRuntime = ctrl.player_runtime

	# Switch to DEFEND via real UI button press
	boss_panel.get_card_button("card_defend").emit_signal("pressed")

	# Emit question completed with is_correct = true
	var q_ctrl: QuestionPresentationController = root.get_question_controller()
	q_ctrl.question_completed.emit({"is_correct": true, "question_id": "q_test"})

	if p_rt.shield != 8:
		_cleanup(root)
		return _fail("RR-005", "Player shield is %d after DEFEND, expected 8" % p_rt.shield)

	if not boss_panel._player_shield_label.text.contains("8"):
		_cleanup(root)
		return _fail("RR-005", "Player shield label does not contain '8': '%s'" % boss_panel._player_shield_label.text)

	_cleanup(root)
	print("[RR-005] PASS: Correct DEFEND adds +8 Shield and updates Player HUD label")
	return true

# ---------- RR-006: Layout hierarchy and dimensions ----------
static func test_rr_006_layout_hierarchy_and_dimensions(tree: SceneTree) -> bool:
	print("[RR-006] Verifying layout hierarchy, glass QuestionPanel, and card dimensions...")
	var root: AppRoot = _setup_app_root_at_stage_1_5(tree)
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	var boss_panel: BossCombatPanel = shell.get_existing_boss_combat_panel()
	var q_panel: QuestionPanel = shell.get_question_panel()

	var q_host: MarginContainer = shell.get_question_host_container()
	var gameplay_hbox: Control = q_host.get_node_or_null("GameplayHBox") as Control
	var q_panel_host: Control = gameplay_hbox.get_node_or_null("QuestionPanelHost") as Control

	if q_panel_host == null:
		_cleanup(root)
		return _fail("RR-006", "QuestionPanelHost is null")

	# Check QuestionPanelHost size flags and minimum width (Task 216: 700-760px human layout)
	if q_panel_host.custom_minimum_size.x < 700.0 or q_panel_host.custom_minimum_size.x > 760.0:
		_cleanup(root)
		return _fail("RR-006", "QuestionPanelHost custom_minimum_size.x expected 700-760, got %f" % q_panel_host.custom_minimum_size.x)

	if q_panel_host.size_flags_horizontal != Control.SIZE_SHRINK_BEGIN:
		_cleanup(root)
		return _fail("RR-006", "QuestionPanelHost size_flags_horizontal expected SIZE_SHRINK_BEGIN")

	# Check enlarged card dimensions in BossCombatPanel (Task 216: 150-165x215-235)
	var card_btn: Button = boss_panel.get_card_button("card_strike")
	if card_btn == null:
		_cleanup(root)
		return _fail("RR-006", "STRIKE button is null")

	if card_btn.custom_minimum_size.x != BossCombatPanel.CARD_WIDTH or card_btn.custom_minimum_size.y != BossCombatPanel.CARD_HEIGHT:
		_cleanup(root)
		return _fail("RR-006", "Card button size expected %fx%f, got %s" % [BossCombatPanel.CARD_WIDTH, BossCombatPanel.CARD_HEIGHT, str(card_btn.custom_minimum_size)])

	if BossCombatPanel.CARD_WIDTH < 150.0 or BossCombatPanel.CARD_WIDTH > 165.0 or BossCombatPanel.CARD_HEIGHT < 215.0 or BossCombatPanel.CARD_HEIGHT > 235.0:
		_cleanup(root)
		return _fail("RR-006", "Card dimensions expected 150-165x215-235, got %fx%f" % [BossCombatPanel.CARD_WIDTH, BossCombatPanel.CARD_HEIGHT])

	# Check unboxed BossVisualContainer (460px Stitch parity)
	var visual_container: Control = boss_panel._boss_visual_rect
	if visual_container == null:
		_cleanup(root)
		return _fail("RR-006", "BossVisualContainer is null")

	if visual_container.custom_minimum_size.x != 460:
		_cleanup(root)
		return _fail("RR-006", "BossVisualContainer custom_minimum_size.x expected 460, got %f" % visual_container.custom_minimum_size.x)

	# Check QuestionPanel has combat glass styling
	if not q_panel.has_theme_stylebox_override("panel"):
		_cleanup(root)
		return _fail("RR-006", "QuestionPanel does not have stylebox override in combat")

	_cleanup(root)
	print("[RR-006] PASS: Layout hierarchy, compact glass QuestionPanel, and enlarged cards verified")
	return true

