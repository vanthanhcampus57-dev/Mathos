class_name TestSaveContract
extends RefCounted

## Unit test suite for Save Contract, Codec, Versioning, and Structural/Semantic Validation.

static func run_all_tests() -> bool:
	print("--- RUNNING SAVE CONTRACT SUITE ---")
	var all_ok: bool = true
	all_ok = test_valid_schema_v1() and all_ok
	all_ok = test_unknown_top_level_field_rejected() and all_ok
	all_ok = test_missing_required_field_rejected() and all_ok
	all_ok = test_future_schema_version_rejected() and all_ok
	all_ok = test_malformed_json_codec() and all_ok
	all_ok = test_player_persistent_validation() and all_ok
	all_ok = test_progress_id_uniqueness_and_validation() and all_ok
	all_ok = test_progress_sequential_validation() and all_ok
	all_ok = test_progress_fragment_unlock_dependencies() and all_ok
	all_ok = test_progress_game_complete_constraints() and all_ok
	all_ok = test_adaptive_profile_validation() and all_ok
	all_ok = test_adaptive_topic_stats_key_restrictions() and all_ok
	all_ok = test_adaptive_recent_records_limit() and all_ok
	all_ok = test_performance_record_field_checks() and all_ok
	all_ok = test_transient_field_rejection() and all_ok
	all_ok = test_codec_serialization_deserialization() and all_ok
	return all_ok

static func _valid_snapshot_dict() -> Dictionary:
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

static func test_valid_schema_v1() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if not bool(res.get("success", false)):
		print("[SAVE-CONTRACT-001] FAIL: Valid schema v1 snapshot failed validation: ", res.get("error_message"))
		return false
	print("[SAVE-CONTRACT-001] PASS")
	return true

static func test_unknown_top_level_field_rejected() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["settings"] = {"volume": 1.0}
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-002] FAIL: Unknown top-level field was not rejected with CorruptSaveError")
		return false
	print("[SAVE-CONTRACT-002] PASS")
	return true

static func test_missing_required_field_rejected() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap.erase("player_persistent")
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-003] FAIL: Missing required field was not rejected with CorruptSaveError")
		return false
	print("[SAVE-CONTRACT-003] PASS")
	return true

static func test_future_schema_version_rejected() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["schema_version"] = 2
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.UNSUPPORTED_SAVE_VERSION:
		print("[SAVE-CONTRACT-004] FAIL: Future schema version 2 was not rejected with UnsupportedSaveVersionError")
		return false
	print("[SAVE-CONTRACT-004] PASS")
	return true

static func test_malformed_json_codec() -> bool:
	var malformed_str: String = "{ invalid json string }"
	var res: Dictionary = SaveSnapshotCodec.deserialize(malformed_str)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-005] FAIL: Malformed JSON was not rejected by Codec with CorruptSaveError")
		return false
	print("[SAVE-CONTRACT-005] PASS")
	return true

static func test_player_persistent_validation() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["player_persistent"]["coin_balance"] = -50
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-006] FAIL: Negative coin_balance was not rejected")
		return false

	var snap2: Dictionary = _valid_snapshot_dict()
	snap2["player_persistent"]["player_id"] = "wrong_char"
	var res2: Dictionary = SaveSnapshotValidator.validate_snapshot(snap2)
	if bool(res2.get("success", false)) or String(res2.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-006] FAIL: Invalid player_id was not rejected")
		return false

	print("[SAVE-CONTRACT-006] PASS")
	return true

static func test_progress_id_uniqueness_and_validation() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	(snap["progress"]["unlocked_stage_ids"] as Array).append("stage_01_01")
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-007] FAIL: Duplicate stage ID in unlocked_stage_ids was not rejected")
		return false
	print("[SAVE-CONTRACT-007] PASS")
	return true

static func test_progress_sequential_validation() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["progress"]["unlocked_stage_ids"] = ["stage_01_01", "stage_01_03"]
	snap["progress"]["cleared_stage_ids"] = []
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-008] FAIL: Non-sequential stage unlock without clearing previous stage was not rejected")
		return false
	print("[SAVE-CONTRACT-008] PASS")
	return true

static func test_progress_fragment_unlock_dependencies() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	(snap["progress"]["fragment_ids"] as Array).append("fragment_01")
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-009] FAIL: fragment_01 without stage_01_05 clear was not rejected")
		return false

	var snap2: Dictionary = _valid_snapshot_dict()
	(snap2["progress"]["unlocked_dungeon_ids"] as Array).append("dungeon_02")
	var res2: Dictionary = SaveSnapshotValidator.validate_snapshot(snap2)
	if bool(res2.get("success", false)) or String(res2.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-009] FAIL: dungeon_02 unlock without stage_01_05 clear and fragment_01 was not rejected")
		return false

	print("[SAVE-CONTRACT-009] PASS")
	return true

static func test_progress_game_complete_constraints() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["progress"]["game_complete"] = true
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-010] FAIL: game_complete=true with only 1 cleared stage was not rejected")
		return false
	print("[SAVE-CONTRACT-010] PASS")
	return true

static func test_adaptive_profile_validation() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["adaptive_profile"]["correct_total"] = 20
	snap["adaptive_profile"]["attempts_total"] = 10
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-011] FAIL: correct_total > attempts_total was not rejected")
		return false
	print("[SAVE-CONTRACT-011] PASS")
	return true

static func test_adaptive_topic_stats_key_restrictions() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	(snap["adaptive_profile"]["topic_stats"] as Dictionary)["invalid_topic"] = {
		"attempts": 1,
		"correct": 1,
		"average_time_seconds": 5.0,
		"last_difficulty": 1
	}
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-012] FAIL: Invalid topic_stats key was not rejected")
		return false
	print("[SAVE-CONTRACT-012] PASS")
	return true

static func test_adaptive_recent_records_limit() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	var recs: Array = []
	for i in range(101):
		recs.append({
			"attempt_id": "att_" + str(i),
			"question_id": "q_001",
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"subtopic_id": "sample_space",
			"context": "practice",
			"difficulty": 2,
			"is_correct": true,
			"elapsed_seconds": 10.0
		})
	snap["adaptive_profile"]["recent_records"] = recs
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-013] FAIL: recent_records exceeding limit 100 was not rejected")
		return false
	print("[SAVE-CONTRACT-013] PASS")
	return true

static func test_performance_record_field_checks() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	var rec: Dictionary = (snap["adaptive_profile"]["recent_records"] as Array)[0] as Dictionary
	rec["topic_id"] = "classical_probability" # Mismatch with dungeon_01 (topic: trial_sample_event)
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-014] FAIL: PerformanceRecord topic mismatch with dungeon was not rejected")
		return false
	print("[SAVE-CONTRACT-014] PASS")
	return true

static func test_transient_field_rejection() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	(snap["player_persistent"] as Dictionary)["current_hp"] = 100
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-015] FAIL: Transient player field current_hp was not rejected")
		return false
	print("[SAVE-CONTRACT-015] PASS")
	return true

static func test_codec_serialization_deserialization() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	var json_str: String = SaveSnapshotCodec.serialize(snap)
	var res: Dictionary = SaveSnapshotCodec.deserialize(json_str)
	if not bool(res.get("success", false)):
		print("[SAVE-CONTRACT-016] FAIL: Codec deserialize failed: ", res.get("error_message"))
		return false

	var restored: Dictionary = res["snapshot"] as Dictionary
	var val_res: Dictionary = SaveSnapshotValidator.validate_snapshot(restored)
	if not bool(val_res.get("success", false)):
		print("[SAVE-CONTRACT-016] FAIL: Deserialized snapshot failed validation: ", val_res.get("error_message"))
		return false

	print("[SAVE-CONTRACT-016] PASS")
	return true
