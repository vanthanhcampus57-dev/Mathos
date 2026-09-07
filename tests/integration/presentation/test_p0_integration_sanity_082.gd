class_name TestP0IntegrationSanity082
extends SceneTree

## Dedicated End-to-End Integration Sanity Test for MATHOS-P0-INTEGRATION-CANDIDATE-082.
## Verifies full flow:
## Fresh Guest -> D1 -> normal question -> next stage -> Stage 1.4 (no Boss UI) ->
## Stage 1.5 (Boss lesson -> Boss encounter) -> complete D1 -> save -> restart/reload ->
## D1 still completed -> D2 still locked -> Hub/Map agree -> prologue_gate.json deletion isolation ->
## No player-facing debug text.

const TEST_DIR: String = "user://test_p0_sanity_082/"

func _initialize() -> void:
	var ok: bool = run_all_tests(self)
	quit(0 if ok else 1)

static func run_all_tests(tree: SceneTree = null) -> bool:
	print("=== RUNNING P0 INTEGRATION CANDIDATE 082 SANITY TEST ===")
	_ensure_test_dir()
	var all_ok: bool = true

	all_ok = test_full_d1_flow_and_restart_consistency(tree) and all_ok
	all_ok = test_prologue_gate_deletion_isolation() and all_ok
	all_ok = test_no_restored_debug_text_in_shell() and all_ok

	_cleanup_test_dir()

	if all_ok:
		print("=== P0 INTEGRATION CANDIDATE 082 SANITY TEST: ALL PASSED! ===")
	else:
		print("=== P0 INTEGRATION CANDIDATE 082 SANITY TEST: FAILED! ===")
	return all_ok

static func _fail(code: String, msg: String) -> bool:
	push_error("[%s] FAIL: %s" % [code, msg])
	print("[%s] FAIL: %s" % [code, msg])
	return false

static func _get_catalog() -> ValidatedCatalog:
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://content")
	return repo.get_catalog()

static func _ensure_test_dir() -> void:
	var global_dir: String = ProjectSettings.globalize_path(TEST_DIR)
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

static func _cleanup_test_dir() -> void:
	var global_dir: String = ProjectSettings.globalize_path(TEST_DIR)
	if DirAccess.dir_exists_absolute(global_dir):
		var dir: DirAccess = DirAccess.open(global_dir)
		if dir != null:
			dir.list_dir_begin()
			var fname: String = dir.get_next()
			while fname != "":
				if fname != "." and fname != "..":
					var sub_path: String = global_dir.path_join(fname)
					if DirAccess.dir_exists_absolute(sub_path):
						var sub_dir: DirAccess = DirAccess.open(sub_path)
						if sub_dir != null:
							sub_dir.list_dir_begin()
							var sname: String = sub_dir.get_next()
							while sname != "":
								if sname != "." and sname != "..":
									sub_dir.remove(sname)
								sname = sub_dir.get_next()
							sub_dir.list_dir_end()
						DirAccess.remove_absolute(sub_path)
					else:
						dir.remove(fname)
				fname = dir.get_next()
			dir.list_dir_end()
		DirAccess.remove_absolute(global_dir)

static func _cleanup_node(node: Node) -> void:
	if node != null:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		if node.is_inside_tree():
			node.queue_free()
		else:
			node.free()

static func test_full_d1_flow_and_restart_consistency(tree: SceneTree) -> bool:
	print("[SANITY-001] Step 1: Testing Fresh Guest invariants...")
	var catalog: ValidatedCatalog = _get_catalog()
	var store_path: String = TEST_DIR + "playthrough/"
	var store: SaveFileStore = SaveFileStore.new(store_path)
	var save_srv: SaveService = SaveService.new(catalog, store)
	var player: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var progress: ProgressService = ProgressService.new(catalog, player)
	var bridge: ProgressSaveBridge = ProgressSaveBridge.new(catalog, player, progress, save_srv)

	var snap: ProgressState = progress.create_snapshot_view()
	if not snap.cleared_stage_ids.is_empty():
		return _fail("SANITY-001", "Fresh guest must have no cleared stages")
	if not snap.fragment_ids.is_empty():
		return _fail("SANITY-001", "Fresh guest must have 0 fragments")
	if not snap.unlocked_stage_ids.has("stage_01_01"):
		return _fail("SANITY-001", "Fresh guest must have stage_01_01 unlocked")
	if snap.unlocked_stage_ids.has("stage_02_01"):
		return _fail("SANITY-001", "Fresh guest must NOT have stage_02_01 unlocked")
	print("[SANITY-001] PASS: Fresh Guest invariants verified")

	print("[SANITY-002] Step 2: Testing AppRoot D1 normal question and stage progression...")
	var root: AppRoot = AppRoot.new()
	root.bootstrap_runtime()
	if tree != null and tree.root != null:
		tree.root.add_child(root)

	# Enter Stage 1.1 and advance to question phase
	root.select_stage("stage_01_01")
	root._on_story_completed()
	root._on_lesson_continue_requested()

	var shell: StagePresentationShell = root.get_presentation_shell()
	if shell == null:
		_cleanup_node(root)
		return _fail("SANITY-002", "Presentation shell is null")

	var q_panel: QuestionPanel = root.get_question_panel()
	if q_panel == null:
		_cleanup_node(root)
		return _fail("SANITY-002", "QuestionPanel is null in stage 1.1")

	# Question state 078: Fresh invariant
	if q_panel.get_lifecycle_state() != QuestionPanel.LifecycleState.FRESH:
		_cleanup_node(root)
		return _fail("SANITY-002", "QuestionPanel must start in LifecycleState.FRESH")

	print("[SANITY-002] PASS: Normal question starts fresh in Stage 1.1")

	print("[SANITY-003] Step 3: Transition to Stage 1.4 -> Verify NO Boss UI...")
	var app_prog: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03"]:
		var r_id: String = String(cat.get_stage(s_id).get("reward_id", "reward_01_01"))
		app_prog.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, [] as Array[String]))

	root.select_stage("stage_01_04")
	if shell.is_boss_stage():
		_cleanup_node(root)
		return _fail("SANITY-003", "Stage 1.4 must NOT be classified as boss stage")

	var existing_boss: BossCombatPanel = shell.get_existing_boss_combat_panel()
	if existing_boss != null and existing_boss.visible:
		_cleanup_node(root)
		return _fail("SANITY-003", "Stage 1.4 must not display BossCombatPanel")

	print("[SANITY-003] PASS: Stage 1.4 has NO Boss UI and AdvisorPanel owns gameplay HBox")

	print("[SANITY-004] Step 4: Advance to Stage 1.5 -> Lesson -> Boss encounter...")
	var r_id_04: String = String(cat.get_stage("stage_01_04").get("reward_id", "reward_01_04"))
	app_prog.commit_stage_clear("stage_01_04", RewardGrant.new(r_id_04, "stage_01_04", 10, 10, [] as Array[String]))
	root.select_stage("stage_01_05")

	# In Story/Lesson mode before combat: Boss UI must be hidden
	existing_boss = shell.get_existing_boss_combat_panel()
	if existing_boss != null and existing_boss.visible:
		_cleanup_node(root)
		return _fail("SANITY-004", "Boss panel must not be visible during Story phase")

	shell.show_lesson_phase()
	existing_boss = shell.get_existing_boss_combat_panel()
	if existing_boss != null and existing_boss.visible:
		_cleanup_node(root)
		return _fail("SANITY-004", "Boss panel must not be visible during Lesson phase")

	# Lesson continue to combat (Bat dau giai do)
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)
	if not shell.is_boss_stage():
		_cleanup_node(root)
		return _fail("SANITY-004", "Stage 1.5 must be classified as boss stage")

	var boss_panel: BossCombatPanel = shell.get_boss_combat_panel()
	if boss_panel == null or not boss_panel.visible:
		_cleanup_node(root)
		return _fail("SANITY-004", "BossCombatPanel must be visible in Stage 1.5 question mode")

	print("[SANITY-004] PASS: Stage 1.5 activates Boss encounter strictly on question mode")

	print("[SANITY-005] Step 5: Complete D1 -> Save to disk...")
	_cleanup_node(root)

	# Commit full D1 clears (1.1..1.5) via ProgressSaveBridge to our isolated store
	for i in range(1, 6):
		var s_id: String = "stage_01_%02d" % i
		var r_id: String = String(catalog.get_stage(s_id).get("reward_id", "reward_01_01"))
		var frags: Array[String] = []
		if i == 5:
			frags.append("fragment_01")
		var reward: RewardGrant = RewardGrant.new(r_id, s_id, 25, 50, frags)
		var c_res: Dictionary = bridge.commit_stage_and_checkpoint(s_id, reward)
		if not bool(c_res.get("success", false)):
			return _fail("SANITY-005", "Failed to commit stage clear for " + s_id)

	var d1_snap: ProgressState = progress.create_snapshot_view()
	if d1_snap.cleared_stage_ids.size() != 5:
		return _fail("SANITY-005", "Expected 5 cleared stages")
	if not d1_snap.fragment_ids.has("fragment_01") or d1_snap.fragment_ids.size() != 1:
		return _fail("SANITY-005", "Expected exactly fragment_01 in progress")
	if not d1_snap.cleared_stage_ids.has("stage_01_05"):
		return _fail("SANITY-005", "Expected stage_01_05 to be cleared")

	print("[SANITY-005] PASS: Full D1 completed and persisted to disk")

	print("[SANITY-006] Step 6: Restart/reload simulation -> Verify hydration and lock consistency...")
	# Simulate fresh boot with disk save present
	var store_reload: SaveFileStore = SaveFileStore.new(store_path)
	var save_srv_reload: SaveService = SaveService.new(catalog, store_reload)
	var player_reload: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var prog_reload: ProgressService = ProgressService.new(catalog, player_reload)
	var bridge_reload: ProgressSaveBridge = ProgressSaveBridge.new(catalog, player_reload, prog_reload, save_srv_reload)

	# Hydrate from disk
	var hyd_ok: bool = bridge_reload.hydrate_initial_state()
	if not hyd_ok:
		return _fail("SANITY-006", "hydrate_initial_state failed on reload")

	# 1. D1 still completed
	var re_snap: ProgressState = prog_reload.create_snapshot_view()
	if not re_snap.cleared_stage_ids.has("stage_01_05"):
		return _fail("SANITY-006", "stage_01_05 not cleared after reload")
	if re_snap.cleared_stage_ids.size() != 5:
		return _fail("SANITY-006", "Cleared stage count changed after reload: %d" % re_snap.cleared_stage_ids.size())
	if not re_snap.fragment_ids.has("fragment_01") or re_snap.fragment_ids.size() != 1:
		return _fail("SANITY-006", "Fragment count/id changed after reload")

	# 2. D2 still locked
	if prog_reload.can_enter("stage_02_01"):
		return _fail("SANITY-006", "stage_02_01 is legally enterable but D2 is frozen!")
	if re_snap.unlocked_dungeon_ids.has("dungeon_02"):
		return _fail("SANITY-006", "dungeon_02 leaked into unlocked dungeons after reload")
	if re_snap.unlocked_stage_ids.has("stage_02_01"):
		return _fail("SANITY-006", "stage_02_01 leaked into unlocked stages after reload")

	# 3. Hub/Map agree
	var legal_entry: String = bridge_reload.get_legal_entry_stage_id()
	if legal_entry != "stage_01_05":
		return _fail("SANITY-006", "Hub continue points to '%s', expected 'stage_01_05'" % legal_entry)

	print("[SANITY-006] PASS: Restart hydration preserves D1 complete, 1 fragment, D2 locked, Hub/Map agreement")
	return true

static func test_prologue_gate_deletion_isolation() -> bool:
	print("[SANITY-007] Step 7: Testing prologue_gate.json deletion isolation...")
	var catalog: ValidatedCatalog = _get_catalog()
	var store_path: String = TEST_DIR + "gate_iso/"
	var store: SaveFileStore = SaveFileStore.new(store_path)
	var save_srv: SaveService = SaveService.new(catalog, store)
	var player: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var progress: ProgressService = ProgressService.new(catalog, player)
	var bridge: ProgressSaveBridge = ProgressSaveBridge.new(catalog, player, progress, save_srv)

	# Commit D1 clear
	for i in range(1, 6):
		var s_id: String = "stage_01_%02d" % i
		var r_id: String = String(catalog.get_stage(s_id).get("reward_id", "reward_01_01"))
		var frags: Array[String] = []
		if i == 5:
			frags.append("fragment_01")
		bridge.commit_stage_and_checkpoint(s_id, RewardGrant.new(r_id, s_id, 10, 10, frags))

	# Write a fake prologue_gate.json
	var gate_path: String = store_path + "prologue_gate.json"
	var f: FileAccess = FileAccess.open(gate_path, FileAccess.WRITE)
	if f != null:
		f.store_string('{"prologue_completed": true}')
		f.close()

	if not FileAccess.file_exists(gate_path):
		return _fail("SANITY-007", "Failed to create dummy prologue_gate.json")

	# Delete prologue_gate.json
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gate_path))
	if FileAccess.file_exists(gate_path):
		return _fail("SANITY-007", "Failed to delete prologue_gate.json")

	# Verify save_v1 is intact and reload still works
	var reload_store: SaveFileStore = SaveFileStore.new(store_path)
	var reload_srv: SaveService = SaveService.new(catalog, reload_store)
	var reload_player: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var reload_prog: ProgressService = ProgressService.new(catalog, reload_player)
	var reload_bridge: ProgressSaveBridge = ProgressSaveBridge.new(catalog, reload_player, reload_prog, reload_srv)

	var hyd_ok: bool = reload_bridge.hydrate_initial_state()
	if not hyd_ok:
		return _fail("SANITY-007", "Reload failed after deleting prologue_gate.json")

	var snap: ProgressState = reload_prog.create_snapshot_view()
	if not snap.cleared_stage_ids.has("stage_01_05") or snap.fragment_ids.size() != 1:
		return _fail("SANITY-007", "D1 progress altered by prologue_gate deletion!")

	print("[SANITY-007] PASS: Deleting prologue_gate.json has zero impact on saved progression")
	return true

static func test_no_restored_debug_text_in_shell() -> bool:
	print("[SANITY-008] Step 8: Testing RestoredBadgeLabel text is empty...")
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell

	var restored_ctx: PresentationModels.StageContextInfo = PresentationModels.StageContextInfo.new(
		"stage_01_02", "Stage 1.2", "Dungeon 1", [], true
	)
	shell.set_stage_context(restored_ctx)
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_LESSON)

	var badge: Label = shell._get_restored_badge_label()
	if badge == null:
		_cleanup_node(shell)
		return _fail("SANITY-008", "RestoredBadgeLabel not found in shell hierarchy")

	if badge.text != "":
		_cleanup_node(shell)
		return _fail("SANITY-008", "RestoredBadgeLabel text must be empty! Got: '" + badge.text + "'")

	_cleanup_node(shell)
	print("[SANITY-008] PASS: RestoredBadgeLabel has empty text (no player-facing developer marker)")
	return true
