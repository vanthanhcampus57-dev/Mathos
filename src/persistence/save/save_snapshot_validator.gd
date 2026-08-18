class_name SaveSnapshotValidator
extends RefCounted

## Structural and semantic validation engine for SaveSnapshot V1.
## Validates data integrity, sequential progression, fragment locks, adaptive profile bounds,
## and transient field exclusion without mutating gameplay state.

static func validate_snapshot(snapshot: Dictionary, catalog: ValidatedCatalog = null, custom_config: Dictionary = {}) -> Dictionary:
	if snapshot.is_empty():
		return _error(SaveErrorCodes.CORRUPT_SAVE, "Snapshot cannot be empty")

	# Check schema version gate first
	if snapshot.has("schema_version"):
		var ver_variant: Variant = snapshot["schema_version"]
		if (typeof(ver_variant) == TYPE_INT or typeof(ver_variant) == TYPE_FLOAT) and not (ver_variant is bool):
			var version_float: float = float(ver_variant)
			var version_int: int = int(ver_variant)
			if version_float != float(version_int):
				return _error(SaveErrorCodes.CORRUPT_SAVE, "schema_version must be a whole integer")
			var ver_check: Dictionary = SaveVersioning.check_version(version_int)
			if not bool(ver_check.get("success", false)):
				return ver_check
		else:
			return _error(SaveErrorCodes.CORRUPT_SAVE, "schema_version must be an integer")
	else:
		return _error(SaveErrorCodes.CORRUPT_SAVE, "Missing schema_version")

	# Top-level exact field check
	if not _has_exact_fields(snapshot, SaveSchema.TOP_LEVEL_FIELDS):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "SaveSnapshot top-level fields do not match schema v1 contract")

	# Top-level field types & canonical constraints
	if not (snapshot["game_version"] is String) or String(snapshot["game_version"]).is_empty():
		return _error(SaveErrorCodes.CORRUPT_SAVE, "game_version must be a non-empty String")
	if not (snapshot["content_version"] is int or snapshot["content_version"] is float) or int(snapshot["content_version"]) != SaveSchema.CONTENT_VERSION_V1:
		return _error(SaveErrorCodes.CORRUPT_SAVE, "content_version must equal %d" % SaveSchema.CONTENT_VERSION_V1)
	if not (snapshot["saved_at_utc"] is String) or String(snapshot["saved_at_utc"]).is_empty():
		return _error(SaveErrorCodes.CORRUPT_SAVE, "saved_at_utc must be a non-empty ISO-8601 String")
	if String(snapshot["profile_id"]) != SaveSchema.PROFILE_ID_CANONICAL:
		return _error(SaveErrorCodes.CORRUPT_SAVE, "profile_id must be '%s'" % SaveSchema.PROFILE_ID_CANONICAL)

	# Validate PlayerPersistent
	var player_res: Dictionary = _validate_player_persistent(snapshot["player_persistent"])
	if not bool(player_res.get("success", false)):
		return player_res

	# Validate Progress
	var progress_res: Dictionary = _validate_progress(snapshot["progress"], catalog)
	if not bool(progress_res.get("success", false)):
		return progress_res

	# Validate Adaptive Profile
	var adaptive_res: Dictionary = _validate_adaptive_profile(snapshot["adaptive_profile"], catalog, custom_config)
	if not bool(adaptive_res.get("success", false)):
		return adaptive_res

	return {"success": true}

static func _validate_player_persistent(player: Variant) -> Dictionary:
	if not (player is Dictionary):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "player_persistent must be a Dictionary")
	var p_dict: Dictionary = player as Dictionary
	if not _has_exact_fields(p_dict, SaveSchema.PLAYER_PERSISTENT_FIELDS):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "player_persistent fields do not match schema v1 contract")

	if String(p_dict["player_id"]) != SaveSchema.PLAYER_ID_CANONICAL:
		return _error(SaveErrorCodes.CORRUPT_SAVE, "player_id must be '%s'" % SaveSchema.PLAYER_ID_CANONICAL)

	if not (p_dict["coin_balance"] is int or p_dict["coin_balance"] is float) or float(p_dict["coin_balance"]) < 0.0:
		return _error(SaveErrorCodes.CORRUPT_SAVE, "coin_balance must be a non-negative number")

	if not (p_dict["exp_total"] is int or p_dict["exp_total"] is float) or float(p_dict["exp_total"]) < 0.0:
		return _error(SaveErrorCodes.CORRUPT_SAVE, "exp_total must be a non-negative number")

	return {"success": true}

static func _validate_progress(progress: Variant, catalog: ValidatedCatalog) -> Dictionary:
	if not (progress is Dictionary):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "progress must be a Dictionary")
	var prg: Dictionary = progress as Dictionary
	if not _has_exact_fields(prg, SaveSchema.PROGRESS_FIELDS):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "progress fields do not match schema v1 contract")

	if typeof(prg["game_complete"]) != TYPE_BOOL:
		return _error(SaveErrorCodes.CORRUPT_SAVE, "game_complete must be a boolean")

	# Validate arrays for uniqueness and string types
	var dungeons_res: Dictionary = _extract_unique_string_array(prg["unlocked_dungeon_ids"], "unlocked_dungeon_ids")
	if not bool(dungeons_res.get("success", false)):
		return dungeons_res
	var unlocked_dungeons: Array[String] = dungeons_res["items"] as Array[String]

	var unlocked_stages_res: Dictionary = _extract_unique_string_array(prg["unlocked_stage_ids"], "unlocked_stage_ids")
	if not bool(unlocked_stages_res.get("success", false)):
		return unlocked_stages_res
	var unlocked_stages: Array[String] = unlocked_stages_res["items"] as Array[String]

	var cleared_stages_res: Dictionary = _extract_unique_string_array(prg["cleared_stage_ids"], "cleared_stage_ids")
	if not bool(cleared_stages_res.get("success", false)):
		return cleared_stages_res
	var cleared_stages: Array[String] = cleared_stages_res["items"] as Array[String]

	var fragments_res: Dictionary = _extract_unique_string_array(prg["fragment_ids"], "fragment_ids")
	if not bool(fragments_res.get("success", false)):
		return fragments_res
	var fragment_ids: Array[String] = fragments_res["items"] as Array[String]

	# Validate IDs against canonical sets
	for d in unlocked_dungeons:
		if not SaveSchema.CANONICAL_DUNGEONS.has(d):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "Unknown dungeon_id in unlocked_dungeon_ids: " + d)

	for f in fragment_ids:
		if not SaveSchema.CANONICAL_FRAGMENTS.has(f):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "Unknown fragment_id in fragment_ids: " + f)

	for s in unlocked_stages:
		if not _is_canonical_stage_id(s):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "Unknown stage_id in unlocked_stage_ids: " + s)

	for s in cleared_stages:
		if not _is_canonical_stage_id(s):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "Unknown stage_id in cleared_stage_ids: " + s)
		if not unlocked_stages.has(s):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "Cleared stage '%s' is not in unlocked_stage_ids" % s)

	# If catalog is provided, verify stages/dungeons against catalog
	if catalog != null:
		for d in unlocked_dungeons:
			if catalog.get_dungeon(d).is_empty():
				return _error(SaveErrorCodes.CORRUPT_SAVE, "Dungeon '%s' not found in catalog" % d)
		for s in unlocked_stages:
			if catalog.get_stage(s).is_empty():
				return _error(SaveErrorCodes.CORRUPT_SAVE, "Stage '%s' not found in catalog" % s)

	# Mandatory baseline unlocked checks
	if not unlocked_dungeons.has("dungeon_01"):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "dungeon_01 must always be unlocked")
	if not unlocked_stages.has("stage_01_01"):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "stage_01_01 must always be unlocked")

	# Sequential progression checks within each dungeon
	for d_idx in range(1, 5):
		var d_id: String = "dungeon_0%d" % d_idx
		var d_unlocked: bool = unlocked_dungeons.has(d_id)

		for s_idx in range(1, 6):
			var s_id: String = "stage_0%d_0%d" % [d_idx, s_idx]
			var s_unlocked: bool = unlocked_stages.has(s_id)
			var s_cleared: bool = cleared_stages.has(s_id)

			if s_unlocked and not d_unlocked:
				return _error(SaveErrorCodes.CORRUPT_SAVE, "Stage '%s' is unlocked but Dungeon '%s' is not unlocked" % [s_id, d_id])

			if s_idx > 1:
				var prev_s_id: String = "stage_0%d_0%d" % [d_idx, s_idx - 1]
				var prev_cleared: bool = cleared_stages.has(prev_s_id)
				if s_unlocked and not prev_cleared:
					return _error(SaveErrorCodes.CORRUPT_SAVE, "Stage '%s' is unlocked but previous stage '%s' is not cleared" % [s_id, prev_s_id])

			if s_cleared and not s_unlocked:
				return _error(SaveErrorCodes.CORRUPT_SAVE, "Stage '%s' is cleared but not unlocked" % s_id)

	# Fragment & Dungeon unlock dependency checks
	if fragment_ids.has("fragment_01") and not cleared_stages.has("stage_01_05"):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "fragment_01 requires stage_01_05 to be cleared")
	if fragment_ids.has("fragment_02") and not cleared_stages.has("stage_02_05"):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "fragment_02 requires stage_02_05 to be cleared")
	if fragment_ids.has("fragment_03") and not cleared_stages.has("stage_03_05"):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "fragment_03 requires stage_03_05 to be cleared")
	if fragment_ids.has("fragment_04") and not cleared_stages.has("stage_04_05"):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "fragment_04 requires stage_04_05 to be cleared")

	if unlocked_dungeons.has("dungeon_02"):
		if not cleared_stages.has("stage_01_05") or not fragment_ids.has("fragment_01"):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "dungeon_02 requires stage_01_05 clear and fragment_01")
	if unlocked_dungeons.has("dungeon_03"):
		if not cleared_stages.has("stage_02_05") or not fragment_ids.has("fragment_02"):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "dungeon_03 requires stage_02_05 clear and fragment_02")
	if unlocked_dungeons.has("dungeon_04"):
		if not cleared_stages.has("stage_03_05") or not fragment_ids.has("fragment_03"):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "dungeon_04 requires stage_03_05 clear and fragment_03")

	# Game completion constraint
	var game_complete: bool = bool(prg["game_complete"])
	if game_complete:
		if cleared_stages.size() != 20 or fragment_ids.size() != 4:
			return _error(SaveErrorCodes.CORRUPT_SAVE, "game_complete requires all 20 canonical stages cleared and all 4 fragments")

	return {"success": true}

static func _validate_adaptive_profile(adaptive: Variant, catalog: ValidatedCatalog, custom_config: Dictionary) -> Dictionary:
	if not (adaptive is Dictionary):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "adaptive_profile must be a Dictionary")
	var adp: Dictionary = adaptive as Dictionary
	if not _has_exact_fields(adp, SaveSchema.ADAPTIVE_PROFILE_FIELDS):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "adaptive_profile fields do not match schema v1 contract")

	var attempts_total: int = int(adp["attempts_total"])
	var correct_total: int = int(adp["correct_total"])
	var consecutive_correct: int = int(adp["consecutive_correct"])
	var consecutive_incorrect: int = int(adp["consecutive_incorrect"])

	if attempts_total < 0 or correct_total < 0 or consecutive_correct < 0 or consecutive_incorrect < 0:
		return _error(SaveErrorCodes.CORRUPT_SAVE, "Adaptive counters must be non-negative integers")

	if correct_total > attempts_total:
		return _error(SaveErrorCodes.CORRUPT_SAVE, "correct_total cannot exceed attempts_total")

	# Validate topic_stats
	if not (adp["topic_stats"] is Dictionary):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "topic_stats must be a Dictionary")
	var t_stats: Dictionary = adp["topic_stats"] as Dictionary

	for topic_key in t_stats.keys():
		var topic_str: String = String(topic_key)
		if not SaveSchema.ALLOWED_TOPIC_IDS.has(topic_str):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "Invalid topic_stats key: " + topic_str)
		var stat_val: Variant = t_stats[topic_key]
		if not (stat_val is Dictionary):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "topic_stats value must be a Dictionary")
		var stat_dict: Dictionary = stat_val as Dictionary
		if not _has_exact_fields(stat_dict, SaveSchema.ADAPTIVE_TOPIC_STATS_FIELDS):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "AdaptiveTopicStats fields do not match schema v1 contract")

		var t_att: int = int(stat_dict["attempts"])
		var t_cor: int = int(stat_dict["correct"])
		if t_att < 0 or t_cor < 0 or t_cor > t_att:
			return _error(SaveErrorCodes.CORRUPT_SAVE, "Topic attempts/correct values are invalid")

		if not (stat_dict["average_time_seconds"] is int or stat_dict["average_time_seconds"] is float) or float(stat_dict["average_time_seconds"]) < 0.0:
			return _error(SaveErrorCodes.CORRUPT_SAVE, "average_time_seconds must be >= 0")

		var last_diff: Variant = stat_dict["last_difficulty"]
		if last_diff != null:
			if not (last_diff is int or last_diff is float) or int(last_diff) < 1 or int(last_diff) > 5:
				return _error(SaveErrorCodes.CORRUPT_SAVE, "last_difficulty must be null or 1..5")

	# Validate recent_records limit dynamically from catalog config or custom_config
	if not (adp["recent_records"] is Array):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "recent_records must be an Array")
	var records: Array = adp["recent_records"] as Array

	var limit: int = 100
	if catalog != null:
		var cfg: Dictionary = catalog.get_config()
		if cfg.has("adaptive_recent_record_limit"):
			limit = int(cfg["adaptive_recent_record_limit"])
	elif custom_config.has("adaptive_recent_record_limit"):
		limit = int(custom_config["adaptive_recent_record_limit"])

	if records.size() > limit:
		return _error(SaveErrorCodes.CORRUPT_SAVE, "recent_records length (%d) exceeds limit (%d)" % [records.size(), limit])

	for rec_variant in records:
		if not (rec_variant is Dictionary):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord must be a Dictionary")
		var rec: Dictionary = rec_variant as Dictionary
		if not _has_exact_fields(rec, SaveSchema.PERFORMANCE_RECORD_FIELDS):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord fields do not match schema v1 contract")

		if String(rec["attempt_id"]).is_empty():
			return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord attempt_id must be non-empty")

		var q_id: String = String(rec["question_id"])
		if q_id.is_empty():
			return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord question_id must be non-empty")

		var dung_id: String = String(rec["dungeon_id"])
		if not SaveSchema.CANONICAL_DUNGEONS.has(dung_id):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord unknown dungeon_id: " + dung_id)

		var expected_topic: String = SaveSchema.DUNGEON_TOPIC_MAP.get(dung_id, "")
		if String(rec["topic_id"]) != expected_topic:
			return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord topic_id '%s' does not match dungeon topic '%s'" % [String(rec["topic_id"]), expected_topic])

		var sub_id: String = String(rec["subtopic_id"])
		if sub_id.is_empty():
			return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord subtopic_id must be non-empty")

		# If catalog is available, validate against catalog questions reference
		if catalog != null:
			if catalog.get_dungeon(dung_id).is_empty():
				return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord dungeon_id '%s' not found in catalog" % dung_id)
			var q_def: Dictionary = catalog.get_question(q_id)
			if q_def.is_empty():
				return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord question_id '%s' not found in catalog" % q_id)

			if String(q_def.get("dungeon_id", "")) != dung_id:
				return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord dungeon_id '%s' incompatible with question definition '%s'" % [dung_id, String(q_def.get("dungeon_id", ""))])
			if String(q_def.get("topic_id", "")) != String(rec["topic_id"]):
				return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord topic_id '%s' incompatible with question definition '%s'" % [String(rec["topic_id"]), String(q_def.get("topic_id", ""))])
			if String(q_def.get("subtopic_id", "")) != sub_id:
				return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord subtopic_id '%s' incompatible with question definition '%s'" % [sub_id, String(q_def.get("subtopic_id", ""))])

		var ctx: String = String(rec["context"])
		if not SaveSchema.ALLOWED_PERFORMANCE_CONTEXTS.has(ctx):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord context '%s' is not allowed" % ctx)

		var diff: int = int(rec["difficulty"])
		if diff < 1 or diff > 5:
			return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord difficulty must be 1..5")

		if typeof(rec["is_correct"]) != TYPE_BOOL:
			return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord is_correct must be a boolean")

		if not (rec["elapsed_seconds"] is int or rec["elapsed_seconds"] is float) or float(rec["elapsed_seconds"]) < 0.0:
			return _error(SaveErrorCodes.CORRUPT_SAVE, "PerformanceRecord elapsed_seconds must be >= 0")

	return {"success": true}

static func _has_exact_fields(data: Dictionary, fields: Array[String]) -> bool:
	if data.size() != fields.size():
		return false
	for field in fields:
		if not data.has(field):
			return false
	return true

static func _extract_unique_string_array(arr_variant: Variant, name: String) -> Dictionary:
	if not (arr_variant is Array):
		return _error(SaveErrorCodes.CORRUPT_SAVE, "%s must be an Array" % name)
	var arr: Array = arr_variant as Array
	var items: Array[String] = []
	var seen: Dictionary = {}
	for item_var in arr:
		if not (item_var is String):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "%s items must be Strings" % name)
		var str_val: String = String(item_var)
		if seen.has(str_val):
			return _error(SaveErrorCodes.CORRUPT_SAVE, "%s contains duplicate item: %s" % [name, str_val])
		seen[str_val] = true
		items.append(str_val)
	return {"success": true, "items": items}

static func _is_canonical_stage_id(stage_id: String) -> bool:
	if stage_id.length() != 11 or not stage_id.begins_with("stage_"):
		return false
	var parts: PackedStringArray = stage_id.split("_")
	if parts.size() != 3:
		return false
	if not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return false
	var d_num: int = parts[1].to_int()
	var s_num: int = parts[2].to_int()
	return d_num >= 1 and d_num <= 4 and s_num >= 1 and s_num <= 5

static func _error(code: String, message: String) -> Dictionary:
	return {"success": false, "error_code": code, "error_message": message}
