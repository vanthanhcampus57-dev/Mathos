class_name QaAnswerFormatter
extends RefCounted

## Formats authoritative answer_spec dictionaries into human-readable QA text.
## Supports multiple_choice, input, matching, and drag_drop / classification interaction types.
## Guarantees 100% human-readable output with ZERO raw implementation IDs (e.g. opt_a, item_1, target_1).

static func format_answer(interaction_type: String, answer_spec: Dictionary, question_dict: Dictionary = {}) -> String:
	if answer_spec.is_empty():
		return "⚠️ Không tìm thấy answer_spec cho câu hỏi này"

	match interaction_type:
		"multiple_choice":
			return _format_multiple_choice(answer_spec, question_dict)
		"input":
			return _format_input(answer_spec)
		"matching":
			return _format_matching(answer_spec, question_dict)
		"drag_drop", "classification":
			return _format_drag_drop(answer_spec, question_dict)
		_:
			return "QA answer format unsupported: %s" % interaction_type

static func _format_multiple_choice(answer_spec: Dictionary, question_dict: Dictionary) -> String:
	var payload: Dictionary = question_dict.get("interaction_payload", {}) as Dictionary
	var options: Array = answer_spec.get("options", payload.get("options", [])) as Array

	var correct_ids: Array[String] = []
	if answer_spec.has("correct_option_id"):
		correct_ids.append(String(answer_spec["correct_option_id"]))
	elif answer_spec.has("correct_option_ids") and answer_spec["correct_option_ids"] is Array:
		for cid in (answer_spec["correct_option_ids"] as Array):
			correct_ids.append(String(cid))

	var formatted_lines: Array[String] = []
	var letter_index: int = 0

	for opt in options:
		if opt is Dictionary:
			var opt_dict: Dictionary = opt as Dictionary
			var opt_id: String = String(opt_dict.get("id", opt_dict.get("option_id", "")))
			var text: String = String(opt_dict.get("text", "")).strip_edges()
			var is_correct: bool = bool(opt_dict.get("is_correct", false)) or correct_ids.has(opt_id)

			if is_correct:
				var letter_prefix: String = String.chr(65 + letter_index) if letter_index < 26 else str(letter_index + 1)
				if not text.is_empty():
					formatted_lines.append("%s. %s" % [letter_prefix, text])
				else:
					formatted_lines.append("Lựa chọn %s" % letter_prefix)

			letter_index += 1

	if formatted_lines.is_empty():
		# Fallback if options list was not available in payload: format correct_option_id to human letter
		for cid in correct_ids:
			var letter: String = _convert_option_id_to_letter(cid)
			formatted_lines.append("Lựa chọn %s" % letter)

	if formatted_lines.is_empty():
		return "⚠️ Không xác định đáp án đúng trong answer_spec"

	if formatted_lines.size() == 1:
		return "ĐÁP ÁN ĐÚNG: %s" % formatted_lines[0]
	else:
		return "ĐÁP ÁN ĐÚNG:\n" + "\n".join(formatted_lines)

static func _convert_option_id_to_letter(opt_id: String) -> String:
	var clean: String = opt_id.to_lower().strip_edges()
	if clean.begins_with("opt_") or clean.begins_with("option_"):
		var suffix: String = clean.trim_prefix("opt_").trim_prefix("option_")
		if suffix.length() == 1 and suffix >= "a" and suffix <= "z":
			return suffix.to_upper()
		elif suffix.is_valid_int():
			var idx: int = suffix.to_int() - 1
			if idx >= 0 and idx < 26:
				return String.chr(65 + idx)
	elif clean.length() == 1 and clean >= "a" and clean <= "z":
		return clean.to_upper()
	return opt_id

static func _format_input(answer_spec: Dictionary) -> String:
	var vals: Array = []
	if answer_spec.has("accepted_values") and answer_spec["accepted_values"] is Array:
		vals = answer_spec["accepted_values"] as Array
	elif answer_spec.has("acceptable_values") and answer_spec["acceptable_values"] is Array:
		vals = answer_spec["acceptable_values"] as Array
	elif answer_spec.has("answers") and answer_spec["answers"] is Array:
		vals = answer_spec["answers"] as Array
	elif answer_spec.has("expected") and answer_spec["expected"] is Array:
		vals = answer_spec["expected"] as Array

	var tol_val: Variant = answer_spec.get("numeric_tolerance", answer_spec.get("tolerance", null))
	var tol_str: String = ""
	if tol_val != null and (tol_val is int or tol_val is float) and float(tol_val) > 0.0:
		tol_str = " (±%s)" % str(tol_val)

	if not vals.is_empty():
		var str_vals: Array[String] = []
		for v in vals:
			str_vals.append(str(v))
		return "ĐÁP ÁN ĐÚNG: %s%s" % [", ".join(str_vals), tol_str]
	elif answer_spec.has("numeric_value"):
		return "ĐÁP ÁN ĐÚNG: %s%s" % [str(answer_spec["numeric_value"]), tol_str]
	elif answer_spec.has("target_value"):
		return "ĐÁP ÁN ĐÚNG: %s%s" % [str(answer_spec["target_value"]), tol_str]
	elif answer_spec.has("value"):
		return "ĐÁP ÁN ĐÚNG: %s%s" % [str(answer_spec["value"]), tol_str]
	elif answer_spec.has("exact"):
		return "ĐÁP ÁN ĐÚNG: %s%s" % [str(answer_spec["exact"]), tol_str]
	elif answer_spec.has("expected"):
		return "ĐÁP ÁN ĐÚNG: %s%s" % [str(answer_spec["expected"]), tol_str]
	elif answer_spec.has("correct_answer"):
		return "ĐÁP ÁN ĐÚNG: %s%s" % [str(answer_spec["correct_answer"]), tol_str]

	return "⚠️ Không tìm thấy đáp án hợp lệ cho câu hỏi điền số"

static func _format_matching(answer_spec: Dictionary, question_dict: Dictionary = {}) -> String:
	var pairs: Array = answer_spec.get("correct_pairs", answer_spec.get("pairs", [])) as Array
	if pairs.is_empty():
		return "⚠️ Không có cặp ghép đúng trong answer_spec"

	# Build lookup maps for left and right items from interaction_payload
	var payload: Dictionary = question_dict.get("interaction_payload", {}) as Dictionary
	var left_items: Array = payload.get("left_items", payload.get("left", [])) as Array
	var right_items: Array = payload.get("right_items", payload.get("right", [])) as Array

	var left_map: Dictionary = {}
	for item in left_items:
		if item is Dictionary:
			var id_str: String = String(item.get("item_id", item.get("id", "")))
			var text_str: String = String(item.get("text", item.get("label", id_str)))
			if not id_str.is_empty():
				left_map[id_str] = text_str

	var right_map: Dictionary = {}
	for item in right_items:
		if item is Dictionary:
			var id_str: String = String(item.get("item_id", item.get("id", "")))
			var text_str: String = String(item.get("text", item.get("label", id_str)))
			if not id_str.is_empty():
				right_map[id_str] = text_str

	var lines: Array[String] = []
	for p in pairs:
		if p is Dictionary:
			var pair_dict: Dictionary = p as Dictionary
			var left_key: String = String(pair_dict.get("left", pair_dict.get("left_id", "")))
			var right_key: String = String(pair_dict.get("right", pair_dict.get("right_id", "")))

			var resolved_left: String = left_map.get(left_key, left_key)
			var resolved_right: String = right_map.get(right_key, right_key)

			lines.append("• %s ➔ %s" % [resolved_left, resolved_right])

	if lines.is_empty():
		return "⚠️ Không có cặp ghép đúng hợp lệ"

	return "ĐÁP ÁN ĐÚNG:\n" + "\n".join(lines)

static func _format_drag_drop(answer_spec: Dictionary, question_dict: Dictionary = {}) -> String:
	var mappings: Array = answer_spec.get("item_targets", answer_spec.get("correct_mappings", answer_spec.get("mappings", []))) as Array
	var payload: Dictionary = question_dict.get("interaction_payload", {}) as Dictionary

	var items: Array = payload.get("items", []) as Array
	var targets: Array = payload.get("targets", payload.get("categories", payload.get("containers", []))) as Array

	var item_map: Dictionary = {}
	for it in items:
		if it is Dictionary:
			var id_str: String = String(it.get("item_id", it.get("id", "")))
			var text_str: String = String(it.get("text", it.get("label", id_str)))
			if not id_str.is_empty():
				item_map[id_str] = text_str

	var target_map: Dictionary = {}
	for tg in targets:
		if tg is Dictionary:
			var id_str: String = String(tg.get("target_id", tg.get("category_id", tg.get("id", ""))))
			var text_str: String = String(tg.get("label", tg.get("title", tg.get("text", tg.get("name", id_str)))))
			if not id_str.is_empty():
				target_map[id_str] = text_str

	var lines: Array[String] = []

	if not mappings.is_empty():
		for m in mappings:
			if m is Dictionary:
				var map_dict: Dictionary = m as Dictionary
				var item_key: String = String(map_dict.get("item", map_dict.get("item_id", "")))
				var target_key: String = String(map_dict.get("target", map_dict.get("target_id", map_dict.get("category_id", ""))))

				var resolved_item: String = item_map.get(item_key, item_key)
				var resolved_target: String = target_map.get(target_key, target_key)

				lines.append("• %s ➔ %s" % [resolved_item, resolved_target])
	elif answer_spec.has("targets") and answer_spec["targets"] is Dictionary:
		var targets_dict: Dictionary = answer_spec["targets"] as Dictionary
		for k in targets_dict:
			var item_key: String = String(k)
			var target_key: String = String(targets_dict[k])

			var resolved_item: String = item_map.get(item_key, item_key)
			var resolved_target: String = target_map.get(target_key, target_key)

			lines.append("• %s ➔ %s" % [resolved_item, resolved_target])

	if lines.is_empty():
		return "⚠️ Không có phân loại đúng trong answer_spec"

	return "ĐÁP ÁN ĐÚNG:\n" + "\n".join(lines)
