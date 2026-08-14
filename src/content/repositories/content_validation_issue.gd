class_name ContentValidationIssue
extends RefCounted

## Represents a structured issue produced during content validation.

enum Severity {
	FATAL,
	BLOCK_STAGE,
	REJECT_ITEM,
	WARNING
}

var severity: Severity = Severity.FATAL
var rule_code: String = ""
var content_type: String = ""
var content_id: String = ""
var file_path: String = ""
var message: String = ""

func _init(
	p_severity: Severity = Severity.FATAL,
	p_rule_code: String = "",
	p_content_type: String = "",
	p_content_id: String = "",
	p_file_path: String = "",
	p_message: String = ""
) -> void:
	severity = p_severity
	rule_code = p_rule_code
	content_type = p_content_type
	content_id = p_content_id
	file_path = p_file_path
	message = p_message

func get_severity_string() -> String:
	match severity:
		Severity.FATAL: return "FATAL"
		Severity.BLOCK_STAGE: return "BLOCK_STAGE"
		Severity.REJECT_ITEM: return "REJECT_ITEM"
		Severity.WARNING: return "WARNING"
		_: return "UNKNOWN"
