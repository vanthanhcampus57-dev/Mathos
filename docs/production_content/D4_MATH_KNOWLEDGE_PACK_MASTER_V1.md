# DUNGEON 4 MATH KNOWLEDGE PACK MASTER V1.0

**Document Version**: 1.0.1 (Corrected Fix 1)  
**Authority Task ID**: `MATHOS-DIRECT-QGEN-D4-AUTHORITY-001`  
**Dungeon ID**: `dungeon_04`  
**Topic ID**: `multiplication_independence`  
**Canonical Subtopics**: `independence`, `tree_diagram`, `multiplication_two_step`, `multiplication_chain`, `independence_application`  
**Target Domain**: High School Probability & Statistics (Grade 10/11 - Chương Trình GDPT Việt Nam)  

---

## 1. GLOBAL PEDAGOGICAL & BOUNDARY GUARDRAILS

- **Core Independent Multiplication Rules**:
  - Independent Events Definition: Two events A and B are independent if and only if the occurrence or non-occurrence of A does not alter the probability of B occurring.
  - Two-Event Multiplication Rule: P(A n B) = P(A) * P(B) if and only if A and B are independent.
  - Independence Preservation Rule: If A and B are independent, then A and B_bar, A_bar and B, A_bar and B_bar are also independent pairs.
  - Chain Multiplication Rule: P(A_1 n A_2 n ... n A_k) = P(A_1) * P(A_2) * ... * P(A_k) for k independent events.
  - At-Least-One Independent Identity: P(at least 1 occurs) = 1 - P(A_1_bar n ... n A_k_bar) = 1 - (1 - P(A_1)) * ... * (1 - P(A_k)).
  - Exactly-One Independent Identity: P(exactly 1 occurs out of 2) = P(A n B_bar) + P(A_bar n B) = P(A)*(1 - P(B)) + (1 - P(A))*P(B).
- **Strict Event Consistency Constraints**:
  - 0 <= P(A), P(B), P(A n B) <= 1.
  - P(A n B) <= min(P(A), P(B)).
  - Independent condition P(A n B) = P(A) * P(B) must be explicitly authorized by physical independence (e.g. separate dice, separate coin flips, independent target shooters, independent exam takers, independent parallel electrical components).
- **Strict Exponent Notation Enforcement**:
  - All sample space sizing for k independent outcome flips must explicitly use power notation: n(Omega) = 2^k for k coins, n(Omega) = 6^k for k dice, (1 / 6)^3 = 1 / 216 for 3 dice.
  - Misconception for k coin flips explicitly contrasts linear error WRONG: 2 * k vs CORRECT exponent: 2^k.
- **Rational First & Runtime Float Contract**:
  - Rational probability P(A) = a / b is mathematically exact.
  - Decimal float expressions (e.g. P(A) = 0.4 * 0.5 = 0.2) are evaluated against the `QuestionEvaluator` contract (`abs(submission - accepted) <= numeric_tolerance`).
- **Anti-Leakage Guardrails (Out of Scope)**:
  - NO Bayes' Theorem or advanced conditional probability updates P(A|B).
  - NO continuous random variables, probability density functions, or integrals.
  - NO expected value, variance, or standard deviation calculations.
  - NO Markov chains or stochastic matrices.

---

## 2. SUBTOPIC 4.1: `independence` (Khái Niệm Hai Biến Cố Độc Lập)

### 2.1 Canonical Knowledge & Definitions
- **Hai Biến Cố Độc Lập**: Hai biến cố A và B được gọi là độc lập nếu việc xảy ra hay không xảy ra của biến cố này không ảnh hưởng đến xác suất xảy ra của biến cố kia.
- **Phép Thử Lặp Lại Độc Lập**: Các phép thử ngẫu nhiên được tiến hành độc lập với nhau (như gieo 2 đồng xu riêng biệt, 2 xạ thủ cùng bắn độc lập vào mục tiêu).
- **Phân Biệt Xung Khắc và Độc Lập**:
  - Xung khắc: A n B = EmptySet, n(A n B) = 0 (hai biến cố không thể cùng xảy ra).
  - Độc Lập: P(A n B) = P(A) * P(B) (hai biến cố có thể cùng xảy ra, xác suất giao bằng tích xác suất).

### 2.2 Allowed Concepts & Terminology
- Biến cố độc lập, phép thử độc lập, không ảnh hưởng lẫn nhau, phân biệt độc lập và xung khắc, biến cố đối độc lập.

### 2.3 Forbidden Concepts (Anti-Leakage)
- Công thức Bayes, xác suất điều kiện P(A|B), quy tắc cộng tổng quát D3 (trừ khi kết hợp ở Subtopic 4.4/4.5).

### 2.4 Common Misconceptions & Distractor Logic
- `MISC_IND_01`: Nhầm lẫn giữa hai biến cố độc lập (P(A n B) = P(A)*P(B)) và hai biến cố xung khắc (P(A n B) = 0).
- `MISC_IND_02`: Cho rằng hai biến cố phụ thuộc (như rút bi không hoàn lại) là độc lập.

### 2.5 Difficulty Guidance
- **Difficulty 1**: Nhận biết định nghĩa hai biến cố độc lập.
- **Difficulty 2**: Phân loại các tình huống thực tế vào nhóm "Độc lập" hoặc "Phụ thuộc".
- **Difficulty 3**: Nhận biết tính chất: Nếu A và B độc lập thì A_bar và B_bar cũng độc lập.

### 2.6 Parameter Domains & Mutation Boundaries
- `independent_scenarios`: ["Gieo 1 con xúc xắc 6 mặt và 1 đồng xu cân đối (q_04_01_01)", "Hai xạ thủ bắn độc lập vào 1 mục tiêu (q_04_02_05)", "Hai học sinh An và Bình làm bài thi độc lập (q_04_03_04)"].
- `dependent_scenarios`: ["Rút 2 bi liên tiếp không hoàn lại từ túi bi (q_04_05_03)"].

### 2.7 Seed Families & Reference Mappings
- `q_d4_01_1` (MC), `q_d4_01_2` (Matching), `q_d4_01_3` (DragDrop), `q_d4_01_4` (MC), `q_d4_01_5` (Input).

### 2.8 Deterministic Answer Rules
- `is_independent_scenario(scenario_id)`: Return `true` if scenario has independent physical mechanism; `false` otherwise. (Result Type: `bool`)

### 2.9 Legal Interaction Types
- `multiple_choice`, `matching`, `drag_drop`, `input`.

---

## 3. SUBTOPIC 4.2: `tree_diagram` (Liệt Kê Phép Thử Lặp & Sơ Đồ Cây Độc Lập)

### 3.1 Canonical Knowledge & Definitions
- **Liệt Kê Không Gian Mẫu Cho Phép Thử Lặp Độc Lập**: Khi thực hiện phép thử lặp độc lập k lần (gieo đồng xu k lần, gieo k xúc xắc), n(Omega) = n_1 * n_2 * ... * n_k.
- **Đồng Xu Lặp k Lần**: n(Omega) = 2^k (với k = 2 -> n(Omega) = 2^2 = 4, với k = 3 -> n(Omega) = 2^3 = 8).
- **Xúc Xắc Lặp k Lần**: n(Omega) = 6^k (với k = 2 -> n(Omega) = 6^2 = 36, với k = 3 -> n(Omega) = 6^3 = 216).
- **Mối Quan Hệ Biến Cố Đối Độc Lập (Authorized in Stage 4.2 Q5)**: Nếu A và B độc lập thì A_bar và B_bar độc lập, suy ra P(A_bar n B_bar) = (1 - P(A)) * (1 - P(B)).

### 3.2 Allowed Concepts & Terminology
- Sơ đồ cây độc lập, n(Omega) = 2^k, 6^k, tích số phần tử, xác suất biến cố đối độc lập (1 - p1)*(1 - p2).

### 3.3 Forbidden Concepts (Anti-Leakage)
- Xác suất điều kiện trên từng nhánh cây phụ thuộc.

### 3.4 Common Misconceptions & Distractor Logic
- `MISC_TD_01`: Tính sai n(Omega) cho phép thử lặp (nhầm công thức lũy thừa 2^k với tích 2 * k; ví dụ: gieo đồng xu 3 lần cho rằng n(Omega) = 2 * 3 = 6 thay vì 2^3 = 8).
- `MISC_TD_02`: Tính sai P(A_bar n B_bar) bằng cách lấy 1 - P(A n B) thay vì (1 - P(A))*(1 - P(B)).

### 3.5 Difficulty Guidance
- **Difficulty 2**: Tính n(Omega) cho gieo k đồng xu cân đối độc lập (n(Omega) = 2^k).
- **Difficulty 3**: Cho xạ thủ 1 có P(trúng) = p1, xạ thủ 2 có P(trúng) = p2. Tính P(cả 2 cùng trượt) = (1 - p1)*(1 - p2) (Authorized in Stage 4.2 Q5).
- **Difficulty 4**: Phân loại các giá trị xác suất sơ đồ cây khi gieo 1 đồng xu 3 lần liên tiếp (n(Omega) = 2^3 = 8).

### 3.6 Parameter Domains & Mutation Boundaries
- `shooters_miss`: p1 in {0.6, 0.7, 0.8}, p2 in {0.5, 0.7, 0.8, 0.9} -> P(miss_both) = (1 - p1) * (1 - p2).
- `coin_flips`: k in {2, 3} -> n(Omega) in {2^2 = 4, 2^3 = 8}.

### 3.7 Seed Families & Reference Mappings
- `q_d4_02_1` (MC), `q_d4_02_2` (Input), `q_d4_02_3` (Matching), `q_d4_02_4` (DragDrop), `q_d4_02_5` (Input).

### 3.8 Deterministic Answer Rules
- `calc_both_miss_prob(p1, p2)`: Return float `round((1.0 - p1) * (1.0 - p2), 3)`. (Result Type: `float`)
- `calc_n_omega_independent_flips(k)`: Return integer `2^k`. (Result Type: `int`)

### 3.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---

## 4. SUBTOPIC 4.3: `multiplication_two_step` (Quy Tắc Nhân Xác Suất Cho Hai Biến Cố Độc Lập)

### 4.1 Canonical Knowledge & Definitions
- **Quy Tắc Nhân Cho 2 Biến Cố Độc Lập**: Nếu A và B là hai biến cố độc lập, xác suất để cả A và B cùng xảy ra là: P(A n B) = P(A) * P(B).
- **Áp Dụng Cho Phép Thử Thập Phân & Phân Số**:
  - P(A) = 0.4, P(B) = 0.5 -> P(A n B) = 0.4 * 0.5 = 0.2.
  - Gieo 2 đồng xu: P(S1 n S2) = (1 / 2) * (1 / 2) = 1 / 4 = 0.25.
  - Gieo 2 con xúc xắc: P(mặt 6 con 1 n mặt 6 con 2) = (1 / 6) * (1 / 6) = 1 / 36.

### 4.2 Allowed Concepts & Terminology
- Quy tắc nhân xác suất, P(A n B) = P(A) * P(B), biến cố giao của 2 biến cố độc lập, 2 đồng xu, 2 xạ thủ.

### 4.3 Forbidden Concepts (Anti-Leakage)
- Áp dụng quy tắc nhân P(A n B) = P(A) * P(B) cho 2 biến cố phụ thuộc.

### 4.4 Common Misconceptions & Distractor Logic
- `MISC_M2S_01`: Cộng xác suất P(A) + P(B) khi biến cố giao A n B ("và") xảy ra độc lập.
- `MISC_M2S_02`: Lấy trung bình cộng (P(A) + P(B)) / 2 thay vì nhân P(A) * P(B).

### 4.5 Difficulty Guidance
- **Difficulty 2**: Tính P(A n B) khi biết P(A) và P(B) dạng thập phân cho trước (P(A)=0.4, P(B)=0.5 -> P(A n B)=0.2).
- **Difficulty 3**: Tính P(cả 2 đồng xu sấp) = (1 / 2) * (1 / 2) = 1 / 4 = 0.25.
- **Difficulty 4**: Bài toán An và Bình làm bài thi độc lập: P(An đúng)=0.8, P(Bình đúng)=0.9 -> P(cả 2 cùng đúng) = 0.8 * 0.9 = 0.72.

### 4.6 Parameter Domains & Mutation Boundaries
- `decimal_mult`: pA in {0.3, 0.4, 0.5, 0.6, 0.7}, pB in {0.4, 0.5, 0.6, 0.8, 0.9} -> P(A n B) = pA * pB.
- `exam_takers`: p_an in {0.7, 0.8}, p_binh in {0.8, 0.9} -> P(both_correct) = p_an * p_binh.

### 4.7 Seed Families & Reference Mappings
- `q_d4_03_1` (MC), `q_d4_03_2` (Input), `q_d4_03_3` (Matching), `q_d4_03_4` (DragDrop), `q_d4_03_5` (Input).

### 4.8 Deterministic Answer Rules
- `calc_two_step_mult_prob(p_A, p_B)`: Return float `round(p_A * p_B, 3)`. (Result Type: `float`)

### 4.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---

## 5. SUBTOPIC 4.4: `multiplication_chain` (Quy Tắc Nhân Mở Rộng Cho n Biến Cố & Bài Toán "Ít Nhất 1")

### 5.1 Canonical Knowledge & Definitions
- **Quy Tắc Nhân Mở Rộng Cho k Biến Cố Độc Lập**: P(A_1 n A_2 n ... n A_k) = P(A_1) * P(A_2) * ... * P(A_k).
- **Bài Toán "Ít Nhất 1 Biến Cố Xảy Ra"**: P(ít nhất 1 xảy ra) = 1 - P(tất cả đều không xảy ra) = 1 - (1 - P(A_1)) * (1 - P(A_2)) * ... * (1 - P(A_k)).
- **Linh Kiện Mắc Song Song**: Hệ thống gồm k linh kiện mắc song song hoạt động khi ít nhất 1 linh kiện hoạt động. P(hệ thống hoạt động) = 1 - P(linh kiện 1 hỏng) * ... * P(linh kiện k hỏng).

### 5.2 Allowed Concepts & Terminology
- Quy tắc nhân chuỗi, P(A_1 n ... n A_k), biến cố đối "ít nhất 1", linh kiện mắc song song, 3 con xúc xắc 6 mặt độc lập ((1 / 6)^3 = 1 / 216), 3 người làm bài thi độc lập.

### 5.3 Forbidden Concepts (Anti-Leakage)
- Công thức Bernouilli / Phân phối nhị thức.

### 5.4 Common Misconceptions & Distractor Logic
- `MISC_MC_01`: Cộng các xác suất P(A_i) khi tính bài toán "ít nhất 1" dẫn tới P > 1.
- `MISC_MC_02`: Quên trừ khỏi 1 khi dùng biến cố đối cho bài toán "ít nhất 1".

### 5.5 Difficulty Guidance
- **Difficulty 3**: Gieo 3 con xúc xắc 6 mặt độc lập. P(cả 3 mặt 6) = (1 / 6)^3 = 1 / 216 (Hỏi mẫu số b = 216 của phân số 1 / b theo q_04_03_05).
- **Difficulty 4**: Hai xạ thủ độc lập có P(A)=0.7, P(B)=0.8. P(ít nhất 1 trúng) = 1 - (1 - 0.7)*(1 - 0.8) = 1 - 0.3 * 0.2 = 1 - 0.06 = 0.94.
- **Difficulty 5**: Ba người A, B, C độc lập làm bài thi với P(A)=0.7, P(B)=0.8, P(C)=0.9. P(cả 3 cùng đúng) = 0.7 * 0.8 * 0.9 = 0.504.

### 5.6 Parameter Domains & Mutation Boundaries
- `three_shooters_hit`: pA=0.7, pB=0.8, pC=0.9 -> P(all_hit) = 0.7 * 0.8 * 0.9 = 0.504.
- `parallel_components`: p_fail1=0.1, p_fail2=0.2 -> P(system_works) = 1 - 0.1 * 0.2 = 0.98.

### 5.7 Seed Families & Reference Mappings
- `q_d4_04_1` (MC), `q_d4_04_2` (Input), `q_d4_04_3` (Matching), `q_d4_04_4` (DragDrop), `q_d4_04_5` (Input).

### 5.8 Deterministic Answer Rules
- `calc_chain_mult_prob(p_list)`:
  - Return float `round(product(p_list), 3)`. (Result Type: `float`)
- `calc_at_least_one_independent_prob(p_list)`:
  - Return float `round(1.0 - product(1.0 - p for p in p_list), 3)`. (Result Type: `float`)

### 5.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---

## 6. SUBTOPIC 4.5: `independence_application` (Vận Dụng Phức Hợp Quy Tắc Nhân & Cộng - Boss APHODIUS Scope)

### 6.1 Canonical Knowledge & Definitions
- **Bài Toán "Đúng 1 Biến Cố Xảy Ra"**: Cho 2 biến cố độc lập A và B. P(đúng 1 biến cố xảy ra) = P(A n B_bar) + P(A_bar n B) = P(A)*(1 - P(B)) + (1 - P(A))*P(B).
- **Vận Dụng Tổng Hợp Boss APHODIUS**: Phối hợp quy tắc nhân độc lập và quy tắc cộng cho các trường hợp xung khắc trong bài toán 2 hoặc 3 xạ thủ, gieo 2 xúc xắc độc lập với điều kiện số học kết hợp, hoặc thi đấu thể thao độc lập.

### 6.2 Allowed Concepts & Terminology
- Đúng 1 biến cố xảy ra, P(A n B_bar) + P(A_bar n B), Boss APHODIUS synthesis, vận dụng phức hợp quy tắc nhân và cộng.

### 6.3 Forbidden Concepts (Anti-Leakage)
- Công thức Bayes, xác suất điều kiện P(A|B), sơ đồ cây phụ thuộc.

### 6.4 Common Misconceptions & Distractor Logic
- `MISC_IA_01`: Bỏ sót 1 trong 2 trường hợp khi tính bài toán "đúng 1 biến cố xảy ra" (ví dụ: chỉ tính P(A n B_bar) mà quên P(A_bar n B)).
- `MISC_IA_02`: Nhân P(A) * P(B) cho bài toán "đúng 1 biến cố xảy ra" (nhầm với bài toán "cả 2 cùng xảy ra").

### 6.5 Difficulty Guidance
- **Difficulty 4**: Gieo 2 con xúc xắc 6 mặt độc lập. P(xúc xắc 1 chẵn VÀ xúc xắc 2 chia hết 3) = P(chẵn) * P(chia hết 3) = (3 / 6) * (2 / 6) = (1 / 2) * (1 / 3) = 1 / 6.
- **Difficulty 5**: Hai xạ thủ độc lập có P(A)=0.8, P(B)=0.7. P(đúng 1 người trúng) = 0.8 * (1 - 0.7) + (1 - 0.8) * 0.7 = 0.8 * 0.3 + 0.2 * 0.7 = 0.24 + 0.14 = 0.38.
- **Difficulty 5**: Boss APHODIUS Chiêu Cuối: Ba xạ thủ độc lập có P(A)=0.6, P(B)=0.7, P(C)=0.8. P(mục tiêu bị trúng đạn) = 1 - (1 - 0.6)*(1 - 0.7)*(1 - 0.8) = 1 - 0.4 * 0.3 * 0.2 = 1 - 0.024 = 0.976.

### 6.6 Parameter Domains & Mutation Boundaries
- `exactly_one_hit`: pA=0.8, pB=0.7 -> P = 0.8*0.3 + 0.2*0.7 = 0.38.
- `aphodius_final`: pA=0.6, pB=0.7, pC=0.8 -> P = 1 - 0.4*0.3*0.2 = 0.976.

### 6.7 Seed Families & Reference Mappings
- `q_d4_05_1` (MC), `q_d4_05_2` (Input), `q_d4_05_3` (Matching), `q_d4_05_4` (DragDrop), `q_d4_05_5` (Input).

### 6.8 Deterministic Answer Rules
- `calc_exactly_one_hit_prob(pA, pB)`:
  - Return float `round(pA * (1.0 - pB) + (1.0 - pA) * pB, 3)`. (Result Type: `float`)
- `calc_aphodius_final_prob(pA, pB, pC)`:
  - Return float `round(1.0 - (1.0 - pA) * (1.0 - pB) * (1.0 - pC), 3)`. (Result Type: `float`)

### 6.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---
