class_name TestSaveProgressionConsistency
extends SceneTree

## Automated verification suite for MATHOS-P0-SAVE-PROGRESSION-CONSISTENCY-079.
## Verifies that:
## 1. Fresh guest save has D1 open, 0 fragments, 0/4 dungeons.
## 2. Complete D1 achieves 1 fragment, 1/4 dungeons, and does not leak locked D2 into unlocked stages.
## 3. Persist + simulated restart restores exact completion state into Map and services without Continue.
## 4. Deleting prologue_gate.json alone leaves player progression completely intact.
## 5. Hub Continue and Map unlock state never conflict; no locked stage resumed.
## 6. New game/reset intentionally resets progression to fresh state.
## 7. Existing user save containing legacy stage_02_01 is loaded safely and normalized.
## 8. Config toggle: when D2 is configured playable, Hub and progression agree on D2.

const TEST_DIR: String = "user://test_save_progression_consistency/"
const PrologueGateService = preload("res://src/gameplay/prologue/prologue_gate_service.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func run_all_tests() -> bool:
	print("--- RUNNING SAVE PROGRESSION CONSISTENCY QA SUITE (SAVE-PROG-001..008) ---")
	_ensure_test_dir()

	var all_ok: bool = true
	all_ok = test_prog_001_fresh_guest_save() and all_ok
	all_ok = test_prog_002_complete_d1_state() and all_ok
	all_ok = test_prog_003_persist_and_simulated_restart() and all_ok
	all_ok = test_prog_004_prologue_gate_isolation() and all_ok
	all_ok = test_prog_005_hub_continue_map_unlock_consistency() and all_ok
	all_ok = test_prog_006_new_game_resets_progression() and all_ok
	all_ok = test_prog_007_existing_user_save_compatibility() and all_ok
	all_ok = test_prog_008_config_toggle_playable_dungeon() and all_ok

	_cleanup_test_dir()
	if all_ok:
		print("==========================================")
		print("SAVE PROGRESSION CONSISTENCY SUMMARY: PASS 8 / FAIL 0")
		print("==========================================")
	else:
		print("SAVE PROGRESSION CONSISTENCY SUITE FAILED")
	return all_ok

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

# 1. Fresh guest save: D1 open, fragment 0, dungeon 0/4
static func test_prog_001_fresh_guest_save() -> bool:
	print("[SAVE-PROG-001] Testing fresh guest save state...")
	var catalog: ValidatedCatalog = _get_catalog()
	if catalog == null:
		print("[SAVE-PROG-001] FAIL: Could not load ValidatedCatalog")
		return false

	var player: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var progress: ProgressService = ProgressService.new(catalog, player)

	var snap: ProgressState = progress.create_snapshot_view()
	if snap.cleared_stage_ids.size() != 0:
		print("[SAVE-PROG-001] FAIL: Fresh save has cleared stages")
		return false
	if snap.fragment_ids.size() != 0:
		print("[SAVE-PROG-001] FAIL: Fresh save has fragments")
		return false
	if not snap.unlocked_stage_ids.has("stage_01_01"):
		print("[SAVE-PROG-001] FAIL: Fresh save missing stage_01_01")
		return false
	if not snap.unlocked_dungeon_ids.has("dungeon_01"):
		print("[SAVE-PROG-001] FAIL: Fresh save missing dungeon_01")
		return false

	print("[SAVE-PROG-001] PASS: Fresh guest save verified (D1 open, 0 frags, 0/4 dungeons)")
	return true

# 2. Complete D1: state becomes fragment 1, dungeon 1/4, D1 complete
static func test_prog_002_complete_d1_state() -> bool:
	print("[SAVE-PROG-002] Testing complete D1 progression and lock invariants...")
	var catalog: ValidatedCatalog = _get_catalog()
	var store: SaveFileStore = SaveFileStore.new(TEST_DIR + "test_002/")
	var save_srv: SaveService = SaveService.new(catalog, store)
	var player: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var progress: ProgressService = ProgressService.new(catalog, player)
	var bridge: ProgressSaveBridge = ProgressSaveBridge.new(catalog, player, progress, save_srv)

	# Clear stages 1.1 to 1.5
	for i in range(1, 6):
		var s_id: String = "stage_01_%02d" % i
		var r_id: String = "reward_01_%02d" % i
		var frags: Array[String] = []
		if i == 5:
			frags.append("fragment_01")
		var reward: RewardGrant = RewardGrant.new(r_id, s_id, 10, 10, frags)
		var res: Dictionary = bridge.commit_stage_and_checkpoint(s_id, reward)
		if not bool(res.get("success", false)):
			print("[SAVE-PROG-002] FAIL: Commit stage clear failed for " + s_id)
			return false

	var snap: ProgressState = progress.create_snapshot_view()
	if snap.cleared_stage_ids.size() != 5:
		print("[SAVE-PROG-002] FAIL: Expected 5 cleared stages, got %d" % snap.cleared_stage_ids.size())
		return false
	if not snap.fragment_ids.has("fragment_01") or snap.fragment_ids.size() != 1:
		print("[SAVE-PROG-002] FAIL: Expected exactly fragment_01, got %s" % str(snap.fragment_ids))
		return false

	# Invariant: SaveService load must sanitize unlocked stages to playable content
	var load_res: Dictionary = save_srv.load()
	if not bool(load_res.get("success", false)):
		print("[SAVE-PROG-002] FAIL: Save load failed")
		return false
	var snap_dict: Dictionary = (load_res.get("snapshot", {}) as Dictionary).get("progress", {}) as Dictionary
	var unlocked_stages: Array = snap_dict.get("unlocked_stage_ids", []) as Array
	if unlocked_stages.has("stage_02_01"):
		print("[SAVE-PROG-002] FAIL: stage_02_01 leaked into saved unlocked_stage_ids")
		return false
	var unlocked_dungeons: Array = snap_dict.get("unlocked_dungeon_ids", []) as Array
	if unlocked_dungeons.has("dungeon_02"):
		print("[SAVE-PROG-002] FAIL: dungeon_02 leaked into saved unlocked_dungeon_ids")
		return false

	# Invariant: Legal entry stage must be stage_01_05
	var entry: String = bridge.get_legal_entry_stage_id()
	if entry != "stage_01_05":
		print("[SAVE-PROG-002] FAIL: Expected entry stage_01_05, got %s" % entry)
		return false

	print("[SAVE-PROG-002] PASS: Complete D1 state verified (1 frag, 5 stages cleared, D2 locked)")
	return true

# 3. Persist + simulated restart/reload: exact completion state restored into Map and services
static func test_prog_003_persist_and_simulated_restart() -> bool:
	print("[SAVE-PROG-003] Testing persistence + simulated restart hydration...")
	_ensure_test_dir()
	var catalog: ValidatedCatalog = _get_catalog()
	var store_path: String = TEST_DIR + "test_003/"
	var store1: SaveFileStore = SaveFileStore.new(store_path)
	var save_srv1: SaveService = SaveService.new(catalog, store1)
	var player1: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var prog1: ProgressService = ProgressService.new(catalog, player1)
	var bridge1: ProgressSaveBridge = ProgressSaveBridge.new(catalog, player1, prog1, save_srv1)

	# Clear D1 and checkpoint
	for i in range(1, 6):
		var s_id: String = "stage_01_%02d" % i
		var r_id: String = "reward_01_%02d" % i
		var frags: Array[String] = []
		if i == 5:
			frags.append("fragment_01")
		var reward: RewardGrant = RewardGrant.new(r_id, s_id, 14, 14, frags)
		var commit_res: Dictionary = bridge1.commit_stage_and_checkpoint(s_id, reward)
		if not bool(commit_res.get("success", false)):
			print("[SAVE-PROG-003] FAIL: Commit failed at " + s_id)
			return false

	# Verify disk file exists
	if not store1.file_exists(store1.main_path):
		print("[SAVE-PROG-003] FAIL: Save file not written to disk")
		return false

	# SIMULATE APP RESTART: Instantiate fresh objects exactly like AppRoot.bootstrap_runtime()
	var store2: SaveFileStore = SaveFileStore.new(store_path)
	var save_srv2: SaveService = SaveService.new(catalog, store2)
	var player2: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var prog2: ProgressService = ProgressService.new(catalog, player2)
	var bridge2: ProgressSaveBridge = ProgressSaveBridge.new(catalog, player2, prog2, save_srv2)

	# Verify auto-hydration on _init immediately populated player and progress
	if player2.coin_balance != 70 or player2.exp_total != 70:
		print("[SAVE-PROG-003] FAIL: Post-boot player balances mismatch: coin=%d, exp=%d" % [player2.coin_balance, player2.exp_total])
		return false

	var snap2: ProgressState = prog2.create_snapshot_view()
	if snap2.cleared_stage_ids.size() != 5 or not snap2.cleared_stage_ids.has("stage_01_05"):
		print("[SAVE-PROG-003] FAIL: Post-boot cleared stages mismatch: %s" % str(snap2.cleared_stage_ids))
		return false
	if snap2.fragment_ids.size() != 1 or not snap2.fragment_ids.has("fragment_01"):
		print("[SAVE-PROG-003] FAIL: Post-boot fragments mismatch: %s" % str(snap2.fragment_ids))
		return false

	# Verify Map snapshot view sees completed D1
	var is_d1_completed: bool = ("stage_01_05" in snap2.cleared_stage_ids)
	if not is_d1_completed:
		print("[SAVE-PROG-003] FAIL: Map would not see D1 as completed")
		return false

	print("[SAVE-PROG-003] PASS: Post-restart hydration verified (exact state restored on boot)")
	return true

# 4. Delete/reset Prologue gate only: player progression remains unchanged
static func test_prog_004_prologue_gate_isolation() -> bool:
	print("[SAVE-PROG-004] Testing prologue_gate.json deletion isolation...")
	_ensure_test_dir()
	var catalog: ValidatedCatalog = _get_catalog()
	var store_path: String = TEST_DIR + "test_004/"
	var gate_path: String = TEST_DIR + "test_004_gate.json"

	var store: SaveFileStore = SaveFileStore.new(store_path)
	var save_srv: SaveService = SaveService.new(catalog, store)
	var player: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var prog: ProgressService = ProgressService.new(catalog, player)
	var bridge: ProgressSaveBridge = ProgressSaveBridge.new(catalog, player, prog, save_srv)
	var gate: PrologueGateService = PrologueGateService.new(gate_path)

	# Mark prologue seen and complete D1
	gate.mark_prologue_completed()
	for i in range(1, 6):
		var s_id: String = "stage_01_%02d" % i
		var r_id: String = "reward_01_%02d" % i
		var frags: Array[String] = []
		if i == 5:
			frags.append("fragment_01")
		bridge.commit_stage_and_checkpoint(s_id, RewardGrant.new(r_id, s_id, 10, 10, frags))

	# TEST ACTION: Delete/reset prologue gate ONLY
	gate.reset_state()
	if FileAccess.file_exists(gate_path):
		print("[SAVE-PROG-004] FAIL: Prologue gate file was not deleted")
		return false

	# SIMULATE APP RESTART with deleted prologue gate
	var store_reboot: SaveFileStore = SaveFileStore.new(store_path)
	var save_reboot: SaveService = SaveService.new(catalog, store_reboot)
	var player_reboot: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var prog_reboot: ProgressService = ProgressService.new(catalog, player_reboot)
	var bridge_reboot: ProgressSaveBridge = ProgressSaveBridge.new(catalog, player_reboot, prog_reboot, save_reboot)
	var gate_reboot: PrologueGateService = PrologueGateService.new(gate_path)

	# Invariants after prologue gate reset:
	# A. Player progression remains 100% intact
	var snap_reboot: ProgressState = prog_reboot.create_snapshot_view()
	if snap_reboot.cleared_stage_ids.size() != 5 or not snap_reboot.fragment_ids.has("fragment_01"):
		print("[SAVE-PROG-004] FAIL: Player progression altered by prologue gate deletion!")
		return false

	# B. is_first_dungeon_entry evaluates to true because gate was reset, allowing prologue replay
	var is_first: bool = gate_reboot.is_first_dungeon_entry("stage_01_01", snap_reboot)
	if not is_first:
		print("[SAVE-PROG-004] FAIL: Deleting prologue gate did not cause Dungeon I entry to replay prologue")
		return false

	# Marking prologue completed restores suppression
	gate_reboot.mark_prologue_completed()
	if gate_reboot.is_first_dungeon_entry("stage_01_01", snap_reboot):
		print("[SAVE-PROG-004] FAIL: Marking prologue completed did not suppress prologue replay")
		return false

	print("[SAVE-PROG-004] PASS: Prologue gate isolation verified (zero impact on save progression)")
	return true

# 5. Hub Continue vs Map unlock consistency: no locked stage may be resumed through Continue
static func test_prog_005_hub_continue_map_unlock_consistency() -> bool:
	print("[SAVE-PROG-005] Testing Hub Continue vs Map unlock agreement...")
	_ensure_test_dir()
	var catalog: ValidatedCatalog = _get_catalog()
	var store_path: String = TEST_DIR + "test_005/"
	var store: SaveFileStore = SaveFileStore.new(store_path)
	var save_srv: SaveService = SaveService.new(catalog, store)
	var player: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var prog: ProgressService = ProgressService.new(catalog, player)
	var bridge: ProgressSaveBridge = ProgressSaveBridge.new(catalog, player, prog, save_srv)

	# Clear D1
	for i in range(1, 6):
		var s_id: String = "stage_01_%02d" % i
		var r_id: String = "reward_01_%02d" % i
		var frags: Array[String] = []
		if i == 5:
			frags.append("fragment_01")
		bridge.commit_stage_and_checkpoint(s_id, RewardGrant.new(r_id, s_id, 10, 10, frags))

	# Check what Hub Continue sees from load():
	var load_res: Dictionary = save_srv.load()
	if not bool(load_res.get("success", false)):
		print("[SAVE-PROG-005] FAIL: Save load failed")
		return false

	var snapshot: Dictionary = load_res.get("snapshot", {}) as Dictionary
	var prog_dict: Dictionary = snapshot.get("progress", {}) as Dictionary
	var unlocked_stages: Array = prog_dict.get("unlocked_stage_ids", []) as Array
	var entry_stage_id: String = String(unlocked_stages[unlocked_stages.size() - 1])

	# INVARIANT: Hub entry stage ID MUST NOT be stage_02_01
	if entry_stage_id == "stage_02_01" or entry_stage_id.begins_with("stage_02_"):
		print("[SAVE-PROG-005] FAIL: Hub Continue points to locked D2 stage '%s'!" % entry_stage_id)
		return false

	if entry_stage_id != "stage_01_05":
		print("[SAVE-PROG-005] FAIL: Expected latest playable stage stage_01_05, got '%s'" % entry_stage_id)
		return false

	# INVARIANT: ProgressSaveBridge.get_legal_entry_stage_id must also return stage_01_05
	var bridge_entry: String = bridge.get_legal_entry_stage_id()
	if bridge_entry != "stage_01_05":
		print("[SAVE-PROG-005] FAIL: Bridge legal entry stage mismatch: '%s'" % bridge_entry)
		return false

	# INVARIANT: Save snapshot unlocked stages must not contain stage_02_01
	if unlocked_stages.has("stage_02_01"):
		print("[SAVE-PROG-005] FAIL: Save snapshot unlocked stages contains locked stage_02_01")
		return false

	print("[SAVE-PROG-005] PASS: Hub Continue vs Map unlock agreement verified (stage_01_05 active, D2 locked)")
	return true

# 6. New game/reset: still resets progression intentionally
static func test_prog_006_new_game_resets_progression() -> bool:
	print("[SAVE-PROG-006] Testing New Game intentional progression reset...")
	var catalog: ValidatedCatalog = _get_catalog()
	var player: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 100, 200)
	var prog: ProgressService = ProgressService.new(catalog, player)

	# Clear some stages first
	for i in range(1, 4):
		var s_id: String = "stage_01_%02d" % i
		var r_id: String = "reward_01_%02d" % i
		var frags: Array[String] = []
		prog.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, frags))

	var q_srv: QuestionService = QuestionService.new(catalog)
	var flow: GameFlowService = GameFlowService.new(catalog, q_srv, prog, null, player)

	# Execute start_new_game
	var res: Dictionary = flow.start_new_game()
	if not bool(res.get("success", false)):
		print("[SAVE-PROG-006] FAIL: start_new_game failed")
		return false

	# Verify progression was reset
	var snap: ProgressState = prog.create_snapshot_view()
	if snap.cleared_stage_ids.size() != 0:
		print("[SAVE-PROG-006] FAIL: Cleared stages not reset after New Game: %s" % str(snap.cleared_stage_ids))
		return false
	if player.coin_balance != 0 or player.exp_total != 0:
		print("[SAVE-PROG-006] FAIL: Player balances not reset after New Game: coin=%d, exp=%d" % [player.coin_balance, player.exp_total])
		return false

	print("[SAVE-PROG-006] PASS: New Game intentional progression reset verified")
	return true

# 7. Existing user save compatibility: loads existing save containing stage_02_01 and normalizes
static func test_prog_007_existing_user_save_compatibility() -> bool:
	print("[SAVE-PROG-007] Testing existing user save backwards compatibility...")
	_ensure_test_dir()
	var catalog: ValidatedCatalog = _get_catalog()
	var store_path: String = TEST_DIR + "test_007/"
	var store: SaveFileStore = SaveFileStore.new(store_path)

	# Construct legacy save file directly containing stage_02_01 in unlocked stages
	var legacy_snapshot: Dictionary = {
		"schema_version": 1,
		"game_version": "1.0.0",
		"content_version": 1,
		"saved_at_utc": "2026-09-06T10:00:00Z",
		"profile_id": "local_player",
		"player_persistent": {
			"player_id": "char_karl",
			"coin_balance": 150,
			"exp_total": 200
		},
		"progress": {
			"unlocked_dungeon_ids": ["dungeon_01", "dungeon_02"],
			"unlocked_stage_ids": ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04", "stage_01_05", "stage_02_01"],
			"cleared_stage_ids": ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04", "stage_01_05"],
			"fragment_ids": ["fragment_01"],
			"game_complete": false
		},
		"adaptive_profile": {
			"attempts_total": 5,
			"correct_total": 5,
			"consecutive_correct": 5,
			"consecutive_incorrect": 0,
			"topic_stats": {},
			"recent_records": []
		}
	}

	var json_text: String = SaveSnapshotCodec.serialize(legacy_snapshot)
	store.write_text(store.main_path, json_text)

	# Load via SaveService
	var save_srv: SaveService = SaveService.new(catalog, store)
	var load_res: Dictionary = save_srv.load()
	if not bool(load_res.get("success", false)):
		print("[SAVE-PROG-007] FAIL: Failed to load legacy save snapshot: ", load_res)
		return false

	var loaded_snap: Dictionary = load_res.get("snapshot", {}) as Dictionary
	var prog_dict: Dictionary = loaded_snap.get("progress", {}) as Dictionary
	var unlocked_stages: Array = prog_dict.get("unlocked_stage_ids", []) as Array
	var unlocked_dungeons: Array = prog_dict.get("unlocked_dungeon_ids", []) as Array

	# Verify normalization to playable content boundary
	if unlocked_stages.has("stage_02_01"):
		print("[SAVE-PROG-007] FAIL: Legacy stage_02_01 not filtered from unlocked_stage_ids")
		return false
	if unlocked_dungeons.has("dungeon_02"):
		print("[SAVE-PROG-007] FAIL: Legacy dungeon_02 not filtered from unlocked_dungeon_ids")
		return false

	# Verify hydration via bridge
	var player: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var prog: ProgressService = ProgressService.new(catalog, player)
	var bridge: ProgressSaveBridge = ProgressSaveBridge.new(catalog, player, prog, save_srv)

	var bridge_entry: String = bridge.get_legal_entry_stage_id()
	if bridge_entry != "stage_01_05":
		print("[SAVE-PROG-007] FAIL: Expected legal entry stage_01_05, got '%s'" % bridge_entry)
		return false

	if player.coin_balance != 150 or player.exp_total != 200:
		print("[SAVE-PROG-007] FAIL: Player balances mismatch after legacy restore")
		return false

	print("[SAVE-PROG-007] PASS: Existing user save compatibility verified (clean normalization)")
	return true

# 8. Config toggle: when D2 is configured playable, Hub and progression agree on D2
static func test_prog_008_config_toggle_playable_dungeon() -> bool:
	print("[SAVE-PROG-008] Testing dynamic config toggle agreement...")
	_ensure_test_dir()
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://content")
	var catalog: ValidatedCatalog = repo.get_catalog()

	# Create custom catalog configuration with playable_dungeon_ids: ["dungeon_01", "dungeon_02"]
	var custom_config: Dictionary = catalog.get_config()
	custom_config["playable_dungeon_ids"] = ["dungeon_01", "dungeon_02"]

	var cat_d2: ValidatedCatalog = ValidatedCatalog.new(
		custom_config,
		catalog._dungeons,
		catalog._stages,
		catalog._story,
		catalog._lessons,
		catalog._practice,
		catalog._questions,
		catalog._cards,
		catalog._enemies,
		catalog._rewards,
		catalog._math_knowledge,
		catalog._question_generation
	)

	if not cat_d2.is_dungeon_playable("dungeon_02"):
		print("[SAVE-PROG-008] FAIL: cat_d2 did not recognize dungeon_02 as playable")
		return false

	var player: PlayerPersistentState = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var prog: ProgressService = ProgressService.new(cat_d2, player)

	# Clear D1
	for i in range(1, 6):
		var s_id: String = "stage_01_%02d" % i
		var r_id: String = "reward_01_%02d" % i
		var frags: Array[String] = []
		if i == 5:
			frags.append("fragment_01")
		prog.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, frags))

	var snap: ProgressState = prog.create_snapshot_view()
	# Because D2 is playable in cat_d2, clearing D1 should unlock dungeon_02 and stage_02_01
	if not snap.unlocked_dungeon_ids.has("dungeon_02"):
		print("[SAVE-PROG-008] FAIL: dungeon_02 was not unlocked when configured as playable")
		return false
	if not snap.unlocked_stage_ids.has("stage_02_01"):
		print("[SAVE-PROG-008] FAIL: stage_02_01 was not unlocked when configured as playable")
		return false

	var store_path: String = TEST_DIR + "test_008/"
	var store: SaveFileStore = SaveFileStore.new(store_path)
	var save_srv: SaveService = SaveService.new(cat_d2, store)
	var bridge: ProgressSaveBridge = ProgressSaveBridge.new(cat_d2, player, prog, save_srv)

	var entry_stage: String = bridge.get_legal_entry_stage_id()
	if entry_stage != "stage_02_01":
		print("[SAVE-PROG-008] FAIL: Expected legal entry stage_02_01, got '%s'" % entry_stage)
		return false

	print("[SAVE-PROG-008] PASS: Config toggle agreement verified (D2 unlocks when configured playable)")
	return true
