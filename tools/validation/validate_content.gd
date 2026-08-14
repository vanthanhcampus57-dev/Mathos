class_name ValidateContent
extends SceneTree

## Foundation & Full Content Validator CLI for Mathos.
## Supports `--mode foundation` and `--mode full --content-root <root>`.

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = "foundation"
	var content_root: String = "res://content"

	var i: int = 0
	while i < args.size():
		var arg: String = args[i]
		if arg == "--mode" and i + 1 < args.size():
			mode = args[i + 1]
			i += 1
		elif arg == "--content-root" and i + 1 < args.size():
			content_root = args[i + 1]
			i += 1
		i += 1

	if mode == "foundation":
		_run_foundation_mode()
	elif mode == "full":
		_run_full_mode(content_root)
	else:
		print("Unknown mode: " + mode)
		quit(1)

func _run_foundation_mode() -> void:
	print("==========================================")
	print("MATHOS FOUNDATION CONTENT VALIDATION")
	print("==========================================")

	var valid: bool = true
	valid = validate_game_config() and valid
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

func _run_full_mode(content_root: String) -> void:
	print("==========================================")
	print("MATHOS FULL CONTENT VALIDATION")
	print("Content Root: " + content_root)
	print("==========================================")

	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate(content_root)

	print("Total Issues: " + str(report.issues.size()))
	print("  FATAL: " + str(report.get_count_by_severity(ContentValidationIssue.Severity.FATAL)))
	print("  BLOCK_STAGE: " + str(report.get_count_by_severity(ContentValidationIssue.Severity.BLOCK_STAGE)))
	print("  REJECT_ITEM: " + str(report.get_count_by_severity(ContentValidationIssue.Severity.REJECT_ITEM)))
	print("  WARNING: " + str(report.get_count_by_severity(ContentValidationIssue.Severity.WARNING)))

	for issue in report.issues:
		print(" [%s] %s (%s:%s) -> %s" % [
			issue.get_severity_string(), issue.rule_code, issue.content_type, issue.content_id, issue.message
		])

	print("==========================================")
	if report.publication_allowed:
		print("FULL CONTENT VALIDATION PASS")
		print("==========================================")
		quit(0)
	else:
		print("FULL CONTENT VALIDATION FAIL")
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

	if not config.has("schema_version") or int(config["schema_version"]) != 1:
		print("[VALIDATOR] ERROR: schema_version missing or != 1")
		return false

	var required_fields: Array[String] = [
		"game_version", "content_version", "initial_dungeon_id", "initial_stage_id",
		"difficulty_min", "difficulty_max", "minimum_valid_candidates_per_required_scope",
		"default_practice_question_count", "adaptive_recent_record_limit", "player_stats",
		"performance_grade_thresholds", "supported_interaction_types"
	]

	for field in required_fields:
		if not config.has(field):
			print("[VALIDATOR] ERROR: Missing required foundation field '" + field + "'")
			return false

	if int(config["difficulty_min"]) < 1 or int(config["difficulty_max"]) > 10 or int(config["difficulty_min"]) > int(config["difficulty_max"]):
		print("[VALIDATOR] ERROR: Invalid difficulty bounds")
		return false

	print("[VALIDATOR] Config schema and required fields... OK")
	return true

func validate_content_directories() -> bool:
	print("[VALIDATOR] Checking canonical content directories...")
	var canonical_dirs: Array[String] = [
		"res://content/config", "res://content/dungeons", "res://content/stages",
		"res://content/story", "res://content/lessons", "res://content/practice",
		"res://content/questions", "res://content/cards", "res://content/enemies", "res://content/rewards"
	]

	for dir_path in canonical_dirs:
		if not DirAccess.dir_exists_absolute(dir_path):
			print("[VALIDATOR] ERROR: Canonical content directory missing: " + dir_path)
			return false

	print("[VALIDATOR] Canonical content directories structure... OK")
	return true
