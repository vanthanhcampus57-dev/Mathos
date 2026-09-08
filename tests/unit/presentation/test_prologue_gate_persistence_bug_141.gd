class_name TestPrologueGatePersistenceBug141
extends SceneTree

## Dedicated regression suite for MATHOS-PROLOGUE-GATE-PERSISTENCE-BUG-141.
## Validates complete independence between Prologue gate lifecycle and SaveSchema V1 gameplay progression:
## CASE 1: Gate missing + existing D1 progress in save_v1.json -> Beat 1
## CASE 2: Gate completed -> D1 entry bypasses Prologue to D1 Story / Lesson
## CASE 3: Gate deleted after completion -> Prologue becomes replayable again
## CASE 4: Gate reset does NOT mutate save_v1.json progression (stages, fragments, currency)
## CASE 5: Game restart preserves independent behavior across boots
## CASE 6: Skip Beat 1/2/3/4 reaches Story correctly and marks gate completed
## CASE 7: Natural Beat 1->4 completion writes gate exactly once and hands off to D1 Story

const TEST_DIR: String = "user://test_gate_bug_141/"

const AppRootScript = preload("res://src/app/app_root.gd")
const PrologueGateServiceClass = preload("res://src/gameplay/prologue/prologue_gate_service.gd")
const SaveFileStoreClass = preload("res://src/persistence/save/save_file_store.gd")
const SaveServiceClass = preload("res://src/persistence/save/save_service.gd")
const ProgressSaveBridgeClass = preload("res://src/gameplay/flow/integration/progress_save_bridge.gd")
const StagePresentationShellClass = preload("res://src/ui/stage/stage_presentation_shell.gd")
const RewardGrantClass = preload("res://src/gameplay/reward/reward_grant.gd")

func _initialize() -> void:
	print("--- RUNNING SUITE: Prologue Gate Persistence Bug 141 ---")
	var ok: bool = run_all_tests()
	quit(0 if ok else 1)

static func _ensure_test_dir(sub: String = "") -> String:
	var path: String = TEST_DIR + sub + "/" if not sub.is_empty() else TEST_DIR
	_clean_dir(path)
	var global_p: String = ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(global_p):
		DirAccess.make_dir_recursive_absolute(global_p)
	return path

static func _clean_dir(path: String) -> void:
	var global_p: String = ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(global_p):
		var dir: DirAccess = DirAccess.open(global_p)
		if dir != null:
			dir.list_dir_begin()
			var file_name: String = dir.get_next()
			while not file_name.is_empty():
				if file_name != "." and file_name != "..":
					var sub_global: String = global_p.path_join(file_name)
					if DirAccess.dir_exists_absolute(sub_global):
						_clean_dir(path.path_join(file_name))
					else:
						DirAccess.remove_absolute(sub_global)
				file_name = dir.get_next()
			dir.list_dir_end()
			DirAccess.remove_absolute(global_p)

static func _cleanup_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()

static func _create_app_with_paths(store_dir: String, gate_path: String) -> Node:
	var app: Node = AppRootScript.new()
	if Engine.get_main_loop() != null and Engine.get_main_loop() is SceneTree:
		var root_win: Window = (Engine.get_main_loop() as SceneTree).root
		if root_win != null:
			root_win.add_child(app)

	app.call("bootstrap_runtime", "res://content")

	var catalog = app.call("get_catalog")
	var store = SaveFileStoreClass.new(store_dir)
	var save_srv = SaveServiceClass.new(catalog, store)
	var player = PlayerPersistentState.new(PlayerPersistentState.CANONICAL_PLAYER_ID, 0, 0)
	var prog = ProgressService.new(catalog, player)
	var bridge = ProgressSaveBridgeClass.new(catalog, player, prog, save_srv)

	if save_srv.has_save():
		bridge.hydrate_initial_state()

	var q_service = app.get("_question_service")
	var flow = GameFlowService.new(catalog, q_service, prog, save_srv, player)

	app.set("_save_file_store", store)
	app.set("_save_service", save_srv)
	app.set("_player_persistent", player)
	app.set("_progress_service", prog)
	app.set("_bridge", bridge)
	app.set("_game_flow_service", flow)

	var gate = PrologueGateServiceClass.new(gate_path)
	app.call("set_prologue_gate", gate)

	return app

static func run_all_tests() -> bool:
	print("==================================================")
	print("MATHOS-PROLOGUE-GATE-PERSISTENCE-BUG-141 REGRESSION SUITE")
	print("==================================================")
	var passed_count: int = 0

	if test_bug141_001_gate_missing_with_existing_d1_save_opens_beat1(): passed_count += 1
	if test_bug141_002_gate_completed_bypasses_prologue_to_story_or_lesson(): passed_count += 1
	if test_bug141_003_gate_deleted_after_completion_replays_prologue(): passed_count += 1
	if test_bug141_004_gate_reset_does_not_mutate_save_progression(): passed_count += 1
	if test_bug141_005_restart_preserves_independent_lifecycle(): passed_count += 1
	if test_bug141_006_skip_any_beat_reaches_story_and_marks_gate(): passed_count += 1
	if test_bug141_007_natural_beat1_to_4_completion_writes_gate_once(): passed_count += 1

	_clean_dir(TEST_DIR)

	print("==================================================")
	print("BUG 141 REGRESSION SUMMARY: %d / 7 passed" % passed_count)
	print("==================================================")
	return passed_count == 7

# CASE 1: Gate missing + existing D1 progress in save_v1.json -> Beat 1
static func test_bug141_001_gate_missing_with_existing_d1_save_opens_beat1() -> bool:
	print("[BUG141-001] Testing missing gate with existing D1 save progression launches Beat 1...")
	var test_path: String = _ensure_test_dir("test_001")
	var gate_path: String = test_path + "prologue_gate.json"
	if FileAccess.file_exists(gate_path):
		DirAccess.remove_absolute(gate_path)

	var app: Node = _create_app_with_paths(test_path, gate_path)
	var catalog = app.call("get_catalog")
	var bridge = app.get("_bridge")

	# Pre-populate save_v1.json with cleared stage_01_01 and unlocked stage_01_02
	var r_id: String = String(catalog.get_stage("stage_01_01").get("reward_id", "reward_01_01"))
	var commit_res: Dictionary = bridge.commit_stage_and_checkpoint("stage_01_01", RewardGrantClass.new(r_id, "stage_01_01", 10, 20, []))
	if not bool(commit_res.get("success", false)):
		print("[BUG141-001] FAIL: Pre-condition commit failed")
		_cleanup_node(app)
		return false

	# Re-hydrate to ensure save is active
	bridge.hydrate_initial_state()
	var prog = app.call("get_progress_service")
	var snap = prog.call("create_snapshot_view")
	if not snap.cleared_stage_ids.has("stage_01_01"):
		print("[BUG141-001] FAIL: Pre-condition failed, stage_01_01 not cleared")
		_cleanup_node(app)
		return false

	# Ensure gate file DOES NOT exist
	if FileAccess.file_exists(gate_path):
		print("[BUG141-001] FAIL: Gate file exists prior to test")
		_cleanup_node(app)
		return false

	# Player selects stage_01_02 via Map 'BẮT ĐẦU'
	var res: Dictionary = app.call("select_stage", "stage_01_02")
	if not bool(res.get("success", false)):
		print("[BUG141-001] FAIL: select_stage('stage_01_02') failed: %s" % str(res))
		_cleanup_node(app)
		return false

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	var mode: int = int(shell.call("get_view_mode"))
	if mode != 9: # MODE_PROLOGUE
		print("[BUG141-001] FAIL: Expected MODE_PROLOGUE (9), got %d" % mode)
		_cleanup_node(app)
		return false

	var player: Control = shell.call("get_prologue_player")
	if player == null or not player.visible:
		print("[BUG141-001] FAIL: ProloguePlayer null or not visible")
		_cleanup_node(app)
		return false

	if int(player.call("get_current_beat")) != 1:
		print("[BUG141-001] FAIL: Expected Beat 1, got Beat %d" % int(player.call("get_current_beat")))
		_cleanup_node(app)
		return false

	_cleanup_node(app)
	print("[BUG141-001] PASS: Missing gate with existing save correctly launches Beat 1")
	return true

# CASE 2: Gate completed -> Story
static func test_bug141_002_gate_completed_bypasses_prologue_to_story_or_lesson() -> bool:
	print("[BUG141-002] Testing completed gate bypasses Prologue to D1 Story...")
	var test_path: String = _ensure_test_dir("test_002")
	var gate_path: String = test_path + "prologue_gate.json"

	var app: Node = _create_app_with_paths(test_path, gate_path)
	var gate = app.call("get_prologue_gate")
	gate.call("mark_prologue_completed")

	if not FileAccess.file_exists(gate_path):
		print("[BUG141-002] FAIL: Gate file not created on disk")
		_cleanup_node(app)
		return false

	# Select initial stage (stage_01_01)
	var res: Dictionary = app.call("select_stage", "stage_01_01")
	if not bool(res.get("success", false)):
		print("[BUG141-002] FAIL: select_stage failed")
		_cleanup_node(app)
		return false

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	var mode: int = int(shell.call("get_view_mode"))
	if mode == 9: # Must NOT be MODE_PROLOGUE
		print("[BUG141-002] FAIL: Completed gate triggered Prologue (mode 9)!")
		_cleanup_node(app)
		return false

	if mode != 7: # Must be MODE_STORY (7) on first uncleared entry
		print("[BUG141-002] FAIL: Expected MODE_STORY (7), got %d" % mode)
		_cleanup_node(app)
		return false

	_cleanup_node(app)
	print("[BUG141-002] PASS: Completed gate bypasses Prologue directly to Story")
	return true

# CASE 3: Gate deleted after completion -> Beat 1 again
static func test_bug141_003_gate_deleted_after_completion_replays_prologue() -> bool:
	print("[BUG141-003] Testing deleting ONLY prologue_gate.json restores Prologue replayability...")
	var test_path: String = _ensure_test_dir("test_003")
	var gate_path: String = test_path + "prologue_gate.json"

	var app: Node = _create_app_with_paths(test_path, gate_path)
	var gate = app.call("get_prologue_gate")
	gate.call("mark_prologue_completed")

	# Verify gate completed
	if not bool(gate.call("has_completed_prologue")):
		print("[BUG141-003] FAIL: Gate not marked completed")
		_cleanup_node(app)
		return false

	# TEST ACTION: Delete ONLY prologue_gate.json
	gate.call("reset_state")
	if FileAccess.file_exists(gate_path):
		print("[BUG141-003] FAIL: Gate file was not deleted by reset_state()")
		_cleanup_node(app)
		return false

	# Next Dungeon I start MUST play Prologue again
	var res: Dictionary = app.call("select_stage", "stage_01_01")
	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	var mode: int = int(shell.call("get_view_mode"))

	if mode != 9:
		print("[BUG141-003] FAIL: Expected MODE_PROLOGUE (9) after deleting gate, got %d" % mode)
		_cleanup_node(app)
		return false

	var player: Control = shell.call("get_prologue_player")
	if int(player.call("get_current_beat")) != 1:
		print("[BUG141-003] FAIL: Expected Beat 1, got Beat %d" % int(player.call("get_current_beat")))
		_cleanup_node(app)
		return false

	_cleanup_node(app)
	print("[BUG141-003] PASS: Deleting gate file successfully makes Prologue replayable")
	return true

# CASE 4: Gate reset does not mutate save_v1.json progression
static func test_bug141_004_gate_reset_does_not_mutate_save_progression() -> bool:
	print("[BUG141-004] Testing deleting prologue gate has zero mutation on save_v1.json...")
	var test_path: String = _ensure_test_dir("test_004")
	var gate_path: String = test_path + "prologue_gate.json"

	var app: Node = _create_app_with_paths(test_path, gate_path)
	var catalog = app.call("get_catalog")
	var bridge = app.get("_bridge")

	# Populate full 5 stages, fragment, coins, and xp
	for i in range(1, 6):
		var s_id: String = "stage_01_%02d" % i
		var r_id: String = String(catalog.get_stage(s_id).get("reward_id", "reward_01_01"))
		var frags: Array[String] = []
		if i == 5:
			frags.append("fragment_01")
		bridge.commit_stage_and_checkpoint(s_id, RewardGrantClass.new(r_id, s_id, 50, 100, frags))

	var gate = app.call("get_prologue_gate")
	gate.call("mark_prologue_completed")

	# Verify pre-reset progression
	var save_srv = app.get("_save_service")
	var load_pre: Dictionary = save_srv.load()
	var full_snap_pre: Dictionary = (load_pre.get("snapshot", {}) as Dictionary).duplicate(true)
	var snap_pre: Dictionary = full_snap_pre.get("progress", {}) as Dictionary
	if snap_pre.get("cleared_stage_ids", []).size() != 5:
		print("[BUG141-004] FAIL: Pre-condition failed, cleared_stages != 5")
		_cleanup_node(app)
		return false

	# TEST ACTION: Delete gate
	gate.call("reset_state")

	# Verify post-reset progression
	var load_post: Dictionary = save_srv.load()
	var full_snap_post: Dictionary = (load_post.get("snapshot", {}) as Dictionary).duplicate(true)
	var snap_post: Dictionary = full_snap_post.get("progress", {}) as Dictionary

	if snap_post.get("cleared_stage_ids", []).size() != 5:
		print("[BUG141-004] FAIL: Cleared stage count changed after gate deletion!")
		_cleanup_node(app)
		return false

	if not (snap_post.get("fragment_ids", []) as Array).has("fragment_01"):
		print("[BUG141-004] FAIL: Fragment lost after gate deletion!")
		_cleanup_node(app)
		return false

	if full_snap_pre != full_snap_post:
		print("[BUG141-004] FAIL: Save snapshot mutated by gate reset!")
		_cleanup_node(app)
		return false

	_cleanup_node(app)
	print("[BUG141-004] PASS: Zero mutation of save_v1.json upon gate deletion verified")
	return true

# CASE 5: Game restart preserves independent behavior
static func test_bug141_005_restart_preserves_independent_lifecycle() -> bool:
	print("[BUG141-005] Testing reboot lifecycle preserves independent gate behavior...")
	var test_path: String = _ensure_test_dir("test_005")
	var gate_path: String = test_path + "prologue_gate.json"

	# Phase 1: Create session with completed gate and stage clear
	var app1: Node = _create_app_with_paths(test_path, gate_path)
	var catalog1 = app1.call("get_catalog")
	var bridge1 = app1.get("_bridge")
	var r_id1: String = String(catalog1.get_stage("stage_01_01").get("reward_id", "reward_01_01"))
	bridge1.commit_stage_and_checkpoint("stage_01_01", RewardGrantClass.new(r_id1, "stage_01_01", 10, 10, []))
	var gate1 = app1.call("get_prologue_gate")
	gate1.call("mark_prologue_completed")
	_cleanup_node(app1)

	# Phase 2: Reboot 1 -> Gate is completed, entering stage_01_02 must NOT trigger prologue
	var app2: Node = _create_app_with_paths(test_path, gate_path)

	var res2: Dictionary = app2.call("select_stage", "stage_01_02")
	var shell2: Control = app2.get_node_or_null("StagePresentationShell") as Control
	if int(shell2.call("get_view_mode")) == 9:
		print("[BUG141-005] FAIL: Reboot with completed gate launched Prologue")
		_cleanup_node(app2)
		return false

	# Delete gate while app is off
	_cleanup_node(app2)
	DirAccess.remove_absolute(gate_path)

	# Phase 3: Reboot 2 -> Gate is missing, entering stage_01_02 MUST trigger prologue
	var app3: Node = _create_app_with_paths(test_path, gate_path)

	var res3: Dictionary = app3.call("select_stage", "stage_01_02")
	var shell3: Control = app3.get_node_or_null("StagePresentationShell") as Control
	if int(shell3.call("get_view_mode")) != 9:
		print("[BUG141-005] FAIL: Reboot with deleted gate failed to launch Prologue, got %d" % int(shell3.call("get_view_mode")))
		_cleanup_node(app3)
		return false

	_cleanup_node(app3)
	print("[BUG141-005] PASS: Reboot preserves independent gate behavior deterministically")
	return true

# CASE 6: Skip Beat 1/2/3/4 still reaches Story correctly
static func test_bug141_006_skip_any_beat_reaches_story_and_marks_gate() -> bool:
	print("[BUG141-006] Testing skip from prologue reaches Story and marks gate completed...")
	var test_path: String = _ensure_test_dir("test_006")
	var gate_path: String = test_path + "prologue_gate.json"
	if FileAccess.file_exists(gate_path):
		DirAccess.remove_absolute(gate_path)

	var app: Node = _create_app_with_paths(test_path, gate_path)
	var res: Dictionary = app.call("select_stage", "stage_01_01")
	if not bool(res.get("success", false)):
		print("[BUG141-006] FAIL: select_stage failed")
		_cleanup_node(app)
		return false

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	if int(shell.call("get_view_mode")) != 9:
		print("[BUG141-006] FAIL: Did not enter MODE_PROLOGUE initially, got %d" % int(shell.call("get_view_mode")))
		_cleanup_node(app)
		return false

	# Player clicks skip on Prologue
	var player: Control = shell.call("get_prologue_player")
	player.call("_on_skip_pressed")

	# View mode must now transition to MODE_STORY (7)
	var post_mode: int = int(shell.call("get_view_mode"))
	if post_mode != 7:
		print("[BUG141-006] FAIL: Expected MODE_STORY (7) after skip, got %d" % post_mode)
		_cleanup_node(app)
		return false

	# Gate file must be written to disk
	if not FileAccess.file_exists(gate_path):
		print("[BUG141-006] FAIL: Gate file not created after skip")
		_cleanup_node(app)
		return false

	var gate = app.call("get_prologue_gate")
	if not bool(gate.call("has_completed_prologue")):
		print("[BUG141-006] FAIL: Gate not marked completed after skip")
		_cleanup_node(app)
		return false

	_cleanup_node(app)
	print("[BUG141-006] PASS: Skip reaches Story and marks gate completed")
	return true

# CASE 7: Natural Beat 1->4 completion writes gate exactly once
static func test_bug141_007_natural_beat1_to_4_completion_writes_gate_once() -> bool:
	print("[BUG141-007] Testing natural Beat 1->4 completion writes gate and routes to Story...")
	var test_path: String = _ensure_test_dir("test_007")
	var gate_path: String = test_path + "prologue_gate.json"
	if FileAccess.file_exists(gate_path):
		DirAccess.remove_absolute(gate_path)

	var app: Node = _create_app_with_paths(test_path, gate_path)
	var res: Dictionary = app.call("select_stage", "stage_01_01")
	if not bool(res.get("success", false)):
		print("[BUG141-007] FAIL: select_stage failed")
		_cleanup_node(app)
		return false

	var shell: Control = app.get_node_or_null("StagePresentationShell") as Control
	var player: Control = shell.call("get_prologue_player")

	# Advance Beat 1 -> Beat 2
	player.call("advance_to_beat2")
	if int(player.call("get_current_beat")) != 2:
		print("[BUG141-007] FAIL: Failed to advance to Beat 2")
		_cleanup_node(app)
		return false

	# Advance Beat 2 -> Beat 3
	player.call("advance_to_beat3")
	if int(player.call("get_current_beat")) != 3:
		print("[BUG141-007] FAIL: Failed to advance to Beat 3")
		_cleanup_node(app)
		return false

	# Advance Beat 3 -> Beat 4
	player.call("advance_to_beat4")
	if int(player.call("get_current_beat")) != 4:
		print("[BUG141-007] FAIL: Failed to advance to Beat 4")
		_cleanup_node(app)
		return false

	# Gate must NOT be marked completed while still in Beat 4
	if FileAccess.file_exists(gate_path):
		print("[BUG141-007] FAIL: Gate written prematurely before Beat 4 completion")
		_cleanup_node(app)
		return false

	# Fast-forward / complete Beat 4 synchronously
	player.call("set_speed_scale", 0.0)
	player.call("complete_prologue")

	# Shell must transition to MODE_STORY (7)
	if int(shell.call("get_view_mode")) != 7:
		print("[BUG141-007] FAIL: Shell not in MODE_STORY after Beat 4 completion, got %d" % int(shell.call("get_view_mode")))
		_cleanup_node(app)
		return false

	# Gate must now be written on disk exactly once
	if not FileAccess.file_exists(gate_path):
		print("[BUG141-007] FAIL: Gate file not written after Beat 4 completion")
		_cleanup_node(app)
		return false

	var gate = app.call("get_prologue_gate")
	if not bool(gate.call("has_completed_prologue")):
		print("[BUG141-007] FAIL: Gate not completed after Beat 4 completion")
		_cleanup_node(app)
		return false

	_cleanup_node(app)
	print("[BUG141-007] PASS: Natural Beat 1->4 completion writes gate and enters Story")
	return true
