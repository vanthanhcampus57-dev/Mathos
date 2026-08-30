class_name TestD3ProceduralQGen
extends RefCounted

## Unit test suite for Dungeon 3 Procedural Question Generation (addition_rule).
## Validates all 15 locked canonical spec IDs (qspec_d3_<code>_<nn>):
## - qspec_d3_ui_01..03 (union_intersection)
## - qspec_d3_me_01..03 (mutually_exclusive)
## - qspec_d3_as_01..03 (addition_simple)
## - qspec_d3_ag_01..03 (addition_general)
## - qspec_d3_asl_01..03 (addition_selection & Boss MELKOR 23/36 proof)
## Enforces anti-leakage boundary (NO D4 multiplication rules, NO C(n,k) combinatorics).

const QuestionGeneratorIdentity = preload("res://src/education/question/generator/question_generator_identity.gd")
const D3QuestionGenerator = preload("res://src/education/question/generator/d3_question_generator.gd")
const QuestionEvaluator = preload("res://src/education/question/question_evaluator.gd")

static func run_all_tests() -> bool:
	print("--- RUNNING D3 PROCEDURAL QGEN SUITE ---")
	var all_ok: bool = true

	all_ok = test_d3_qgen_001_math_utilities_contract() and all_ok
	all_ok = test_d3_qgen_002_union_intersection_subtopic() and all_ok
	all_ok = test_d3_qgen_003_mutually_exclusive_subtopic() and all_ok
	all_ok = test_d3_qgen_004_addition_simple_subtopic() and all_ok
	all_ok = test_d3_qgen_005_addition_general_subtopic() and all_ok
	all_ok = test_d3_qgen_006_addition_selection_boss_melkor_proof() and all_ok
	all_ok = test_d3_qgen_007_identity_determinism_batch_uniqueness() and all_ok
	all_ok = test_d3_qgen_008_d4_anti_leakage_and_evaluator_compatibility() and all_ok

	return all_ok

# --- 1. MATH UTILITIES CONTRACT ---
static func test_d3_qgen_001_math_utilities_contract() -> bool:
	print("[D3-QGEN-001] Testing D3 mathematical utility rules...")

	# Set union count n(A U B) = n(A) + n(B) - n(A n B)
	if D3QuestionGenerator.calc_union_count(15, 12, 5) != 22:
		print("[D3-QGEN-001] FAIL: calc_union_count(15,12,5) expected 22")
		return false

	# Simple addition rule
	if abs(D3QuestionGenerator.calc_simple_addition_prob(0.2, 0.35) - 0.55) > 0.0001:
		print("[D3-QGEN-001] FAIL: calc_simple_addition_prob(0.2, 0.35) expected 0.55")
		return false

	# General addition rule
	if abs(D3QuestionGenerator.calc_general_addition_prob(0.6, 0.5, 0.3) - 0.8) > 0.0001:
		print("[D3-QGEN-001] FAIL: calc_general_addition_prob(0.6, 0.5, 0.3) expected 0.8")
		return false

	# Mutually exclusive check
	if not D3QuestionGenerator.is_mutually_exclusive(0):
		print("[D3-QGEN-001] FAIL: is_mutually_exclusive(0) expected true")
		return false
	if D3QuestionGenerator.is_mutually_exclusive(2):
		print("[D3-QGEN-001] FAIL: is_mutually_exclusive(2) expected false")
		return false

	print("[D3-QGEN-001] PASS")
	return true

# --- 2. UNION & INTERSECTION SUBTOPIC ---
static func test_d3_qgen_002_union_intersection_subtopic() -> bool:
	print("[D3-QGEN-002] Testing subtopic 'union_intersection' (qspec_d3_ui_01, 02, 03)...")
	var gen: D3QuestionGenerator = D3QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_03", "addition_rule", "union_intersection")

	# qspec_d3_ui_01 (MC symbol)
	var spec_ui01: Dictionary = _make_mock_spec("qspec_d3_ui_01", "dungeon_03", "addition_rule", "union_intersection", "multiple_choice", {
		"prompt": "Ký hiệu nào biểu diễn biến cố 'A hoặc B xảy ra'?",
		"explanation": "Ký hiệu U biểu diễn phép hợp biến cố.",
		"learning_objective": "Nhận biết ký hiệu hợp biến cố.",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "{correct_symbol}"},
				{"option_id": "opt_b", "text": "{incorrect_symbol_1}"},
				{"option_id": "opt_c", "text": "{incorrect_symbol_2}"},
				{"option_id": "opt_d", "text": "{incorrect_symbol_3}"}
			]
		},
		"answer_spec": {"correct_option_id": "opt_a"}
	})
	var q_ui01: Dictionary = gen.generate_question(spec_ui01, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_ui01, "qspec_d3_ui_01"):
		print("[D3-QGEN-002] FAIL: Invalid qdef for qspec_d3_ui_01")
		return false

	# qspec_d3_ui_02 (Input count n(A U B))
	var spec_ui02: Dictionary = _make_mock_spec("qspec_d3_ui_02", "dungeon_03", "addition_rule", "union_intersection", "input", {
		"prompt": "Cho n(A)={n_A}, n(B)={n_B}, n(A n B)={n_inter}. Tính n(A U B).",
		"explanation": "n(A U B) = n(A) + n(B) - n(A n B) = {ans_n_union}.",
		"learning_objective": "Tính số phần tử hợp hai tập hợp.",
		"interaction_payload": {"input_type": "integer"},
		"answer_spec": {"accepted_values": ["{ans_n_union}"]}
	})
	var q_ui02: Dictionary = gen.generate_question(spec_ui02, pack, {"n_A": 15, "n_B": 12, "n_inter": 5})
	if not _is_valid_qdef(q_ui02, "qspec_d3_ui_02"):
		print("[D3-QGEN-002] FAIL: Invalid qdef for qspec_d3_ui_02")
		return false
	if int(q_ui02["answer_spec"]["accepted_values"][0]) != 22:
		print("[D3-QGEN-002] FAIL: Expected 22 for n(A U B), got: " + str(q_ui02["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d3_ui_03 (Matching symbols)
	var spec_ui03: Dictionary = _make_mock_spec("qspec_d3_ui_03", "dungeon_03", "addition_rule", "union_intersection", "matching", {
		"prompt": "Nối ký hiệu với ý nghĩa...",
		"explanation": "Giải thích ký hiệu.",
		"learning_objective": "Nối ký hiệu biến cố.",
		"interaction_payload": {
			"left_items": [
				{"item_id": "l1", "text": "{left_1}"},
				{"item_id": "l2", "text": "{left_2}"},
				{"item_id": "l3", "text": "{left_3}"}
			],
			"right_items": [
				{"item_id": "r1", "text": "{right_1}"},
				{"item_id": "r2", "text": "{right_2}"},
				{"item_id": "r3", "text": "{right_3}"}
			]
		},
		"answer_spec": {
			"pairs": [
				{"left_id": "l1", "right_id": "r1"},
				{"left_id": "l2", "right_id": "r2"},
				{"left_id": "l3", "right_id": "r3"}
			]
		}
	})
	var q_ui03: Dictionary = gen.generate_question(spec_ui03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_ui03, "qspec_d3_ui_03"):
		print("[D3-QGEN-002] FAIL: Invalid qdef for qspec_d3_ui_03")
		return false

	print("[D3-QGEN-002] PASS")
	return true

# --- 3. MUTUALLY EXCLUSIVE SUBTOPIC ---
static func test_d3_qgen_003_mutually_exclusive_subtopic() -> bool:
	print("[D3-QGEN-003] Testing subtopic 'mutually_exclusive' (qspec_d3_me_01, 02, 03)...")
	var gen: D3QuestionGenerator = D3QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_03", "addition_rule", "mutually_exclusive")

	# qspec_d3_me_01 (MC valid mutually exclusive pair)
	var spec_me01: Dictionary = _make_mock_spec("qspec_d3_me_01", "dungeon_03", "addition_rule", "mutually_exclusive", "multiple_choice", {
		"prompt": "Cặp biến cố nào sau đây là **xung khắc**?",
		"explanation": "Cặp biến cố xung khắc không thể cùng xảy ra.",
		"learning_objective": "Nhận biết biến cố xung khắc.",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "{valid_pair}"},
				{"option_id": "opt_b", "text": "{invalid_pair_1}"},
				{"option_id": "opt_c", "text": "{invalid_pair_2}"},
				{"option_id": "opt_d", "text": "{invalid_pair_3}"}
			]
		},
		"answer_spec": {"correct_option_id": "opt_a"}
	})
	var q_me01: Dictionary = gen.generate_question(spec_me01, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_me01, "qspec_d3_me_01"):
		print("[D3-QGEN-003] FAIL: Invalid qdef for qspec_d3_me_01")
		return false

	# qspec_d3_me_02 (Input P(A n B) = 0.0)
	var spec_me02: Dictionary = _make_mock_spec("qspec_d3_me_02", "dungeon_03", "addition_rule", "mutually_exclusive", "input", {
		"prompt": "Cho 2 biến cố A và B xung khắc. Tính P(A n B).",
		"explanation": "Do A và B xung khắc nên P(A n B) = 0.",
		"learning_objective": "Xác suất giao hai biến cố xung khắc bằng 0.",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_p_inter}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_me02: Dictionary = gen.generate_question(spec_me02, pack, {})
	if not _is_valid_qdef(q_me02, "qspec_d3_me_02"):
		print("[D3-QGEN-003] FAIL: Invalid qdef for qspec_d3_me_02")
		return false
	if abs(float(q_me02["answer_spec"]["accepted_values"][0]) - 0.0) > 0.001:
		print("[D3-QGEN-003] FAIL: Expected 0.0 for P(A n B) mutually exclusive")
		return false

	# qspec_d3_me_03 (DragDrop)
	var spec_me03: Dictionary = _make_mock_spec("qspec_d3_me_03", "dungeon_03", "addition_rule", "mutually_exclusive", "drag_drop", {
		"prompt": "Phân loại các cặp biến cố vào nhóm 'Xung khắc' hoặc 'Không xung khắc'.",
		"explanation": "Giải thích phân loại.",
		"learning_objective": "Phân loại cặp biến cố.",
		"interaction_payload": {
			"items": [
				{"item_id": "item_1", "text": "{item_1_text}"},
				{"item_id": "item_2", "text": "{item_2_text}"},
				{"item_id": "item_3", "text": "{item_3_text}"},
				{"item_id": "item_4", "text": "{item_4_text}"}
			],
			"targets": [
				{"target_id": "target_me", "title": "Biến cố Xung khắc"},
				{"target_id": "target_not_me", "title": "Không xung khắc"}
			]
		},
		"answer_spec": {
			"mappings": [
				{"item_id": "item_1", "target_id": "target_me"},
				{"item_id": "item_2", "target_id": "target_me"},
				{"item_id": "item_3", "target_id": "target_not_me"},
				{"item_id": "item_4", "target_id": "target_not_me"}
			]
		}
	})
	var q_me03: Dictionary = gen.generate_question(spec_me03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_me03, "qspec_d3_me_03"):
		print("[D3-QGEN-003] FAIL: Invalid qdef for qspec_d3_me_03")
		return false

	print("[D3-QGEN-003] PASS")
	return true

# --- 4. ADDITION SIMPLE SUBTOPIC ---
static func test_d3_qgen_004_addition_simple_subtopic() -> bool:
	print("[D3-QGEN-004] Testing subtopic 'addition_simple' (qspec_d3_as_01, 02, 03)...")
	var gen: D3QuestionGenerator = D3QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_03", "addition_rule", "addition_simple")

	# qspec_d3_as_01 (MC)
	var spec_as01: Dictionary = _make_mock_spec("qspec_d3_as_01", "dungeon_03", "addition_rule", "addition_simple", "multiple_choice", {
		"prompt": "Cho P(A)={p_A}, P(B)={p_B} với A, B xung khắc. Tính P(A U B).",
		"explanation": "P(A U B) = P(A) + P(B) = {ans_prob}.",
		"learning_objective": "Áp dụng quy tắc cộng xung khắc.",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "{ans_prob}"},
				{"option_id": "opt_b", "text": "0.15"},
				{"option_id": "opt_c", "text": "0.70"}
			]
		},
		"answer_spec": {"correct_option_id": "opt_a"}
	})
	var q_as01: Dictionary = gen.generate_question(spec_as01, pack, {"p_A": 0.2, "p_B": 0.35})
	if not _is_valid_qdef(q_as01, "qspec_d3_as_01"):
		print("[D3-QGEN-004] FAIL: Invalid qdef for qspec_d3_as_01")
		return false

	# qspec_d3_as_02 (Input float)
	var spec_as02: Dictionary = _make_mock_spec("qspec_d3_as_02", "dungeon_03", "addition_rule", "addition_simple", "input", {
		"prompt": "Cho P(A)={p_A}, P(B)={p_B} với A, B xung khắc. Nhập P(A U B).",
		"explanation": "P(A U B) = {ans_prob}.",
		"learning_objective": "Tính P(A U B) cho biến cố xung khắc.",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_as02: Dictionary = gen.generate_question(spec_as02, pack, {"p_A": 0.25, "p_B": 0.35})
	if not _is_valid_qdef(q_as02, "qspec_d3_as_02"):
		print("[D3-QGEN-004] FAIL: Invalid qdef for qspec_d3_as_02")
		return false
	if abs(float(q_as02["answer_spec"]["accepted_values"][0]) - 0.6) > 0.001:
		print("[D3-QGEN-004] FAIL: Expected 0.6 for simple addition, got: " + str(q_as02["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d3_as_03 (Matching)
	var spec_as03: Dictionary = _make_mock_spec("qspec_d3_as_03", "dungeon_03", "addition_rule", "addition_simple", "matching", {
		"prompt": "Nối phép tính xác suất...",
		"explanation": "Giải thích nối quy tắc cộng.",
		"learning_objective": "Nối bài toán với xác suất.",
		"interaction_payload": {
			"left_items": [
				{"item_id": "l1", "text": "{left_1}"},
				{"item_id": "l2", "text": "{left_2}"},
				{"item_id": "l3", "text": "{left_3}"}
			],
			"right_items": [
				{"item_id": "r1", "text": "{right_1}"},
				{"item_id": "r2", "text": "{right_2}"},
				{"item_id": "r3", "text": "{right_3}"}
			]
		},
		"answer_spec": {
			"pairs": [
				{"left_id": "l1", "right_id": "r1"},
				{"left_id": "l2", "right_id": "r2"},
				{"left_id": "l3", "right_id": "r3"}
			]
		}
	})
	var q_as03: Dictionary = gen.generate_question(spec_as03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_as03, "qspec_d3_as_03"):
		print("[D3-QGEN-004] FAIL: Invalid qdef for qspec_d3_as_03")
		return false

	print("[D3-QGEN-004] PASS")
	return true

# --- 5. ADDITION GENERAL SUBTOPIC ---
static func test_d3_qgen_005_addition_general_subtopic() -> bool:
	print("[D3-QGEN-005] Testing subtopic 'addition_general' (qspec_d3_ag_01, 02, 03)...")
	var gen: D3QuestionGenerator = D3QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_03", "addition_rule", "addition_general")

	# qspec_d3_ag_01 (Input float P(A U B) = P(A) + P(B) - P(A n B))
	var spec_ag01: Dictionary = _make_mock_spec("qspec_d3_ag_01", "dungeon_03", "addition_rule", "addition_general", "input", {
		"prompt": "Cho P(A)={p_A}, P(B)={p_B}, P(A n B)={p_inter}. Tính P(A U B).",
		"explanation": "P(A U B) = P(A) + P(B) - P(A n B) = {ans_prob}.",
		"learning_objective": "Tính quy tắc cộng tổng quát.",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_ag01: Dictionary = gen.generate_question(spec_ag01, pack, {"p_A": 0.6, "p_B": 0.5, "p_inter": 0.3})
	if not _is_valid_qdef(q_ag01, "qspec_d3_ag_01"):
		print("[D3-QGEN-005] FAIL: Invalid qdef for qspec_d3_ag_01")
		return false
	if abs(float(q_ag01["answer_spec"]["accepted_values"][0]) - 0.8) > 0.001:
		print("[D3-QGEN-005] FAIL: Expected 0.8 for general addition, got: " + str(q_ag01["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d3_ag_02 (MC Red or King card draw)
	var spec_ag02: Dictionary = _make_mock_spec("qspec_d3_ag_02", "dungeon_03", "addition_rule", "addition_general", "multiple_choice", {
		"prompt": "Rút 1 lá bài từ bộ 52 lá. Tính xác suất rút được lá bài màu Đỏ hoặc lá K.",
		"explanation": "P(Đỏ u K) = (26 + 4 - 2) / 52 = 28 / 52 = 7 / 13.",
		"learning_objective": "Tính xác suất rút lá bài đỏ hoặc K.",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "{correct_fraction}"},
				{"option_id": "opt_b", "text": "{incorrect_1}"},
				{"option_id": "opt_c", "text": "{incorrect_2}"},
				{"option_id": "opt_d", "text": "{incorrect_3}"}
			]
		},
		"answer_spec": {"correct_option_id": "opt_a"}
	})
	var q_ag02: Dictionary = gen.generate_question(spec_ag02, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_ag02, "qspec_d3_ag_02"):
		print("[D3-QGEN-005] FAIL: Invalid qdef for qspec_d3_ag_02")
		return false
	if q_ag02["answer_spec"]["correct_option_id"] != "opt_a":
		print("[D3-QGEN-005] FAIL: Expected opt_a for qspec_d3_ag_02")
		return false

	# qspec_d3_ag_03 (DragDrop)
	var spec_ag03: Dictionary = _make_mock_spec("qspec_d3_ag_03", "dungeon_03", "addition_rule", "addition_general", "drag_drop", {
		"prompt": "Phân loại các bài toán quy tắc cộng...",
		"explanation": "Giải thích quy tắc cộng.",
		"learning_objective": "Phân loại bài toán quy tắc cộng.",
		"interaction_payload": {
			"items": [
				{"item_id": "item_1", "text": "{item_1_text}"},
				{"item_id": "item_2", "text": "{item_2_text}"},
				{"item_id": "item_3", "text": "{item_3_text}"},
				{"item_id": "item_4", "text": "{item_4_text}"}
			],
			"targets": [
				{"target_id": "t1", "title": "Nhóm A"},
				{"target_id": "t2", "title": "Nhóm B"}
			]
		},
		"answer_spec": {
			"mappings": [
				{"item_id": "item_1", "target_id": "t1"},
				{"item_id": "item_2", "target_id": "t1"},
				{"item_id": "item_3", "target_id": "t2"},
				{"item_id": "item_4", "target_id": "t2"}
			]
		}
	})
	var q_ag03: Dictionary = gen.generate_question(spec_ag03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_ag03, "qspec_d3_ag_03"):
		print("[D3-QGEN-005] FAIL: Invalid qdef for qspec_d3_ag_03")
		return false

	print("[D3-QGEN-005] PASS")
	return true

# --- 6. ADDITION SELECTION & BOSS MELKOR PROOF ---
static func test_d3_qgen_006_addition_selection_boss_melkor_proof() -> bool:
	print("[D3-QGEN-006] Testing subtopic 'addition_selection' (qspec_d3_asl_01, 02, 03) & Boss MELKOR 23/36 proof...")
	var gen: D3QuestionGenerator = D3QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_03", "addition_rule", "addition_selection")

	# qspec_d3_asl_01 (Class survey input: 20 math, 15 eng, 5 both / 40 total -> P = 30/40 = 0.75)
	var spec_asl01: Dictionary = _make_mock_spec("qspec_d3_asl_01", "dungeon_03", "addition_rule", "addition_selection", "input", {
		"prompt": "Lớp có {N_math} Toán, {N_eng} Anh, {N_both} cả hai / {N_total}. Tính P(giỏi ít nhất 1 môn).",
		"explanation": "n(Toán U Anh) = 20 + 15 - 5 = 30 => P = 30 / 40 = 0.75.",
		"learning_objective": "Tính xác suất chọn học sinh giỏi môn học.",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_asl01: Dictionary = gen.generate_question(spec_asl01, pack, {"N_math": 20, "N_eng": 15, "N_both": 5, "N_total": 40})
	if not _is_valid_qdef(q_asl01, "qspec_d3_asl_01"):
		print("[D3-QGEN-006] FAIL: Invalid qdef for qspec_d3_asl_01")
		return false
	if abs(float(q_asl01["answer_spec"]["accepted_values"][0]) - 0.75) > 0.001:
		print("[D3-QGEN-006] FAIL: Expected 0.75 for class survey, got: " + str(q_asl01["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d3_asl_02 (Single die input: div by 3 or even -> 2/3)
	var spec_asl02: Dictionary = _make_mock_spec("qspec_d3_asl_02", "dungeon_03", "addition_rule", "addition_selection", "input", {
		"prompt": "Gieo 1 xúc xắc. Tính xác suất mặt chia hết cho 3 hoặc mặt chẵn.",
		"explanation": "P = 2 / 3.",
		"learning_objective": "Tính xác suất biến cố hợp trên xúc xắc.",
		"interaction_payload": {"input_type": "string"},
		"answer_spec": {"accepted_values": ["{ans_fraction}"]}
	})
	var q_asl02: Dictionary = gen.generate_question(spec_asl02, pack, {})
	if not _is_valid_qdef(q_asl02, "qspec_d3_asl_02"):
		print("[D3-QGEN-006] FAIL: Invalid qdef for qspec_d3_asl_02")
		return false
	if String(q_asl02["answer_spec"]["accepted_values"][0]) != "2 / 3":
		print("[D3-QGEN-006] FAIL: Expected '2 / 3', got: " + String(q_asl02["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d3_asl_03 (BOSS MELKOR SYNTHESIS PROOF)
	# 2 fair dice (n(Omega)=36).
	# A: sum odd (n(A)=18)
	# B: product div by 5 (n(B)=11)
	# Intersection A n B: product div 5 AND sum odd (n(A n B)=6)
	# n(A U B) = 18 + 11 - 6 = 23 => P(A U B) = "23 / 36"
	var spec_asl03: Dictionary = _make_mock_spec("qspec_d3_asl_03", "dungeon_03", "addition_rule", "addition_selection", "matching", {
		"prompt": "BOSS MELKOR SYNTHESIS: Gieo 2 con xúc xắc 6 mặt (n(Omega)=36)...",
		"explanation": "n(A)=18, n(B)=11, n(A n B)=6 => n(A U B)=23 => P(A U B) = 23 / 36.",
		"learning_objective": "Giải bài toán Boss Melkor quy tắc cộng tổng quát.",
		"interaction_payload": {
			"left_items": [
				{"item_id": "l1", "text": "{left_1}"},
				{"item_id": "l2", "text": "{left_2}"},
				{"item_id": "l3", "text": "{left_3}"},
				{"item_id": "l4", "text": "{left_4}"}
			],
			"right_items": [
				{"item_id": "r1", "text": "{right_1}"},
				{"item_id": "r2", "text": "{right_2}"},
				{"item_id": "r3", "text": "{right_3}"},
				{"item_id": "r4", "text": "{right_4}"}
			]
		},
		"answer_spec": {
			"pairs": [
				{"left_id": "l1", "right_id": "r1"},
				{"left_id": "l2", "right_id": "r2"},
				{"left_id": "l3", "right_id": "r3"},
				{"left_id": "l4", "right_id": "r4"}
			]
		}
	})
	var q_asl03: Dictionary = gen.generate_question(spec_asl03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_asl03, "qspec_d3_asl_03"):
		print("[D3-QGEN-006] FAIL: Invalid qdef for Boss MELKOR qspec_d3_asl_03")
		return false

	# Verify Boss MELKOR exact values in interaction payload
	var payload: Dictionary = q_asl03["interaction_payload"] as Dictionary
	var right_items: Array = payload.get("right_items", []) as Array
	if right_items.size() != 4:
		print("[D3-QGEN-006] FAIL: Boss MELKOR expected 4 right items")
		return false
	if String((right_items[0] as Dictionary).get("text", "")) != "18" or \
	   String((right_items[1] as Dictionary).get("text", "")) != "11" or \
	   String((right_items[2] as Dictionary).get("text", "")) != "6" or \
	   String((right_items[3] as Dictionary).get("text", "")) != "23 / 36":
		print("[D3-QGEN-006] FAIL: Boss MELKOR exact values mismatch: expected 18, 11, 6, 23 / 36")
		return false

	print("[D3-QGEN-006] PASS (Boss MELKOR 23/36 proof verified)")
	return true

# --- 7. FOUNDATION IDENTITY & DETERMINISM & BATCH UNIQUENESS ---
static func test_d3_qgen_007_identity_determinism_batch_uniqueness() -> bool:
	print("[D3-QGEN-007] Testing Foundation identity, determinism, and batch generation uniqueness...")
	var gen: D3QuestionGenerator = D3QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_03", "addition_rule", "addition_general")
	var spec: Dictionary = _make_mock_spec("qspec_d3_ag_01", "dungeon_03", "addition_rule", "addition_general", "input", {
		"prompt": "Test {p_A}",
		"explanation": "Test exp",
		"learning_objective": "Test obj",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {"accepted_values": ["{ans_prob}"]}
	})

	# 1. Deterministic repeatability
	var q1: Dictionary = gen.generate_question(spec, pack, {"p_A": 0.6, "p_B": 0.5, "p_inter": 0.3})
	var q2: Dictionary = gen.generate_question(spec, pack, {"p_A": 0.6, "p_B": 0.5, "p_inter": 0.3})
	if q1 != q2:
		print("[D3-QGEN-007] FAIL: Repeated generation with same parameters was not identical")
		return false

	# 2. Foundation Identity prefix & parsing
	var q_id: String = String(q1.get("question_id", ""))
	if not QuestionGeneratorIdentity.is_generated_id(q_id):
		print("[D3-QGEN-007] FAIL: generated ID lacks 'qgen_' prefix: " + q_id)
		return false
	var parsed: Dictionary = QuestionGeneratorIdentity.parse_generated_id(q_id)
	if not bool(parsed.get("success", false)) or parsed.get("spec_id") != "qspec_d3_ag_01":
		print("[D3-QGEN-007] FAIL: Failed to parse generated ID: " + str(parsed))
		return false

	# 3. Batch generation uniqueness across parameter tuples
	var tuples: Array[Dictionary] = [
		{"p_A": 0.6, "p_B": 0.5, "p_inter": 0.3},
		{"p_A": 0.5, "p_B": 0.4, "p_inter": 0.2},
		{"p_A": 0.7, "p_B": 0.4, "p_inter": 0.3}
	]
	var batch_res: Dictionary = gen.generate_batch(spec, pack, tuples)
	if not bool(batch_res.get("success", false)):
		print("[D3-QGEN-007] FAIL: Batch generation failed: " + str(batch_res))
		return false
	var batch_qs: Array = batch_res.get("questions", []) as Array
	if batch_qs.size() != 3:
		print("[D3-QGEN-007] FAIL: Expected 3 batch questions, got: " + str(batch_qs.size()))
		return false

	var seen_ids: Dictionary = {}
	for q_item_var in batch_qs:
		var q_item: Dictionary = q_item_var as Dictionary
		var item_id: String = String(q_item.get("question_id", ""))
		if seen_ids.has(item_id):
			print("[D3-QGEN-007] FAIL: Duplicate ID in batch: " + item_id)
			return false
		seen_ids[item_id] = true

	print("[D3-QGEN-007] PASS")
	return true

# --- 8. D4 ANTI-LEAKAGE & EVALUATOR COMPATIBILITY ---
static func test_d3_qgen_008_d4_anti_leakage_and_evaluator_compatibility() -> bool:
	print("[D3-QGEN-008] Testing D4 anti-leakage guard & QuestionEvaluator compatibility...")
	var gen: D3QuestionGenerator = D3QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_03", "addition_rule", "addition_general")

	# Verify QuestionEvaluator evaluates D3 float addition answers
	var spec_float: Dictionary = _make_mock_spec("qspec_d3_ag_01", "dungeon_03", "addition_rule", "addition_general", "input", {
		"prompt": "Test float",
		"explanation": "Test exp",
		"learning_objective": "Test obj",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_float: Dictionary = gen.generate_question(spec_float, pack, {"p_A": 0.6, "p_B": 0.5, "p_inter": 0.3})

	# Submit answer "0.8"
	var eval_res: Dictionary = QuestionEvaluator.evaluate(
		q_float,
		{"value": "0.8"},
		"stage_03_01",
		"practice",
		5.0,
		{"PERFECT": 10.0, "GREAT": 20.0, "GOOD": 30.0, "PASS": 45.0},
		"attempt_d3_001"
	)
	if not bool(eval_res.get("success", false)):
		print("[D3-QGEN-008] FAIL: QuestionEvaluator failed on valid float submission: " + str(eval_res))
		return false
	var result_data: Dictionary = eval_res.get("result", {}) as Dictionary
	if not bool(result_data.get("is_correct", false)):
		print("[D3-QGEN-008] FAIL: Submission 0.8 evaluated as incorrect for accepted float 0.8")
		return false

	print("[D3-QGEN-008] PASS")
	return true

# --- MOCK HELPERS ---
static func _make_mock_pack(dungeon_id: String, topic_id: String, subtopic_id: String) -> Dictionary:
	return {
		"schema_version": 1,
		"pack_id": "mkp_" + subtopic_id,
		"dungeon_id": dungeon_id,
		"topic_id": topic_id,
		"subtopic_id": subtopic_id,
		"domain_variables": {},
		"math_rules": {},
		"forbidden_concepts": [],
		"prerequisite_concepts": []
	}

static func _make_mock_spec(spec_id: String, dungeon_id: String, topic_id: String, subtopic_id: String, itype: String, template: Dictionary) -> Dictionary:
	return {
		"schema_version": 1,
		"spec_id": spec_id,
		"generator_family_id": "family_d3_procedural",
		"pack_id": "mkp_" + subtopic_id,
		"dungeon_id": dungeon_id,
		"topic_id": topic_id,
		"subtopic_id": subtopic_id,
		"difficulty_range": {"min": 1, "max": 5},
		"interaction_type": itype,
		"template": template,
		"parameter_bindings": []
	}

static func _is_valid_qdef(q: Dictionary, expected_spec_id: String) -> bool:
	var q_id: String = String(q.get("question_id", ""))
	if not QuestionGeneratorIdentity.is_generated_id(q_id):
		return false
	var parsed: Dictionary = QuestionGeneratorIdentity.parse_generated_id(q_id)
	if not bool(parsed.get("success", false)) or parsed.get("spec_id") != expected_spec_id:
		return false
	if String(q.get("prompt", "")).is_empty():
		return false
	if String(q.get("explanation", "")).is_empty():
		return false
	if not (q.get("interaction_payload") is Dictionary) or not (q.get("answer_spec") is Dictionary):
		return false
	return true
