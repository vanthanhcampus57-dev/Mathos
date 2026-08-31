class_name GameVictoryPanel
extends Control

## UI presentation component for Game Victory ("Hoàn thành Mathos").
## Displays campaign victory title, 4 dungeon completion cards, cumulative player XP/Gold if available,
## and a CTA button to return to the Main Menu.

signal return_to_main_menu_requested()

var _main_vbox: VBoxContainer = null
var _dungeon_grid: HBoxContainer = null
var _stats_hbox: HBoxContainer = null
var _gold_value_label: Label = null
var _xp_value_label: Label = null
var _return_button: Button = null

func _ready() -> void:
	_ensure_ui_built()
	var btn: Button = _get_return_button()
	if btn != null:
		if not btn.pressed.is_connected(_on_return_pressed):
			btn.pressed.connect(_on_return_pressed)

func set_victory_data(player_gold: int = 0, player_xp: int = 0) -> void:
	_ensure_ui_built()
	if _gold_value_label != null:
		_gold_value_label.text = "%d" % player_gold
	if _xp_value_label != null:
		_xp_value_label.text = "%d" % player_xp

func _ensure_ui_built() -> void:
	if _main_vbox != null:
		return

	set_anchors_preset(PRESET_FULL_RECT)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var card: PanelContainer = PanelContainer.new()
	card.name = "VictoryCard"
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	card.size_flags_vertical = SIZE_EXPAND_FILL
	card.theme_type_variation = &"MathosCard"
	margin.add_child(card)

	var card_margin: MarginContainer = MarginContainer.new()
	card_margin.name = "CardMargin"
	card_margin.add_theme_constant_override("margin_left", 24)
	card_margin.add_theme_constant_override("margin_top", 20)
	card_margin.add_theme_constant_override("margin_right", 24)
	card_margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(card_margin)

	_main_vbox = VBoxContainer.new()
	_main_vbox.name = "MainVBox"
	_main_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_main_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	_main_vbox.add_theme_constant_override("separation", 16)
	_main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_margin.add_child(_main_vbox)

	# Banner Title
	var title_lbl: Label = Label.new()
	title_lbl.name = "TitleLabel"
	title_lbl.theme_type_variation = &"MathosTitle"
	title_lbl.text = "HOÀN THÀNH MATHOS"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_vbox.add_child(title_lbl)

	# Subtitle / Message
	var sub_lbl: Label = Label.new()
	sub_lbl.name = "SubtitleLabel"
	sub_lbl.theme_type_variation = &"MathosHeading"
	sub_lbl.text = "Chúc mừng bạn đã xuất sắc chinh phục toàn bộ 4 Dungeon xác suất!"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_vbox.add_child(sub_lbl)

	# Dungeons Grid (4 Dungeons)
	_dungeon_grid = HBoxContainer.new()
	_dungeon_grid.name = "DungeonGrid"
	_dungeon_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	_dungeon_grid.add_theme_constant_override("separation", 12)
	_dungeon_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_vbox.add_child(_dungeon_grid)

	var dungeons: Array[Dictionary] = [
		{
			"dungeon_id": "dungeon_01",
			"name": "Dungeon 1: Khu Rừng Mù Sương",
			"desc": "Phép thử ngẫu nhiên • Không gian mẫu • Biến cố"
		},
		{
			"dungeon_id": "dungeon_02",
			"name": "Dungeon 2: Đầm Lầy Tỷ Lệ",
			"desc": "Xác suất cổ điển • Biểu diễn & so sánh"
		},
		{
			"dungeon_id": "dungeon_03",
			"name": "Dungeon 3: Cung Điện Hợp Nhất",
			"desc": "Hợp & giao biến cố • Quy tắc cộng xác suất"
		},
		{
			"dungeon_id": "dungeon_04",
			"name": "Dungeon 4: Đỉnh Tháp Độc Lập",
			"desc": "Biến cố độc lập • Sơ đồ cây • Quy tắc nhân"
		}
	]

	for d in dungeons:
		var d_card: PanelContainer = PanelContainer.new()
		d_card.size_flags_horizontal = SIZE_EXPAND_FILL
		d_card.custom_minimum_size = Vector2(230, 115)
		d_card.theme_type_variation = &"MathosPanelSecondary"

		var d_vbox: VBoxContainer = VBoxContainer.new()
		d_vbox.add_theme_constant_override("separation", 4)
		d_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var name_lbl: Label = Label.new()
		name_lbl.text = d["name"] as String
		name_lbl.theme_type_variation = &"MathosSubtitle"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var desc_lbl: Label = Label.new()
		desc_lbl.text = d["desc"] as String
		desc_lbl.theme_type_variation = &"MathosMeta"
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var check_lbl: Label = Label.new()
		check_lbl.text = "[Hoàn thành]"
		check_lbl.theme_type_variation = &"MathosSuccess"
		check_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		d_vbox.add_child(name_lbl)
		d_vbox.add_child(desc_lbl)
		d_vbox.add_child(check_lbl)
		d_card.add_child(d_vbox)
		_dungeon_grid.add_child(d_card)

	# Stats (XP & Gold)
	_stats_hbox = HBoxContainer.new()
	_stats_hbox.name = "StatsHBox"
	_stats_hbox.add_theme_constant_override("separation", 24)
	_stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_vbox.add_child(_stats_hbox)

	var gold_panel: PanelContainer = PanelContainer.new()
	gold_panel.custom_minimum_size = Vector2(200, 54)
	gold_panel.theme_type_variation = &"MathosPanelElevated"
	var gold_vbox: VBoxContainer = VBoxContainer.new()
	gold_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var gold_title: Label = Label.new()
	gold_title.text = "VÀNG"
	gold_title.theme_type_variation = &"MathosMeta"
	gold_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_value_label = Label.new()
	_gold_value_label.text = "0"
	_gold_value_label.theme_type_variation = &"MathosHeading"
	_gold_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_vbox.add_child(gold_title)
	gold_vbox.add_child(_gold_value_label)
	gold_panel.add_child(gold_vbox)
	_stats_hbox.add_child(gold_panel)

	var xp_panel: PanelContainer = PanelContainer.new()
	xp_panel.custom_minimum_size = Vector2(200, 54)
	xp_panel.theme_type_variation = &"MathosPanelElevated"
	var xp_vbox: VBoxContainer = VBoxContainer.new()
	xp_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var xp_title: Label = Label.new()
	xp_title.text = "KINH NGHIỆM (XP)"
	xp_title.theme_type_variation = &"MathosMeta"
	xp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_value_label = Label.new()
	_xp_value_label.text = "0"
	_xp_value_label.theme_type_variation = &"MathosHeading"
	_xp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_vbox.add_child(xp_title)
	xp_vbox.add_child(_xp_value_label)
	xp_panel.add_child(xp_vbox)
	_stats_hbox.add_child(xp_panel)

	# Action HBox
	var action_hbox: HBoxContainer = HBoxContainer.new()
	action_hbox.name = "ActionHBox"
	action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_vbox.add_child(action_hbox)

	_return_button = Button.new()
	_return_button.name = "ReturnButton"
	_return_button.custom_minimum_size = Vector2(280, 48)
	_return_button.theme_type_variation = &"MathosPrimaryButton"
	_return_button.text = "Trở về trang chủ"
	action_hbox.add_child(_return_button)

func _on_return_pressed() -> void:
	return_to_main_menu_requested.emit()

func _get_return_button() -> Button:
	_ensure_ui_built()
	return _return_button

func get_dungeon_grid() -> HBoxContainer:
	_ensure_ui_built()
	return _dungeon_grid
