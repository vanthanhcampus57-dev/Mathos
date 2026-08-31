class_name QaAnswerFormatter
extends RefCounted

## Formats authoritative answer_spec dictionaries into human-readable QA text.
## Supports multiple_choice, input, matching, and drag_drop / classification interaction types.

static func format_answer(interaction_type: String, answer_spec: Dictionary, question_dict: Dictionary = {}) -> String:
	if answer_spec.is_empty():
		return "⚠️ Không tìm thấy answer_spec cho câu hỏi này"

	match interaction_type:
		"multiple_choice":
			return _format_multiple_choice(answer_spec, question_dict)
		"input":
			return _format_input(answer_spec)
		"matching":
			return _format_matching(answer_spec)
		"drag_drop", "classification":
			return _format_drag_drop(answer_spec)
		_:
			return "QA answer format unsupported: %s" % interaction_type

static func _format_multiple_choice(answer_spec: Dictionary, question_dict: Dictionary) -> String:
	var options: Array = answer_spec.get("options", [])
	if options.is_empty() and question_dict.has("interaction_payload"):
		var payload: Dictionary = question_dict.get("interaction_payload", {}) as Dictionary
		options = payload.get("options", [])

	var correct_items: Array[String] = []
	for opt in options:
		if opt is Dictionary:
			var opt_dict: Dictionary = opt as Dictionary
			if bool(opt_dict.get("is_correct", false)):
				var opt_id: String = String(opt_dict.get("id", opt_dict.get("option_id", "")))
				var text: String = String(opt_dict.get("text", ""))
				if text.is_empty():
					correct_items.append("[%s]" % opt_id)
				else:
					correct_items.append("[%s] %s" % [opt_id, text])

	if correct_items.is_empty():
		var correct_id: String = String(answer_spec.get("correct_option_id", ""))
		if not correct_id.is_empty():
			return "ĐÁP ÁN ĐÚNG: [%s]" % correct_id
		return "⚠️ Không xác định đáp án đúng trong answer_spec"

	return "ĐÁP ÁN ĐÚNG:\n" + "\n".join(correct_items)

static func _format_input(answer_spec: Dictionary) -> String:
	if answer_spec.has("acceptable_values") and answer_spec["acceptable_values"] is Array:
		var vals: Array = answer_spec["acceptable_values"] as Array
		var str_vals: Array[String] = []
		for v in vals:
			str_vals.append(String(v))
		return "ĐÁP ÁN ĐÚNG (Chấp nhận):\n" + ", ".join(str_vals)
	elif answer_spec.has("target_value"):
		var target: Variant = answer_spec["target_value"]
		var tol: Variant = answer_spec.get("tolerance", null)
		if tol != null:
			return "ĐÁP ÁN ĐÚNG: %s (Sai số ±%s)" % [String(target), String(tol)]
		return "ĐÁP ÁN ĐÚNG: %s" % String(target)
	elif answer_spec.has("value"):
		return "ĐÁP ÁN ĐÚNG: %s" % String(answer_spec["value"])
	elif answer_spec.has("correct_answer"):
		return "ĐÁP ÁN ĐÚNG: %s" % String(answer_spec["correct_answer"])

	return "QA answer format unsupported input spec: %s" % String(answer_spec)

static func _format_matching(answer_spec: Dictionary) -> String:
	var pairs: Array = answer_spec.get("correct_pairs", answer_spec.get("pairs", [])) as Array
	if pairs.is_empty():
		return "⚠️ Không có cặp ghép đúng trong answer_spec"

	var lines: Array[String] = []
	for p in pairs:
		if p is Dictionary:
			var pair_dict: Dictionary = p as Dictionary
			var left: String = String(pair_dict.get("left", pair_dict.get("left_id", "")))
			var right: String = String(pair_dict.get("right", pair_dict.get("right_id", "")))
			lines.append("• %s ➔ %s" % [left, right])

	return "CÁC CẶP GHÉP ĐÚNG:\n" + "\n".join(lines)

static func _format_drag_drop(answer_spec: Dictionary) -> String:
	var mappings: Array = answer_spec.get("item_targets", answer_spec.get("correct_mappings", answer_spec.get("mappings", []))) as Array
	if not mappings.is_empty():
		var lines: Array[String] = []
		for m in mappings:
			if m is Dictionary:
				var map_dict: Dictionary = m as Dictionary
				var item: String = String(map_dict.get("item", map_dict.get("item_id", "")))
				var target: String = String(map_dict.get("target", map_dict.get("target_id", "")))
				lines.append("• %s ➔ %s" % [item, target])
		return "PHÂN LOẠI / KÉO THẢ ĐÚNG:\n" + "\n".join(lines)
	elif answer_spec.has("targets") and answer_spec["targets"] is Dictionary:
		var targets_dict: Dictionary = answer_spec["targets"] as Dictionary
		var lines: Array[String] = []
		for k in targets_dict:
			lines.append("• %s ➔ %s" % [String(k), String(targets_dict[k])])
		return "PHÂN LOẠI / KÉO THẢ ĐÚNG:\n" + "\n".join(lines)

	return "⚠️ Không có phân loại đúng trong answer_spec"
