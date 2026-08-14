class_name ContentValidationReport
extends RefCounted

## Report detailing all issues discovered during content validation.

var issues: Array[ContentValidationIssue] = []
var blocked_stage_ids: Array[String] = []
var rejected_item_ids: Array[String] = []
var publication_allowed: bool = false

func add_issue(issue: ContentValidationIssue) -> void:
	issues.append(issue)
	if issue.severity == ContentValidationIssue.Severity.BLOCK_STAGE and issue.content_id != "":
		if not blocked_stage_ids.has(issue.content_id):
			blocked_stage_ids.append(issue.content_id)
	elif issue.severity == ContentValidationIssue.Severity.REJECT_ITEM and issue.content_id != "":
		if not rejected_item_ids.has(issue.content_id):
			rejected_item_ids.append(issue.content_id)

func get_count_by_severity(sev: ContentValidationIssue.Severity) -> int:
	var count: int = 0
	for issue in issues:
		if issue.severity == sev:
			count += 1
	return count

func has_fatal() -> bool:
	return get_count_by_severity(ContentValidationIssue.Severity.FATAL) > 0

func is_stage_blocked(stage_id: String) -> bool:
	return blocked_stage_ids.has(stage_id)

func is_item_rejected(item_id: String) -> bool:
	return rejected_item_ids.has(item_id)
