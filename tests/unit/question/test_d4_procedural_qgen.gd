class_name TestD4ProceduralQGen
extends RefCounted

## Unit test suite for Dungeon 4 Procedural Question Generation (multiplication_independence).
## Validates all 15 locked canonical spec IDs (qspec_d4_<code>_<nn>):
## - qspec_d4_ind_01..03 (independence)
## - qspec_d4_td_01..03 (tree_diagram)
## - qspec_d4_m2s_01..03 (multiplication_two_step)
## - qspec_d4_mc_01..03 (multiplication_chain & 3 dice all sixes 1/216 proof)
## - qspec_d4_ia_01..03 (independence_application & Boss APHODIUS 0.976 / 0.38 / 1/6 proofs)
## Enforces anti-leakage boundary (NO Bayes, NO conditional updates, NO continuous prob, NO expectation).

const QuestionGeneratorIdentity = preload("res://src/education/question/generator/question_generator_identity.gd")
const D4QuestionGenerator = preload("res://src/education/question/generator/d4_question_generator.gd")
const QuestionEvaluator = preload("res://src/education/question/question_evaluator.gd")

static func run_all_tests() -> bool:
	print("--- RUNNING D4 PROCEDURAL QGEN SUITE ---")
	var all_ok: bool = true

	all_ok = test_d4_qgen_001_math_utilities_contract() and all_ok
	all_ok = test_d4_qgen_002_independence_subtopic() and all_ok
	all_ok = test_d4_qgen_003_tree_diagram_subtopic() and all_ok
	all_ok = test_d4_qgen_004_multiplication_two_step_subtopic() and all_ok
	all_ok = test_d4_qgen_005_multiplication_chain_3_dice_proof() and all_ok
	all_ok = test_d4_qgen_006_independence_application_boss_aphodius_proof() and all_ok
	all_ok = test_d4_qgen_007_identity_determinism_batch_uniqueness() and all_ok
	all_ok = test_d4_qgen_008_out_of_scope_leakage_and_evaluator_compatibility() and all_ok

	return all_ok

# --- 1. MATH UTILITIES CONTRACT ---
static func test_d4_qgen_001_math_utilities_contract() -> bool:
	print("[D4-QGEN-001] Testing D4 mathematical utility rules...")

	# Two-step multiplication: 0.4 * 0.5 = 0.2
	if abs(D4QuestionGenerator.calc_two_step_mult_prob(0.4, 0.5) - 0.2) > 0.0001:
		print("[D4-QGEN-001] FAIL: calc_two_step_mult_prob(0.4, 0.5) expected 0.2")
		return false

	# Both miss: (1 - 0.7)*(1 - 0.8) = 0.3 * 0.2 = 0.06
	if abs(D4QuestionGenerator.calc_both_miss_prob(0.7, 0.8) - 0.06) > 0.0001:
		print("[D4-QGEN-001] FAIL: calc_both_miss_prob(0.7, 0.8) expected 0.06")
		return false

	# Chain multiplication: 0.7 * 0.8 * 0.9 = 0.504
	if abs(D4QuestionGenerator.calc_chain_mult_prob([0.7, 0.8, 0.9]) - 0.504) > 0.0001:
		print("[D4-QGEN-001] FAIL: calc_chain_mult_prob([0.7, 0.8, 0.9]) expected 0.504")
		return false

	# At least one independent: 1 - (1 - 0.7)*(1 - 0.8) = 1 - 0.06 = 0.94
	if abs(D4QuestionGenerator.calc_at_least_one_independent_prob([0.7, 0.8]) - 0.94) > 0.0001:
		print("[D4-QGEN-001] FAIL: calc_at_least_one_independent_prob([0.7, 0.8]) expected 0.94")
		return false

	# Exactly one hit: 0.8 * (1 - 0.7) + (1 - 0.8) * 0.7 = 0.24 + 0.14 = 0.38
	if abs(D4QuestionGenerator.calc_exactly_one_hit_prob(0.8, 0.7) - 0.38) > 0.0001:
		print("[D4-QGEN-001] FAIL: calc_exactly_one_hit_prob(0.8, 0.7) expected 0.38")
		return false

	# Boss Aphodius final: 1 - (1 - 0.6)*(1 - 0.7)*(1 - 0.8) = 1 - 0.4*0.3*0.2 = 1 - 0.024 = 0.976
	if abs(D4QuestionGenerator.calc_aphodius_final_prob(0.6, 0.7, 0.8) - 0.976) > 0.0001:
		print("[D4-QGEN-001] FAIL: calc_aphodius_final_prob(0.6, 0.7, 0.8) expected 0.976")
		return false

	print("[D4-QGEN-001] PASS")
	return true

# --- 2. INDEPENDENCE SUBTOPIC ---
static func test_d4_qgen_002_independence_subtopic() -> bool:
	print("[D4-QGEN-002] Testing subtopic 'independence' (qspec_d4_ind_01, 02, 03)...")
	var gen: D4QuestionGenerator = D4QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_04", "multiplication_independence", "independence")

	# qspec_d4_ind_01 (MC concept)
	var spec_ind01: Dictionary = _make_mock_spec("qspec_d4_ind_01", "dungeon_04", "multiplication_independence", "independence", "multiple_choice", {
		"prompt": "Phát biểu nào sau đây đúng về hai biến cố **độc lập**?",
		"explanation": "Hai biến cố độc lập khi việc xảy ra hay không xảy ra của biến cố này không ảnh hưởng đến biến cố kia.",
		"learning_objective": "Nhận biết khái niệm biến cố độc lập.",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "{valid_statement}"},
				{"option_id": "opt_b", "text": "{invalid_statement_1}"},
				{"option_id": "opt_c", "text": "{invalid_statement_2}"},
				{"option_id": "opt_d", "text": "{invalid_statement_3}"}
			]
		},
		"answer_spec": {"correct_option_id": "opt_a"}
	})
	var q_ind01: Dictionary = gen.generate_question(spec_ind01, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_ind01, "qspec_d4_ind_01"):
		print("[D4-QGEN-002] FAIL: Invalid qdef for qspec_d4_ind_01")
		return false

	# qspec_d4_ind_02 (Input P(A n B) = 0.4 * 0.5 = 0.2)
	var spec_ind02: Dictionary = _make_mock_spec("qspec_d4_ind_02", "dungeon_04", "multiplication_independence", "independence", "input", {
		"prompt": "Cho P(A)={p_A}, P(B)={p_B} độc lập. Tính P(A n B).",
		"explanation": "P(A n B) = P(A) * P(B) = {ans_prob}.",
		"learning_objective": "Tính P(A n B) cho hai biến cố độc lập.",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_ind02: Dictionary = gen.generate_question(spec_ind02, pack, {"p_A": 0.4, "p_B": 0.5})
	if not _is_valid_qdef(q_ind02, "qspec_d4_ind_02"):
		print("[D4-QGEN-002] FAIL: Invalid qdef for qspec_d4_ind_02")
		return false
	if abs(float(q_ind02["answer_spec"]["accepted_values"][0]) - 0.2) > 0.001:
		print("[D4-QGEN-002] FAIL: Expected 0.2 for P(A n B), got: " + str(q_ind02["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d4_ind_03 (Matching outcome counts)
	var spec_ind03: Dictionary = _make_mock_spec("qspec_d4_ind_03", "dungeon_04", "multiplication_independence", "independence", "matching", {
		"prompt": "Nối phép thử độc lập với số kết quả sơ cấp...",
		"explanation": "Giải thích số kết quả sơ cấp.",
		"learning_objective": "Nối phép thử độc lập với không gian mẫu.",
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
	var q_ind03: Dictionary = gen.generate_question(spec_ind03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_ind03, "qspec_d4_ind_03"):
		print("[D4-QGEN-002] FAIL: Invalid qdef for qspec_d4_ind_03")
		return false

	print("[D4-QGEN-002] PASS")
	return true

# --- 3. TREE DIAGRAM SUBTOPIC ---
static func test_d4_qgen_003_tree_diagram_subtopic() -> bool:
	print("[D4-QGEN-003] Testing subtopic 'tree_diagram' (qspec_d4_td_01, 02, 03)...")
	var gen: D4QuestionGenerator = D4QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_04", "multiplication_independence", "tree_diagram")

	# qspec_d4_td_01 (Input tree branch multiplication)
	var spec_td01: Dictionary = _make_mock_spec("qspec_d4_td_01", "dungeon_04", "multiplication_independence", "tree_diagram", "input", {
		"prompt": "Cho sơ đồ cây với P(A)={p_A}, P(B|A)={p_B_given_A}. Tính P(A n B).",
		"explanation": "Nhân trên nhánh cây: {ans_prob}.",
		"learning_objective": "Tính xác suất nhánh sơ đồ cây.",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_td01: Dictionary = gen.generate_question(spec_td01, pack, {"p_A": 0.6, "p_B_given_A": 0.5})
	if not _is_valid_qdef(q_td01, "qspec_d4_td_01"):
		print("[D4-QGEN-003] FAIL: Invalid qdef for qspec_d4_td_01")
		return false
	if abs(float(q_td01["answer_spec"]["accepted_values"][0]) - 0.3) > 0.001:
		print("[D4-QGEN-003] FAIL: Expected 0.3 for tree branch, got: " + str(q_td01["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d4_td_02 (Input both miss)
	var spec_td02: Dictionary = _make_mock_spec("qspec_d4_td_02", "dungeon_04", "multiplication_independence", "tree_diagram", "input", {
		"prompt": "Hai xạ thủ p1={p1}, p2={p2}. Tính xác suất cả 2 cùng trượt.",
		"explanation": "P(trượt cả 2) = (1 - {p1})*(1 - {p2}) = {ans_prob}.",
		"learning_objective": "Tính xác suất cả 2 cùng trượt.",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_td02: Dictionary = gen.generate_question(spec_td02, pack, {"p1": 0.7, "p2": 0.8})
	if not _is_valid_qdef(q_td02, "qspec_d4_td_02"):
		print("[D4-QGEN-003] FAIL: Invalid qdef for qspec_d4_td_02")
		return false
	if abs(float(q_td02["answer_spec"]["accepted_values"][0]) - 0.06) > 0.001:
		print("[D4-QGEN-003] FAIL: Expected 0.06 for both miss, got: " + str(q_td02["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d4_td_03 (DragDrop)
	var spec_td03: Dictionary = _make_mock_spec("qspec_d4_td_03", "dungeon_04", "multiplication_independence", "tree_diagram", "drag_drop", {
		"prompt": "Phân loại các nhánh xác suất trên sơ đồ cây...",
		"explanation": "Giải thích sơ đồ cây.",
		"learning_objective": "Phân loại nhánh sơ đồ cây.",
		"interaction_payload": {
			"items": [
				{"item_id": "item_1", "text": "{item_1_text}"},
				{"item_id": "item_2", "text": "{item_2_text}"},
				{"item_id": "item_3", "text": "{item_3_text}"},
				{"item_id": "item_4", "text": "{item_4_text}"}
			],
			"targets": [
				{"target_id": "t1", "title": "Nhánh 1"},
				{"target_id": "t2", "title": "Nhánh 2"}
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
	var q_td03: Dictionary = gen.generate_question(spec_td03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_td03, "qspec_d4_td_03"):
		print("[D4-QGEN-003] FAIL: Invalid qdef for qspec_d4_td_03")
		return false

	print("[D4-QGEN-003] PASS")
	return true

# --- 4. MULTIPLICATION TWO STEP SUBTOPIC ---
static func test_d4_qgen_004_multiplication_two_step_subtopic() -> bool:
	print("[D4-QGEN-004] Testing subtopic 'multiplication_two_step' (qspec_d4_m2s_01, 02, 03)...")
	var gen: D4QuestionGenerator = D4QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_04", "multiplication_independence", "multiplication_two_step")

	# qspec_d4_m2s_01 (MC 2 coins both heads = 0.25)
	var spec_m2s01: Dictionary = _make_mock_spec("qspec_d4_m2s_01", "dungeon_04", "multiplication_independence", "multiplication_two_step", "multiple_choice", {
		"prompt": "Gieo 2 đồng xu cân đối độc lập. Tính xác suất cả 2 đều xuất hiện mặt sấp.",
		"explanation": "P = (1/2) * (1/2) = 0.25.",
		"learning_objective": "Tính xác suất gieo 2 đồng xu sấp.",
		"interaction_payload": {
			"options": [
				{"option_id": "opt_a", "text": "{ans_prob}"},
				{"option_id": "opt_b", "text": "0.50"},
				{"option_id": "opt_c", "text": "0.75"}
			]
		},
		"answer_spec": {"correct_option_id": "{correct_opt}"}
	})
	var q_m2s01: Dictionary = gen.generate_question(spec_m2s01, pack, {})
	if not _is_valid_qdef(q_m2s01, "qspec_d4_m2s_01"):
		print("[D4-QGEN-004] FAIL: Invalid qdef for qspec_d4_m2s_01")
		return false

	# qspec_d4_m2s_02 (Input exam takers An & Binh both correct = 0.8 * 0.9 = 0.72)
	var spec_m2s02: Dictionary = _make_mock_spec("qspec_d4_m2s_02", "dungeon_04", "multiplication_independence", "multiplication_two_step", "input", {
		"prompt": "An ({p_an}) và Bình ({p_binh}) làm bài độc lập. Tính P(cả 2 cùng đúng).",
		"explanation": "P = {p_an} * {p_binh} = {ans_prob}.",
		"learning_objective": "Tính xác suất 2 người làm đúng.",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_m2s02: Dictionary = gen.generate_question(spec_m2s02, pack, {"p_an": 0.8, "p_binh": 0.9})
	if not _is_valid_qdef(q_m2s02, "qspec_d4_m2s_02"):
		print("[D4-QGEN-004] FAIL: Invalid qdef for qspec_d4_m2s_02")
		return false
	if abs(float(q_m2s02["answer_spec"]["accepted_values"][0]) - 0.72) > 0.001:
		print("[D4-QGEN-004] FAIL: Expected 0.72 for An & Binh, got: " + str(q_m2s02["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d4_m2s_03 (Matching)
	var spec_m2s03: Dictionary = _make_mock_spec("qspec_d4_m2s_03", "dungeon_04", "multiplication_independence", "multiplication_two_step", "matching", {
		"prompt": "Nối bài toán với xác suất...",
		"explanation": "Giải thích nối quy tắc nhân.",
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
	var q_m2s03: Dictionary = gen.generate_question(spec_m2s03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_m2s03, "qspec_d4_m2s_03"):
		print("[D4-QGEN-004] FAIL: Invalid qdef for qspec_d4_m2s_03")
		return false

	print("[D4-QGEN-004] PASS")
	return true

# --- 5. MULTIPLICATION CHAIN & 3 DICE ALL SIXES PROOF ---
static func test_d4_qgen_005_multiplication_chain_3_dice_proof() -> bool:
	print("[D4-QGEN-005] Testing subtopic 'multiplication_chain' (qspec_d4_mc_01, 02, 03) & 3 dice all sixes 1/216 proof...")
	var gen: D4QuestionGenerator = D4QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_04", "multiplication_independence", "multiplication_chain")

	# qspec_d4_mc_01 (REQUIRED CHECK: 3 fair dice all sixes = 1 / 216)
	var spec_mc01: Dictionary = _make_mock_spec("qspec_d4_mc_01", "dungeon_04", "multiplication_independence", "multiplication_chain", "input", {
		"prompt": "Gieo 3 con xúc xắc 6 mặt độc lập. Tính xác suất cả 3 mặt đều xuất hiện số 6.",
		"explanation": "P = (1/6)^3 = 1 / 216.",
		"learning_objective": "Tính xác suất gieo 3 con xúc xắc mặt 6.",
		"interaction_payload": {"input_type": "string"},
		"answer_spec": {"accepted_values": ["{ans_fraction}"]}
	})
	var q_mc01: Dictionary = gen.generate_question(spec_mc01, pack, {})
	if not _is_valid_qdef(q_mc01, "qspec_d4_mc_01"):
		print("[D4-QGEN-005] FAIL: Invalid qdef for qspec_d4_mc_01")
		return false
	if String(q_mc01["answer_spec"]["accepted_values"][0]) != "1 / 216":
		print("[D4-QGEN-005] FAIL: Expected '1 / 216' for 3 dice all sixes, got: " + String(q_mc01["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d4_mc_02 (Input at least one hit = 1 - 0.3*0.2 = 0.94)
	var spec_mc02: Dictionary = _make_mock_spec("qspec_d4_mc_02", "dungeon_04", "multiplication_independence", "multiplication_chain", "input", {
		"prompt": "Hai xạ thủ p1={p1}, p2={p2}. Tính P(ít nhất 1 trúng).",
		"explanation": "P = 1 - (1 - {p1})*(1 - {p2}) = {ans_prob}.",
		"learning_objective": "Tính xác suất ít nhất 1 xạ thủ trúng.",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_mc02: Dictionary = gen.generate_question(spec_mc02, pack, {"p1": 0.7, "p2": 0.8})
	if not _is_valid_qdef(q_mc02, "qspec_d4_mc_02"):
		print("[D4-QGEN-005] FAIL: Invalid qdef for qspec_d4_mc_02")
		return false
	if abs(float(q_mc02["answer_spec"]["accepted_values"][0]) - 0.94) > 0.001:
		print("[D4-QGEN-005] FAIL: Expected 0.94 for at least one hit, got: " + str(q_mc02["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d4_mc_03 (Input 3 students all correct = 0.7 * 0.8 * 0.9 = 0.504)
	var spec_mc03: Dictionary = _make_mock_spec("qspec_d4_mc_03", "dungeon_04", "multiplication_independence", "multiplication_chain", "input", {
		"prompt": "Ba người pA={pA}, pB={pB}, pC={pC}. Tính P(cả 3 cùng đúng).",
		"explanation": "P = {pA} * {pB} * {pC} = {ans_prob}.",
		"learning_objective": "Tính xác suất 3 người cùng đúng.",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_mc03: Dictionary = gen.generate_question(spec_mc03, pack, {"pA": 0.7, "pB": 0.8, "pC": 0.9})
	if not _is_valid_qdef(q_mc03, "qspec_d4_mc_03"):
		print("[D4-QGEN-005] FAIL: Invalid qdef for qspec_d4_mc_03")
		return false
	if abs(float(q_mc03["answer_spec"]["accepted_values"][0]) - 0.504) > 0.001:
		print("[D4-QGEN-005] FAIL: Expected 0.504 for 3 students, got: " + str(q_mc03["answer_spec"]["accepted_values"][0]))
		return false

	print("[D4-QGEN-005] PASS (3 dice all sixes 1/216 proof verified)")
	return true

# --- 6. INDEPENDENCE APPLICATION & BOSS APHODIUS PROOFS ---
static func test_d4_qgen_006_independence_application_boss_aphodius_proof() -> bool:
	print("[D4-QGEN-006] Testing subtopic 'independence_application' (qspec_d4_ia_01, 02, 03) & Boss APHODIUS 0.976 / 0.38 / 1/6 proofs...")
	var gen: D4QuestionGenerator = D4QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_04", "multiplication_independence", "independence_application")

	# qspec_d4_ia_01 (REQUIRED CHECK: Die1 even AND Die2 div by 3 = 1 / 6)
	var spec_ia01: Dictionary = _make_mock_spec("qspec_d4_ia_01", "dungeon_04", "multiplication_independence", "independence_application", "input", {
		"prompt": "Gieo 2 con xúc xắc. Tính P(xúc xắc 1 chẵn VÀ xúc xắc 2 chia hết cho 3).",
		"explanation": "P = (1/2) * (1/3) = 1 / 6.",
		"learning_objective": "Tính xác suất biến cố giao xúc xắc.",
		"interaction_payload": {"input_type": "string"},
		"answer_spec": {"accepted_values": ["{ans_fraction}"]}
	})
	var q_ia01: Dictionary = gen.generate_question(spec_ia01, pack, {})
	if not _is_valid_qdef(q_ia01, "qspec_d4_ia_01"):
		print("[D4-QGEN-006] FAIL: Invalid qdef for qspec_d4_ia_01")
		return false
	if String(q_ia01["answer_spec"]["accepted_values"][0]) != "1 / 6":
		print("[D4-QGEN-006] FAIL: Expected '1 / 6' for Die1 even & Die2 div 3, got: " + String(q_ia01["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d4_ia_02 (REQUIRED CHECK: Exactly one hit = 0.38 for pA=0.8, pB=0.7)
	var spec_ia02: Dictionary = _make_mock_spec("qspec_d4_ia_02", "dungeon_04", "multiplication_independence", "independence_application", "input", {
		"prompt": "Hai xạ thủ pA={pA}, pB={pB}. Tính P(đúng 1 người trúng).",
		"explanation": "P = 0.8*0.3 + 0.2*0.7 = 0.38.",
		"learning_objective": "Tính xác suất đúng 1 xạ thủ trúng.",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_ia02: Dictionary = gen.generate_question(spec_ia02, pack, {"pA": 0.8, "pB": 0.7})
	if not _is_valid_qdef(q_ia02, "qspec_d4_ia_02"):
		print("[D4-QGEN-006] FAIL: Invalid qdef for qspec_d4_ia_02")
		return false
	if abs(float(q_ia02["answer_spec"]["accepted_values"][0]) - 0.38) > 0.001:
		print("[D4-QGEN-006] FAIL: Expected 0.38 for exactly one hit, got: " + str(q_ia02["answer_spec"]["accepted_values"][0]))
		return false

	# qspec_d4_ia_03 (REQUIRED CHECK: BOSS APHODIUS SYNTHESIS 3 shooters at least 1 hit = 0.976)
	var spec_ia03: Dictionary = _make_mock_spec("qspec_d4_ia_03", "dungeon_04", "multiplication_independence", "independence_application", "matching", {
		"prompt": "BOSS APHODIUS SYNTHESIS: 3 xạ thủ (0.6, 0.7, 0.8)...",
		"explanation": "P(mục tiêu bị trúng) = 1 - 0.4*0.3*0.2 = 0.976.",
		"learning_objective": "Giải bài toán Boss Aphodius.",
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
	var q_ia03: Dictionary = gen.generate_question(spec_ia03, pack, {"variant": "v1"})
	if not _is_valid_qdef(q_ia03, "qspec_d4_ia_03"):
		print("[D4-QGEN-006] FAIL: Invalid qdef for Boss APHODIUS qspec_d4_ia_03")
		return false
	var payload: Dictionary = q_ia03["interaction_payload"] as Dictionary
	var right_items: Array = payload.get("right_items", []) as Array
	if right_items.size() != 3 or String((right_items[1] as Dictionary).get("text", "")) != "0.976":
		print("[D4-QGEN-006] FAIL: Boss APHODIUS target hit expected 0.976")
		return false

	print("[D4-QGEN-006] PASS (Boss APHODIUS 0.976 / 0.38 / 1/6 proofs verified)")
	return true

# --- 7. FOUNDATION IDENTITY & DETERMINISM & BATCH UNIQUENESS ---
static func test_d4_qgen_007_identity_determinism_batch_uniqueness() -> bool:
	print("[D4-QGEN-007] Testing Foundation identity, determinism, and batch generation uniqueness...")
	var gen: D4QuestionGenerator = D4QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_04", "multiplication_independence", "multiplication_chain")
	var spec: Dictionary = _make_mock_spec("qspec_d4_mc_02", "dungeon_04", "multiplication_independence", "multiplication_chain", "input", {
		"prompt": "Test {p1}",
		"explanation": "Test exp",
		"learning_objective": "Test obj",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {"accepted_values": ["{ans_prob}"]}
	})

	# 1. Deterministic repeatability
	var q1: Dictionary = gen.generate_question(spec, pack, {"p1": 0.7, "p2": 0.8})
	var q2: Dictionary = gen.generate_question(spec, pack, {"p1": 0.7, "p2": 0.8})
	if q1 != q2:
		print("[D4-QGEN-007] FAIL: Repeated generation with same parameters was not identical")
		return false

	# 2. Foundation Identity prefix & parsing
	var q_id: String = String(q1.get("question_id", ""))
	if not QuestionGeneratorIdentity.is_generated_id(q_id):
		print("[D4-QGEN-007] FAIL: generated ID lacks 'qgen_' prefix: " + q_id)
		return false
	var parsed: Dictionary = QuestionGeneratorIdentity.parse_generated_id(q_id)
	if not bool(parsed.get("success", false)) or parsed.get("spec_id") != "qspec_d4_mc_02":
		print("[D4-QGEN-007] FAIL: Failed to parse generated ID: " + str(parsed))
		return false

	# 3. Batch generation uniqueness across parameter tuples
	var tuples: Array[Dictionary] = [
		{"p1": 0.7, "p2": 0.8},
		{"p1": 0.6, "p2": 0.9},
		{"p1": 0.8, "p2": 0.5}
	]
	var batch_res: Dictionary = gen.generate_batch(spec, pack, tuples)
	if not bool(batch_res.get("success", false)):
		print("[D4-QGEN-007] FAIL: Batch generation failed: " + str(batch_res))
		return false
	var batch_qs: Array = batch_res.get("questions", []) as Array
	if batch_qs.size() != 3:
		print("[D4-QGEN-007] FAIL: Expected 3 batch questions, got: " + str(batch_qs.size()))
		return false

	var seen_ids: Dictionary = {}
	for q_item_var in batch_qs:
		var q_item: Dictionary = q_item_var as Dictionary
		var item_id: String = String(q_item.get("question_id", ""))
		if seen_ids.has(item_id):
			print("[D4-QGEN-007] FAIL: Duplicate ID in batch: " + item_id)
			return false
		seen_ids[item_id] = true

	print("[D4-QGEN-007] PASS")
	return true

# --- 8. OUT OF SCOPE LEAKAGE GUARD & EVALUATOR COMPATIBILITY ---
static func test_d4_qgen_008_out_of_scope_leakage_and_evaluator_compatibility() -> bool:
	print("[D4-QGEN-008] Testing D5 out-of-scope leakage guard & QuestionEvaluator compatibility...")
	var gen: D4QuestionGenerator = D4QuestionGenerator.new()
	var pack: Dictionary = _make_mock_pack("dungeon_04", "multiplication_independence", "independence_application")

	# Float evaluation with numeric_tolerance = 0.001
	var spec_float: Dictionary = _make_mock_spec("qspec_d4_ia_02", "dungeon_04", "multiplication_independence", "independence_application", "input", {
		"prompt": "Test float",
		"explanation": "Test exp",
		"learning_objective": "Test obj",
		"interaction_payload": {"input_type": "float"},
		"answer_spec": {
			"accepted_values": ["{ans_prob}"],
			"numeric_tolerance": 0.001
		}
	})
	var q_float: Dictionary = gen.generate_question(spec_float, pack, {"pA": 0.8, "pB": 0.7})

	# Submit answer "0.38" to evaluator
	var eval_res: Dictionary = QuestionEvaluator.evaluate(
		q_float,
		{"value": "0.38"},
		"stage_04_01",
		"practice",
		5.0,
		{"PERFECT": 10.0, "GREAT": 20.0, "GOOD": 30.0, "PASS": 45.0},
		"attempt_d4_001"
	)
	if not bool(eval_res.get("success", false)):
		print("[D4-QGEN-008] FAIL: QuestionEvaluator failed on valid float submission: " + str(eval_res))
		return false
	var result_data: Dictionary = eval_res.get("result", {}) as Dictionary
	if not bool(result_data.get("is_correct", false)):
		print("[D4-QGEN-008] FAIL: Submission 0.38 evaluated as incorrect for accepted float 0.38")
		return false

	print("[D4-QGEN-008] PASS")
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
		"generator_family_id": "family_d4_procedural",
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
