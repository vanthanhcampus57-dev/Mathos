class_name ValidateContent
extends SceneTree

## Foundation Content Validator for Mathos.
## Validates game_config.json and canonical content directories.

func _init() -> void:
	print("==========================================")
	print("MATHOS FOUNDATION CONTENT VALIDATION")
	print("==========================================")

	var valid: bool = true

	# 1 & 2 & 3: Load, parse UTF-8 JSON, check schema & required fields
	valid = validate_game_config() and valid

	# 4: Check canonical content directories existence
	valid = validate_content_directories() and valid

	print("==========================================")
	if valid:
		print("FOUNDATION VALIDATION PASS")
		print("==========================================")
		quit(0)
	else:
		print("FOUNDATION VALIDATION FAIL")
		print("==========================================")
		quit(1)

func validate_game_config() -> bool:
	var config_path: String = "res://content/config/game_config.json"
	print("[VALIDATOR] Checking " + config_path + "...")

	if not FileAccess.file_exists(config_path):
		print("[VALIDATOR] ERROR: Config file missing at " + config_path)
		return false

	var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		print("[VALIDATOR] ERROR: Cannot open " + config_path)
		return false

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_text)
	if parse_result != OK:
		print("[VALIDATOR] ERROR: JSON parse error at line " + str(json.get_error_line()) + ": " + json.get_error_message())
		return false

	var data: Variant = json.get_data()
	if not (data is Dictionary):
		print("[VALIDATOR] ERROR: Root element of game_config.json is not a Dictionary")
		return false

	var config: Dictionary = data as Dictionary

	# Schema version check
	if not config.has("schema_version") or int(config["schema_version"]) != 1:
		print("[VALIDATOR] ERROR: schema_version missing or != 1")
		return false

	# Required config fields check
	var required_fields: Array[String] = [
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
			print("[VALIDATOR] ERROR: Missing required foundation field '" + field + "'")
			return false

	# Range / type validations
	if int(config["difficulty_min"]) < 1 or int(config["difficulty_max"]) > 10 or int(config["difficulty_min"]) > int(config["difficulty_max"]):
		print("[VALIDATOR] ERROR: Invalid difficulty bounds")
		return false

	print("[VALIDATOR] Config schema and required fields... OK")
	return true

func validate_content_directories() -> bool:
	print("[VALIDATOR] Checking canonical content directories...")
	var canonical_dirs: Array[String] = [
		"res://content/config",
		"res://content/dungeons",
		"res://content/stages",
		"res://content/story",
		"res://content/lessons",
		"res://content/practice",
		"res://content/questions",
		"res://content/cards",
		"res://content/enemies",
		"res://content/rewards"
	]

	for dir_path in canonical_dirs:
		if not DirAccess.dir_exists_absolute(dir_path):
			print("[VALIDATOR] ERROR: Canonical content directory missing: " + dir_path)
			return false

	print("[VALIDATOR] Canonical content directories structure... OK")
	return true
