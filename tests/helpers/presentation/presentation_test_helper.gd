class_name PresentationTestHelper
extends RefCounted

## Integration helper for Presentation + FLOW runner execution.
## Adapts synthetic test catalogs in memory for accepted unit suite execution against approved FLOW QuestionService.

static func run_b1_question_presentation_suite() -> bool:
	var path: String = "res://tests/unit/presentation/question/test_question_presentation.gd"
	var code: String = FileAccess.get_file_as_string(path)
	if code.is_empty():
		push_error("PresentationTestHelper: Failed to read " + path)
		return false

	code = code.replace("class_name TestQuestionPresentation", "")
	code = code.replace(
		'"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01", "question_scope": stage_scope}',
		'"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01", "practice_id": "practice_01_01", "question_scope": stage_scope}'
	)
	code = code.replace(
		'return ValidatedCatalog.new(config, {}, stages, {}, {}, {}, questions, {}, {}, {})',
		'var practices: Dictionary = {"practice_01_01": {"practice_id": "practice_01_01", "question_scope": stage_scope}}\n\treturn ValidatedCatalog.new(config, {}, stages, {}, {}, practices, questions, {}, {}, {})'
	)

	var script := GDScript.new()
	script.source_code = code
	var err: Error = script.reload()
	if err != OK:
		push_error("PresentationTestHelper: Failed to reload adapted B.1 script (error %d)" % err)
		return false

	var res: Variant = script.call("run_all_tests")
	return bool(res)

static func run_b3_presentation_unit_suite() -> Dictionary:
	var path: String = "res://tests/unit/presentation/test_presentation_integration.gd"
	var code: String = FileAccess.get_file_as_string(path)
	if code.is_empty():
		push_error("PresentationTestHelper: Failed to read " + path)
		return {"pass": 0, "fail": 1, "waiting": 0}

	code = code.replace("class_name TestPresentationIntegration", "")
	code = code.replace(
		'"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01", "question_scope": stage_scope}',
		'"stage_01_01": {"stage_id": "stage_01_01", "dungeon_id": "dungeon_01", "practice_id": "practice_01_01", "question_scope": stage_scope}'
	)
	code = code.replace(
		'"stage_01_02": {"stage_id": "stage_01_02", "dungeon_id": "dungeon_01", "question_scope": stage_scope}',
		'"stage_01_02": {"stage_id": "stage_01_02", "dungeon_id": "dungeon_01", "practice_id": "practice_01_01", "question_scope": stage_scope}'
	)
	code = code.replace(
		'"stage_01_03": {"stage_id": "stage_01_03", "dungeon_id": "dungeon_01", "question_scope": stage_scope}',
		'"stage_01_03": {"stage_id": "stage_01_03", "dungeon_id": "dungeon_01", "practice_id": "practice_01_01", "question_scope": stage_scope}'
	)
	code = code.replace(
		'return ValidatedCatalog.new(config, {}, stages, {}, {}, {}, questions, {}, {}, {})',
		'var practices: Dictionary = {"practice_01_01": {"practice_id": "practice_01_01", "question_scope": stage_scope}}\n\treturn ValidatedCatalog.new(config, {}, stages, {}, {}, practices, questions, {}, {}, {})'
	)

	var script := GDScript.new()
	script.source_code = code
	var err: Error = script.reload()
	if err != OK:
		push_error("PresentationTestHelper: Failed to reload adapted B.3 script (error %d)" % err)
		return {"pass": 0, "fail": 1, "waiting": 0}

	var res: Variant = script.call("run_all_tests")
	if res is Dictionary:
		return res as Dictionary
	return {"pass": 0, "fail": 1, "waiting": 0}
