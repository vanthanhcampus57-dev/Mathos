extends SceneTree

## Unit tests for Batch 2A components: DungeonStageMapPanel and PauseMenuOverlay.

const DungeonStageMapPanelClass = preload("res://src/ui/map/dungeon_stage_map_panel.gd")
const PauseMenuOverlayClass = preload("res://src/ui/common/pause_menu_overlay.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func run_all_tests() -> bool:
	var pass_count: int = 0
	if test_stage_map_shows_4_dungeons_and_20_stages(): pass_count += 1
	if test_locked_stage_cannot_start(): pass_count += 1
	if test_unlocked_and_completed_stage_emits_stage_id(): pass_count += 1
	if test_pause_resume_and_esc_toggle(): pass_count += 1
	if test_pause_menu_navigation_signals(): pass_count += 1

	print("[BATCH-2A-HARNESS] %d / 5 tests passed" % pass_count)
	return pass_count == 5

static func test_stage_map_shows_4_dungeons_and_20_stages() -> bool:
	print("[BATCH-2A-001] Testing Stage Map shows 4 dungeons and 20 stages...")
	var map_panel: DungeonStageMapPanel = DungeonStageMapPanelClass.new()
	map_panel._ready()

	if map_panel._dungeon_container == null:
		print("[BATCH-2A-001] FAIL: _dungeon_container is null")
		return false

	var d_count: int = map_panel._dungeon_container.get_child_count()
	if d_count != 4:
		print("[BATCH-2A-001] FAIL: expected 4 dungeon columns, got %d" % d_count)
		return false

	var total_stage_buttons: int = 0
	for dun in map_panel._dungeon_container.get_children():
		var margin: MarginContainer = dun.get_child(0) as MarginContainer
		var vbox: VBoxContainer = margin.get_child(0) as VBoxContainer
		for child in vbox.get_children():
			if child is Button:
				total_stage_buttons += 1

	if total_stage_buttons != 20:
		print("[BATCH-2A-001] FAIL: expected 20 total stage buttons, got %d" % total_stage_buttons)
		return false

	print("[BATCH-2A-001] PASS: 4 dungeons and 20 stages verified")
	return true

static func test_locked_stage_cannot_start() -> bool:
	print("[BATCH-2A-002] Testing locked stage cannot start...")
	var map_panel: DungeonStageMapPanel = DungeonStageMapPanelClass.new()
	map_panel._ready()
	map_panel.set_map_data({
		"unlocked_stages": ["stage_01_01"],
		"completed_stages": [],
		"current_stage_id": "stage_01_01"
	})

	var emitted: Array = []
	map_panel.stage_selected.connect(func(sid: String) -> void:
		emitted.append(sid)
	)

	# Try selecting locked stage_04_05
	map_panel._on_stage_button_pressed("stage_04_05")
	if not emitted.is_empty():
		print("[BATCH-2A-002] FAIL: locked stage emitted stage_selected!")
		return false

	print("[BATCH-2A-002] PASS: locked stage cannot start verified")
	return true

static func test_unlocked_and_completed_stage_emits_stage_id() -> bool:
	print("[BATCH-2A-003] Testing unlocked and completed stage emissions...")
	var map_panel: DungeonStageMapPanel = DungeonStageMapPanelClass.new()
	map_panel._ready()
	map_panel.set_map_data({
		"unlocked_stages": ["stage_01_01", "stage_01_02"],
		"completed_stages": ["stage_01_01"],
		"current_stage_id": "stage_01_02"
	})

	var emitted: Array = []
	map_panel.stage_selected.connect(func(sid: String) -> void:
		emitted.append(sid)
	)

	# Click completed stage_01_01 (replay)
	map_panel._on_stage_button_pressed("stage_01_01")
	if emitted.size() != 1 or emitted[0] != "stage_01_01":
		print("[BATCH-2A-003] FAIL: completed replay stage emission failed")
		return false

	# Click unlocked active stage_01_02
	map_panel._on_stage_button_pressed("stage_01_02")
	if emitted.size() != 2 or emitted[1] != "stage_01_02":
		print("[BATCH-2A-003] FAIL: unlocked stage emission failed")
		return false

	print("[BATCH-2A-003] PASS: unlocked and completed stage selection verified")
	return true

static func test_pause_resume_and_esc_toggle() -> bool:
	print("[BATCH-2A-004] Testing pause show/hide/toggle and resume signal...")
	var overlay: PauseMenuOverlay = PauseMenuOverlayClass.new()
	overlay._ready()

	if overlay.is_paused():
		print("[BATCH-2A-004] FAIL: overlay should start hidden")
		return false

	var resume_count: Array = [0]
	overlay.resume_requested.connect(func() -> void:
		resume_count[0] += 1
	)

	overlay.show_pause()
	if not overlay.is_paused():
		print("[BATCH-2A-004] FAIL: show_pause failed")
		return false

	# Toggle off -> emits resume_requested
	overlay.toggle_pause()
	if overlay.is_paused():
		print("[BATCH-2A-004] FAIL: toggle_pause off failed")
		return false

	if resume_count[0] != 1:
		print("[BATCH-2A-004] FAIL: resume_requested signal count mismatch: %d" % resume_count[0])
		return false

	print("[BATCH-2A-004] PASS: pause resume and toggle verified")
	return true

static func test_pause_menu_navigation_signals() -> bool:
	print("[BATCH-2A-005] Testing Pause Menu stage_map and main_menu signals...")
	var overlay: PauseMenuOverlay = PauseMenuOverlayClass.new()
	overlay._ready()

	var map_count: Array = [0]
	var menu_count: Array = [0]

	overlay.stage_map_requested.connect(func() -> void:
		map_count[0] += 1
	)
	overlay.main_menu_requested.connect(func() -> void:
		menu_count[0] += 1
	)

	overlay.show_pause()
	overlay._map_button.pressed.emit()
	if map_count[0] != 1 or overlay.is_paused():
		print("[BATCH-2A-005] FAIL: stage_map_requested signal or auto-hide failed")
		return false

	overlay.show_pause()
	overlay._menu_button.pressed.emit()
	if menu_count[0] != 1 or overlay.is_paused():
		print("[BATCH-2A-005] FAIL: main_menu_requested signal or auto-hide failed")
		return false

	print("[BATCH-2A-005] PASS: pause menu navigation signals verified")
	return true
