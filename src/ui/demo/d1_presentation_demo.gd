class_name D1PresentationDemo
extends Control

## Interactive presentation demo for Mathos D1 (Stage 1.1 -> 1.3) vertical slice.
## Pure UI composition layer connecting Presentation Shell (B.2) and Question UI (B.1)
## to QuestionService without modifying GameFlow, ProgressState, or SaveService.

@onready var shell: StagePresentationShell = $StagePresentationShell

var _catalog: ValidatedCatalog = null
var _question_service: QuestionService = null
var _question_panel: QuestionPanel = null
var _controller: QuestionPresentationController = null

var _current_stage_id: String = "stage_01_01"
var _active_session_id: String = ""
var _is_demo_active: bool = false

func _ready() -> void:
	# Load validated catalog fixture
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	if report != null and repo.get_catalog() != null:
		_catalog = repo.get_catalog()
		_question_service = QuestionService.new(_catalog)

	if shell != null:
		if not shell.new_game_requested.is_connected(_on_new_game_requested):
			shell.new_game_requested.connect(_on_new_game_requested)
		if not shell.lesson_continue_requested.is_connected(_on_lesson_continue):
			shell.lesson_continue_requested.connect(_on_lesson_continue)
		if not shell.question_host_ready.is_connected(_on_question_host_ready):
			shell.question_host_ready.connect(_on_question_host_ready)
		if not shell.stage_continue_requested.is_connected(_on_stage_continue):
			shell.stage_continue_requested.connect(_on_stage_continue)

	_controller = QuestionPresentationController.new(_question_service)

func start_demo(initial_stage_id: String = "stage_01_01") -> void:
	_current_stage_id = initial_stage_id
	_is_demo_active = true
	_load_stage_presentation(_current_stage_id)

func _on_new_game_requested() -> void:
	start_demo("stage_01_01")

func _on_lesson_continue() -> void:
	if shell != null:
		shell.set_view_mode(StagePresentationShell.ViewMode.MODE_QUESTION_HOST)

func _on_question_host_ready(container: Control) -> void:
	if container == null or _question_service == null:
		return

	if _question_panel != null:
		_question_panel.queue_free()
		_question_panel = null

	_question_panel = QuestionPanel.new()
	container.add_child(_question_panel)

	if not _question_panel.submit_requested.is_connected(_on_question_submit_requested):
		_question_panel.submit_requested.connect(_on_question_submit_requested)

	# Request question for current D1 stage scope
	var request_payload: Dictionary = {
		"request_id": "req_%s_demo" % _current_stage_id,
		"stage_id": _current_stage_id,
		"scope": {
			"dungeon_id": "dungeon_01",
			"topic_id": "trial_sample_event",
			"subtopic_ids": ["sample_space", "event_probability"],
			"difficulty_min": 1,
			"difficulty_max": 3,
			"interaction_types": ["multiple_choice", "input", "drag_drop", "matching"]
		},
		"context": "practice",
		"preferred_difficulty": 1
	}

	var req_res: Dictionary = _question_service.request_question(request_payload)
	if bool(req_res.get("success", false)):
		var session: Dictionary = req_res.get("session", {}) as Dictionary
		_active_session_id = String(session.get("session_id", ""))
		var pres_view: Dictionary = req_res.get("question", {}) as Dictionary
		_question_panel.setup_question(pres_view)

func _on_question_submit_requested(interaction_payload: Dictionary) -> void:
	if _question_service == null or _active_session_id.is_empty():
		return

	var submit_payload: Dictionary = {
		"session_id": _active_session_id,
		"interaction_payload": interaction_payload,
		"elapsed_seconds": 3.5
	}

	var sub_res: Dictionary = _question_service.submit_answer(submit_payload)
	if bool(sub_res.get("success", false)):
		var result: Dictionary = sub_res.get("result", {}) as Dictionary
		if _question_panel != null:
			_question_panel.display_feedback(result)

		# Advance to stage complete view
		if shell != null:
			shell.set_view_mode(StagePresentationShell.ViewMode.MODE_STAGE_COMPLETE)

func _on_stage_continue() -> void:
	# Advance stage 1.1 -> 1.2 -> 1.3 sequence
	match _current_stage_id:
		"stage_01_01":
			start_demo("stage_01_02")
		"stage_01_02":
			start_demo("stage_01_03")
		"stage_01_03":
			_is_demo_active = false
			if shell != null:
				shell.set_view_mode(StagePresentationShell.ViewMode.MODE_ENTRY)

func _load_stage_presentation(stage_id: String) -> void:
	var stage_title: String = "Stage 1.1 — Mist Forest Entrance"
	match stage_id:
		"stage_01_02":
			stage_title = "Stage 1.2 — Forest Clearing"
		"stage_01_03":
			stage_title = "Stage 1.3 — Deep Canopy"

	var context_info: PresentationModels.StageContextInfo = PresentationModels.StageContextInfo.new(
		stage_id,
		stage_title,
		"Khu Rừng Mù Sương (Dungeon 01)",
		[
			PresentationModels.LessonStepData.new("Karl", "Welcome to Mathos D1 Presentation Demo!", stage_title, 1, 2),
			PresentationModels.LessonStepData.new("Karl", "Complete the question challenge to advance through the forest.", stage_title, 2, 2)
		],
		false
	)

	if shell != null:
		shell.set_stage_context(context_info)
		shell.set_view_mode(StagePresentationShell.ViewMode.MODE_LESSON)
