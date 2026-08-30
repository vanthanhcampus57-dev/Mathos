# DUNGEON 3 MATH KNOWLEDGE PACK MASTER V1.0

**Document Version**: 1.0.1 (Corrected Fix 1)  
**Authority Task ID**: `MATHOS-DIRECT-QGEN-D3-AUTHORITY-001`  
**Dungeon ID**: `dungeon_03`  
**Topic ID**: `addition_rule`  
**Canonical Subtopics**: `union_intersection`, `mutually_exclusive`, `addition_simple`, `addition_general`, `addition_selection`  
**Target Domain**: High School Probability & Statistics (Grade 10/11 - Chương Trình GDPT Việt Nam)  

---

## 1. GLOBAL PEDAGOGICAL & BOUNDARY GUARDRAILS

- **Core Addition Rules**:
  - General Addition Rule: P(A u B) = P(A) + P(B) - P(A n B) for any two events A, B <= Omega.
  - Disjoint / Mutually Exclusive Addition Rule: If A n B = EmptySet, then P(A n B) = 0 and P(A u B) = P(A) + P(B).
  - Complementary Event Rule: P(A_bar) = 1 - P(A).
  - Set Element Addition Identity: n(A u B) = n(A) + n(B) - n(A n B).
- **Strict Event Consistency Constraints**:
  - 0 <= P(A), P(B), P(A n B), P(A u B) <= 1.
  - P(A n B) <= min(P(A), P(B)).
  - P(A u B) = P(A) + P(B) - P(A n B) <= 1 (i.e. P(A n B) >= P(A) + P(B) - 1).
  - n(A n B) <= min(n(A), n(B)).
  - n(A u B) <= n(Omega).
- **Rational First Arithmetic & Runtime Float Contract**:
  - Rational probability P(A) = a / b is mathematically exact and authoritative.
  - Decimal float expressions (e.g. P(A) = 0.75) are evaluated against the `QuestionEvaluator` contract (`abs(submission - accepted) <= numeric_tolerance`).
- **Strict Prohibition of Combinatorial Formulas in D3 QGen**:
  - Absolutely ZERO C(n,k), A(n,k), or P(n) combination/permutation formulas are required or permitted in D3 question generation.
  - All set sizes n(A), n(B), n(A n B), n(A u B) and probabilities are computed via direct listing, set identities, or given data parameters with n(Omega) <= 36 (or explicit finite counts).
- **Anti-D4 Learner-Facing Audit**:
  - Learner-facing answer options and distractors MUST NEVER include Dungeon 4 multiplication formulas P(A n B) = P(A) * P(B) or independence formulas.
  - Learner-facing distractors test D3-native misconceptions ONLY (e.g., failing to subtract overlap P(A) + P(B), subtracting overlap twice P(A) + P(B) - 2*P(A n B), or adding overlap P(A) + P(B) + P(A n B)).
  - D4 multiplication formulas appear strictly in internal forbidden concept documentation for developer anti-leakage compliance.
- **Strict Subtopic Sequencing**:
  - Subtopic 3.1 (`union_intersection`) uses ONLY union A u B, intersection A n B, and subset A <= Omega. Complement notation A_bar is introduced exclusively in Subtopic 3.2 (`mutually_exclusive`).
- **Concrete Context Authority Mapping**:
  - Every template context is mapped directly to accepted D3 curriculum in `PRODUCTION_CONTENT_MASTER_V1.md`:
    - `dice_roll` (1 or 2 dice): Authorized in Stage 3.1 (Q2), Stage 3.2 (Q3), Stage 3.5 (Q1).
    - `playing_cards` (52-card deck): Authorized in Stage 3.1 (Q5), Stage 3.3 (Q2), Stage 3.4 (Q2).
    - `class_survey` (Students preferring Math/English/Sports): Authorized in Stage 3.4 (Q5), Stage 3.5 (Q2).
    - `target_shooting` (Shooter rounds 10, 9, 8): Authorized in Stage 3.2 (Q5), Stage 3.3 (Q5).
    - `urn_ball_selection` (Balls in bag): Authorized in Stage 3.3 (Q4).

---

## 2. SUBTOPIC 3.1: `union_intersection` (Hợp và Giao Của Hai Biến Cố)

### 2.1 Canonical Knowledge & Definitions
- **Biến Cố Hợp A u B**: Biến cố "A hoặc B xảy ra". n(A u B) = n(A) + n(B) - n(A n B).
- **Biến Cố Giao A n B**: Biến cố "cả A và B cùng xảy ra".
- **Biểu Đồ Venn**: Minh họa mối quan hệ giữa tập A, tập B và phần giao A n B.

### 2.2 Allowed Concepts & Terminology
- Biến cố hợp A u B, biến cố giao A n B, tập hợp hợp, tập hợp giao, số phần tử n(A u B), n(A n B), A <= Omega.

### 2.3 Forbidden Concepts (Anti-Leakage)
- Biến cố đối A_bar (dành cho Subtopic 3.2), quy tắc nhân xác suất P(A n B) = P(A) * P(B), khái niệm độc lập D4, tổ hợp C(n,k).

### 2.4 Common Misconceptions & Distractor Logic
- `MISC_UI_01`: Quên trừ đi phần giao n(A n B) khi tính n(A u B) (tính n(A u B) = n(A) + n(B)).
- `MISC_UI_02`: Nhầm lẫn giữa biến cố hợp A u B ("hoặc") và biến cố giao A n B ("và").

### 2.5 Difficulty Guidance
- **Difficulty 1**: Nhận biết ký hiệu hợp A u B ("hoặc") và giao A n B ("và").
- **Difficulty 2**: Tính n(A u B) khi biết n(A), n(B), n(A n B) cho tập hợp số nhỏ.
- **Difficulty 3**: Liệt kê phần tử thuộc A u B khi gieo 1 con xúc xắc hoặc rút 1 lá bài từ bộ bài 52 lá (ví dụ: lá bài chất Cơ hoặc lá K, n(A u B) = 13 + 4 - 1 = 16).

### 2.6 Parameter Domains & Mutation Boundaries
- `dice_union`: A = {1, 2}, B = {2, 4, 6} -> A n B = {2} (n=1), A u B = {1, 2, 4, 6} (n=4).
- `card_union`: A = chất Cơ (n=13), B = lá K (n=4), A n B = K cơ (n=1) -> n(A u B) = 13 + 4 - 1 = 16.

### 2.7 Seed Families & Reference Mappings
- `q_d3_01_1` (MC), `q_d3_01_2` (Input), `q_d3_01_3` (Matching), `q_d3_01_4` (DragDrop), `q_d3_01_5` (Input).

### 2.8 Deterministic Answer Rules
- `calc_n_union(n_A, n_B, n_intersection)`:
  - Validate: 0 <= n_intersection <= min(n_A, n_B).
  - Return integer `n_A + n_B - n_intersection`. (Result Type: `int`)

### 2.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---

## 3. SUBTOPIC 3.2: `mutually_exclusive` (Hai Biến Cố Xung Khắc & Biến Cố Đối)

### 3.1 Canonical Knowledge & Definitions
- **Hai Biến Cố Xung Khắc**: Hai biến cố A và B được gọi là xung khắc nếu chúng không thể cùng xảy ra trong một phép thử (A n B = EmptySet, n(A n B) = 0).
- **Biến Cố Đối (A_bar)**: Biến cố "A không xảy ra". A và A_bar là hai biến cố xung khắc và A u A_bar = Omega.
- **Công Thức Xác Suất Biến Cố Đối**: P(A_bar) = 1 - P(A).

### 3.2 Allowed Concepts & Terminology
- Biến cố xung khắc, không thể cùng xảy ra, A n B = EmptySet, biến cố đối A_bar, 1 - P(A).

### 3.3 Forbidden Concepts (Anti-Leakage)
- Khái niệm biến cố độc lập D4 (xung khắc n(A n B)=0 khác hoàn toàn với độc lập P(A n B)=P(A)*P(B)).

### 3.4 Common Misconceptions & Distractor Logic
- `MISC_ME_01`: Nhầm lẫn giữa hai biến cố xung khắc (A n B = EmptySet) và hai biến cố có A u B = EmptySet.
- `MISC_ME_02`: Quên rằng P(A) + P(A_bar) = 1.

### 3.5 Difficulty Guidance
- **Difficulty 1**: Nhận biết điều kiện hai biến cố xung khắc A n B = EmptySet.
- **Difficulty 2**: Tính P(A_bar) = 1 - P(A) với P(A) dạng thập phân hoặc phân số.
- **Difficulty 3**: Phân loại các cặp biến cố thành xung khắc vs không xung khắc khi gieo xúc xắc hoặc rút bài.

### 3.6 Parameter Domains & Mutation Boundaries
- `prob_A`: p in {0.1, 0.2, 0.25, 0.3, 0.4, 0.6, 0.75, 0.85}.
- `dice_pairs`: Pair 1: "mặt chẵn" & "mặt lẻ" (xung khắc); Pair 2: "mặt chẵn" & "mặt > 4" (không xung khắc vì có mặt 6).

### 3.7 Seed Families & Reference Mappings
- `q_d3_02_1` (MC), `q_d3_02_2` (Input), `q_d3_02_3` (Matching), `q_d3_02_4` (DragDrop), `q_d3_02_5` (Input).

### 3.8 Deterministic Answer Rules
- `is_mutually_exclusive(n_intersection)`: Return `n_intersection == 0`. (Result Type: `bool`)
- `calc_complement_prob_decimal(p_A)`: Return float `round(1.0 - p_A, 3)`. (Result Type: `float`)

### 3.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---

## 4. SUBTOPIC 3.3: `addition_simple` (Quy Tắc Cộng Xác Suất Cho Biến Cố Xung Khắc)

### 4.1 Canonical Knowledge & Definitions
- **Quy Tắc Cộng Biến Cố Xung Khắc**: Nếu A và B là hai biến cố xung khắc (A n B = EmptySet), thì: P(A u B) = P(A) + P(B).
- **Mở Rộng Cho k Biến Cố**: Nếu A_1, A_2, ..., A_k đôi một xung khắc thì P(A_1 u ... u A_k) = P(A_1) + ... + P(A_k).

### 4.2 Allowed Concepts & Terminology
- Quy tắc cộng xung khắc, P(A u B) = P(A) + P(B), biến cố đôi một xung khắc, rút bài (lá K hoặc lá Q), bắn súng đạt điểm (vòng 10, 9, 8).

### 4.3 Forbidden Concepts (Anti-Leakage)
- Công thức cộng tổng quát cho biến cố không xung khắc (dành cho Subtopic 3.4), quy tắc nhân D4.

### 4.4 Common Misconceptions & Distractor Logic
- `MISC_AS_01`: Trừ xác suất P(A) - P(B) thay vì cộng P(A) + P(B) khi biến cố xung khắc xảy ra ("hoặc").
- `MISC_AS_02`: Áp dụng quy tắc cộng xung khắc cho hai biến cố không xung khắc (bỏ sót P(A n B) > 0).

### 4.5 Difficulty Guidance
- **Difficulty 2**: Tính P(A u B) = P(A) + P(B) cho 2 biến cố xung khắc với P(A), P(B) cho trước dạng thập phân.
- **Difficulty 3**: Tính P(A u B) cho rút 1 lá bài (lá K hoặc lá Q -> P = 4 / 52 + 4 / 52 = 8 / 52 = 2 / 13).
- **Difficulty 4**: Tính xác suất bắn bia đạt ít nhất k điểm từ danh sách xác suất các vòng điểm đôi một xung khắc.

### 4.6 Parameter Domains & Mutation Boundaries
- `target_shooting`: P(10)=0.2, P(9)=0.35, P(8)=0.25 -> P(>=8) = 0.2 + 0.35 + 0.25 = 0.8.
- `card_draw`: P(K) = 4 / 52, P(Q) = 4 / 52 -> P(K or Q) = 8 / 52 = 2 / 13.

### 4.7 Seed Families & Reference Mappings
- `q_d3_03_1` (MC), `q_d3_03_2` (Input), `q_d3_03_3` (Matching), `q_d3_03_4` (DragDrop), `q_d3_03_5` (Input).

### 4.8 Deterministic Answer Rules
- `calc_simple_addition_prob(p_A, p_B)`: Return float `round(p_A + p_B, 3)`. (Result Type: `float`)
- `calc_simple_addition_fraction(n_A, n_B, n_total)`: Simplify (n_A + n_B) / n_total -> Return String "num / den". (Result Type: `String`)

### 4.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---

## 5. SUBTOPIC 3.4: `addition_general` (Quy Tắc Cộng Xác Suất Tổng Quát)

### 5.1 Canonical Knowledge & Definitions
- **Quy Tắc Cộng Xác Suất Tổng Quát**: Với hai biến cố bất kỳ A và B thuộc cùng không gian mẫu Omega: P(A u B) = P(A) + P(B) - P(A n B).
- **Trường Hợp Xung Khắc Nêu Trên**: Khi A n B = EmptySet thì P(A n B) = 0, công thức trở về P(A u B) = P(A) + P(B).

### 5.2 Allowed Concepts & Terminology
- Quy tắc cộng tổng quát, P(A u B) = P(A) + P(B) - P(A n B), biến cố giao, trừ phần lặp.

### 5.3 Forbidden Concepts (Anti-Leakage)
- D4 multiplication formulas. P(A n B) must be given directly or counted directly from n(A n B) / n(Omega).

### 5.4 Common Misconceptions & Distractor Logic
- `MISC_AG_01`: Quên trừ P(A n B) khi A và B không xung khắc (tính P(A u B) = P(A) + P(B)).
- `MISC_AG_02`: Cộng P(A n B) thay vì trừ P(A n B) (tính P(A) + P(B) + P(A n B)) hoặc trừ 2 lần P(A n B).

### 5.5 Difficulty Guidance
- **Difficulty 2**: Tính P(A u B) khi biết P(A), P(B) và P(A n B) dạng thập phân cho trước.
- **Difficulty 3**: Tính P(A u B) cho bài toán rút lá bài màu Đỏ hoặc lá bài K (P(Đỏ) = 26 / 52, P(K) = 4 / 52, P(K đỏ) = 2 / 52 -> P(Đỏ u K) = (26 + 4 - 2) / 52 = 28 / 52 = 7 / 13).
- **Difficulty 4**: Bài toán lớp học có N_math em giỏi Toán, N_eng em giỏi Anh, N_both em giỏi cả hai môn. Chọn 1 học sinh, tính P(giỏi ít nhất 1 môn) = (N_math + N_eng - N_both) / N_total = (20 + 15 - 5) / 40 = 30 / 40 = 3 / 4 = 0.75.

### 5.6 Parameter Domains & Mutation Boundaries
- `decimal_addition`: P(A)=0.6, P(B)=0.5, P(A n B)=0.3 -> P(A u B) = 0.6 + 0.5 - 0.3 = 0.8.
- `class_subject`: Total N=40. N_math=20, N_english=15, N_both=5 -> P = (20 + 15 - 5) / 40 = 30 / 40 = 3 / 4 = 0.75.

### 5.7 Seed Families & Reference Mappings
- `q_d3_04_1` (MC), `q_d3_04_2` (Input), `q_d3_04_3` (Matching), `q_d3_04_4` (DragDrop), `q_d3_04_5` (Input).

### 5.8 Deterministic Answer Rules
- `calc_general_addition_prob(p_A, p_B, p_intersection)`:
  - Validate: 0 <= p_intersection <= min(p_A, p_B), p_A + p_B - p_intersection <= 1.0.
  - Return float `round(p_A + p_B - p_intersection, 3)`. (Result Type: `float`)

### 5.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---

## 6. SUBTOPIC 3.5: `addition_selection` (Vận Dụng Quy Tắc Cộng Bài Toán Chọn/Đếm - Boss MELKOR Scope)

### 6.1 Canonical Knowledge & Definitions
- **Vận Dụng Tổng Hợp Quy Tắc Cộng qua Liệt Kê/Đếm Trực Tiếp**: Giải bài toán chọn/đếm ngẫu nhiên bằng cách phân chia biến cố cần tính thành các trường hợp đồng khả năng xung khắc hoặc dùng biến cố đối P(A) = 1 - P(A_bar) và tập hợp n(A u B) = n(A) + n(B) - n(A n B) với n(Omega) <= 36 (hoặc số đếm trực tiếp). Nghiêm cấm dùng công thức C(n,k).

### 6.2 Allowed Concepts & Terminology
- Vận dụng quy tắc cộng, phân chia trường hợp xung khắc, biến cố đối của "ít nhất 1", đếm số kết quả n(A u B), Boss MELKOR synthesis.

### 6.3 Forbidden Concepts (Anti-Leakage)
- Công thức tổ hợp C(n,k), quy tắc nhân xác suất độc lập D4, sơ đồ cây nhân xác suất.

### 6.4 Common Misconceptions & Distractor Logic
- `MISC_ASL_01`: Liệt kê thiếu trường hợp xung khắc khi chia nhỏ bài toán.
- `MISC_ASL_02`: Trừ sai phần giao khi kết hợp hai điều kiện đếm.

### 6.5 Difficulty Guidance
- **Difficulty 3**: Gieo 1 xúc xắc 6 mặt, tính P(mặt chia hết cho 3 hoặc mặt chẵn) (A={3,6}, B={2,4,6}, A n B={6} -> P = (2 + 3 - 1) / 6 = 4 / 6 = 2 / 3).
- **Difficulty 4**: Tính xác suất chọn 1 học sinh giỏi ít nhất 1 môn từ dữ liệu khảo sát 2 môn: P = (N_math + N_eng - N_both) / N_total = (20 + 15 - 5) / 40 = 3 / 4 = 0.75.
- **Difficulty 5**: Bài toán Boss MELKOR: Cho phép thử gieo 2 con xúc xắc 6 mặt cân đối (n(Omega) = 36). Biến cố A: "Tổng số chấm là số lẻ" (n(A) = 18), B: "Tích hai số chấm chia hết cho 5" (n(B) = 11, với n(A n B) = 6). Tính n(A u B) = 18 + 11 - 6 = 23 -> P(A u B) = 23 / 36. Zero công thức C(n,k) sử dụng.

### 6.6 Parameter Domains & Mutation Boundaries
- `dice_composite`: A={chia hết 3}, B={chẵn} -> P = 2 / 3.
- `two_dice_melkor`: n(Omega)=36, n(A)=18, n(B)=11, n(A n B)=6 -> n(A u B) = 23, P(A u B) = 23 / 36.

### 6.7 Seed Families & Reference Mappings
- `q_d3_05_1` (MC), `q_d3_05_2` (Input), `q_d3_05_3` (Matching), `q_d3_05_4` (DragDrop), `q_d3_05_5` (Input).

### 6.8 Deterministic Answer Rules
- `calc_n_union_melkor(n_A, n_B, n_inter)`:
  - Return integer `n_A + n_B - n_inter`. (Result Type: `int`)

### 6.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---
