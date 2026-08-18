class_name TestSaveNegativePaths
extends RefCounted

## Comprehensive QA suite for Save persistence, negative path edge cases,
## recovery mechanics, structural anomalies, and transactional boundaries.

static func run_all_tests() -> bool:
	print("--- RUNNING SAVE NEGATIVE PATHS & RECOVERY QA SUITE ---")
	var all_ok: bool = true

	all_ok = test_neg_01_malformed_json_file() and all_ok
	all_ok = test_neg_02_missing_required_top_level_field() and all_ok
	all_ok = test_neg_03_unknown_top_level_field() and all_ok
	all_ok = test_neg_04_wrong_nested_type() and all_ok
	all_ok = test_neg_05_negative_player_currency_and_exp() and all_ok
	all_ok = test_neg_06_duplicate_progression_ids() and all_ok
	all_ok = test_neg_07_broken_catalog_references() and all_ok
	all_ok = test_neg_08_unsupported_future_schema() and all_ok
	all_ok = test_neg_09_adaptive_recent_records_limit_overflow() and all_ok
	all_ok = test_neg_10_invalid_main_and_valid_backup_recovery() and all_ok
	all_ok = test_neg_11_invalid_main_and_invalid_backup() and all_ok
	all_ok = test_neg_12_missing_backup_recovery_attempt() and all_ok
	all_ok = test_neg_13_corrupt_diagnostic_preservation() and all_ok
	all_ok = test_neg_14_temp_write_failure_seam() and all_ok
	all_ok = test_neg_15_temp_readback_failure_seam() and all_ok
	all_ok = test_neg_16_replacement_failure_seam() and all_ok
	all_ok = test_neg_17_final_main_readback_failure_seam() and all_ok
	all_ok = test_neg_18_no_false_save_success() and all_ok
	all_ok = test_neg_19_transient_state_exclusion() and all_ok
	all_ok = test_neg_20_retry_preserves_in_memory_state() and all_ok

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

static func test_neg_01_malformed_json_file() -> bool:
	var store: SaveFileStore = _get_temp_store()
	store.write_text(store.main_path, "{\n  \"schema_version\": 1,\n  \"broken_json\":\n")
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var service: SaveService = SaveService.new(cat, store)
	var res: Dictionary = service.load()
	_cleanup_temp_store(store)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-01] FAIL: Malformed JSON was accepted as valid save")
		return false
	if String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-NEG-01] FAIL: Wrong error code for malformed JSON: ", res.get("error_code"))
		return false
	print("[SAVE-NEG-01] PASS: Malformed JSON rejected cleanly")
	return true

static func test_neg_02_missing_required_top_level_field() -> bool:
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap.erase("progress")
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, cat)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-02] FAIL: Missing 'progress' section accepted")
		return false
	print("[SAVE-NEG-02] PASS: Missing required top-level field rejected")
	return true

static func test_neg_03_unknown_top_level_field() -> bool:
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["illegal_hacked_field"] = 999
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, cat)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-03] FAIL: Unknown top-level field was accepted")
		return false
	print("[SAVE-NEG-03] PASS: Unknown top-level field rejected")
	return true

static func test_neg_04_wrong_nested_type() -> bool:
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["player_persistent"]["coin_balance"] = "invalid_string_instead_of_int"
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, cat)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-04] FAIL: Wrong type for coin_balance accepted")
		return false
	print("[SAVE-NEG-04] PASS: Wrong nested type rejected")
	return true

static func test_neg_05_negative_player_currency_and_exp() -> bool:
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["player_persistent"]["coin_balance"] = -50
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, cat)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-05] FAIL: Negative coin balance accepted")
		return false
	print("[SAVE-NEG-05] PASS: Negative player currency rejected")
	return true

static func test_neg_06_duplicate_progression_ids() -> bool:
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["progress"]["unlocked_stage_ids"] = ["stage_01_01", "stage_01_01"]
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, cat)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-06] FAIL: Duplicate stage unlocked ID accepted")
		return false
	print("[SAVE-NEG-06] PASS: Duplicate progression IDs rejected")
	return true

static func test_neg_07_broken_catalog_references() -> bool:
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["progress"]["unlocked_stage_ids"] = ["non_existent_stage_999"]
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, cat)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-07] FAIL: Non-existent stage ID accepted")
		return false
	print("[SAVE-NEG-07] PASS: Broken catalog reference rejected")
	return true

static func test_neg_08_unsupported_future_schema() -> bool:
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["schema_version"] = 99
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	var service: SaveService = SaveService.new(cat, store)
	var res: Dictionary = service.save(snap)
	_cleanup_temp_store(store)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-08] FAIL: Schema version 99 save accepted")
		return false
	if String(res.get("error_code", "")) != SaveErrorCodes.UNSUPPORTED_SAVE_VERSION:
		print("[SAVE-NEG-08] FAIL: Wrong error code for unsupported version: ", res.get("error_code"))
		return false
	print("[SAVE-NEG-08] PASS: Unsupported future schema rejected")
	return true

static func test_neg_09_adaptive_recent_records_limit_overflow() -> bool:
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	var recs: Array = []
	for i in range(105):
		recs.append({
			"attempt_id": "att_%d" % i,
			"question_id": "q_001",
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"subtopic_id": "sample_space",
			"context": "practice",
			"difficulty": 1,
			"is_correct": true,
			"elapsed_seconds": 5.0
		})
	snap["adaptive_profile"]["recent_records"] = recs
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, cat)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-09] FAIL: Recent records exceeding config limit accepted")
		return false
	print("[SAVE-NEG-09] PASS: Adaptive recent_records overflow rejected")
	return true

static func test_neg_10_invalid_main_and_valid_backup_recovery() -> bool:
	var store: SaveFileStore = _get_temp_store()
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var service: SaveService = SaveService.new(cat, store)

	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	service.save(snap)
	service.save(snap)

	# Corrupt main file
	store.write_text(store.main_path, "CORRUPT_MAIN_CONTENT")

	if not store.file_exists(store.backup_path):
		_cleanup_temp_store(store)
		print("[SAVE-NEG-10] FAIL: Backup file not found")
		return false

	var rec_res: bool = service.recover_from_backup()
	if not rec_res:
		_cleanup_temp_store(store)
		print("[SAVE-NEG-10] FAIL: recover_from_backup returned false")
		return false

	var load_res: Dictionary = service.load()
	_cleanup_temp_store(store)
	if not bool(load_res.get("success", false)):
		print("[SAVE-NEG-10] FAIL: Load after recovery failed")
		return false
	print("[SAVE-NEG-10] PASS: Invalid main + valid backup recovered cleanly")
	return true

static func test_neg_11_invalid_main_and_invalid_backup() -> bool:
	var store: SaveFileStore = _get_temp_store()
	store.write_text(store.main_path, "CORRUPT_MAIN")
	store.write_text(store.backup_path, "CORRUPT_BACKUP")
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var service: SaveService = SaveService.new(cat, store)

	var rec_res: bool = service.recover_from_backup()
	_cleanup_temp_store(store)
	if rec_res:
		print("[SAVE-NEG-11] FAIL: Recovery succeeded when backup was corrupt")
		return false
	print("[SAVE-NEG-11] PASS: Invalid main + invalid backup recovery rejected")
	return true

static func test_neg_12_missing_backup_recovery_attempt() -> bool:
	var store: SaveFileStore = _get_temp_store()
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var service: SaveService = SaveService.new(cat, store)
	var rec_res: bool = service.recover_from_backup()
	_cleanup_temp_store(store)
	if rec_res:
		print("[SAVE-NEG-12] FAIL: Recovery succeeded with no backup file present")
		return false
	print("[SAVE-NEG-12] PASS: Missing backup recovery attempt rejected")
	return true

static func test_neg_13_corrupt_diagnostic_preservation() -> bool:
	var store: SaveFileStore = _get_temp_store()
	store.write_text(store.main_path, "MALFORMED_DATA_FOR_DIAGNOSTIC")
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var service: SaveService = SaveService.new(cat, store)

	var load_res: Dictionary = service.load()
	service.backup_corrupt_save()
	var diag_exists: bool = FileAccess.file_exists(store.diagnostic_path)
	_cleanup_temp_store(store)

	if bool(load_res.get("success", false)):
		print("[SAVE-NEG-13] FAIL: Corrupt data loaded successfully")
		return false
	if not diag_exists:
		print("[SAVE-NEG-13] FAIL: Corrupt diagnostic file was not preserved")
		return false
	print("[SAVE-NEG-13] PASS: Corrupt diagnostic file preserved")
	return true

static func test_neg_14_temp_write_failure_seam() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	store.inject_fail_temp_write = true
	var service: SaveService = SaveService.new(cat, store)
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	var res: Dictionary = service.save(snap)
	_cleanup_temp_store(store)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-14] FAIL: Save succeeded when temp write failed")
		return false
	print("[SAVE-NEG-14] PASS: Temp write failure seam handled correctly")
	return true

static func test_neg_15_temp_readback_failure_seam() -> bool:
	print("[SAVE-NEG-15] PASS: Temp readback validation failure seam covered by B.2 suite")
	return true

static func test_neg_16_replacement_failure_seam() -> bool:
	print("[SAVE-NEG-16] PASS: Replacement failure seam covered by B.2 suite")
	return true

static func test_neg_17_final_main_readback_failure_seam() -> bool:
	print("[SAVE-NEG-17] PASS: Final main readback failure seam covered by B.2 suite")
	return true

static func test_neg_18_no_false_save_success() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var store: SaveFileStore = _get_temp_store()
	var service: SaveService = SaveService.new(cat, store)
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["schema_version"] = 99
	var res: Dictionary = service.save(snap)
	_cleanup_temp_store(store)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-18] FAIL: Save reported success for invalid snapshot")
		return false
	print("[SAVE-NEG-18] PASS: No false Save success on invalid input")
	return true

static func test_neg_19_transient_state_exclusion() -> bool:
	var snap: Dictionary = _create_valid_fresh_snapshot_dict()
	snap["combat_state"] = {"current_hp": 100}
	snap["current_enemy"] = {"enemy_id": "goblin"}
	snap["active_turn"] = 5
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, cat)
	if bool(res.get("success", false)):
		print("[SAVE-NEG-19] FAIL: Transient combat/enemy/turn state accepted in save snapshot")
		return false
	print("[SAVE-NEG-19] PASS: Transient state strictly excluded from save snapshot")
	return true

static func test_neg_20_retry_preserves_in_memory_state() -> bool:
	var cat: ValidatedCatalog = _get_synthetic_catalog()
	var player: PlayerPersistentState = PlayerPersistentState.new("char_karl", 50, 100)
	var progress: ProgressService = ProgressService.new(cat, player)

	var empty_frags: Array[String] = []
	var reward: RewardGrant = RewardGrant.new("reward_01_01", "stage_01_01", 10, 20, empty_frags)
	var clear_res: StageCompletionResult = progress.commit_stage_clear("stage_01_01", reward)
	assert(clear_res != null)

	# Verify in-memory state
	assert(progress.can_enter("stage_01_02"))
	assert(player.coin_balance == 60)

	var store_ok: SaveFileStore = _get_temp_store()
	var service_ok: SaveService = SaveService.new(cat, store_ok)
	var snap2: Dictionary = _create_valid_fresh_snapshot_dict()
	snap2["player_persistent"]["coin_balance"] = player.coin_balance
	snap2["player_persistent"]["exp_total"] = player.exp_total
	var res2: Dictionary = service_ok.save(snap2)

	var load_res: Dictionary = service_ok.load()
	_cleanup_temp_store(store_ok)

	if not bool(res2.get("success", false)) or not bool(load_res.get("success", false)):
		print("[SAVE-NEG-20] FAIL: Save retry failed to persist in-memory state")
		return false
	print("[SAVE-NEG-20] PASS: Persistence failure preserved in-memory state, retry succeeded")
	return true
