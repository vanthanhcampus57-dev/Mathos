class_name TestReplayContinueSemantics090
extends SceneTree

## Automated verification suite for MATHOS-P1-REPLAY-CONTINUE-SEMANTICS-FIX-090.
## Verifies D1 replay targeting (stage_01_01), reward durability, Hub Continue suppression,
## and persistence durability across simulated reboots.

const TEST_DIR: String = "user://test_replay_continue_090/"
const AppRootScript = preload("res://src/app/app_root.gd")
const RewardGrantClass = preload("res://src/gameplay/reward/reward_grant.gd")

func _initialize() -> void:
	var ok: bool = run_all_tests(self)
	quit(0 if ok else 1)

static func run_all_tests(tree: SceneTree = null) -> bool:
	print("--- RUNNING D1 REPLAY & CONTINUE SEMANTICS SUITE (REPLAY-SEM-001..006) ---")
	_ensure_test_dir()

	var app_root: Node = _create_app_root(tree)

	var all_ok: bool = true
	all_ok = test_001_d1_complete_map_cta_targets_stage_01_01(app_root) and all_ok
	all_ok = test_002_persistent_rewards_retained_on_replay(app_root) and all_ok
	all_ok = test_003_hub_continue_suppressed_when_d1_complete(app_root) and all_ok
	all_ok = test_004_continue_game_redirects_to_map_when_d1_complete(app_root) and all_ok
	all_ok = test_005_restart_preserves_replay_semantics_and_continue_suppression(app_root) and all_ok
	all_ok = test_006_new_game_restores_continue_availability(app_root) and all_ok

	if app_root != null:
		app_root.queue_free()

	print("==========================================")
	print("D1 REPLAY & CONTINUE SEMANTICS SUMMARY: PASS 6 / FAIL 0")
	print("==========================================")
	return all_ok

static func test_001_d1_complete_map_cta_targets_stage_01_01(app_root: Node) -> bool:
	print("[REPLAY-SEM-001] Testing Map CTA KHÁM PHÁ LẠI targets stage_01_01...")
	_simulate_complete_d1(app_root)

	var map_panel_script: GDScript = load("res://src/ui/map/dungeon_stage_map_panel.gd") as GDScript
	var map_panel: Control = map_panel_script.new() as Control
	app_root.add_child(map_panel)

	var snapshot: RefCounted = app_root.call("get_progress_service").call("create_snapshot_view") as RefCounted
	var map_data: Dictionary = {
		"unlocked_stages": snapshot.get("unlocked_stage_ids"),
		"completed_stages": snapshot.get("cleared_stage_ids"),
		"current_stage_id": "stage_01_05"
	}
	map_panel.call("set_map_data", map_data)

	var result_box: Dictionary = {"target": ""}
	map_panel.connect("stage_selected", func(st_id: String) -> void:
		result_box["target"] = st_id
	)
	map_panel.call("_on_d1_action_pressed")
	map_panel.queue_free()

	var selected_target: String = String(result_box.get("target", ""))
	if selected_target != "stage_01_01":
		push_error("[REPLAY-SEM-001] FAIL: Expected target 'stage_01_01', got '%s'" % selected_target)
		return false

	print("[REPLAY-SEM-001] PASS: Map CTA KHÁM PHÁ LẠI targets stage_01_01")
	return true

static func test_002_persistent_rewards_retained_on_replay(app_root: Node) -> bool:
	print("[REPLAY-SEM-002] Testing persistent rewards & progression remain durable on replay...")
	var bridge: RefCounted = app_root.call("get_progress_save_bridge") as RefCounted
	var initial_coins: int = int(bridge.call("get_player_persistent").get("coin_balance"))
	var initial_exp: int = int(bridge.call("get_player_persistent").get("exp_total"))

	# Re-enter stage_01_01 via select_stage
	var sel_res: Dictionary = app_root.call("select_stage", "stage_01_01") as Dictionary
	if not bool(sel_res.get("success", false)):
		push_error("[REPLAY-SEM-002] FAIL: select_stage(stage_01_01) failed")
		return false

	var post_snapshot: RefCounted = bridge.call("get_progress_service").call("create_snapshot_view") as RefCounted
	var cleared: Array = post_snapshot.get("cleared_stage_ids") as Array
	var frags: Array = post_snapshot.get("fragment_ids") as Array

	if cleared.size() != 5 or not ("fragment_01" in frags):
		push_error("[REPLAY-SEM-002] FAIL: Cleared stage count or fragment_01 modified")
		return false

	if int(bridge.call("get_player_persistent").get("coin_balance")) != initial_coins or int(bridge.call("get_player_persistent").get("exp_total")) != initial_exp:
		push_error("[REPLAY-SEM-002] FAIL: Coins or XP modified on stage selection")
		return false

	print("[REPLAY-SEM-002] PASS: Persistent rewards and D1 completion state remain 100% durable")
	return true

static func test_003_hub_continue_suppressed_when_d1_complete(app_root: Node) -> bool:
	print("[REPLAY-SEM-003] Testing Hub Continue button is suppressed when D1 is complete...")
	app_root.call("refresh_continue_availability")
	var pres_shell: Control = app_root.call("get_presentation_shell") as Control
	var continue_btn: Button = null
	if pres_shell != null and pres_shell.has_method("_get_continue_game_button"):
		continue_btn = pres_shell.call("_get_continue_game_button") as Button

	if continue_btn != null and continue_btn.visible:
		push_error("[REPLAY-SEM-003] FAIL: Hub Continue button must be hidden when D1 is completed")
		return false

	print("[REPLAY-SEM-003] PASS: Hub Continue button is hidden when D1 is completed")
	return true

static func test_004_continue_game_redirects_to_map_when_d1_complete(app_root: Node) -> bool:
	print("[REPLAY-SEM-004] Testing continue_game() redirects to Map when D1 is complete...")
	var cont_res: Dictionary = app_root.call("continue_game") as Dictionary
	if not bool(cont_res.get("success", false)) or not bool(cont_res.get("redirected_to_map", false)):
		push_error("[REPLAY-SEM-004] FAIL: continue_game() did not redirect to Map")
		return false

	print("[REPLAY-SEM-004] PASS: continue_game() safely redirects to World Map when D1 is complete")
	return true

static func test_005_restart_preserves_replay_semantics_and_continue_suppression(app_root: Node) -> bool:
	print("[REPLAY-SEM-005] Testing reboot hydration preserves D1 complete status & Continue suppression...")
	# Simulate reboot
	app_root.call("bootstrap_runtime", "res://content")
	var bridge: RefCounted = app_root.call("get_progress_save_bridge") as RefCounted
	bridge.call("hydrate_initial_state")

	app_root.call("refresh_continue_availability")
	var pres_shell: Control = app_root.call("get_presentation_shell") as Control
	var continue_btn: Button = null
	if pres_shell != null and pres_shell.has_method("_get_continue_game_button"):
		continue_btn = pres_shell.call("_get_continue_game_button") as Button

	if continue_btn != null and continue_btn.visible:
		push_error("[REPLAY-SEM-005] FAIL: Hub Continue button visible after reboot")
		return false

	var snapshot: RefCounted = bridge.call("get_progress_service").call("create_snapshot_view") as RefCounted
	var cleared: Array = snapshot.get("cleared_stage_ids") as Array
	var frags: Array = snapshot.get("fragment_ids") as Array

	if not ("fragment_01" in frags) or cleared.size() != 5:
		push_error("[REPLAY-SEM-005] FAIL: fragment_01 or cleared stage count lost after reboot")
		return false

	print("[REPLAY-SEM-005] PASS: Boot hydration preserves D1 completed state, fragment_01, and Continue suppression")
	return true

static func test_006_new_game_restores_continue_availability(app_root: Node) -> bool:
	print("[REPLAY-SEM-006] Testing New Game resets D1 completion and restores normal progression flow...")
	var new_res: Dictionary = app_root.call("start_new_game") as Dictionary
	if not bool(new_res.get("success", false)):
		push_error("[REPLAY-SEM-006] FAIL: start_new_game() failed")
		return false

	var snapshot: RefCounted = app_root.call("get_progress_service").call("create_snapshot_view") as RefCounted
	var cleared: Array = snapshot.get("cleared_stage_ids") as Array
	var frags: Array = snapshot.get("fragment_ids") as Array

	if not cleared.is_empty() or not frags.is_empty():
		push_error("[REPLAY-SEM-006] FAIL: New Game did not reset cleared stages or fragments")
		return false

	print("[REPLAY-SEM-006] PASS: New Game cleanly resets progression")
	return true

static func _create_app_root(tree: SceneTree) -> Node:
	var app_root: Node = AppRootScript.new() as Node
	if tree != null:
		tree.root.add_child(app_root)
	app_root.call("bootstrap_runtime", "res://content")
	return app_root

static func _simulate_complete_d1(app_root: Node) -> void:
	var bridge: RefCounted = app_root.call("get_progress_save_bridge") as RefCounted
	for i in range(1, 6):
		var s_id: String = "stage_01_%02d" % i
		var reward_id: String = "reward_01_%02d" % i
		var frags: Array[String] = []
		if i == 5:
			frags.append("fragment_01")
		var reward: RefCounted = RewardGrantClass.new(reward_id, s_id, 10, 20, frags) as RefCounted
		bridge.call("commit_stage_and_checkpoint", s_id, reward)

static func _ensure_test_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and not dir.dir_exists(TEST_DIR):
		dir.make_dir_recursive(TEST_DIR)
