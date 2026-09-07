class_name TestMathContentRenderer
extends SceneTree

## Unit tests for MathContentRenderer (MATHOS-P1-MATH-CONTENT-RENDERER-083)
## Validates normalization of LaTeX-like math expressions, symbols, delimiters,
## and protects Vietnamese diacritics and text integrity.

const MathContentRenderer = preload("res://src/ui/common/math/math_content_renderer.gd")

var passed_count: int = 0
var failed_count: int = 0

func _initialize() -> void:
	var ok: bool = run_all_tests()
	if ok:
		quit(0)
	else:
		quit(1)

static func run_tests_for_runner() -> bool:
	var script_res: GDScript = load("res://tests/unit/presentation/test_math_content_renderer.gd") as GDScript
	var runner = script_res.new()
	return runner.run_all_tests()

func run_all_tests() -> bool:
	passed_count = 0
	failed_count = 0

	print("--- RUNNING SUITE: MathContentRenderer ---")
	test_omega_symbol()
	test_n_omega()
	test_n_a()
	test_empty_set()
	test_less_than_or_equal()
	test_escaped_braces()
	test_mixed_vietnamese_math()
	test_unclosed_dollar()
	test_unknown_command_fallback()
	test_multiple_symbols()
	test_vietnamese_plain_text_regression_guard()
	test_fractions_and_text_macros()
	test_complement_overline()
	test_multiplication_clean()
	test_multiplication_tab_artifact()
	test_combinatorics_sub_superscripts()
	test_real_content_normalization()

	print("MATH CONTENT RENDERER SUMMARY: PASS %d / FAIL %d" % [passed_count, failed_count])
	return failed_count == 0

func _assert_eq(actual: String, expected: String, test_name: String) -> void:
	if actual == expected:
		passed_count += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_count += 1
		print("  [FAIL] %s: Expected '%s', got '%s'" % [test_name, expected, actual])

func test_omega_symbol() -> void:
	var raw: String = "Không gian mẫu $\\Omega$ của phép thử"
	var rendered: String = MathContentRenderer.render(raw)
	_assert_eq(rendered, "Không gian mẫu Ω của phép thử", "test_omega_symbol")

func test_n_omega() -> void:
	var raw: String = "Số phần tử $n(\\Omega) = 36$"
	var rendered: String = MathContentRenderer.render(raw)
	_assert_eq(rendered, "Số phần tử n(Ω) = 36", "test_n_omega")

func test_n_a() -> void:
	var raw: String = "Biến cố $A$ có $n(A) = 3$"
	var rendered: String = MathContentRenderer.render(raw)
	_assert_eq(rendered, "Biến cố A có n(A) = 3", "test_n_a")

func test_empty_set() -> void:
	var raw: String = "Tập rỗng $\\emptyset$ không có phần tử"
	var rendered: String = MathContentRenderer.render(raw)
	_assert_eq(rendered, "Tập rỗng ∅ không có phần tử", "test_empty_set")

func test_less_than_or_equal() -> void:
	var raw: String = "Số chấm $\\le 6$"
	var rendered: String = MathContentRenderer.render(raw)
	_assert_eq(rendered, "Số chấm ≤ 6", "test_less_than_or_equal")

func test_escaped_braces() -> void:
	var raw: String = "Tập hợp $\\Omega = \\{1, 2, 3, 4, 5, 6\\}$"
	var rendered: String = MathContentRenderer.render(raw)
	_assert_eq(rendered, "Tập hợp Ω = {1, 2, 3, 4, 5, 6}", "test_escaped_braces")

func test_mixed_vietnamese_math() -> void:
	var raw: String = "Xác suất của biến cố $A$ là $P(A) = \\frac{n(A)}{n(\\Omega)}$."
	var rendered: String = MathContentRenderer.render(raw)
	_assert_eq(rendered, "Xác suất của biến cố A là P(A) = n(A)/n(Ω).", "test_mixed_vietnamese_math")

func test_unclosed_dollar() -> void:
	var unclosed: String = "Giá trị là $n(\\Omega) và còn tiếp"
	var r1: String = MathContentRenderer.render(unclosed)
	_assert_eq(r1, "Giá trị là n(Ω) và còn tiếp", "test_unclosed_dollar")

func test_unknown_command_fallback() -> void:
	var unknown_cmd: String = "Công thức $\\unknownCommand{123}$"
	var r2: String = MathContentRenderer.render(unknown_cmd)
	_assert_eq(r2, "Công thức unknownCommand 123", "test_unknown_command_fallback")

func test_multiple_symbols() -> void:
	var raw: String = "$A \\cap B = \\emptyset \\implies P(A \\cap B) = 0$"
	var rendered: String = MathContentRenderer.render(raw)
	_assert_eq(rendered, "A ∩ B = ∅ ⇒ P(A ∩ B) = 0", "test_multiple_symbols")

func test_vietnamese_plain_text_regression_guard() -> void:
	var vn_text: String = "Gieo một con xúc xắc cân đối và đồng chất. Hãy xác định không gian mẫu."
	var rendered: String = MathContentRenderer.render(vn_text)
	_assert_eq(rendered, vn_text, "test_vietnamese_plain_text_regression_guard")

func test_fractions_and_text_macros() -> void:
	var raw1: String = "$P(A) = \\frac{1}{6}$"
	var r1: String = MathContentRenderer.render(raw1)
	_assert_eq(r1, "P(A) = 1/6", "test_simple_fraction")

	var raw2: String = "$C_6^2 = \\frac{6 \\times 5}{2} = 15$"
	var r2: String = MathContentRenderer.render(raw2)
	_assert_eq(r2, "C_6^2 = (6 × 5)/2 = 15", "test_compound_fraction")

	var raw3: String = "$P(\\text{thất bại}) = 0.2$"
	var r3: String = MathContentRenderer.render(raw3)
	_assert_eq(r3, "P(thất bại) = 0.2", "test_text_macro")

func test_complement_overline() -> void:
	var raw: String = "$P(\\overline{A}) = 1 - P(A)$"
	var rendered: String = MathContentRenderer.render(raw)
	var expected: String = "P(A" + MathContentRenderer.COMBINING_OVERLINE + ") = 1 - P(A)"
	_assert_eq(rendered, expected, "test_complement_overline")

func test_multiplication_clean() -> void:
	var raw1: String = "$10 \\times 4 = 40$"
	var r1: String = MathContentRenderer.render(raw1)
	_assert_eq(r1, "10 × 4 = 40", "test_multiplication_clean")

func test_multiplication_tab_artifact() -> void:
	var raw2: String = "$n(\\Omega) = 2 \times 3 = 6$"
	var r2: String = MathContentRenderer.render(raw2)
	_assert_eq(r2, "n(Ω) = 2 × 3 = 6", "test_multiplication_tab_artifact")

func test_combinatorics_sub_superscripts() -> void:
	var raw: String = "$n(\\Omega) = C_{10}^2 = 45$"
	var rendered: String = MathContentRenderer.render(raw)
	_assert_eq(rendered, "n(Ω) = C_10^2 = 45", "test_combinatorics_sub_superscripts")

func test_real_content_normalization() -> void:
	var q_path: String = "res://content/questions/questions.json"
	if not FileAccess.file_exists(q_path):
		passed_count += 1
		print("  [PASS] test_real_content_normalization (content file not present, skipped)")
		return

	var file: FileAccess = FileAccess.open(q_path, FileAccess.READ)
	if file == null:
		failed_count += 1
		print("  [FAIL] test_real_content_normalization: Could not open questions.json")
		return

	var json_str: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_str) != OK:
		failed_count += 1
		print("  [FAIL] test_real_content_normalization: JSON parse error in questions.json")
		return

	var q_list: Variant = json.data
	if not (q_list is Array):
		failed_count += 1
		print("  [FAIL] test_real_content_normalization: questions.json root is not Array")
		return

	var all_clean: bool = true
	var checked_count: int = 0
	for item in (q_list as Array):
		if not (item is Dictionary):
			continue
		var q: Dictionary = item as Dictionary
		var prompt: String = String(q.get("prompt", ""))
		var rendered: String = MathContentRenderer.render(prompt)
		checked_count += 1

		# Check for unhandled raw LaTeX patterns leaking
		if rendered.contains("$\\Omega$") or rendered.contains("$\\emptyset$") or rendered.contains("$\\le") or rendered.contains("\\{") or rendered.contains("\\}"):
			all_clean = false
			print("  [FAIL] Prompt leaked raw markup: %s" % rendered)
			break

	if all_clean:
		passed_count += 1
		print("  [PASS] test_real_content_normalization (%d questions validated)" % checked_count)
	else:
		failed_count += 1
