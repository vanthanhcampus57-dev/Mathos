class_name TestSaveContract
extends RefCounted

## Unit test suite for Save Contract, Codec, Versioning, and Structural/Semantic Validation.

static func run_all_tests() -> bool:
	print("--- RUNNING SAVE CONTRACT SUITE ---")
	var all_ok: bool = true
	all_ok = test_valid_schema_v1() and all_ok
	all_ok = test_game_version_metadata_rule() and all_ok
	all_ok = test_version_classification() and all_ok
	all_ok = test_unknown_top_level_field_rejected() and all_ok
	all_ok = test_missing_required_field_rejected() and all_ok
	all_ok = test_malformed_json_codec() and all_ok
	all_ok = test_player_persistent_validation() and all_ok
	all_ok = test_progress_id_uniqueness_and_validation() and all_ok
	all_ok = test_progress_sequential_validation() and all_ok
	all_ok = test_progress_fragment_unlock_dependencies() and all_ok
	all_ok = test_progress_game_complete_constraints() and all_ok
	all_ok = test_adaptive_profile_validation() and all_ok
	all_ok = test_adaptive_topic_stats_key_restrictions() and all_ok
	all_ok = test_config_driven_recent_record_limit() and all_ok
	all_ok = test_performance_record_field_checks() and all_ok
	all_ok = test_performance_record_reference_checks() and all_ok
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

static func _synthetic_catalog() -> ValidatedCatalog:
	var config: Dictionary = {"adaptive_recent_record_limit": 100}
	var dungeons: Dictionary = {"dungeon_01": {"dungeon_id": "dungeon_01", "topic_id": "trial_sample_event"}}
	var stages: Dictionary = {
		"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01"},
		"stage_01_02": {"stage_id": "stage_01_02", "dungeon_id": "dungeon_01"}
	}
	var questions: Dictionary = {
		"q_001": {
			"question_id": "q_001",
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"subtopic_id": "sample_space"
		}
	}
	return ValidatedCatalog.new(config, dungeons, stages, {}, {}, {}, questions, {}, {}, {})

static func test_valid_schema_v1() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if not bool(res.get("success", false)):
		print("[SAVE-CONTRACT-001] FAIL: Valid schema v1 snapshot failed validation: ", res.get("error_message"))
		return false
	print("[SAVE-CONTRACT-001] PASS")
	return true

static func test_game_version_metadata_rule() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["game_version"] = "1.2.0"
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if not bool(res.get("success", false)):
		print("[SAVE-CONTRACT-002] FAIL: Differing game_version ('1.2.0') was improperly rejected")
		return false
	print("[SAVE-CONTRACT-002] PASS")
	return true

static func test_version_classification() -> bool:
	var snap_v1: Dictionary = _valid_snapshot_dict()
	var res_v1: Dictionary = SaveSnapshotValidator.validate_snapshot(snap_v1)
	if not bool(res_v1.get("success", false)):
		print("[SAVE-CONTRACT-003] FAIL: schema_version 1 failed")
		return false

	var snap_v2: Dictionary = _valid_snapshot_dict()
	snap_v2["schema_version"] = 2
	var res_v2: Dictionary = SaveSnapshotValidator.validate_snapshot(snap_v2)
	if bool(res_v2.get("success", false)) or String(res_v2.get("error_code", "")) != SaveErrorCodes.UNSUPPORTED_SAVE_VERSION:
		print("[SAVE-CONTRACT-003] FAIL: schema_version 2 was not classified as UnsupportedSaveVersionError")
		return false

	var snap_v0: Dictionary = _valid_snapshot_dict()
	snap_v0["schema_version"] = 0
	var res_v0: Dictionary = SaveSnapshotValidator.validate_snapshot(snap_v0)
	if bool(res_v0.get("success", false)) or String(res_v0.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-003] FAIL: schema_version 0 was not classified as CorruptSaveError")
		return false

	var snap_missing: Dictionary = _valid_snapshot_dict()
	snap_missing.erase("schema_version")
	var res_missing: Dictionary = SaveSnapshotValidator.validate_snapshot(snap_missing)
	if bool(res_missing.get("success", false)) or String(res_missing.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-003] FAIL: Missing schema_version was not classified as CorruptSaveError")
		return false

	var snap_wrong_type: Dictionary = _valid_snapshot_dict()
	snap_wrong_type["schema_version"] = "1"
	var res_wrong_type: Dictionary = SaveSnapshotValidator.validate_snapshot(snap_wrong_type)
	if bool(res_wrong_type.get("success", false)) or String(res_wrong_type.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-003] FAIL: String schema_version was not classified as CorruptSaveError")
		return false

	print("[SAVE-CONTRACT-003] PASS")
	return true

static func test_unknown_top_level_field_rejected() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["settings"] = {"volume": 1.0}
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-004] FAIL: Unknown top-level field was not rejected with CorruptSaveError")
		return false
	print("[SAVE-CONTRACT-004] PASS")
	return true

static func test_missing_required_field_rejected() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap.erase("player_persistent")
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-005] FAIL: Missing required field was not rejected with CorruptSaveError")
		return false
	print("[SAVE-CONTRACT-005] PASS")
	return true

static func test_malformed_json_codec() -> bool:
	var malformed_str: String = "{ invalid json string }"
	var res: Dictionary = SaveSnapshotCodec.deserialize(malformed_str)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-006] FAIL: Malformed JSON was not rejected by Codec with CorruptSaveError")
		return false
	print("[SAVE-CONTRACT-006] PASS")
	return true

static func test_player_persistent_validation() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["player_persistent"]["coin_balance"] = -50
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-007] FAIL: Negative coin_balance was not rejected")
		return false

	var snap2: Dictionary = _valid_snapshot_dict()
	snap2["player_persistent"]["player_id"] = "wrong_char"
	var res2: Dictionary = SaveSnapshotValidator.validate_snapshot(snap2)
	if bool(res2.get("success", false)) or String(res2.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-007] FAIL: Invalid player_id was not rejected")
		return false

	print("[SAVE-CONTRACT-007] PASS")
	return true

static func test_progress_id_uniqueness_and_validation() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	(snap["progress"]["unlocked_stage_ids"] as Array).append("stage_01_01")
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-008] FAIL: Duplicate stage ID in unlocked_stage_ids was not rejected")
		return false
	print("[SAVE-CONTRACT-008] PASS")
	return true

static func test_progress_sequential_validation() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["progress"]["unlocked_stage_ids"] = ["stage_01_01", "stage_01_03"]
	snap["progress"]["cleared_stage_ids"] = []
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-009] FAIL: Non-sequential stage unlock without clearing previous stage was not rejected")
		return false
	print("[SAVE-CONTRACT-009] PASS")
	return true

static func test_progress_fragment_unlock_dependencies() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	(snap["progress"]["fragment_ids"] as Array).append("fragment_01")
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-010] FAIL: fragment_01 without stage_01_05 clear was not rejected")
		return false

	var snap2: Dictionary = _valid_snapshot_dict()
	(snap2["progress"]["unlocked_dungeon_ids"] as Array).append("dungeon_02")
	var res2: Dictionary = SaveSnapshotValidator.validate_snapshot(snap2)
	if bool(res2.get("success", false)) or String(res2.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-010] FAIL: dungeon_02 unlock without stage_01_05 clear and fragment_01 was not rejected")
		return false

	print("[SAVE-CONTRACT-010] PASS")
	return true

static func test_progress_game_complete_constraints() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["progress"]["game_complete"] = true
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-011] FAIL: game_complete=true with only 1 cleared stage was not rejected")
		return false
	print("[SAVE-CONTRACT-011] PASS")
	return true

static func test_adaptive_profile_validation() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	snap["adaptive_profile"]["correct_total"] = 20
	snap["adaptive_profile"]["attempts_total"] = 10
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-012] FAIL: correct_total > attempts_total was not rejected")
		return false
	print("[SAVE-CONTRACT-012] PASS")
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
		print("[SAVE-CONTRACT-013] FAIL: Invalid topic_stats key was not rejected")
		return false
	print("[SAVE-CONTRACT-013] PASS")
	return true

static func test_config_driven_recent_record_limit() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	var recs: Array = []
	for i in range(3):
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

	# With custom limit = 3, 3 records are accepted
	var res_pass: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, null, {"adaptive_recent_record_limit": 3})
	if not bool(res_pass.get("success", false)):
		print("[SAVE-CONTRACT-014] FAIL: Custom limit=3 rejected 3 records: ", res_pass.get("error_message"))
		return false

	# With custom limit = 2, 3 records are rejected
	var res_fail: Dictionary = SaveSnapshotValidator.validate_snapshot(snap, null, {"adaptive_recent_record_limit": 2})
	if bool(res_fail.get("success", false)) or String(res_fail.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-014] FAIL: Custom limit=2 did not reject 3 records")
		return false

	print("[SAVE-CONTRACT-014] PASS")
	return true

static func test_performance_record_field_checks() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	var rec: Dictionary = (snap["adaptive_profile"]["recent_records"] as Array)[0] as Dictionary
	rec["topic_id"] = "classical_probability" # Mismatch with dungeon_01 (topic: trial_sample_event)
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-015] FAIL: PerformanceRecord topic mismatch with dungeon was not rejected")
		return false
	print("[SAVE-CONTRACT-015] PASS")
	return true

static func test_performance_record_reference_checks() -> bool:
	var catalog: ValidatedCatalog = _synthetic_catalog()

	# Unknown question_id
	var snap_unk_q: Dictionary = _valid_snapshot_dict()
	((snap_unk_q["adaptive_profile"]["recent_records"] as Array)[0] as Dictionary)["question_id"] = "unknown_q"
	var res_unk_q: Dictionary = SaveSnapshotValidator.validate_snapshot(snap_unk_q, catalog)
	if bool(res_unk_q.get("success", false)) or String(res_unk_q.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-016] FAIL: Unknown question_id was not rejected against catalog")
		return false

	# Incompatible subtopic_id reference (q_001 has subtopic_id 'sample_space')
	var snap_incomp_sub: Dictionary = _valid_snapshot_dict()
	((snap_incomp_sub["adaptive_profile"]["recent_records"] as Array)[0] as Dictionary)["subtopic_id"] = "event_subset"
	var res_incomp_sub: Dictionary = SaveSnapshotValidator.validate_snapshot(snap_incomp_sub, catalog)
	if bool(res_incomp_sub.get("success", false)) or String(res_incomp_sub.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-016] FAIL: Incompatible subtopic_id reference was not rejected")
		return false

	print("[SAVE-CONTRACT-016] PASS")
	return true

static func test_transient_field_rejection() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	(snap["player_persistent"] as Dictionary)["current_hp"] = 100
	var res: Dictionary = SaveSnapshotValidator.validate_snapshot(snap)
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != SaveErrorCodes.CORRUPT_SAVE:
		print("[SAVE-CONTRACT-017] FAIL: Transient player field current_hp was not rejected")
		return false
	print("[SAVE-CONTRACT-017] PASS")
	return true

static func test_codec_serialization_deserialization() -> bool:
	var snap: Dictionary = _valid_snapshot_dict()
	var json_str: String = SaveSnapshotCodec.serialize(snap)
	var res: Dictionary = SaveSnapshotCodec.deserialize(json_str)
	if not bool(res.get("success", false)):
		print("[SAVE-CONTRACT-018] FAIL: Codec deserialize failed: ", res.get("error_message"))
		return false

	var restored: Dictionary = res["snapshot"] as Dictionary
	var val_res: Dictionary = SaveSnapshotValidator.validate_snapshot(restored)
	if not bool(val_res.get("success", false)):
		print("[SAVE-CONTRACT-018] FAIL: Deserialized snapshot failed validation: ", val_res.get("error_message"))
		return false

	print("[SAVE-CONTRACT-018] PASS")
	return true
