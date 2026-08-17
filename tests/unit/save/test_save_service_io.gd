class_name TestSaveServiceIO
extends RefCounted

## Unit test suite for SaveService I/O operations, transactional commits,
## backup preservation, corrupt diagnostics, and recovery flows.

static func run_all_tests() -> bool:
	print("--- RUNNING SAVE SERVICE IO SUITE ---")
	var all_ok: bool = true
	all_ok = test_successful_write_clean_location() and all_ok
	all_ok = test_temp_readback_before_main_replacement() and all_ok
	all_ok = test_valid_existing_main_preserved_as_backup() and all_ok
	all_ok = test_invalid_existing_main_not_promoted_as_backup() and all_ok
	all_ok = test_failed_temp_write() and all_ok
	all_ok = test_failed_temp_readback_validation() and all_ok
	all_ok = test_backup_failure_behavior() and all_ok
	all_ok = test_replacement_failure_behavior() and all_ok
	all_ok = test_final_main_readback_failure_behavior() and all_ok
	all_ok = test_valid_main_load() and all_ok
	all_ok = test_corrupt_main_load_classification() and all_ok
	all_ok = test_unsupported_version_propagated_from_b1() and all_ok
	all_ok = test_missing_main() and all_ok
	all_ok = test_valid_backup_discovery_path() and all_ok
	all_ok = test_invalid_main_and_invalid_backup() and all_ok
	all_ok = test_save_retry_io_only() and all_ok
	all_ok = test_has_save_valid_vs_corrupt_distinction() and all_ok
	all_ok = test_no_writes_to_res_or_project_source() and all_ok

	# Dedicated Backup Recovery Contract Gate Tests (SAVE-IO-RECOVERY-001..005)
	all_ok = test_save_io_recovery_001() and all_ok
	all_ok = test_save_io_recovery_002() and all_ok
	all_ok = test_save_io_recovery_003() and all_ok
	all_ok = test_save_io_recovery_004() and all_ok
	all_ok = test_save_io_recovery_005() and all_ok
	return all_ok

static func _make_test_store() -> SaveFileStore:
	var unique_dir: String = "user://test_io_%d_%d/" % [Time.get_ticks_msec(), randi_range(1000, 9999)]
	return SaveFileStore.new(unique_dir)

static func _valid_snapshot() -> Dictionary:
	return {
		"schema_version": 1,
		"game_version": "1.0.0",
		"content_version": 1,
		"saved_at_utc": "2026-08-17T00:00:00Z",
		"profile_id": "local_player",
		"player_persistent": {
			"player_id": "char_karl",
			"coin_balance": 100,
			"exp_total": 250
		},
		"progress": {
			"unlocked_dungeon_ids": ["dungeon_01"],
			"unlocked_stage_ids": ["stage_01_01", "stage_01_02"],
			"cleared_stage_ids": ["stage_01_01"],
			"fragment_ids": [],
			"game_complete": false
		},
		"adaptive_profile": {
			"attempts_total": 10,
			"correct_total": 8,
			"consecutive_correct": 2,
			"consecutive_incorrect": 0,
			"topic_stats": {
				"trial_sample_event": {
					"attempts": 10,
					"correct": 8,
					"average_time_seconds": 15.0,
					"last_difficulty": 3
				}
			},
			"recent_records": [
				{
					"attempt_id": "att_101",
					"question_id": "q_001",
					"dungeon_id": "dungeon_01",
					"topic_id": "trial_sample_event",
					"subtopic_id": "sample_space",
					"context": "practice",
					"difficulty": 2,
					"is_correct": true,
					"elapsed_seconds": 12.0
				}
			]
		}
	}

static func test_successful_write_clean_location() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var snap: Dictionary = _valid_snapshot()
	var res: Dictionary = service.save(snap)
	if not bool(res.get("success", false)):
		return _fail("SAVE-IO-001", "Successful write to clean location failed")
	if not store.file_exists(store.main_path):
		return _fail("SAVE-IO-001", "Main file missing after save")
	if store.file_exists(store.temp_path):
		return _fail("SAVE-IO-001", "Temp file was not cleaned up after save")
	print("[SAVE-IO-001] PASS")
	return true

static func test_temp_readback_before_main_replacement() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var snap: Dictionary = _valid_snapshot()
	store.inject_fail_temp_read = true
	var res: Dictionary = service.save(snap)
	if bool(res.get("success", false)):
		return _fail("SAVE-IO-002", "Save claimed success despite temp readback failure")
	if store.file_exists(store.main_path):
		return _fail("SAVE-IO-002", "Main file was created despite temp readback failure")
	print("[SAVE-IO-002] PASS")
	return true

static func test_valid_existing_main_preserved_as_backup() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var snap1: Dictionary = _valid_snapshot()
	snap1["player_persistent"]["coin_balance"] = 100
	service.save(snap1)

	var snap2: Dictionary = _valid_snapshot()
	snap2["player_persistent"]["coin_balance"] = 200
	service.save(snap2)

	if not store.file_exists(store.backup_path):
		return _fail("SAVE-IO-003", "Backup file was not created for previous valid main")

	var bak_read: Dictionary = store.read_text(store.backup_path)
	var bak_codec: Dictionary = SaveSnapshotCodec.deserialize(str(bak_read.get("content", "")))
	var bak_coin: int = int((bak_codec["snapshot"]["player_persistent"] as Dictionary)["coin_balance"])
	if bak_coin != 100:
		return _fail("SAVE-IO-003", "Backup file did not preserve original coin_balance=100")
	print("[SAVE-IO-003] PASS")
	return true

static func test_invalid_existing_main_not_promoted_as_backup() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	store.write_text(store.main_path, "{ corrupt json }")

	var snap: Dictionary = _valid_snapshot()
	service.save(snap)

	if store.file_exists(store.backup_path):
		return _fail("SAVE-IO-004", "Corrupt main file was incorrectly promoted to backup")
	print("[SAVE-IO-004] PASS")
	return true

static func test_failed_temp_write() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	store.inject_fail_temp_write = true
	var res: Dictionary = service.save(_valid_snapshot())
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.WRITE_ERROR:
		return _fail("SAVE-IO-005", "Failed temp write did not return WriteError")
	print("[SAVE-IO-005] PASS")
	return true

static func test_failed_temp_readback_validation() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	store.inject_fail_temp_read = true
	var res: Dictionary = service.save(_valid_snapshot())
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.READ_ERROR:
		return _fail("SAVE-IO-006", "Failed temp readback did not return ReadError")
	print("[SAVE-IO-006] PASS")
	return true

static func test_backup_failure_behavior() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	service.save(_valid_snapshot())

	store.inject_fail_backup = true
	var snap2: Dictionary = _valid_snapshot()
	snap2["player_persistent"]["coin_balance"] = 500
	var res: Dictionary = service.save(snap2)

	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.WRITE_ERROR:
		return _fail("SAVE-IO-007", "Backup failure did not return WriteError")

	var load_res: Dictionary = service.load()
	var current_coin: int = int((load_res["snapshot"]["player_persistent"] as Dictionary)["coin_balance"])
	if current_coin != 100:
		return _fail("SAVE-IO-007", "Existing valid main was destroyed during backup failure")
	print("[SAVE-IO-007] PASS")
	return true

static func test_replacement_failure_behavior() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	store.inject_fail_replace = true
	var res: Dictionary = service.save(_valid_snapshot())
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.WRITE_ERROR:
		return _fail("SAVE-IO-008", "Replacement failure did not return WriteError")
	print("[SAVE-IO-008] PASS")
	return true

static func test_final_main_readback_failure_behavior() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	store.inject_fail_final_read = true
	var res: Dictionary = service.save(_valid_snapshot())
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.READ_ERROR:
		return _fail("SAVE-IO-009", "Final main readback failure did not return ReadError")
	print("[SAVE-IO-009] PASS")
	return true

static func test_valid_main_load() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var snap: Dictionary = _valid_snapshot()
	service.save(snap)

	var load_res: Dictionary = service.load()
	if not bool(load_res.get("success", false)):
		return _fail("SAVE-IO-010", "Valid main load failed")
	var loaded: Dictionary = load_res["snapshot"] as Dictionary
	if String(loaded["profile_id"]) != "local_player":
		return _fail("SAVE-IO-010", "Loaded snapshot fields do not match")
	print("[SAVE-IO-010] PASS")
	return true

static func test_corrupt_main_load_classification() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	store.write_text(store.main_path, "{ corrupt json }")

	var load_res: Dictionary = service.load()
	if bool(load_res.get("success", false)) or String(load_res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		return _fail("SAVE-IO-011", "Corrupt main load was not classified as CorruptSaveError")
	print("[SAVE-IO-011] PASS")
	return true

static func test_unsupported_version_propagated_from_b1() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var future_snap: Dictionary = _valid_snapshot()
	future_snap["schema_version"] = 99
	store.write_text(store.main_path, JSON.stringify(future_snap, "\t"))

	var load_res: Dictionary = service.load()
	if bool(load_res.get("success", false)) or String(load_res.get("error_code", "")) != SaveErrorCodes.UNSUPPORTED_SAVE_VERSION:
		return _fail("SAVE-IO-012", "Future schema version was not classified as UnsupportedSaveVersionError")
	print("[SAVE-IO-012] PASS")
	return true

static func test_missing_main() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var load_res: Dictionary = service.load()
	if bool(load_res.get("success", false)) or String(load_res.get("error_code", "")) != SaveErrorCodes.READ_ERROR:
		return _fail("SAVE-IO-013", "Missing main file did not return ReadError")
	print("[SAVE-IO-013] PASS")
	return true

static func test_valid_backup_discovery_path() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var snap: Dictionary = _valid_snapshot()
	snap["player_persistent"]["coin_balance"] = 777
	store.write_text(store.backup_path, JSON.stringify(snap, "\t"))

	var load_res: Dictionary = service.load()
	if not bool(load_res.get("success", false)):
		return _fail("SAVE-IO-014", "Load with valid backup failed")

	var coin: int = int((load_res["snapshot"]["player_persistent"] as Dictionary)["coin_balance"])
	if coin != 777:
		return _fail("SAVE-IO-014", "Recovered snapshot did not preserve coin_balance=777")
	print("[SAVE-IO-014] PASS")
	return true

static func test_invalid_main_and_invalid_backup() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	store.write_text(store.main_path, "{ corrupt main }")
	store.write_text(store.backup_path, "{ corrupt bak }")

	var load_res: Dictionary = service.load()
	if bool(load_res.get("success", false)) or String(load_res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		return _fail("SAVE-IO-015", "Invalid main + backup load did not return CorruptSaveError")
	print("[SAVE-IO-015] PASS")
	return true

static func test_save_retry_io_only() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var snap: Dictionary = _valid_snapshot()
	snap["player_persistent"]["coin_balance"] = 100

	store.inject_fail_temp_write = true
	service.save(snap)

	store.inject_fail_temp_write = false
	var res: Dictionary = service.save(snap)
	if not bool(res.get("success", false)):
		return _fail("SAVE-IO-016", "Save retry failed")

	var coin: int = int((res["snapshot"]["player_persistent"] as Dictionary)["coin_balance"])
	if coin != 100:
		return _fail("SAVE-IO-016", "Save retry mutated caller snapshot data")
	print("[SAVE-IO-016] PASS")
	return true

static func test_has_save_valid_vs_corrupt_distinction() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)

	if service.has_save():
		return _fail("SAVE-IO-017", "has_save returned true on clean location")

	store.write_text(store.main_path, "{ corrupt }")
	if service.has_save():
		return _fail("SAVE-IO-017", "has_save returned true on corrupt main")

	service.save(_valid_snapshot())
	if not service.has_save():
		return _fail("SAVE-IO-017", "has_save returned false on valid main save")
	print("[SAVE-IO-017] PASS")
	return true

static func test_no_writes_to_res_or_project_source() -> bool:
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	service.save(_valid_snapshot())

	var base_dir: String = store.get_base_dir()
	if base_dir.begins_with("res://") or base_dir.begins_with("src/") or base_dir.begins_with("content/"):
		return _fail("SAVE-IO-018", "SaveFileStore path violates user:// isolation boundary")
	print("[SAVE-IO-018] PASS")
	return true

# --- Dedicated Backup Recovery Contract Gate Tests ---

static func test_save_io_recovery_001() -> bool:
	# SAVE-IO-RECOVERY-001: invalid main + valid backup -> recovery succeeds through approved method.
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var bak_snap: Dictionary = _valid_snapshot()
	bak_snap["player_persistent"]["coin_balance"] = 999
	store.write_text(store.main_path, "{ corrupt main json }")
	store.write_text(store.backup_path, JSON.stringify(bak_snap, "\t"))

	var load_res: Dictionary = service.load()
	if not bool(load_res.get("success", false)):
		return _fail("SAVE-IO-RECOVERY-001", "Recovery load failed for invalid main + valid backup")
	if not bool(load_res.get("recovered_from_backup", false)):
		return _fail("SAVE-IO-RECOVERY-001", "recovered_from_backup flag missing")
	print("[SAVE-IO-RECOVERY-001] PASS")
	return true

static func test_save_io_recovery_002() -> bool:
	# SAVE-IO-RECOVERY-002: resulting main parses and validates.
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var bak_snap: Dictionary = _valid_snapshot()
	bak_snap["player_persistent"]["coin_balance"] = 999
	store.write_text(store.main_path, "{ corrupt main json }")
	store.write_text(store.backup_path, JSON.stringify(bak_snap, "\t"))

	service.load()

	# Verify resulting main file exists, parses, and validates independently
	if not store.file_exists(store.main_path):
		return _fail("SAVE-IO-RECOVERY-002", "Recovered main file missing")

	var main_read: Dictionary = store.read_text(store.main_path)
	var codec_res: Dictionary = SaveSnapshotCodec.deserialize(str(main_read.get("content", "")))
	if not bool(codec_res.get("success", false)):
		return _fail("SAVE-IO-RECOVERY-002", "Recovered main file failed deserialization")

	var val_res: Dictionary = service.validate_persisted_snapshot(codec_res["snapshot"] as Dictionary)
	if not bool(val_res.get("success", false)):
		return _fail("SAVE-IO-RECOVERY-002", "Recovered main file failed validation")
	var coin: int = int(((codec_res["snapshot"] as Dictionary)["player_persistent"] as Dictionary)["coin_balance"])
	if coin != 999:
		return _fail("SAVE-IO-RECOVERY-002", "Recovered main file coin_balance != 999")
	print("[SAVE-IO-RECOVERY-002] PASS")
	return true

static func test_save_io_recovery_003() -> bool:
	# SAVE-IO-RECOVERY-003: corrupt main and backup are not merged.
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var bak_snap: Dictionary = _valid_snapshot()
	bak_snap["player_persistent"]["coin_balance"] = 50
	store.write_text(store.main_path, "{\"corrupt_garbage\": 99999, \"player_persistent\": {\"coin_balance\": 99999}}")
	store.write_text(store.backup_path, JSON.stringify(bak_snap, "\t"))

	var load_res: Dictionary = service.load()
	if not bool(load_res.get("success", false)):
		return _fail("SAVE-IO-RECOVERY-003", "Load failed during non-merge recovery")

	var loaded_snap: Dictionary = load_res["snapshot"] as Dictionary
	if loaded_snap.has("corrupt_garbage"):
		return _fail("SAVE-IO-RECOVERY-003", "Corrupt main fields were merged into recovered snapshot")
	var coin: int = int((loaded_snap["player_persistent"] as Dictionary)["coin_balance"])
	if coin != 50:
		return _fail("SAVE-IO-RECOVERY-003", "Coin balance was merged/mutated")
	print("[SAVE-IO-RECOVERY-003] PASS")
	return true

static func test_save_io_recovery_004() -> bool:
	# SAVE-IO-RECOVERY-004: recovery write/final-readback failure -> explicit failure, no false success.
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	var bak_snap: Dictionary = _valid_snapshot()
	store.write_text(store.main_path, "{ corrupt main }")
	store.write_text(store.backup_path, JSON.stringify(bak_snap, "\t"))

	# Inject replacement failure during recovery write
	store.inject_fail_replace = true

	var load_res: Dictionary = service.load()
	if bool(load_res.get("success", false)):
		return _fail("SAVE-IO-RECOVERY-004", "Recovery load reported false success despite replacement failure")
	if String(load_res.get("error_code", "")) != SaveErrorCodes.WRITE_ERROR:
		return _fail("SAVE-IO-RECOVERY-004", "Recovery failure did not return WriteError")
	print("[SAVE-IO-RECOVERY-004] PASS")
	return true

static func test_save_io_recovery_005() -> bool:
	# SAVE-IO-RECOVERY-005: invalid backup -> no recovery success.
	var store: SaveFileStore = _make_test_store()
	var service: SaveService = SaveService.new(null, store)
	store.write_text(store.main_path, "{ corrupt main }")
	store.write_text(store.backup_path, "{ corrupt backup }")

	var load_res: Dictionary = service.load()
	if bool(load_res.get("success", false)):
		return _fail("SAVE-IO-RECOVERY-005", "Recovery load reported false success for invalid backup")
	if String(load_res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		return _fail("SAVE-IO-RECOVERY-005", "Invalid backup load did not return CorruptSaveError")
	print("[SAVE-IO-RECOVERY-005] PASS")
	return true

static func _fail(test_id: String, message: String) -> bool:
	print("[%s] FAIL: %s" % [test_id, message])
	return false
