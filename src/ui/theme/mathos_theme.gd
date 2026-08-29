class_name MathosTheme
extends RefCounted

## Factory and utility class for building the canonical Mathos Theme resource.
## Configures default Control styles and semantic Theme type variations:
## - Buttons: MathosPrimaryButton, MathosSecondaryButton, MathosDestructiveButton
## - Panels: MathosPanelPrimary, MathosPanelSecondary, MathosPanelElevated, MathosPanelModal, MathosCard, MathosOption
## - Labels: MathosTitle, MathosHeading, MathosSubtitle, MathosBody, MathosMeta, MathosSuccess, MathosError

static func create_theme() -> Theme:
	var theme: Theme = Theme.new()

	# --- DEFAULT FONT SIZES ---
	theme.set_default_font_size(MathosTokens.FONT_SIZE_BODY)

	# --- BASE STYLEBOXES ---
	var base_panel: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_PRIMARY, MathosTokens.BORDER_DEFAULT, 1, MathosTokens.RADIUS_MD, 12, 12, 12, 12)
	var focus_ring: StyleBoxFlat = _make_stylebox(Color(0, 0, 0, 0), MathosTokens.BORDER_FOCUS, 2, MathosTokens.RADIUS_MD, 4, 4, 4, 4)

	# Default PanelContainer
	theme.set_stylebox("panel", "PanelContainer", base_panel)

	# Default MarginContainer margins
	theme.set_constant("margin_left", "MarginContainer", MathosTokens.SPACING_LG)
	theme.set_constant("margin_top", "MarginContainer", MathosTokens.SPACING_LG)
	theme.set_constant("margin_right", "MarginContainer", MathosTokens.SPACING_LG)
	theme.set_constant("margin_bottom", "MarginContainer", MathosTokens.SPACING_LG)

	# Default VBoxContainer / HBoxContainer separation
	theme.set_constant("separation", "VBoxContainer", MathosTokens.SPACING_MD)
	theme.set_constant("separation", "HBoxContainer", MathosTokens.SPACING_MD)

	# Default Label
	theme.set_color("font_color", "Label", MathosTokens.TEXT_BODY)
	theme.set_font_size("font_size", "Label", MathosTokens.FONT_SIZE_BODY)

	# --- DEFAULT BUTTON STYLES ---
	var btn_normal: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_SECONDARY, MathosTokens.BORDER_DEFAULT, 1, MathosTokens.RADIUS_MD, 16, 10, 16, 10)
	var btn_hover: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_ELEVATED, MathosTokens.BORDER_HOVER, 2, MathosTokens.RADIUS_MD, 16, 10, 16, 10)
	var btn_pressed: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_PRIMARY, MathosTokens.COLOR_CYAN_PRESSED, 2, MathosTokens.RADIUS_MD, 16, 10, 16, 10)
	var btn_disabled: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_CARD, MathosTokens.BORDER_SUBTLE, 1, MathosTokens.RADIUS_MD, 16, 10, 16, 10)

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", focus_ring)
	theme.set_color("font_color", "Button", MathosTokens.TEXT_TITLE)
	theme.set_color("font_hover_color", "Button", MathosTokens.TEXT_TITLE)
	theme.set_color("font_pressed_color", "Button", MathosTokens.TEXT_TITLE)
	theme.set_color("font_disabled_color", "Button", MathosTokens.TEXT_DISABLED)

	# --- SEMANTIC BUTTON VARIATIONS ---

	# 1. MathosPrimaryButton (Arcane Gold)
	var primary_normal: StyleBoxFlat = _make_stylebox(MathosTokens.COLOR_GOLD_PRIMARY, MathosTokens.COLOR_GOLD_PRIMARY, 0, MathosTokens.RADIUS_MD, 20, 12, 20, 12)
	var primary_hover: StyleBoxFlat = _make_stylebox(MathosTokens.COLOR_GOLD_HOVER, MathosTokens.BORDER_FOCUS, 2, MathosTokens.RADIUS_MD, 20, 12, 20, 12)
	var primary_pressed: StyleBoxFlat = _make_stylebox(MathosTokens.COLOR_GOLD_PRESSED, MathosTokens.COLOR_GOLD_PRESSED, 0, MathosTokens.RADIUS_MD, 20, 12, 20, 12)
	var primary_disabled: StyleBoxFlat = _make_stylebox(MathosTokens.COLOR_GOLD_MUTED, Color(0, 0, 0, 0), 0, MathosTokens.RADIUS_MD, 20, 12, 20, 12)

	_apply_button_variation(theme, "MathosPrimaryButton", primary_normal, primary_hover, primary_pressed, primary_disabled, focus_ring, MathosTokens.TEXT_ON_ACCENT, MathosTokens.TEXT_ON_ACCENT, MathosTokens.TEXT_ON_ACCENT, MathosTokens.TEXT_DISABLED)

	# 2. MathosSecondaryButton (Mana Cyan / Surface Secondary)
	var secondary_normal: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_SECONDARY, MathosTokens.BORDER_DEFAULT, 1, MathosTokens.RADIUS_MD, 16, 10, 16, 10)
	var secondary_hover: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_ELEVATED, MathosTokens.BORDER_HOVER, 2, MathosTokens.RADIUS_MD, 16, 10, 16, 10)
	var secondary_pressed: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_PRIMARY, MathosTokens.COLOR_CYAN_PRESSED, 2, MathosTokens.RADIUS_MD, 16, 10, 16, 10)
	var secondary_disabled: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_CARD, MathosTokens.BORDER_SUBTLE, 1, MathosTokens.RADIUS_MD, 16, 10, 16, 10)

	_apply_button_variation(theme, "MathosSecondaryButton", secondary_normal, secondary_hover, secondary_pressed, secondary_disabled, focus_ring, MathosTokens.TEXT_TITLE, MathosTokens.COLOR_CYAN_HOVER, MathosTokens.TEXT_TITLE, MathosTokens.TEXT_DISABLED)

	# 3. MathosDestructiveButton (Crimson Red)
	var dest_normal: StyleBoxFlat = _make_stylebox(MathosTokens.COLOR_RED_DESTRUCTIVE, MathosTokens.COLOR_RED_DESTRUCTIVE, 0, MathosTokens.RADIUS_MD, 16, 10, 16, 10)
	var dest_hover: StyleBoxFlat = _make_stylebox(MathosTokens.COLOR_RED_HOVER, MathosTokens.BORDER_FOCUS, 2, MathosTokens.RADIUS_MD, 16, 10, 16, 10)
	var dest_pressed: StyleBoxFlat = _make_stylebox(MathosTokens.COLOR_RED_PRESSED, MathosTokens.COLOR_RED_PRESSED, 0, MathosTokens.RADIUS_MD, 16, 10, 16, 10)
	var dest_disabled: StyleBoxFlat = _make_stylebox(Color(0.40, 0.15, 0.15, 0.50), Color(0, 0, 0, 0), 0, MathosTokens.RADIUS_MD, 16, 10, 16, 10)

	_apply_button_variation(theme, "MathosDestructiveButton", dest_normal, dest_hover, dest_pressed, dest_disabled, focus_ring, MathosTokens.TEXT_TITLE, MathosTokens.TEXT_TITLE, MathosTokens.TEXT_TITLE, MathosTokens.TEXT_DISABLED)

	# --- SEMANTIC PANEL VARIATIONS ---

	# Panel Primary
	var p_primary: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_PRIMARY, MathosTokens.BORDER_DEFAULT, 1, MathosTokens.RADIUS_MD, 16, 16, 16, 16)
	theme.set_stylebox("panel", "MathosPanelPrimary", p_primary)

	# Panel Secondary
	var p_secondary: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_SECONDARY, MathosTokens.BORDER_SUBTLE, 1, MathosTokens.RADIUS_MD, 14, 14, 14, 14)
	theme.set_stylebox("panel", "MathosPanelSecondary", p_secondary)

	# Panel Elevated
	var p_elevated: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_ELEVATED, MathosTokens.BORDER_DEFAULT, 1, MathosTokens.RADIUS_LG, 18, 18, 18, 18)
	theme.set_stylebox("panel", "MathosPanelElevated", p_elevated)

	# Panel Modal
	var p_modal: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_MODAL, MathosTokens.BORDER_HOVER, 2, MathosTokens.RADIUS_LG, 24, 24, 24, 24)
	theme.set_stylebox("panel", "MathosPanelModal", p_modal)

	# MathosCard
	var p_card: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_CARD, MathosTokens.BORDER_DEFAULT, 1, MathosTokens.RADIUS_MD, 16, 14, 16, 14)
	theme.set_stylebox("panel", "MathosCard", p_card)

	# MathosOption states
	var opt_default: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_SECONDARY, MathosTokens.BORDER_DEFAULT, 1, MathosTokens.RADIUS_MD, 16, 12, 16, 12)
	var opt_hover: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_ELEVATED, MathosTokens.BORDER_HOVER, 2, MathosTokens.RADIUS_MD, 16, 12, 16, 12)
	var opt_selected: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_ELEVATED, MathosTokens.BORDER_SELECTED, 2, MathosTokens.RADIUS_MD, 16, 12, 16, 12)
	var opt_correct: StyleBoxFlat = _make_stylebox(Color(0.06, 0.73, 0.51, 0.15), MathosTokens.BORDER_CORRECT, 2, MathosTokens.RADIUS_MD, 16, 12, 16, 12)
	var opt_incorrect: StyleBoxFlat = _make_stylebox(Color(0.94, 0.27, 0.27, 0.15), MathosTokens.BORDER_INCORRECT, 2, MathosTokens.RADIUS_MD, 16, 12, 16, 12)
	var opt_disabled: StyleBoxFlat = _make_stylebox(MathosTokens.SURFACE_CARD, MathosTokens.BORDER_SUBTLE, 1, MathosTokens.RADIUS_MD, 16, 12, 16, 12)

	theme.set_stylebox("panel", "MathosOption", opt_default)
	theme.set_stylebox("hover", "MathosOption", opt_hover)
	theme.set_stylebox("selected", "MathosOption", opt_selected)
	theme.set_stylebox("correct", "MathosOption", opt_correct)
	theme.set_stylebox("incorrect", "MathosOption", opt_incorrect)
	theme.set_stylebox("disabled", "MathosOption", opt_disabled)

	# --- SEMANTIC LABEL VARIATIONS ---
	_apply_label_variation(theme, "MathosTitle", MathosTokens.TEXT_TITLE, MathosTokens.FONT_SIZE_TITLE)
	_apply_label_variation(theme, "MathosHeading", MathosTokens.TEXT_HEADING, MathosTokens.FONT_SIZE_HEADING)
	_apply_label_variation(theme, "MathosSubtitle", MathosTokens.TEXT_SECONDARY, MathosTokens.FONT_SIZE_SUBTITLE)
	_apply_label_variation(theme, "MathosBody", MathosTokens.TEXT_BODY, MathosTokens.FONT_SIZE_BODY)
	_apply_label_variation(theme, "MathosMeta", MathosTokens.TEXT_MUTED, MathosTokens.FONT_SIZE_META)
	_apply_label_variation(theme, "MathosSuccess", MathosTokens.COLOR_EMERALD_SUCCESS, MathosTokens.FONT_SIZE_BODY)
	_apply_label_variation(theme, "MathosError", MathosTokens.COLOR_RED_DESTRUCTIVE, MathosTokens.FONT_SIZE_BODY)

	return theme

static func _make_stylebox(bg_color: Color, border_color: Color, border_width: int, radius: int, pad_left: int = 8, pad_top: int = 8, pad_right: int = 8, pad_bottom: int = 8) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.border_width_left = border_width
	sb.border_width_top = border_width
	sb.border_width_right = border_width
	sb.border_width_bottom = border_width
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	sb.content_margin_left = pad_left
	sb.content_margin_top = pad_top
	sb.content_margin_right = pad_right
	sb.content_margin_bottom = pad_bottom
	return sb

static func _apply_button_variation(theme: Theme, var_name: String, normal: StyleBox, hover: StyleBox, pressed: StyleBox, disabled: StyleBox, focus: StyleBox, font_col: Color, hover_col: Color, press_col: Color, dis_col: Color) -> void:
	theme.set_stylebox("normal", var_name, normal)
	theme.set_stylebox("hover", var_name, hover)
	theme.set_stylebox("pressed", var_name, pressed)
	theme.set_stylebox("disabled", var_name, disabled)
	theme.set_stylebox("focus", var_name, focus)
	theme.set_color("font_color", var_name, font_col)
	theme.set_color("font_hover_color", var_name, hover_col)
	theme.set_color("font_pressed_color", var_name, press_col)
	theme.set_color("font_disabled_color", var_name, dis_col)
	theme.set_font_size("font_size", var_name, MathosTokens.FONT_SIZE_BODY)

static func _apply_label_variation(theme: Theme, var_name: String, color: Color, font_size: int) -> void:
	theme.set_color("font_color", var_name, color)
	theme.set_font_size("font_size", var_name, font_size)
