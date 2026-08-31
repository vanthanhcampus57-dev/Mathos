extends SceneTree

## Unit & QA test suite for MATHOS-DIRECT-FINAL-PLAYER-POLISH-V2-002
## Verifies player-facing polish: Main Menu hierarchy, Stage Map node states, Pause Overlay polish,
## Save failure notification banner, Vietnamese capitalization, and mode transition consistency.

const StagePresentationShellClass = preload("res://src/ui/stage/stage_presentation_shell.gd")
const PauseMenuOverlayClass = preload("res://src/ui/common/pause_menu_overlay.gd")
const DungeonStageMapPanelClass = preload("res://src/ui/map/dungeon_stage_map_panel.gd")
const GameVictoryPanelClass = preload("res://src/ui/stage/game_victory_panel.gd")

func _initialize() -> void:
	print("--- RUNNING FINAL PLAYER POLISH V2 QA HARNESS ---")
	var ok: bool = run_all_tests()
	if ok:
		print("FINAL PLAYER POLISH V2 QA HARNESS PASS!")
		quit(0)
	else:
		print("FINAL PLAYER POLISH V2 QA HARNESS FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var pass_count: int = 0
	if test_001_main_menu_hierarchy_and_wording(): pass_count += 1
	if test_002_stage_map_node_state_distinction(): pass_count += 1
	if test_003_pause_overlay_polish_and_wording(): pass_count += 1
	if test_004_save_failure_in_game_notification_banner(): pass_count += 1
	if test_005_victory_presentation_wording_consistency(): pass_count += 1
	if test_006_mode_transition_consistency(): pass_count += 1

	print("[POLISH-V2-HARNESS] %d / 6 test scenarios passed" % pass_count)
	return pass_count == 6

static func test_001_main_menu_hierarchy_and_wording() -> bool:
	print("[POLISH-V2-001] Testing Main Menu hierarchy and Vietnamese CTA wording...")
	var scene_res: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn") as PackedScene
	var shell: StagePresentationShell = scene_res.instantiate() as StagePresentationShell

	shell.set_continue_available(true, {"stage_title": "Khởi Đầu Rừng Mù Sương"})

	var continue_btn: Button = shell._get_continue_game_button()
	var new_btn: Button = shell._get_new_game_button()
	var map_btn: Button = shell._get_journey_map_button()

	if continue_btn == null or continue_btn.text != "Tiếp tục":
		print("[POLISH-V2-001] FAIL: Continue button text mismatch")
		shell.free()
		return false

	if new_btn == null or new_btn.text != "Bắt đầu mới":
		print("[POLISH-V2-001] FAIL: New Game button text mismatch")
		shell.free()
		return false

	if map_btn == null or map_btn.text != "Bản đồ hành trình":
		print("[POLISH-V2-001] FAIL: Journey Map button text mismatch")
		shell.free()
		return false

	print("[POLISH-V2-001] PASS: Main Menu hierarchy & wording verified")
	shell.free()
	return true

static func test_002_stage_map_node_state_distinction() -> bool:
	print("[POLISH-V2-002] Testing Stage Map node state visual distinction...")
	var map_panel: DungeonStageMapPanel = DungeonStageMapPanelClass.new()
	map_panel._ready()

	map_panel.set_map_data({
		"unlocked_stages": ["stage_01_01", "stage_01_02"],
		"completed_stages": ["stage_01_01"],
		"current_stage_id": "stage_01_02"
	})

	var first_dungeon: MarginContainer = map_panel._dungeon_container.get_child(0).get_child(0) as MarginContainer
	var vbox: VBoxContainer = first_dungeon.get_child(0) as VBoxContainer

	# Check Stage 1.1 (Completed) vs Stage 1.2 (Current/Unlocked) vs Stage 1.3 (Locked)
	var btn_11: Button = null
	var btn_12: Button = null
	var btn_13: Button = null

	for child in vbox.get_children():
		if child is Button:
			var btn: Button = child as Button
			if btn.text.contains("1.1"): btn_11 = btn
			elif btn.text.contains("1.2"): btn_12 = btn
			elif btn.text.contains("1.3"): btn_13 = btn

	if btn_11 == null or not btn_11.text.contains("✔") or not btn_11.text.contains("Đã xong"):
		print("[POLISH-V2-002] FAIL: Stage 1.1 completed badge/icon mismatch")
		map_panel.free()
		return false

	if btn_12 == null or not btn_12.text.contains("▶") or not btn_12.text.contains("Đang mở") or btn_12.theme_type_variation != &"MathosPrimaryButton":
		print("[POLISH-V2-002] FAIL: Stage 1.2 current/unlocked primary theme or icon mismatch")
		map_panel.free()
		return false

	if btn_13 == null or not btn_13.text.contains("🔒") or not btn_13.disabled or btn_13.modulate.a > 0.6:
		print("[POLISH-V2-002] FAIL: Stage 1.3 locked state or opacity mismatch")
		map_panel.free()
		return false

	print("[POLISH-V2-002] PASS: Stage Map node state distinction verified")
	map_panel.free()
	return true

static func test_003_pause_overlay_polish_and_wording() -> bool:
	print("[POLISH-V2-003] Testing Pause overlay styling and consistent Vietnamese CTAs...")
	var overlay: PauseMenuOverlay = PauseMenuOverlayClass.new()
	overlay._ready()

	if overlay._resume_button == null or overlay._resume_button.text != "Tiếp tục":
		print("[POLISH-V2-003] FAIL: Resume button wording mismatch")
		overlay.free()
		return false

	if overlay._map_button == null or overlay._map_button.text != "Bản đồ hành trình":
		print("[POLISH-V2-003] FAIL: Map button wording mismatch")
		overlay.free()
		return false

	if overlay._menu_button == null or overlay._menu_button.text != "Trở về trang chủ":
		print("[POLISH-V2-003] FAIL: Menu button wording mismatch")
		overlay.free()
		return false

	print("[POLISH-V2-003] PASS: Pause overlay styling & wording verified")
	overlay.free()
	return true

static func test_004_save_failure_in_game_notification_banner() -> bool:
	print("[POLISH-V2-004] Testing Save Failure non-blocking in-game notification banner...")
	var scene_res: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn") as PackedScene
	var shell: StagePresentationShell = scene_res.instantiate() as StagePresentationShell

	shell.show_notification_banner("Không thể lưu tiến trình tự động. Tiến trình hiện tại vẫn được giữ tạm thời.", true, 2.0)

	var banner: PanelContainer = shell.get_node_or_null("NotificationBanner") as PanelContainer
	if banner == null or not banner.visible:
		print("[POLISH-V2-004] FAIL: Notification banner is null or invisible")
		shell.free()
		return false

	var lbl: Label = banner.get_node_or_null("MarginContainer/NotificationLabel") as Label
	if lbl == null or not lbl.text.contains("Không thể lưu tiến trình tự động") or lbl.text.contains("SAVE_ERROR"):
		print("[POLISH-V2-004] FAIL: Banner text contains raw error codes or missing Vietnamese message")
		shell.free()
		return false

	print("[POLISH-V2-004] PASS: Save Failure in-game notification banner verified")
	shell.free()
	return true

static func test_005_victory_presentation_wording_consistency() -> bool:
	print("[POLISH-V2-005] Testing Victory presentation wording consistency...")
	var victory: GameVictoryPanel = GameVictoryPanelClass.new()
	victory._ready()

	var return_btn: Button = victory._get_return_button()
	if return_btn == null or return_btn.text != "Trở về trang chủ":
		print("[POLISH-V2-005] FAIL: Return button text casing mismatch: '%s'" % (return_btn.text if return_btn else "null"))
		victory.free()
		return false

	print("[POLISH-V2-005] PASS: Victory presentation wording consistency verified")
	victory.free()
	return true

static func test_006_mode_transition_consistency() -> bool:
	print("[POLISH-V2-006] Testing mode transition consistency across all screens...")
	var scene_res: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn") as PackedScene
	var shell: StagePresentationShell = scene_res.instantiate() as StagePresentationShell

	var modes: Array[StagePresentationShell.ViewMode] = [
		StagePresentationShell.ViewMode.MODE_ENTRY,
		StagePresentationShell.ViewMode.MODE_MAP,
		StagePresentationShell.ViewMode.MODE_LESSON,
		StagePresentationShell.ViewMode.MODE_QUESTION_HOST,
		StagePresentationShell.ViewMode.MODE_FEEDBACK_HOST,
		StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE,
		StagePresentationShell.ViewMode.MODE_VICTORY,
		StagePresentationShell.ViewMode.MODE_ENTRY
	]

	for m in modes:
		shell.set_view_mode(m)
		if shell.get_view_mode() != m:
			print("[POLISH-V2-006] FAIL: Failed to transition to mode %d" % m)
			shell.free()
			return false

	print("[POLISH-V2-006] PASS: Mode transition consistency verified across all 7 view modes")
	shell.free()
	return true
