# DUNGEON 4 QUESTION GENERATION SPEC V1.0

**Document Version**: 1.0.1 (Corrected Fix 1)  
**Authority Task ID**: `MATHOS-DIRECT-QGEN-D4-AUTHORITY-001`  
**Dungeon ID**: `dungeon_04`  
**Topic ID**: `multiplication_independence`  

---

## 1. DETERMINISTIC MATERIALIZATION CONTRACT

Every generator template in Dungeon 4 receives a seed integer `seed_val` and deterministic parameters, returning a valid `QuestionDefinition` Dictionary that strictly conforms to `ContentValidator` rules. All generated probabilities must satisfy 0 <= P <= 1 and strictly obey independent multiplication laws.

---

## 2. GENERATOR TEMPLATE INVENTORY (15 TEMPLATES / EXACTLY 3 PER SUBTOPIC)

### 2.1 Subtopic: `independence`

#### Template `T_d4_ind_01` (Interaction: `multiple_choice`, Difficulty: 1)
- **Prompt Pattern**: "Cặp biến cố nào sau đây là hai biến cố **độc lập**?"
- **Parameter Mutations**:
  - `correct_pair`: "Gieo 1 con xúc xắc 6 mặt và gieo 1 đồng xu cân đối độc lập (is_independent = true)"
  - `distractor_pairs`: [
      "Rút 2 bi liên tiếp không hoàn lại từ túi bi (is_independent = false)",
      "Rút 2 lá bài liên tiếp không hoàn lại từ bộ bài 52 lá (is_independent = false)",
      "Chọn 2 học sinh liên tiếp từ danh sách lớp không hoàn lại (is_independent = false)"
    ]
- **Answer Spec**: `correct_option_id: "opt_a"`.

#### Template `T_d4_ind_02` (Interaction: `matching`, Difficulty: 2)
- **Prompt Pattern**: "Nối mô tả tình huống với tính chất độc lập hay phụ thuộc tương ứng."
- **Parameter Mutations**:
  - "Hai xạ thủ bắn độc lập vào 1 mục tiêu" -> Hai biến cố độc lập
  - "Rút 2 bi liên tiếp không hoàn lại" -> Hai biến cố phụ thuộc
  - "Gieo 2 đồng xu cân đối riêng biệt" -> Hai biến cố độc lập

#### Template `T_d4_ind_03` (Interaction: `drag_drop`, Difficulty: 2)
- **Prompt Pattern**: "Phân loại các tình huống vào nhóm 'Hai biến cố độc lập' hoặc 'Hai biến cố phụ thuộc'."
- **Parameter Mutations**: 2 independent scenarios + 2 dependent scenarios (without replacement).

---

### 2.2 Subtopic: `tree_diagram`

#### Template `T_d4_td_01` (Interaction: `multiple_choice`, Difficulty: 2)
- **Prompt Pattern**: "Khi gieo k đồng xu cân đối độc lập liên tiếp, số kết quả sơ cấp của không gian mẫu n(Omega) = 2^k bằng bao nhiêu?"
- **Parameter Mutations**: k in {2 -> 2^2 = 4, 3 -> 2^3 = 8}.
- **Distractor Mutations**: [2 * k (sai lầm nhân thay vì lũy thừa), 2^k + 1, 2^k - 1].
- **Answer Spec**: `correct_option_id` matching integer `2^k`.

#### Template `T_d4_td_02` (Interaction: `input`, Difficulty: 3)
- **Prompt Pattern**: "Cho 2 xạ thủ độc lập cùng bắn vào mục tiêu. Xạ thủ 1 bắn trúng với xác suất p1, xạ thủ 2 bắn trúng với xác suất p2. Tính xác suất P(cả 2 xạ thủ cùng bắn trượt) = (1 - p1) * (1 - p2)."
- **Parameter Mutations**: p1 in {0.6, 0.7, 0.8}, p2 in {0.5, 0.7, 0.8}. (e.g. p1=0.7, p2=0.8 -> (1-0.7)*(1-0.8) = 0.3 * 0.2 = 0.06).
- **Answer Rule**: `calc_both_miss_prob(p1, p2)` returning float. (Result Type: `float`)
- **Runtime Input Spec**: `interaction_payload.input_type = "float"`, `answer_spec.accepted_values = [(1.0 - p1)*(1.0 - p2)]`, `answer_spec.numeric_tolerance = 0.001`.

#### Template `T_d4_td_03` (Interaction: `matching`, Difficulty: 3)
- **Prompt Pattern**: "Gieo 1 đồng xu cân đối 3 lần liên tiếp độc lập (n(Omega) = 2^3 = 8). Nối biến cố với giá trị xác suất tương ứng."
- **Parameter Mutations**:
  - "Cả 3 lần cùng sấp" -> 1 / 8 = 0.125
  - "Có ít nhất 1 lần sấp" -> 7 / 8 = 0.875
  - "Lần 1 sấp, lần 2 ngửa, lần 3 sấp" -> 1 / 8 = 0.125

---

### 2.3 Subtopic: `multiplication_two_step`

#### Template `T_d4_m2s_01` (Interaction: `input`, Difficulty: 2)
- **Prompt Pattern**: "Cho hai biến cố độc lập A và B có P(A) = pA và P(B) = pB. Tính xác suất P(A n B) = P(A) * P(B)."
- **Parameter Mutations**: pA in {0.4, 0.5, 0.6}, pB in {0.5, 0.6, 0.8}. (e.g. pA=0.4, pB=0.5 -> 0.4 * 0.5 = 0.2).
- **Answer Rule**: `calc_two_step_mult_prob(pA, pB)` returning float `pA * pB`. (Result Type: `float`)
- **Runtime Input Spec**: `interaction_payload.input_type = "float"`, `answer_spec.accepted_values = [pA * pB]`, `answer_spec.numeric_tolerance = 0.001`.

#### Template `T_d4_m2s_02` (Interaction: `input`, Difficulty: 3)
- **Prompt Pattern**: "Hai học sinh An và Bình cùng làm bài thi độc lập. Xác suất An làm đúng là p_an, Bình làm đúng là p_binh. Tính xác suất P(cả 2 em cùng làm đúng) = p_an * p_binh."
- **Parameter Mutations**: p_an in {0.7, 0.8}, p_binh in {0.8, 0.9}. (e.g. p_an=0.8, p_binh=0.9 -> 0.8 * 0.9 = 0.72).
- **Answer Rule**: Float `p_an * p_binh`. (Result Type: `float`)

#### Template `T_d4_m2s_03` (Interaction: `matching`, Difficulty: 3)
- **Prompt Pattern**: "Nối cặp xác suất P(A) và P(B) của hai biến cố độc lập với xác suất giao P(A n B) = P(A) * P(B) tương ứng."
- **Parameter Mutations**: (0.5 & 0.6 -> 0.3), (0.4 & 0.5 -> 0.2), (0.7 & 0.8 -> 0.56).

---

### 2.4 Subtopic: `multiplication_chain`

#### Template `T_d4_mc_01` (Interaction: `input`, Difficulty: 3)
- **Prompt Pattern**: "Gieo 3 con xúc xắc 6 mặt cân đối độc lập. Tính xác suất P = 1 / b = (1 / 6)^3 = 1 / 216 để cả 3 con xúc xắc cùng xuất hiện mặt 6 chấm. Nhập mẫu số b của phân số 1 / b."
- **Parameter Mutations**: P = (1 / 6)^3 = 1 / 216 -> b = 216.
- **Answer Rule**: Integer `216`. (Result Type: `int`)
- **Runtime Input Spec**: `interaction_payload.input_type = "integer"`, `answer_spec.accepted_values = [216]`.

#### Template `T_d4_mc_02` (Interaction: `input`, Difficulty: 4)
- **Prompt Pattern**: "Một hệ thống gồm 2 linh kiện mắc song song hoạt động độc lập. Hệ thống hoạt động tốt khi có ít nhất 1 linh kiện hoạt động. Xác suất hỏng của linh kiện 1 là p1, linh kiện 2 là p2. Tính xác suất P(hệ thống hoạt động tốt) = 1 - p1 * p2."
- **Parameter Mutations**: p1=0.1, p2=0.2 -> P = 1 - 0.1 * 0.2 = 0.98; p1=0.2, p2=0.2 -> P = 1 - 0.04 = 0.96.
- **Answer Rule**: Float `1.0 - p1 * p2`. (Result Type: `float`)

#### Template `T_d4_mc_03` (Interaction: `multiple_choice`, Difficulty: 4)
- **Prompt Pattern**: "Ba người A, B, C cùng làm bài thi độc lập. Xác suất làm đúng của A là 0.7, B là 0.8, C là 0.9. Giá trị P(cả 3 người cùng làm đúng) = 0.7 * 0.8 * 0.9 bằng bao nhiêu?"
- **Parameter Mutations**: 0.7 * 0.8 * 0.9 = 0.504.
- **Answer Spec**: `correct_option_id` matching float `0.504`.

---

### 2.5 Subtopic: `independence_application`

#### Template `T_d4_ia_01` (Interaction: `input`, Difficulty: 4)
- **Prompt Pattern**: "Gieo 2 con xúc xắc 6 mặt cân đối độc lập. Tính xác suất để con thứ nhất xuất hiện mặt chẵn (3 / 6) VÀ con thứ hai xuất hiện mặt chia hết cho 3 (2 / 6). Nhập kết quả dạng phân số tối giản a / b."
- **Parameter Mutations**: P = (3 / 6) * (2 / 6) = (1 / 2) * (1 / 3) = 1 / 6.
- **Answer Rule**: Simplified fraction string "1 / 6". (Result Type: `String`)

#### Template `T_d4_ia_02` (Interaction: `input`, Difficulty: 5)
- **Prompt Pattern**: "Hai xạ thủ độc lập cùng bắn vào 1 mục tiêu. Xác suất trúng của người 1 là p1 = 0.8, người 2 là p2 = 0.7. Tính xác suất P(đúng 1 người bắn trúng) = p1 * (1 - p2) + (1 - p1) * p2."
- **Parameter Mutations**: p1=0.8, p2=0.7 -> P = 0.8 * 0.3 + 0.2 * 0.7 = 0.24 + 0.14 = 0.38.
- **Answer Rule**: Float `0.38`. (Result Type: `float`)
- **Runtime Input Spec**: `interaction_payload.input_type = "float"`, `answer_spec.accepted_values = [0.38]`, `answer_spec.numeric_tolerance = 0.001`.

#### Template `T_d4_ia_03` (Interaction: `input`, Difficulty: 5)
- **Prompt Pattern**: "BOSS APHODIUS TUYỆT CHIÊU: Ba xạ thủ độc lập cùng bắn vào mục tiêu với xác suất trúng lần lượt là p1 = 0.6, p2 = 0.7, p3 = 0.8. Tính xác suất P(mục tiêu bị trúng đạn) = 1 - (1 - p1) * (1 - p2) * (1 - p3)."
- **Parameter Mutations**: p1=0.6, p2=0.7, p3=0.8 -> P = 1 - 0.4 * 0.3 * 0.2 = 1 - 0.024 = 0.976.
- **Answer Rule**: Float `0.976`. (Result Type: `float`)

---
