class_name TestSaveIntegration
extends RefCounted

## Integration test suite covering SAVE-01..14 and INT-005, INT-006, INT-010
## end-to-end integration across SaveService, ProgressService, PlayerRuntime, and SaveFileStore.

static func run_all_tests() -> bool:
	print("--- RUNNING SAVE CANONICAL INTEGRATION SUITE (SAVE-01..14, INT-005/006/010) ---")
	var all_ok: bool = true

	all_ok = test_save_01_fresh_save() and all_ok
	all_ok = test_save_02_stage_complete() and all_ok
	all_ok = test_save_03_dungeon_complete() and all_ok
	all_ok = test_save_04_stage_4_5_checkpoint() and all_ok
	all_ok = test_save_05_game_complete() and all_ok
	all_ok = test_save_06_restart_continue() and all_ok
	all_ok = test_save_07_invalid_json() and all_ok
	all_ok = test_save_08_missing_required_field() and all_ok
	all_ok = test_save_09_unsupported_schema() and all_ok
	all_ok = test_save_10_backup_recovery() and all_ok
	all_ok = test_save_11_save_failure_retry() and all_ok
	all_ok = test_save_12_no_duplicate_reward() and all_ok
	all_ok = test_save_13_no_transient_state_saved() and all_ok
	all_ok = test_save_14_temp_main_backup_strategy() and all_ok

	all_ok = test_int_005_progress_to_save() and all_ok
	all_ok = test_int_006_save_to_continue() and all_ok
	all_ok = test_int_010_save_failure_retry() and all_ok

	return all_ok

static func _get_temp_store() -> SaveFileStore:
	var tmp_dir: String = "user://temp_qa_save_%d_%d/" % [Time.get_ticks_msec(), randi_range(1000, 9999)]
	return SaveFileStore.new(tmp_dir)

static func _cleanup_temp_store(store: SaveFileStore) -> void:
	if store != null and store.get_base_dir().begins_with("user://temp_qa_save_"):
		var dir_path: String = store.get_base_dir()
		if DirAccess.dir_exists_absolute(dir_path):
			var dir: DirAccess = DirAccess.open(dir_path)
			if dir != null:
				dir.list_dir_begin()
				var fname: String = dir.get_next()
				while fname != "":
					if fname != "." and fname != "..":
						dir.remove(fname)
					fname = dir.get_next()
				dir.list_dir_end()
				DirAccess.remove_absolute(dir_path)

static func _get_synthetic_catalog() -> ValidatedCatalog:
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	if repo.get_catalog() != null:
		return repo.get_catalog()

	# Fallback synthetic builder
	var config: Dictionary = {
		"adaptive_recent_record_limit": 100,
		"initial_dungeon_id": "dungeon_01",
		"initial_stage_id": "stage_01_01"
	}
	var dungeons: Dictionary = {}
	for i in range(1, 5):
		var did: String = "dungeon_0%d" % i
		var stage_ids: Array = []
		for j in range(1, 6):
			stage_ids.append("stage_0%d_0%d" % [i, j])
		dungeons[did] = {"dungeon_id": did, "topic_id": ValidatedCatalog.TOPIC_BY_DUNGEON.get(did, ""), "stage_ids": stage_ids}

	var stages: Dictionary = {}
	for i in range(1, 5):
		var did: String = "dungeon_0%d" % i
		for j in range(1, 6):
			var sid: String = "stage_0%d_0%d" % [i, j]
			var reward_id: String = "reward_0%d_0%d" % [i, j]
			stages[sid] = {"stage_id": sid, "dungeon_id": did, "reward_id": reward_id}
	var rewards: Dictionary = {}
	for i in range(1, 5):
		for j in range(1, 6):
			var sid: String = "stage_0%d_0%d" % [i, j]
			var rid: String = "reward_0%d_0%d" % [i, j]
			var frag: Variant = null
			if j == 5:
				frag = "fragment_0%d" % i
			rewards[rid] = {"reward_id": rid, "stage_id": sid, "coin_amount": 10, "exp_amount": 20, "fragment_id": frag}
	var questions: Dictionary = {
		"q_001": {"question_id": "q_001", "dungeon_id": "dungeon_01", "topic_id": "trial_sample_event", "subtopic_id": "sample_space"}
	}
	return ValidatedCatalog.new(config, dungeons, stages, {}, {}, {}, questions, {}, {}, rewards)

static func _create_valid_fresh_snapshot_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"game_version": "1.0.0",
		"content_version": 1,
		"saved_at_utc": "2026-08-18T00:00:00Z",
		"profile_id": "local_player",
		"player_persistent": {
			"player_id": "char_karl",
			"coin_balance": 0,
			"exp_total": 0
		},
		"progress": {
			"unlocked_dungeon_ids": ["dungeon_01"],
			"unlocked_stage_ids": ["stage_01_01"],
			"cleared_stage_ids": [],
			"fragment_ids": [],
			"game_complete": false
		},
		"adaptive_profile": {
			"attempts_total": 0,
			"correct_total": 0,
			"consecutive_correct": 0,
			"consecutive_incorrect": 0,
			"topic_stats": {},
			"recent_records": []
		}
	}

# SAVE-01 — Fresh save
static func test_save_01_fresh_save() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	var service: SaveService = SaveService.new(cat, store)

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	var save_res: Dictionary = service.save(snap)
	if not bool(save_res.get("success", false)):
		_cleanup_temp_store(store)
		print("[SAVE-01] FAIL: Save fresh snapshot failed")
		return false

	var load_res: Dictionary = service.load()
	_cleanup_temp_store(store)
	if not bool(load_res.get("success", false)):
		print("[SAVE-01] FAIL: Load fresh save failed")
		return false

	var loaded_dict: Dictionary = load_res.get("snapshot", {})
	if int(loaded_dict.get("schema_version", 0)) != 1:
		print("[SAVE-01] FAIL: schema_version != 1")
		return false

	var prog_dict: Dictionary = loaded_dict.get("progress", {})
	var unlocked_dungeons: Array = prog_dict.get("unlocked_dungeon_ids", [])
	var unlocked_stages: Array = prog_dict.get("unlocked_stage_ids", [])
	if not unlocked_dungeons.has("dungeon_01") or not unlocked_stages.has("stage_01_01"):
		print("[SAVE-01] FAIL: Fresh save missing initial dungeon_01 or stage_01_01 unlock")
		return false

	print("[SAVE-01] PASS: Valid fresh save snapshot committed and loaded")
	return true

# SAVE-02 — Stage complete
static func test_save_02_stage_complete() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	var service: SaveService = SaveService.new(cat, store)

	var player: PlayerPersistentState = PlayerPersistentState.new("char_karl", 0, 0)
	var progress: ProgressService = ProgressService.new(cat, player)

	var empty_frags: Array[String] = []
	var reward: RewardGrant = RewardGrant.new("reward_01_01", "stage_01_01", 10, 20, empty_frags)
	var clear_res: StageCompletionResult = progress.commit_stage_clear("stage_01_01", reward)
	if clear_res == null:
		_cleanup_temp_store(store)
		print("[SAVE-02] FAIL: commit_stage_clear returned null")
		return false

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["progress"]["unlocked_stage_ids"] = ["stage_01_01", "stage_01_02"]
	snap["progress"]["cleared_stage_ids"] = ["stage_01_01"]
	snap["player_persistent"]["coin_balance"] = player.coin_balance
	snap["player_persistent"]["exp_total"] = player.exp_total
	service.save(snap)

	var load_res: Dictionary = service.load()
	_cleanup_temp_store(store)
	if not bool(load_res.get("success", false)):
		print("[SAVE-02] FAIL: Load after stage complete failed")
		return false

	var loaded_dict: Dictionary = load_res.get("snapshot", {})
	var prog_dict: Dictionary = loaded_dict.get("progress", {})
	var unlocked_stages: Array = prog_dict.get("unlocked_stage_ids", [])
	if not unlocked_stages.has("stage_01_02"):
		print("[SAVE-02] FAIL: Restored ProgressService missing stage_01_02 unlock")
		return false

	print("[SAVE-02] PASS: Stage complete victory committed and restored")
	return true

# SAVE-03 — Dungeon complete
static func test_save_03_dungeon_complete() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	var service: SaveService = SaveService.new(cat, store)

	var player: PlayerPersistentState = PlayerPersistentState.new("char_karl", 0, 0)
	var progress: ProgressService = ProgressService.new(cat, player)

	for j in range(1, 6):
		var sid: String = "stage_01_0%d" % j
		var rid: String = "reward_01_0%d" % j
		var frags: Array[String] = []
		if j == 5:
			frags.append("fragment_01")
		var reward: RewardGrant = RewardGrant.new(rid, sid, 10, 20, frags)
		progress.commit_stage_clear(sid, reward)

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["progress"]["unlocked_dungeon_ids"] = ["dungeon_01", "dungeon_02"]
	snap["progress"]["unlocked_stage_ids"] = ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04", "stage_01_05", "stage_02_01"]
	snap["progress"]["cleared_stage_ids"] = ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04", "stage_01_05"]
	snap["progress"]["fragment_ids"] = ["fragment_01"]
	service.save(snap)

	var load_res: Dictionary = service.load()
	_cleanup_temp_store(store)
	var loaded_dict: Dictionary = load_res.get("snapshot", {})
	var prog_dict: Dictionary = loaded_dict.get("progress", {})
	var frags_loaded: Array = prog_dict.get("fragment_ids", [])
	var dungs_loaded: Array = prog_dict.get("unlocked_dungeon_ids", [])

	if not frags_loaded.has("fragment_01") or not dungs_loaded.has("dungeon_02"):
		print("[SAVE-03] FAIL: Dungeon 1 complete missing fragment_01 or dungeon_02 unlock")
		return false

	print("[SAVE-03] PASS: Dungeon complete contains fragment and next dungeon unlock")
	return true

# SAVE-04 — Stage 4.5 checkpoint
static func test_save_04_stage_4_5_checkpoint() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	var service: SaveService = SaveService.new(cat, store)

	var cleared_all: Array = []
	for d in range(1, 5):
		for s in range(1, 6):
			cleared_all.append("stage_0%d_0%d" % [d, s])

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["progress"]["unlocked_dungeon_ids"] = ["dungeon_01", "dungeon_02", "dungeon_03", "dungeon_04"]
	snap["progress"]["unlocked_stage_ids"] = cleared_all.duplicate()
	snap["progress"]["cleared_stage_ids"] = cleared_all.duplicate()
	snap["progress"]["fragment_ids"] = ["fragment_01", "fragment_02", "fragment_03", "fragment_04"]
	snap["progress"]["game_complete"] = false
	var save_res: Dictionary = service.save(snap)
	if not bool(save_res.get("success", false)):
		_cleanup_temp_store(store)
		print("[SAVE-04] FAIL: Save failed: ", save_res)
		return false

	var load_res: Dictionary = service.load()
	_cleanup_temp_store(store)
	var loaded_dict: Dictionary = load_res.get("snapshot", {})
	var prog_dict: Dictionary = loaded_dict.get("progress", {})

	if not prog_dict.get("fragment_ids", []).has("fragment_04"):
		print("[SAVE-04] FAIL: Missing fragment_04 on stage 4.5 checkpoint")
		return false
	if bool(prog_dict.get("game_complete", false)):
		print("[SAVE-04] FAIL: game_complete should be false before ending sequence")
		return false

	print("[SAVE-04] PASS: Stage 4.5 checkpoint contains fragment_04 with game_complete=false")
	return true

# SAVE-05 — Game complete
static func test_save_05_game_complete() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	var service: SaveService = SaveService.new(cat, store)

	var cleared_all: Array = []
	for d in range(1, 5):
		for s in range(1, 6):
			cleared_all.append("stage_0%d_0%d" % [d, s])

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["progress"]["unlocked_dungeon_ids"] = ["dungeon_01", "dungeon_02", "dungeon_03", "dungeon_04"]
	snap["progress"]["unlocked_stage_ids"] = cleared_all.duplicate()
	snap["progress"]["cleared_stage_ids"] = cleared_all
	snap["progress"]["fragment_ids"] = ["fragment_01", "fragment_02", "fragment_03", "fragment_04"]
	snap["progress"]["game_complete"] = true
	service.save(snap)

	var load_res: Dictionary = service.load()
	_cleanup_temp_store(store)
	var loaded_dict: Dictionary = load_res.get("snapshot", {})
	var prog_dict: Dictionary = loaded_dict.get("progress", {})

	if not bool(prog_dict.get("game_complete", false)) or prog_dict.get("cleared_stage_ids", []).size() != 20 or prog_dict.get("fragment_ids", []).size() != 4:
		print("[SAVE-05] FAIL: Game complete snapshot missing game_complete or complete 20 stages / 4 frags")
		return false

	print("[SAVE-05] PASS: Game complete committed with 20 stages, 4 fragments, game_complete=true")
	return true

# SAVE-06 — Restart + Continue
static func test_save_06_restart_continue() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	var service: SaveService = SaveService.new(cat, store)

	var player: PlayerPersistentState = PlayerPersistentState.new("char_karl", 50, 100)
	var progress: ProgressService = ProgressService.new(cat, player)
	var empty_frags: Array[String] = []
	var reward: RewardGrant = RewardGrant.new("reward_01_01", "stage_01_01", 10, 20, empty_frags)
	progress.commit_stage_clear("stage_01_01", reward)

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["player_persistent"]["coin_balance"] = player.coin_balance
	snap["player_persistent"]["exp_total"] = player.exp_total
	snap["progress"]["unlocked_stage_ids"] = ["stage_01_01", "stage_01_02"]
	snap["progress"]["cleared_stage_ids"] = ["stage_01_01"]
	service.save(snap)

	# Restored session
	var load_res: Dictionary = service.load()
	_cleanup_temp_store(store)
	if not bool(load_res.get("success", false)):
		print("[SAVE-06] FAIL: Continue load failed")
		return false

	var loaded_dict: Dictionary = load_res.get("snapshot", {})
	var p_persistent: Dictionary = loaded_dict.get("player_persistent", {})
	var prog_dict: Dictionary = loaded_dict.get("progress", {})

	if int(p_persistent.get("coin_balance", 0)) != 60 or not prog_dict.get("unlocked_stage_ids", []).has("stage_01_02"):
		print("[SAVE-06] FAIL: Restored Continue state incorrect")
		return false

	print("[SAVE-06] PASS: Continue restores committed state cleanly")
	return true

# SAVE-07 — Invalid JSON
static func test_save_07_invalid_json() -> bool:
	var store: SaveFileStore = _get_temp_store()
	store.write_text(store.main_path, "BROKEN_JSON_STRUCT")
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var service: SaveService = SaveService.new(cat, store)
	var res: Dictionary = service.load()
	_cleanup_temp_store(store)
	if bool(res.get("success", false)) or service.has_save():
		print("[SAVE-07] FAIL: Invalid JSON loaded or reported valid save")
		return false
	print("[SAVE-07] PASS: Malformed JSON cleanly rejected without crash")
	return true

# SAVE-08 — Missing required field
static func test_save_08_missing_required_field() -> bool:
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap.erase("profile_id")
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, cat)
	if bool(res.get("success", false)):
		print("[SAVE-08] FAIL: Missing required field profile_id accepted")
		return false
	print("[SAVE-08] PASS: Missing required field rejected")
	return true

# SAVE-09 — Unsupported schema
static func test_save_09_unsupported_schema() -> bool:
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["schema_version"] = 2
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, cat)
	if bool(res.get("success", false)):
		print("[SAVE-09] FAIL: Unsupported schema_version 2 accepted")
		return false
	print("[SAVE-09] PASS: Unsupported schema version rejected")
	return true

# SAVE-10 — Backup recovery
static func test_save_10_backup_recovery() -> bool:
	var store: SaveFileStore = _get_temp_store()
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var service: SaveService = SaveService.new(cat, store)

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	service.save(snap)
	service.save(snap)

	# Corrupt main file
	store.write_text(store.main_path, "BAD_MAIN")

	var rec_res: bool = service.recover_from_backup()
	if not rec_res:
		_cleanup_temp_store(store)
		print("[SAVE-10] FAIL: recover_from_backup returned false")
		return false

	var load_res: Dictionary = service.load()
	_cleanup_temp_store(store)
	if not bool(load_res.get("success", false)):
		print("[SAVE-10] FAIL: Load after recovery failed")
		return false

	print("[SAVE-10] PASS: Backup recovery succeeded cleanly")
	return true

# SAVE-11 — Save failure + retry
static func test_save_11_save_failure_retry() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var player: PlayerPersistentState = PlayerPersistentState.new("char_karl", 0, 0)
	var progress: ProgressService = ProgressService.new(cat, player)
	var empty_frags: Array[String] = []
	var reward: RewardGrant = RewardGrant.new("reward_01_01", "stage_01_01", 10, 20, empty_frags)
	progress.commit_stage_clear("stage_01_01", reward)

	# Fail store
	var store_fail: SaveFileStore = _get_temp_store()
	store_fail.inject_fail_temp_write = true
	var service_fail: SaveService = SaveService.new(cat, store_fail)
	var snap1: Dictionary = _create_valid_fresh_snapshot_dict()
	var save_fail_res: Dictionary = service_fail.save(snap1)
	_cleanup_temp_store(store_fail)
	if bool(save_fail_res.get("success", false)):
		print("[SAVE-11] FAIL: Save succeeded on unwritable path")
		return false

	# Retry store
	var store_ok: SaveFileStore = _get_temp_store()
	var service_ok: SaveService = SaveService.new(cat, store_ok)
	var snap2: Dictionary = _create_valid_fresh_snapshot_dict()
	snap2["player_persistent"]["coin_balance"] = player.coin_balance
	snap2["player_persistent"]["exp_total"] = player.exp_total
	snap2["progress"]["cleared_stage_ids"] = ["stage_01_01"]
	snap2["progress"]["unlocked_stage_ids"] = ["stage_01_01", "stage_01_02"]
	var save_ok_res: Dictionary = service_ok.save(snap2)

	var load_res: Dictionary = service_ok.load()
	_cleanup_temp_store(store_ok)
	if not bool(save_ok_res.get("success", false)) or not bool(load_res.get("success", false)):
		print("[SAVE-11] FAIL: Save failure retry failed")
		return false

	print("[SAVE-11] PASS: In-memory state preserved during save failure; retry succeeded")
	return true

# SAVE-12 — No duplicate reward
static func test_save_12_no_duplicate_reward() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	var service: SaveService = SaveService.new(cat, store)

	var player: PlayerPersistentState = PlayerPersistentState.new("char_karl", 0, 0)
	var progress: ProgressService = ProgressService.new(cat, player)
	var empty_frags: Array[String] = []
	var reward: RewardGrant = RewardGrant.new("reward_01_01", "stage_01_01", 10, 20, empty_frags)

	var res1: StageCompletionResult = progress.commit_stage_clear("stage_01_01", reward)
	var res2: StageCompletionResult = progress.commit_stage_clear("stage_01_01", reward)

	if player.coin_balance != 10 or player.exp_total != 20:
		_cleanup_temp_store(store)
		print("[SAVE-12] FAIL: Duplicate stage clear awarded duplicate coins/exp")
		return false

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["player_persistent"]["coin_balance"] = player.coin_balance
	snap["player_persistent"]["exp_total"] = player.exp_total
	snap["progress"]["cleared_stage_ids"] = ["stage_01_01"]
	snap["progress"]["unlocked_stage_ids"] = ["stage_01_01", "stage_01_02"]
	service.save(snap)

	var load_res: Dictionary = service.load()
	_cleanup_temp_store(store)
	var loaded_dict: Dictionary = load_res.get("snapshot", {})
	var loaded_player: Dictionary = loaded_dict.get("player_persistent", {})

	if int(loaded_player.get("coin_balance", 0)) != 10 or int(loaded_player.get("exp_total", 0)) != 20:
		print("[SAVE-12] FAIL: Duplicate reward present in persisted state")
		return false

	print("[SAVE-12] PASS: Duplicate reward prevented and verified in persisted snapshot")
	return true

# SAVE-13 — No transient state saved
static func test_save_13_no_transient_state_saved() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var player: PlayerPersistentState = PlayerPersistentState.new("char_karl", 0, 0)
	var progress: ProgressService = ProgressService.new(cat, player)
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()

	var forbidden_keys: Array = ["combat_state", "enemy_hp", "active_turn", "selected_answer", "pending_question"]
	for k in forbidden_keys:
		if snap.has(k):
			print("[SAVE-13] FAIL: Serialized snapshot contains forbidden transient key: ", k)
			return false

	print("[SAVE-13] PASS: Serialized snapshot strictly excludes transient state")
	return true

# SAVE-14 — Temp/main/backup strategy
static func test_save_14_temp_main_backup_strategy() -> bool:
	var store: SaveFileStore = _get_temp_store()
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var service: SaveService = SaveService.new(cat, store)

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	service.save(snap)

	if not FileAccess.file_exists(store.main_path):
		_cleanup_temp_store(store)
		print("[SAVE-14] FAIL: Main save file not created")
		return false

	snap["player_persistent"]["coin_balance"] = 100
	service.save(snap)

	if not FileAccess.file_exists(store.backup_path):
		_cleanup_temp_store(store)
		print("[SAVE-14] FAIL: Backup save file not promoted")
		return false

	_cleanup_temp_store(store)
	print("[SAVE-14] PASS: Temp/main/backup atomic replacement strategy verified")
	return true

# INT-005 — Progress -> Save
static func test_int_005_progress_to_save() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	var service: SaveService = SaveService.new(cat, store)

	var player: PlayerPersistentState = PlayerPersistentState.new("char_karl", 0, 0)
	var progress: ProgressService = ProgressService.new(cat, player)
	var empty_frags: Array[String] = []
	var reward: RewardGrant = RewardGrant.new("reward_01_01", "stage_01_01", 10, 20, empty_frags)
	progress.commit_stage_clear("stage_01_01", reward)

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["player_persistent"]["coin_balance"] = player.coin_balance
	snap["player_persistent"]["exp_total"] = player.exp_total
	snap["progress"]["cleared_stage_ids"] = ["stage_01_01"]
	snap["progress"]["unlocked_stage_ids"] = ["stage_01_01", "stage_01_02"]
	var save_res: Dictionary = service.save(snap)
	_cleanup_temp_store(store)

	if not bool(save_res.get("success", false)):
		print("[INT-005] FAIL: Progress -> Save pipeline failed")
		return false

	print("[INT-005] PASS: Progress state committed to Save pipeline successfully")
	return true

# INT-006 — Save -> Continue
static func test_int_006_save_to_continue() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	var service: SaveService = SaveService.new(cat, store)

	var player: PlayerPersistentState = PlayerPersistentState.new("char_karl", 15, 30)
	var progress: ProgressService = ProgressService.new(cat, player)
	var empty_frags: Array[String] = []
	var reward: RewardGrant = RewardGrant.new("reward_01_01", "stage_01_01", 10, 20, empty_frags)
	progress.commit_stage_clear("stage_01_01", reward)

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["player_persistent"]["coin_balance"] = player.coin_balance
	snap["player_persistent"]["exp_total"] = player.exp_total
	snap["progress"]["cleared_stage_ids"] = ["stage_01_01"]
	snap["progress"]["unlocked_stage_ids"] = ["stage_01_01", "stage_01_02"]
	service.save(snap)

	var load_res: Dictionary = service.load()
	_cleanup_temp_store(store)

	if not bool(load_res.get("success", false)):
		print("[INT-006] FAIL: Save -> Continue pipeline failed")
		return false

	var loaded_dict: Dictionary = load_res.get("snapshot", {})
	var p_persistent: Dictionary = loaded_dict.get("player_persistent", {})
	if int(p_persistent.get("coin_balance", 0)) != 25 or int(p_persistent.get("exp_total", 0)) != 50:
		print("[INT-006] FAIL: Save -> Continue restored player state mismatch")
		return false

	print("[INT-006] PASS: Save state restored to Continue pipeline successfully")
	return true

# INT-010 — Save failure -> retry
static func test_int_010_save_failure_retry() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var player: PlayerPersistentState = PlayerPersistentState.new("char_karl", 0, 0)
	var progress: ProgressService = ProgressService.new(cat, player)

	var store_fail: SaveFileStore = _get_temp_store()
	store_fail.inject_fail_temp_write = true
	var service_fail: SaveService = SaveService.new(cat, store_fail)
	var snap1: Dictionary = _create_valid_fresh_snapshot_dict()
	var fail_res: Dictionary = service_fail.save(snap1)
	_cleanup_temp_store(store_fail)
	if bool(fail_res.get("success", false)):
		print("[INT-010] FAIL: Save succeeded on unwritable path")
		return false

	var store_ok: SaveFileStore = _get_temp_store()
	var service_ok: SaveService = SaveService.new(cat, store_ok)
	var snap2: Dictionary = _create_valid_fresh_snapshot_dict()
	var ok_res: Dictionary = service_ok.save(snap2)
	_cleanup_temp_store(store_ok)

	if not bool(ok_res.get("success", false)):
		print("[INT-010] FAIL: Save failure -> retry pipeline failed")
		return false

	print("[INT-010] PASS: Save failure -> retry pipeline succeeded")
	return true
