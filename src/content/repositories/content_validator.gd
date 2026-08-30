class_name ContentValidator
extends RefCounted

## Full Content Validation Engine for Mathos.
## Enforces Syntax, Schema, Canonical ID, Referential, Semantic, and Cross-Content rules.

const CANONICAL_DUNGEONS: Array[String] = ["dungeon_01", "dungeon_02", "dungeon_03", "dungeon_04"]
const TOPIC_MAPPING: Dictionary = {
	"dungeon_01": "trial_sample_event",
	"dungeon_02": "classical_probability",
	"dungeon_03": "addition_rule",
	"dungeon_04": "multiplication_independence"
}
const BOSS_MAPPING: Dictionary = {
	"stage_01_05": "enemy_d1_stochas",
	"stage_02_05": "enemy_d2_aleator",
	"stage_03_05": "enemy_d3_melkor",
	"stage_04_05": "enemy_d4_aphodius"
}
const FRAGMENT_MAPPING: Dictionary = {
	"stage_01_05": "fragment_01",
	"stage_02_05": "fragment_02",
	"stage_03_05": "fragment_03",
	"stage_04_05": "fragment_04"
}

var _id_regex: RegEx = null

func _init() -> void:
	_id_regex = RegEx.new()
	_id_regex.compile("^[a-z][a-z0-9_]*$")

func validate(content_root: String) -> Dictionary:
	var report: ContentValidationReport = ContentValidationReport.new()

	var config: Dictionary = {}
	var dungeons: Dictionary = {}
	var stages: Dictionary = {}
	var story: Dictionary = {}
	var lessons: Dictionary = {}
	var practice: Dictionary = {}
	var questions: Dictionary = {}
	var cards: Dictionary = {}
	var enemies: Dictionary = {}
	var rewards: Dictionary = {}
	var math_knowledge: Dictionary = {}
	var question_generation: Dictionary = {}

	# Track global top-level IDs to ensure uniqueness across categories
	var global_ids: Dictionary = {}

	# Step 1: Load and Validate GameConfig
	config = _load_and_validate_config(content_root, report)

	# Step 2: Load Category Files & Validate Item Schemas
	_load_category(content_root, "dungeons", dungeons, report, global_ids, _validate_dungeon)
	_load_category(content_root, "stages", stages, report, global_ids, _validate_stage)
	_load_category(content_root, "story", story, report, global_ids, _validate_story)
	_load_category(content_root, "lessons", lessons, report, global_ids, _validate_lesson)
	_load_category(content_root, "practice", practice, report, global_ids, _validate_practice)
	_load_category(content_root, "questions", questions, report, global_ids, _validate_question)
	_load_category(content_root, "cards", cards, report, global_ids, _validate_card)
	_load_category(content_root, "enemies", enemies, report, global_ids, _validate_enemy)
	_load_category(content_root, "rewards", rewards, report, global_ids, _validate_reward)
	_load_category(content_root, "math_knowledge", math_knowledge, report, global_ids, _validate_math_knowledge_pack)
	_load_category(content_root, "question_generation", question_generation, report, global_ids, _validate_question_generation_spec)

	# Step 3: Validate References & Asset Refs
	_validate_references(dungeons, stages, story, lessons, practice, questions, cards, enemies, rewards, report)
	_validate_qgen_references(math_knowledge, question_generation, report)

	# Step 4: Semantic & Cross-Content Validation
	_validate_cross_content(dungeons, stages, story, lessons, practice, questions, cards, enemies, rewards, report)

	# Step 5: Question Pool Validation
	var min_pool: int = 3
	if config.has("minimum_valid_candidates_per_required_scope"):
		min_pool = int(config["minimum_valid_candidates_per_required_scope"])
	_validate_question_pools(stages, questions, min_pool, report)

	# Determine if catalog publication is allowed
	report.publication_allowed = not report.has_fatal() and report.blocked_stage_ids.size() == 0

	var catalog: ValidatedCatalog = null
	if report.publication_allowed:
		catalog = ValidatedCatalog.new(
			config, dungeons, stages, story, lessons, practice, questions, cards, enemies, rewards,
			math_knowledge, question_generation
		)

	return {
		"report": report,
		"catalog": catalog
	}

# --- CONFIG LOADING & VALIDATION ---
func _load_and_validate_config(content_root: String, report: ContentValidationReport) -> Dictionary:
	var config_path: String = content_root.path_join("config/game_config.json")
	var load_res: Dictionary = JSONContentLoader.load_json_file(config_path)

	if not load_res["success"]:
		report.add_issue(ContentValidationIssue.new(
			ContentValidationIssue.Severity.FATAL,
			"ERR_SYNTAX_CONFIG", "config", "game_config", config_path,
			load_res["error"]
		))
		return {}

	var config: Dictionary = load_res["data"] as Dictionary
	var required_fields: Array[String] = [
		"schema_version", "game_version", "content_version", "initial_dungeon_id",
		"initial_stage_id", "difficulty_min", "difficulty_max",
		"minimum_valid_candidates_per_required_scope", "default_practice_question_count",
		"adaptive_recent_record_limit", "player_stats", "performance_grade_thresholds",
		"supported_interaction_types"
	]

	for f in required_fields:
		if not config.has(f):
			report.add_issue(ContentValidationIssue.new(
				ContentValidationIssue.Severity.FATAL,
				"ERR_SCHEMA_CONFIG", "config", "game_config", config_path,
				"Missing required field '" + f + "'"
			))

	if int(config.get("schema_version", 0)) != 1:
		report.add_issue(ContentValidationIssue.new(
			ContentValidationIssue.Severity.FATAL,
			"ERR_SCHEMA_VERSION", "config", "game_config", config_path,
			"schema_version must be 1"
		))

	return config

# --- CATEGORY FILE LOADER ---
func _load_category(
	content_root: String,
	folder_name: String,
	out_dict: Dictionary,
	report: ContentValidationReport,
	global_ids: Dictionary,
	validator_func: Callable
) -> void:
	var dir_path: String = content_root.path_join(folder_name)
	if not DirAccess.dir_exists_absolute(dir_path):
		return

	var files: Array[String] = _get_all_json_files(dir_path)
	for fpath in files:
		var load_res: Dictionary = JSONContentLoader.load_json_file(fpath)
		if not load_res["success"]:
			report.add_issue(ContentValidationIssue.new(
				ContentValidationIssue.Severity.FATAL,
				"ERR_SYNTAX_JSON", folder_name, fpath.get_file(), fpath,
				load_res["error"]
			))
			continue

		var raw_data: Variant = load_res["data"]
		var items_to_validate: Array = []
		if raw_data is Dictionary:
			items_to_validate.append(raw_data)
		elif raw_data is Array:
			items_to_validate = raw_data
		else:
			report.add_issue(ContentValidationIssue.new(
				ContentValidationIssue.Severity.FATAL,
				"ERR_INVALID_TOP_LEVEL", folder_name, fpath.get_file(), fpath,
				"Top level JSON must be Object or Array of Objects"
			))
			continue

		for item_variant in items_to_validate:
			if not (item_variant is Dictionary):
				report.add_issue(ContentValidationIssue.new(
					ContentValidationIssue.Severity.FATAL,
					"ERR_INVALID_ITEM_TYPE", folder_name, "", fpath,
					"Item in JSON array is not an Object"
				))
				continue

			var item: Dictionary = item_variant as Dictionary
			var id_field: String = _get_id_field_for_category(folder_name)
			var item_id: String = String(item.get(id_field, ""))

			# ID format validation
			if item_id == "" or not _id_regex.search(item_id):
				var sev: ContentValidationIssue.Severity = ContentValidationIssue.Severity.FATAL
				if folder_name == "questions":
					sev = ContentValidationIssue.Severity.REJECT_ITEM
				report.add_issue(ContentValidationIssue.new(
					sev, "ERR_CANONICAL_ID_FORMAT", folder_name, item_id, fpath,
					"Invalid or non-snake_case canonical ID: '" + item_id + "'"
				))
				continue

			# Duplicate global ID check
			if global_ids.has(item_id):
				var sev: ContentValidationIssue.Severity = ContentValidationIssue.Severity.FATAL
				if folder_name == "questions":
					sev = ContentValidationIssue.Severity.REJECT_ITEM
				report.add_issue(ContentValidationIssue.new(
					sev, "ERR_DUPLICATE_ID", folder_name, item_id, fpath,
					"Duplicate global top-level ID: '" + item_id + "'"
				))
				continue

			# Execute specific schema validator
			var is_valid: bool = validator_func.call(item, fpath, report)
			if is_valid:
				global_ids[item_id] = folder_name
				out_dict[item_id] = item

func _get_all_json_files(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if not file_name.begins_with("."):
					result.append_array(_get_all_json_files(dir_path.path_join(file_name)))
			else:
				if file_name.ends_with(".json"):
					result.append(dir_path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	return result

func _get_id_field_for_category(category: String) -> String:
	match category:
		"dungeons": return "dungeon_id"
		"stages": return "stage_id"
		"story": return "story_id"
		"lessons": return "lesson_id"
		"practice": return "practice_id"
		"questions": return "question_id"
		"cards": return "card_id"
		"enemies": return "enemy_id"
		"rewards": return "reward_id"
		_: return "id"

# --- ITEM SCHEMA VALIDATORS ---
func _validate_dungeon(item: Dictionary, fpath: String, report: ContentValidationReport) -> bool:
	var id: String = item.get("dungeon_id", "")
	var valid: bool = true
	for field in ["schema_version", "dungeon_id", "order", "display_name", "topic_id", "learning_objective", "stage_ids", "boss_enemy_id", "fragment_id"]:
		if not item.has(field):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_MISSING_FIELD", "dungeons", id, fpath, "Missing required field '" + field + "'"))
			valid = false
	if item.has("display_name") and (not (item["display_name"] is String) or String(item["display_name"]).is_empty()):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_EMPTY_STRING", "dungeons", id, fpath, "display_name must be a non-empty String"))
		valid = false
	if item.has("learning_objective") and (not (item["learning_objective"] is String) or String(item["learning_objective"]).is_empty()):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_EMPTY_STRING", "dungeons", id, fpath, "learning_objective must be a non-empty String"))
		valid = false
	if int(item.get("schema_version", 0)) != 1:
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_VERSION", "dungeons", id, fpath, "schema_version must be 1"))
		valid = false
	if int(item.get("order", 0)) < 1 or int(item.get("order", 0)) > 4:
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SEMANTIC_DUNGEON_ORDER", "dungeons", id, fpath, "order must be between 1 and 4"))
		valid = false
	if not (item.get("stage_ids") is Array) or (item.get("stage_ids") as Array).size() != 5:
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SEMANTIC_STAGE_IDS_COUNT", "dungeons", id, fpath, "stage_ids must contain exactly 5 stage IDs"))
		valid = false
	return valid

func _validate_stage(item: Dictionary, fpath: String, report: ContentValidationReport) -> bool:
	var id: String = item.get("stage_id", "")
	var valid: bool = true
	var req_fields: Array[String] = ["schema_version", "stage_id", "dungeon_id", "order_in_dungeon", "title", "learning_objective", "learning_scope", "phase_sequence", "encounter_mode", "completion_rule", "reward_id", "card_pool_ids", "intent_enabled"]
	for f in req_fields:
		if not item.has(f):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_SCHEMA_MISSING_FIELD", "stages", id, fpath, "Missing required field '" + f + "'"))
			valid = false

	if item.has("title") and (not (item["title"] is String) or String(item["title"]).is_empty()):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_SCHEMA_EMPTY_STRING", "stages", id, fpath, "stage title must be a non-empty String"))
		valid = false
	if item.has("learning_objective") and (not (item["learning_objective"] is String) or String(item["learning_objective"]).is_empty()):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_SCHEMA_EMPTY_STRING", "stages", id, fpath, "learning_objective must be a non-empty String"))
		valid = false

	if int(item.get("order_in_dungeon", 0)) < 1 or int(item.get("order_in_dungeon", 0)) > 5:
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_SEMANTIC_STAGE_ORDER", "stages", id, fpath, "order_in_dungeon must be 1..5"))
		valid = false
	return valid

func _validate_story(item: Dictionary, fpath: String, report: ContentValidationReport) -> bool:
	var id: String = item.get("story_id", "")
	var valid: bool = true
	for f in ["schema_version", "story_id", "dungeon_id", "stage_id", "dialogue_steps"]:
		if not item.has(f):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_MISSING_FIELD", "story", id, fpath, "Missing required field '" + f + "'"))
			valid = false
	return valid

func _validate_lesson(item: Dictionary, fpath: String, report: ContentValidationReport) -> bool:
	var id: String = item.get("lesson_id", "")
	var valid: bool = true
	for f in ["schema_version", "lesson_id", "dungeon_id", "topic_id", "title", "sections"]:
		if not item.has(f):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_MISSING_FIELD", "lessons", id, fpath, "Missing required field '" + f + "'"))
			valid = false

	if item.has("title") and (not (item["title"] is String) or String(item["title"]).is_empty()):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_EMPTY_STRING", "lessons", id, fpath, "lesson title must be a non-empty String"))
		valid = false

	if item.has("sections"):
		var sections: Variant = item["sections"]
		if not (sections is Array) or (sections as Array).is_empty():
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_INVALID_SECTIONS", "lessons", id, fpath, "sections must be a non-empty array"))
			valid = false
		else:
			for sec_idx in range((sections as Array).size()):
				var sec_var: Variant = (sections as Array)[sec_idx]
				if not (sec_var is Dictionary):
					report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_INVALID_SECTION", "lessons", id, fpath, "section at index %d is not an Object" % sec_idx))
					valid = false
					continue
				var sec: Dictionary = sec_var as Dictionary
				for req_sec_f in ["header", "body"]:
					if not sec.has(req_sec_f) or not (sec[req_sec_f] is String) or String(sec[req_sec_f]).is_empty():
						report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_MISSING_FIELD", "lessons", id, fpath, "section at index %d requires non-empty string '%s'" % [sec_idx, req_sec_f]))
						valid = false
				if sec.has("speaker"):
					if not (sec["speaker"] is String) or String(sec["speaker"]).is_empty():
						report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_EMPTY_STRING", "lessons", id, fpath, "section speaker at index %d must be a non-empty string" % sec_idx))
						valid = false

	return valid

func _validate_practice(item: Dictionary, fpath: String, report: ContentValidationReport) -> bool:
	var id: String = item.get("practice_id", "")
	var valid: bool = true
	for f in ["schema_version", "practice_id", "dungeon_id", "topic_id", "question_scope", "question_count"]:
		if not item.has(f):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_MISSING_FIELD", "practice", id, fpath, "Missing required field '" + f + "'"))
			valid = false
	return valid

func _validate_question(item: Dictionary, fpath: String, report: ContentValidationReport) -> bool:
	var id: String = item.get("question_id", "")
	var valid: bool = true
	var req_fields: Array[String] = ["schema_version", "question_id", "dungeon_id", "topic_id", "learning_objective", "prompt", "explanation", "difficulty", "interaction_type", "interaction_payload", "answer_spec", "allowed_contexts"]
	for f in req_fields:
		if not item.has(f):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_SCHEMA_MISSING_FIELD", "questions", id, fpath, "Missing required field '" + f + "'"))
			valid = false

	var diff: int = int(item.get("difficulty", 0))
	if diff < 1 or diff > 5:
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_SEMANTIC_DIFFICULTY", "questions", id, fpath, "difficulty must be 1..5"))
		valid = false

	var interaction_type: String = item.get("interaction_type", "")
	if not ["multiple_choice", "drag_drop", "matching", "input"].has(interaction_type):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_SCHEMA_ENUM", "questions", id, fpath, "Invalid interaction_type: " + interaction_type))
		valid = false
	else:
		var payload: Dictionary = item.get("interaction_payload", {})
		var answer: Dictionary = item.get("answer_spec", {})
		match interaction_type:
			"multiple_choice":
				if not payload.has("options") or not (payload["options"] is Array) or (payload["options"] as Array).size() < 2:
					report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_PAYLOAD_MC", "questions", id, fpath, "multiple_choice options must be array of size >= 2"))
					valid = false
				if not answer.has("correct_option_id") or not _question_dict_has_only_fields(answer, ["correct_option_id"]):
					report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_ANSWER_MC", "questions", id, fpath, "multiple_choice answer_spec must contain only correct_option_id"))
					valid = false
			"drag_drop":
				if not _validate_drag_drop_question(payload, answer, id, fpath, report):
					valid = false
			"matching":
				if not _validate_matching_question(payload, answer, id, fpath, report):
					valid = false
			"input":
				if not _validate_input_question(payload, answer, id, fpath, report):
					valid = false
	return valid

func _question_dict_has_only_fields(data: Dictionary, allowed_fields: Array[String]) -> bool:
	for key_variant in data.keys():
		if not allowed_fields.has(String(key_variant)):
			return false
	return true

func _question_ids_from_items(items: Array, id_field: String) -> Dictionary:
	var result: Dictionary = {}
	for item_variant in items:
		if not (item_variant is Dictionary):
			return {}
		var item: Dictionary = item_variant as Dictionary
		if not item.has(id_field) or not (item[id_field] is String):
			return {}
		var item_id: String = String(item[id_field])
		if item_id == "" or result.has(item_id):
			return {}
		result[item_id] = true
	return result

func _validate_drag_drop_question(payload: Dictionary, answer: Dictionary, id: String, fpath: String, report: ContentValidationReport) -> bool:
	var valid: bool = true
	if not _question_dict_has_only_fields(answer, ["mappings"]):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_ANSWER_DD_FIELDS", "questions", id, fpath, "drag_drop answer_spec permits only canonical field mappings"))
		valid = false
	if not payload.has("items") or not (payload["items"] is Array) or not payload.has("targets") or not (payload["targets"] is Array):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_PAYLOAD_DD", "questions", id, fpath, "drag_drop requires items and targets arrays"))
		return false
	if not answer.has("mappings") or not (answer["mappings"] is Array) or (answer["mappings"] as Array).is_empty():
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_ANSWER_DD", "questions", id, fpath, "drag_drop answer_spec.mappings must be a non-empty array"))
		return false

	var item_ids: Dictionary = _question_ids_from_items(payload["items"] as Array, "item_id")
	var target_ids: Dictionary = _question_ids_from_items(payload["targets"] as Array, "target_id")
	if item_ids.is_empty() or target_ids.is_empty():
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_PAYLOAD_DD_IDS", "questions", id, fpath, "drag_drop item_id/target_id values must be unique non-empty strings"))
		return false

	var seen_items: Dictionary = {}
	for mapping_variant in answer["mappings"] as Array:
		if not (mapping_variant is Dictionary):
			valid = false
			break
		var mapping: Dictionary = mapping_variant as Dictionary
		if not _question_dict_has_only_fields(mapping, ["item_id", "target_id"]) or not mapping.has("item_id") or not mapping.has("target_id"):
			valid = false
			break
		if not (mapping["item_id"] is String) or not (mapping["target_id"] is String):
			valid = false
			break
		var item_id: String = String(mapping["item_id"])
		var target_id: String = String(mapping["target_id"])
		if not item_ids.has(item_id) or not target_ids.has(target_id) or seen_items.has(item_id):
			valid = false
			break
		seen_items[item_id] = true

	if bool(payload.get("must_place_all", true)) and seen_items.size() != item_ids.size():
		valid = false
	if not valid:
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_ANSWER_DD_MAPPING", "questions", id, fpath, "drag_drop answer_spec.mappings contains an invalid, duplicate, unknown, or incomplete mapping"))
	return valid

func _validate_matching_question(payload: Dictionary, answer: Dictionary, id: String, fpath: String, report: ContentValidationReport) -> bool:
	var valid: bool = true
	if not _question_dict_has_only_fields(answer, ["pairs"]):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_ANSWER_MATCHING_FIELDS", "questions", id, fpath, "matching answer_spec permits only canonical field pairs"))
		valid = false
	if not payload.has("left_items") or not (payload["left_items"] is Array) or not payload.has("right_items") or not (payload["right_items"] is Array):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_PAYLOAD_MATCHING", "questions", id, fpath, "matching requires left_items and right_items arrays"))
		return false
	if not answer.has("pairs") or not (answer["pairs"] is Array):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_ANSWER_MATCHING", "questions", id, fpath, "matching answer_spec.pairs must be an array"))
		return false

	var left_ids: Dictionary = _question_ids_from_items(payload["left_items"] as Array, "item_id")
	var right_ids: Dictionary = _question_ids_from_items(payload["right_items"] as Array, "item_id")
	if left_ids.is_empty() or right_ids.is_empty():
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_PAYLOAD_MATCHING_IDS", "questions", id, fpath, "matching item IDs must be unique non-empty strings"))
		return false

	var pairs: Array = answer["pairs"] as Array
	if pairs.size() != left_ids.size():
		valid = false
	var seen_left: Dictionary = {}
	var seen_right: Dictionary = {}
	var seen_pairs: Dictionary = {}
	for pair_variant in pairs:
		if not (pair_variant is Dictionary):
			valid = false
			break
		var pair: Dictionary = pair_variant as Dictionary
		if not _question_dict_has_only_fields(pair, ["left_id", "right_id"]) or not pair.has("left_id") or not pair.has("right_id"):
			valid = false
			break
		if not (pair["left_id"] is String) or not (pair["right_id"] is String):
			valid = false
			break
		var left_id: String = String(pair["left_id"])
		var right_id: String = String(pair["right_id"])
		var pair_key: String = left_id + "\u001f" + right_id
		if not left_ids.has(left_id) or not right_ids.has(right_id) or seen_left.has(left_id) or seen_right.has(right_id) or seen_pairs.has(pair_key):
			valid = false
			break
		seen_left[left_id] = true
		seen_right[right_id] = true
		seen_pairs[pair_key] = true

	if seen_left.size() != left_ids.size():
		valid = false
	if not valid:
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_ANSWER_MATCHING_PAIR", "questions", id, fpath, "matching answer_spec.pairs must be complete one-to-one ground truth with known unique IDs"))
	return valid

func _validate_input_question(payload: Dictionary, answer: Dictionary, id: String, fpath: String, report: ContentValidationReport) -> bool:
	var allowed_answer_fields: Array[String] = ["accepted_values", "numeric_tolerance", "case_sensitive", "trim_whitespace"]
	if not _question_dict_has_only_fields(answer, allowed_answer_fields):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_ANSWER_INPUT_FIELDS", "questions", id, fpath, "input answer_spec contains a non-canonical field"))
		return false
	if not payload.has("input_type") or not (payload["input_type"] is String) or not ["integer", "float", "string", "symbol"].has(String(payload["input_type"])):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_PAYLOAD_INPUT", "questions", id, fpath, "input interaction_payload.input_type must be integer, float, string, or symbol"))
		return false
	if not answer.has("accepted_values") or not (answer["accepted_values"] is Array) or (answer["accepted_values"] as Array).is_empty():
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_ANSWER_INPUT", "questions", id, fpath, "input answer_spec.accepted_values must be a non-empty array"))
		return false
	if answer.has("numeric_tolerance") and answer["numeric_tolerance"] != null:
		if not (answer["numeric_tolerance"] is int or answer["numeric_tolerance"] is float) or float(answer["numeric_tolerance"]) < 0.0:
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.REJECT_ITEM, "ERR_ANSWER_INPUT_TOLERANCE", "questions", id, fpath, "numeric_tolerance must be null or >= 0"))
			return false
	return true

func _validate_card(item: Dictionary, fpath: String, report: ContentValidationReport) -> bool:
	var id: String = item.get("card_id", "")
	var valid: bool = true
	for f in ["schema_version", "card_id", "name", "card_type", "cost", "effects"]:
		if not item.has(f):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_MISSING_FIELD", "cards", id, fpath, "Missing required field '" + f + "'"))
			valid = false
	var ctype: String = item.get("card_type", "")
	if not ["attack", "shield", "heal"].has(ctype):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_ENUM", "cards", id, fpath, "Invalid card_type: " + ctype))
		valid = false
	return valid

func _validate_enemy(item: Dictionary, fpath: String, report: ContentValidationReport) -> bool:
	var id: String = item.get("enemy_id", "")
	var valid: bool = true
	for f in ["schema_version", "enemy_id", "dungeon_id", "role", "max_hp", "stage_ids", "intent_selection", "intents"]:
		if not item.has(f):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_MISSING_FIELD", "enemies", id, fpath, "Missing required field '" + f + "'"))
			valid = false
	var role: String = item.get("role", "")
	if not ["minion", "elite", "boss"].has(role):
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_ENUM", "enemies", id, fpath, "Invalid enemy role: " + role))
		valid = false
	return valid

func _validate_reward(item: Dictionary, fpath: String, report: ContentValidationReport) -> bool:
	var id: String = item.get("reward_id", "")
	var valid: bool = true
	for f in ["schema_version", "reward_id", "stage_id", "coin_amount", "exp_amount"]:
		if not item.has(f):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_MISSING_FIELD", "rewards", id, fpath, "Missing required field '" + f + "'"))
			valid = false
	return valid

# --- REFERENTIAL VALIDATION ---
func _validate_references(
	dungeons: Dictionary, stages: Dictionary, story: Dictionary, lessons: Dictionary,
	practice: Dictionary, questions: Dictionary, cards: Dictionary, enemies: Dictionary,
	rewards: Dictionary, report: ContentValidationReport
) -> void:
	for st_id in stages:
		var st: Dictionary = stages[st_id]
		# Check story_id ref
		if st.get("story_id") != null and st.get("story_id") != "":
			if not story.has(st["story_id"]):
				report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_DANGLING_REF", "stages", st_id, "", "Dangling story_id: " + String(st["story_id"])))
		# Check lesson_id ref
		if st.get("lesson_id") != null and st.get("lesson_id") != "":
			if not lessons.has(st["lesson_id"]):
				report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_DANGLING_REF", "stages", st_id, "", "Dangling lesson_id: " + String(st["lesson_id"])))
		# Check practice_id ref
		if st.get("practice_id") != null and st.get("practice_id") != "":
			if not practice.has(st["practice_id"]):
				report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_DANGLING_REF", "stages", st_id, "", "Dangling practice_id: " + String(st["practice_id"])))
		# Check enemy_id ref
		if st.get("enemy_id") != null and st.get("enemy_id") != "":
			if not enemies.has(st["enemy_id"]):
				report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_DANGLING_REF", "stages", st_id, "", "Dangling enemy_id: " + String(st["enemy_id"])))
		# Check reward_id ref
		if st.get("reward_id") != null and st.get("reward_id") != "":
			if not rewards.has(st["reward_id"]):
				report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_DANGLING_REF", "stages", st_id, "", "Dangling reward_id: " + String(st["reward_id"])))
		# Check card_pool_ids refs
		var card_pools: Array = st.get("card_pool_ids", [])
		for cid in card_pools:
			if not cards.has(cid):
				report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_DANGLING_REF", "stages", st_id, "", "Dangling card_id in card_pool_ids: " + String(cid)))

# --- CROSS-CONTENT & SEMANTIC VALIDATION ---
func _validate_cross_content(
	dungeons: Dictionary, stages: Dictionary, story: Dictionary, lessons: Dictionary,
	practice: Dictionary, questions: Dictionary, cards: Dictionary, enemies: Dictionary,
	rewards: Dictionary, report: ContentValidationReport
) -> void:
	# 1. Exactly 4 Dungeons
	if dungeons.size() != 4:
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_COMPLETENESS_DUNGEONS", "dungeons", "", "", "V1 requires exactly 4 canonical Dungeons"))

	for d_id in CANONICAL_DUNGEONS:
		if not dungeons.has(d_id):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_MISSING_CANONICAL_DUNGEON", "dungeons", d_id, "", "Missing canonical Dungeon: " + d_id))
		else:
			var d: Dictionary = dungeons[d_id]
			# Check topic mapping
			if d.get("topic_id", "") != TOPIC_MAPPING[d_id]:
				report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_DUNGEON_TOPIC_MISMATCH", "dungeons", d_id, "", "Dungeon topic_id must be " + TOPIC_MAPPING[d_id]))

	# 2. Exactly 20 Stages total (5 per Dungeon)
	var expected_stages: Array[String] = []
	for i in range(1, 5):
		for j in range(1, 6):
			expected_stages.append("stage_0%d_0%d" % [i, j])

	if stages.size() != 20:
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_COMPLETENESS_STAGES", "stages", "", "", "V1 requires exactly 20 canonical Stages"))

	for s_id in expected_stages:
		if not stages.has(s_id):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_MISSING_CANONICAL_STAGE", "stages", s_id, "", "Missing canonical Stage: " + s_id))
		else:
			var st: Dictionary = stages[s_id]
			# Topic boundary check on QuestionScope
			var q_scope: Dictionary = st.get("learning_scope", {})
			var expected_dungeon: String = "dungeon_" + s_id.substr(6, 2)
			if st.get("dungeon_id", "") != expected_dungeon:
				report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_STAGE_DUNGEON_MISMATCH", "stages", s_id, "", "Stage dungeon_id mismatch"))

			# Boss mapping check
			if BOSS_MAPPING.has(s_id):
				var expected_boss: String = BOSS_MAPPING[s_id]
				if st.get("enemy_id", "") != expected_boss:
					report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_BOSS_MAPPING_MISMATCH", "stages", s_id, "", "Boss stage " + s_id + " must assign enemy " + expected_boss))

			# Fragment mapping check in rewards
			var reward_id: String = st.get("reward_id", "")
			if rewards.has(reward_id):
				var r: Dictionary = rewards[reward_id]
				var frag: Variant = r.get("fragment_id")
				if FRAGMENT_MAPPING.has(s_id):
					var expected_frag: String = FRAGMENT_MAPPING[s_id]
					if String(frag) != expected_frag:
						report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_FRAGMENT_MAPPING_MISMATCH", "stages", s_id, "", "Stage " + s_id + " reward fragment_id must be " + expected_frag))
				else:
					if frag != null and String(frag) != "":
						report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.BLOCK_STAGE, "ERR_NON_BOSS_FRAGMENT", "stages", s_id, "", "Non-x.5 stage reward must not grant a fragment"))

# --- QUESTION POOL VALIDATION ---
func _validate_question_pools(stages: Dictionary, questions: Dictionary, min_pool: int, report: ContentValidationReport) -> void:
	for st_id in stages:
		var st: Dictionary = stages[st_id]
		var scope: Dictionary = st.get("learning_scope", {})
		var count: int = 0
		var req_dungeon: String = scope.get("dungeon_id", st.get("dungeon_id", ""))
		var req_topic: String = scope.get("topic_id", "")

		for q_id in questions:
			var q: Dictionary = questions[q_id]
			if q.get("dungeon_id", "") == req_dungeon and q.get("topic_id", "") == req_topic:
				count += 1

		if count < min_pool:
			report.add_issue(ContentValidationIssue.new(
				ContentValidationIssue.Severity.BLOCK_STAGE,
				"ERR_QUESTION_POOL_INSUFFICIENT", "stages", st_id, "",
				"Question pool for stage " + st_id + " has only " + str(count) + " candidates (minimum required: " + str(min_pool) + ")"
			))

# --- PROCEDURAL QUESTION GENERATION VALIDATION ---
func _validate_math_knowledge_pack(item: Dictionary, fpath: String, report: ContentValidationReport) -> bool:
	var id: String = String(item.get("pack_id", ""))
	var valid: bool = true
	var required_fields: Array[String] = [
		"schema_version", "pack_id", "dungeon_id", "topic_id", "subtopic_id",
		"domain_variables", "math_rules", "forbidden_concepts", "prerequisite_concepts"
	]
	for f in required_fields:
		if not item.has(f):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_MISSING_FIELD", "math_knowledge", id, fpath, "Missing required field '" + f + "'"))
			valid = false
	if item.has("schema_version") and int(item["schema_version"]) != 1:
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_VERSION", "math_knowledge", id, fpath, "schema_version must be 1"))
		valid = false
	if item.has("dungeon_id"):
		var dun: String = String(item["dungeon_id"])
		if not CANONICAL_DUNGEONS.has(dun):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_ENUM", "math_knowledge", id, fpath, "Invalid dungeon_id: " + dun))
			valid = false
		elif item.has("topic_id"):
			var top: String = String(item["topic_id"])
			if TOPIC_MAPPING.get(dun, "") != top:
				report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SEMANTIC_TOPIC_MISMATCH", "math_knowledge", id, fpath, "topic_id " + top + " does not match dungeon " + dun))
				valid = false
	return valid

func _validate_question_generation_spec(item: Dictionary, fpath: String, report: ContentValidationReport) -> bool:
	var id: String = String(item.get("spec_id", ""))
	var valid: bool = true
	var required_fields: Array[String] = [
		"schema_version", "spec_id", "generator_family_id", "pack_id", "dungeon_id",
		"topic_id", "subtopic_id", "difficulty_range", "interaction_type", "template", "parameter_bindings"
	]
	for f in required_fields:
		if not item.has(f):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_MISSING_FIELD", "question_generation", id, fpath, "Missing required field '" + f + "'"))
			valid = false
	if item.has("schema_version") and int(item["schema_version"]) != 1:
		report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_VERSION", "question_generation", id, fpath, "schema_version must be 1"))
		valid = false
	if item.has("interaction_type"):
		var itype: String = String(item["interaction_type"])
		if not ["multiple_choice", "input", "matching", "drag_drop"].has(itype):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_ENUM", "question_generation", id, fpath, "Invalid interaction_type: " + itype))
			valid = false
	if item.has("dungeon_id"):
		var dun: String = String(item["dungeon_id"])
		if not CANONICAL_DUNGEONS.has(dun):
			report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SCHEMA_ENUM", "question_generation", id, fpath, "Invalid dungeon_id: " + dun))
			valid = false
		elif item.has("topic_id"):
			var top: String = String(item["topic_id"])
			if TOPIC_MAPPING.get(dun, "") != top:
				report.add_issue(ContentValidationIssue.new(ContentValidationIssue.Severity.FATAL, "ERR_SEMANTIC_TOPIC_MISMATCH", "question_generation", id, fpath, "topic_id " + top + " does not match dungeon " + dun))
				valid = false
	return valid

func _validate_qgen_references(math_knowledge: Dictionary, question_generation: Dictionary, report: ContentValidationReport) -> void:
	for spec_id in question_generation:
		var spec: Dictionary = question_generation[spec_id]
		var pack_id: String = String(spec.get("pack_id", ""))
		if pack_id != "" and not math_knowledge.has(pack_id):
			report.add_issue(ContentValidationIssue.new(
				ContentValidationIssue.Severity.FATAL,
				"ERR_REF_MISSING_PACK", "question_generation", spec_id, "",
				"QuestionGenerationSpec " + spec_id + " references missing MathKnowledgePack " + pack_id
			))
		elif math_knowledge.has(pack_id):
			var pack: Dictionary = math_knowledge[pack_id]
			if spec.get("dungeon_id") != pack.get("dungeon_id") or spec.get("topic_id") != pack.get("topic_id") or spec.get("subtopic_id") != pack.get("subtopic_id"):
				report.add_issue(ContentValidationIssue.new(
					ContentValidationIssue.Severity.FATAL,
					"ERR_SEMANTIC_SCOPE_MISMATCH", "question_generation", spec_id, "",
					"QuestionGenerationSpec " + spec_id + " target scope does not match referenced MathKnowledgePack " + pack_id
				))
