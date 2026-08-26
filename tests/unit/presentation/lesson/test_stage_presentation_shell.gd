class_name TestStagePresentationShell
extends RefCounted

## Unit test suite for StagePresentationShell, LessonPanel, StageCompletePanel,
## and presentation models (supporting PRES-009, PRES-010, PRES-011, PRES-STARTUP-LEAK).

static func run_all_tests(tree: SceneTree = null) -> bool:
	print("--- RUNNING PRESENTATION UI SHELL SUITE ---")
	var all_ok: bool = true
	all_ok = test_models_neutral_data() and all_ok
	all_ok = test_shell_instantiation_and_nodes_exist(tree) and all_ok
	all_ok = test_start_new_game_entry_presentation(tree) and all_ok
	all_ok = test_entry_layout_non_overlapping_controls(tree) and all_ok
	all_ok = test_entry_mode_does_not_expose_restored_header(tree) and all_ok
	all_ok = test_stage_title_and_context(tree) and all_ok
	all_ok = test_lesson_panel_pagination_and_continue(tree) and all_ok
	all_ok = test_question_host_container_ready(tree) and all_ok
	all_ok = test_feedback_host_and_display(tree) and all_ok
	all_ok = test_stage_complete_presentation(tree) and all_ok
	all_ok = test_restored_stage_context_display_pres_011(tree) and all_ok
	all_ok = test_sequence_flow_pres_009(tree) and all_ok
	all_ok = test_no_combat_intent_dependency_pres_010(tree) and all_ok
	all_ok = test_no_progress_or_save_mutation(tree) and all_ok
	return all_ok

static func _sample_context(stage_id: String = "stage_01_01", restored: bool = false) -> PresentationModels.StageContextInfo:
	var step1: PresentationModels.LessonStepData = PresentationModels.LessonStepData.new(
		"Guide",
		"Welcome to the probability trial. Count the outcomes in the sample space.",
		"Sample Space Fundamentals",
		1, 2
	)
	var step2: PresentationModels.LessonStepData = PresentationModels.LessonStepData.new(
		"Guide",
		"Select the total number of equally likely outcomes.",
		"Trial & Event Definition",
		2, 2
	)
	return PresentationModels.StageContextInfo.new(
		stage_id,
		"Stage 1-1: Trial & Sample Event",
		"Dungeon 1: Probability Ruins",
		[step1, step2],
		restored
	)

static func _add_node_to_tree(node: Node, tree: SceneTree = null) -> void:
	if tree == null:
		tree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(node)
	if not node.is_node_ready():
		node._ready()

static func _remove_node_from_tree(node: Node) -> void:
	if node != null:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()

static func test_models_neutral_data() -> bool:
	var step: PresentationModels.LessonStepData = PresentationModels.LessonStepData.from_dict({
		"speaker_label": "Instructor",
		"body_text": "Neutral test text",
		"context_title": "Title",
		"step_index": 1,
		"total_steps": 3
	})
	if step.speaker_label != "Instructor" or step.body_text != "Neutral test text":
		return _fail("PRES-MODEL-001", "LessonStepData deserialization failed")
	print("[PRES-MODEL-001] PASS")
	return true

static func test_shell_instantiation_and_nodes_exist(tree: SceneTree = null) -> bool:
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	if scene == null:
		return _fail("PRES-SHELL-001", "Failed to load stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	if shell == null:
		return _fail("PRES-SHELL-001", "Failed to instantiate StagePresentationShell")

	_add_node_to_tree(shell, tree)

	if shell.get_question_host_container() == null:
		_remove_node_from_tree(shell)
		return _fail("PRES-SHELL-001", "QuestionHostContainer node missing")
	if shell.get_feedback_host_container() == null:
		_remove_node_from_tree(shell)
		return _fail("PRES-SHELL-001", "FeedbackHostContainer node missing")
	if shell.get_lesson_panel() == null:
		_remove_node_from_tree(shell)
		return _fail("PRES-SHELL-001", "LessonPanel node missing")
	if shell.get_stage_complete_panel() == null:
		_remove_node_from_tree(shell)
		return _fail("PRES-SHELL-001", "StageCompletePanel node missing")

	_remove_node_from_tree(shell)
	print("[PRES-SHELL-001] PASS")
	return true

static func test_start_new_game_entry_presentation(tree: SceneTree = null) -> bool:
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	_add_node_to_tree(shell, tree)

	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_ENTRY)
	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_ENTRY:
		_remove_node_from_tree(shell)
		return _fail("PRES-SHELL-002", "ViewMode entry not set")

	var state: Dictionary = {"emitted": false}
	shell.new_game_requested.connect(func(): state["emitted"] = true)
	shell._on_new_game_pressed()

	if not bool(state["emitted"]):
		_remove_node_from_tree(shell)
		return _fail("PRES-SHELL-002", "new_game_requested signal not emitted")

	_remove_node_from_tree(shell)
	print("[PRES-SHELL-002] PASS")
	return true

static func test_entry_layout_non_overlapping_controls(tree: SceneTree = null) -> bool:
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	_add_node_to_tree(shell, tree)

	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_ENTRY)
	shell.set_continue_available(true)

	var cont_btn: Button = shell._get_continue_game_button()
	var new_btn: Button = shell._get_new_game_button()

	if cont_btn == null or not cont_btn.visible:
		_remove_node_from_tree(shell)
		return _fail("PRES-LAYOUT-001", "ContinueButton is not visible when enabled")

	if new_btn == null or not new_btn.visible:
		_remove_node_from_tree(shell)
		return _fail("PRES-LAYOUT-001", "NewGameButton is not visible in MODE_ENTRY")

	var cont_parent: Node = cont_btn.get_parent()
	var new_parent: Node = new_btn.get_parent()

	if cont_parent == null or cont_parent != new_parent or not (cont_parent is VBoxContainer):
		_remove_node_from_tree(shell)
		return _fail("PRES-LAYOUT-001", "ContinueButton and NewGameButton do not share a common VBoxContainer layout")

	if cont_btn.get_index() >= new_btn.get_index():
		_remove_node_from_tree(shell)
		return _fail("PRES-LAYOUT-001", "ContinueButton index is not above NewGameButton in VBoxContainer")

	_remove_node_from_tree(shell)
	print("[PRES-LAYOUT-001] PASS")
	return true

static func test_entry_mode_does_not_expose_restored_header(tree: SceneTree = null) -> bool:
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	_add_node_to_tree(shell, tree)

	# In MODE_ENTRY (default upon ready), HeaderBar and RestoredBadgeLabel must not be visible
	var header: Control = shell._get_header_bar()
	var badge: Label = shell._get_restored_badge_label()

	if header != null and header.visible:
		_remove_node_from_tree(shell)
		return _fail("PRES-STARTUP-LEAK", "HeaderBar is visible during MODE_ENTRY")

	if badge != null and badge.visible:
		_remove_node_from_tree(shell)
		return _fail("PRES-STARTUP-LEAK", "RestoredBadgeLabel is visible during MODE_ENTRY")

	# Even if set_stage_context is called with is_restored_context=true while in MODE_ENTRY
	shell.set_stage_context(_sample_context("stage_01_01", true))

	if header != null and header.visible:
		_remove_node_from_tree(shell)
		return _fail("PRES-STARTUP-LEAK", "HeaderBar exposed restored context during MODE_ENTRY")

	# Transitioning to MODE_LESSON must reveal header and badge for restored context
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_LESSON)

	if header == null or not header.visible:
		_remove_node_from_tree(shell)
		return _fail("PRES-STARTUP-LEAK", "HeaderBar failed to become visible in MODE_LESSON")

	if badge == null or not badge.visible:
		_remove_node_from_tree(shell)
		return _fail("PRES-STARTUP-LEAK", "RestoredBadgeLabel failed to become visible in MODE_LESSON for restored context")

	_remove_node_from_tree(shell)
	print("[PRES-STARTUP-LEAK] PASS")
	return true

static func test_stage_title_and_context(tree: SceneTree = null) -> bool:
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	_add_node_to_tree(shell, tree)

	var ctx: PresentationModels.StageContextInfo = _sample_context("stage_01_01", false)
	shell.set_stage_context(ctx)

	var stage_label: Label = shell._get_stage_title_label()
	var dungeon_label: Label = shell._get_dungeon_title_label()

	if stage_label == null or stage_label.text != "Stage 1-1: Trial & Sample Event":
		_remove_node_from_tree(shell)
		return _fail("PRES-SHELL-003", "Stage title label text mismatch")
	if dungeon_label == null or dungeon_label.text != "Dungeon 1: Probability Ruins":
		_remove_node_from_tree(shell)
		return _fail("PRES-SHELL-003", "Dungeon title label text mismatch")

	_remove_node_from_tree(shell)
	print("[PRES-SHELL-003] PASS")
	return true

static func test_lesson_panel_pagination_and_continue(tree: SceneTree = null) -> bool:
	var scene: PackedScene = load("res://src/ui/lesson/lesson_panel.tscn")
	var panel: LessonPanel = scene.instantiate() as LessonPanel
	_add_node_to_tree(panel, tree)

	var step1: PresentationModels.LessonStepData = PresentationModels.LessonStepData.new("Guide", "Page 1 content", "Title 1")
	var step2: PresentationModels.LessonStepData = PresentationModels.LessonStepData.new("Guide", "Page 2 content", "Title 2")

	var state: Dictionary = {"completed": false}
	panel.lesson_completed.connect(func(): state["completed"] = true)

	panel.set_lesson_data([step1, step2])

	if panel.get_current_step_index() != 0 or panel.get_total_steps() != 2:
		_remove_node_from_tree(panel)
		return _fail("PRES-LESSON-001", "LessonPanel initial page index mismatch")

	var advanced: bool = panel.next_step()
	if not advanced or panel.get_current_step_index() != 1:
		_remove_node_from_tree(panel)
		return _fail("PRES-LESSON-001", "LessonPanel failed to advance to next step")

	var final_adv: bool = panel.next_step()
	if final_adv or not bool(state["completed"]):
		_remove_node_from_tree(panel)
		return _fail("PRES-LESSON-001", "LessonPanel did not emit lesson_completed on final step")

	_remove_node_from_tree(panel)
	print("[PRES-LESSON-001] PASS")
	return true

static func test_question_host_container_ready(tree: SceneTree = null) -> bool:
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	_add_node_to_tree(shell, tree)

	var state: Dictionary = {"container": null}
	shell.question_host_ready.connect(func(c): state["container"] = c)

	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)

	if state["container"] == null or state["container"] != shell.get_question_host_container():
		_remove_node_from_tree(shell)
		return _fail("PRES-SHELL-004", "question_host_ready signal did not pass correct host container")

	_remove_node_from_tree(shell)
	print("[PRES-SHELL-004] PASS")
	return true

static func test_feedback_host_and_display(tree: SceneTree = null) -> bool:
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	_add_node_to_tree(shell, tree)

	var fb: PresentationModels.FeedbackInfo = PresentationModels.FeedbackInfo.new(true, "Correct Answer!", "Well done", "Detailed explanation")
	shell.show_feedback(fb)

	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_FEEDBACK_HOST:
		_remove_node_from_tree(shell)
		return _fail("PRES-SHELL-005", "show_feedback did not transition to MODE_FEEDBACK_HOST")

	_remove_node_from_tree(shell)
	print("[PRES-SHELL-005] PASS")
	return true

static func test_stage_complete_presentation(tree: SceneTree = null) -> bool:
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	_add_node_to_tree(shell, tree)

	var state: Dictionary = {"emitted": false}
	shell.stage_continue_requested.connect(func(): state["emitted"] = true)

	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE)
	shell.get_stage_complete_panel()._on_continue_pressed()

	if not bool(state["emitted"]):
		_remove_node_from_tree(shell)
		return _fail("PRES-SHELL-006", "stage_continue_requested signal not emitted from stage complete panel")

	_remove_node_from_tree(shell)
	print("[PRES-SHELL-006] PASS")
	return true

static func test_restored_stage_context_display_pres_011(tree: SceneTree = null) -> bool:
	# PRES-011: shell can display caller-supplied restored legal stage context
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	_add_node_to_tree(shell, tree)

	var restored_ctx: PresentationModels.StageContextInfo = _sample_context("stage_01_02", true)
	shell.set_stage_context(restored_ctx)
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_LESSON)

	if not shell.is_restored_context_displayed():
		_remove_node_from_tree(shell)
		return _fail("PRES-011", "is_restored_context_displayed returned false for restored context")
	var badge: Label = shell._get_restored_badge_label()
	if badge == null or not badge.visible:
		_remove_node_from_tree(shell)
		return _fail("PRES-011", "Restored badge label is not visible for restored context in active stage mode")

	_remove_node_from_tree(shell)
	print("[PRES-011] PASS")
	return true

static func test_sequence_flow_pres_009(tree: SceneTree = null) -> bool:
	# PRES-009: Stage presentation sequence shell: lesson/dialogue -> question host -> result/feedback presentation
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	_add_node_to_tree(shell, tree)

	shell.set_stage_context(_sample_context("stage_01_01", false))

	# Step 1: Start at Lesson
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_LESSON)
	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_LESSON:
		_remove_node_from_tree(shell)
		return _fail("PRES-009", "Failed to set MODE_LESSON")

	# Step 2: Complete lesson -> transitions to Question Host
	shell._on_lesson_completed()
	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_QUESTION_HOST:
		_remove_node_from_tree(shell)
		return _fail("PRES-009", "Lesson completion did not transition to MODE_QUESTION_HOST")

	# Step 3: Question result -> transitions to Feedback Host
	shell.show_feedback({"is_correct": true, "title": "Good Job!"})
	if shell.get_view_mode() != StagePresentationShell.ViewMode.MODE_FEEDBACK_HOST:
		_remove_node_from_tree(shell)
		return _fail("PRES-009", "Feedback display did not transition to MODE_FEEDBACK_HOST")

	_remove_node_from_tree(shell)
	print("[PRES-009] PASS")
	return true

static func test_no_combat_intent_dependency_pres_010(tree: SceneTree = null) -> bool:
	# PRES-010: Stage 1.1-1.3 shell has no Combat/Intent dependency
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	_add_node_to_tree(shell, tree)

	var stages: Array[String] = ["stage_01_01", "stage_01_02", "stage_01_03"]
	for st_id in stages:
		shell.set_stage_context(_sample_context(st_id, false))
		var label: Label = shell._get_stage_title_label()
		if label == null or label.text.is_empty():
			_remove_node_from_tree(shell)
			return _fail("PRES-010", "Failed to set context for " + st_id)

	_remove_node_from_tree(shell)
	print("[PRES-010] PASS")
	return true

static func test_no_progress_or_save_mutation(tree: SceneTree = null) -> bool:
	var scene: PackedScene = load("res://src/ui/stage/stage_presentation_shell.tscn")
	var shell: StagePresentationShell = scene.instantiate() as StagePresentationShell
	_add_node_to_tree(shell, tree)

	# Execute all UI mode transitions & button clicks
	shell.set_stage_context(_sample_context("stage_01_01", false))
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_LESSON)
	shell.get_lesson_panel().next_step()
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)
	shell.show_feedback({"is_correct": true})
	shell.set_view_mode(StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE)
	shell.get_stage_complete_panel()._on_continue_pressed()

	_remove_node_from_tree(shell)
	print("[PRES-MUTATION-001] PASS")
	return true

static func _fail(test_id: String, message: String) -> bool:
	print("[%s] FAIL: %s" % [test_id, message])
	return false
