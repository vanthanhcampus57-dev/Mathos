class_name UISystemShowcase
extends Control

## Standalone 1280x720 Visual QA Showcase for Shared UI Foundation.
## Renders Surface Hierarchy, Typography Scale, Button Variant Grid, Card States,
## and Spacing Containers without dependency on gameplay or content state.

func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	size = Vector2(1280, 720)
	set_anchors_preset(PRESET_FULL_RECT)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 24)
	margin.add_child(root_vbox)

	# Header / Title
	var title: Label = Label.new()
	title.text = "Mathos Shared UI System - Visual QA Showcase"
	title.add_theme_font_size_override("font_size", 28)
	root_vbox.add_child(title)

	# Content Grid (2 columns: Buttons & Typography, Cards & Spacing)
	var grid: HBoxContainer = HBoxContainer.new()
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("separation", 32)
	root_vbox.add_child(grid)

	# Left Column: Buttons & Typography
	var left_col: VBoxContainer = VBoxContainer.new()
	left_col.size_flags_horizontal = SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 16)
	grid.add_child(left_col)

	var btn_section_title: Label = Label.new()
	btn_section_title.text = "Button Component Variants & States"
	btn_section_title.add_theme_font_size_override("font_size", 20)
	left_col.add_child(btn_section_title)

	var btn_primary: Button = Button.new()
	btn_primary.text = "PRIMARY BUTTON (Normal)"
	btn_primary.custom_minimum_size = Vector2(240, 48)
	left_col.add_child(btn_primary)

	var btn_secondary: Button = Button.new()
	btn_secondary.text = "SECONDARY BUTTON (Normal)"
	btn_secondary.custom_minimum_size = Vector2(240, 40)
	left_col.add_child(btn_secondary)

	var btn_destructive: Button = Button.new()
	btn_destructive.text = "DESTRUCTIVE BUTTON (Normal)"
	btn_destructive.custom_minimum_size = Vector2(240, 40)
	left_col.add_child(btn_destructive)

	var btn_disabled: Button = Button.new()
	btn_disabled.text = "DISABLED BUTTON"
	btn_disabled.disabled = true
	btn_disabled.custom_minimum_size = Vector2(240, 40)
	left_col.add_child(btn_disabled)

	# Right Column: Card States & Containers
	var right_col: VBoxContainer = VBoxContainer.new()
	right_col.size_flags_horizontal = SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 16)
	grid.add_child(right_col)

	var card_section_title: Label = Label.new()
	card_section_title.text = "Option Card Component States"
	card_section_title.add_theme_font_size_override("font_size", 20)
	right_col.add_child(card_section_title)

	var card_default: PanelContainer = PanelContainer.new()
	card_default.custom_minimum_size = Vector2(280, 48)
	var lbl1: Label = Label.new()
	lbl1.text = "Card State: DEFAULT"
	card_default.add_child(lbl1)
	right_col.add_child(card_default)

	var card_selected: PanelContainer = PanelContainer.new()
	card_selected.custom_minimum_size = Vector2(280, 48)
	card_selected.set_meta("selected", true)
	var lbl2: Label = Label.new()
	lbl2.text = "Card State: SELECTED"
	card_selected.add_child(lbl2)
	right_col.add_child(card_selected)

	var card_correct: PanelContainer = PanelContainer.new()
	card_correct.custom_minimum_size = Vector2(280, 48)
	card_correct.set_meta("feedback", "correct")
	var lbl3: Label = Label.new()
	lbl3.text = "Card State: CORRECT"
	card_correct.add_child(lbl3)
	right_col.add_child(card_correct)

	var card_incorrect: PanelContainer = PanelContainer.new()
	card_incorrect.custom_minimum_size = Vector2(280, 48)
	card_incorrect.set_meta("feedback", "incorrect")
	var lbl4: Label = Label.new()
	lbl4.text = "Card State: INCORRECT"
	card_incorrect.add_child(lbl4)
	right_col.add_child(card_incorrect)
