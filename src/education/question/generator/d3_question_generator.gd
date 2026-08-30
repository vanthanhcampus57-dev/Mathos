class_name D3QuestionGenerator
extends QuestionGenerator

## Production procedural QuestionGenerator for Dungeon 3 (addition_rule).
## Enforces mathematical authority from accepted HEAD ce5dd4281657dec5a0036ed4165c69c70c588d02:
## - Union & Intersection events: A U B ("A or B"), A n B ("A and B").
## - Mutually Exclusive events: A n B = EmptySet => n(A n B) = 0 => P(A n B) = 0.0.
## - Simple Addition Rule: P(A U B) = P(A) + P(B) when A n B = EmptySet.
## - General Addition Rule: P(A U B) = P(A) + P(B) - P(A n B) for any two events.
## - Boss MELKOR Synthesis (qspec_d3_asl_03): 2 fair dice (n(Omega)=36).
##   A: sum is odd (n(A)=18), B: product div by 5 (n(B)=11), A n B: (n(A n B)=6).
##   n(A U B) = 18 + 11 - 6 = 23 => P(A U B) = "23 / 36".
## - FORBIDDEN: NO D4 multiplication/independence formulas (P(A n B) = P(A)*P(B) is forbidden).
## - FORBIDDEN: NO combinatorics (C(n,k), A(n,k)).
## - Spec IDs locked to canonical format: qspec_d3_<code>_<nn>.

func get_family_id() -> String:
	return "family_d3_procedural"

func generate_question(spec: Dictionary, pack: Dictionary, parameters: Dictionary = {}) -> Dictionary:
	var spec_id: String = String(spec.get("spec_id", ""))
	var params_enriched: Dictionary = parameters.duplicate(true)

	_enrich_d3_parameters(spec_id, params_enriched)

	return super.generate_question(spec, pack, params_enriched)

func _enrich_d3_parameters(spec_id: String, params: Dictionary) -> void:
	match spec_id:
		# --- SUBTOPIC 3.1: union_intersection ---
		"qspec_d3_ui_01":
			params["correct_symbol"] = "A ∪ B"
			params["incorrect_symbol_1"] = "A ∩ B"
			params["incorrect_symbol_2"] = "A \\ B"
			params["incorrect_symbol_3"] = "A × B"

		"qspec_d3_ui_02":
			var n_A: int = int(params.get("n_A", 15))
			var n_B: int = int(params.get("n_B", 12))
			var n_inter: int = int(params.get("n_inter", 5))
			var n_union: int = calc_union_count(n_A, n_B, n_inter)
			params["n_A"] = n_A
			params["n_B"] = n_B
			params["n_inter"] = n_inter
			params["ans_n_union"] = n_union

		"qspec_d3_ui_03":
			params["left_1"] = "Ký hiệu A ∪ B"
			params["left_2"] = "Ký hiệu A ∩ B"
			params["left_3"] = "Biến cố A không xảy ra"
			params["right_1"] = "Biến cố A hoặc B xảy ra"
			params["right_2"] = "Biến cố A và B cùng xảy ra"
			params["right_3"] = "Biến cố đối A_bar"

		# --- SUBTOPIC 3.2: mutually_exclusive ---
		"qspec_d3_me_01":
			params["valid_pair"] = "Xuất hiện mặt lẻ và xuất hiện mặt chẵn (khi gieo 1 xúc xắc)"
			params["invalid_pair_1"] = "Xuất hiện mặt chẵn và xuất hiện mặt lớn hơn 4"
			params["invalid_pair_2"] = "Xuất hiện mặt lẻ và xuất hiện mặt số nguyên tố"
			params["invalid_pair_3"] = "Rút được lá bài đỏ và rút được lá bài K"

		"qspec_d3_me_02":
			params["p_inter"] = 0.0
			params["ans_p_inter"] = 0.0

		"qspec_d3_me_03":
			params["item_1_text"] = "Gieo 1 con xúc xắc: 'Mặt chẵn' và 'Mặt lẻ'"
			params["item_2_text"] = "Rút 1 lá bài: 'Lá K' và 'Lá Q'"
			params["item_3_text"] = "Gieo 1 con xúc xắc: 'Mặt chẵn' và 'Mặt > 4'"
			params["item_4_text"] = "Rút 1 lá bài: 'Lá bài đỏ' và 'Lá K'"

		# --- SUBTOPIC 3.3: addition_simple ---
		"qspec_d3_as_01":
			var p_A: float = float(params.get("p_A", 0.2))
			var p_B: float = float(params.get("p_B", 0.35))
			var ans_p: float = calc_simple_addition_prob(p_A, p_B)
			params["p_A"] = p_A
			params["p_B"] = p_B
			params["ans_prob"] = ans_p

		"qspec_d3_as_02":
			var p_A: float = float(params.get("p_A", 0.25))
			var p_B: float = float(params.get("p_B", 0.35))
			var ans_p: float = calc_simple_addition_prob(p_A, p_B)
			params["p_A"] = p_A
			params["p_B"] = p_B
			params["ans_prob"] = ans_p

		"qspec_d3_as_03":
			params["left_1"] = "Rút được lá K hoặc lá Q (bộ bài 52 lá)"
			params["left_2"] = "Bắn trúng vòng 10 hoặc 9 (P(10)=0.2, P(9)=0.35)"
			params["left_3"] = "Rút được bi đỏ hoặc xanh (túi 3 đỏ, 2 xanh, 5 vàng)"
			params["right_1"] = "2 / 13"
			params["right_2"] = "0.55"
			params["right_3"] = "1 / 2"

		# --- SUBTOPIC 3.4: addition_general ---
		"qspec_d3_ag_01":
			var p_A: float = float(params.get("p_A", 0.6))
			var p_B: float = float(params.get("p_B", 0.5))
			var p_inter: float = float(params.get("p_inter", 0.3))
			var ans_p: float = calc_general_addition_prob(p_A, p_B, p_inter)
			params["p_A"] = p_A
			params["p_B"] = p_B
			params["p_inter"] = p_inter
			params["ans_prob"] = ans_p

		"qspec_d3_ag_02":
			# Card draw: Red (26/52) or King (4/52), Intersection Red King (2/52)
			# P(Red U King) = (26 + 4 - 2) / 52 = 28 / 52 = 7 / 13
			params["correct_fraction"] = "7 / 13"
			params["incorrect_1"] = "15 / 26"
			params["incorrect_2"] = "1 / 2"
			params["incorrect_3"] = "30 / 52"

		"qspec_d3_ag_03":
			params["item_1_text"] = "Rút được lá bài màu Đỏ hoặc lá K"
			params["item_2_text"] = "Học sinh giỏi Toán (20) hoặc giỏi Anh (15), cả hai (5) trong 40 em"
			params["item_3_text"] = "Gieo 1 xúc xắc: Số chẵn hoặc số > 4"
			params["item_4_text"] = "Gieo 1 xúc xắc: Số lẻ hoặc số chia hết cho 3"

		# --- SUBTOPIC 3.5: addition_selection ---
		"qspec_d3_asl_01":
			var N_math: int = int(params.get("N_math", 20))
			var N_eng: int = int(params.get("N_eng", 15))
			var N_both: int = int(params.get("N_both", 5))
			var N_total: int = int(params.get("N_total", 40))
			var n_union: int = calc_union_count(N_math, N_eng, N_both)
			var ans_p: float = round((float(n_union) / float(N_total)) * 1000.0) / 1000.0
			params["N_math"] = N_math
			params["N_eng"] = N_eng
			params["N_both"] = N_both
			params["N_total"] = N_total
			params["ans_prob"] = ans_p

		"qspec_d3_asl_02":
			# Single die: A = {3, 6} (div by 3, n(A)=2), B = {2, 4, 6} (even, n(B)=3), A n B = {6} (n(inter)=1)
			# n(A U B) = 2 + 3 - 1 = 4 => P = 4 / 6 = 2 / 3
			params["ans_fraction"] = "2 / 3"

		"qspec_d3_asl_03":
			# BOSS MELKOR SYNTHESIS:
			# 2 fair dice (n(Omega)=36).
			# Event A: sum is odd => n(A) = 18
			# Event B: product is divisible by 5 => n(B) = 11
			# Intersection A n B: product div 5 AND sum odd => n(A n B) = 6
			# n(A U B) = 18 + 11 - 6 = 23 => P(A U B) = "23 / 36"
			params["left_1"] = "Số kết quả n(A) của biến cố A (tổng số chấm là số lẻ)"
			params["left_2"] = "Số kết quả n(B) của biến cố B (tích hai số chấm chia hết cho 5)"
			params["left_3"] = "Số kết quả giao n(A ∩ B) (tổng lẻ VÀ tích chia hết cho 5)"
			params["left_4"] = "Xác suất P(A ∪ B) theo quy tắc cộng tổng quát"
			params["right_1"] = "18"
			params["right_2"] = "11"
			params["right_3"] = "6"
			params["right_4"] = "23 / 36"

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

static func calc_union_count(n_A: int, n_B: int, n_inter: int) -> int:
	return n_A + n_B - n_inter

static func calc_simple_addition_prob(p_A: float, p_B: float) -> float:
	return round((p_A + p_B) * 1000.0) / 1000.0

static func calc_general_addition_prob(p_A: float, p_B: float, p_inter: float) -> float:
	return round((p_A + p_B - p_inter) * 1000.0) / 1000.0

static func is_mutually_exclusive(n_inter: int) -> bool:
	return n_inter == 0
