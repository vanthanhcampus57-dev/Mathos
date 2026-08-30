# DUNGEON 2 MATH KNOWLEDGE PACK MASTER V1.0

**Document Version**: 1.0.3 (Corrected Round 3)  
**Authority Task ID**: `MATHOS-DIRECT-QGEN-D2-AUTHORITY-001`  
**Dungeon ID**: `dungeon_02`  
**Topic ID**: `classical_probability`  
**Canonical Subtopics**: `equally_likely`, `classical_probability_formula`, `probability_representation`, `compare_probability`, `multi_data_classical`  
**Target Domain**: High School Probability & Statistics (Grade 10/11 - Chương Trình GDPT Việt Nam)  

---

## 1. GLOBAL PEDAGOGICAL & BOUNDARY GUARDRAILS

- **Classical Probability Validity Scope**: The classical probability formula P(A) = n(A) / n(Omega) is valid IF AND ONLY IF the sample space Omega consists of a finite number of elementary outcomes (n(Omega) > 0) AND all elementary outcomes in Omega are equally likely (đồng khả năng / đồng chất / cân đối).
- **Elementary Outcome Granularity (`sample_space_unit`)**:
  - Coin flip: `sample_space_unit = "coin_face"` ({S, N}, 2 elementary outcomes, P(S) = P(N) = 1 / 2 for a balanced coin).
  - Die roll: `sample_space_unit = "die_face"` ({1, 2, 3, 4, 5, 6}, 6 elementary outcomes, P(i) = 1 / 6 for a balanced die).
  - Card draw: `sample_space_unit = "card_identity"` ({C_1, C_2, ..., C_N}, N elementary outcomes, P(C_i) = 1 / N).
  - Ball draw: `sample_space_unit = "ball_identity"` ({b_1, b_2, ..., b_N}, N elementary outcomes, P(b_i) = 1 / N for uniform balls).
  - **CRITICAL BALL BAG SEMANTICS**: In a bag containing 5 red balls and 3 blue balls of identical size and mass:
    - The 8 individual balls {b_1, ..., b_8} are the **equally likely elementary outcomes** (P(b_i) = 1 / 8 for each ball).
    - Unequal color counts (5 red vs 3 blue) do NOT make elementary outcomes unequal!
    - Color categories {red, blue} are **compound events**, with probabilities P(red) = 5 / 8 and P(blue) = 3 / 8.
- **Strict Adherence to Curriculum Authority (No Invented Biased Mechanisms)**:
  - All authorized D2 physical mechanisms are symmetric and balanced: "gieo đồng xu cân đối", "gieo xúc xắc 6 mặt cân đối", "rút thẻ từ 1..N", "bốc bi từ túi chứa bi cùng kích thước", "chọn học sinh đại diện".
  - Invalid applications of the classical formula are tested exclusively via non-equally-likely event scenarios (e.g. generic non-equally-likely events, or mistakenly treating compound color categories as elementary outcomes). No unauthorized weighted dice or biased coin physical mechanisms are invented.
- **Rational Authority & Float Precision Contract**:
  - Rational probability P(A) = a / b is mathematically exact.
  - When expressed as decimal or percentage float values (e.g. 1 / 4 -> 0.25 -> 25.0%, 3 / 8 -> 0.375 -> 37.5%), float values are evaluated using the existing `QuestionEvaluator` contract (`abs(submission - accepted) <= numeric_tolerance`).
  - Integer rounding is prohibited. 3 / 8 evaluates to 37.5% float with `numeric_tolerance: 0.001` (zero rounding to 38).
- **Strict Probability Value Range**: 0 <= P(A) <= 1 for all events. P(EmptySet) = 0, P(Omega) = 1.
- **Sample Space Size Bounds**: n(Omega) <= 36 for multi-step listing experiments (dice, coins); n(Omega) <= 100 for single-step uniform selection from discrete sets (balls, cards, students).
- **Allowed Complementary Probability**: P(A_bar) = 1 - P(A) is allowed in D2 as a direct ratio identity since n(A_bar) = n(Omega) - n(A).
- **No D3 Addition Rule Leakage**: No P(A u B) = P(A) + P(B) or inclusion-exclusion probability formulas.
- **No D4 Multiplication Rule Leakage**: No P(A n B) = P(A) * P(B) or independence formulas.
- **No Conditional Probability**: No P(A|B) or multi-stage tree probability multiplication.

---

## 2. SUBTOPIC 2.1: `equally_likely` (Kết Quả Đồng Khả Năng)

### 2.1 Canonical Knowledge & Definitions
- **Kết Quả Đồng Khả Năng**: Các kết quả sơ cấp của phép thử ngẫu nhiên được gọi là đồng khả năng nếu không có lý do gì để tin rằng kết quả này có khả năng xuất hiện cao hơn kết quả khác.
- **Điều Kiện Phép Thử Hợp Lệ**: Gieo xúc xắc 6 mặt cân đối, gieo đồng xu cân đối, bốc bi từ túi chứa bi có cùng kích thước và khối lượng.
- **Ứng Dụng Không Hợp Lệ Của Công Thức Cổ Điển**: Áp dụng công thức cổ điển vào các sự kiện chưa được xác định là đồng khả năng hoặc nhầm lẫn tập danh mục phân loại là các kết quả sơ cấp.

### 2.2 Allowed Concepts & Terminology
- Đồng khả năng, kết quả sơ cấp, cân đối, đồng chất, kích thước như nhau, phạm vi áp dụng công thức cổ điển.

### 2.3 Forbidden Concepts (Anti-Leakage)
- Quy tắc cộng/nhân xác suất, xác suất thực nghiệm/tần suất, biến cố độc lập D4, sáng tạo thêm cơ chế vật lý lệch không có trong chương trình.

### 2.4 Common Misconceptions & Distractor Logic
- `MISC_EL_01`: Giả định sai lầm rằng mọi thí nghiệm có 2 khả năng đều có các kết quả sơ cấp đồng khả năng khi chưa được xác định điều kiện đồng chất/cân đối.
- `MISC_EL_02`: Nhầm lẫn giữa "danh mục màu sắc {đỏ, xanh}" là kết quả sơ cấp khi số lượng bi đỏ và bi xanh khác nhau.

### 2.5 Difficulty Guidance
- **Difficulty 1**: Nhận biết phép thử có các kết quả sơ cấp đồng khả năng (1 đồng xu cân đối, 1 xúc xắc 6 mặt cân đối).
- **Difficulty 2**: Phân biệt tình huống áp dụng hợp lệ công thức cổ điển vs áp dụng không hợp lệ.
- **Difficulty 3**: Xác định số kết quả sơ cấp đồng khả năng n(Omega) cho phép thử cân đối.

### 2.6 Parameter Domains & Mutation Boundaries
- `experiment_scenario`:
  - Valid Classical (is_valid_classical = true): ["gieo 1 con xúc xắc 6 mặt cân đối", "gieo 1 đồng xu cân đối", "bốc 1 quả cầu từ túi chứa các quả cầu cùng kích thước"]
  - Invalid Classical (is_valid_classical = false): ["thí nghiệm có 2 kết quả nhưng chưa được xác định các kết quả sơ cấp đồng khả năng", "coi danh mục các nhóm là các kết quả sơ cấp khi số lượng phần tử mỗi nhóm khác nhau"]

### 2.7 Seed Families & Reference Mappings
- `q_d2_01_1` (MC), `q_d2_01_2` (DragDrop), `q_d2_01_3` (Matching), `q_d2_01_4` (MC), `q_d2_01_5` (Input).

### 2.8 Deterministic Answer Rules
- `is_valid_classical_formula(experiment_scenario)`: `true` if scenario has balanced elementary outcomes; `false` if applied to non-equally-likely events. (Result Type: `bool`)

### 2.9 Legal Interaction Types
- `multiple_choice`, `drag_drop`, `matching`, `input`.

---

## 3. SUBTOPIC 2.2: `classical_probability_formula` (Công Thức Xác Suất Cổ Điển)

### 3.1 Canonical Knowledge & Definitions
- **Công Thức Xác Suất Cổ Điển**: Cho phép thử ngẫu nhiên có không gian mẫu Omega gồm n(Omega) kết quả sơ cấp đồng khả năng. Xác suất của biến cố A (A <= Omega) là: P(A) = n(A) / n(Omega).
- **Giá Trị Đặc Biệt**: P(EmptySet) = 0 / n(Omega) = 0, P(Omega) = n(Omega) / n(Omega) = 1. Với mọi biến cố A: 0 <= P(A) <= 1.

### 3.2 Allowed Concepts & Terminology
- P(A), n(A), n(Omega), số kết quả thuận lợi, tổng số kết quả sơ cấp đồng khả năng, phân số tối giản a / b.

### 3.3 Forbidden Concepts (Anti-Leakage)
- Công thức cộng P(A u B), công thức nhân P(A n B), biến cố độc lập, tổ hợp C_n^k.

### 3.4 Common Misconceptions & Distractor Logic
- `MISC_CPF_01`: Lật ngược phân số thành n(Omega) / n(A) (ví dụ: tính P(A) = 6 / 3 = 2 > 1).
- `MISC_CPF_02`: Nhầm n(A) là số kết quả không thuận lợi (n(Omega) - n(A)).

### 3.5 Difficulty Guidance
- **Difficulty 1**: Nhận biết công thức P(A) = n(A) / n(Omega) và tính P(A) cho gieo 1 xúc xắc (n(Omega) = 6).
- **Difficulty 2**: Tính P(A) dưới dạng phân số tối giản cho rút thẻ 1..N hoặc bốc bi từ túi.
- **Difficulty 3**: Tính P(A) cho gieo 2 đồng xu (n(Omega) = 4) hoặc gieo 1 xúc xắc với điều kiện số học.

### 3.6 Parameter Domains & Mutation Boundaries
- `dice_roll`: n(Omega) = 6. Events: odd (n=3 -> P = 3 / 6 = 1 / 2), even (n=3 -> P = 3 / 6 = 1 / 2), prime (n=3 -> P = 3 / 6 = 1 / 2), gt_4 (n=2 -> P = 2 / 6 = 1 / 3).
- `card_deck`: N in {10, 12, 20}. Events: divisible_by_k, prime_cards.
- `ball_bag`: R red, B blue balls of identical size (R+B <= 20). P(red) = R / (R + B).

### 3.7 Seed Families & Reference Mappings
- `q_d2_02_1` (MC), `q_d2_02_2` (Input), `q_d2_02_3` (Matching), `q_d2_02_4` (Input), `q_d2_02_5` (MC).

### 3.8 Deterministic Answer Rules & Input Contract Compatibility
- `calc_classical_probability(n_fav, n_total)`:
  - Validate: 0 <= n_fav <= n_total, n_total > 0.
  - Simplify fraction: g = gcd(n_fav, n_total) -> numerator = n_fav / g, denominator = n_total / g.
  - Return String "numerator / denominator" (e.g. "1 / 2"). (Result Type: `String`)
- **Runtime Input Compatibility**:
  - Fraction string input: `interaction_payload.input_type = "string"` (or `"symbol"`), `answer_spec.accepted_values = ["1 / 2"]`, `answer_spec.trim_whitespace = true`.
  - Numeric decimal float input: `interaction_payload.input_type = "float"`, `answer_spec.accepted_values = [0.5]`, `answer_spec.numeric_tolerance = 0.01`.
  - Integer count input: `interaction_payload.input_type = "integer"`, `answer_spec.accepted_values = [3]`.

### 3.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---

## 4. SUBTOPIC 2.3: `probability_representation` (Biểu Diễn Xác Suất & Biến Cố Đối)

### 4.1 Canonical Knowledge & Definitions
- **Các Dạng Biểu Diễn Xác Suất**: Phân số tối giản (a / b), số thập phân (0.xx), phần trăm (xx%).
- **Chuyển Đổi Chính Xác**:
  - 1 / 2 = 0.5 = 50%
  - 1 / 4 = 0.25 = 25%
  - 3 / 4 = 0.75 = 75%
  - 1 / 5 = 0.2 = 20%
  - 2 / 5 = 0.4 = 40%
  - 3 / 5 = 0.6 = 60%
  - 4 / 5 = 0.8 = 80%
  - 1 / 8 = 0.125 = 12.5%
  - 3 / 8 = 0.375 = 37.5% (Chính xác float 37.5 với numeric_tolerance = 0.001, KHÔNG làm tròn thành 38)
  - 1 / 10 = 0.1 = 10%
- **Biến Cố Đối (A_bar)**: Biến cố "A không xảy ra". n(A_bar) = n(Omega) - n(A).
- **Công Thức Biến Cố Đối**: P(A_bar) = 1 - P(A).

### 4.2 Allowed Concepts & Terminology
- Biểu diễn xác suất, số thập phân, phần trăm %, biến cố đối A_bar, 1 - P(A).

### 4.3 Forbidden Concepts (Anti-Leakage)
- Quy tắc cộng cho 2 biến cố bất kỳ A, B (chỉ dùng mối quan hệ A và A_bar), quy tắc nhân D4.

### 4.4 Common Misconceptions & Distractor Logic
- `MISC_PR_01`: Chuyển đổi sai giữa phân số và phần trăm (ví dụ: 1 / 4 = 0.25 = 2.5% thay vì 25%).
- `MISC_PR_02`: Quên trừ khỏi 1 khi tính biến cố đối (cho rằng P(A_bar) = P(A)).

### 4.5 Difficulty Guidance
- **Difficulty 2**: Đổi phân số xác suất đơn giản sang số thập phân (1 / 2 = 0.5, 1 / 4 = 0.25, 3 / 4 = 0.75, 1 / 5 = 0.2).
- **Difficulty 3**: Tính P(A_bar) khi biết P(A).
- **Difficulty 4**: Chuyển đổi qua lại giữa phân số, số thập phân và phần trăm cho bài toán thực tế (bao gồm 3 / 8 = 37.5%).

### 4.6 Parameter Domains & Mutation Boundaries
- `probability_fractions`: {1 / 2, 1 / 4, 3 / 4, 1 / 5, 2 / 5, 3 / 5, 4 / 5, 1 / 8, 3 / 8, 1 / 10, 3 / 10, 7 / 10, 9 / 10}.
- `decimals`: {0.5, 0.25, 0.75, 0.2, 0.4, 0.6, 0.8, 0.125, 0.375, 0.1, 0.3, 0.7, 0.9}.
- `percentages`: {50.0, 25.0, 75.0, 20.0, 40.0, 60.0, 80.0, 12.5, 37.5, 10.0, 30.0, 70.0, 90.0}.

### 4.7 Seed Families & Reference Mappings
- `q_d2_03_1` (MC), `q_d2_03_2` (Input), `q_d2_03_3` (Matching), `q_d2_03_4` (DragDrop), `q_d2_03_5` (Input).

### 4.8 Deterministic Answer Rules
- `calc_complement_probability(p_num, p_den)`: Returns string "(p_den - p_num) / p_den" simplified. (Result Type: `String`)
- `fraction_to_decimal(a, b)`: Returns float `round(a / b, 3)` evaluated with `numeric_tolerance: 0.001`. (Result Type: `float`)
- `fraction_to_percent(a, b)`: Returns float `(a / b) * 100.0` evaluated with `numeric_tolerance: 0.01` (e.g. 3 / 8 -> 37.5 float). (Result Type: `float`)

### 4.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---

## 5. SUBTOPIC 2.4: `compare_probability` (So Sánh Xác Suất Các Biến Cố)

### 5.1 Canonical Knowledge & Definitions
- **So Sánh Xác Suất Chính Xác qua Tích Chéo**: Cho 2 biến cố A (trong mẫu Omega_A có n(A) / n(Omega_A)) và B (trong mẫu Omega_B có n(B) / n(Omega_B)).
  - Tính `left = n(A) * n(Omega_B)` và `right = n(B) * n(Omega_A)`.
  - If `left > right` -> P(A) > P(B) ("lớn hơn" / "khả năng cao hơn").
  - If `left < right` -> P(A) < P(B) ("nhỏ hơn" / "khả năng thấp hơn").
  - If `left == right` -> P(A) == P(B) ("bằng nhau" / "khả năng như nhau").
- Nghiêm cấm so sánh chỉ số kết quả thuận lợi n(A) và n(B) khi không gian mẫu n(Omega_A) khác n(Omega_B).

### 5.2 Allowed Concepts & Terminology
- So sánh xác suất, tích chéo, lớn hơn, nhỏ hơn, bằng nhau, khả năng xảy ra cao hơn / thấp hơn / như nhau.

### 5.3 Forbidden Concepts (Anti-Leakage)
- Kỳ vọng toán học, biến ngẫu nhiên, quy tắc cộng/nhân D3/D4.

### 5.4 Common Misconceptions & Distractor Logic
- `MISC_CP_01`: So sánh n(A) và n(B) thuộc 2 không gian mẫu khác nhau n(Omega_A) != n(Omega_B) mà không đưa về cùng mẫu số hoặc không nhân tích chéo (ví dụ: cho rằng n(A)=4 trong 20 bi có xác suất lớn hơn n(B)=3 trong 10 bi).
- `MISC_CP_02`: Cho rằng biến cố ngẫu nhiên bất kỳ luôn có khả năng xảy ra bằng 50%.

### 5.5 Difficulty Guidance
- **Difficulty 2**: So sánh n(A) và n(B) trong cùng phép thử gieo 1 con xúc xắc (n(Omega_A) = n(Omega_B) = 6).
- **Difficulty 3**: Sắp xếp 3 biến cố theo thứ tự xác suất tăng dần hoặc giảm dần sử dụng so sánh tích chéo.
- **Difficulty 4**: Ghép biến cố với mô tả khả năng ("Ít khả năng nhất", "Đồng khả năng", "Khả năng cao nhất").

### 5.6 Parameter Domains & Mutation Boundaries
- `dice_events`: A: mặt lẻ (3 / 6), B: mặt 6 (1 / 6), C: mặt > 2 (4 / 6).
- `urn_balls`: Bag A (R=5, total=10 -> 5 / 10), Bag B (R=3, total=5 -> 3 / 5). Left = 5 * 5 = 25, Right = 3 * 10 = 30 -> Bag B lớn hơn.

### 5.7 Seed Families & Reference Mappings
- `q_d2_04_1` (MC), `q_d2_04_2` (DragDrop), `q_d2_04_3` (Matching), `q_d2_04_4` (Input), `q_d2_04_5` (MC).

### 5.8 Deterministic Answer Rules
- `compare_probability(n_A, n_total_A, n_B, n_total_B)`: (Result Type: `String`)
  - `left = n_A * n_total_B`
  - `right = n_B * n_total_A`
  - If `left > right` return `"greater"`
  - If `left < right` return `"less"`
  - Else return `"equal"`

### 5.9 Legal Interaction Types
- `multiple_choice`, `drag_drop`, `matching`, `input`.

---

## 6. SUBTOPIC 2.5: `multi_data_classical` (Bài Toán Xác Suất Từ Nhiều Tập Dữ Liệu - Boss ALEATOR Scope)

### 6.1 Canonical Knowledge & Definitions
- **Xác Suất Chọn Từ Tập Dữ Liệu Đa Thể**: Bài toán chọn ngẫu nhiên 1 đối tượng từ tổng thể gồm nhiều nhóm phân loại (màu sắc bi, nam/nữ, lớp học, loại thẻ).
- **Tính n(Omega) Tổng**: n(Omega) = N_1 + N_2 + ... + N_k (tổng số đối tượng sơ cấp).
- **Tính n(A) Nhóm**: n(A) = tổng số đối tượng thuộc các nhóm thỏa mãn điều kiện A.
- **Tính P(A)**: P(A) = n(A) / n(Omega).
- **Ví dụ Túi Bi 5 Đỏ + 3 Xanh**:
  - Không gian mẫu n(Omega) = 5 + 3 = 8 quả cầu sơ cấp đồng khả năng (b_1..b_8).
  - Xác suất mỗi quả cầu b_i: P(b_i) = 1 / 8.
  - Xác suất biến cố A ("bốc được bi đỏ"): P(A) = 5 / 8.
  - Xác suất biến cố B ("bốc được bi xanh"): P(B) = 3 / 8.

### 6.2 Allowed Concepts & Terminology
- Bài toán tổng hợp, bốc bi nhiều màu, chọn học sinh từ danh sách nam/nữ, chọn thẻ từ nhiều hộp, phân số tối giản.

### 6.3 Forbidden Concepts (Anti-Leakage)
- Công thức tổ hợp C_n^k chọn nhiều đối tượng cùng lúc (D2 chỉ chọn 1 đối tượng ngẫu nhiên từ tập đa thể, n(Omega) = tổng số vật), quy tắc cộng/nhân D3/D4.

### 6.4 Common Misconceptions & Distractor Logic
- `MISC_MDC_01`: Quên cộng tất cả các nhóm khi tính n(Omega) (ví dụ: chỉ lấy số bi đỏ chia cho số bi xanh).
- `MISC_MDC_02`: Đếm thiếu nhóm thỏa mãn khi biến cố A bao gồm nhiều nhóm (ví dụ: "chọn bi đỏ hoặc xanh" chỉ đếm bi đỏ).

### 6.5 Difficulty Guidance
- **Difficulty 3**: Bốc 1 bi từ túi chứa R bi đỏ, B bi xanh, Y bi vàng. Tính P(bi đỏ) = R / (R + B + Y) hoặc P(bi không phải vàng) = (R + B) / (R + B + Y).
- **Difficulty 4**: Chọn 1 học sinh từ lớp gồm M nam và N nữ. Tính P(chọn được học sinh nữ) = N / (M + N).
- **Difficulty 5**: Bài toán tổng hợp Boss ALEATOR: Rút 1 thẻ từ tập N thẻ gồm nhiều màu sắc và chữ số, đếm n(A) thỏa mãn điều kiện kết hợp (màu X và số chẵn) rồi tính P(A) = n(A) / N.

### 6.6 Parameter Domains & Mutation Boundaries
- `urn_balls`: R in {3..8}, B in {3..8}, Y in {2..6} (Total N = R+B+Y <= 20).
- `class_students`: M boys in {10..20}, N girls in {10..20} (Total N = M+N <= 40).
- `numbered_cards`: N in {20, 30, 40}.

### 6.7 Seed Families & Reference Mappings
- `q_d2_05_1` (MC), `q_d2_05_2` (Input), `q_d2_05_3` (DragDrop), `q_d2_05_4` (Matching), `q_d2_05_5` (Input).

### 6.8 Deterministic Answer Rules
- `calc_multi_data_prob(group_counts, fav_groups)`:
  - n_total = sum(group_counts)
  - n_fav = sum(group_counts[g] for g in fav_groups)
  - g = gcd(n_fav, n_total)
  - Return simplified fraction string "n_fav/g / n_total/g". (Result Type: `String`)

### 6.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---
