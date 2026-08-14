class_name ContentRepository
extends RefCounted

## Public API boundary for static content loading and validated catalog publication.

var _catalog: ValidatedCatalog = null
var _last_report: ContentValidationReport = null

func load_and_validate(content_root: String = "res://content") -> ContentValidationReport:
	_catalog = null
	var validator: ContentValidator = ContentValidator.new()
	var result: Dictionary = validator.validate(content_root)
	_last_report = result["report"] as ContentValidationReport

	if _last_report.publication_allowed:
		_catalog = result["catalog"] as ValidatedCatalog

	return _last_report

func get_catalog() -> ValidatedCatalog:
	return _catalog

func get_last_report() -> ContentValidationReport:
	return _last_report
