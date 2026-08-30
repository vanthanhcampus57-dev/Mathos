class_name D4QuestionGenerator
extends QuestionGenerator

## Production procedural QuestionGenerator for Dungeon 4 (multiplication_independence).
## Enforces mathematical authority from accepted HEAD 72943989b16ecd814452fcefd2289456c42391a9:
## - Independence rule P(A n B) = P(A) * P(B) for independent events.
## - Multiplication chain P(A_1 n ... n A_k) = P(A_1) * ... * P(A_k).
## - At least one event occurs: P(at least 1) = 1 - (1 - p_1)*(1 - p_2)...*(1 - p_k).
## - Exactly one event occurs: P(exactly 1) = p_1*(1 - p_2) + (1 - p_1)*p_2.
## - Specific required checks:
##   1. 3 fair dice all sixes: (1/6)^3 = 1 / 216
##   2. Exactly one hit (p_A=0.8, p_B=0.7): 0.8*0.3 + 0.2*0.7 = 0.38
##   3. Three shooters at least one hit (p_A=0.6, p_B=0.7, p_C=0.8): 1 - 0.4*0.3*0.2 = 0.976
##   4. Die1 even AND Die2 div by 3: (1/2) * (1/3) = 1 / 6
## - FORBIDDEN: NO Bayes' Theorem, NO conditional probability updates, NO continuous prob, NO expectation, NO unsupported combinatorics.
## - Spec IDs locked to canonical format: qspec_d4_<code>_<nn>.

func get_family_id() -> String:
	return "family_d4_procedural"

func generate_question(spec: Dictionary, pack: Dictionary, parameters: Dictionary = {}) -> Dictionary:
	var spec_id: String = String(spec.get("spec_id", ""))
	var params_enriched: Dictionary = parameters.duplicate(true)

	_enrich_d4_parameters(spec_id, params_enriched)

	return super.generate_question(spec, pack, params_enriched)

func _enrich_d4_parameters(spec_id: String, params: Dictionary) -> void:
	match spec_id:
		# --- SUBTOPIC 4.1: independence ---
		"qspec_d4_ind_01":
			params["valid_statement"] = "Kết quả gieo đồng xu lần 1 không làm thay đổi xác suất xuất hiện các mặt ở lần 2"
			params["invalid_statement_1"] = "Rút 1 lá bài từ bộ 52 lá không hoàn lại"
			params["invalid_statement_2"] = "Lấy bi lần 1 không trả lại túi rồi lấy bi lần 2"
			params["invalid_statement_3"] = "Hai biến cố có tổng xác suất bằng 1 luôn độc lập"

		"qspec_d4_ind_02":
			var p_A: float = float(params.get("p_A", 0.4))
			var p_B: float = float(params.get("p_B", 0.5))
			var ans_p: float = calc_two_step_mult_prob(p_A, p_B)
			params["p_A"] = p_A
			params["p_B"] = p_B
			params["ans_prob"] = ans_p

		"qspec_d4_ind_03":
			params["left_1"] = "Gieo 2 đồng xu cân đối độc lập"
			params["left_2"] = "Gieo 1 đồng xu 3 lần độc lập"
			params["left_3"] = "Gieo 2 con xúc xắc 6 mặt độc lập"
			params["right_1"] = "4 kết quả sơ cấp (2^2)"
			params["right_2"] = "8 kết quả sơ cấp (2^3)"
			params["right_3"] = "36 kết quả sơ cấp (6^2)"

		# --- SUBTOPIC 4.2: tree_diagram ---
		"qspec_d4_td_01":
			var p_A: float = float(params.get("p_A", 0.6))
			var p_B_given_A: float = float(params.get("p_B_given_A", 0.5))
			var ans_p: float = calc_two_step_mult_prob(p_A, p_B_given_A)
			params["p_A"] = p_A
			params["p_B_given_A"] = p_B_given_A
			params["ans_prob"] = ans_p

		"qspec_d4_td_02":
			var p1: float = float(params.get("p1", 0.7))
			var p2: float = float(params.get("p2", 0.8))
			var ans_p: float = calc_both_miss_prob(p1, p2)
			params["p1"] = p1
			params["p2"] = p2
			params["ans_prob"] = ans_p

		"qspec_d4_td_03":
			params["item_1_text"] = "Xác suất nhánh cả 2 xạ thủ trúng"
			params["item_2_text"] = "Xác suất nhánh cả 2 xạ thủ trượt"
			params["item_3_text"] = "Xác suất nhánh xạ thủ 1 trúng, xạ thủ 2 trượt"
			params["item_4_text"] = "Xác suất nhánh xạ thủ 1 trượt, xạ thủ 2 trúng"

		# --- SUBTOPIC 4.3: multiplication_two_step ---
		"qspec_d4_m2s_01":
			# Two independent coins: P(both Heads) = (1/2) * (1/2) = 1/4 = 0.25
			params["ans_prob"] = 0.25
			params["correct_opt"] = "opt_a"

		"qspec_d4_m2s_02":
			var p_an: float = float(params.get("p_an", 0.8))
			var p_binh: float = float(params.get("p_binh", 0.9))
			var ans_p: float = calc_two_step_mult_prob(p_an, p_binh)
			params["p_an"] = p_an
			params["p_binh"] = p_binh
			params["ans_prob"] = ans_p

		"qspec_d4_m2s_03":
			params["left_1"] = "Gieo 2 đồng xu: P(cả 2 sấp)"
			params["left_2"] = "An (0.8) và Bình (0.9) làm bài độc lập: P(cả 2 làm đúng)"
			params["left_3"] = "Gieo 2 con xúc xắc: P(cả 2 xuất hiện mặt 6)"
			params["right_1"] = "0.25"
			params["right_2"] = "0.72"
			params["right_3"] = "1 / 36"

		# --- SUBTOPIC 4.4: multiplication_chain ---
		"qspec_d4_mc_01":
			# 3 fair dice all sixes: (1/6)^3 = 1 / 216
			params["ans_fraction"] = "1 / 216"

		"qspec_d4_mc_02":
			var p1: float = float(params.get("p1", 0.7))
			var p2: float = float(params.get("p2", 0.8))
			var ans_p: float = calc_at_least_one_independent_prob([p1, p2])
			params["p1"] = p1
			params["p2"] = p2
			params["ans_prob"] = ans_p

		"qspec_d4_mc_03":
			var pA: float = float(params.get("pA", 0.7))
			var pB: float = float(params.get("pB", 0.8))
			var pC: float = float(params.get("pC", 0.9))
			var ans_p: float = calc_chain_mult_prob([pA, pB, pC])
			params["pA"] = pA
			params["pB"] = pB
			params["pC"] = pC
			params["ans_prob"] = ans_p

		# --- SUBTOPIC 4.5: independence_application ---
		"qspec_d4_ia_01":
			# Die1 even (3/6 = 1/2) AND Die2 div by 3 (2/6 = 1/3) => P = (1/2)*(1/3) = 1 / 6
			params["ans_fraction"] = "1 / 6"

		"qspec_d4_ia_02":
			# Two shooters (pA=0.8, pB=0.7) exactly one hit => 0.8*0.3 + 0.2*0.7 = 0.24 + 0.14 = 0.38
			var pA: float = float(params.get("pA", 0.8))
			var pB: float = float(params.get("pB", 0.7))
			var ans_p: float = calc_exactly_one_hit_prob(pA, pB)
			params["pA"] = pA
			params["pB"] = pB
			params["ans_prob"] = ans_p

		"qspec_d4_ia_03":
			# BOSS APHODIUS SYNTHESIS:
			# 3 shooters (pA=0.6, pB=0.7, pC=0.8) target hit (at least 1 hit) => 1 - 0.4*0.3*0.2 = 0.976
			params["left_1"] = "Xác suất cả 3 xạ thủ cùng trượt mục tiêu"
			params["left_2"] = "Xác suất mục tiêu bị trúng đạn (ít nhất 1 xạ thủ trúng)"
			params["left_3"] = "Xác suất cả 3 xạ thủ cùng trúng mục tiêu"
			params["right_1"] = "0.024"
			params["right_2"] = "0.976"
			params["right_3"] = "0.336"

# --- MATHEMATICAL UTILITIES ---

static func calc_gcd(a: int, b: int) -> int:
	var x: int = abs(a)
	var y: int = abs(b)
	while y != 0:
		var temp: int = y
		y = x % y
		x = temp
	return x if x > 0 else 1

static func calc_classical_probability(n_A: int, n_Omega: int) -> String:
	if n_Omega <= 0:
		return "0"
	if n_A == 0:
		return "0"
	if n_A == n_Omega:
		return "1"
	var g: int = calc_gcd(n_A, n_Omega)
	return "%d / %d" % [n_A / g, n_Omega / g]

static func calc_two_step_mult_prob(p_A: float, p_B: float) -> float:
	return round(p_A * p_B * 1000.0) / 1000.0

static func calc_both_miss_prob(p1: float, p2: float) -> float:
	return round((1.0 - p1) * (1.0 - p2) * 1000.0) / 1000.0

static func calc_chain_mult_prob(p_list: Array) -> float:
	var prod: float = 1.0
	for p_var in p_list:
		prod *= float(p_var)
	return round(prod * 1000.0) / 1000.0

static func calc_at_least_one_independent_prob(p_list: Array) -> float:
	var miss_prod: float = 1.0
	for p_var in p_list:
		miss_prod *= (1.0 - float(p_var))
	return round((1.0 - miss_prod) * 1000.0) / 1000.0

static func calc_exactly_one_hit_prob(pA: float, pB: float) -> float:
	var val: float = pA * (1.0 - pB) + (1.0 - pA) * pB
	return round(val * 1000.0) / 1000.0

static func calc_aphodius_final_prob(pA: float, pB: float, pC: float) -> float:
	var miss_all: float = (1.0 - pA) * (1.0 - pB) * (1.0 - pC)
	return round((1.0 - miss_all) * 1000.0) / 1000.0
