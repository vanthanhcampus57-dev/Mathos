extends SceneTree

## Unit & Integration test suite verifying D1 Critical Flow Fixes:
## Story phase handoff, story -> lesson transition, canonical speaker names,
## D1 completion screen & D2 freeze, real reward values, ReviewButton handling,
## stage-aware advisor text, stage-aware summary, and practice count capping.

func _initialize() -> void:
	print("--- RUNNING SUITE: D1 Critical Flow Fixes ---")
	var ok: bool = run_all_tests()
	if ok:
		print("MATHOS D1 CRITICAL FLOW FIXES QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS D1 CRITICAL FLOW FIXES QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	print("--- RUNNING SUITE: D1 Critical Flow Fixes ---")
	var passed: bool = true

	passed = test_001_speaker_identity_resolution() and passed
	passed = test_002_story_phase_mount_and_advance() and passed
	passed = test_003_stage_aware_advisor_and_summary() and passed
	passed = test_004_practice_question_count_respected() and passed
	passed = test_005_real_reward_presentation_and_review_button() and passed
	passed = test_006_d1_completion_and_d2_frozen() and passed

	if passed:
		print("[D1-FLOW-FIXES] ALL TESTS PASSED!")
	else:
		print("[D1-FLOW-FIXES] SOME TESTS FAILED!")
	return passed

static func _cleanup_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()

static func test_001_speaker_identity_resolution() -> bool:
	print("[D1-FLOW-001] Testing canonical speaker identity resolution...")

	var arithmos: String = LessonPanel.get_player_facing_speaker_name("npc_arithmos")
	if arithmos != "Arithmos":
		print("[D1-FLOW-001] FAIL: Expected 'Arithmos', got '%s'" % arithmos)
		return false

	var draven: String = LessonPanel.get_player_facing_speaker_name("npc_draven")
	if draven != "Draven":
		print("[D1-FLOW-001] FAIL: Expected 'Draven', got '%s'" % draven)
		return false

	var karl: String = LessonPanel.get_player_facing_speaker_name("char_karl")
	if karl != "Karl":
		print("[D1-FLOW-001] FAIL: Expected 'Karl', got '%s'" % karl)
		return false

	var aether: String = LessonPanel.get_player_facing_speaker_name("npc_aether")
	if aether != "Aether":
		print("[D1-FLOW-001] FAIL: Expected 'Aether', got '%s'" % aether)
		return false

	var stochas: String = LessonPanel.get_player_facing_speaker_name("enemy_d1_stochas")
	if stochas != "STOCHAS":
		print("[D1-FLOW-001] FAIL: Expected 'STOCHAS', got '%s'" % stochas)
		return false

	var empty_speaker: String = LessonPanel.get_player_facing_speaker_name("")
	if empty_speaker != "CỐ VẤN":
		print("[D1-FLOW-001] FAIL: Expected fallback 'CỐ VẤN', got '%s'" % empty_speaker)
		return false

	print("[D1-FLOW-001] PASS: Speaker identity resolved canonically.")
	return true

static func test_002_story_phase_mount_and_advance() -> bool:
	print("[D1-FLOW-002] Testing Story Phase mount and transition to Lesson...")
	var app_script: GDScript = load("res://src/app/app_root.gd") as GDScript
	var app: AppRoot = app_script.new()
	Engine.get_main_loop().root.add_child(app)

	# Clean save
	var u_dir := DirAccess.open("user://")
	if u_dir != null and u_dir.file_exists("save_v1.json"):
		u_dir.remove("save_v1.json")

	if not app.bootstrap_runtime():
		print("[D1-FLOW-002] FAIL: bootstrap_runtime failed")
		_cleanup_node(app)
		return false

	var res: Dictionary = app.start_new_game()
	if not bool(res.get("success", false)):
		print("[D1-FLOW-002] FAIL: start_new_game failed")
		_cleanup_node(app)
		return false

	var shell = app.get_node_or_null("StagePresentationShell")
	if shell == null:
		print("[D1-FLOW-002] FAIL: StagePresentationShell not found")
		_cleanup_node(app)
		return false

	# Must enter MODE_STORY (7)
	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_STORY:
		print("[D1-FLOW-002] FAIL: Expected MODE_STORY (7), got %d" % shell.get_view_mode())
		_cleanup_node(app)
		return false

	var lesson_panel: LessonPanel = shell.get_lesson_panel()
	if lesson_panel == null or not lesson_panel.visible:
		print("[D1-FLOW-002] FAIL: LessonPanel not visible during MODE_STORY")
		_cleanup_node(app)
		return false

	# Check button text on story step
	var btn: Button = lesson_panel._get_continue_button()
	if btn == null or btn.text != "Vào bài học":
		print("[D1-FLOW-002] FAIL: Expected story button text 'Vào bài học', got '%s'" % (btn.text if btn else "null"))
		_cleanup_node(app)
		return false

	# Click continue button to complete story
	btn.pressed.emit()

	# Shell must now transition to MODE_LESSON (1)
	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_LESSON:
		print("[D1-FLOW-002] FAIL: Expected MODE_LESSON (1) after story, got %d" % shell.get_view_mode())
		_cleanup_node(app)
		return false

	_cleanup_node(app)
	print("[D1-FLOW-002] PASS: Story Phase mounts and cleanly transitions to Lesson.")
	return true

static func test_003_stage_aware_advisor_and_summary() -> bool:
	print("[D1-FLOW-003] Testing Stage-Aware Advisor text and Dynamic Summary...")
	var app_script: GDScript = load("res://src/app/app_root.gd") as GDScript
	var app: AppRoot = app_script.new()
	Engine.get_main_loop().root.add_child(app)

	app.bootstrap_runtime()
	app.start_new_game()

	var summary_1: String = app._build_dynamic_stage_summary()
	if not summary_1.contains("Khái Niệm Phép Thử"):
		print("[D1-FLOW-003] FAIL: Stage 1 summary does not contain lesson header: '%s'" % summary_1)
		_cleanup_node(app)
		return false

	# Unlock and Select Stage 1.2
	var progress = app.get_progress_service()
	if not progress._state.unlocked_stage_ids.has("stage_01_02"):
		progress._state.unlocked_stage_ids.append("stage_01_02")
	app.select_stage("stage_01_02")
	var summary_2: String = app._build_dynamic_stage_summary()
	if not summary_2.contains("Không Gian Mẫu"):
		print("[D1-FLOW-003] FAIL: Stage 2 summary does not contain lesson header: '%s'" % summary_2)
		_cleanup_node(app)
		return false

	if summary_1 == summary_2:
		print("[D1-FLOW-003] FAIL: Summary 1 and Summary 2 must be different!")
		_cleanup_node(app)
		return false

	_cleanup_node(app)
	print("[D1-FLOW-003] PASS: Stage-aware advisor text and dynamic summary verified.")
	return true

static func test_004_practice_question_count_respected() -> bool:
	print("[D1-FLOW-004] Testing configured question_count = 3 enforcement...")
	var app_script: GDScript = load("res://src/app/app_root.gd") as GDScript
	var app: AppRoot = app_script.new()
	Engine.get_main_loop().root.add_child(app)

	var u_dir := DirAccess.open("user://")
	if u_dir != null and u_dir.file_exists("save_v1.json"):
		u_dir.remove("save_v1.json")

	app.bootstrap_runtime()
	app.start_new_game()

	var target_count: int = app._get_target_practice_question_count()
	if target_count != 3:
		print("[D1-FLOW-004] FAIL: Expected target_count == 3 from practice.json, got %d" % target_count)
		_cleanup_node(app)
		return false

	# Transition story -> lesson -> questions
	app._on_story_completed()
	app._on_lesson_continue_requested()

	# Answer 3 questions via QuestionController
	for i in range(3):
		var q_ctrl = app.get_question_controller()
		q_ctrl.submit_answer({"selected_option_id": "opt_a"})
		app._on_question_continue_requested()

	# After 3 questions, stage complete panel must be displayed without error!
	var shell = app.get_node_or_null("StagePresentationShell")
	if shell == null or shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE:
		print("[D1-FLOW-004] FAIL: Expected MODE_STAGE_COMPLETE after 3 questions, got %s" % (str(shell.get_view_mode()) if shell else "null"))
		_cleanup_node(app)
		return false

	if app._finalized_question_ids.size() != 3:
		print("[D1-FLOW-004] FAIL: Expected exactly 3 finalized questions, got %d" % app._finalized_question_ids.size())
		_cleanup_node(app)
		return false

	_cleanup_node(app)
	print("[D1-FLOW-004] PASS: Practice question count capped exactly at configured 3.")
	return true

static func test_005_real_reward_presentation_and_review_button() -> bool:
	print("[D1-FLOW-005] Testing Real Reward Presentation & disabled ReviewButton...")
	var panel_scene: PackedScene = load("res://src/ui/stage/stage_complete_panel.tscn") as PackedScene
	var panel: StageCompletePanel = panel_scene.instantiate() as StageCompletePanel
	Engine.get_main_loop().root.add_child(panel)

	# ReviewButton must be hidden / disabled
	var rev_btn: Button = panel._get_review_button()
	if rev_btn != null and (rev_btn.visible or not rev_btn.disabled):
		print("[D1-FLOW-005] FAIL: ReviewButton must be hidden or disabled!")
		_cleanup_node(panel)
		return false

	# Set rewards data
	panel.set_rewards_data(250, 500, "Mảnh Vỡ Ma Thuật 01")
	var rew_val: Label = panel.get_node_or_null("MarginContainer/VBoxContainer/StatsHBox/RewardsPanel/VBox/Value") as Label
	if rew_val == null or not rew_val.text.contains("+250 Vàng") or not rew_val.text.contains("+500 XP") or not rew_val.text.contains("Mảnh Vỡ"):
		print("[D1-FLOW-005] FAIL: Reward values not formatted correctly: '%s'" % (rew_val.text if rew_val else "null"))
		_cleanup_node(panel)
		return false

	_cleanup_node(panel)
	print("[D1-FLOW-005] PASS: Real rewards formatted and ReviewButton cleanly disabled.")
	return true

static func test_006_d1_completion_and_d2_frozen() -> bool:
	print("[D1-FLOW-006] Testing D1 completion screen and D2 route freeze...")
	var app_script: GDScript = load("res://src/app/app_root.gd") as GDScript
	var app: AppRoot = app_script.new()
	Engine.get_main_loop().root.add_child(app)

	var u_dir := DirAccess.open("user://")
	if u_dir != null and u_dir.file_exists("save_v1.json"):
		u_dir.remove("save_v1.json")

	app.bootstrap_runtime()
	app.start_new_game()

	# Clear all 5 stages of D1 directly into progress service
	var progress = app.get_progress_service()
	for s_num in range(1, 6):
		var s_id: String = "stage_01_%02d" % s_num
		if not progress._state.cleared_stage_ids.has(s_id):
			progress._state.cleared_stage_ids.append(s_id)
		if not progress._state.unlocked_stage_ids.has(s_id):
			progress._state.unlocked_stage_ids.append(s_id)

	if not app._is_dungeon_1_complete():
		print("[D1-FLOW-006] FAIL: Expected _is_dungeon_1_complete() == true")
		_cleanup_node(app)
		return false

	# Selecting D2 stage must be rejected
	var sel_d2: Dictionary = app.select_stage("stage_02_01")
	if bool(sel_d2.get("success", false)):
		print("[D1-FLOW-006] FAIL: select_stage('stage_02_01') succeeded but D2 must be frozen!")
		_cleanup_node(app)
		return false

	# Advancing from stage_01_05 must show D1 Complete, NOT enter D2
	app.get_game_flow_service().start_stage("stage_01_05")
	app._on_stage_continue_requested()

	var shell = app.get_node_or_null("StagePresentationShell")
	if shell == null or shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_DUNGEON_COMPLETE:
		print("[D1-FLOW-006] FAIL: Expected MODE_DUNGEON_COMPLETE (8), got %s" % (str(shell.get_view_mode()) if shell else "null"))
		_cleanup_node(app)
		return false

	var v_panel: GameVictoryPanel = shell.get_victory_panel()
	if v_panel == null or not v_panel.visible:
		print("[D1-FLOW-006] FAIL: GameVictoryPanel not visible in MODE_DUNGEON_COMPLETE")
		_cleanup_node(app)
		return false

	# Verify Real Fragment 01 reward container & asset
	var frag_rect: TextureRect = v_panel.get_fragment_rect()
	if frag_rect == null or not frag_rect.visible:
		print("[D1-FLOW-006] FAIL: FragmentTextureRect is null or invisible")
		_cleanup_node(app)
		return false

	if frag_rect.texture == null or not frag_rect.texture.resource_path.ends_with("fragment_01.png"):
		print("[D1-FLOW-006] FAIL: Fragment texture missing or not pointing to fragment_01.png")
		_cleanup_node(app)
		return false

	if frag_rect.texture.get_width() != 512 or frag_rect.texture.get_height() != 512:
		print("[D1-FLOW-006] FAIL: Fragment texture not 512x512 (%dx%d)" % [frag_rect.texture.get_width(), frag_rect.texture.get_height()])
		_cleanup_node(app)
		return false

	if frag_rect.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		print("[D1-FLOW-006] FAIL: Fragment stretch_mode not STRETCH_KEEP_ASPECT_CENTERED")
		_cleanup_node(app)
		return false

	var frag_cont: Control = v_panel.get_fragment_container()
	if frag_cont == null or not frag_cont.visible:
		print("[D1-FLOW-006] FAIL: FragmentRewardContainer is null or invisible")
		_cleanup_node(app)
		return false

	# Verify generic placeholder removed from Dungeon 1 card
	var d1_card: PanelContainer = v_panel.get_dungeon_grid().get_child(0) as PanelContainer
	var d1_vbox = d1_card.get_child(0) if d1_card != null and d1_card.get_child_count() > 0 else null
	var d1_status: Label = d1_vbox.get_child(2) as Label if d1_vbox != null and d1_vbox.get_child_count() >= 3 else null
	if d1_status == null or d1_status.text.contains("[Hoàn thành - "):
		print("[D1-FLOW-006] FAIL: Generic placeholder not removed from D1 card: '%s'" % (d1_status.text if d1_status else "null"))
		_cleanup_node(app)
		return false

	# Verify runtime reward values preserved (actual gold and XP)
	var exp_val: int = app._player_persistent.exp_total if app._player_persistent != null else 0
	var gold_val: int = app._player_persistent.coin_balance if app._player_persistent != null else 0
	if v_panel._xp_value_label == null or v_panel._xp_value_label.text != ("%d" % exp_val):
		print("[D1-FLOW-006] FAIL: Runtime XP reward not preserved: expected %d, got '%s'" % [exp_val, v_panel._xp_value_label.text if v_panel._xp_value_label else "null"])
		_cleanup_node(app)
		return false
	if v_panel._gold_value_label == null or v_panel._gold_value_label.text != ("%d" % gold_val):
		print("[D1-FLOW-006] FAIL: Runtime Gold reward not preserved: expected %d, got '%s'" % [gold_val, v_panel._gold_value_label.text if v_panel._gold_value_label else "null"])
		_cleanup_node(app)
		return false

	var curr_st: String = app.get_game_flow_service().get_current_stage_id()
	if curr_st == "stage_02_01":
		print("[D1-FLOW-006] FAIL: Current stage advanced to stage_02_01! D2 auto-entry occurred!")
		_cleanup_node(app)
		return false

	_cleanup_node(app)
	print("[D1-FLOW-006] PASS: D1 completion screen triggers with real Fragment 01 and D2 route remains frozen.")
	return true
