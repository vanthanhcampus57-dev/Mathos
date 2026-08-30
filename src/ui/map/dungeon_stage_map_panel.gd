class_name DungeonStageMapPanel
extends Control

## Standalone Production UI Component for Mathos 4 Dungeons / 20 Stages Map.
## Displays 4 Dungeons and 20 Stages with explicit Completed, Current/Unlocked,
## and Locked node states. Emits 'stage_selected(stage_id)' on valid selection.

signal stage_selected(stage_id: String)
signal back_requested

var _unlocked_stages: Array[String] = ["stage_01_01"]
var _completed_stages: Array[String] = []
var _current_stage_id: String = "stage_01_01"

# Node references
var _title_label: Label = null
var _dungeon_container: HBoxContainer = null
var _back_button: Button = null

const DEFAULT_DUNGEONS: Array = [
	{
		"dungeon_id": "dungeon_01",
		"title": "Dungeon 1: Phép Thử & Biến Cố",
		"stages": ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04", "stage_01_05"]
	},
	{
		"dungeon_id": "dungeon_02",
		"title": "Dungeon 2: Xác Suất Cổ Điển",
		"stages": ["stage_02_01", "stage_02_02", "stage_02_03", "stage_02_04", "stage_02_05"]
	},
	{
		"dungeon_id": "dungeon_03",
		"title": "Dungeon 3: Quy Tắc Cộng",
		"stages": ["stage_03_01", "stage_03_02", "stage_03_03", "stage_03_04", "stage_03_05"]
	},
	{
		"dungeon_id": "dungeon_04",
		"title": "Dungeon 4: Quy Tắc Nhân & Độc Lập",
		"stages": ["stage_04_01", "stage_04_02", "stage_04_03", "stage_04_04", "stage_04_05"]
	}
]

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_base_layout()
	render_map()

func _build_base_layout() -> void:
	# Clear existing children if any
	for child in get_children():
		child.queue_free()

	# Background dark overlay
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.12, 0.98)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Main MarginContainer
	var margin: MarginContainer = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)

	# Header Bar
	var header_hbox: HBoxContainer = HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	_title_label = Label.new()
	_title_label.text = "BẢN ĐỒ TIẾN TRÌNH MATHOS"
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(_title_label)

	_back_button = Button.new()
	_back_button.text = "QUAY LẠI"
	_back_button.custom_minimum_size = Vector2(120, 40)
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	header_hbox.add_child(_back_button)

	# 4 Dungeons Container
	_dungeon_container = HBoxContainer.new()
	_dungeon_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dungeon_container.add_theme_constant_override("separation", 16)
	main_vbox.add_child(_dungeon_container)

## Public runtime setter for progression model
func set_map_data(p_map_data: Dictionary) -> void:
	if p_map_data.has("unlocked_stages"):
		_unlocked_stages.clear()
		for s in p_map_data.get("unlocked_stages", []):
			_unlocked_stages.append(String(s))

	if p_map_data.has("completed_stages"):
		_completed_stages.clear()
		for s in p_map_data.get("completed_stages", []):
			_completed_stages.append(String(s))

	if p_map_data.has("current_stage_id"):
		_current_stage_id = String(p_map_data.get("current_stage_id", "stage_01_01"))

	render_map()

## Render 4 Dungeons and 20 stage nodes
func render_map() -> void:
	if _dungeon_container == null:
		return

	for child in _dungeon_container.get_children():
		child.queue_free()

	for dun_info in DEFAULT_DUNGEONS:
		var dun_panel: PanelContainer = PanelContainer.new()
		dun_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dun_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var dun_margin: MarginContainer = MarginContainer.new()
		dun_margin.add_theme_constant_override("margin_left", 12)
		dun_margin.add_theme_constant_override("margin_right", 12)
		dun_margin.add_theme_constant_override("margin_top", 12)
		dun_margin.add_theme_constant_override("margin_bottom", 12)
		dun_panel.add_child(dun_margin)

		var dun_vbox: VBoxContainer = VBoxContainer.new()
		dun_vbox.add_theme_constant_override("separation", 12)
		dun_margin.add_child(dun_vbox)

		# Dungeon Header
		var dun_title: Label = Label.new()
		dun_title.text = String(dun_info.get("title", "Dungeon"))
		dun_title.add_theme_font_size_override("font_size", 16)
		dun_title.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0))
		dun_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dun_vbox.add_child(dun_title)

		var hs: HSeparator = HSeparator.new()
		dun_vbox.add_child(hs)

		# Stages
		var stages: Array = dun_info.get("stages", [])
		for s_id_raw in stages:
			var s_id: String = String(s_id_raw)
			var is_completed: bool = s_id in _completed_stages
			var is_unlocked: bool = is_completed or (s_id in _unlocked_stages) or (s_id == _current_stage_id)
			var is_current: bool = (s_id == _current_stage_id)

			var stage_btn: Button = Button.new()
			stage_btn.custom_minimum_size = Vector2(0, 48)
			stage_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var parts: PackedStringArray = s_id.split("_")
			var stage_num_str: String = "S" + parts[1] + "." + parts[2] if parts.size() == 3 else s_id

			if is_completed:
				stage_btn.text = "✔ " + stage_num_str + " (Hoàn thành)"
				stage_btn.disabled = false
				stage_btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
			elif is_current or is_unlocked:
				stage_btn.text = "▶ " + stage_num_str + " (Đang mở)"
				stage_btn.disabled = false
				stage_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			else:
				stage_btn.text = "🔒 " + stage_num_str + " (Khóa)"
				stage_btn.disabled = true
				stage_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

			if is_unlocked or is_completed:
				stage_btn.pressed.connect(func() -> void:
					_on_stage_button_pressed(s_id)
				)

			dun_vbox.add_child(stage_btn)

		_dungeon_container.add_child(dun_panel)

func _on_stage_button_pressed(stage_id: String) -> void:
	var is_completed: bool = stage_id in _completed_stages
	var is_unlocked: bool = is_completed or (stage_id in _unlocked_stages) or (stage_id == _current_stage_id)

	if is_unlocked or is_completed:
		stage_selected.emit(stage_id)
