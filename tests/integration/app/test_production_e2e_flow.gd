class_name TestProductionE2EFlow
extends RefCounted

## Unit & integration proof for Production Content Pipeline E2E execution on res://content.

static func run_all_tests() -> bool:
	print("[PROD-E2E-001] Testing production AppRoot bootstrap and QuestionService execution on res://content...")
	var packed: PackedScene = load("res://src/app/app_root.tscn") as PackedScene
	if packed == null:
		print("[PROD-E2E-001] FAIL: Unable to load res://src/app/app_root.tscn")
		return false

	var app: AppRoot = packed.instantiate() as AppRoot
	var ok_boot: bool = app.bootstrap_runtime("res://content")
	if not ok_boot:
		print("[PROD-E2E-001] FAIL: bootstrap_runtime('res://content') returned false")
		app.free()
		return false

	var catalog: ValidatedCatalog = app.get_catalog()
	if catalog == null:
		print("[PROD-E2E-001] FAIL: ValidatedCatalog null")
		app.free()
		return false

	var d_topics: Dictionary = {
		"dungeon_01": "trial_sample_event",
		"dungeon_02": "classical_probability",
		"dungeon_03": "addition_rule",
		"dungeon_04": "multiplication_independence"
	}
	var q_all: Array[Dictionary] = []
	for d_id in d_topics:
		var t_id: String = String(d_topics[d_id])
		var d_qs: Array[Dictionary] = catalog.query_questions({
			"dungeon_id": d_id,
			"topic_id": t_id,
			"subtopic_ids": [],
			"difficulty_min": 1,
			"difficulty_max": 5
		}, "")
		for q in d_qs:
			q_all.append(q)

	print("[PROD-E2E-001] ValidatedCatalog total indexed questions: ", q_all.size())
	if q_all.size() != 100:
		print("[PROD-E2E-001] FAIL: ValidatedCatalog indexed %d questions, expected 100" % q_all.size())
		app.free()
		return false

	var start_res: Dictionary = app.start_new_game()
	if not bool(start_res.get("success", false)):
		print("[PROD-E2E-001] FAIL: start_new_game failed: ", start_res)
		app.free()
		return false

	var q_service: QuestionService = app.get_question_service()
	if q_service == null:
		print("[PROD-E2E-001] FAIL: QuestionService null")
		app.free()
		return false

	var test_types: Array[String] = ["multiple_choice", "input", "matching", "drag_drop"]
	var type_passed: Dictionary = {}

	for itype in test_types:
		var target_q: Dictionary = {}
		for q_def in q_all:
			if String(q_def.get("interaction_type", "")) == itype:
				target_q = q_def as Dictionary
				break

		if target_q.is_empty():
			print("[PROD-E2E-001] FAIL: No question of type '%s' found in production catalog" % itype)
			app.free()
			return false

		var q_id: String = String(target_q["question_id"])
		var stage_id: String = String((target_q.get("tags", ["stage_01_01"]) as Array)[1] if (target_q.get("tags", []) as Array).size() > 1 else "stage_01_01")
		var topic_id: String = String(target_q.get("topic_id", "trial_sample_event"))
		var subtopic_id: String = String(target_q.get("subtopic_id", ""))

		var request_dict: Dictionary = {
			"request_id": "req_prod_" + itype,
			"stage_id": stage_id,
			"scope": {
				"dungeon_id": String(target_q.get("dungeon_id", "dungeon_01")),
				"topic_id": topic_id,
				"subtopic_ids": [subtopic_id] if subtopic_id != "" else [],
				"difficulty_min": 1,
				"difficulty_max": 5,
				"interaction_types": [itype]
			},
			"context": "practice",
			"preferred_difficulty": null,
			"exclude_question_ids": []
		}

		var req_res: Dictionary = q_service.request_question(request_dict)
		if not bool(req_res.get("success", false)):
			print("[PROD-E2E-001] FAIL: QuestionService request_question for %s failed: %s" % [itype, req_res])
			app.free()
			return false

		var session_dict: Dictionary = req_res["session"] as Dictionary
		var active_q: Dictionary = catalog.get_question(String(session_dict["question_id"]))
		var active_itype: String = String(active_q["interaction_type"])

		if active_itype != itype:
			print("[PROD-E2E-001] FAIL: Expected interaction_type '%s', got '%s'" % [itype, active_itype])
			app.free()
			return false

		var answer_spec: Dictionary = active_q.get("answer_spec", {})
		var user_payload: Dictionary = {}

		match active_itype:
			"multiple_choice":
				var correct_opt: String = String(answer_spec.get("correct_option_id", "opt_a"))
				user_payload = {"selected_option_id": correct_opt}
			"input":
				var acc_vals: Array = answer_spec.get("accepted_values", [0])
				var raw_val: Variant = acc_vals[0] if not acc_vals.is_empty() else 0
				var inp_type: String = String((active_q.get("interaction_payload", {}) as Dictionary).get("input_type", "integer"))
				if inp_type == "integer":
					user_payload = {"value": int(raw_val)}
				elif inp_type == "float":
					user_payload = {"value": float(raw_val)}
				else:
					user_payload = {"value": String(raw_val)}
			"matching":
				var pairs: Array = answer_spec.get("pairs", [])
				user_payload = {"pairs": pairs}
			"drag_drop":
				var mappings: Array = answer_spec.get("mappings", [])
				user_payload = {"placements": mappings}

		var answer_payload: Dictionary = {
			"session_id": String(session_dict["session_id"]),
			"interaction_type": active_itype,
			"payload": user_payload
		}

		var submit_res: Dictionary = q_service.submit_answer(answer_payload)
		if not bool(submit_res.get("success", false)):
			print("[PROD-E2E-001] FAIL: submit_answer failed for %s: %s" % [itype, submit_res])
			app.free()
			return false

		var attempt: Dictionary = submit_res.get("attempt_result", {})
		var is_correct: bool = bool(attempt.get("is_correct", false))
		print("[PROD-E2E-001] Tested %s (%s): is_correct = %s" % [itype, active_q.get("question_id", ""), is_correct])
		type_passed[itype] = is_correct

	app.free()
	print("[PROD-E2E-001] PASS: All 4 production interaction types successfully executed E2E on res://content!")
	return true
