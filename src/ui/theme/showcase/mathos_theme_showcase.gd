class_name MathosThemeShowcase
extends Control

## Visual showcase scene for validating the Mathos design system & theme tokens at 1280x720.
## Demonstrates:
## - Surface hierarchy (Primary, Secondary, Elevated, Modal, Card)
## - Typography hierarchy (Title, Heading, Subtitle, Body, Meta, Success, Error)
## - Button variations & states (Primary, Secondary, Destructive: Normal, Hover, Pressed, Disabled, Focus)
## - Option/Card states (Default, Hover, Selected, Correct, Incorrect, Disabled)
## - Spacing & Corner Radius consistency

const TARGET_WIDTH: float = 1280.0
const TARGET_HEIGHT: float = 720.0

var _bg_rect: ColorRect
var _scroll: ScrollContainer
var _main_vbox: VBoxContainer

func _ready() -> void:
	custom_minimum_size = Vector2(TARGET_WIDTH, TARGET_HEIGHT)
	set_anchors_preset(PRESET_FULL_RECT)

	var theme_res: Theme = load("res://src/ui/theme/mathos_theme.tres") as Theme
	if theme_res != null:
		theme = theme_res

	_build_showcase_ui()

func get_target_viewport_size() -> Vector2:
	return Vector2(TARGET_WIDTH, TARGET_HEIGHT)

func _build_showcase_ui() -> void:
	# 1. Background Fill
	_bg_rect = ColorRect.new()
	_bg_rect.name = "BackgroundFill"
	_bg_rect.color = MathosTokens.BG_APP
	_bg_rect.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_bg_rect)

	# 2. Scroll Container
	_scroll = ScrollContainer.new()
	_scroll.name = "ShowcaseScroll"
	_scroll.position = Vector2(16, 16)
	_scroll.size = Vector2(1248, 688)
	_scroll.custom_minimum_size = Vector2(1248, 688)
	add_child(_scroll)

	_main_vbox = VBoxContainer.new()
	_main_vbox.name = "MainVBox"
	_main_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_main_vbox.add_theme_constant_override("separation", MathosTokens.SPACING_LG)
	_scroll.add_child(_main_vbox)

	# Header Title
	var title_lbl: Label = Label.new()
	title_lbl.name = "ShowcaseTitle"
	title_lbl.text = "MATHOS DESIGN SYSTEM & THEME SHOWCASE"
	title_lbl.theme_type_variation = "MathosTitle"
	_main_vbox.add_child(title_lbl)

	var subtitle_lbl: Label = Label.new()
	subtitle_lbl.name = "ShowcaseSubtitle"
	subtitle_lbl.text = "Fantasy-Math Reusable Token & Style Architecture (1280x720 Baseline)"
	subtitle_lbl.theme_type_variation = "MathosSubtitle"
	_main_vbox.add_child(subtitle_lbl)

	# --- SECTION 1: SURFACES ---
	_build_surface_section()

	# --- SECTION 2: TYPOGRAPHY ---
	_build_typography_section()

	# --- SECTION 3: BUTTONS ---
	_build_button_section()

	# --- SECTION 4: OPTIONS / CARDS ---
	_build_option_section()

func _build_surface_section() -> void:
	var sec_title: Label = Label.new()
	sec_title.text = "1. Surface Hierarchy & Panels"
	sec_title.theme_type_variation = "MathosHeading"
	_main_vbox.add_child(sec_title)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.name = "SurfacesHBox"
	hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", MathosTokens.SPACING_MD)
	_main_vbox.add_child(hbox)

	var surfaces: Array[Dictionary] = [
		{"name": "PanelPrimary", "var": "MathosPanelPrimary", "desc": "Primary Surface (#1a2435)"},
		{"name": "PanelSecondary", "var": "MathosPanelSecondary", "desc": "Secondary Surface (#24304a)"},
		{"name": "PanelElevated", "var": "MathosPanelElevated", "desc": "Elevated Surface (#2e3d5c)"},
		{"name": "PanelModal", "var": "MathosPanelModal", "desc": "Modal Surface (#384a6e)"},
		{"name": "MathosCard", "var": "MathosCard", "desc": "Card Background (#1f293d)"}
	]

	for item in surfaces:
		var panel: PanelContainer = PanelContainer.new()
		panel.name = item["name"] as String
		panel.theme_type_variation = item["var"] as String
		panel.custom_minimum_size = Vector2(230, 90)
		panel.size_flags_horizontal = SIZE_EXPAND_FILL

		var lbl: Label = Label.new()
		lbl.text = item["desc"] as String
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(lbl)
		hbox.add_child(panel)

func _build_typography_section() -> void:
	var sec_title: Label = Label.new()
	sec_title.text = "2. Typography Scale"
	sec_title.theme_type_variation = "MathosHeading"
	_main_vbox.add_child(sec_title)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "TypographyPanel"
	panel.theme_type_variation = "MathosPanelPrimary"
	_main_vbox.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", MathosTokens.SPACING_SM)
	panel.add_child(vbox)

	var samples: Array[Dictionary] = [
		{"text": "Display Title (28px Bold) — Mathos Arcane Trial", "var": "MathosTitle"},
		{"text": "Section Heading (22px Semi-Bold) — Objective: Master Probability", "var": "MathosHeading"},
		{"text": "Subtitle / Context (18px) — Stage 01_01: Sample Space Concepts", "var": "MathosSubtitle"},
		{"text": "Body Text (16px) — Select the outcome set that contains all possible trials.", "var": "MathosBody"},
		{"text": "Meta Info / Captions (14px Muted) — Estimated time: 20s | Tags: Probability, Onboarding", "var": "MathosMeta"},
		{"text": "Status Success — Correct! Answer validated against canonical spec.", "var": "MathosSuccess"},
		{"text": "Status Error — Incorrect answer selected. Try reviewing sample spaces.", "var": "MathosError"}
	]

	for item in samples:
		var lbl: Label = Label.new()
		lbl.text = item["text"] as String
		lbl.theme_type_variation = item["var"] as String
		vbox.add_child(lbl)

func _build_button_section() -> void:
	var sec_title: Label = Label.new()
	sec_title.text = "3. Button States & Variations"
	sec_title.theme_type_variation = "MathosHeading"
	_main_vbox.add_child(sec_title)

	var grid: VBoxContainer = VBoxContainer.new()
	grid.name = "ButtonsVBox"
	grid.add_theme_constant_override("separation", MathosTokens.SPACING_MD)
	_main_vbox.add_child(grid)

	var button_groups: Array[Dictionary] = [
		{"title": "MathosPrimaryButton (Arcane Gold)", "var": "MathosPrimaryButton"},
		{"title": "MathosSecondaryButton (Mana Cyan Outline)", "var": "MathosSecondaryButton"},
		{"title": "MathosDestructiveButton (Crimson Red)", "var": "MathosDestructiveButton"}
	]

	for group in button_groups:
		var grp_lbl: Label = Label.new()
		grp_lbl.text = group["title"] as String
		grp_lbl.theme_type_variation = "MathosSubtitle"
		grid.add_child(grp_lbl)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", MathosTokens.SPACING_MD)
		grid.add_child(hbox)

		var states: Array[Dictionary] = [
			{"label": "Normal", "disabled": false},
			{"label": "Disabled", "disabled": true}
		]

		for st in states:
			var btn: Button = Button.new()
			btn.name = "%s_%s" % [group["var"], st["label"]]
			btn.text = "%s (%s)" % [group["var"], st["label"]]
			btn.theme_type_variation = group["var"] as String
			btn.disabled = st["disabled"] as bool
			btn.custom_minimum_size = Vector2(240, 44)
			hbox.add_child(btn)

func _build_option_section() -> void:
	var sec_title: Label = Label.new()
	sec_title.text = "4. Option & Card Interactive States"
	sec_title.theme_type_variation = "MathosHeading"
	_main_vbox.add_child(sec_title)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.name = "OptionsHBox"
	hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", MathosTokens.SPACING_MD)
	_main_vbox.add_child(hbox)

	var opt_states: Array[Dictionary] = [
		{"name": "OptionDefault", "style_key": "panel", "text": "Option Default State"},
		{"name": "OptionHover", "style_key": "hover", "text": "Option Hover State"},
		{"name": "OptionSelected", "style_key": "selected", "text": "Option Selected State"},
		{"name": "OptionCorrect", "style_key": "correct", "text": "Option Correct State"},
		{"name": "OptionIncorrect", "style_key": "incorrect", "text": "Option Incorrect State"}
	]

	for st in opt_states:
		var panel: PanelContainer = PanelContainer.new()
		panel.name = st["name"] as String
		panel.theme_type_variation = "MathosOption"
		panel.custom_minimum_size = Vector2(230, 70)
		panel.size_flags_horizontal = SIZE_EXPAND_FILL

		var theme_res: Theme = theme if theme != null else load("res://src/ui/theme/mathos_theme.tres") as Theme
		if theme_res != null and theme_res.has_stylebox(st["style_key"] as String, "MathosOption"):
			panel.add_theme_stylebox_override("panel", theme_res.get_stylebox(st["style_key"] as String, "MathosOption"))

		var lbl: Label = Label.new()
		lbl.text = st["text"] as String
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(lbl)
		hbox.add_child(panel)
