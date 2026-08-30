# DUNGEON 2 QUESTION GENERATION SPEC V1.0

**Document Version**: 1.0.3 (Corrected Round 3)  
**Authority Task ID**: `MATHOS-DIRECT-QGEN-D2-AUTHORITY-001`  
**Dungeon ID**: `dungeon_02`  
**Topic ID**: `classical_probability`  

---

## 1. DETERMINISTIC MATERIALIZATION CONTRACT

Every generator template in Dungeon 2 receives a seed integer `seed_val` and deterministic parameters, returning a valid `QuestionDefinition` Dictionary that strictly conforms to `ContentValidator` rules. All generated probabilities must satisfy 0 <= P(A) <= 1.

---

## 2. GENERATOR TEMPLATE INVENTORY (15 TEMPLATES / EXACTLY 3 PER SUBTOPIC)

### 2.1 Subtopic: `equally_likely`

#### Template `T_d2_el_01` (Interaction: `multiple_choice`, Difficulty: 1)
- **Prompt Pattern**: "Phép thử ngẫu nhiên nào sau đây có các kết quả sơ cấp **đồng khả năng**?"
- **Parameter Mutations**:
  - `valid_scenario`: "Gieo 1 con xúc xắc 6 mặt cân đối và đồng chất (is_valid_classical = true)"
  - `invalid_scenarios`: [
      "Thí nghiệm 2 kết quả nhưng các kết quả sơ cấp chưa được xác định đồng khả năng (is_valid_classical = false)",
      "Áp dụng công thức cổ điển khi chưa có thông tin về tính cân đối/đồng chất (is_valid_classical = false)",
      "Nhầm lẫn danh mục màu sắc bi là các kết quả sơ cấp khi số lượng bi mỗi màu khác nhau (is_valid_classical = false)"
    ]
- **Deterministic Selection**: Place `valid_scenario` at `opt_a`, invalid at `opt_b, opt_c, opt_d`.
- **Answer Spec**: `correct_option_id: "opt_a"`.

#### Template `T_d2_el_02` (Interaction: `drag_drop`, Difficulty: 2)
- **Prompt Pattern**: "Kéo thả các tình huống vào nhóm 'Áp dụng hợp lệ công thức xác suất cổ điển' hoặc 'Áp dụng không hợp lệ công thức xác suất cổ điển'."
- **Parameter Mutations**: 2 valid scenarios (symmetric coin/dice/ball draw) + 2 invalid scenarios (non-equally-likely events).
- **Answer Spec**: `mappings` array mapping each `item_id` to `target_1` or `target_2`.

#### Template `T_d2_el_03` (Interaction: `matching`, Difficulty: 2)
- **Prompt Pattern**: "Nối phép thử ngẫu nhiên cân đối với số kết quả sơ cấp đồng khả năng n(Omega) tương ứng."
- **Parameter Mutations**:
  - Items: (1 đồng xu cân đối -> 2), (1 xúc xắc 6 mặt cân đối -> 6), (Rút 1 lá bài từ bộ 52 lá -> 52).
- **Answer Spec**: Exact 1-to-1 matching pairs array.

---

### 2.2 Subtopic: `classical_probability_formula`

#### Template `T_d2_cpf_01` (Interaction: `input`, Difficulty: 2)
- **Prompt Pattern**: "Gieo 1 con xúc xắc 6 mặt cân đối. Tính xác suất P(A) = n(A) / n(Omega) xuất hiện mặt có số chấm $CONDITION$. Nhập kết quả dưới dạng phân số tối giản a / b."
- **Parameter Mutations**:
  - `CONDITION = "chẵn"` -> n(A) = 3, n(Omega) = 6 -> Answer: "1 / 2"
  - `CONDITION = "là số nguyên tố"` -> n(A) = 3, n(Omega) = 6 -> Answer: "1 / 2"
  - `CONDITION = "lớn hơn 4"` -> n(A) = 2, n(Omega) = 6 -> Answer: "1 / 3"
  - `CONDITION = "chia hết cho 3"` -> n(A) = 2, n(Omega) = 6 -> Answer: "1 / 3"
- **Answer Rule**: `calc_classical_probability(n(A), 6)` returning simplified fraction string. (Result Type: `String`)
- **Runtime Input Spec**: `interaction_payload.input_type = "string"`, `answer_spec.accepted_values = ["1 / 2"]`, `answer_spec.trim_whitespace = true`.

#### Template `T_d2_cpf_02` (Interaction: `multiple_choice`, Difficulty: 1)
- **Prompt Pattern**: "Có N thẻ được đánh số từ 1 đến N. Rút ngẫu nhiên 1 thẻ. Xác suất P(A) = n(A) / n(Omega) rút được thẻ ghi số chẵn bằng bao nhiêu?"
- **Parameter Mutations**: N in {10, 20, 30}.
- **Answer Spec**: `correct_option_id` matching fraction "1 / 2".

#### Template `T_d2_cpf_03` (Interaction: `matching`, Difficulty: 2)
- **Prompt Pattern**: "Nối biến cố khi gieo 1 con xúc xắc 6 mặt cân đối với giá trị xác suất P(A) = n(A) / n(Omega) tương ứng."
- **Parameter Mutations**:
  - Event 1: Số chấm lẻ -> 1 / 2
  - Event 2: Số chấm bằng 6 -> 1 / 6
  - Event 3: Số chấm nhỏ hơn 7 -> 1

---

### 2.3 Subtopic: `probability_representation`

#### Template `T_d2_pr_01` (Interaction: `input`, Difficulty: 2)
- **Prompt Pattern**: "Biết xác suất của biến cố A là P(A) = a / b. Hãy đổi xác suất này sang dạng số thập phân."
- **Parameter Mutations**: (a / b in {1 / 2 -> 0.5, 1 / 4 -> 0.25, 3 / 4 -> 0.75, 1 / 5 -> 0.2, 2 / 5 -> 0.4, 3 / 5 -> 0.6, 4 / 5 -> 0.8, 3 / 8 -> 0.375}).
- **Answer Rule**: `fraction_to_decimal(a, b)` returning float. Evaluated against `QuestionEvaluator` contract `abs(submission - accepted) <= numeric_tolerance`. (Result Type: `float`)
- **Runtime Input Spec**: `interaction_payload.input_type = "float"`, `answer_spec.accepted_values = [0.375]`, `answer_spec.numeric_tolerance = 0.001`.

#### Template `T_d2_pr_02` (Interaction: `input`, Difficulty: 3)
- **Prompt Pattern**: "Cho biến cố A có xác suất P(A) = a / b. Tính xác suất của biến cố đối P(A_bar) = 1 - P(A). Nhập kết quả dưới dạng phân số tối giản."
- **Parameter Mutations**: a / b in {1 / 6, 1 / 3, 2 / 5, 3 / 8, 5 / 12}.
- **Answer Rule**: `calc_complement_probability(a, b)` returning string "(b - a) / b". (Result Type: `String`)

#### Template `T_d2_pr_03` (Interaction: `drag_drop`, Difficulty: 2)
- **Prompt Pattern**: "Sắp xếp các giá trị xác suất vào các nhóm biểu diễn tương đương ('Dạng phân số', 'Dạng thập phân', 'Dạng phần trăm')."
- **Parameter Mutations**: Matching triplets e.g. (3 / 8, 0.375, 37.5%).

---

### 2.4 Subtopic: `compare_probability`

#### Template `T_d2_cp_01` (Interaction: `multiple_choice`, Difficulty: 2)
- **Prompt Pattern**: "Một túi chứa R bi đỏ, B bi xanh và Y bi vàng cùng kích thước. Rút ngẫu nhiên 1 bi. Biến cố nào có **khả năng xảy ra cao nhất**?"
- **Parameter Mutations**: R=5, B=3, Y=2 (Đỏ cao nhất) or R=2, B=6, Y=2 (Xanh cao nhất).
- **Answer Spec**: `correct_option_id` matching the color with highest probability by `compare_probability`.

#### Template `T_d2_cp_02` (Interaction: `drag_drop`, Difficulty: 3)
- **Prompt Pattern**: "Sắp xếp các biến cố sau theo thứ tự xác suất **tăng dần** (sử dụng so sánh tích chéo left = n_A * n_total_B vs right = n_B * n_total_A)."
- **Parameter Mutations**: 3 events with P(A1) < P(A2) < P(A3).

#### Template `T_d2_cp_03` (Interaction: `matching`, Difficulty: 3)
- **Prompt Pattern**: "Nối biến cố với mô tả khả năng xảy ra tương ứng khi rút 1 bi từ túi chứa 4 bi đỏ và 4 bi xanh cùng kích thước."
- **Parameter Mutations**:
  - Bi đỏ -> "Đồng khả năng với bi xanh"
  - Bi đỏ hoặc xanh -> "Biến cố chắc chắn"
  - Bi vàng -> "Biến cố không thể"

---

### 2.5 Subtopic: `multi_data_classical`

#### Template `T_d2_mdc_01` (Interaction: `input`, Difficulty: 3)
- **Prompt Pattern**: "Một túi chứa R bi đỏ, B bi xanh và Y bi vàng cùng kích thước. Rút ngẫu nhiên 1 bi (sample_space_unit = ball_identity, n(Omega) = R+B+Y). Tính xác suất rút được bi màu $COLOR$. Nhập kết quả dạng phân số tối giản a / b."
- **Parameter Mutations**: R in {3, 4, 5}, B in {3, 4, 5}, Y in {2, 3, 4}.
- **Answer Rule**: `calc_multi_data_prob([R, B, Y], color_idx)` returning simplified fraction string. (Result Type: `String`)

#### Template `T_d2_mdc_02` (Interaction: `input`, Difficulty: 4)
- **Prompt Pattern**: "Một lớp học có M học sinh nam và N học sinh nữ. Chọn ngẫu nhiên 1 học sinh đại diện (sample_space_unit = student_identity, n(Omega) = M+N). Tính xác suất chọn được học sinh nữ. Nhập kết quả dạng phân số tối giản a / b."
- **Parameter Mutations**: M in {12, 15, 18}, N in {12, 15, 20}.
- **Answer Rule**: `calc_classical_probability(N, M+N)` returning simplified fraction string. (Result Type: `String`)

#### Template `T_d2_mdc_03` (Interaction: `matching`, Difficulty: 4)
- **Prompt Pattern**: "BOSS ALEATOR SYNTHESIS: Cho tập hợp N thẻ gồm R thẻ đỏ, B thẻ xanh, Y thẻ vàng. Nối biến cố chọn 1 thẻ với giá trị xác suất P(A) = n(A) / n(Omega) tương ứng."
- **Parameter Mutations**: 3 distinct event probability pairs from multi-group dataset.

---
