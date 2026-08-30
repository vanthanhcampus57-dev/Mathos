# DUNGEON 1 MATH KNOWLEDGE PACK MASTER V1.0

**Document Version**: 1.0.3 (Corrected Round 3)  
**Authority Task ID**: `MATHOS-DIRECT-QGEN-D1-AUTHORITY-001`  
**Dungeon ID**: `dungeon_01`  
**Topic ID**: `trial_sample_event`  
**Canonical Subtopics**: `random_trial`, `sample_space`, `event_subset`, `event_classification`, `counting_outcomes`  
**Target Domain**: High School Probability & Statistics (Grade 10/11 - Chương Trình GDPT Việt Nam)  

---

## 1. GLOBAL PEDAGOGICAL & BOUNDARY GUARDRAILS

- **Sample Space Upper Bound**: n(Omega) <= 36 strictly enforced across all generator templates in Dungeon 1.
- **No Classical Probability**: Zero probability calculations (P(A) = n(A)/n(Omega)) allowed in Dungeon 1. D1 focuses exclusively on identifying trials, listing outcomes, identifying event subsets, classifying events, and counting outcomes via direct listing.
- **No D3 Addition Rule Leakage**: No event unions A u B, mutually exclusive additions, or general addition rules.
- **No D4 Multiplication & Independence Leakage**: No event intersections A n B, independent multiplication rules, or D4 concepts of independent events. Neutral terminology such as `two_step_draw`, `sequential_draw`, or `cartesian_outcome_enumeration` is used.
- **Strictly No Combinatorial Formulas**: No reliance on P_n, A_n^k, C_n^k or any algebraic permutation/combination formulas. All outcome counting in D1 must be solvable by direct listing, tree-diagram enumeration, or basic counting table methods.
- **Canonical Subset Notation**: Event subsets are denoted using A <= Omega (or A subseteq Omega) to account for certain events where A = Omega.

---

## 2. SUBTOPIC 1.1: `random_trial` (Phép Thử Ngẫu Nhiên)

### 2.1 Canonical Knowledge & Definitions
- **Phép Thử Ngẫu Nhiên**: Là hành động/thí nghiệm mà kết quả không thể đoán trước chính xác, nhưng biết trước tập hợp tất cả các kết quả có thể xảy ra.
- **Hành Động Tất Nhiên**: Thí nghiệm vật lý/toán học luôn cho cùng 1 kết quả cố định biết trước (vd: đun sôi nước ở 100°C, thả đá chìm trong nước, phép tính 5 x 6 = 30).

### 2.2 Allowed Concepts & Terminology
- Phép thử, ngẫu nhiên, gieo đồng xu, gieo xúc xắc, rút thẻ, bốc bi, kết quả có thể xảy ra.

### 2.3 Forbidden Concepts (Anti-Leakage)
- Xác suất P(A), tỷ lệ %, biến cố xung khắc, khái niệm biến cố độc lập D4, tổ hợp C_n^k, chỉnh hợp A_n^k, hoán vị P_n.

### 2.4 Common Misconceptions & Distractor Logic
- `MISC_RT_01`: Nhầm lẫn giữa hành động ngẫu nhiên và hành động có kết quả tất nhiên (vd: cho rằng thả đá rơi là ngẫu nhiên).
- `MISC_RT_02`: Cho rằng ngẫu nhiên nghĩa là "không thể biết bất kỳ khả năng nào" (thực tế là biết tập khả năng).

### 2.5 Difficulty Guidance
- **Difficulty 1**: Nhận biết ngẫu nhiên vs tất nhiên trong ví dụ đơn giản (1 đồng xu, 1 xúc xắc).
- **Difficulty 2**: Phân loại ngẫu nhiên vs tất nhiên trong danh sách tình huống thực tế.
- **Difficulty 3**: Ghép số lượng kết quả có thể xảy ra của các phép thử đơn lẻ.

### 2.6 Parameter Domains & Mutation Boundaries
- `coin_count`: k in {1, 2}
- `dice_count`: k in {1}
- `card_deck_size`: N in {4, 6, 10, 52}
- `ball_bag_total`: N in {2, 3, 4, 5, 6}

### 2.7 Seed Families & Reference Mappings
- `q_d1_01_1` (MC), `q_d1_01_2` (Matching), `q_d1_01_3` (DragDrop), `q_d1_01_4` (Input), `q_d1_01_5` (MC).

### 2.8 Deterministic Answer Rules
- `is_random_trial(action)`: `true` if action has uncertain outcomes within known set; `false` if outcome is deterministic. (Result Type: `bool`)
- `outcome_count(single_coin)` = 2; `outcome_count(single_dice)` = 6; `outcome_count(deck_N)` = N. (Result Type: `int`)

### 2.9 Legal Interaction Types
- `multiple_choice`, `matching`, `drag_drop`, `input`.

---

## 3. SUBTOPIC 1.2: `sample_space` (Không Gian Mẫu Omega)

### 3.1 Canonical Knowledge & Definitions
- **Không Gian Mẫu Omega**: Tập hợp tất cả các kết quả có thể xảy ra của phép thử ngẫu nhiên.
- **Số Phần Tử n(Omega)**: Kí hiệu số lượng phần tử thuộc Omega. Gieo 1 coin: n(Omega) = 2^1 = 2. Gieo 2 coins: n(Omega) = 2^2 = 4. Gieo 3 coins: n(Omega) = 2^3 = 8. Gieo 1 dice: n(Omega) = 6^1 = 6. Gieo 2 dice: n(Omega) = 6^2 = 36.

### 3.2 Allowed Concepts & Terminology
- Tập hợp Omega, phần tử, n(Omega), mặt Sấp (S), mặt Ngửa (N), số chấm xúc xắc {1, 2, 3, 4, 5, 6}.

### 3.3 Forbidden Concepts (Anti-Leakage)
- Tập rỗng làm không gian mẫu, xác suất cổ điển n(A)/n(Omega).

### 3.4 Common Misconceptions & Distractor Logic
- `MISC_SS_01`: Tính n(Omega) cho k đồng xu bằng 2*k thay vì 2^k (cho rằng 3 đồng xu có 2*3 = 6 kết quả thay vì 2^3 = 8).
- `MISC_SS_02`: Bỏ sót thứ tự cặp kết quả khi gieo 2 xúc xắc (cho rằng (1, 2) và (2, 1) là 1 kết quả).

### 3.5 Difficulty Guidance
- **Difficulty 1**: Viết hoặc chọn tập Omega cho phép thử 1 bước (1 coin, 1 dice).
- **Difficulty 2**: Tính n(Omega) cho gieo 2 coins (n(Omega) = 2^2 = 4) hoặc gieo 1 dice (n(Omega) = 6^1 = 6).
- **Difficulty 3**: Tính n(Omega) cho gieo 3 coins (n(Omega) = 2^3 = 8), 2 dice (n(Omega) = 6^2 = 36), chọn 1 bi từ 2 hộp (n(Omega) = N1 * N2 <= 36).

### 3.6 Parameter Domains & Mutation Boundaries
- `coin_count`: k in {1, 2, 3} -> n(Omega) = 2^k in {2, 4, 8}
- `dice_count`: k in {1, 2} -> n(Omega) = 6^k in {6, 36}
- `urn_1_size`: N1 in {2, 3, 4, 5}, `urn_2_size`: N2 in {2, 3, 4, 5, 6} -> N1 * N2 <= 30

### 3.7 Seed Families & Reference Mappings
- `q_d1_02_1` (MC), `q_d1_02_2` (Input), `q_d1_02_3` (Matching), `q_d1_02_4` (DragDrop), `q_d1_02_5` (Input).

### 3.8 Deterministic Answer Rules
- `n_omega_coins(k)` = 2^k. (Result Type: `int`)
- `n_omega_dice(k)` = 6^k. (Result Type: `int`)
- `n_omega_two_step_draw(N1, N2)` = N1 * N2. (Result Type: `int`)

### 3.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---

## 4. SUBTOPIC 1.3: `event_subset` (Biến Cố & Tập Con)

### 4.1 Canonical Knowledge & Definitions
- **Biến Cố A**: Tập con của không gian mẫu Omega (A subseteq Omega).
- **Kết Quả Thuận Lợi n(A)**: Số lượng phần tử thuộc tập A.

### 4.2 Allowed Concepts & Terminology
- Biến cố, tập con, kết quả thuận lợi, n(A), số chẵn, số lẻ, số nguyên tố, số chia hết cho k.

### 4.3 Forbidden Concepts (Anti-Leakage)
- Phép toán hợp A u B, phép toán giao A n B, tính P(A), công thức tổ hợp.

### 4.4 Common Misconceptions & Distractor Logic
- `MISC_ES_01`: Coi số 1 là số nguyên tố khi liệt kê kết quả thuận lợi.
- `MISC_ES_02`: Đếm thiếu hoặc đếm trùng phần tử thỏa mãn điều kiện biến cố.

### 4.5 Difficulty Guidance
- **Difficulty 1**: Nhận biết tập hợp kết quả thuận lợi A cho biến cố điều kiện đơn lẻ (mặt chẵn/lẻ).
- **Difficulty 2**: Tính n(A) cho biến cố điều kiện số học (số chấm > k, số nguyên tố <= 10).
- **Difficulty 3**: Liệt kê và tính n(A) khi rút thẻ từ tập N in {10, 12, 15, 20}.

### 4.6 Parameter Domains & Mutation Boundaries
- `dice_condition`: `odd` (n(A) = 3), `even` (n(A) = 3), `greater_than_k` (k in {2, 3, 4, 5}), `prime` (n(A) = 3: {2,3,5}).
- `card_number_range`: 1..N với N in {6, 8, 10, 12, 15, 20}.

### 4.7 Seed Families & Reference Mappings
- `q_d1_03_1` (MC), `q_d1_03_2` (Input), `q_d1_03_3` (Matching), `q_d1_03_4` (DragDrop), `q_d1_03_5` (Input).

### 4.8 Deterministic Answer Rules
- `n_favorable_dice_odd()` = 3; `n_favorable_dice_even()` = 3; `n_favorable_dice_prime()` = 3. (Result Type: `int`)
- `n_favorable_dice_gt(k)` = 6 - k. (Result Type: `int`)
- `n_favorable_range_prime(N)` = count of primes in 1..N. (Result Type: `int`)

### 4.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---

## 5. SUBTOPIC 1.4: `event_classification` (Phân Loại Biến Cố)

### 5.1 Canonical Knowledge & Definitions
- **Biến Cố Không Thể (EmptySet)**: Biến cố không bao giờ xảy ra, n(EmptySet) = 0.
- **Biến Cố Chắc Chắn (Omega)**: Biến cố luôn luôn xảy ra trong mọi lượt thử, n(Omega) = |Omega|.
- **Biến Cố Ngẫu Nhiên**: Biến cố có thể xảy ra hoặc không xảy ra tùy thuộc kết quả phép thử.

### 5.2 Allowed Concepts & Terminology
- Biến cố không thể, tập rỗng EmptySet, biến cố chắc chắn, không gian mẫu Omega, biến cố ngẫu nhiên.

### 5.3 Forbidden Concepts (Anti-Leakage)
- Xác suất P(EmptySet)=0, P(Omega)=1 (chưa giới thiệu phân số xác suất trong D1), biến cố đối A_bar.

### 5.4 Common Misconceptions & Distractor Logic
- `MISC_EC_01`: Nhầm biến cố chắc chắn với biến cố ngẫu nhiên có khả năng cao.
- `MISC_EC_02`: Nhầm biến cố không thể với biến cố ngẫu nhiên có khả năng thấp.

### 5.5 Difficulty Guidance
- **Difficulty 1**: Phân loại biến cố đơn giản (xuất hiện 7 chấm khi gieo xúc xắc 6 mặt là Không Thể).
- **Difficulty 2**: Phân loại biến cố chắc chắn vs ngẫu nhiên vs không thể trên tập số 1..N.
- **Difficulty 3**: Ghép 3 loại biến cố (Không thể, Chắc chắn, Ngẫu nhiên) với các mệnh đề số học.

### 5.6 Parameter Domains & Mutation Boundaries
- `dice_faces`: 6 mặt (1..6).
- `card_range`: 1..N (N in {6, 8, 10, 12}).

### 5.7 Seed Families & Reference Mappings
- `q_d1_04_1` (MC), `q_d1_04_2` (Input), `q_d1_04_3` (DragDrop), `q_d1_04_4` (Matching), `q_d1_04_5` (Input).

### 5.8 Deterministic Answer Rules
- `classify_event(n_fav, n_total)`: If n_fav == 0 return "impossible"; If n_fav == n_total return "certain"; Else return "random". (Result Type: `String`)

### 5.9 Legal Interaction Types
- `multiple_choice`, `matching`, `drag_drop`, `input`.

---

## 6. SUBTOPIC 1.5: `counting_outcomes` (Đếm Số Kết Quả - Stage 1.5 Canonical Scope)

### 6.1 Canonical Knowledge & Definitions
- **Đếm Số Kết Quả Thuận Lợi n(A) qua Liệt Kê Trực Tiếp**: Liệt kê hệ thống tất cả các cặp kết quả (x, y) hoặc chuỗi kết quả thỏa mãn điều kiện đề bài cho phép thử nhỏ với n(Omega) <= 36. Nghiêm cấm sử dụng bất kỳ công thức đại số tổ hợp/chỉnh hợp nào.

### 6.2 Allowed Concepts & Terminology
- Tổng số chấm 2 xúc xắc (x+y=S), liệt kê cặp ordered pairs (x,y), liệt kê dãy sấp ngửa 3 đồng xu (SSS, SSN, ...), liệt kê trực tiếp cặp bi được chọn từ bình nhỏ bằng tập hợp phần tử phân biệt {R1, R2, B1, B2}.
- **Exact Urn Draw Semantics**: Rút ngẫu nhiên đồng thời 2 bi **không hoàn lại** (without replacement), thứ tự cặp bi **không quan trọng** (unordered pair {bi_1, bi_2}).

### 6.3 Forbidden Concepts (Anti-Leakage)
- Phân số xác suất P(A), quy tắc cộng/nhân xác suất, D4 probability independence, công thức tổ hợp C_n^k, chỉnh hợp A_n^k, hoán vị P_n.

### 6.4 Common Misconceptions & Distractor Logic
- `MISC_CO_01`: Quên tính hoán vị cặp (x,y) khi x != y (vd: đếm tổng bằng 5 chỉ đếm (1,4) và (2,3) thiếu (4,1) và (3,2)).
- `MISC_CO_02`: Nhầm lẫn giữa phép thử gieo k đồng xu với gieo k con xúc xắc.

### 6.5 Difficulty Guidance
- **Difficulty 2**: Tính n(Omega) hoặc n(A) cho 3 đồng xu (n(Omega) = 2^3 = 8) bằng cách liệt kê trực tiếp dãy {SSS, SSN, SNS, NSS, SNN, NSN, NNS, NNN}.
- **Difficulty 3**: Đếm số cặp (x,y) khi gieo 2 con xúc xắc 6 mặt có tổng x+y = S (S in {3, 4, 5, 6, 7, 8, 9, 10, 11}) bằng cách liệt kê toàn bộ các cặp (x,y) in {1..6}^2.
- **Difficulty 4**: Liệt kê trực tiếp các cặp bi cùng màu từ bình chứa 3 bi đỏ {R1, R2, R3} và 2 bi xanh {B1, B2} (Tổng số cặp không thứ tự là 10 <= 36).

### 6.6 Parameter Domains & Mutation Boundaries
- `dice_sum_target`: S in {3, 4, 5, 6, 7, 8, 9, 10, 11}
- `coin_flip_heads_target`: k in {2, 3} trong 3 lần gieo
- `urn_red_balls`: R in {2, 3}, `urn_blue_balls`: B in {2, 3} (R + B <= 5)

### 6.7 Seed Families & Reference Mappings
- `q_d1_05_1` (MC), `q_d1_05_2` (Input), `q_d1_05_3` (DragDrop), `q_d1_05_4` (Matching), `q_d1_05_5` (Input).

### 6.8 Deterministic Answer Rules
- `count_dice_sum(S)`: (Result Type: `int`)
  - 1. Enumerate all ordered pairs (x,y) where 1 <= x <= 6 and 1 <= y <= 6.
  - 2. Retain pairs where x + y = S.
  - 3. Return integer count:
    - S=3 -> 2  [(1,2), (2,1)]
    - S=4 -> 3  [(1,3), (2,2), (3,1)]
    - S=5 -> 4  [(1,4), (2,3), (3,2), (4,1)]
    - S=6 -> 5  [(1,5), (2,4), (3,3), (4,2), (5,1)]
    - S=7 -> 6  [(1,6), (2,5), (3,4), (4,3), (5,2), (6,1)]
    - S=8 -> 5  [(2,6), (3,5), (4,4), (5,3), (6,2)]
    - S=9 -> 4  [(3,6), (4,5), (5,4), (6,3)]
    - S=10 -> 3 [(4,6), (5,5), (6,4)]
    - S=11 -> 2 [(5,6), (6,5)]

- `count_coin_at_least_heads(k_heads, total_flips)`: (Result Type: `int`)
  - Enumerate all sequences in {S, N}^total_flips.
  - Count sequences containing >= k_heads 'S'.
  - Return integer count.

- `count_same_color_pairs_enumeration(R, B)`: (Result Type: `int`)
  - Model: Unordered 2-ball draw without replacement.
  - 1. Construct finite set of distinct ball identities: {R1, ..., RR, B1, ..., BB}.
  - 2. Enumerate every legal unordered 2-ball pair explicitly (order does not matter).
  - 3. Classify each pair by color (both R or both B).
  - 4. Count same-color pairs and return integer (e.g. R=3, B=2: red pairs {R1R2, R1R3, R2R3} = 3; blue pairs {B1B2} = 1; total = 4).

### 6.9 Legal Interaction Types
- `multiple_choice`, `input`, `matching`, `drag_drop`.

---
