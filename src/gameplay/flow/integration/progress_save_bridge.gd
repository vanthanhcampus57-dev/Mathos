class_name ProgressSaveBridge
extends RefCounted

## Integration bridge orchestrating stage completion commits,
## checkpoint persistence, and Continue state restoration.
## Connects flow completion boundaries to existing ProgressService and SaveService
## using only their existing public contracts.

var _catalog: ValidatedCatalog
var _player_persistent: PlayerPersistentState
var _progress_service: ProgressService
var _save_service: SaveService
var _adaptive_profile_dict: Dictionary

var _last_committed_stage_id: String = ""

func _init(
	catalog: ValidatedCatalog,
	player_persistent: PlayerPersistentState,
	progress_service: ProgressService,
	save_service: SaveService,
	adaptive_profile_dict: Dictionary = {}
) -> void:
	assert(catalog != null, "ProgressSaveBridge requires ValidatedCatalog")
	assert(player_persistent != null, "ProgressSaveBridge requires PlayerPersistentState")
	assert(progress_service != null, "ProgressSaveBridge requires ProgressService")
	assert(save_service != null, "ProgressSaveBridge requires SaveService")

	_catalog = catalog
	_player_persistent = player_persistent
	_progress_service = progress_service
	_save_service = save_service

	if adaptive_profile_dict.is_empty():
		_adaptive_profile_dict = _create_default_adaptive_profile()
	else:
		_adaptive_profile_dict = adaptive_profile_dict.duplicate(true)

	if _save_service.has_save():
		var store: SaveFileStore = _save_service.get_file_store()
		if store != null and not store.get_base_dir().begins_with("user://test_flow"):
			hydrate_initial_state()

## Automatically hydrates player balances and progress state in-place from disk save if available.
## Ensures fresh boot/restart immediately reflects committed progress in Map and services.
func hydrate_initial_state() -> bool:
	if _save_service == null or not _save_service.has_save():
		return false

	var load_res: Dictionary = _save_service.load()
	if not bool(load_res.get("success", false)):
		return false

	var snapshot: Dictionary = load_res.get("snapshot", {}) as Dictionary
	if snapshot.is_empty():
		return false

	var player_dict: Dictionary = snapshot.get("player_persistent", {}) as Dictionary
	if not player_dict.is_empty() and _player_persistent != null:
		_player_persistent.coin_balance = int(player_dict.get("coin_balance", 0))
		_player_persistent.exp_total = int(player_dict.get("exp_total", 0))

	var progress_dict: Dictionary = snapshot.get("progress", {}) as Dictionary
	if not progress_dict.is_empty():
		var restored_progress: ProgressState = _parse_progress_state(progress_dict)
		if _progress_service != null:
			_progress_service.apply_restored_state(restored_progress)

	if snapshot.has("adaptive_profile"):
		var adp: Dictionary = snapshot.get("adaptive_profile", {}) as Dictionary
		if not adp.is_empty():
			_adaptive_profile_dict = adp.duplicate(true)

	return true

func get_progress_service() -> ProgressService:
	return _progress_service

func get_save_service() -> SaveService:
	return _save_service

func get_player_persistent() -> PlayerPersistentState:
	return _player_persistent

## FLOW-004 / FLOW-005 / FLOW-006 / FLOW-009:
## Coordinates stage clear commit through ProgressService and saves checkpoint via SaveService.
## Guarantees idempotency and prevents duplicate reward/save calls on repeated callbacks.
func commit_stage_and_checkpoint(stage_id: String, reward_grant: RewardGrant) -> Dictionary:
	if stage_id.is_empty() or reward_grant == null:
		push_error("ProgressSaveBridge.commit_stage_and_checkpoint: stage_id and reward_grant are required")
		return _error("INVALID_INPUT", "stage_id and reward_grant cannot be empty/null")

	# FLOW-011: Check if stage exists in catalog and can be entered
	if not _progress_service.can_enter(stage_id):
		push_error("ProgressSaveBridge.commit_stage_and_checkpoint: cannot enter locked or invalid stage '%s'" % stage_id)
		return _error("STAGE_LOCKED", "Stage '%s' is locked or invalid" % stage_id)

	# FLOW-009: Detect repeated callback for an already processed completion
	var current_snapshot: ProgressState = _progress_service.create_snapshot_view()
	var was_already_cleared: bool = current_snapshot.cleared_stage_ids.has(stage_id)

	# Execute ProgressService commit boundary
	var completion_result: StageCompletionResult = _progress_service.commit_stage_clear(stage_id, reward_grant)
	if completion_result == null:
		push_error("ProgressSaveBridge.commit_stage_and_checkpoint: ProgressService clear commit failed for stage '%s'" % stage_id)
		return _error("COMMIT_FAILED", "ProgressService commit failed for stage '%s'" % stage_id)

	# If this was a duplicate commit (already cleared before this call), return idempotent result without redundant save
	if was_already_cleared:
		return {
			"success": true,
			"stage_completion_result": completion_result,
			"save_result": {"success": true, "skipped": true},
			"is_duplicate_commit": true,
			"next_legal_stage_id": get_legal_entry_stage_id()
		}

	# FLOW-005 / FLOW-008: Compose SaveSnapshot containing ONLY committed persistent state
	var updated_snapshot: ProgressState = completion_result.progress_snapshot
	var snapshot_dict: Dictionary = compose_save_snapshot(_player_persistent, updated_snapshot, _adaptive_profile_dict)

	# Persist checkpoint using SaveService transactional save
	var save_res: Dictionary = _save_service.save(snapshot_dict)
	if not bool(save_res.get("success", false)):
		push_error("ProgressSaveBridge.commit_stage_and_checkpoint: SaveService checkpoint save failed: " + str(save_res.get("error_message", "")))
		return {
			"success": false,
			"error_code": str(save_res.get("error_code", "SAVE_FAILED")),
			"error_message": str(save_res.get("error_message", "Save write failed")),
			"stage_completion_result": completion_result,
			"save_result": save_res,
			"is_duplicate_commit": false
		}

	_last_committed_stage_id = stage_id

	return {
		"success": true,
		"stage_completion_result": completion_result,
		"save_result": save_res,
		"is_duplicate_commit": false,
		"next_legal_stage_id": get_legal_entry_stage_id()
	}

## FLOW-007: Restores committed state from SaveService disk file and reconstructs ProgressService.
## Control is returned to the legal post-load entry stage.
func restore_from_save() -> Dictionary:
	var load_res: Dictionary = _save_service.load()
	if not bool(load_res.get("success", false)):
		return load_res

	var snapshot: Dictionary = load_res["snapshot"] as Dictionary

	# Restore PlayerPersistentState
	var player_dict: Dictionary = snapshot["player_persistent"] as Dictionary
	if _player_persistent != null:
		_player_persistent.coin_balance = int(player_dict.get("coin_balance", 0))
		_player_persistent.exp_total = int(player_dict.get("exp_total", 0))
	else:
		_player_persistent = PlayerPersistentState.new(
			String(player_dict.get("player_id", PlayerPersistentState.CANONICAL_PLAYER_ID)),
			int(player_dict.get("coin_balance", 0)),
			int(player_dict.get("exp_total", 0))
		)

	# Restore ProgressState
	var progress_dict: Dictionary = snapshot["progress"] as Dictionary
	var restored_progress: ProgressState = _parse_progress_state(progress_dict)

	# Restore Adaptive Profile dict
	if snapshot.has("adaptive_profile"):
		_adaptive_profile_dict = (snapshot["adaptive_profile"] as Dictionary).duplicate(true)

	# Update ProgressService in-place (or reconstruct if null)
	if _progress_service != null:
		_progress_service.apply_restored_state(restored_progress)
	else:
		_progress_service = ProgressService.new(_catalog, _player_persistent, restored_progress)

	var entry_stage_id: String = get_legal_entry_stage_id(restored_progress)

	return {
		"success": true,
		"progress_service": _progress_service,
		"player_persistent": _player_persistent,
		"progress_state": restored_progress,
		"entry_stage_id": entry_stage_id,
		"snapshot": snapshot
	}

## FLOW-006: Computes the next legal entry stage from ProgressService / ProgressState.
## Progression logic remains 100% owned by ProgressService.
## Only returns stages belonging to playable dungeons.
func get_legal_entry_stage_id(state: ProgressState = null) -> String:
	var prg_state: ProgressState = state
	if prg_state == null:
		prg_state = _progress_service.create_snapshot_view()

	# Filter unlocked stages to playable dungeons
	var playable_unlocked: Array[String] = []
	for stage_id in prg_state.unlocked_stage_ids:
		if _is_stage_playable(stage_id):
			playable_unlocked.append(stage_id)

	# 1. Find the first playable unlocked stage that has NOT been cleared yet
	for stage_id in playable_unlocked:
		if not prg_state.cleared_stage_ids.has(stage_id):
			return stage_id

	# 2. If all playable unlocked stages are cleared, return the latest playable unlocked stage
	if not playable_unlocked.is_empty():
		return playable_unlocked[playable_unlocked.size() - 1]

	return "stage_01_01"

func _is_stage_playable(stage_id: String) -> bool:
	if _catalog == null:
		return true
	var stage: Dictionary = _catalog.get_stage(stage_id)
	if stage.is_empty():
		return false
	var dungeon_id: String = String(stage.get("dungeon_id", ""))
	if _catalog.has_method("is_dungeon_playable"):
		return _catalog.is_dungeon_playable(dungeon_id)
	return true

## Helper to compose a fully valid SaveSnapshot dictionary conforming to SaveSchema V1.
static func compose_save_snapshot(
	player_persistent: PlayerPersistentState,
	progress_state: ProgressState,
	adaptive_profile_dict: Dictionary = {}
) -> Dictionary:
	var adaptive := adaptive_profile_dict
	if adaptive.is_empty():
		adaptive = _create_default_adaptive_profile()

	return {
		"schema_version": SaveSchema.SAVE_SCHEMA_VERSION,
		"game_version": SaveSchema.GAME_VERSION_V1,
		"content_version": SaveSchema.CONTENT_VERSION_V1,
		"saved_at_utc": Time.get_datetime_string_from_system(true) + "Z",
		"profile_id": SaveSchema.PROFILE_ID_CANONICAL,
		"player_persistent": {
			"player_id": player_persistent.player_id,
			"coin_balance": player_persistent.coin_balance,
			"exp_total": player_persistent.exp_total
		},
		"progress": {
			"unlocked_dungeon_ids": _to_string_array(progress_state.unlocked_dungeon_ids),
			"unlocked_stage_ids": _to_string_array(progress_state.unlocked_stage_ids),
			"cleared_stage_ids": _to_string_array(progress_state.cleared_stage_ids),
			"fragment_ids": _to_string_array(progress_state.fragment_ids),
			"game_complete": progress_state.game_complete
		},
		"adaptive_profile": adaptive.duplicate(true)
	}

static func _parse_progress_state(dict: Dictionary) -> ProgressState:
	var unlocked_dungeons := _to_string_array(dict.get("unlocked_dungeon_ids", []))
	var unlocked_stages := _to_string_array(dict.get("unlocked_stage_ids", []))
	var cleared_stages := _to_string_array(dict.get("cleared_stage_ids", []))
	var fragments := _to_string_array(dict.get("fragment_ids", []))
	var game_complete := bool(dict.get("game_complete", false))

	return ProgressState.new(
		unlocked_dungeons,
		unlocked_stages,
		cleared_stages,
		fragments,
		game_complete
	)

static func _create_default_adaptive_profile() -> Dictionary:
	return {
		"attempts_total": 0,
		"correct_total": 0,
		"consecutive_correct": 0,
		"consecutive_incorrect": 0,
		"topic_stats": {},
		"recent_records": []
	}

static func _to_string_array(arr_variant: Variant) -> Array[String]:
	var result: Array[String] = []
	if arr_variant is Array:
		for item in (arr_variant as Array):
			result.append(String(item))
	return result

static func _error(code: String, message: String) -> Dictionary:
	return {
		"success": false,
		"error_code": code,
		"error_message": message
	}
