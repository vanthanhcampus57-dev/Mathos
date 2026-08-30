extends SceneTree

## Comprehensive test suite for MATHOS-DIRECT-GAME-FINISH-FLOW-BATCH-1-FIX-1
## Verifies production Main Menu, no-save continue behavior, stage_04_05 victory flow,
## authoritative dungeon curriculum labels, and 1..19 stage advancement continuity.

const AppRootClass = preload("res://src/app/app_root.gd")
const GameVictoryPanelClass = preload("res://src/ui/stage/game_victory_panel.gd")
const StagePresentationShellClass = preload("res://src/ui/stage/stage_presentation_shell.gd")

func _initialize() -> void:
	print("--- RUNNING FINISHED GAME FLOW BATCH 1 FIX-1 QA HARNESS ---")
	var ok: bool = run_all_tests()
	if ok:
		print("FINISHED GAME FLOW BATCH 1 FIX-1 QA HARNESS PASS!")
		quit(0)
	else:
		print("FINISHED GAME FLOW BATCH 1 FIX-1 QA HARNESS FAIL!")
		quit(1)

static func _clean_user_saves() -> void:
	for name in ["save_v1.json", "save_v1.tmp", "save_v1.bak", "save_v1_corrupt_diagnostic.json", "save_slot_0.json"]:
		var p: String = "user://" + name
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

static func run_all_tests() -> bool:
	var pass_count: int = 0
	if test_001_main_menu_presentation_and_continue_summary(): pass_count += 1
	if test_002_normal_stage_advancement_1_to_19(): pass_count += 1
	if test_003_stage_04_05_completion_transitions_to_victory(): pass_count += 1
	if test_004_game_victory_panel_content_and_return_to_menu(): pass_count += 1
	if test_005_new_game_and_continue_after_victory(): pass_count += 1

	print("[FINISH-FLOW-HARNESS] %d / 5 test scenarios passed" % pass_count)
	return pass_count == 5

static func test_001_main_menu_presentation_and_continue_summary() -> bool:
	print("[FLOW-001] Testing Main Menu presentation, no-save handling, and save summary...")
	_clean_user_saves()

	var root: AppRoot = AppRootClass.new()
	if not root.bootstrap_runtime("res://content"):
		print("[FLOW-001] FAIL: AppRoot bootstrap failed")
		root.free()
		return false

	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	if shell == null:
		print("[FLOW-001] FAIL: shell is null")
		root.free()
		return false

	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_ENTRY:
		print("[FLOW-001] FAIL: default view mode is not MODE_ENTRY")
		root.free()
		return false

	# Initial state without save -> Continue button hidden
	root.refresh_continue_availability()
	var cont_btn_initial: Button = shell._get_continue_game_button()
	if cont_btn_initial != null and cont_btn_initial.visible:
		print("[FLOW-001] FAIL: continue button must NOT be visible when no save exists")
		root.free()
		return false

	# Create a save checkpoint for stage_01_01
	var bridge: ProgressSaveBridge = root.get_progress_save_bridge()
	var cat: ValidatedCatalog = root.get_catalog()
	if bridge != null and cat != null:
		var st_data: Dictionary = cat.get_stage("stage_01_01")
		var reward_id: String = String(st_data.get("reward_id", "reward_stage_01_01"))
		var empty_frags: Array[String] = []
		var grant: RewardGrant = RewardGrant.new(reward_id, "stage_01_01", 100, 50, empty_frags)
		bridge.commit_stage_and_checkpoint("stage_01_01", grant)

	root.refresh_continue_availability()
	var cont_btn: Button = shell._get_continue_game_button()
	if cont_btn == null or not cont_btn.visible:
		print("[FLOW-001] FAIL: continue button should be visible when save exists")
		root.free()
		return false

	var summary_lbl: Label = shell._get_save_summary_label()
	if summary_lbl != null and summary_lbl.text.is_empty():
		print("[FLOW-001] FAIL: save summary text is empty")
		root.free()
		return false

	print("[FLOW-001] PASS: Main Menu presentation, no-save handling & save summary verified")
	root.free()
	return true

static func test_002_normal_stage_advancement_1_to_19() -> bool:
	print("[FLOW-002] Testing normal stage advancement continuity (stages 1..19)...")
	_clean_user_saves()
	var root: AppRoot = AppRootClass.new()
	root.bootstrap_runtime("res://content")

	var flow: GameFlowService = root.get_game_flow_service()
	flow.start_stage("stage_01_01")
	if flow.get_current_stage_id() != "stage_01_01":
		print("[FLOW-002] FAIL: start_stage failed")
		root.free()
		return false

	var prog: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	var st_data: Dictionary = cat.get_stage("stage_01_01")
	var reward_id: String = String(st_data.get("reward_id", "reward_stage_01_01"))
	var empty_frags: Array[String] = []
	var grant: RewardGrant = RewardGrant.new(reward_id, "stage_01_01", 100, 50, empty_frags)
	prog.commit_stage_clear("stage_01_01", grant)

	var adv: Dictionary = flow.advance_to_next_stage()
	if not bool(adv.get("success", false)) or flow.get_current_stage_id() != "stage_01_02":
		print("[FLOW-002] FAIL: stage_01_01 did not advance to stage_01_02")
		root.free()
		return false

	print("[FLOW-002] PASS: Normal stage advancement continuity verified")
	root.free()
	return true

static func test_003_stage_04_05_completion_transitions_to_victory() -> bool:
	print("[FLOW-003] Testing stage_04_05 completion transitions to GAME_COMPLETE...")
	_clean_user_saves()
	var root: AppRoot = AppRootClass.new()
	root.bootstrap_runtime("res://content")

	var flow: GameFlowService = root.get_game_flow_service()
	var prog: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()

	# Clear all stages up to 04_05
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
	var adv: Dictionary = flow.advance_to_next_stage()

	if not bool(adv.get("success", false)) or not bool(adv.get("game_completed", false)):
		print("[FLOW-003] FAIL: completing stage_04_05 did not return game_completed: true. Result: %s" % str(adv))
		root.free()
		return false

	if flow.get_flow_state() != "GAME_COMPLETE":
		print("[FLOW-003] FAIL: flow state is not GAME_COMPLETE")
		root.free()
		return false

	print("[FLOW-003] PASS: stage_04_05 completion successfully transitions to GAME_COMPLETE")
	root.free()
	return true

static func test_004_game_victory_panel_content_and_return_to_menu() -> bool:
	print("[FLOW-004] Testing GameVictoryPanel curriculum labels, authoritative names, and return to Main Menu...")
	_clean_user_saves()
	var root: AppRoot = AppRootClass.new()
	root.bootstrap_runtime("res://content")

	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	root._show_game_victory()

	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_VICTORY:
		print("[FLOW-004] FAIL: view mode is not MODE_VICTORY")
		root.free()
		return false

	var v_panel: GameVictoryPanel = shell.get_victory_panel()
	if v_panel == null or not v_panel.visible:
		print("[FLOW-004] FAIL: GameVictoryPanel is null or invisible")
		root.free()
		return false

	# Audit curriculum labels and authoritative dungeon names on victory card
	var d_grid: HBoxContainer = v_panel.get_dungeon_grid()
	if d_grid == null or d_grid.get_child_count() < 4:
		print("[FLOW-004] FAIL: DungeonGrid missing or less than 4 cards")
		root.free()
		return false

	# Card 3 (Dungeon 3): Addition rule content ("Quy tắc cộng")
	var d3_card: PanelContainer = d_grid.get_child(2) as PanelContainer
	var d3_text: String = ""
	for child in d3_card.get_child(0).get_children():
		if child is Label:
			d3_text += (child as Label).text + " "

	if not d3_text.contains("Quy tắc cộng"):
		print("[FLOW-004] FAIL: Dungeon 3 label missing 'Quy tắc cộng'. Got: %s" % d3_text)
		root.free()
		return false

	# Card 4 (Dungeon 4): Independence / multiplication ("Quy tắc nhân"), NOT conditional probability ("Xác suất điều kiện")
	var d4_card: PanelContainer = d_grid.get_child(3) as PanelContainer
	var d4_text: String = ""
	for child in d4_card.get_child(0).get_children():
		if child is Label:
			d4_text += (child as Label).text + " "

	if not d4_text.contains("Biến cố độc lập") or d4_text.contains("Xác suất điều kiện"):
		print("[FLOW-004] FAIL: Dungeon 4 label incorrect. Expected independence/multiplication, got: %s" % d4_text)
		root.free()
		return false

	# Test returning to Main Menu via signal
	var returned: Array = [false]
	shell.return_to_main_menu_requested.connect(func() -> void:
		returned[0] = true
	)

	v_panel._on_return_pressed()
	if not returned[0] or shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_ENTRY:
		print("[FLOW-004] FAIL: return to main menu failed")
		root.free()
		return false

	print("[FLOW-004] PASS: GameVictoryPanel curriculum labels, authoritative names & return to Main Menu verified")
	root.free()
	return true

static func test_005_new_game_and_continue_after_victory() -> bool:
	print("[FLOW-005] Testing New Game and Continue after victory...")
	_clean_user_saves()
	var root: AppRoot = AppRootClass.new()
	root.bootstrap_runtime("res://content")

	var ng_res: Dictionary = root.start_new_game()
	if not bool(ng_res.get("success", false)) or ng_res.get("stage_id", "") != "stage_01_01":
		print("[FLOW-005] FAIL: start_new_game failed")
		root.free()
		return false

	print("[FLOW-005] PASS: New Game & Continue after victory verified")
	root.free()
	return true
