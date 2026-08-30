# DUNGEON 3 QUESTION GENERATION SPEC V1.0

**Document Version**: 1.0.1 (Corrected Fix 1)  
**Authority Task ID**: `MATHOS-DIRECT-QGEN-D3-AUTHORITY-001`  
**Dungeon ID**: `dungeon_03`  
**Topic ID**: `addition_rule`  

---

## 1. DETERMINISTIC MATERIALIZATION CONTRACT

Every generator template in Dungeon 3 receives a seed integer `seed_val` and deterministic parameters, returning a valid `QuestionDefinition` Dictionary that strictly conforms to `ContentValidator` rules. All generated probabilities must satisfy 0 <= P <= 1 and strictly obey set addition laws.

---

## 2. GENERATOR TEMPLATE INVENTORY (15 TEMPLATES / EXACTLY 3 PER SUBTOPIC)

### 2.1 Subtopic: `union_intersection`

#### Template `T_d3_ui_01` (Interaction: `multiple_choice`, Difficulty: 1)
- **Prompt Pattern**: "Phát biểu nào sau đây đúng nhất về biến cố hợp A u B?"
- **Parameter Mutations**:
  - `correct_stmt`: "Biến cố A u B xảy ra khi có ít nhất một trong hai biến cố A hoặc B xảy ra"
  - `distractors`: [
      "Biến cố A u B xảy ra khi cả hai biến cố A và B đồng thời xảy ra",
      "Biến cố A u B xảy ra khi biến cố A xảy ra nhưng B không xảy ra",
      "Biến cố A u B xảy ra khi cả A và B đều không xảy ra"
    ]
- **Answer Spec**: `correct_option_id: "opt_a"`.

#### Template `T_d3_ui_02` (Interaction: `input`, Difficulty: 2)
- **Prompt Pattern**: "Cho hai tập hợp biến cố A có n(A) = N1 phần tử, B có n(B) = N2 phần tử và phần giao A n B có n(A n B) = N12 phần tử. Tính số phần tử của biến cố hợp n(A u B) = n(A) + n(B) - n(A n B)."
- **Parameter Mutations**: N1 in {10..20}, N2 in {8..15}, N12 in {3..7}.
- **Answer Rule**: `calc_n_union(N1, N2, N12)` returning integer. (Result Type: `int`)
- **Runtime Input Spec**: `interaction_payload.input_type = "integer"`, `answer_spec.accepted_values = [N1 + N2 - N12]`.

#### Template `T_d3_ui_03` (Interaction: `matching`, Difficulty: 2)
- **Prompt Pattern**: "Nối phát biểu mô tả bằng lời với ký hiệu tập hợp biến cố tương ứng."
- **Parameter Mutations**:
  - "Biến cố A hoặc B xảy ra" -> A u B
  - "Cả hai biến cố A và B cùng xảy ra" -> A n B
  - "Biến cố A là tập con của không gian mẫu" -> A <= Omega
- **Note**: Notation is strictly limited to A u B, A n B, and A <= Omega. Complement notation A_bar is excluded from Subtopic 3.1.

---

### 2.2 Subtopic: `mutually_exclusive`

#### Template `T_d3_me_01` (Interaction: `multiple_choice`, Difficulty: 1)
- **Prompt Pattern**: "Hai biến cố A và B được gọi là **xung khắc** khi và chỉ khi điều kiện nào sau đây thỏa mãn?"
- **Parameter Mutations**:
  - `correct_option`: "A n B = EmptySet (không thể cùng xảy ra)"
  - `distractor_options`: ["A u B = EmptySet", "P(A) = P(B)", "A u B = Omega (mọi trường hợp)"]
- **Note**: Distractors test D3-native misconceptions ONLY. D4 multiplication formulas are strictly excluded.
- **Answer Spec**: `correct_option_id: "opt_a"`.

#### Template `T_d3_me_02` (Interaction: `input`, Difficulty: 2)
- **Prompt Pattern**: "Cho xác suất của biến cố A là P(A) = p_val. Tính xác suất của biến cố đối P(A_bar) = 1 - P(A)."
- **Parameter Mutations**: p_val in {0.1, 0.2, 0.25, 0.3, 0.4, 0.6, 0.75, 0.85}.
- **Answer Rule**: `calc_complement_prob_decimal(p_val)` returning float. (Result Type: `float`)
- **Runtime Input Spec**: `interaction_payload.input_type = "float"`, `answer_spec.accepted_values = [round(1.0 - p_val, 3)]`, `answer_spec.numeric_tolerance = 0.001`.

#### Template `T_d3_me_03` (Interaction: `drag_drop`, Difficulty: 2)
- **Prompt Pattern**: "Phân loại các cặp biến cố khi gieo 1 con xúc xắc 6 mặt vào nhóm 'Xung khắc' hoặc 'Không xung khắc'."
- **Parameter Mutations**:
  - Pair 1: "Mặt chẵn" & "Mặt lẻ" -> Xung khắc
  - Pair 2: "Mặt chẵn" & "Mặt > 4" -> Không xung khắc (chung mặt 6)

---

### 2.3 Subtopic: `addition_simple`

#### Template `T_d3_as_01` (Interaction: `multiple_choice`, Difficulty: 2)
- **Prompt Pattern**: "Cho hai biến cố xung khắc A và B có P(A) = pA và P(B) = pB. Tính xác suất để A hoặc B xảy ra P(A u B) = P(A) + P(B)."
- **Parameter Mutations**: pA in {0.1, 0.2, 0.3}, pB in {0.3, 0.4, 0.5}.
- **Distractor Mutations**: [pA - pB, 1.0 - (pA + pB), pA + pB + 0.1] (D3-native only).
- **Answer Spec**: `correct_option_id` matching float `pA + pB`.

#### Template `T_d3_as_02` (Interaction: `input`, Difficulty: 3)
- **Prompt Pattern**: "Rút 1 lá bài từ bộ bài 52 lá cân đối. Xác suất rút được lá K là 4 / 52, lá Q là 4 / 52. Tính xác suất P(King or Queen) = 4 / 52 + 4 / 52 = 8 / 52 = 2 / 13 để rút được lá K hoặc lá Q. Nhập kết quả dưới dạng phân số tối giản a / b."
- **Parameter Mutations**: K or Q -> 8 / 52 = 2 / 13; J or 10 -> 2 / 13; Ace or King -> 2 / 13.
- **Answer Rule**: `calc_simple_addition_fraction(4, 4, 52)` returning simplified fraction string "2 / 13". (Result Type: `String`)
- **Runtime Input Spec**: `interaction_payload.input_type = "string"`, `answer_spec.accepted_values = ["2 / 13"]`, `answer_spec.trim_whitespace = true`.

#### Template `T_d3_as_03` (Interaction: `matching`, Difficulty: 3)
- **Prompt Pattern**: "Một xạ thủ bắn vào bia. Nối các điểm số với xác suất đạt được ít nhất k điểm bằng quy tắc cộng xung khắc."
- **Parameter Mutations**: P(10)=0.2, P(9)=0.35, P(8)=0.25 -> P(>=9) = 0.55, P(>=8) = 0.8.

---

### 2.4 Subtopic: `addition_general`

#### Template `T_d3_ag_01` (Interaction: `input`, Difficulty: 2)
- **Prompt Pattern**: "Cho hai biến cố A và B có P(A) = pA, P(B) = pB và P(A n B) = pAB. Tính xác suất P(A u B) = P(A) + P(B) - P(A n B)."
- **Parameter Mutations**: pA in {0.5, 0.6, 0.7}, pB in {0.4, 0.5}, pAB in {0.2, 0.3}.
- **Answer Rule**: `calc_general_addition_prob(pA, pB, pAB)` returning float `pA + pB - pAB`. (Result Type: `float`)
- **Runtime Input Spec**: `interaction_payload.input_type = "float"`, `answer_spec.accepted_values = [pA + pB - pAB]`, `answer_spec.numeric_tolerance = 0.001`.

#### Template `T_d3_ag_02` (Interaction: `multiple_choice`, Difficulty: 3)
- **Prompt Pattern**: "Rút 1 lá bài từ bộ bài 52 lá. Tính xác suất P(Red or King) = (26 + 4 - 2) / 52 = 28 / 52 = 7 / 13 rút được lá bài màu Đỏ (26 lá) hoặc lá bài hình quân K (4 lá, có 2 lá K đỏ). Giá trị P(A u B) bằng bao nhiêu?"
- **Parameter Mutations**: P(Red or King) = 7 / 13.
- **Answer Spec**: `correct_option_id` matching fraction "7 / 13".

#### Template `T_d3_ag_03` (Interaction: `drag_drop`, Difficulty: 3)
- **Prompt Pattern**: "Phân loại các phép tính xác suất đúng theo quy tắc cộng tổng quát P(A u B) = P(A) + P(B) - P(A n B)."
- **Parameter Mutations**: 2 correct general addition formulas + 2 incorrect formulas (bỏ sót P(A n B) e.g. P(A) + P(B), hoặc cộng nhầm P(A) + P(B) + P(A n B)).

---

### 2.5 Subtopic: `addition_selection`

#### Template `T_d3_asl_01` (Interaction: `input`, Difficulty: 3)
- **Prompt Pattern**: "Gieo 1 con xúc xắc 6 mặt cân đối. Xét biến cố A: 'Số chấm chia hết cho 3' ({3,6}) và B: 'Số chấm là số chẵn' ({2,4,6}). Tính xác suất P(A u B) = P(A) + P(B) - P(A n B). Nhập kết quả dưới dạng phân số tối giản a / b."
- **Parameter Mutations**: n(A)=2, n(B)=3, n(A n B)=1 -> n(A u B) = 4 -> P = 4 / 6 = 2 / 3.
- **Answer Rule**: Simplified fraction string "2 / 3". (Result Type: `String`)

#### Template `T_d3_asl_02` (Interaction: `input`, Difficulty: 4)
- **Prompt Pattern**: "Một lớp có N40 = 40 học sinh, có N_math = 20 em giỏi Toán, N_eng = 15 em giỏi Anh và N_both = 5 em giỏi cả hai môn. Chọn ngẫu nhiên 1 học sinh. Tính xác suất P(Math or English) = (20 + 15 - 5) / 40 = 30 / 40 = 3 / 4 = 0.75."
- **Parameter Mutations**: N40 = 40, N_math = 20, N_eng = 15, N_both = 5 -> P = 0.75.
- **Answer Rule**: Float `0.75`. Evaluated against `QuestionEvaluator` contract `abs(submission - accepted) <= numeric_tolerance`. (Result Type: `float`)
- **Runtime Input Spec**: `interaction_payload.input_type = "float"`, `answer_spec.accepted_values = [0.75]`, `answer_spec.numeric_tolerance = 0.001`.

#### Template `T_d3_asl_03` (Interaction: `matching`, Difficulty: 5)
- **Prompt Pattern**: "BOSS MELKOR SYNTHESIS: Gieo 2 con xúc xắc 6 mặt cân đối (n(Omega) = 36). Cho biến cố A: 'Tổng số chấm là số lẻ' (n(A) = 18), B: 'Tích hai số chấm chia hết cho 5' (n(B) = 11, với n(A n B) = 6). Nối các biến cố với giá trị số phần tử đếm được bằng quy tắc cộng n(A u B) = n(A) + n(B) - n(A n B)."
- **Parameter Mutations**: n(A u B) = 18 + 11 - 6 = 23 -> P(A u B) = 23 / 36. Zero combination formulas required.

---
