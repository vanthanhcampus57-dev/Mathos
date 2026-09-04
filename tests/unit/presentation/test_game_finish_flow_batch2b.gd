extends SceneTree

## Comprehensive test suite for MATHOS-DIRECT-GAME-FINISH-FLOW-BATCH-2B
## Verifies full player navigation: Main Menu -> Stage Map -> Unlocked/Replay Stage,
## runtime lock enforcement, Pause Menu (Resume, Map, Main Menu), and stage_04_05 Victory flow.

const AppRootClass = preload("res://src/app/app_root.gd")
const StagePresentationShellClass = preload("res://src/ui/stage/stage_presentation_shell.gd")
const PauseMenuOverlayClass = preload("res://src/ui/common/pause_menu_overlay.gd")
const DungeonStageMapPanelClass = preload("res://src/ui/map/dungeon_stage_map_panel.gd")

func _initialize() -> void:
	print("--- RUNNING FINISHED GAME FLOW BATCH 2B QA HARNESS ---")
	var ok: bool = run_all_tests()
	if ok:
		print("FINISHED GAME FLOW BATCH 2B QA HARNESS PASS!")
		quit(0)
	else:
		print("FINISHED GAME FLOW BATCH 2B QA HARNESS FAIL!")
		quit(1)

static func _clean_user_saves() -> void:
	for name in ["save_v1.json", "save_v1.tmp", "save_v1.bak", "save_v1_corrupt_diagnostic.json", "save_slot_0.json"]:
		var p: String = "user://" + name
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

static func run_all_tests() -> bool:
	var pass_count: int = 0
	if test_001_main_menu_to_stage_map_navigation(): pass_count += 1
	if test_002_map_unlocked_stage_selection(): pass_count += 1
	if test_003_locked_stage_rejected_at_runtime(): pass_count += 1
	if test_004_pause_resume_exact_state_return(): pass_count += 1
	if test_005_pause_to_stage_map_and_main_menu(): pass_count += 1
	if test_006_completed_stage_replay_preserves_progression(): pass_count += 1
	if test_007_final_stage_to_victory_flow_integration(): pass_count += 1

	print("[BATCH2B-HARNESS] %d / 7 test scenarios passed" % pass_count)
	return pass_count == 7

static func test_001_main_menu_to_stage_map_navigation() -> bool:
	print("[BATCH2B-001] Testing Main Menu -> Stage Map navigation...")
	_clean_user_saves()
	var root: AppRoot = AppRootClass.new()
	if not root.bootstrap_runtime("res://content"):
		print("[BATCH2B-001] FAIL: AppRoot bootstrap failed")
		root.free()
		return false

	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	root.show_stage_map()

	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_MAP:
		print("[BATCH2B-001] FAIL: shell view mode is not MODE_MAP")
		root.free()
		return false

	var map_panel: DungeonStageMapPanel = shell.get_stage_map_panel()
	if map_panel == null or not map_panel.visible:
		print("[BATCH2B-001] FAIL: DungeonStageMapPanel is null or invisible")
		root.free()
		return false

	print("[BATCH2B-001] PASS: Main Menu -> Stage Map navigation verified")
	root.free()
	return true

static func test_002_map_unlocked_stage_selection() -> bool:
	print("[BATCH2B-002] Testing Map -> Unlocked stage selection...")
	_clean_user_saves()
	var root: AppRoot = AppRootClass.new()
	root.bootstrap_runtime("res://content")

	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	var res: Dictionary = root.select_stage("stage_01_01")

	if not bool(res.get("success", false)):
		print("[BATCH2B-002] FAIL: select_stage('stage_01_01') failed: %s" % str(res))
		root.free()
		return false

	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_LESSON and shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_STORY:
		print("[BATCH2B-002] FAIL: view mode is not MODE_LESSON or MODE_STORY after selecting stage_01_01, got %d" % shell.get_view_mode())
		root.free()
		return false

	print("[BATCH2B-002] PASS: Map -> Unlocked stage selection verified")
	root.free()
	return true

static func test_003_locked_stage_rejected_at_runtime() -> bool:
	print("[BATCH2B-003] Testing locked stage selection rejected at runtime...")
	_clean_user_saves()
	var root: AppRoot = AppRootClass.new()
	root.bootstrap_runtime("res://content")

	# Attempt to select a locked stage (e.g. stage_04_05) when only stage_01_01 is unlocked
	var res: Dictionary = root.select_stage("stage_04_05")
	if bool(res.get("success", false)) or String(res.get("error_code", "")) != "STAGE_LOCKED":
		print("[BATCH2B-003] FAIL: select_stage('stage_04_05') should be rejected with STAGE_LOCKED. Got: %s" % str(res))
		root.free()
		return false

	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	if shell.get_view_mode() == StagePresentationShell.ViewMode.MODE_LESSON:
		print("[BATCH2B-003] FAIL: shell entered MODE_LESSON despite locked stage rejection")
		root.free()
		return false

	print("[BATCH2B-003] PASS: Locked stage selection rejected at runtime verified")
	root.free()
	return true

static func test_004_pause_resume_exact_state_return() -> bool:
	print("[BATCH2B-004] Testing Pause -> Resume exact active state return...")
	_clean_user_saves()
	var root: AppRoot = AppRootClass.new()
	root.bootstrap_runtime("res://content")

	root.start_new_game()
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	var initial_mode = shell.get_view_mode()
	if initial_mode != StagePresentationShell.ViewMode.MODE_LESSON and initial_mode != StagePresentationShell.ViewMode.MODE_STORY:
		print("[BATCH2B-004] FAIL: expected MODE_LESSON or MODE_STORY initially, got %d" % initial_mode)
		root.free()
		return false

	# Trigger Pause
	shell.toggle_pause()
	if not shell.is_paused():
		print("[BATCH2B-004] FAIL: shell is not paused after toggle_pause")
		root.free()
		return false

	# Resume
	shell.toggle_pause()
	if shell.is_paused():
		print("[BATCH2B-004] FAIL: shell is still paused after second toggle_pause")
		root.free()
		return false

	if shell.get_view_mode() != initial_mode:
		print("[BATCH2B-004] FAIL: shell did not return to initial mode on resume (was %d, now %d)" % [initial_mode, shell.get_view_mode()])
		root.free()
		return false

	print("[BATCH2B-004] PASS: Pause -> Resume exact state return verified")
	root.free()
	return true

static func test_005_pause_to_stage_map_and_main_menu() -> bool:
	print("[BATCH2B-005] Testing Pause -> Stage Map and Main Menu transitions...")
	_clean_user_saves()
	var root: AppRoot = AppRootClass.new()
	root.bootstrap_runtime("res://content")

	root.start_new_game()
	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	var pause: PauseMenuOverlay = shell.get_pause_menu_overlay()

	# Pause -> Stage Map
	shell.show_pause()
	pause.stage_map_requested.emit()

	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_MAP or shell.is_paused():
		print("[BATCH2B-005] FAIL: Pause -> Stage Map transition failed")
		root.free()
		return false

	# Pause -> Main Menu from active game
	root.start_new_game()
	shell.show_pause()
	pause.main_menu_requested.emit()

	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_ENTRY or shell.is_paused():
		print("[BATCH2B-005] FAIL: Pause -> Main Menu transition failed")
		root.free()
		return false

	print("[BATCH2B-005] PASS: Pause -> Stage Map and Main Menu transitions verified")
	root.free()
	return true

static func test_006_completed_stage_replay_preserves_progression() -> bool:
	print("[BATCH2B-006] Testing completed-stage replay preserves progression...")
	_clean_user_saves()
	var root: AppRoot = AppRootClass.new()
	root.bootstrap_runtime("res://content")

	var prog: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	var st_data: Dictionary = cat.get_stage("stage_01_01")
	var r_id: String = String(st_data.get("reward_id", "reward_stage_01_01"))
	var empty_frags: Array[String] = []
	var grant: RewardGrant = RewardGrant.new(r_id, "stage_01_01", 100, 50, empty_frags)
	prog.commit_stage_clear("stage_01_01", grant)

	# Select stage_01_01 in replay mode
	var replay_res: Dictionary = root.select_stage("stage_01_01")
	if not bool(replay_res.get("success", false)):
		print("[BATCH2B-006] FAIL: select_stage('stage_01_01') replay failed: %s" % str(replay_res))
		root.free()
		return false

	var cleared: Array[String] = prog.create_snapshot_view().cleared_stage_ids
	if not cleared.has("stage_01_01"):
		print("[BATCH2B-006] FAIL: stage_01_01 cleared record was corrupted during replay")
		root.free()
		return false

	print("[BATCH2B-006] PASS: Completed-stage replay preserves progression verified")
	root.free()
	return true

static func test_007_final_stage_to_victory_flow_integration() -> bool:
	print("[BATCH2B-007] Testing final stage (stage_04_05) -> Victory flow integration...")
	_clean_user_saves()
	var root: AppRoot = AppRootClass.new()
	root.bootstrap_runtime("res://content")

	var flow: GameFlowService = root.get_game_flow_service()
	var prog: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()

	# Clear stages up to 04_05
	for d in range(1, 5):
		for s in range(1, 6):
			var st_id: String = "stage_%02d_%02d" % [d, s]
			if prog.can_enter(st_id):
				var st_data: Dictionary = cat.get_stage(st_id)
				var r_id: String = String(st_data.get("reward_id", ""))
				var frags: Array[String] = []
				if s == 5:
					frags.append("fragment_%02d" % d)
				var grant: RewardGrant = RewardGrant.new(r_id, st_id, 10, 10, frags)
				prog.commit_stage_clear(st_id, grant)

	flow.start_stage("stage_04_05")
	root._on_stage_continue_requested()

	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_VICTORY:
		print("[BATCH2B-007] FAIL: completing stage_04_05 did not transition shell to MODE_VICTORY")
		root.free()
		return false

	print("[BATCH2B-007] PASS: Final stage -> Victory flow integration verified")
	root.free()
	return true
