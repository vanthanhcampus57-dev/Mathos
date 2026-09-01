class_name QuestionPresentationController
extends RefCounted

## Presentation controller for managing QuestionSession lifecycle, rendering interaction views,
## submitting canonical AnswerPayloads to QuestionService, consuming AttemptResult feedback,
## and emitting completion/failure events toward stage presentation.

signal question_completed(result: Dictionary)
signal question_failed(error: Dictionary)
signal continue_requested()
signal retry_requested()

var _question_service: QuestionService
var _question_panel: QuestionPanel = null
var _active_session_id: String = ""
var _active_interaction_type: String = ""
var _completed: bool = false

static func strip_answer_spec(question: Dictionary) -> Dictionary:
	var view: Dictionary = question.duplicate(true)
	view.erase("answer_spec")
	return view

func _init(p_service: QuestionService, p_panel: QuestionPanel = null) -> void:
	_question_service = p_service
	if p_panel != null:
		attach_panel(p_panel)

func attach_panel(panel: QuestionPanel) -> void:
	_question_panel = panel
	if not _question_panel.submit_requested.is_connected(submit_answer):
		_question_panel.submit_requested.connect(submit_answer)
	if _question_panel.has_signal("continue_requested") and not _question_panel.continue_requested.is_connected(_on_panel_continue):
		_question_panel.continue_requested.connect(_on_panel_continue)
	if _question_panel.has_signal("retry_requested") and not _question_panel.retry_requested.is_connected(_on_panel_retry):
		_question_panel.retry_requested.connect(_on_panel_retry)

func start_question(request: Dictionary, adaptive_recommendation: Dictionary = {}) -> Dictionary:
	_active_session_id = ""
	_active_interaction_type = ""
	_completed = false

	if _question_service == null:
		var err_null: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION_SESSION, "QuestionService reference is null")
		question_failed.emit(err_null)
		return err_null

	var response: Dictionary = _question_service.request_question(request, adaptive_recommendation)
	if not bool(response.get("success", false)):
		question_failed.emit(response)
		return response

	var session: Dictionary = response.get("session", {}) as Dictionary
	var question: Dictionary = response.get("question", {}) as Dictionary

	if session.is_empty() or question.is_empty() or not session.has("session_id") or not question.has("interaction_type"):
		var err_shape: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION, "Malformed presentation view from QuestionService")
		question_failed.emit(err_shape)
		return err_shape

	# Never require or expose answer_spec
	if question.has("answer_spec"):
		var err_leak: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION, "answer_spec leaked into presentation view")
		question_failed.emit(err_leak)
		return err_leak

	if _question_panel != null:
		var panel_ok: bool = _question_panel.setup_question(question)
		if not panel_ok:
			var err_panel: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION, "Failed to setup QuestionPanel with question view")
			question_failed.emit(err_panel)
			return err_panel

	_active_session_id = String(session["session_id"])
	_active_interaction_type = String(question["interaction_type"])
	_completed = false
	return response

func bind_existing_session(session: Dictionary, question: Dictionary) -> Dictionary:
	_active_session_id = ""
	_active_interaction_type = ""
	_completed = false

	if _question_service == null:
		var err_null: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION_SESSION, "QuestionService reference is null")
		push_error("QuestionPresentationController.bind_existing_session: QuestionService reference is null")
		question_failed.emit(err_null)
		return err_null

	if session.is_empty() and _question_service.has_active_session():
		session = _question_service.get_active_session()

	if not _question_service.has_active_session():
		var err_no_session: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION_SESSION, "QuestionService has no active session to bind")
		push_error("QuestionPresentationController.bind_existing_session: QuestionService has no active session to bind")
		question_failed.emit(err_no_session)
		return err_no_session

	if not (session is Dictionary) or session.is_empty() or not session.has("session_id") or not (session["session_id"] is String):
		var err_sess_shape: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION_SESSION, "Supplied session dictionary is missing session_id")
		push_error("QuestionPresentationController.bind_existing_session: Supplied session dictionary is missing session_id")
		question_failed.emit(err_sess_shape)
		return err_sess_shape

	if not session.has("question_id") or not (session["question_id"] is String) or String(session["question_id"]).is_empty():
		var err_sess_qid: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION_SESSION, "Supplied session dictionary is missing question_id")
		push_error("QuestionPresentationController.bind_existing_session: Supplied session dictionary is missing question_id")
		question_failed.emit(err_sess_qid)
		return err_sess_qid

	var active_sess_dict: Dictionary = _question_service.get_active_session()
	var active_session_id: String = String(active_sess_dict.get("session_id", ""))
	var supplied_session_id: String = String(session["session_id"])

	if supplied_session_id != active_session_id or active_session_id.is_empty():
		var err_mismatch: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION_SESSION, "Supplied session_id '%s' does not match active QuestionService session '%s'" % [supplied_session_id, active_session_id])
		push_error("QuestionPresentationController.bind_existing_session: " + String(err_mismatch["error_message"]))
		question_failed.emit(err_mismatch)
		return err_mismatch

	if not (question is Dictionary) or question.is_empty() or not question.has("question_id") or not (question["question_id"] is String) or String(question["question_id"]).is_empty() or not question.has("interaction_type"):
		var err_q_shape: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION, "Supplied question view dictionary is missing required fields")
		push_error("QuestionPresentationController.bind_existing_session: Supplied question view dictionary is missing required fields")
		question_failed.emit(err_q_shape)
		return err_q_shape

	var session_qid: String = String(session["question_id"])
	var question_qid: String = String(question["question_id"])
	if question_qid != session_qid:
		var err_qid_mismatch: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION, "Supplied question_id '%s' does not match active session question_id '%s'" % [question_qid, session_qid])
		push_error("QuestionPresentationController.bind_existing_session: " + String(err_qid_mismatch["error_message"]))
		question_failed.emit(err_qid_mismatch)
		return err_qid_mismatch

	if question.has("answer_spec"):
		var err_leak: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION, "answer_spec leaked into presentation view")
		push_error("QuestionPresentationController.bind_existing_session: answer_spec leaked into presentation view")
		question_failed.emit(err_leak)
		return err_leak

	if _question_panel != null:
		var panel_ok: bool = _question_panel.setup_question(question)
		if not panel_ok:
			var err_panel: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION, "Failed to setup QuestionPanel with question view")
			push_error("QuestionPresentationController.bind_existing_session: Failed to setup QuestionPanel with question view")
			question_failed.emit(err_panel)
			return err_panel

	_active_session_id = supplied_session_id
	_active_interaction_type = String(question["interaction_type"])
	_completed = false

	return {
		"success": true,
		"session": session.duplicate(true),
		"question": question.duplicate(true)
	}

func submit_answer(interaction_payload: Dictionary) -> Dictionary:
	if _active_session_id.is_empty() and _question_service != null and _question_service.has_active_session():
		var active_sess: Dictionary = _question_service.get_active_session()
		_active_session_id = String(active_sess.get("session_id", ""))
		if _question_panel != null and _question_panel.get("_question_view") is Dictionary:
			var q_view: Dictionary = _question_panel.get("_question_view") as Dictionary
			_active_interaction_type = String(q_view.get("interaction_type", ""))

	if _question_service == null or _active_session_id.is_empty() or _completed:
		var err_no_sess: Dictionary = _error(QuestionErrorCodes.INVALID_QUESTION_SESSION, "No active or uncompleted QuestionSession")
		push_error("QuestionPresentationController.submit_answer: No active or uncompleted QuestionSession")
		if _question_panel != null and _question_panel.has_method("on_submission_failed"):
			_question_panel.call("on_submission_failed", err_no_sess)
		question_failed.emit(err_no_sess)
		return err_no_sess

	var answer_payload: Dictionary = {
		"session_id": _active_session_id,
		"interaction_type": _active_interaction_type,
		"payload": interaction_payload
	}

	var response: Dictionary = _question_service.submit_answer(answer_payload)
	if not bool(response.get("success", false)):
		if _question_panel != null and _question_panel.has_method("on_submission_failed"):
			_question_panel.call("on_submission_failed", response)
		question_failed.emit(response)
		return response

	var result: Dictionary = (response.get("result", {}) as Dictionary).duplicate(true)
	_completed = true

	if _question_panel != null:
		_question_panel.show_feedback(result)

	var session_completed_id: String = _active_session_id
	_active_session_id = ""
	_active_interaction_type = ""

	# Emit completion signal exactly once for this session
	question_completed.emit(result)
	return {"success": true, "result": result}

func has_active_session() -> bool:
	return not _active_session_id.is_empty() and not _completed

func is_completed() -> bool:
	return _completed

func get_active_session_id() -> String:
	return _active_session_id

func _on_panel_continue() -> void:
	continue_requested.emit()

func _on_panel_retry() -> void:
	_completed = false
	retry_requested.emit()

func _error(code: String, message: String) -> Dictionary:
	return {"success": false, "error_code": code, "error_message": message}
