class_name GameFlowService
extends RefCounted

## Authoritative GameFlow orchestrator coordinating New Game entry, stage sequence
## transitions, continue save flow restoration, and StageOrchestrator delegation.
## Note: SaveService load/save and Progress restoration are owned by A.2 integration bridge.
## GameFlowService consumes restored state and transitions flow state only.

var _catalog: ValidatedCatalog
var _question_service: QuestionService
var _progress_service: ProgressService
var _save_service: SaveService
var _player_persistent: PlayerPersistentState
var _orchestrator: StageOrchestrator

var _flow_state: String = "IDLE"
var _current_stage_id: String = ""

func _init(
	catalog: ValidatedCatalog,
	question_service: QuestionService,
	progress_service: ProgressService,
	save_service: SaveService = null,
	player_persistent: PlayerPersistentState = null
) -> void:
	assert(catalog != null, "GameFlowService requires ValidatedCatalog")
	assert(question_service != null, "GameFlowService requires QuestionService")
	assert(progress_service != null, "GameFlowService requires ProgressService")
	_catalog = catalog
	_question_service = question_service
	_progress_service = progress_service
	_save_service = save_service
	_player_persistent = player_persistent

	_orchestrator = StageOrchestrator.new(_catalog, _question_service, _progress_service)
	_flow_state = "STARTUP"

func start_new_game() -> Dictionary:
	var config: Dictionary = _catalog.get_config()
	var initial_stage_id: String = String(config.get("initial_stage_id", "stage_01_01"))

	var init_res: Dictionary = start_stage(initial_stage_id)
	if not bool(init_res.get("success", false)):
		_flow_state = "IDLE"
		return init_res

	_flow_state = "NEW_GAME"
	return {
		"success": true,
		"flow_state": _flow_state,
		"stage_id": initial_stage_id,
		"orchestrator_result": init_res
	}

func start_stage(stage_id: String) -> Dictionary:
	if stage_id.is_empty():
		return _error(FlowErrorCodes.INVALID_STAGE_ID, "Stage ID cannot be empty")

	var init_res: Dictionary = _orchestrator.initialize_stage(stage_id)
	if not bool(init_res.get("success", false)):
		return init_res

	_current_stage_id = stage_id
	_flow_state = "STAGE_ACTIVE"
	return init_res

## Consumes an authoritative A.2 restore bridge result to initialize the active flow stage.
## Requires a valid non-empty String 'entry_stage_id'. Zero fallbacks permitted.
## Does NOT read raw save progress arrays or execute SaveService.load / ProgressService restoration.
func restore_from_save(restore_result: Dictionary) -> Dictionary:
	if restore_result.is_empty():
		return _error(FlowErrorCodes.SAVE_RESTORE_FAILED, "Restore result dictionary cannot be empty")

	if not restore_result.has("entry_stage_id"):
		return _error(FlowErrorCodes.SAVE_RESTORE_FAILED, "Restore result missing required 'entry_stage_id'")

	var entry_stage_val: Variant = restore_result["entry_stage_id"]
	if not (entry_stage_val is String) or String(entry_stage_val).strip_edges().is_empty():
		return _error(FlowErrorCodes.SAVE_RESTORE_FAILED, "Restore result 'entry_stage_id' must be a non-empty String")

	var entry_stage_id: String = String(entry_stage_val).strip_edges()

	if _catalog.get_stage(entry_stage_id).is_empty():
		return _error(FlowErrorCodes.INVALID_STAGE_ID, "Unknown stage_id '%s' in ValidatedCatalog" % entry_stage_id)

	if not _progress_service.can_enter(entry_stage_id):
		return _error(FlowErrorCodes.STAGE_LOCKED, "Stage '%s' is locked by ProgressService" % entry_stage_id)

	var init_res: Dictionary = start_stage(entry_stage_id)
	if not bool(init_res.get("success", false)):
		return init_res

	_flow_state = "CONTINUE_RESTORE"

	var context: Dictionary = get_stage_context(true)

	return {
		"success": true,
		"flow_state": _flow_state,
		"target_stage_id": entry_stage_id,
		"stage_context": context,
		"orchestrator_result": init_res
	}

func advance_to_next_stage() -> Dictionary:
	if _current_stage_id.is_empty():
		return _error(FlowErrorCodes.INVALID_STAGE_ID, "No active stage to advance from")

	var newly_unlocked: Array[String] = _progress_service.unlock_next()
	var target_stage_id: String = ""

	if not newly_unlocked.is_empty():
		target_stage_id = newly_unlocked[0]
	else:
		target_stage_id = _find_next_sequential_stage(_current_stage_id)

	if target_stage_id.is_empty():
		_flow_state = "GAME_COMPLETE"
		return {
			"success": true,
			"game_completed": true,
			"flow_state": "GAME_COMPLETE",
			"last_stage_id": _current_stage_id
		}

	if not _progress_service.can_enter(target_stage_id):
		return _error(FlowErrorCodes.STAGE_LOCKED, "Next stage is locked or unavailable")

	return start_stage(target_stage_id)

func is_game_completed() -> bool:
	return _flow_state == "GAME_COMPLETE"

func get_stage_context(is_restored: bool = false) -> Dictionary:
	return _orchestrator.create_stage_context(is_restored)

func get_flow_state() -> String:
	return _flow_state

func get_current_stage_id() -> String:
	return _current_stage_id

func get_orchestrator() -> StageOrchestrator:
	return _orchestrator

func get_catalog() -> ValidatedCatalog:
	return _catalog

func get_question_service() -> QuestionService:
	return _question_service

func get_progress_service() -> ProgressService:
	return _progress_service

func get_save_service() -> SaveService:
	return _save_service

func _find_next_sequential_stage(current_stage_id: String) -> String:
	var parts: PackedStringArray = current_stage_id.split("_")
	if parts.size() != 3 or parts[0] != "stage":
		return ""

	var d_num: int = int(parts[1])
	var s_num: int = int(parts[2])

	var next_s: int = s_num + 1
	var next_d: int = d_num
	if next_s > 5:
		next_s = 1
		next_d += 1

	if next_d > 4:
		return ""

	var candidate: String = "stage_%02d_%02d" % [next_d, next_s]
	if _catalog.get_stage(candidate).is_empty():
		return ""

	return candidate

func _error(code: String, message: String) -> Dictionary:
	return {
		"success": false,
		"error_code": code,
		"error_message": message
	}
