class_name MathContentRenderer
extends RefCounted

## Generic normalization and rendering engine for mathematical and scientific notation.
## Converts LaTeX-like markup, delimiters, and symbols into clean, readable Unicode strings.
## Safe fallback ensures unknown markup is unwrapped without crashing or corrupting text.
## 100% preserves Vietnamese diacritics and plain text content.

const PLACEHOLDER_OPEN_BRACE: String = "\uE000"
const PLACEHOLDER_CLOSE_BRACE: String = "\uE001"
const COMBINING_OVERLINE: String = "\u0305"

# Ordered list of symbol replacements: longer commands first to prevent partial substring collision.
const SYMBOL_REPLACEMENTS: Array[Array] = [
	["\\subseteq", "⊆"],
	["\\supseteq", "⊇"],
	["\\emptyset", "∅"],
	["\\setminus", "\\"],
	["\\rightarrow", "→"],
	["\\leftarrow", "←"],
	["\\implies", "⇒"],
	["\\approx", "≈"],
	["\\forall", "∀"],
	["\\exists", "∃"],
	["\\subset", "⊂"],
	["\\supset", "⊃"],
	["\\notin", "∉"],
	["\\cdots", "…"],
	["\\ldots", "…"],
	["\\Omega", "Ω"],
	["\\omega", "ω"],
	["\\Delta", "Δ"],
	["\\delta", "δ"],
	["\\Sigma", "Σ"],
	["\\sigma", "σ"],
	["\\alpha", "α"],
	["\\beta", "β"],
	["\\gamma", "γ"],
	["\\theta", "θ"],
	["\\lambda", "λ"],
	["\\times", "×"],
	["\\cdot", "·"],
	["\\dots", "…"],
	["\\iff", "⇔"],
	["\\neq", "≠"],
	["\\leq", "≤"],
	["\\geq", "≥"],
	["\\cap", "∩"],
	["\\cup", "∪"],
	["\\mid", "|"],
	["\\pm", "±"],
	["\\mp", "∓"],
	["\\mu", "μ"],
	["\\pi", "π"],
	["\\in", "∈"],
	["\\ne", "≠"],
	["\\le", "≤"],
	["\\ge", "≥"],
	["\\to", "→"],
]

## Main entry point: render authored text into normalized player-facing presentation text.
static func render(text: String) -> String:
	if text.is_empty():
		return ""

	var result: String = text

	# 0. Clean JSON unescaped control character artifacts (\t and \n before TeX names)
	result = _clean_unescaped_json_artifacts(result)

	# 1. Process display math blocks: $$...$$
	result = _process_delimiters(result, "$$", "$$", false)

	# 2. Process display math blocks: \[...\]
	result = _process_delimiters(result, "\\[", "\\]", false)

	# 3. Process inline math blocks: \(...\)
	result = _process_delimiters(result, "\\(", "\\)", false)

	# 4. Process inline math blocks: $...$
	result = _process_inline_dollars(result)

	# 5. Process any remaining un-delimited math symbols or LaTeX commands in plain text
	result = normalize_math(result, true)

	return result

## Normalizes an individual mathematical expression into clean Unicode.
## When is_outer_text is true, only explicit LaTeX commands and escaped braces are replaced,
## preserving normal words and punctuation.
static func normalize_math(expr: String, is_outer_text: bool = false) -> String:
	if expr.is_empty():
		return ""

	var s: String = expr

	# 0. Clean JSON artifacts
	s = _clean_unescaped_json_artifacts(s)

	# 1. Protect literal escaped braces: \{ and \} -> placeholders
	s = s.replace("\\{", PLACEHOLDER_OPEN_BRACE)
	s = s.replace("\\}", PLACEHOLDER_CLOSE_BRACE)

	# 2. Process text macros: \text{...}, \textbf{...}, \textit{...}, \mathrm{...}
	s = _process_text_macros(s)

	# 3. Process fractions: \frac{num}{den}
	s = _process_fractions(s)

	# 4. Process overline: \overline{...}
	s = _process_overlines(s)

	# 5. Process combinatorics braces: C_{10}^2 -> C_10^2, C_n^k, etc.
	s = _process_sub_superscripts(s)

	# 6. Replace all known LaTeX mathematical symbols
	s = _replace_symbols(s)

	# 7. Safe fallback: unwrap unrecognized commands with arguments: \cmd{arg} -> cmd arg
	s = _strip_unrecognized_commands(s)

	# 8. Unwrap any remaining TeX grouping braces: {x} -> x (only if inside math, not outer text)
	if not is_outer_text:
		s = _unwrap_grouping_braces(s)

	# 9. Restore protected literal set braces: placeholders -> { and }
	s = s.replace(PLACEHOLDER_OPEN_BRACE, "{")
	s = s.replace(PLACEHOLDER_CLOSE_BRACE, "}")

	# 10. Clean redundant whitespace within math expressions
	if not is_outer_text:
		s = _clean_math_spacing(s)

	return s

# --- Private Helper Methods ---

static func _clean_unescaped_json_artifacts(s: String) -> String:
	var res: String = s
	# When \times was authored with a single backslash in JSON, it decodes to tab (ASCII 9) + "imes"
	res = res.replace("\times", "\\times")
	# When \text was authored with a single backslash in JSON, it decodes to tab (ASCII 9) + "ext"
	res = res.replace("\text", "\\text")
	# When \neq was authored with a single backslash in JSON, it decodes to newline (ASCII 10) + "eq"
	res = res.replace("\neq", "\\neq")
	# When \notin was authored with a single backslash in JSON, it decodes to newline (ASCII 10) + "otin"
	res = res.replace("\notin", "\\notin")
	return res

static func _process_delimiters(s: String, open_delim: String, close_delim: String, is_display: bool) -> String:
	var out: String = ""
	var cursor: int = 0
	var len_s: int = s.length()
	var open_len: int = open_delim.length()
	var close_len: int = close_delim.length()

	while cursor < len_s:
		var open_pos: int = s.find(open_delim, cursor)
		if open_pos == -1:
			out += s.substr(cursor)
			break

		out += s.substr(cursor, open_pos - cursor)
		var inner_start: int = open_pos + open_len
		var close_pos: int = s.find(close_delim, inner_start)
		if close_pos == -1:
			# Unclosed delimiter: safe fallback, strip open delimiter and normalize remainder
			out += normalize_math(s.substr(inner_start), false)
			break

		var inner_expr: String = s.substr(inner_start, close_pos - inner_start)
		var normalized: String = normalize_math(inner_expr, false)
		out += normalized
		cursor = close_pos + close_len

	return out

static func _process_inline_dollars(s: String) -> String:
	var out: String = ""
	var cursor: int = 0
	var len_s: int = s.length()

	while cursor < len_s:
		var open_pos: int = s.find("$", cursor)
		if open_pos == -1:
			out += s.substr(cursor)
			break

		# Check for escaped dollar: \$
		if open_pos > 0 and s[open_pos - 1] == "\\":
			out += s.substr(cursor, open_pos - 1 - cursor) + "$"
			cursor = open_pos + 1
			continue

		out += s.substr(cursor, open_pos - cursor)
		var inner_start: int = open_pos + 1
		var close_pos: int = s.find("$", inner_start)
		if close_pos == -1:
			# Unclosed dollar: if followed by math character or backslash, treat as unclosed delimiter
			if inner_start < len_s and (s[inner_start] == "\\" or (s[inner_start] >= "a" and s[inner_start] <= "z") or (s[inner_start] >= "A" and s[inner_start] <= "Z")):
				out += normalize_math(s.substr(inner_start), false)
			else:
				out += "$" + s.substr(inner_start)
			break

		var inner_expr: String = s.substr(inner_start, close_pos - inner_start)
		var normalized: String = normalize_math(inner_expr, false)
		out += normalized
		cursor = close_pos + 1

	return out

static func _process_text_macros(s: String) -> String:
	# Matches \text{...}, \textbf{...}, \textit{...}, \mathrm{...}
	var regex := RegEx.new()
	regex.compile("\\\\(?:text|textbf|textit|mathrm)\\s*\\{([^{}]*)\\}")
	var res: String = s
	var max_passes: int = 5
	while max_passes > 0 and regex.search(res) != null:
		res = regex.sub(res, "$1", true)
		max_passes -= 1
	return res

static func _process_fractions(s: String) -> String:
	# Matches \frac{num}{den}
	var regex := RegEx.new()
	regex.compile("\\\\frac\\s*\\{([^{}]*)\\}\\s*\\{([^{}]*)\\}")
	var res: String = s
	var max_passes: int = 5
	while max_passes > 0:
		var m := regex.search(res)
		if m == null:
			break
		var num: String = normalize_math(m.get_string(1), false).strip_edges()
		var den: String = normalize_math(m.get_string(2), false).strip_edges()

		# Determine if parentheses are needed for numerator or denominator
		var num_wrapped: String = num
		if _needs_parens_in_fraction(num):
			num_wrapped = "(%s)" % num

		var den_wrapped: String = den
		if _needs_parens_in_fraction(den):
			den_wrapped = "(%s)" % den

		var frac_str: String = "%s/%s" % [num_wrapped, den_wrapped]
		res = res.substr(0, m.get_start()) + frac_str + res.substr(m.get_end())
		max_passes -= 1
	return res

static func _needs_parens_in_fraction(expr: String) -> bool:
	if expr.contains("+") or expr.contains("-") or expr.contains("×") or expr.contains("·") or expr.contains("="):
		return not (expr.begins_with("(") and expr.ends_with(")"))
	return false

static func _process_overlines(s: String) -> String:
	# Matches \overline{...}
	var regex := RegEx.new()
	regex.compile("\\\\overline\\s*\\{([^{}]*)\\}")
	var res: String = s
	var max_passes: int = 5
	while max_passes > 0:
		var m := regex.search(res)
		if m == null:
			break
		var inner: String = normalize_math(m.get_string(1), false).strip_edges()
		var overline_str: String = ""
		if inner.length() == 1:
			overline_str = inner + COMBINING_OVERLINE
		elif inner.begins_with("(") and inner.ends_with(")"):
			overline_str = inner + COMBINING_OVERLINE
		else:
			overline_str = "(%s)%s" % [inner, COMBINING_OVERLINE]
		res = res.substr(0, m.get_start()) + overline_str + res.substr(m.get_end())
		max_passes -= 1
	return res

static func _process_sub_superscripts(s: String) -> String:
	# Normalizes C_{10}^2 -> C_10^2, A_{1} -> A_1, etc.
	var regex_sub := RegEx.new()
	regex_sub.compile("_\\{([^{}]+)\\}")
	var res: String = regex_sub.sub(s, "_$1", true)

	var regex_sup := RegEx.new()
	regex_sup.compile("\\^\\{([^{}]+)\\}")
	res = regex_sup.sub(res, "^$1", true)
	return res

static func _replace_symbols(s: String) -> String:
	var res: String = s
	for pair in SYMBOL_REPLACEMENTS:
		var cmd: String = pair[0] as String
		var sym: String = pair[1] as String

		# Check if cmd is preceded by backslash and followed by non-alpha to avoid prefix collisions
		var search_pos: int = 0
		while search_pos < res.length():
			var idx: int = res.find(cmd, search_pos)
			if idx == -1:
				break

			var after_idx: int = idx + cmd.length()
			var is_boundary: bool = true
			if after_idx < res.length():
				var next_char: String = res[after_idx]
				# If command name is followed immediately by an ASCII letter, it's a longer command
				if (next_char >= "a" and next_char <= "z") or (next_char >= "A" and next_char <= "Z"):
					is_boundary = false

			if is_boundary:
				res = res.substr(0, idx) + sym + res.substr(after_idx)
				search_pos = idx + sym.length()
			else:
				search_pos = after_idx

	return res

static func _unwrap_grouping_braces(s: String) -> String:
	# Unwraps non-escaped grouping braces like {10} or {S} in math context
	var regex := RegEx.new()
	regex.compile("\\{([^{}]+)\\}")
	var res: String = s
	var max_passes: int = 5
	while max_passes > 0 and regex.search(res) != null:
		res = regex.sub(res, "$1", true)
		max_passes -= 1
	return res

static func _strip_unrecognized_commands(s: String) -> String:
	var res: String = s
	# Safe fallback: unwrap unrecognized commands with arguments: \cmd{arg} -> cmd arg
	var regex_with_arg := RegEx.new()
	regex_with_arg.compile("\\\\([a-zA-Z]+)\\s*\\{([^{}]*)\\}")
	res = regex_with_arg.sub(res, "$1 $2", true)

	# Safe fallback: strip leading backslash from any unrecognized \commandName -> commandName
	var regex_simple := RegEx.new()
	regex_simple.compile("\\\\([a-zA-Z]+)")
	res = regex_simple.sub(res, "$1", true)
	return res

static func _clean_math_spacing(s: String) -> String:
	var regex_spaces := RegEx.new()
	regex_spaces.compile("[ \\t]{2,}")
	var cleaned: String = regex_spaces.sub(s, " ", true)
	return cleaned.strip_edges()
