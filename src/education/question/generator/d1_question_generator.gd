class_name D1QuestionGenerator
extends QuestionGenerator

## Production procedural QuestionGenerator for Dungeon 1 (trial_sample_event).
## Enforces mathematical authority:
## - 2^k, 6^k, 2^3 = 8
## - n(Omega) <= 36
## - ordered pairs (x,y) for dice sum counting
## - urn 2-ball draw without replacement (unordered pairs, direct enumeration)
## - NO C(n,k), NO D2 classical probability fraction, NO D3/D4 rules.

func get_family_id() -> String:
	return "family_d1_procedural"

func generate_question(spec: Dictionary, pack: Dictionary, parameters: Dictionary = {}) -> Dictionary:
	var spec_id: String = String(spec.get("spec_id", ""))
	var params_enriched: Dictionary = parameters.duplicate(true)

	_enrich_d1_parameters(spec_id, params_enriched)

	var q: Dictionary = super.generate_question(spec, pack, params_enriched)
	if params_enriched.has("ans"):
		var ans_val: Variant = params_enriched["ans"]
		(q["answer_spec"] as Dictionary)["accepted_values"] = [ans_val]

	return q

func _enrich_d1_parameters(spec_id: String, params: Dictionary) -> void:
	match spec_id:
		"qspec_d1_rt_01":
			var variant: String = String(params.get("variant", "v1"))
			match variant:
				"v2":
					params["action_random"] = "Rút ngẫu nhiên 1 lá bài từ bộ 52 lá"
					params["action_det_1"] = "Hòa tan muối ăn vào nước ở nhiệt độ phòng"
					params["action_det_2"] = "Thả quả bóng cao su nảy trên sàn"
					params["action_det_3"] = "Tính 10 + 15 = 25"
				"v3":
					params["action_random"] = "Bốc ngẫu nhiên 1 viên bi từ túi có bi đỏ và bi xanh"
					params["action_det_1"] = "Đóng băng nước hoa quả ở -18°C"
					params["action_det_2"] = "Đốt nến trong không khí"
					params["action_det_3"] = "Tính 7 x 8 = 56"
				_:
					params["action_random"] = "Gieo một con xúc xắc 6 mặt cân đối"
					params["action_det_1"] = "Đun sôi nước tinh khiết ở 100°C"
					params["action_det_2"] = "Thả hòn đá rơi tự do từ trên cao"
					params["action_det_3"] = "Tính 5 x 6 = 30"

		"qspec_d1_rt_02":
			var variant: String = String(params.get("variant", "v1"))
			if variant == "v2":
				params["left_1"] = "Gieo 1 con xúc xắc 4 mặt"
				params["left_2"] = "Gieo 1 con xúc xắc 8 mặt"
				params["left_3"] = "Chọn 1 ngày trong tuần"
				params["right_1"] = "4 kết quả"
				params["right_2"] = "8 kết quả"
				params["right_3"] = "7 kết quả"
			else:
				params["left_1"] = "Gieo 1 đồng xu cân đối"
				params["left_2"] = "Gieo 1 con xúc xắc 6 mặt"
				params["left_3"] = "Rút 1 lá bài từ bộ 52 lá"
				params["right_1"] = "2 kết quả"
				params["right_2"] = "6 kết quả"
				params["right_3"] = "52 kết quả"

		"qspec_d1_rt_03":
			params["item_1_text"] = "Gieo 1 đồng xu cân đối"
			params["item_2_text"] = "Rút 1 lá bài từ bộ bài 52 lá"
			params["item_3_text"] = "Đun sôi nước tinh khiết ở 100°C"
			params["item_4_text"] = "Thả hòn đá rơi từ trên cao"

		"qspec_d1_ss_01":
			var faces: int = int(params.get("faces", 6))
			match faces:
				4:
					params["opt_a_text"] = "Ω = {1, 2, 3, 4}"
					params["opt_b_text"] = "Ω = {1, 2, 3}"
					params["opt_c_text"] = "Ω = {0, 1, 2, 3, 4}"
					params["opt_d_text"] = "Ω = {4}"
				8:
					params["opt_a_text"] = "Ω = {1, 2, 3, 4, 5, 6, 7, 8}"
					params["opt_b_text"] = "Ω = {1, 2, 3, 4, 5, 6}"
					params["opt_c_text"] = "Ω = {0, 1, 2, 3, 4, 5, 6, 7, 8}"
					params["opt_d_text"] = "Ω = {8}"
				_:
					params["opt_a_text"] = "Ω = {1, 2, 3, 4, 5, 6}"
					params["opt_b_text"] = "Ω = {1, 2, 3, 4}"
					params["opt_c_text"] = "Ω = {0, 1, 2, 3, 4, 5, 6}"
					params["opt_d_text"] = "Ω = {6}"

		"qspec_d1_ss_02":
			var k: int = int(params.get("k", 1))
			var ans: int = int(pow(2, k))
			params["k"] = k
			params["ans"] = ans

		"qspec_d1_es_01":
			var etype: String = String(params.get("event_type", "odd"))
			match etype:
				"even":
					params["event_label"] = "số chẵn"
					params["opt_a_text"] = "A = {2, 4, 6}"
					params["opt_b_text"] = "A = {1, 3, 5}"
					params["opt_c_text"] = "A = {2, 4}"
					params["opt_d_text"] = "A = {1, 2, 4, 6}"
				"prime":
					params["event_label"] = "số nguyên tố"
					params["opt_a_text"] = "A = {2, 3, 5}"
					params["opt_b_text"] = "A = {1, 2, 3, 5}"
					params["opt_c_text"] = "A = {3, 5}"
					params["opt_d_text"] = "A = {2, 4, 6}"
				_:
					params["event_label"] = "số lẻ"
					params["opt_a_text"] = "A = {1, 3, 5}"
					params["opt_b_text"] = "A = {2, 4, 6}"
					params["opt_c_text"] = "A = {1, 2, 3}"
					params["opt_d_text"] = "A = {3, 5}"

		"qspec_d1_es_02":
			var k: int = int(params.get("k", 3))
			var favorable: Array[int] = []
			for face in range(k + 1, 7):
				favorable.append(face)
			params["k"] = k
			params["ans"] = favorable.size()
			var fav_strs: Array[String] = []
			for f in favorable:
				fav_strs.append(str(f))
			params["favorable_set"] = "{" + ", ".join(fav_strs) + "}"

		"qspec_d1_es_03":
			params["N"] = int(params.get("N", 10))
			params["m"] = int(params.get("m", 3))

		"qspec_d1_ec_02":
			var variant: String = String(params.get("variant", "v1"))
			params["impossible_value"] = "0" if variant == "v2" else "7"

		"qspec_d1_co_01":
			var S: int = int(params.get("S", 5))
			var pairs: Array[String] = []
			for x in range(1, 7):
				for y in range(1, 7):
					if x + y == S:
						pairs.append("(%d,%d)" % [x, y])
			params["S"] = S
			params["ans"] = pairs.size()
			params["pairs_list"] = ", ".join(pairs)

		"qspec_d1_co_02":
			var k: int = int(params.get("k", 2))
			var seqs: Array[String] = []
			for c1 in ["S", "N"]:
				for c2 in ["S", "N"]:
					for c3 in ["S", "N"]:
						var heads: int = (1 if c1 == "S" else 0) + (1 if c2 == "S" else 0) + (1 if c3 == "S" else 0)
						if heads >= k:
							seqs.append(c1 + c2 + c3)
			params["k"] = k
			params["ans"] = seqs.size()
			params["sequences_list"] = "{" + ", ".join(seqs) + "}"

		"qspec_d1_co_03":
			var setup: String = String(params.get("setup", "urn_setup_1"))
			if setup == "urn_setup_2":
				params["R_list"] = "{R1, R2}"
				params["B_list"] = "{B1, B2}"
				params["left_1_text"] = "Số cặp bi đỏ {R1R2}"
				params["left_2_text"] = "Số cặp bi xanh {B1B2}"
				params["right_1_text"] = "1 cặp"
				params["right_2_text"] = "1 cặp"
				params["red_pairs"] = "{R1R2}"
				params["blue_pairs"] = "{B1B2}"
			else:
				params["R_list"] = "{R1, R2, R3}"
				params["B_list"] = "{B1, B2}"
				params["left_1_text"] = "Số cặp bi đỏ {R1R2, R1R3, R2R3}"
				params["left_2_text"] = "Số cặp bi xanh {B1B2}"
				params["right_1_text"] = "3 cặp"
				params["right_2_text"] = "1 cặp"
				params["red_pairs"] = "{R1R2, R1R3, R2R3}"
				params["blue_pairs"] = "{B1B2}"
