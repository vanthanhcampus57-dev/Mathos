class_name TestRunner
extends SceneTree

## Headless Test Runner for Mathos task verification.
## Executes TEST-BOOT-001, TEST-SMOKE-001, TEST-CONFIG-001, CONTENT-001..028, and QUESTION-001..026.

func _init() -> void:
	print("==========================================")
	print("MATHOS HEADLESS TEST HARNESS STARTING")
	print("==========================================")

	var all_passed: bool = true

	all_passed = run_smoke_test() and all_passed
	all_passed = run_boot_test() and all_passed
	all_passed = run_config_test() and all_passed
	all_passed = TestContentRepository.run_all_tests() and all_passed
	all_passed = TestQuestionRuntime.run_all_tests() and all_passed

	print("==========================================")
	if all_passed:
		print("ALL INITIALIZATION, CONTENT, AND QUESTION TESTS PASSED")
		print("==========================================")
		quit(0)
	else:
		print("TEST SUITE FAILED")
		print("==========================================")
		quit(1)

func run_smoke_test() -> bool:
	print("[TEST-SMOKE-001] Test harness execution check... PASS")
	return true

func run_boot_test() -> bool:
	print("[TEST-BOOT-001] Verifying AppRoot scene loading...")
	var scene_path: String = "res://src/app/app_root.tscn"
	if not ResourceLoader.exists(scene_path):
		print("[TEST-BOOT-001] FAIL: AppRoot scene missing at " + scene_path)
		return false

	var packed_scene: PackedScene = ResourceLoader.load(scene_path) as PackedScene
	if packed_scene == null:
		print("[TEST-BOOT-001] FAIL: Unable to parse/load AppRoot scene.")
		return false

	var instance: Node = packed_scene.instantiate()
	if instance == null:
		print("[TEST-BOOT-001] FAIL: Unable to instantiate AppRoot scene.")
		return false

	instance.free()
	print("[TEST-BOOT-001] AppRoot scene parse and load... PASS")
	return true

func run_config_test() -> bool:
	print("[TEST-CONFIG-001] Verifying content/config/game_config.json...")
	var config_path: String = "res://content/config/game_config.json"

	if not FileAccess.file_exists(config_path):
		print("[TEST-CONFIG-001] FAIL: Config file missing at " + config_path)
		return false

	var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		print("[TEST-CONFIG-001] FAIL: Cannot open " + config_path)
		return false

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_text)
	if parse_result != OK:
		print("[TEST-CONFIG-001] FAIL: JSON parse error: " + json.get_error_message())
		return false

	var data: Variant = json.get_data()
	if not (data is Dictionary):
		print("[TEST-CONFIG-001] FAIL: Root JSON is not a Dictionary")
		return false

	var config: Dictionary = data as Dictionary

	var required_fields: Array[String] = [
		"schema_version",
		"game_version",
		"content_version",
		"initial_dungeon_id",
		"initial_stage_id",
		"difficulty_min",
		"difficulty_max",
		"minimum_valid_candidates_per_required_scope",
		"default_practice_question_count",
		"adaptive_recent_record_limit",
		"player_stats",
		"performance_grade_thresholds",
		"supported_interaction_types"
	]

	for field in required_fields:
		if not config.has(field):
			print("[TEST-CONFIG-001] FAIL: Missing required field '" + field + "'")
			return false

	if int(config["schema_version"]) != 1:
		print("[TEST-CONFIG-001] FAIL: Invalid schema_version (must be 1)")
		return false

	if int(config["difficulty_min"]) != 1 or int(config["difficulty_max"]) != 5:
		print("[TEST-CONFIG-001] FAIL: Invalid difficulty_min/max range")
		return false

	print("[TEST-CONFIG-001] game_config.json schema validation... PASS")
	return true
