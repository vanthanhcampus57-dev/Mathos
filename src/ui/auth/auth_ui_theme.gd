class_name AuthUiTheme
extends RefCounted

## Styling and Theme Helper for Mathos Production Auth UI.
## Implements the Dark Fantasy Academic RPG visual direction using MathosTokens.

const MathosTokensClass = preload("res://src/ui/theme/mathos_tokens.gd")

# Custom Academy Auth Color Palette
const COLOR_AUTH_PANEL_BG: Color = Color(0.055, 0.08, 0.125, 0.94) # #0e1420 - Deep navy parchment
const COLOR_AUTH_PANEL_BORDER: Color = Color(0.18, 0.35, 0.52, 0.55) # Arcane cyan-slate border
const COLOR_AUTH_PANEL_BORDER_HIGHLIGHT: Color = Color(0.96, 0.77, 0.26, 0.40) # Restrained gold rim

const COLOR_INPUT_BG: Color = Color(0.08, 0.11, 0.17, 0.95) # Dark input field
const COLOR_INPUT_BORDER_NORMAL: Color = Color(0.20, 0.28, 0.40, 0.80)
const COLOR_INPUT_BORDER_HOVER: Color = Color(0.35, 0.60, 0.85, 0.90)
const COLOR_INPUT_BORDER_FOCUS: Color = Color(0.22, 0.74, 0.97, 1.0) # Mana Cyan focus glow

const COLOR_GOLD_PRIMARY: Color = Color(0.96, 0.77, 0.26, 1.0) # Arcane Gold
const COLOR_GOLD_HOVER: Color = Color(1.0, 0.85, 0.38, 1.0)
const COLOR_GOLD_PRESSED: Color = Color(0.82, 0.63, 0.18, 1.0)
const COLOR_GOLD_DISABLED: Color = Color(0.40, 0.33, 0.15, 0.50)

const COLOR_SECONDARY_BG: Color = Color(0.11, 0.16, 0.25, 0.90)
const COLOR_SECONDARY_HOVER: Color = Color(0.15, 0.22, 0.34, 0.95)
const COLOR_SECONDARY_PRESSED: Color = Color(0.09, 0.13, 0.20, 1.0)

const COLOR_CYAN_ACCENT: Color = Color(0.25, 0.75, 0.98, 1.0)
const COLOR_CYAN_MUTED: Color = Color(0.40, 0.65, 0.85, 0.80)
const COLOR_TEXT_TITLE: Color = Color(0.98, 0.98, 1.0, 1.0)
const COLOR_TEXT_BODY: Color = Color(0.88, 0.91, 0.95, 1.0)
const COLOR_TEXT_MUTED: Color = Color(0.55, 0.62, 0.72, 1.0)
const COLOR_TEXT_DARK: Color = Color(0.05, 0.07, 0.10, 1.0) # Text on Gold button
const COLOR_ERROR_TEXT: Color = Color(1.0, 0.40, 0.40, 1.0) # Restrained Red
const COLOR_SUCCESS_TEXT: Color = Color(0.25, 0.85, 0.55, 1.0) # Emerald Success

## Creates main right-hand authentication panel container stylebox.
static func create_auth_panel_stylebox() -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = COLOR_AUTH_PANEL_BG
	s.border_width_left = 1
	s.border_width_top = 2
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = COLOR_AUTH_PANEL_BORDER
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_right = 16
	s.corner_radius_bottom_left = 16
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	s.shadow_size = 18
	s.shadow_offset = Vector2(-4, 6)
	return s

## Creates standard LineEdit field stylebox for normal, focus, and hover states.
static func create_input_stylebox(state: String) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = COLOR_INPUT_BG
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_right = 8
	s.corner_radius_bottom_left = 8
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10

	match state:
		"focus":
			s.border_width_left = 2
			s.border_width_top = 2
			s.border_width_right = 2
			s.border_width_bottom = 2
			s.border_color = COLOR_INPUT_BORDER_FOCUS
			s.shadow_color = Color(0.22, 0.74, 0.97, 0.35)
			s.shadow_size = 4
		"hover":
			s.border_width_left = 1
			s.border_width_top = 1
			s.border_width_right = 1
			s.border_width_bottom = 1
			s.border_color = COLOR_INPUT_BORDER_HOVER
		_: # normal
			s.border_width_left = 1
			s.border_width_top = 1
			s.border_width_right = 1
			s.border_width_bottom = 1
			s.border_color = COLOR_INPUT_BORDER_NORMAL

	return s

## Applies input styleboxes and colors to a LineEdit.
static func style_line_edit(line_edit: LineEdit) -> void:
	if line_edit == null:
		return
	line_edit.add_theme_stylebox_override("normal", create_input_stylebox("normal"))
	line_edit.add_theme_stylebox_override("focus", create_input_stylebox("focus"))
	line_edit.add_theme_stylebox_override("hover", create_input_stylebox("hover"))
	line_edit.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.42, 0.48, 0.58, 0.70))
	line_edit.add_theme_color_override("caret_color", COLOR_CYAN_ACCENT)
	line_edit.add_theme_font_size_override("font_size", 14)

## Creates Primary (Arcane Gold) button stylebox for each state.
static func create_primary_button_stylebox(state: String) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_right = 8
	s.corner_radius_bottom_left = 8
	s.content_margin_top = 10
	s.content_margin_bottom = 10

	match state:
		"hover":
			s.bg_color = COLOR_GOLD_HOVER
			s.border_width_left = 2
			s.border_width_top = 2
			s.border_width_right = 2
			s.border_width_bottom = 2
			s.border_color = COLOR_CYAN_ACCENT
			s.shadow_color = Color(0.96, 0.77, 0.26, 0.45)
			s.shadow_size = 6
		"pressed":
			s.bg_color = COLOR_GOLD_PRESSED
			s.border_width_left = 1
			s.border_width_top = 1
			s.border_width_right = 1
			s.border_width_bottom = 1
			s.border_color = COLOR_GOLD_PRESSED
		"disabled":
			s.bg_color = COLOR_GOLD_DISABLED
			s.border_color = Color(0, 0, 0, 0)
		_: # normal
			s.bg_color = COLOR_GOLD_PRIMARY
			s.border_width_left = 1
			s.border_width_top = 1
			s.border_width_right = 1
			s.border_width_bottom = 1
			s.border_color = Color(1.0, 0.88, 0.45, 0.8)
			s.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
			s.shadow_size = 4
	return s

## Applies Primary (Gold) button styling.
static func style_primary_button(btn: Button) -> void:
	if btn == null:
		return
	btn.add_theme_stylebox_override("normal", create_primary_button_stylebox("normal"))
	btn.add_theme_stylebox_override("hover", create_primary_button_stylebox("hover"))
	btn.add_theme_stylebox_override("pressed", create_primary_button_stylebox("pressed"))
	btn.add_theme_stylebox_override("disabled", create_primary_button_stylebox("disabled"))
	btn.add_theme_stylebox_override("focus", create_primary_button_stylebox("hover"))
	btn.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	btn.add_theme_color_override("font_hover_color", COLOR_TEXT_DARK)
	btn.add_theme_color_override("font_pressed_color", COLOR_TEXT_DARK)
	btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.25, 0.15, 0.7))
	btn.add_theme_font_size_override("font_size", 14)

## Creates Secondary (Navy Surface) button stylebox.
static func create_secondary_button_stylebox(state: String) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_right = 8
	s.corner_radius_bottom_left = 8
	s.content_margin_top = 10
	s.content_margin_bottom = 10

	match state:
		"hover":
			s.bg_color = COLOR_SECONDARY_HOVER
			s.border_width_left = 1
			s.border_width_top = 1
			s.border_width_right = 1
			s.border_width_bottom = 1
			s.border_color = COLOR_CYAN_ACCENT
			s.shadow_color = Color(0.22, 0.74, 0.97, 0.25)
			s.shadow_size = 4
		"pressed":
			s.bg_color = COLOR_SECONDARY_PRESSED
			s.border_width_left = 1
			s.border_width_top = 1
			s.border_width_right = 1
			s.border_width_bottom = 1
			s.border_color = COLOR_INPUT_BORDER_FOCUS
		"disabled":
			s.bg_color = Color(0.08, 0.11, 0.17, 0.50)
			s.border_color = Color(0.15, 0.20, 0.30, 0.40)
		_: # normal
			s.bg_color = COLOR_SECONDARY_BG
			s.border_width_left = 1
			s.border_width_top = 1
			s.border_width_right = 1
			s.border_width_bottom = 1
			s.border_color = COLOR_INPUT_BORDER_NORMAL
	return s

## Applies Secondary button styling.
static func style_secondary_button(btn: Button) -> void:
	if btn == null:
		return
	btn.add_theme_stylebox_override("normal", create_secondary_button_stylebox("normal"))
	btn.add_theme_stylebox_override("hover", create_secondary_button_stylebox("hover"))
	btn.add_theme_stylebox_override("pressed", create_secondary_button_stylebox("pressed"))
	btn.add_theme_stylebox_override("disabled", create_secondary_button_stylebox("disabled"))
	btn.add_theme_stylebox_override("focus", create_secondary_button_stylebox("hover"))
	btn.add_theme_color_override("font_color", COLOR_TEXT_TITLE)
	btn.add_theme_color_override("font_hover_color", COLOR_CYAN_ACCENT)
	btn.add_theme_color_override("font_pressed_color", COLOR_TEXT_TITLE)
	btn.add_theme_color_override("font_disabled_color", COLOR_TEXT_MUTED)
	btn.add_theme_font_size_override("font_size", 13)

## Styles a subtle text/action button (e.g. Guest mode, Forgot Password, Back).
static func style_text_button(btn: Button, accent_cyan: bool = false) -> void:
	if btn == null:
		return
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	btn.add_theme_stylebox_override("focus", empty)

	var normal_color: Color = COLOR_CYAN_ACCENT if accent_cyan else COLOR_TEXT_MUTED
	var hover_color: Color = Color(1.0, 0.88, 0.45, 1.0) if accent_cyan else COLOR_CYAN_ACCENT
	btn.add_theme_color_override("font_color", normal_color)
	btn.add_theme_color_override("font_hover_color", hover_color)
	btn.add_theme_color_override("font_pressed_color", normal_color)
	btn.add_theme_color_override("font_disabled_color", Color(0.35, 0.40, 0.50, 0.50))
	btn.add_theme_font_size_override("font_size", 12)

## Creates an elegant rune divider with left/right gradient lines and center rune.
static func create_rune_divider(text: String = "HOẶC · OR") -> HBoxContainer:
	var h: HBoxContainer = HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.custom_minimum_size = Vector2(0, 20)

	var left_line: ColorRect = ColorRect.new()
	left_line.custom_minimum_size = Vector2(60, 1)
	left_line.color = Color(0.25, 0.45, 0.65, 0.35)
	left_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(left_line)

	var lbl: Label = Label.new()
	lbl.text = "  %s  " % text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.45, 0.65, 0.85, 0.70))
	h.add_child(lbl)

	var right_line: ColorRect = ColorRect.new()
	right_line.custom_minimum_size = Vector2(60, 1)
	right_line.color = Color(0.25, 0.45, 0.65, 0.35)
	right_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(right_line)

	return h
