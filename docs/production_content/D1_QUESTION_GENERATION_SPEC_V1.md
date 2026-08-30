# DUNGEON 1 QUESTION GENERATION SPEC V1.0

**Document Version**: 1.0.3 (Corrected Round 3)  
**Authority Task ID**: `MATHOS-DIRECT-QGEN-D1-AUTHORITY-001`  
**Dungeon ID**: `dungeon_01`  
**Topic ID**: `trial_sample_event`  

---

## 1. DETERMINISTIC MATERIALIZATION CONTRACT

Every generator template in Dungeon 1 receives a seed integer `seed_val` and deterministic parameters, returning a valid `QuestionDefinition` Dictionary that strictly conforms to `ContentValidator` rules.

---

## 2. GENERATOR TEMPLATE INVENTORY (15 TEMPLATES / EXACTLY 3 PER SUBTOPIC)

### 2.1 Subtopic: `random_trial`

#### Template `T_d1_rt_01` (Interaction: `multiple_choice`, Difficulty: 1)
- **Prompt Pattern**: "Hành động nào sau đây là một phép thử ngẫu nhiên?"
- **Parameter Mutations**:
  - `random_action_set`: [Gieo xúc xắc 6 mặt, Rút 1 lá bài từ bộ 52 lá, Bốc ngẫu nhiên 1 bi từ túi]
  - `deterministic_action_set`: [Đun sôi nước tinh khiết ở 100°C, Thả đá chìm trong nước, Tính 5 x 6 = 30]
- **Deterministic Selection**: Choose 1 random action for `opt_a`, 3 deterministic actions for `opt_b, opt_c, opt_d`.
- **Answer Spec**: `correct_option_id: "opt_a"`.

#### Template `T_d1_rt_02` (Interaction: `matching`, Difficulty: 2)
- **Prompt Pattern**: "Nối phép thử ngẫu nhiên với số kết quả có thể xảy ra tương ứng."
- **Parameter Mutations**:
  - Items: (1 đồng xu -> 2), (1 con xúc xắc 6 mặt -> 6), (Bộ bài N lá -> N).
- **Answer Spec**: Exact 1-to-1 matching pairs array.

#### Template `T_d1_rt_03` (Interaction: `drag_drop`, Difficulty: 2)
- **Prompt Pattern**: "Phân loại các hành động vào nhóm 'Phép thử ngẫu nhiên' hoặc 'Kết quả tất nhiên'."
- **Parameter Mutations**: 2 random actions + 2 deterministic actions.
- **Answer Spec**: `mappings` array mapping each `item_id` to `target_1` or `target_2`.

---

### 2.2 Subtopic: `sample_space`

#### Template `T_d1_ss_01` (Interaction: `multiple_choice`, Difficulty: 1)
- **Prompt Pattern**: "Không gian mẫu Omega của phép thử gieo 1 con xúc xắc N mặt là tập hợp nào?"
- **Parameter Mutations**: N in {4, 6, 8}.
- **Answer Spec**: `correct_option_id` matching {1, 2, ..., N}.

#### Template `T_d1_ss_02` (Interaction: `input`, Difficulty: 2)
- **Prompt Pattern**: "Tính số phần tử của không gian mẫu n(Omega) khi gieo đồng thời k đồng xu cân đối."
- **Parameter Mutations**: k in {1, 2, 3}.
- **Answer Rule**: n(Omega) = 2^k in {2, 4, 8}.
- **Answer Spec**: `accepted_values: [2^k]`. (Result Type: `int`)

#### Template `T_d1_ss_03` (Interaction: `matching`, Difficulty: 2)
- **Prompt Pattern**: "Ghép phép thử ngẫu nhiên với tập hợp không gian mẫu Omega tương ứng."
- **Parameter Mutations**: 3 distinct trial-space pairs.

---

### 2.3 Subtopic: `event_subset`

#### Template `T_d1_es_01` (Interaction: `multiple_choice`, Difficulty: 1)
- **Prompt Pattern**: "Gieo con xúc xắc 6 mặt. Xét biến cố A: 'Số chấm xuất hiện là số TYPE'."
- **Parameter Mutations**: TYPE in {lẻ, chẵn, nguyên tố}.
- **Answer Spec**: `correct_option_id` matching {1,3,5} or {2,4,6} or {2,3,5}.

#### Template `T_d1_es_02` (Interaction: `input`, Difficulty: 2)
- **Prompt Pattern**: "Gieo con xúc xắc 6 mặt. Xét biến cố B: 'Số chấm lớn hơn k'. Số kết quả thuận lợi n(B) bằng bao nhiêu?"
- **Parameter Mutations**: k in {2, 3, 4, 5}.
- **Answer Rule**: n(B) = 6 - k. (Result Type: `int`)

#### Template `T_d1_es_03` (Interaction: `drag_drop`, Difficulty: 2)
- **Prompt Pattern**: "Phân loại các số từ 1 đến N vào biến cố D (D subseteq Omega): 'Số chia hết cho m'."
- **Parameter Mutations**: N = 10, m = 3 -> {3, 6, 9} (n(D) = 3).

---

### 2.4 Subtopic: `event_classification`

#### Template `T_d1_ec_01` (Interaction: `matching`, Difficulty: 2)
- **Prompt Pattern**: "Nối biến cố khi gieo con xúc xắc 6 mặt với tên gọi loại biến cố tương ứng."
- **Parameter Mutations**:
  - `item_l1`: Số chấm <= 6 -> Biến cố chắc chắn (Omega)
  - `item_l2`: Số chấm = 7 -> Biến cố không thể (EmptySet)
  - `item_l3`: Số chấm chia hết 3 -> Biến cố ngẫu nhiên

#### Template `T_d1_ec_02` (Interaction: `multiple_choice`, Difficulty: 1)
- **Prompt Pattern**: "Khi gieo con xúc xắc 6 mặt, biến cố nào sau đây là **biến cố không thể**?"
- **Parameter Mutations**: Option with impossible condition (e.g. số chấm = 0 hoặc 7).

#### Template `T_d1_ec_03` (Interaction: `drag_drop`, Difficulty: 2)
- **Prompt Pattern**: "Sắp xếp các biến cố vào nhóm 'Biến cố chắc chắn' hoặc 'Biến cố không thể'."

---

### 2.5 Subtopic: `counting_outcomes`

#### Template `T_d1_co_01` (Interaction: `input`, Difficulty: 3)
- **Prompt Pattern**: "Gieo 2 con xúc xắc 6 mặt cân đối. Xét biến cố A (A subseteq Omega): 'Tổng số chấm bằng S'. Số kết quả thuận lợi n(A) bằng bao nhiêu?"
- **Parameter Mutations**: S in {3, 4, 5, 6, 7, 8, 9, 10, 11}.
- **Answer Rule**: `count_dice_sum(S)` enumerating ordered pairs (x,y) in {1..6}^2 with x+y=S. (Result Type: `int`)
  - S=3 -> 2
  - S=4 -> 3
  - S=5 -> 4
  - S=6 -> 5
  - S=7 -> 6
  - S=8 -> 5
  - S=9 -> 4
  - S=10 -> 3
  - S=11 -> 2

#### Template `T_d1_co_02` (Interaction: `input`, Difficulty: 3)
- **Prompt Pattern**: "Gieo 3 đồng xu cân đối. Xét biến cố K (K subseteq Omega): 'Có ít nhất k mặt sấp'. Liệt kê và tính số kết quả thuận lợi n(K)."
- **Parameter Mutations**: k=2 -> n(K) = |{SSS, SSN, SNS, NSS}| = 4; k=3 -> n(K) = |{SSS}| = 1.
- **Answer Rule**: Direct sequence listing count from {S, N}^3. (Result Type: `int`)

#### Template `T_d1_co_03` (Interaction: `matching`, Difficulty: 3)
- **Prompt Pattern**: "Cho bình chứa R bi đỏ {R1, ..., RR} và B bi xanh {B1, ..., BB} (R+B <= 5). Rút ngẫu nhiên đồng thời 2 bi (without replacement, unordered pairs). Nối biến cố với số kết quả thuận lợi đếm được bằng liệt kê cặp."
- **Parameter Mutations**:
  - `urn_setup_1`: R=3, B=2 -> Liệt kê cặp đỏ {R1R2, R1R3, R2R3} (3 cặp); cặp xanh {B1B2} (1 cặp).
  - `urn_setup_2`: R=2, B=2 -> Liệt kê cặp đỏ {R1R2} (1 cặp); cặp xanh {B1B2} (1 cặp).
- **Answer Rule**: `count_same_color_pairs_enumeration(R, B)` by explicit element pair listing without combination formulas. (Result Type: `int`)

---
