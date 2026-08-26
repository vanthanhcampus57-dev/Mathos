class_name AppRoot
extends Node

## Authoritative Production Composition Root for Mathos Engine.
## Bootstraps ContentCatalog, Save/Progress Services, GameFlowService,
## ProgressSaveBridge, QuestionService, and StagePresentationShell UI.

# Runtime Services
var _catalog: ValidatedCatalog = null
var _player_persistent: PlayerPersistentState = null
var _save_file_store: SaveFileStore = null
var _save_service: SaveService = null
var _progress_service: ProgressService = null
var _bridge: ProgressSaveBridge = null
var _question_service: QuestionService = null
var _game_flow_service: GameFlowService = null
var _question_controller: RefCounted = null
var _active_question_res: Dictionary = {}

# UI Presentation
var _presentation_shell: Control = null
var _bootstrap_ui: Control = null

func _ready() -> void:
	_bootstrap_ui = get_node_or_null("BootstrapUI") as Control
	bootstrap_runtime()

## Main runtime bootstrap method.
## Validates content catalog and initializes all core service instances.
func bootstrap_runtime(custom_content_root: String = "") -> bool:
	var repo: ContentRepository = ContentRepository.new()
	var root_path: String = custom_content_root
	if root_path.is_empty():
		root_path = "res://content"

	var report: ContentValidationReport = repo.load_and_validate(root_path)
	if not report.publication_allowed:
		root_path = "res://tests/fixtures/content/valid_catalog"
		report = repo.load_and_validate(root_path)

	_catalog = repo.get_catalog()
	if _catalog == null:
		push_error("AppRoot: Failed to initialize ValidatedCatalog from root '%s'" % root_path)
		return false

	_player_persistent = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	_save_file_store = SaveFileStore.new("user://")
	_save_service = SaveService.new(_catalog, _save_file_store)
	_progress_service = ProgressService.new(_catalog, _player_persistent)
	_bridge = ProgressSaveBridge.new(_catalog, _player_persistent, _progress_service, _save_service)
	_question_service = QuestionService.new(_catalog)
	_game_flow_service = GameFlowService.new(_catalog, _question_service, _progress_service, _save_service, _player_persistent)

	var q_ctrl_script: Resource = load("res://src/ui/question/question_presentation_controller.gd")
	if q_ctrl_script is GDScript:
		_question_controller = (q_ctrl_script as GDScript).new(_question_service)

	_setup_presentation_shell()
	refresh_continue_availability()
	print("[AppRoot] Runtime services and composition root initialized cleanly.")
	return true

## Starts a fresh New Game sequence from configured initial stage.
func start_new_game() -> Dictionary:
	if _game_flow_service == null:
		return {"success": false, "error_code": "NOT_INITIALIZED"}

	var flow_res: Dictionary = _game_flow_service.start_new_game()
	if not bool(flow_res.get("success", false)):
		return flow_res

	var context: Dictionary = _game_flow_service.get_stage_context(false)
	if _presentation_shell != null and _presentation_shell.has_method("set_stage_context"):
		_presentation_shell.call("set_stage_context", context)
		if _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 1) # MODE_LESSON
		if _bootstrap_ui != null:
			_bootstrap_ui.visible = false

	return {
		"success": true,
		"stage_id": _game_flow_service.get_current_stage_id(),
		"stage_context": context,
		"flow_result": flow_res
	}

## Restores committed save state via ProgressSaveBridge and initializes GameFlow stage context.
func continue_game() -> Dictionary:
	if _bridge == null:
		return {"success": false, "error_code": "NOT_INITIALIZED"}

	var restore_res: Dictionary = _bridge.restore_from_save()
	if not bool(restore_res.get("success", false)):
		return restore_res

	var restored_progress: ProgressService = restore_res.get("progress_service") as ProgressService
	var restored_player: PlayerPersistentState = restore_res.get("player_persistent") as PlayerPersistentState

	if restored_progress != null:
		_progress_service = restored_progress
	if restored_player != null:
		_player_persistent = restored_player

	_game_flow_service = GameFlowService.new(
		_catalog,
		_question_service,
		_progress_service,
		_save_service,
		_player_persistent
	)

	var flow_res: Dictionary = _game_flow_service.restore_from_save(restore_res)
	if not bool(flow_res.get("success", false)):
		return flow_res

	var context: Dictionary = _game_flow_service.get_stage_context(true)
	if _presentation_shell != null and _presentation_shell.has_method("set_stage_context"):
		_presentation_shell.call("set_stage_context", context)
		if _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 1) # MODE_LESSON
		if _bootstrap_ui != null:
			_bootstrap_ui.visible = false

	return {
		"success": true,
		"entry_stage_id": String(restore_res.get("entry_stage_id", "")),
		"stage_context": context,
		"restore_result": restore_res,
		"flow_result": flow_res
	}

# Service Accessors
func get_catalog() -> ValidatedCatalog:
	return _catalog

func get_game_flow_service() -> GameFlowService:
	return _game_flow_service

func get_progress_save_bridge() -> ProgressSaveBridge:
	return _bridge

func get_progress_service() -> ProgressService:
	return _progress_service

func get_save_service() -> SaveService:
	return _save_service

func get_question_service() -> QuestionService:
	return _question_service

func get_question_controller() -> RefCounted:
	return _question_controller

func get_presentation_shell() -> Control:
	return _presentation_shell

# Internal Helper Methods
func _setup_presentation_shell() -> void:
	if _presentation_shell == null:
		_presentation_shell = get_node_or_null("StagePresentationShell") as Control

	if _presentation_shell == null:
		var scene_res: Resource = load("res://src/ui/stage/stage_presentation_shell.tscn")
		if scene_res is PackedScene:
			_presentation_shell = (scene_res as PackedScene).instantiate() as Control
			add_child(_presentation_shell)

	if _presentation_shell == null:
		var script_res: Resource = load("res://src/ui/stage/stage_presentation_shell.gd")
		if script_res is GDScript:
			_presentation_shell = (script_res as GDScript).new() as Control
			add_child(_presentation_shell)

	if _presentation_shell != null:
		if _presentation_shell.has_signal("new_game_requested") and not _presentation_shell.is_connected("new_game_requested", _on_new_game_requested):
			_presentation_shell.connect("new_game_requested", _on_new_game_requested)
		if _presentation_shell.has_signal("continue_game_requested") and not _presentation_shell.is_connected("continue_game_requested", _on_continue_game_requested):
			_presentation_shell.connect("continue_game_requested", _on_continue_game_requested)
		if _presentation_shell.has_signal("lesson_continue_requested") and not _presentation_shell.is_connected("lesson_continue_requested", _on_lesson_continue_requested):
			_presentation_shell.connect("lesson_continue_requested", _on_lesson_continue_requested)
		if _presentation_shell.has_signal("question_host_ready") and not _presentation_shell.is_connected("question_host_ready", _on_question_host_ready):
			_presentation_shell.connect("question_host_ready", _on_question_host_ready)
		if _presentation_shell.has_signal("feedback_host_ready") and not _presentation_shell.is_connected("feedback_host_ready", _on_feedback_host_ready):
			_presentation_shell.connect("feedback_host_ready", _on_feedback_host_ready)
		if _presentation_shell.has_signal("stage_continue_requested") and not _presentation_shell.is_connected("stage_continue_requested", _on_stage_continue_requested):
			_presentation_shell.connect("stage_continue_requested", _on_stage_continue_requested)

func refresh_continue_availability() -> void:
	var has_save: bool = false
	if _save_service != null:
		has_save = _save_service.has_save()

	if _presentation_shell != null and _presentation_shell.has_method("set_continue_available"):
		_presentation_shell.call("set_continue_available", has_save)

# Signal Event Handlers
func _on_new_game_requested() -> void:
	start_new_game()

func _on_continue_game_requested() -> void:
	continue_game()

func _on_lesson_continue_requested() -> void:
	if _game_flow_service != null:
		var orch: StageOrchestrator = _game_flow_service.get_orchestrator()
		if orch != null:
			_active_question_res = orch.advance_to_question_phase()
	if _presentation_shell != null and _presentation_shell.has_method("set_view_mode"):
		_presentation_shell.call("set_view_mode", 2) # MODE_QUESTION_HOST

func _on_question_host_ready(host_container: Control) -> void:
	if host_container == null:
		return

	var panel: Control = host_container.get_node_or_null("QuestionPanel") as Control
	if panel == null:
		var scene_res: Resource = load("res://src/ui/question/question_panel.tscn")
		if scene_res is PackedScene:
			panel = (scene_res as PackedScene).instantiate() as Control
			host_container.add_child(panel)
		else:
			var script_res: Resource = load("res://src/ui/question/question_panel.gd")
			if script_res is GDScript:
				panel = (script_res as GDScript).new() as Control
				host_container.add_child(panel)

	if panel != null and _question_controller != null and _question_controller.has_method("attach_panel"):
		_question_controller.call("attach_panel", panel)
		if _question_controller.has_signal("question_completed") and not _question_controller.is_connected("question_completed", _on_question_completed):
			_question_controller.connect("question_completed", _on_question_completed)

	_start_current_question()

func _on_feedback_host_ready(_host_container: Control) -> void:
	if _presentation_shell != null and _presentation_shell.has_method("set_view_mode"):
		_presentation_shell.call("set_view_mode", 3) # MODE_FEEDBACK_HOST

func _on_question_completed(_result: Dictionary) -> void:
	if _game_flow_service == null:
		return

	var orch: StageOrchestrator = _game_flow_service.get_orchestrator()
	if orch != null:
		orch.set("_current_phase", "QUESTION_COMPLETE")
		var prep_res: Dictionary = orch.prepare_stage_clear_commit()
		if bool(prep_res.get("success", false)):
			var stage_id: String = String(prep_res.get("stage_id", ""))
			var reward_grant: RewardGrant = prep_res.get("reward_grant") as RewardGrant
			if not stage_id.is_empty() and reward_grant != null and _bridge != null:
				_bridge.commit_stage_and_checkpoint(stage_id, reward_grant)

	if _presentation_shell != null and _presentation_shell.has_method("set_view_mode"):
		_presentation_shell.call("set_view_mode", 4) # MODE_STAGE_COMPLETE

func _on_stage_continue_requested() -> void:
	if _game_flow_service == null:
		return

	var adv_res: Dictionary = _game_flow_service.advance_to_next_stage()
	if bool(adv_res.get("success", false)):
		var context: Dictionary = _game_flow_service.get_stage_context(false)
		if _presentation_shell != null and _presentation_shell.has_method("set_stage_context"):
			_presentation_shell.call("set_stage_context", context)
			if _presentation_shell.has_method("set_view_mode"):
				_presentation_shell.call("set_view_mode", 1) # MODE_LESSON

func _start_current_question() -> Dictionary:
	if _game_flow_service == null or _question_controller == null or _catalog == null:
		return {"success": false, "error_code": "NOT_INITIALIZED"}

	var current_stage_id: String = _game_flow_service.get_current_stage_id()
	if current_stage_id.is_empty():
		return {"success": false, "error_code": "NO_ACTIVE_STAGE"}

	if not _active_question_res.is_empty() and bool(_active_question_res.get("success", false)):
		var session: Dictionary = _active_question_res.get("session", {}) as Dictionary
		var question: Dictionary = _active_question_res.get("question", {}) as Dictionary
		if not session.is_empty() and not question.is_empty():
			if _question_controller.has_method("bind_existing_session"):
				return _question_controller.call("bind_existing_session", session, question) as Dictionary
			return _active_question_res

	var stage_data: Dictionary = _catalog.get_stage(current_stage_id)
	var practice_id: String = String(stage_data.get("practice_id", ""))
	var practice_data: Dictionary = _catalog.get_practice(practice_id)
	var scope: Dictionary = practice_data.get("question_scope", {}) as Dictionary

	var exclude_ids: Array[String] = []
	var request: Dictionary = {
		"request_id": "req_%s" % current_stage_id,
		"stage_id": current_stage_id,
		"scope": scope,
		"context": "practice",
		"preferred_difficulty": null,
		"exclude_question_ids": exclude_ids
	}

	var res: Dictionary = {}
	if _question_controller.has_method("start_question"):
		res = _question_controller.call("start_question", request) as Dictionary

	if bool(res.get("success", false)):
		_active_question_res = res
		var orch: StageOrchestrator = _game_flow_service.get_orchestrator()
		if orch != null:
			var session: Dictionary = res.get("session", {}) as Dictionary
			orch.set("_current_phase", "QUESTION_ACTIVE")
			orch.set("_active_question_session_id", String(session.get("session_id", "")))

	return res
