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

# Demo runtime metric state per stage/practice
var _active_practice_stage_id: String = ""
var _finalized_question_ids: Array[String] = []
var _first_attempt_results: Dictionary = {} # question_id (String) -> is_correct (bool)
var _current_question_id: String = ""

# Stage 1.5 Boss Combat State
var _active_combat_controller: CardCombatController = null
var _player_stats: PlayerStats = null
var _player_runtime: PlayerRuntime = null
var _active_enemy_entity: EnemyEntity = null

const QaAnswerRevealOverlayClass = preload("res://src/ui/qa/qa_answer_reveal_overlay.gd")
const AuthShellClass = preload("res://src/ui/auth/auth_shell.gd")
const AuthApiClientClass = preload("res://src/core/auth/auth_api_client.gd")

# UI Presentation
var _presentation_shell: Control = null
var _bootstrap_ui: Control = null
var _qa_overlay: Control = null
var _visual_lab_instance: Control = null
var _boot_sequence_instance: Control = null
var _auth_shell_instance: Control = null
var _auth_client: RefCounted = null
var _is_guest: bool = false
var _launch_reset_token: String = ""

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
	if report == null or not report.publication_allowed:
		push_error("AppRoot: Content validation failed for root '%s'. Publication not allowed." % root_path)
		return false

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
	_ensure_qa_overlay()
	refresh_continue_availability()
	print("[AppRoot] Runtime services and composition root initialized cleanly.")
	return true

func _ensure_qa_overlay() -> void:
	if _qa_overlay == null:
		var overlay_script: GDScript = load("res://src/ui/qa/qa_answer_reveal_overlay.gd") as GDScript
		if overlay_script != null and overlay_script.can_instantiate():
			_qa_overlay = overlay_script.new() as Control
			if _qa_overlay != null:
				_qa_overlay.call("set_catalog", _catalog)
				_qa_overlay.call("set_app_root", self)
				add_child(_qa_overlay)
	elif _qa_overlay != null and _qa_overlay.get_parent() == null:
		add_child(_qa_overlay)

func get_qa_overlay() -> Control:
	_ensure_qa_overlay()
	return _qa_overlay

## Starts a fresh New Game sequence from configured initial stage.
func start_new_game() -> Dictionary:
	if _game_flow_service == null:
		return {"success": false, "error_code": "NOT_INITIALIZED"}

	var flow_res: Dictionary = _game_flow_service.start_new_game()
	if not bool(flow_res.get("success", false)):
		return flow_res

	var stage_id: String = _game_flow_service.get_current_stage_id()
	_reset_practice_metrics(stage_id)
	_setup_combat_if_needed(stage_id)

	var context: Dictionary = _game_flow_service.get_stage_context(false)
	if _presentation_shell != null and _presentation_shell.has_method("set_stage_context"):
		var story_steps: Array = context.get("story_steps", []) as Array
		if not story_steps.is_empty() and _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 7) # MODE_STORY
		elif _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 1) # MODE_LESSON
		_presentation_shell.call("set_stage_context", context)
		if _bootstrap_ui != null:
			_bootstrap_ui.visible = false
		_presentation_shell.visible = true

	if _auth_shell_instance != null:
		_auth_shell_instance.visible = false

	return {
		"success": true,
		"stage_id": stage_id,
		"stage_context": context,
		"flow_result": flow_res
	}

## Restores committed save state via ProgressSaveBridge and initializes GameFlow stage context.
func continue_game() -> Dictionary:
	if _bridge == null or _save_service == null or not _save_service.has_save():
		return {"success": false, "error_code": "NO_SAVE_FOUND"}

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

	var entry_stage_id: String = String(restore_res.get("entry_stage_id", ""))

	# D1 Completion check: If D1 is fully completed and entry points to D2, freeze D2 auto-entry
	if _is_dungeon_1_complete() and entry_stage_id.begins_with("stage_02_"):
		if _presentation_shell != null and _presentation_shell.has_method("show_dungeon_1_complete"):
			var gold_val: int = _player_persistent.coin_balance if _player_persistent != null else 0
			var xp_val: int = _player_persistent.exp_total if _player_persistent != null else 0
			_presentation_shell.call("show_dungeon_1_complete", gold_val, xp_val, "Mảnh Vỡ Ma Thuật 01")
		if _bootstrap_ui != null:
			_bootstrap_ui.visible = false
		return {
			"success": true,
			"dungeon_1_complete": true,
			"entry_stage_id": entry_stage_id,
			"restore_result": restore_res
		}

	var flow_res: Dictionary = _game_flow_service.restore_from_save(restore_res)
	if not bool(flow_res.get("success", false)):
		return flow_res

	_reset_practice_metrics(entry_stage_id)
	_setup_combat_if_needed(entry_stage_id)

	var context: Dictionary = _game_flow_service.get_stage_context(true)
	if _presentation_shell != null and _presentation_shell.has_method("set_stage_context"):
		_presentation_shell.call("set_stage_context", context)
		if _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 1) # MODE_LESSON
		if _bootstrap_ui != null:
			_bootstrap_ui.visible = false
		_presentation_shell.visible = true

	if _auth_shell_instance != null:
		_auth_shell_instance.visible = false

	return {
		"success": true,
		"entry_stage_id": entry_stage_id,
		"stage_context": context,
		"restore_result": restore_res,
		"flow_result": flow_res
	}

func _is_dungeon_1_complete() -> bool:
	if _progress_service == null:
		return false
	var snapshot: ProgressState = _progress_service.create_snapshot_view()
	if snapshot == null:
		return false
	for s_idx in range(1, 6):
		var s_id: String = "stage_01_%02d" % s_idx
		if not snapshot.cleared_stage_ids.has(s_id):
			return false
	return true

## Section D: MAP -> GAME Validation.
## Validates unlock / replay eligibility through existing progression services before entering stage.
func select_stage(stage_id: String) -> Dictionary:
	if stage_id.is_empty():
		return {"success": false, "error_code": "INVALID_STAGE_ID"}

	if stage_id.begins_with("stage_02_") or stage_id.begins_with("stage_03_") or stage_id.begins_with("stage_04_"):
		push_warning("AppRoot: Dungeon 2-4 are currently frozen.")
		if _presentation_shell != null and _presentation_shell.has_method("show_notification_banner"):
			_presentation_shell.call("show_notification_banner", "Dungeon 2 hiện đang bị khóa.", true)
		return {"success": false, "error_code": "STAGE_LOCKED", "message": "Dungeon is frozen"}

	if _progress_service == null or not _progress_service.can_enter(stage_id):
		push_warning("AppRoot: Stage '%s' is locked and cannot be entered." % stage_id)
		return {"success": false, "error_code": "STAGE_LOCKED", "message": "Stage is locked"}

	if _game_flow_service == null:
		return {"success": false, "error_code": "NOT_INITIALIZED"}

	var flow_res: Dictionary = _game_flow_service.start_stage(stage_id)
	if not bool(flow_res.get("success", false)):
		return flow_res

	_reset_practice_metrics(stage_id)
	_setup_combat_if_needed(stage_id)

	var is_cleared: bool = _progress_service.create_snapshot_view().cleared_stage_ids.has(stage_id)
	var context: Dictionary = _game_flow_service.get_stage_context(is_cleared)

	if _presentation_shell != null and _presentation_shell.has_method("set_stage_context"):
		var story_steps: Array = context.get("story_steps", []) as Array
		if not story_steps.is_empty() and not is_cleared and _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 7) # MODE_STORY
		elif _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 1) # MODE_LESSON
		_presentation_shell.call("set_stage_context", context)
		if _bootstrap_ui != null:
			_bootstrap_ui.visible = false
		_presentation_shell.visible = true

	if _auth_shell_instance != null:
		_auth_shell_instance.visible = false

	return {
		"success": true,
		"stage_id": stage_id,
		"stage_context": context,
		"flow_result": flow_res
	}

## Opens Dungeon Stage Map Panel with live progress data
func show_stage_map() -> void:
	var unlocked_ids: Array[String] = ["stage_01_01"]
	var cleared_ids: Array[String] = []
	var curr_stage: String = "stage_01_01"

	if _progress_service != null:
		var snapshot: ProgressState = _progress_service.create_snapshot_view()
		if snapshot != null:
			unlocked_ids = snapshot.unlocked_stage_ids.duplicate()
			cleared_ids = snapshot.cleared_stage_ids.duplicate()

	if _game_flow_service != null:
		var flow_curr: String = _game_flow_service.get_current_stage_id()
		if not flow_curr.is_empty():
			curr_stage = flow_curr

	var map_data: Dictionary = {
		"unlocked_stages": unlocked_ids,
		"completed_stages": cleared_ids,
		"current_stage_id": curr_stage
	}

	if _presentation_shell != null and _presentation_shell.has_method("show_stage_map"):
		_presentation_shell.call("show_stage_map", map_data)

## Safely returns to Main Menu
func return_to_main_menu() -> void:
	refresh_continue_availability()
	if _presentation_shell != null:
		_presentation_shell.visible = true
		if _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 0) # MODE_ENTRY
	if _auth_shell_instance != null:
		_auth_shell_instance.visible = false

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

func get_active_combat_controller() -> CardCombatController:
	return _active_combat_controller

func get_active_enemy_entity() -> EnemyEntity:
	return _active_enemy_entity

func get_player_runtime() -> PlayerRuntime:
	return _player_runtime

func _setup_combat_if_needed(stage_id: String) -> void:
	if _catalog == null:
		return
	var stage_data: Dictionary = _catalog.get_stage(stage_id)
	var enc_mode: String = str(stage_data.get("encounter_mode", ""))
	var enemy_id: String = "" if stage_data.get("enemy_id") == null else str(stage_data.get("enemy_id"))

	if enc_mode == "card_combat" and not enemy_id.is_empty():
		if _player_stats == null:
			var game_cfg: Dictionary = _catalog.get_config()
			_player_stats = PlayerStats.new(game_cfg)
		_player_runtime = PlayerRuntime.new(stage_id, _player_stats)
		_active_enemy_entity = EnemyEntity.from_catalog(_catalog, enemy_id)

		var card_ids: Array = stage_data.get("card_pool_ids", []) as Array
		var cards: Array[CardModel] = CardModel.load_cards(_catalog, card_ids)

		_active_combat_controller = CardCombatController.new()
		_active_combat_controller.start_combat(_player_runtime, _active_enemy_entity, cards)

		if _presentation_shell != null and _presentation_shell.has_method("get_boss_combat_panel"):
			var boss_panel: BossCombatPanel = _presentation_shell.call("get_boss_combat_panel") as BossCombatPanel
			if boss_panel != null:
				boss_panel.set_controller(_active_combat_controller)
				if not boss_panel.retry_pressed.is_connected(_on_combat_retry_pressed):
					boss_panel.retry_pressed.connect(_on_combat_retry_pressed)
	else:
		_active_combat_controller = null
		_active_enemy_entity = null

func _on_combat_retry_pressed() -> void:
	if _active_combat_controller == null or _player_stats == null:
		return
	_active_combat_controller.reset_encounter(_player_stats)
	_finalized_question_ids.clear()
	_first_attempt_results.clear()
	_retry_question_id = _current_question_id
	_active_question_res = {}
	_start_current_question()

# Internal Helper Methods
func _is_visual_lab_mode() -> bool:
	var args: PackedStringArray = OS.get_cmdline_args()
	for a in args:
		if a == "--visual-lab":
			return true
	var uargs: PackedStringArray = OS.get_cmdline_user_args()
	for ua in uargs:
		if ua == "--visual-lab":
			return true
	return false

func _setup_visual_lab() -> void:
	if _visual_lab_instance != null:
		return

	var lab_scene: Resource = load("res://dev/visual_lab/visual_lab.tscn")
	if lab_scene is PackedScene:
		_visual_lab_instance = (lab_scene as PackedScene).instantiate() as Control
		add_child(_visual_lab_instance)
	else:
		var script_res: Resource = load("res://dev/visual_lab/visual_lab.gd")
		if script_res is GDScript:
			_visual_lab_instance = (script_res as GDScript).new() as Control
			add_child(_visual_lab_instance)

	if _bootstrap_ui != null:
		_bootstrap_ui.visible = false

func get_visual_lab() -> Control:
	return _visual_lab_instance

func _is_skip_splash_mode() -> bool:
	var args: PackedStringArray = OS.get_cmdline_args()
	for a in args:
		if a == "--skip-splash":
			return true
	var uargs: PackedStringArray = OS.get_cmdline_user_args()
	for ua in uargs:
		if ua == "--skip-splash":
			return true
	return false

func set_launch_reset_token(token: String) -> void:
	_launch_reset_token = token.strip_edges()

func get_launch_reset_token() -> String:
	return _launch_reset_token

func clear_launch_reset_token() -> void:
	_launch_reset_token = ""
	if _auth_shell_instance != null and _auth_shell_instance.has_method("clear_reset_token"):
		_auth_shell_instance.call("clear_reset_token")

func _get_cli_reset_token() -> String:
	var args: PackedStringArray = OS.get_cmdline_args()
	for a in args:
		if a.begins_with("--reset-token="):
			return a.substr(14).strip_edges()
	var uargs: PackedStringArray = OS.get_cmdline_user_args()
	for ua in uargs:
		if ua.begins_with("--reset-token="):
			return ua.substr(14).strip_edges()
	return ""

func _resolve_reset_token() -> String:
	if not _launch_reset_token.is_empty():
		return _launch_reset_token
	return _get_cli_reset_token()

func has_valid_reset_token() -> bool:
	var token: String = _resolve_reset_token()
	return not token.is_empty()

func _route_post_splash() -> void:
	if _auth_shell_instance == null:
		return
	_auth_shell_instance.visible = true
	if has_valid_reset_token():
		var token: String = _resolve_reset_token()
		if _auth_shell_instance.has_method("show_reset_password"):
			_auth_shell_instance.call("show_reset_password", token)
	else:
		if _auth_shell_instance.has_method("show_login"):
			_auth_shell_instance.call("show_login")

func _setup_boot_sequence() -> void:
	if _is_visual_lab_mode():
		return

	if _boot_sequence_instance != null or _is_skip_splash_mode():
		_route_post_splash()
		return

	var boot_scene: Resource = load("res://src/ui/boot/boot_sequence.tscn")
	if boot_scene is PackedScene:
		_boot_sequence_instance = (boot_scene as PackedScene).instantiate() as Control
		add_child(_boot_sequence_instance)
	else:
		var boot_script: Resource = load("res://src/ui/boot/boot_sequence.gd")
		if boot_script is GDScript:
			_boot_sequence_instance = (boot_script as GDScript).new() as Control
			add_child(_boot_sequence_instance)

	if _boot_sequence_instance != null:
		if _boot_sequence_instance.has_signal("boot_completed") and not _boot_sequence_instance.is_connected("boot_completed", _on_boot_sequence_completed):
			_boot_sequence_instance.connect("boot_completed", _on_boot_sequence_completed)
		if _boot_sequence_instance.has_method("start_boot_sequence"):
			_boot_sequence_instance.call("start_boot_sequence")

func get_boot_sequence() -> Control:
	return _boot_sequence_instance

func _setup_auth_shell() -> void:
	if _is_visual_lab_mode():
		return

	if _auth_shell_instance == null:
		_auth_shell_instance = get_node_or_null("AuthShell") as Control

	if _auth_shell_instance == null:
		var auth_shell_scene: Resource = load("res://src/ui/auth/auth_shell.tscn")
		if auth_shell_scene is PackedScene:
			_auth_shell_instance = (auth_shell_scene as PackedScene).instantiate() as Control
			add_child(_auth_shell_instance)
		else:
			var auth_script: Resource = load("res://src/ui/auth/auth_shell.gd")
			if auth_script is GDScript:
				_auth_shell_instance = (auth_script as GDScript).new() as Control
				add_child(_auth_shell_instance)

	if _auth_shell_instance != null:
		if _auth_client == null:
			_auth_client = AuthApiClientClass.new()
		if _auth_shell_instance.has_method("set_auth_client"):
			_auth_shell_instance.call("set_auth_client", _auth_client)

		if _auth_shell_instance.has_signal("auth_completed") and not _auth_shell_instance.is_connected("auth_completed", _on_auth_completed):
			_auth_shell_instance.connect("auth_completed", _on_auth_completed)
		if _auth_shell_instance.has_signal("guest_entered") and not _auth_shell_instance.is_connected("guest_entered", _on_guest_entered):
			_auth_shell_instance.connect("guest_entered", _on_guest_entered)

		if _boot_sequence_instance != null and _boot_sequence_instance.is_running():
			_auth_shell_instance.visible = false
		else:
			_route_post_splash()

func _on_boot_sequence_completed() -> void:
	_route_post_splash()

func _on_auth_completed(_result: RefCounted) -> void:
	_is_guest = false
	clear_launch_reset_token()
	if _presentation_shell != null and _presentation_shell.has_method("set_guest_mode"):
		_presentation_shell.call("set_guest_mode", false)
	if _auth_shell_instance != null:
		_auth_shell_instance.visible = false
	if _presentation_shell != null:
		_presentation_shell.visible = true
		if _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 0) # MODE_ENTRY
	refresh_continue_availability()

func _on_guest_entered() -> void:
	_is_guest = true
	clear_launch_reset_token()
	if _presentation_shell != null and _presentation_shell.has_method("set_guest_mode"):
		_presentation_shell.call("set_guest_mode", true)
	if _auth_shell_instance != null:
		_auth_shell_instance.visible = false
	if _presentation_shell != null:
		_presentation_shell.visible = true
		if _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 0) # MODE_ENTRY
	refresh_continue_availability()

func logout() -> void:
	clear_launch_reset_token()
	if not _is_guest:
		if _auth_client != null and _auth_client.has_method("logout"):
			_auth_client.logout()
		elif _auth_shell_instance != null and _auth_shell_instance.has_method("get_auth_client"):
			var ac = _auth_shell_instance.get_auth_client()
			if ac != null and ac.has_method("logout"):
				ac.logout()
	_is_guest = false

	if _presentation_shell != null:
		_presentation_shell.visible = false
		if _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 0)

	if _auth_shell_instance != null:
		_auth_shell_instance.visible = true
		if _auth_shell_instance.has_method("show_login"):
			_auth_shell_instance.call("show_login")

func is_guest_mode() -> bool:
	return _is_guest

func set_guest_mode(guest: bool) -> void:
	_is_guest = guest
	if _presentation_shell != null and _presentation_shell.has_method("set_guest_mode"):
		_presentation_shell.call("set_guest_mode", guest)

func get_auth_shell() -> Control:
	return _auth_shell_instance

func get_auth_client() -> RefCounted:
	if _auth_client != null:
		return _auth_client
	if _auth_shell_instance != null and _auth_shell_instance.has_method("get_auth_client"):
		return _auth_shell_instance.get_auth_client()
	return null

func set_auth_client(client: RefCounted) -> void:
	_auth_client = client
	if _auth_shell_instance != null and _auth_shell_instance.has_method("set_auth_client"):
		_auth_shell_instance.set_auth_client(client)

func _setup_presentation_shell() -> void:
	if _is_visual_lab_mode():
		_setup_visual_lab()
		return

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
		if _presentation_shell.has_signal("show_map_requested") and not _presentation_shell.is_connected("show_map_requested", show_stage_map):
			_presentation_shell.connect("show_map_requested", show_stage_map)
		if _presentation_shell.has_signal("return_to_main_menu_requested") and not _presentation_shell.is_connected("return_to_main_menu_requested", return_to_main_menu):
			_presentation_shell.connect("return_to_main_menu_requested", return_to_main_menu)
		if _presentation_shell.has_signal("stage_selected") and not _presentation_shell.is_connected("stage_selected", select_stage):
			_presentation_shell.connect("stage_selected", select_stage)
		if _presentation_shell.has_signal("lesson_continue_requested") and not _presentation_shell.is_connected("lesson_continue_requested", _on_lesson_continue_requested):
			_presentation_shell.connect("lesson_continue_requested", _on_lesson_continue_requested)
		if _presentation_shell.has_signal("story_completed") and not _presentation_shell.is_connected("story_completed", _on_story_completed):
			_presentation_shell.connect("story_completed", _on_story_completed)
		if _presentation_shell.has_signal("story_continue_requested") and not _presentation_shell.is_connected("story_continue_requested", _on_story_completed):
			_presentation_shell.connect("story_continue_requested", _on_story_completed)
		if _presentation_shell.has_signal("question_host_ready") and not _presentation_shell.is_connected("question_host_ready", _on_question_host_ready):
			_presentation_shell.connect("question_host_ready", _on_question_host_ready)
		if _presentation_shell.has_signal("feedback_host_ready") and not _presentation_shell.is_connected("feedback_host_ready", _on_feedback_host_ready):
			_presentation_shell.connect("feedback_host_ready", _on_feedback_host_ready)
		if _presentation_shell.has_signal("stage_continue_requested") and not _presentation_shell.is_connected("stage_continue_requested", _on_stage_continue_requested):
			_presentation_shell.connect("stage_continue_requested", _on_stage_continue_requested)
		if _presentation_shell.has_signal("logout_requested") and not _presentation_shell.is_connected("logout_requested", logout):
			_presentation_shell.connect("logout_requested", logout)
		if _bootstrap_ui != null:
			_bootstrap_ui.visible = false
		_presentation_shell.visible = false

	_setup_boot_sequence()
	_setup_auth_shell()

func refresh_continue_availability() -> void:
	var has_save: bool = false
	var summary_data: Dictionary = {}
	if _save_service != null:
		has_save = _save_service.has_save()
		if has_save:
			var load_res: Dictionary = _save_service.load()
			if bool(load_res.get("success", false)):
				var snapshot: Dictionary = load_res.get("snapshot", {}) as Dictionary
				var progress_dict: Dictionary = snapshot.get("progress", {}) as Dictionary
				var unlocked: Array = progress_dict.get("unlocked_stage_ids", []) as Array
				var entry_stage_id: String = ""
				if not unlocked.is_empty():
					entry_stage_id = String(unlocked[unlocked.size() - 1])
				if _catalog != null and not entry_stage_id.is_empty():
					var stage_info: Dictionary = _catalog.get_stage(entry_stage_id)
					summary_data["stage_id"] = entry_stage_id
					summary_data["stage_title"] = String(stage_info.get("title", entry_stage_id))
					summary_data["dungeon_id"] = String(stage_info.get("dungeon_id", ""))

	if _presentation_shell != null and _presentation_shell.has_method("set_continue_available"):
		_presentation_shell.call("set_continue_available", has_save, summary_data)

func _reset_practice_metrics(stage_id: String) -> void:
	_active_practice_stage_id = stage_id
	_finalized_question_ids.clear()
	_first_attempt_results.clear()
	_current_question_id = ""

# Signal Event Handlers
func _on_new_game_requested() -> void:
	start_new_game()

func _on_continue_game_requested() -> void:
	continue_game()

func _show_game_victory() -> void:
	var gold: int = 0
	var xp: int = 0
	if _player_persistent != null:
		gold = _player_persistent.coin_balance
		xp = _player_persistent.exp_total

	if _presentation_shell != null and _presentation_shell.has_method("show_game_victory"):
		_presentation_shell.call("show_game_victory", gold, xp)

func _on_story_completed() -> void:
	if _presentation_shell != null:
		if _presentation_shell.has_method("show_lesson_phase"):
			_presentation_shell.call("show_lesson_phase")
		elif _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 1) # MODE_LESSON

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

	var target_container: Control = host_container.get_node_or_null("GameplayHBox/QuestionPanelHost") as Control
	if target_container == null:
		push_error("AppRoot._on_question_host_ready: Missing required mount host 'GameplayHBox/QuestionPanelHost' under QuestionHostContainer")
		return

	var panel: Control = target_container.get_node_or_null("QuestionPanel") as Control
	if panel == null:
		if host_container.has_node("QuestionPanel"):
			panel = host_container.get_node("QuestionPanel") as Control
			host_container.remove_child(panel)
			target_container.add_child(panel)
		else:
			var scene_res: Resource = load("res://src/ui/question/question_panel.tscn")
			if scene_res is PackedScene:
				panel = (scene_res as PackedScene).instantiate() as Control
				target_container.add_child(panel)
			else:
				var script_res: Resource = load("res://src/ui/question/question_panel.gd")
				if script_res is GDScript:
					panel = (script_res as GDScript).new() as Control
					target_container.add_child(panel)

	if panel != null and _question_controller != null and _question_controller.has_method("attach_panel"):
		_question_controller.call("attach_panel", panel)
		if _question_controller.has_signal("question_completed") and not _question_controller.is_connected("question_completed", _on_question_completed):
			_question_controller.connect("question_completed", _on_question_completed)
		if _question_controller.has_signal("continue_requested") and not _question_controller.is_connected("continue_requested", _on_question_continue_requested):
			_question_controller.connect("continue_requested", _on_question_continue_requested)
		if _question_controller.has_signal("retry_requested") and not _question_controller.is_connected("retry_requested", _on_question_retry_requested):
			_question_controller.connect("retry_requested", _on_question_retry_requested)

	if _active_combat_controller != null and _presentation_shell != null and _presentation_shell.has_method("get_boss_combat_panel"):
		var boss_panel: BossCombatPanel = _presentation_shell.call("get_boss_combat_panel") as BossCombatPanel
		if boss_panel != null:
			boss_panel.set_controller(_active_combat_controller)
			if not boss_panel.retry_pressed.is_connected(_on_combat_retry_pressed):
				boss_panel.retry_pressed.connect(_on_combat_retry_pressed)

	_start_current_question()

func get_question_panel() -> QuestionPanel:
	if _presentation_shell != null and _presentation_shell.has_method("get_question_panel"):
		return _presentation_shell.call("get_question_panel") as QuestionPanel
	return null

func _on_feedback_host_ready(_host_container: Control) -> void:
	if _presentation_shell != null and _presentation_shell.has_method("set_view_mode"):
		_presentation_shell.call("set_view_mode", 3) # MODE_FEEDBACK_HOST

func _on_question_completed(result: Dictionary) -> void:
	var q_id: String = String(result.get("question_id", ""))
	if q_id.is_empty():
		q_id = _current_question_id

	var is_correct: bool = bool(result.get("is_correct", false))

	if not q_id.is_empty() and not _first_attempt_results.has(q_id):
		_first_attempt_results[q_id] = is_correct

	if _active_combat_controller != null and _active_combat_controller.is_in_combat:
		_active_combat_controller.resolve_answer_outcome(is_correct)

func _on_question_continue_requested() -> void:
	if not _current_question_id.is_empty() and not _finalized_question_ids.has(_current_question_id):
		_finalized_question_ids.append(_current_question_id)

	if _active_combat_controller != null and _active_combat_controller.boss_entity != null and _active_combat_controller.boss_entity.is_defeated:
		_finish_stage_practice()
		return

	if _active_combat_controller != null and _active_combat_controller.player_runtime != null and _active_combat_controller.player_runtime.is_defeated:
		return

	# Respect target question_count from practice.json when not in card combat
	var is_combat: bool = (_active_combat_controller != null and _active_combat_controller.is_in_combat)
	if not is_combat:
		var target_count: int = _get_target_practice_question_count()
		if target_count > 0 and _finalized_question_ids.size() >= target_count:
			_finish_stage_practice()
			return

	_active_question_res = {}
	var next_res: Dictionary = _start_next_question_in_stage()
	if not bool(next_res.get("success", false)):
		var err_code: String = String(next_res.get("error_code", ""))
		if err_code == QuestionErrorCodes.NO_VALID_QUESTION or err_code == "NO_VALID_QUESTION" or err_code == "NO_REACHABLE_QUESTIONS":
			if _active_combat_controller != null and _active_combat_controller.is_in_combat and not _active_combat_controller.boss_entity.is_defeated:
				_finalized_question_ids.clear()
				next_res = _start_next_question_in_stage()
				if not bool(next_res.get("success", false)):
					_finish_stage_practice()
			else:
				_finish_stage_practice()
		else:
			push_error("AppRoot: _on_question_continue_requested encountered unexpected question request failure code: '%s'. Aborting stage clear." % err_code)

func _get_target_practice_question_count() -> int:
	if _catalog == null or _game_flow_service == null:
		return 3
	var stage_id: String = _game_flow_service.get_current_stage_id()
	if stage_id.is_empty():
		return 3
	var stage: Dictionary = _catalog.get_stage(stage_id)
	var practice_id: String = String(stage.get("practice_id", ""))
	if practice_id.is_empty():
		return 3
	var practice: Dictionary = _catalog.get_practice(practice_id)
	return int(practice.get("question_count", 3))

var _retry_question_id: String = ""

func _on_question_retry_requested() -> void:
	_retry_question_id = _current_question_id
	_active_question_res = {}
	_start_current_question()

func _finish_stage_practice() -> void:
	var granted_coins: int = 0
	var granted_exp: int = 0
	var granted_frag: String = ""

	if _game_flow_service != null:
		var orch: StageOrchestrator = _game_flow_service.get_orchestrator()
		if orch != null:
			orch.set("_current_phase", "QUESTION_COMPLETE")
			var prep_res: Dictionary = orch.prepare_stage_clear_commit()
			if bool(prep_res.get("success", false)):
				var stage_id: String = String(prep_res.get("stage_id", ""))
				var reward_grant: RewardGrant = prep_res.get("reward_grant") as RewardGrant
				if not stage_id.is_empty() and reward_grant != null and _bridge != null:
					granted_coins = reward_grant.coin_delta
					granted_exp = reward_grant.exp_delta
					if not reward_grant.fragment_ids.is_empty():
						granted_frag = String(reward_grant.fragment_ids[0])

					if _bridge != null and _progress_service != null:
						_bridge._progress_service = _progress_service
					var commit_res: Dictionary = _bridge.commit_stage_and_checkpoint(stage_id, reward_grant)
					if not bool(commit_res.get("success", false)):
						if _presentation_shell != null and _presentation_shell.has_method("show_notification_banner"):
							_presentation_shell.call("show_notification_banner", "Không thể lưu tiến trình tự động. Tiến trình hiện tại vẫn được giữ tạm thời.", true)

	var unique_count: int = _finalized_question_ids.size()
	var first_attempt_correct: int = 0
	for qid in _finalized_question_ids:
		if bool(_first_attempt_results.get(qid, false)):
			first_attempt_correct += 1

	var acc_pct: float = (first_attempt_correct as float / max(1, unique_count)) * 100.0
	var stage_summary: String = _build_dynamic_stage_summary()

	if _presentation_shell != null:
		if _presentation_shell.has_method("get_stage_complete_panel"):
			var complete_panel: StageCompletePanel = _presentation_shell.call("get_stage_complete_panel") as StageCompletePanel
			if complete_panel != null:
				complete_panel.set_stage_complete_stats(unique_count, acc_pct, stage_summary)
				complete_panel.set_rewards_data(granted_coins, granted_exp, granted_frag)

		if _presentation_shell.has_method("set_view_mode"):
			_presentation_shell.call("set_view_mode", 4) # MODE_STAGE_COMPLETE

func _build_dynamic_stage_summary() -> String:
	if _catalog == null or _game_flow_service == null:
		return "• Phép thử ngẫu nhiên\n• Không gian mẫu Ω\n• Biến cố A ⊆ Ω"
	var stage_id: String = _game_flow_service.get_current_stage_id()
	if stage_id.is_empty():
		return "• Phép thử ngẫu nhiên\n• Không gian mẫu Ω\n• Biến cố A ⊆ Ω"
	var stage: Dictionary = _catalog.get_stage(stage_id)
	var lesson_id: String = String(stage.get("lesson_id", ""))
	var lesson: Dictionary = _catalog.get_lesson(lesson_id)
	var sections: Array = lesson.get("sections", []) as Array
	if not sections.is_empty():
		var bullets: Array[String] = []
		for sec_var in sections:
			var sec: Dictionary = sec_var as Dictionary
			var header: String = String(sec.get("header", ""))
			if not header.is_empty():
				bullets.append("• " + header)
		if not bullets.is_empty():
			return "\n".join(bullets)
	var obj: String = String(stage.get("learning_objective", ""))
	if not obj.is_empty():
		return "• " + obj
	return "• Phép thử ngẫu nhiên\n• Không gian mẫu Ω\n• Biến cố A ⊆ Ω"

func _on_stage_continue_requested() -> void:
	if _game_flow_service == null:
		return

	var current_st: String = _game_flow_service.get_current_stage_id()
	# D1 Completion check: If clearing stage_01_05, show D1 Complete screen and freeze D2
	if current_st == "stage_01_05":
		_show_dungeon_1_complete()
		return

	var adv_res: Dictionary = _game_flow_service.advance_to_next_stage()
	if bool(adv_res.get("success", false)):
		if bool(adv_res.get("game_completed", false)):
			_show_game_victory()
			return

		var next_stage_id: String = _game_flow_service.get_current_stage_id()
		if next_stage_id.begins_with("stage_02_"):
			_show_dungeon_1_complete()
			return

		_reset_practice_metrics(next_stage_id)
		_setup_combat_if_needed(next_stage_id)

		var context: Dictionary = _game_flow_service.get_stage_context(false)
		if _presentation_shell != null and _presentation_shell.has_method("set_stage_context"):
			var story_steps: Array = context.get("story_steps", []) as Array
			if not story_steps.is_empty() and _presentation_shell.has_method("set_view_mode"):
				_presentation_shell.call("set_view_mode", 7) # MODE_STORY
			elif _presentation_shell.has_method("set_view_mode"):
				_presentation_shell.call("set_view_mode", 1) # MODE_LESSON
			_presentation_shell.call("set_stage_context", context)

func _show_dungeon_1_complete() -> void:
	if _presentation_shell != null and _presentation_shell.has_method("show_dungeon_1_complete"):
		var gold_val: int = _player_persistent.coin_balance if _player_persistent != null else 0
		var xp_val: int = _player_persistent.exp_total if _player_persistent != null else 0
		_presentation_shell.call("show_dungeon_1_complete", gold_val, xp_val, "Mảnh Vỡ Ma Thuật 01")

func _start_current_question() -> Dictionary:
	return _start_next_question_in_stage()

func _start_next_question_in_stage() -> Dictionary:
	if _game_flow_service == null or _question_controller == null or _catalog == null:
		return {"success": false, "error_code": "NOT_INITIALIZED"}

	var current_stage_id: String = _game_flow_service.get_current_stage_id()
	if current_stage_id.is_empty():
		return {"success": false, "error_code": "NO_ACTIVE_STAGE"}

	if _active_practice_stage_id != current_stage_id:
		_reset_practice_metrics(current_stage_id)

	if not _active_question_res.is_empty() and bool(_active_question_res.get("success", false)):
		var session: Dictionary = _active_question_res.get("session", {}) as Dictionary
		var question: Dictionary = _active_question_res.get("question", {}) as Dictionary
		if not session.is_empty() and not question.is_empty():
			var bind_res: Dictionary = {}
			if _question_controller.has_method("bind_existing_session"):
				bind_res = _question_controller.call("bind_existing_session", session, question) as Dictionary
			else:
				bind_res = _active_question_res
			if bool(bind_res.get("success", false)):
				_current_question_id = String(question.get("question_id", ""))
				if _qa_overlay != null: _qa_overlay.on_question_changed(_current_question_id)
				var orch: StageOrchestrator = _game_flow_service.get_orchestrator()
				if orch != null:
					orch.set("_current_phase", "QUESTION_ACTIVE")
					orch.set("_active_question_session_id", String(session.get("session_id", "")))
			return bind_res

	if _question_service != null and _question_service.has_active_session():
		var active_sess: Dictionary = _question_service.get_active_session()
		var active_q: Dictionary = _question_service.get_active_question()
		if not active_sess.is_empty() and not active_q.is_empty():
			_active_question_res = {
				"success": true,
				"session": active_sess,
				"question": active_q
			}
			var bind_res: Dictionary = {}
			if _question_controller.has_method("bind_existing_session"):
				bind_res = _question_controller.call("bind_existing_session", active_sess, active_q) as Dictionary
			else:
				bind_res = _active_question_res
			if bool(bind_res.get("success", false)):
				_current_question_id = String(active_q.get("question_id", ""))
				if _qa_overlay != null: _qa_overlay.on_question_changed(_current_question_id)
				var orch: StageOrchestrator = _game_flow_service.get_orchestrator()
				if orch != null:
					orch.set("_current_phase", "QUESTION_ACTIVE")
					orch.set("_active_question_session_id", String(active_sess.get("session_id", "")))
			return bind_res

	var stage_data: Dictionary = _catalog.get_stage(current_stage_id)
	var practice_id: String = String(stage_data.get("practice_id", ""))
	var practice_data: Dictionary = _catalog.get_practice(practice_id)
	var scope: Dictionary = practice_data.get("question_scope", {}) as Dictionary

	var request_id_str: String = "req_%s" % current_stage_id
	if not _finalized_question_ids.is_empty():
		request_id_str += "_%d" % (_finalized_question_ids.size() + 1)

	var excludes: Array = _finalized_question_ids.duplicate()
	if not _retry_question_id.is_empty():
		var scope_candidates: Array[Dictionary] = _catalog.query_questions(scope, "practice")
		for cand in scope_candidates:
			var qid: String = String(cand.get("question_id", ""))
			if qid != _retry_question_id and not excludes.has(qid):
				excludes.append(qid)
		_retry_question_id = ""

	var request: Dictionary = {
		"request_id": request_id_str,
		"stage_id": current_stage_id,
		"scope": scope,
		"context": "practice",
		"preferred_difficulty": null,
		"exclude_question_ids": excludes
	}

	var res: Dictionary = {}
	if _question_controller.has_method("start_question"):
		res = _question_controller.call("start_question", request) as Dictionary

	if bool(res.get("success", false)):
		_active_question_res = res
		var question: Dictionary = res.get("question", {}) as Dictionary
		_current_question_id = String(question.get("question_id", ""))
		if _qa_overlay != null: _qa_overlay.on_question_changed(_current_question_id)
		var orch: StageOrchestrator = _game_flow_service.get_orchestrator()
		if orch != null:
			var session: Dictionary = res.get("session", {}) as Dictionary
			orch.set("_current_phase", "QUESTION_ACTIVE")
			orch.set("_active_question_session_id", String(session.get("session_id", "")))

	return res
