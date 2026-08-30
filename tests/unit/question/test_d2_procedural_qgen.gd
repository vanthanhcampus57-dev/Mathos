class_name TestD2ProceduralQGen
extends RefCounted

## Unit test suite for Dungeon 2 Procedural Question Generation (classical_probability).
## Validates all 15 locked canonical spec IDs (qspec_d2_<code>_<nn>):
## - qspec_d2_el_01..03 (equally_likely)
## - qspec_d2_cpf_01..03 (classical_probability_formula)
## - qspec_d2_pr_01..03 (probability_representation)
## - qspec_d2_cp_01..03 (compare_probability)
## - qspec_d2_mdc_01..03 (multi_data_classical)
## Enforces canonical bag authority (5 red + 3 blue -> n(Omega)=8, P(red)=5/8, P(blue)=3/8),
## 3/8 -> 37.5% percentage conversion, cross-multiplication comparison, and QuestionEvaluator contract.

const QuestionGeneratorIdentity = preload("res://src/education/question/generator/question_generator_identity.gd")
const D2QuestionGenerator = preload("res://src/education/question/generator/d2_question_generator.gd")
const QuestionEvaluator = preload("res://src/education/question/question_evaluator.gd")

static func run_all_tests() -> bool:
	print("--- RUNNING D2 PROCEDURAL QGEN SUITE ---")
	var all_ok: bool = true

	all_ok = test_d2_qgen_001_math_utilities_contract() and all_ok
	all_ok = test_d2_qgen_002_equally_likely_subtopic() and all_ok
	all_ok = test_d2_qgen_003_classical_formula_subtopic() and all_ok
	all_ok = test_d2_qgen_004_probability_representation_subtopic() and all_ok
	all_ok = test_d2_qgen_005_compare_probability_subtopic() and all_ok
	all_ok = test_d2_qgen_006_multi_data_classical_bag_authority() and all_ok
	all_ok = test_d2_qgen_007_identity_determinism_batch_uniqueness() and all_ok
	all_ok = test_d2_qgen_008_evaluator_compatibility() and all_ok

	return all_ok

# --- 1. MATH UTILITIES CONTRACT ---
static func test_d2_qgen_001_math_utilities_contract() -> bool:
	print("[D2-QGEN-001] Testing D2 mathematical utility rules...")

	# GCD
	if D2QuestionGenerator.calc_gcd(12, 18) != 6:
		print("[D2-QGEN-001] FAIL: calc_gcd(12,18) expected 6")
		return false
	if D2QuestionGenerator.calc_gcd(5, 8) != 1:
		print("[D2-QGEN-001] FAIL: calc_gcd(5,8) expected 1")
		return false

	# Classical probability simplified fraction string
	if D2QuestionGenerator.calc_classical_probability(5, 8) != "5 / 8":
		print("[D2-QGEN-001] FAIL: calc_classical_probability(5,8) expected '5 / 8', got: " + D2QuestionGenerator.calc_classical_probability(5, 8))
		return false
	if D2QuestionGenerator.calc_classical_probability(3, 8) != "3 / 8":
		print("[D2-QGEN-001] FAIL: calc_classical_probability(3,8) expected '3 / 8'")
		return false
	if D2QuestionGenerator.calc_classical_probability(3, 6) != "1 / 2":
		print("[D2-QGEN-001] FAIL: calc_classical_probability(3,6) expected '1 / 2'")
		return false
	if D2QuestionGenerator.calc_classical_probability(6, 6) != "1":
		print("[D2-QGEN-001] FAIL: calc_classical_probability(6,6) expected '1'")
		return false

	# Decimal & Percentage conversion
	if abs(D2QuestionGenerator.fraction_to_decimal(3, 8) - 0.375) > 0.0001:
		print("[D2-QGEN-001] FAIL: fraction_to_decimal(3,8) expected 0.375")
		return false
	if abs(D2QuestionGenerator.fraction_to_percent(3, 8) - 37.5) > 0.0001:
		print("[D2-QGEN-001] FAIL: fraction_to_percent(3,8) expected 37.5")
		return false

	# Complement probability 1 - P(A)
	if D2QuestionGenerator.calc_complement_probability(3, 8) != "5 / 8":
		print("[D2-QGEN-001] FAIL: calc_complement_probability(3,8) expected '5 / 8'")
		return false

	# Cross multiplication comparison
	# A = 3/8 (3*10=30) vs B = 2/10 (2*8=16) -> greater
	if D2QuestionGenerator.compare_probability(3, 8, 2, 10) != "greater":
		print("[D2-QGEN-001] FAIL: compare_probability(3,8, 2,10) expected 'greater'")
		return false
	# A = 2/10 (2*5=10) vs B = 3/5 (3*10=30) -> less
	if D2QuestionGenerator.compare_probability(2, 10, 3, 5) != "less":
		print("[D2-QGEN-001] FAIL: compare_probability(2,10, 3,5) expected 'less'")
		return false

	print("[D2-QGEN-001] PASS")
	return true

# --- 2. EQUALLY LIKELY SUBTOPIC ---
static func test_d2_qgen_002_equally_likely_subtopic() -> bool:
	print("[D2-QGEN-002] Testing subtopic 'equally_likely' (qspec_d2_el_01, 02, 03)...")
	var gen: D2QuestionGenerator = D2QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_02", "classical_probability", "equally_likely")

	# qspec_d2_el_01 (MC)
	var spec_el01: Dictionary = _make_mock_spec("qspec_d2_el_01", "dungeon_02", "classical_probability", "equally_likely", "multiple_choice", {
		"prompt": "Phép thử ngẫu nhiên nào sau đây có các kết quả sơ cấp **đồng khả năng**?",
		"explanation": "Chi tiết giải thích.",
		"learning_objective": "Nhận biết phép thử đồng khả năng.",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "{valid_scenario}"},
				{"option_id": "opt_b", "text": "{invalid_scenario_1}"},
				{"option_id": "opt_c", "text": "{invalid_scenario_2}"},
				{"option_id": "opt_d", "text": "{invalid_scenario_3}"}
			]
		},
		"answer_spec": {"correct_option_id": "opt_a"}
	})
	var q_el01: Dictionary = gen.generate_question(spec_el01, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_el01, "qspec_d2_el_01"):
		print("[D2-QGEN-002] FAIL: Invalid qdef for qspec_d2_el_01")
		return false
	if q_el01["answer_spec"]["correct_option_id"] != "opt_a":
		print("[D2-QGEN-002] FAIL: Incorrect option for qspec_d2_el_01")
		return false

	# qspec_d2_el_02 (DragDrop)
	var spec_el02: Dictionary = _make_mock_spec("qspec_d2_el_02", "dungeon_02", "classical_probability", "equally_likely", "drag_drop", {
		"prompt": "Kéo thả các tình huống...",
		"explanation": "Giải thích kéo thả.",
		"learning_objective": "Phân loại tình huống đồng khả năng.",
		"interaction_payload": {
			"items": [
				{"item_id": "item_1", "text": "{item_1_text}"},
				{"item_id": "item_2", "text": "{item_2_text}"},
				{"item_id": "item_3", "text": "{item_3_text}"},
				{"item_id": "item_4", "text": "{item_4_text}"}
			],
			"targets": [
				{"target_id": "target_1", "title": "Áp dụng hợp lệ"},
				{"target_id": "target_2", "title": "Áp dụng không hợp lệ"}
			]
		},
		"answer_spec": {
			"mappings": [
				{"item_id": "item_1", "target_id": "target_1"},
				{"item_id": "item_2", "target_id": "target_1"},
				{"item_id": "item_3", "target_id": "target_2"},
				{"item_id": "item_4", "target_id": "target_2"}
			]
		}
	})
	var q_el02: Dictionary = gen.generate_question(spec_el02, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_el02, "qspec_d2_el_02"):
		print("[D2-QGEN-002] FAIL: Invalid qdef for qspec_d2_el_02")
		return false

	# qspec_d2_el_03 (Matching)
	var spec_el03: Dictionary = _make_mock_spec("qspec_d2_el_03", "dungeon_02", "classical_probability", "equally_likely", "matching", {
		"prompt": "Nối phép thử...",
		"explanation": "Giải thích nối.",
		"learning_objective": "Nối phép thử với số kết quả sơ cấp.",
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
	var q_el03: Dictionary = gen.generate_question(spec_el03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_el03, "qspec_d2_el_03"):
		print("[D2-QGEN-002] FAIL: Invalid qdef for qspec_d2_el_03")
		return false

	print("[D2-QGEN-002] PASS")
	return true

# --- 3. CLASSICAL PROBABILITY FORMULA SUBTOPIC ---
static func test_d2_qgen_003_classical_formula_subtopic() -> bool:
	print("[D2-QGEN-003] Testing subtopic 'classical_probability_formula' (qspec_d2_cpf_01, 02, 03)...")
	var gen: D2QuestionGenerator = D2QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_02", "classical_probability", "classical_probability_formula")

	# qspec_d2_cpf_01 (Input string fraction)
	var spec_cpf01: Dictionary = _make_mock_spec("qspec_d2_cpf_01", "dungeon_02", "classical_probability", "classical_probability_formula", "input", {
		"prompt": "Gieo 1 con xúc xắc 6 mặt cân đối. Tính xác suất P(A) xuất hiện mặt {condition_label}.",
		"explanation": "n(A) = {n_A}, n(Omega) = {n_Omega} => P(A) = {ans_fraction}.",
		"learning_objective": "Tính P(A) theo công thức cổ điển.",
		"interaction_payload": {
			"input_type": "string",
			"placeholder_text": "Nhập phân số a / b..."
		},
		"answer_spec": {
			"accepted_values": ["{ans_fraction}"]
		}
	})

	var test_conditions: Dictionary = {
		"even": "1 / 2",
		"odd": "1 / 2",
		"prime": "1 / 2",
		"greater_than_4": "1 / 3",
		"divisible_by_3": "1 / 3"
	}
	for cond in test_conditions.keys():
		var q: Dictionary = gen.generate_question(spec_cpf01, pack, {"condition": cond})
		if not _is_valid_qdef(q, "qspec_d2_cpf_01"):
			print("[D2-QGEN-003] FAIL: Invalid qdef for condition " + cond)
			return false
		var accepted: Array = q["answer_spec"]["accepted_values"]
		if String(accepted[0]) != test_conditions[cond]:
			print("[D2-QGEN-003] FAIL: Fraction mismatch for " + cond + ": expected '" + test_conditions[cond] + "', got '" + String(accepted[0]) + "'")
			return false

	# qspec_d2_cpf_02 (MC)
	var spec_cpf02: Dictionary = _make_mock_spec("qspec_d2_cpf_02", "dungeon_02", "classical_probability", "classical_probability_formula", "multiple_choice", {
		"prompt": "Có {N} thẻ từ 1 đến {N}. Rút ngẫu nhiên 1 thẻ. Xác suất rút được thẻ chẵn bằng bao nhiêu?",
		"explanation": "Số thẻ chẵn là {N}/2.",
		"learning_objective": "Tính xác suất rút thẻ chẵn.",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "{prob_str}"},
				{"option_id": "opt_b", "text": "1 / 3"},
				{"option_id": "opt_c", "text": "1 / 4"}
			]
		},
		"answer_spec": {"correct_option_id": "opt_a"}
	})
	for N in [10, 20, 30]:
		var q: Dictionary = gen.generate_question(spec_cpf02, pack, {"N": N})
		if not _is_valid_qdef(q, "qspec_d2_cpf_02"):
			print("[D2-QGEN-003] FAIL: Invalid qdef for N=" + str(N))
			return false

	# qspec_d2_cpf_03 (Matching)
	var spec_cpf03: Dictionary = _make_mock_spec("qspec_d2_cpf_03", "dungeon_02", "classical_probability", "classical_probability_formula", "matching", {
		"prompt": "Nối biến cố gieo xúc xắc 6 mặt với xác suất...",
		"explanation": "Giải thích nối.",
		"learning_objective": "Nối biến cố với xác suất.",
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
	var q_cpf03: Dictionary = gen.generate_question(spec_cpf03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_cpf03, "qspec_d2_cpf_03"):
		print("[D2-QGEN-003] FAIL: Invalid qdef for qspec_d2_cpf_03")
		return false

	print("[D2-QGEN-003] PASS")
	return true

# --- 4. PROBABILITY REPRESENTATION SUBTOPIC ---
static func test_d2_qgen_004_probability_representation_subtopic() -> bool:
	print("[D2-QGEN-004] Testing subtopic 'probability_representation' (qspec_d2_pr_01, 02, 03)...")
	var gen: D2QuestionGenerator = D2QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_02", "classical_probability", "probability_representation")

	# qspec_d2_pr_01 (Input float decimal & percentage 37.5%)
	var spec_pr01: Dictionary = _make_mock_spec("qspec_d2_pr_01", "dungeon_02", "classical_probability", "probability_representation", "input", {
		"prompt": "Biết P(A) = {fraction_str}. Hãy đổi sang dạng số thập phân.",
		"explanation": "Chuyển phân số sang số thập phân.",
		"learning_objective": "Đổi xác suất sang số thập phân.",
		"interaction_payload": {
			"input_type": "float",
			"placeholder_text": "Nhập số thập phân..."
		},
		"answer_spec": {
			"accepted_values": ["{ans_decimal}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_pr01: Dictionary = gen.generate_question(spec_pr01, pack, {"p_num": 3, "p_den": 8})
	if not _is_valid_qdef(q_pr01, "qspec_d2_pr_01"):
		print("[D2-QGEN-004] FAIL: Invalid qdef for qspec_d2_pr_01")
		return false
	var accepted_val: Variant = q_pr01["answer_spec"]["accepted_values"][0]
	if abs(float(accepted_val) - 0.375) > 0.001:
		print("[D2-QGEN-004] FAIL: Expected float 0.375, got: " + str(accepted_val))
		return false

	# qspec_d2_pr_02 (Input complement fraction)
	var spec_pr02: Dictionary = _make_mock_spec("qspec_d2_pr_02", "dungeon_02", "classical_probability", "probability_representation", "input", {
		"prompt": "Cho P(A) = {fraction_str}. Tính P(A_bar) = 1 - P(A).",
		"explanation": "P(A_bar) = {ans_complement_fraction}.",
		"learning_objective": "Tính xác suất biến cố đối.",
		"interaction_payload": {
			"input_type": "string"
		},
		"answer_spec": {
			"accepted_values": ["{ans_complement_fraction}"]
		}
	})
	var q_pr02: Dictionary = gen.generate_question(spec_pr02, pack, {"p_num": 3, "p_den": 8})
	if not _is_valid_qdef(q_pr02, "qspec_d2_pr_02"):
		print("[D2-QGEN-004] FAIL: Invalid qdef for qspec_d2_pr_02")
		return false
	if String(q_pr02["answer_spec"]["accepted_values"][0]) != "5 / 8":
		print("[D2-QGEN-004] FAIL: Expected '5 / 8', got: " + String(q_pr02["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d2_pr_03 (DragDrop representations)
	var spec_pr03: Dictionary = _make_mock_spec("qspec_d2_pr_03", "dungeon_02", "classical_probability", "probability_representation", "drag_drop", {
		"prompt": "Sắp xếp các biểu diễn xác suất...",
		"explanation": "Giải thích dạng biểu diễn.",
		"learning_objective": "Phân loại dạng biểu diễn xác suất.",
		"interaction_payload": {
			"items": [
				{"item_id": "item_1", "text": "{item_1_text}"},
				{"item_id": "item_2", "text": "{item_2_text}"},
				{"item_id": "item_3", "text": "{item_3_text}"}
			],
			"targets": [
				{"target_id": "target_fraction", "title": "Dạng phân số"},
				{"target_id": "target_decimal", "title": "Dạng thập phân"},
				{"target_id": "target_percent", "title": "Dạng phần trăm"}
			]
		},
		"answer_spec": {
			"mappings": [
				{"item_id": "item_1", "target_id": "target_fraction"},
				{"item_id": "item_2", "target_id": "target_decimal"},
				{"item_id": "item_3", "target_id": "target_percent"}
			]
		}
	})
	var q_pr03: Dictionary = gen.generate_question(spec_pr03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_pr03, "qspec_d2_pr_03"):
		print("[D2-QGEN-004] FAIL: Invalid qdef for qspec_d2_pr_03")
		return false

	print("[D2-QGEN-004] PASS")
	return true

# --- 5. COMPARE PROBABILITY SUBTOPIC ---
static func test_d2_qgen_005_compare_probability_subtopic() -> bool:
	print("[D2-QGEN-005] Testing subtopic 'compare_probability' (qspec_d2_cp_01, 02, 03)...")
	var gen: D2QuestionGenerator = D2QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_02", "classical_probability", "compare_probability")

	# qspec_d2_cp_01 (MC highest probability color)
	var spec_cp01: Dictionary = _make_mock_spec("qspec_d2_cp_01", "dungeon_02", "classical_probability", "compare_probability", "multiple_choice", {
		"prompt": "Túi chứa {R} đỏ, {B} xanh, {Y} vàng. Biến cố nào có khả năng xảy ra cao nhất?",
		"explanation": "Biến cố bi {highest_color} có số kết quả thuận lợi lớn nhất.",
		"learning_objective": "So sánh khả năng xảy ra của các biến cố.",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_red", "text": "Rút được bi đỏ"},
				{"option_id": "opt_blue", "text": "Rút được bi xanh"},
				{"option_id": "opt_yellow", "text": "Rút được bi vàng"}
			]
		},
		"answer_spec": {"correct_option_id": "{correct_opt}"}
	})
	var q_cp01: Dictionary = gen.generate_question(spec_cp01, pack, {"R": 5, "B": 3, "Y": 2})
	if not _is_valid_qdef(q_cp01, "qspec_d2_cp_01"):
		print("[D2-QGEN-005] FAIL: Invalid qdef for qspec_d2_cp_01")
		return false
	if q_cp01["answer_spec"]["correct_option_id"] != "opt_red":
		print("[D2-QGEN-005] FAIL: Expected 'opt_red', got: " + String(q_cp01["answer_spec"]["correct_option_id"]))
		return false

	# qspec_d2_cp_02 (DragDrop order increasing)
	var spec_cp02: Dictionary = _make_mock_spec("qspec_d2_cp_02", "dungeon_02", "classical_probability", "compare_probability", "drag_drop", {
		"prompt": "Sắp xếp theo thứ tự xác suất tăng dần...",
		"explanation": "Giải thích so sánh.",
		"learning_objective": "Sắp xếp biến cố theo xác suất.",
		"interaction_payload": {
			"items": [
				{"item_id": "item_1", "text": "{item_1_text}"},
				{"item_id": "item_2", "text": "{item_2_text}"},
				{"item_id": "item_3", "text": "{item_3_text}"}
			],
			"targets": [
				{"target_id": "rank_1", "title": "Thấp nhất"},
				{"target_id": "rank_2", "title": "Trung bình"},
				{"target_id": "rank_3", "title": "Cao nhất"}
			]
		},
		"answer_spec": {
			"mappings": [
				{"item_id": "item_1", "target_id": "rank_1"},
				{"item_id": "item_2", "target_id": "rank_2"},
				{"item_id": "item_3", "target_id": "rank_3"}
			]
		}
	})
	var q_cp02: Dictionary = gen.generate_question(spec_cp02, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_cp02, "qspec_d2_cp_02"):
		print("[D2-QGEN-005] FAIL: Invalid qdef for qspec_d2_cp_02")
		return false

	# qspec_d2_cp_03 (Matching descriptors)
	var spec_cp03: Dictionary = _make_mock_spec("qspec_d2_cp_03", "dungeon_02", "classical_probability", "compare_probability", "matching", {
		"prompt": "Nối biến cố với mô tả khả năng...",
		"explanation": "Giải thích nối khả năng.",
		"learning_objective": "Nối biến cố với khả năng xảy ra.",
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
	var q_cp03: Dictionary = gen.generate_question(spec_cp03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_cp03, "qspec_d2_cp_03"):
		print("[D2-QGEN-005] FAIL: Invalid qdef for qspec_d2_cp_03")
		return false

	print("[D2-QGEN-005] PASS")
	return true

# --- 6. MULTI DATA CLASSICAL SUBTOPIC & CANONICAL BAG AUTHORITY ---
static func test_d2_qgen_006_multi_data_classical_bag_authority() -> bool:
	print("[D2-QGEN-006] Testing subtopic 'multi_data_classical' (qspec_d2_mdc_01, 02, 03) & canonical 5R+3B bag authority...")
	var gen: D2QuestionGenerator = D2QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_02", "classical_probability", "multi_data_classical")

	# qspec_d2_mdc_01 (Canonical Bag Authority: 5 Red + 3 Blue -> Total 8 elementary balls)
	var spec_mdc01: Dictionary = _make_mock_spec("qspec_d2_mdc_01", "dungeon_02", "classical_probability", "multi_data_classical", "input", {
		"prompt": "Túi chứa {R} bi đỏ và {B} bi xanh. Tính P(bi {color_name}).",
		"explanation": "n(Omega) = {total}, P = {ans_fraction}.",
		"learning_objective": "Tính xác suất từ túi bi đỏ và xanh.",
		"interaction_payload": {
			"input_type": "string"
		},
		"answer_spec": {
			"accepted_values": ["{ans_fraction}"]
		}
	})

	# Test P(red) = 5/8 -> "5 / 8"
	var q_red: Dictionary = gen.generate_question(spec_mdc01, pack, {"R": 5, "B": 3, "target_color": "red"})
	if not _is_valid_qdef(q_red, "qspec_d2_mdc_01"):
		print("[D2-QGEN-006] FAIL: Invalid qdef for qspec_d2_mdc_01 (red)")
		return false
	if String(q_red["answer_spec"]["accepted_values"][0]) != "5 / 8":
		print("[D2-QGEN-006] FAIL: P(red) expected '5 / 8', got: " + String(q_red["answer_spec"]["accepted_values"][0]))
		return false

	# Test P(blue) = 3/8 -> "3 / 8"
	var q_blue: Dictionary = gen.generate_question(spec_mdc01, pack, {"R": 5, "B": 3, "target_color": "blue"})
	if String(q_blue["answer_spec"]["accepted_values"][0]) != "3 / 8":
		print("[D2-QGEN-006] FAIL: P(blue) expected '3 / 8', got: " + String(q_blue["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d2_mdc_02 (15 boys, 20 girls -> Total 35 students -> P(girl) = 20/35 = 4/7)
	var spec_mdc02: Dictionary = _make_mock_spec("qspec_d2_mdc_02", "dungeon_02", "classical_probability", "multi_data_classical", "input", {
		"prompt": "Lớp học có {M} nam và {N} nữ. Tính P(chọn được học sinh nữ).",
		"explanation": "n(Omega) = {total}, P = {ans_girl_fraction}.",
		"learning_objective": "Tính xác suất chọn học sinh.",
		"interaction_payload": {
			"input_type": "string"
		},
		"answer_spec": {
			"accepted_values": ["{ans_girl_fraction}"]
		}
	})
	var q_class: Dictionary = gen.generate_question(spec_mdc02, pack, {"M": 15, "N": 20})
	if not _is_valid_qdef(q_class, "qspec_d2_mdc_02"):
		print("[D2-QGEN-006] FAIL: Invalid qdef for qspec_d2_mdc_02")
		return false
	if String(q_class["answer_spec"]["accepted_values"][0]) != "4 / 7":
		print("[D2-QGEN-006] FAIL: P(girl) expected '4 / 7', got: " + String(q_class["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d2_mdc_03 (Matching Boss synthesis)
	var spec_mdc03: Dictionary = _make_mock_spec("qspec_d2_mdc_03", "dungeon_02", "classical_probability", "multi_data_classical", "matching", {
		"prompt": "BOSS ALEATOR SYNTHESIS...",
		"explanation": "Giải thích nối BOSS.",
		"learning_objective": "Nối xác suất từ tập dữ liệu thẻ.",
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
	var q_mdc03: Dictionary = gen.generate_question(spec_mdc03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_mdc03, "qspec_d2_mdc_03"):
		print("[D2-QGEN-006] FAIL: Invalid qdef for qspec_d2_mdc_03")
		return false

	print("[D2-QGEN-006] PASS")
	return true

# --- 7. FOUNDATION IDENTITY & DETERMINISM & BATCH UNIQUENESS ---
static func test_d2_qgen_007_identity_determinism_batch_uniqueness() -> bool:
	print("[D2-QGEN-007] Testing Foundation identity, determinism, and batch generation uniqueness...")
	var gen: D2QuestionGenerator = D2QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_02", "classical_probability", "classical_probability_formula")
	var spec: Dictionary = _make_mock_spec("qspec_d2_cpf_01", "dungeon_02", "classical_probability", "classical_probability_formula", "input", {
		"prompt": "Test prompt {condition_label}",
		"explanation": "Test explanation",
		"learning_objective": "Test objective",
		"interaction_payload": {"input_type": "string"},
		"answer_spec": {"accepted_values": ["{ans_fraction}"]}
	})

	# 1. Deterministic repeatability
	var q1: Dictionary = gen.generate_question(spec, pack, {"condition": "even"})
	var q2: Dictionary = gen.generate_question(spec, pack, {"condition": "even"})
	if q1 != q2:
		print("[D2-QGEN-007] FAIL: Repeated generation with same parameters was not identical")
		return false

	# 2. Foundation Identity prefix & parsing
	var q_id: String = String(q1.get("question_id", ""))
	if not QuestionGeneratorIdentity.is_generated_id(q_id):
		print("[D2-QGEN-007] FAIL: generated ID lacks 'qgen_' prefix: " + q_id)
		return false
	var parsed: Dictionary = QuestionGeneratorIdentity.parse_generated_id(q_id)
	if not bool(parsed.get("success", false)) or parsed.get("spec_id") != "qspec_d2_cpf_01":
		print("[D2-QGEN-007] FAIL: Failed to parse generated ID: " + str(parsed))
		return false

	# 3. Batch generation uniqueness across parameter tuples
	var tuples: Array[Dictionary] = [
		{"condition": "even"},
		{"condition": "odd"},
		{"condition": "prime"},
		{"condition": "greater_than_4"},
		{"condition": "divisible_by_3"}
	]
	var batch_res: Dictionary = gen.generate_batch(spec, pack, tuples)
	if not bool(batch_res.get("success", false)):
		print("[D2-QGEN-007] FAIL: Batch generation failed: " + str(batch_res))
		return false
	var batch_qs: Array = batch_res.get("questions", []) as Array
	if batch_qs.size() != 5:
		print("[D2-QGEN-007] FAIL: Expected 5 batch questions, got: " + str(batch_qs.size()))
		return false

	var seen_ids: Dictionary = {}
	for q_item_var in batch_qs:
		var q_item: Dictionary = q_item_var as Dictionary
		var item_id: String = String(q_item.get("question_id", ""))
		if seen_ids.has(item_id):
			print("[D2-QGEN-007] FAIL: Duplicate ID in batch: " + item_id)
			return false
		seen_ids[item_id] = true

	print("[D2-QGEN-007] PASS")
	return true

# --- 8. QUESTION EVALUATOR COMPATIBILITY ---
static func test_d2_qgen_008_evaluator_compatibility() -> bool:
	print("[D2-QGEN-008] Testing QuestionEvaluator compatibility for D2 float and string answers...")
	var gen: D2QuestionGenerator = D2QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_02", "classical_probability", "probability_representation")

	# Float decimal evaluation with numeric_tolerance = 0.001
	var spec_float: Dictionary = _make_mock_spec("qspec_d2_pr_01", "dungeon_02", "classical_probability", "probability_representation", "input", {
		"prompt": "Test float",
		"explanation": "Test exp",
		"learning_objective": "Test obj",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_decimal}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_float: Dictionary = gen.generate_question(spec_float, pack, {"p_num": 3, "p_den": 8})

	# Submit answer "0.375" to evaluator
	var eval_res: Dictionary = QuestionEvaluator.evaluate(
		q_float,
		{"value": "0.375"},
		"stage_02_01",
		"practice",
		5.0,
		{"PERFECT": 10.0, "GREAT": 20.0, "GOOD": 30.0, "PASS": 45.0},
		"attempt_d2_001"
	)
	if not bool(eval_res.get("success", false)):
		print("[D2-QGEN-008] FAIL: QuestionEvaluator failed on valid float submission: " + str(eval_res))
		return false
	var result_data: Dictionary = eval_res.get("result", {}) as Dictionary
	if not bool(result_data.get("is_correct", false)):
		print("[D2-QGEN-008] FAIL: Submission 0.375 evaluated as incorrect for accepted float 0.375")
		return false

	print("[D2-QGEN-008] PASS")
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
		"generator_family_id": "family_d2_procedural",
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
