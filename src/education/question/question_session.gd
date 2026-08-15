class_name QuestionSession
extends RefCounted

## Transient single-question runtime session. Never persisted.
var session_id: String
var request_id: String
var question_id: String
var context: String
var started_at_msec: int
var submission_locked: bool = false
var completed: bool = false

func _init(
	p_session_id: String,
	p_request_id: String,
	p_question_id: String,
	p_context: String,
	p_started_at_msec: int
) -> void:
	session_id = p_session_id
	request_id = p_request_id
	question_id = p_question_id
	context = p_context
	started_at_msec = p_started_at_msec

func to_dictionary() -> Dictionary:
	return {
		"session_id": session_id,
		"request_id": request_id,
		"question_id": question_id,
		"context": context,
		"started_at_msec": started_at_msec,
		"submission_locked": submission_locked,
		"completed": completed
	}
