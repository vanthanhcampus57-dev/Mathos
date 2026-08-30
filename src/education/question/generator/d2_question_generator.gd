class_name D2QuestionGenerator
extends QuestionGenerator

## Production procedural QuestionGenerator for Dungeon 2 (classical_probability).
## Enforces mathematical authority from accepted HEAD cf80dbb4424ae3b4fb5342cf4095aaa68d9bc092:
## - Classical probability formula P(A) = n(A) / n(Omega) for finite equally-likely elementary outcomes.
## - Outcome granularity: coin_face, die_face, card_identity, ball_identity.
## - Bag authority: 5 red + 3 blue uniform bag (n(Omega) = 8 individual elementary balls; P(red) = 5/8, P(blue) = 3/8).
## - Colors are events, not elementary outcomes.
## - Exact cross-multiplication comparison: left = n_A * n_total_B vs right = n_B * n_total_A.
## - Complement probability: P(A_bar) = 1 - P(A) = (n(Omega) - n(A)) / n(Omega) simplified string.
## - Answers supported: simplified fraction String ("a / b"), float decimal (evaluated with numeric_tolerance = 0.001), percentages (37.5%).
## - NO D3 addition rule (P(A U B)), NO D4 multiplication/independence rule.
## - Spec IDs locked to canonical format: qspec_d2_<code>_<nn>.

func get_family_id() -> String:
	return "family_d2_procedural"

func generate_question(spec: Dictionary, pack: Dictionary, parameters: Dictionary = {}) -> Dictionary:
	var spec_id: String = String(spec.get("spec_id", ""))
	var params_enriched: Dictionary = parameters.duplicate(true)

	_enrich_d2_parameters(spec_id, params_enriched)

	return super.generate_question(spec, pack, params_enriched)

func _enrich_d2_parameters(spec_id: String, params: Dictionary) -> void:
	match spec_id:
		# --- SUBTOPIC 2.1: equally_likely ---
		"qspec_d2_el_01":
			params["valid_scenario"] = "Gieo 1 con xúc xắc 6 mặt cân đối và đồng chất"
			params["invalid_scenario_1"] = "Thí nghiệm 2 kết quả nhưng các kết quả sơ cấp chưa được xác định đồng khả năng"
			params["invalid_scenario_2"] = "Áp dụng công thức cổ điển khi chưa có thông tin về tính cân đối/đồng chất"
			params["invalid_scenario_3"] = "Nhầm lẫn danh mục màu sắc bi là các kết quả sơ cấp khi số lượng bi mỗi màu khác nhau"

		"qspec_d2_el_02":
			params["item_1_text"] = "Gieo 1 đồng xu cân đối"
			params["item_2_text"] = "Gieo 1 con xúc xắc 6 mặt cân đối"
			params["item_3_text"] = "Thí nghiệm 2 kết quả nhưng các kết quả sơ cấp chưa được xác định đồng khả năng"
			params["item_4_text"] = "Nhầm lẫn danh mục màu sắc bi là các kết quả sơ cấp khi số lượng bi mỗi màu khác nhau"

		"qspec_d2_el_03":
			params["left_1"] = "Gieo 1 đồng xu cân đối"
			params["left_2"] = "Gieo 1 con xúc xắc 6 mặt cân đối"
			params["left_3"] = "Rút 1 lá bài từ bộ bài 52 lá"
			params["right_1"] = "2 kết quả sơ cấp"
			params["right_2"] = "6 kết quả sơ cấp"
			params["right_3"] = "52 kết quả sơ cấp"

		# --- SUBTOPIC 2.2: classical_probability_formula ---
		"qspec_d2_cpf_01":
			var condition: String = String(params.get("condition", "even"))
			var n_A: int = 3
			var n_Omega: int = 6
			match condition:
				"odd":
					n_A = 3
					params["condition_label"] = "số lẻ"
				"prime":
					n_A = 3
					params["condition_label"] = "số nguyên tố"
				"greater_than_4":
					n_A = 2
					params["condition_label"] = "lớn hơn 4"
				"divisible_by_3":
					n_A = 2
					params["condition_label"] = "chia hết cho 3"
				_: # "even"
					n_A = 3
					params["condition_label"] = "số chẵn"

			var prob_str: String = calc_classical_probability(n_A, n_Omega)
			params["ans_fraction"] = prob_str
			params["n_A"] = n_A
			params["n_Omega"] = n_Omega

		"qspec_d2_cpf_02":
			var N: int = int(params.get("N", 10))
			var n_A: int = N / 2
			params["N"] = N
			params["prob_str"] = calc_classical_probability(n_A, N)

		"qspec_d2_cpf_03":
			params["left_1"] = "Số chấm là số lẻ"
			params["left_2"] = "Số chấm xuất hiện bằng 6"
			params["left_3"] = "Số chấm xuất hiện nhỏ hơn 7"
			params["right_1"] = "1 / 2"
			params["right_2"] = "1 / 6"
			params["right_3"] = "1"

		# --- SUBTOPIC 2.3: probability_representation ---
		"qspec_d2_pr_01":
			var p_num: int = int(params.get("p_num", 3))
			var p_den: int = int(params.get("p_den", 8))
			var dec_val: float = fraction_to_decimal(p_num, p_den)
			params["fraction_str"] = "%d / %d" % [p_num, p_den]
			params["ans_decimal"] = dec_val
			params["ans_percent"] = fraction_to_percent(p_num, p_den)

		"qspec_d2_pr_02":
			var p_num: int = int(params.get("p_num", 3))
			var p_den: int = int(params.get("p_den", 8))
			params["fraction_str"] = "%d / %d" % [p_num, p_den]
			params["ans_complement_fraction"] = calc_complement_probability(p_num, p_den)

		"qspec_d2_pr_03":
			params["item_1_text"] = "3 / 8"
			params["item_2_text"] = "0.375"
			params["item_3_text"] = "37.5%"

		# --- SUBTOPIC 2.4: compare_probability ---
		"qspec_d2_cp_01":
			var R: int = int(params.get("R", 5))
			var B: int = int(params.get("B", 3))
			var Y: int = int(params.get("Y", 2))
			params["R"] = R
			params["B"] = B
			params["Y"] = Y
			if R >= B and R >= Y:
				params["highest_color"] = "bi đỏ"
				params["correct_opt"] = "opt_red"
			elif B >= R and B >= Y:
				params["highest_color"] = "bi xanh"
				params["correct_opt"] = "opt_blue"
			else:
				params["highest_color"] = "bi vàng"
				params["correct_opt"] = "opt_yellow"

		"qspec_d2_cp_02":
			params["item_1_text"] = "Rút được bi từ túi 2 đỏ / 10 bi" # 2/10 = 0.2
			params["item_2_text"] = "Rút được bi từ túi 3 đỏ / 8 bi"  # 3/8 = 0.375
			params["item_3_text"] = "Rút được bi từ túi 3 đỏ / 5 bi"  # 3/5 = 0.6

		"qspec_d2_cp_03":
			params["left_1"] = "Rút được bi đỏ (túi 4 đỏ, 4 xanh)"
			params["left_2"] = "Rút được bi đỏ hoặc xanh (túi 4 đỏ, 4 xanh)"
			params["left_3"] = "Rút được bi vàng (túi 4 đỏ, 4 xanh)"
			params["right_1"] = "Đồng khả năng với bi xanh"
			params["right_2"] = "Biến cố chắc chắn"
			params["right_3"] = "Biến cố không thể"

		# --- SUBTOPIC 2.5: multi_data_classical ---
		"qspec_d2_mdc_01":
			# Canonical Bag Authority: 5 red + 3 blue (total n(Omega) = 8 elementary ball outcomes)
			var R: int = int(params.get("R", 5))
			var B: int = int(params.get("B", 3))
			var target_color: String = String(params.get("target_color", "red"))
			var total: int = R + B
			var fav: int = R if target_color == "red" else B
			params["color_name"] = "đỏ" if target_color == "red" else "xanh"
			params["R"] = R
			params["B"] = B
			params["total"] = total
			params["ans_fraction"] = calc_classical_probability(fav, total)

		"qspec_d2_mdc_02":
			var M: int = int(params.get("M", 15)) # boys
			var N: int = int(params.get("N", 20)) # girls
			var total: int = M + N
			params["M"] = M
			params["N"] = N
			params["total"] = total
			params["ans_girl_fraction"] = calc_classical_probability(N, total)

		"qspec_d2_mdc_03":
			params["left_1"] = "Rút được thẻ đỏ (5 đỏ, 3 xanh, 2 vàng)"
			params["left_2"] = "Rút được thẻ xanh (5 đỏ, 3 xanh, 2 vàng)"
			params["left_3"] = "Rút được thẻ vàng (5 đỏ, 3 xanh, 2 vàng)"
			params["right_1"] = "1 / 2"
			params["right_2"] = "3 / 10"
			params["right_3"] = "1 / 5"

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

static func fraction_to_decimal(n_A: int, n_Omega: int) -> float:
	if n_Omega <= 0:
		return 0.0
	var val: float = float(n_A) / float(n_Omega)
	return round(val * 1000.0) / 1000.0

static func calc_complement_probability(n_A: int, n_Omega: int) -> String:
	var n_A_bar: int = n_Omega - n_A
	return calc_classical_probability(n_A_bar, n_Omega)

static func fraction_to_percent(n_A: int, n_Omega: int) -> float:
	if n_Omega <= 0:
		return 0.0
	var val: float = (float(n_A) / float(n_Omega)) * 100.0
	return round(val * 100.0) / 100.0

static func compare_probability(n_A: int, n_total_A: int, n_B: int, n_total_B: int) -> String:
	var left: int = n_A * n_total_B
	var right: int = n_B * n_total_A
	if left > right:
		return "greater"
	elif left < right:
		return "less"
	else:
		return "equal"

static func calc_multi_data_prob(group_counts: Array, fav_indices: Array) -> String:
	var n_total: int = 0
	for count_variant in group_counts:
		n_total += int(count_variant)
	var n_fav: int = 0
	for idx_variant in fav_indices:
		var idx: int = int(idx_variant)
		if idx >= 0 and idx < group_counts.size():
			n_fav += int(group_counts[idx])
	return calc_classical_probability(n_fav, n_total)
