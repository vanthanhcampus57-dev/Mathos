extends Control

## MATHOS-STOCHAS-COMBAT-UI-LAB-218L
## Isolated Native Godot UI Lab for STOCHAS Combat Presentation Iteration
## Viewport: 1280 x 720

# Metric specifications (authoritative lab targets)
const CARD_SHELL_WIDTH: float = 140.0
const CARD_SHELL_HEIGHT: float = 200.0
const CARD_ART_WIDTH: float = 124.0
const CARD_ART_HEIGHT: float = 158.0
const QUESTION_PANEL_WIDTH: float = 650.0
const QUESTION_PANEL_HEIGHT: float = 240.0

# Asset paths (real production assets)
const ASSET_BG: String = "res://assets/backgrounds/d1_misty_forest_bg.png"
const ASSET_KARL: String = "res://assets/characters/player/karl/karl_portrait.png"
const ASSET_BOSS: String = "res://assets/characters/bosses/dungeon_1/stochas_boss.png"
const ASSET_CARD_STRIKE: String = "res://assets/ui/combat/cards_v1/STRIKE.png"
const ASSET_CARD_DEFEND: String = "res://assets/ui/combat/cards_v1/DEFEND.png"
const ASSET_CARD_HEAL: String = "res://assets/ui/combat/cards_v1/HEAL.png"
const ASSET_CARD_PROBABILITY: String = "res://assets/ui/combat/cards_v1/PROBABILITY.png"

# Colors
const COLOR_ACCENT_CYAN: Color = Color(0.25, 0.85, 0.98, 1.0)
const COLOR_ACCENT_GOLD: Color = Color(1.0, 0.82, 0.28, 1.0)
const COLOR_ACCENT_RED: Color = Color(0.95, 0.35, 0.35, 1.0)
const COLOR_ACCENT_GREEN: Color = Color(0.35, 0.90, 0.45, 1.0)
const COLOR_ACCENT_PURPLE: Color = Color(0.75, 0.45, 0.95, 1.0)
const COLOR_PANEL_BG: Color = Color(0.06, 0.08, 0.13, 0.92)
const COLOR_PANEL_BORDER: Color = Color(0.22, 0.65, 0.85, 0.65)
const COLOR_CARD_BG: Color = Color(0.08, 0.10, 0.16, 0.95)
const COLOR_CARD_BORDER: Color = Color(0.30, 0.42, 0.58, 0.60)
const COLOR_CARD_SELECTED_BORDER: Color = Color(1.0, 0.85, 0.30, 0.95)
const COLOR_TEXT_MUTED: Color = Color(0.75, 0.82, 0.90, 0.85)

# State
var selected_card_idx: int = 0
var selected_answer_idx: int = 0
var current_question_idx: int = 0
var debug_mode: bool = false
var hint_shown: bool = false

# UI References
var bg_rect: TextureRect = null
var boss_rect: TextureRect = null
var karl_portrait_rect: TextureRect = null
var question_panel: PanelContainer = null
var question_prompt_label: Label = null
var question_stage_label: Label = null
var answer_buttons: Array[Button] = []
var hint_button: Button = null
var cta_button: Button = null
var helper_label: Label = null
var card_panels: Array[PanelContainer] = []
var card_art_rects: Array[TextureRect] = []
var card_badges: Array[Label] = []
var debug_overlay: Control = null
var status_toast: Label = null

# Sample Questions
var questions_data: Array[Dictionary] = [
	{
		"stage": "ARCANE MATH CHALLENGE • CÂU HỎI 1 / 3",
		"prompt": "Tính xác suất rút được 1 thẻ bài Tấn công từ bộ bài 20 lá gồm 8 Tấn công, 6 Phòng thủ, 6 Hồi máu?",
		"choices": [
			"[ A ]  8 / 20  =  40%",
			"[ B ]  6 / 20  =  30%",
			"[ C ]  12 / 20  =  60%",
			"[ D ]  14 / 20  =  70%"
		],
		"correct": 0,
		"hint": "Gợi ý: Xác suất P = Số lá mong muốn (8) chia cho Tổng số lá (20)."
	},
	{
		"stage": "ARCANE MATH CHALLENGE • CÂU HỎI 2 / 3",
		"prompt": "Gieo một xúc xắc 6 mặt cân đối. Xác suất xuất hiện mặt có số chấm là số nguyên tố bằng bao nhiêu?",
		"choices": [
			"[ A ]  1 / 6  (~16.7%)",
			"[ B ]  2 / 6  (~33.3%)",
			"[ C ]  3 / 6  =  50%",
			"[ D ]  4 / 6  (~66.7%)"
		],
		"correct": 2,
		"hint": "Gợi ý: Các số nguyên tố từ 1 đến 6 là {2, 3, 5}, có tổng cộng 3 trường hợp thuận lợi."
	},
	{
		"stage": "ARCANE MATH CHALLENGE • CÂU HỎI 3 / 3",
		"prompt": "Một túi có 5 viên bi đỏ và 3 viên bi xanh. Rút ngẫu nhiên 1 viên, xác suất rút được bi đỏ là:",
		"choices": [
			"[ A ]  3 / 8  =  37.5%",
			"[ B ]  5 / 8  =  62.5%",
			"[ C ]  5 / 3  (~166%)",
			"[ D ]  1 / 2  =  50%"
		],
		"correct": 1,
		"hint": "Gợi ý: Tổng số bi = 5 + 3 = 8. Số bi đỏ = 5. P = 5/8."
	}
]

# Card Configurations
var cards_data: Array[Dictionary] = [
	{
		"id": "strike",
		"name": "TẤN CÔNG",
		"cost": "1 MP",
		"desc": "10 DMG",
		"subtext": "Sát thương chuẩn",
		"color": COLOR_ACCENT_RED,
		"asset": ASSET_CARD_STRIKE,
		"disabled": false
	},
	{
		"id": "defend",
		"name": "PHÒNG THỦ",
		"cost": "1 MP",
		"desc": "+8 GIÁP",
		"subtext": "Chặn sát thương",
		"color": COLOR_ACCENT_CYAN,
		"asset": ASSET_CARD_DEFEND,
		"disabled": false
	},
	{
		"id": "heal",
		"name": "HỒI MÁU",
		"cost": "2 MP",
		"desc": "+15 HP",
		"subtext": "Phục hồi sinh mệnh",
		"color": COLOR_ACCENT_GREEN,
		"asset": ASSET_CARD_HEAL,
		"disabled": false
	},
	{
		"id": "probability",
		"name": "XÁC SUẤT",
		"cost": "3 MP",
		"desc": "BỊ KHÓA",
		"subtext": "Cần 3 MP",
		"color": COLOR_ACCENT_PURPLE,
		"asset": ASSET_CARD_PROBABILITY,
		"disabled": true
	}
]

func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	clip_contents = true

	_build_scene()
	_update_card_selection()
	_update_question_view()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_1:
			select_card(0)
		KEY_2:
			select_card(1)
		KEY_3:
			select_card(2)
		KEY_4:
			select_card(3)
		KEY_Q:
			cycle_question()
		KEY_A:
			cycle_answer()
		KEY_R:
			reset_lab()
		KEY_D:
			toggle_debug_overlay()

func get_card_shell_size() -> Vector2:
	return Vector2(CARD_SHELL_WIDTH, CARD_SHELL_HEIGHT)

func get_card_art_size() -> Vector2:
	return Vector2(CARD_ART_WIDTH, CARD_ART_HEIGHT)

func get_question_panel_size() -> Vector2:
	return Vector2(QUESTION_PANEL_WIDTH, QUESTION_PANEL_HEIGHT)

func is_combat_feed_present() -> bool:
	return false

func get_selected_card_index() -> int:
	return selected_card_idx

func get_selected_answer_index() -> int:
	return selected_answer_idx

func select_card(idx: int) -> void:
	if idx < 0 or idx >= cards_data.size():
		return
	if cards_data[idx]["disabled"]:
		_show_toast("Thẻ bài [XÁC SUẤT] đang bị khóa (cần 3 MP)!")
		return
	selected_card_idx = idx
	_update_card_selection()
	_update_cta_button_text()

func cycle_question() -> void:
	current_question_idx = (current_question_idx + 1) % questions_data.size()
	selected_answer_idx = 0
	hint_shown = false
	_update_question_view()
	_show_toast("Đã chuyển sang Câu hỏi %d / %d" % [current_question_idx + 1, questions_data.size()])

func cycle_answer() -> void:
	selected_answer_idx = (selected_answer_idx + 1) % 4
	_update_answer_selection()

func select_answer(idx: int) -> void:
	if idx >= 0 and idx < 4:
		selected_answer_idx = idx
		_update_answer_selection()

func reset_lab() -> void:
	selected_card_idx = 0
	selected_answer_idx = 0
	current_question_idx = 0
	hint_shown = false
	_update_card_selection()
	_update_question_view()
	_show_toast("Đã đặt lại giao diện Lab về trạng thái ban đầu.")

func toggle_debug_overlay() -> void:
	debug_mode = not debug_mode
	if debug_overlay != null:
		debug_overlay.visible = debug_mode
	_show_toast("Debug Outlines: %s" % ("BẬT" if debug_mode else "TẮT"))

func _build_scene() -> void:
	_build_background()
	_build_boss_render()
	_build_top_huds()
	_build_question_panel()
	_build_card_bar()
	_build_controls_bar()
	_build_debug_overlay()
	_build_toast()

func _build_background() -> void:
	bg_rect = TextureRect.new()
	bg_rect.name = "Background"
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.offset_left = 0
	bg_rect.offset_top = 0
	bg_rect.offset_right = 1280
	bg_rect.offset_bottom = 720
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(ASSET_BG):
		bg_rect.texture = load(ASSET_BG)
	add_child(bg_rect)

	var dark_overlay: ColorRect = ColorRect.new()
	dark_overlay.name = "AtmosphereOverlay"
	dark_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_overlay.color = Color(0.02, 0.04, 0.08, 0.35)
	add_child(dark_overlay)

func _build_boss_render() -> void:
	boss_rect = TextureRect.new()
	boss_rect.name = "StochasBossRender"
	boss_rect.position = Vector2(810, 130)
	boss_rect.size = Vector2(440, 480)
	boss_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(ASSET_BOSS):
		boss_rect.texture = load(ASSET_BOSS)
	add_child(boss_rect)

func _build_top_huds() -> void:
	var karl_hud: PanelContainer = PanelContainer.new()
	karl_hud.name = "KarlHUD"
	karl_hud.position = Vector2(24, 18)
	karl_hud.custom_minimum_size = Vector2(280, 72)
	karl_hud.size = Vector2(280, 72)
	var karl_box: StyleBoxFlat = _create_glass_box(Color(0.06, 0.09, 0.15, 0.85), Color(0.20, 0.60, 0.85, 0.70), 10)
	karl_hud.add_theme_stylebox_override("panel", karl_box)
	add_child(karl_hud)

	var karl_hbox: HBoxContainer = HBoxContainer.new()
	karl_hbox.add_theme_constant_override("separation", 12)
	karl_hud.add_child(karl_hbox)

	var port_frame: PanelContainer = PanelContainer.new()
	port_frame.custom_minimum_size = Vector2(56, 56)
	var port_box: StyleBoxFlat = _create_glass_box(Color(0.1, 0.14, 0.22, 1.0), COLOR_ACCENT_CYAN, 8)
	port_frame.add_theme_stylebox_override("panel", port_box)
	karl_hbox.add_child(port_frame)

	karl_portrait_rect = TextureRect.new()
	karl_portrait_rect.name = "KarlPortrait"
	karl_portrait_rect.custom_minimum_size = Vector2(50, 50)
	karl_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	karl_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(ASSET_KARL):
		karl_portrait_rect.texture = load(ASSET_KARL)
	port_frame.add_child(karl_portrait_rect)

	var karl_info_vbox: VBoxContainer = VBoxContainer.new()
	karl_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	karl_info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	karl_hbox.add_child(karl_info_vbox)

	var karl_name_lbl: Label = Label.new()
	karl_name_lbl.text = "KARL (TOÁN SƯ TẬP SỰ)"
	karl_name_lbl.add_theme_font_size_override("font_size", 12)
	karl_name_lbl.add_theme_color_override("font_color", COLOR_ACCENT_CYAN)
	karl_info_vbox.add_child(karl_name_lbl)

	var hp_bar: ProgressBar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(170, 16)
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	hp_bar.show_percentage = false
	var hp_bg: StyleBoxFlat = _create_solid_box(Color(0.12, 0.15, 0.22, 0.9), 4)
	var hp_fill: StyleBoxFlat = _create_solid_box(Color(0.20, 0.78, 0.42, 1.0), 4)
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	karl_info_vbox.add_child(hp_bar)

	var hp_text_lbl: Label = Label.new()
	hp_text_lbl.text = "HP: 100 / 100   •   GIÁP: 0"
	hp_text_lbl.add_theme_font_size_override("font_size", 10)
	hp_text_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	karl_info_vbox.add_child(hp_text_lbl)

	var boss_hud: PanelContainer = PanelContainer.new()
	boss_hud.name = "StochasHUD"
	boss_hud.position = Vector2(936, 18)
	boss_hud.custom_minimum_size = Vector2(320, 72)
	boss_hud.size = Vector2(320, 72)
	var boss_box: StyleBoxFlat = _create_glass_box(Color(0.12, 0.06, 0.08, 0.88), Color(0.95, 0.30, 0.35, 0.75), 10)
	boss_hud.add_theme_stylebox_override("panel", boss_box)
	add_child(boss_hud)

	var boss_vbox: VBoxContainer = VBoxContainer.new()
	boss_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	boss_vbox.add_theme_constant_override("separation", 3)
	boss_hud.add_child(boss_vbox)

	var boss_name_lbl: Label = Label.new()
	boss_name_lbl.text = "STOCHAS • CHÚA TỂ XÁC SUẤT"
	boss_name_lbl.add_theme_font_size_override("font_size", 13)
	boss_name_lbl.add_theme_color_override("font_color", COLOR_ACCENT_RED)
	boss_vbox.add_child(boss_name_lbl)

	var boss_hp_bar: ProgressBar = ProgressBar.new()
	boss_hp_bar.custom_minimum_size = Vector2(296, 16)
	boss_hp_bar.max_value = 250.0
	boss_hp_bar.value = 250.0
	boss_hp_bar.show_percentage = false
	var boss_hp_bg: StyleBoxFlat = _create_solid_box(Color(0.20, 0.10, 0.12, 0.9), 4)
	var boss_hp_fill: StyleBoxFlat = _create_solid_box(Color(0.90, 0.22, 0.25, 1.0), 4)
	boss_hp_bar.add_theme_stylebox_override("background", boss_hp_bg)
	boss_hp_bar.add_theme_stylebox_override("fill", boss_hp_fill)
	boss_vbox.add_child(boss_hp_bar)

	var boss_status_lbl: Label = Label.new()
	boss_status_lbl.text = "HP: 250 / 250   •   Ý ĐỊNH: ĐÒN QUÉT (10 DMG)"
	boss_status_lbl.add_theme_font_size_override("font_size", 10)
	boss_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.8, 0.85))
	boss_vbox.add_child(boss_status_lbl)

func _build_question_panel() -> void:
	question_panel = PanelContainer.new()
	question_panel.name = "QuestionPanel"
	question_panel.position = Vector2(315, 82)
	question_panel.custom_minimum_size = Vector2(QUESTION_PANEL_WIDTH, QUESTION_PANEL_HEIGHT)
	question_panel.size = Vector2(QUESTION_PANEL_WIDTH, QUESTION_PANEL_HEIGHT)

	var q_box: StyleBoxFlat = _create_glass_box(COLOR_PANEL_BG, COLOR_PANEL_BORDER, 12)
	q_box.content_margin_left = 18
	q_box.content_margin_top = 10
	q_box.content_margin_right = 18
	q_box.content_margin_bottom = 10
	question_panel.add_theme_stylebox_override("panel", q_box)
	add_child(question_panel)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	question_panel.add_child(main_vbox)

	var header_hbox: HBoxContainer = HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	question_stage_label = Label.new()
	question_stage_label.text = "ARCANE MATH CHALLENGE • CÂU HỎI 1 / 3"
	question_stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_stage_label.add_theme_font_size_override("font_size", 11)
	question_stage_label.add_theme_color_override("font_color", COLOR_ACCENT_CYAN)
	header_hbox.add_child(question_stage_label)

	var round_badge: Label = Label.new()
	round_badge.text = "GIAI ĐOẠN 1"
	round_badge.add_theme_font_size_override("font_size", 10)
	round_badge.add_theme_color_override("font_color", COLOR_ACCENT_GOLD)
	header_hbox.add_child(round_badge)

	question_prompt_label = Label.new()
	question_prompt_label.custom_minimum_size = Vector2(614, 38)
	question_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_prompt_label.add_theme_font_size_override("font_size", 13)
	question_prompt_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	main_vbox.add_child(question_prompt_label)

	var answer_grid: GridContainer = GridContainer.new()
	answer_grid.columns = 2
	answer_grid.add_theme_constant_override("h_separation", 10)
	answer_grid.add_theme_constant_override("v_separation", 6)
	main_vbox.add_child(answer_grid)

	answer_buttons.clear()
	for i in range(4):
		var btn: Button = Button.new()
		btn.name = "AnswerBtn_%d" % i
		btn.custom_minimum_size = Vector2(302, 34)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(select_answer.bind(i))
		answer_grid.add_child(btn)
		answer_buttons.append(btn)

	var action_hbox: HBoxContainer = HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 12)
	action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(action_hbox)

	hint_button = Button.new()
	hint_button.name = "HintButton"
	hint_button.text = "💡 GỢI Ý"
	hint_button.custom_minimum_size = Vector2(110, 42)
	var hint_box: StyleBoxFlat = _create_glass_box(Color(0.12, 0.16, 0.24, 0.85), Color(0.40, 0.55, 0.70, 0.70), 6)
	hint_button.add_theme_stylebox_override("normal", hint_box)
	hint_button.add_theme_font_size_override("font_size", 12)
	hint_button.pressed.connect(_on_hint_pressed)
	action_hbox.add_child(hint_button)

	cta_button = Button.new()
	cta_button.name = "SubmitCTAButton"
	cta_button.text = "XUẤT CHIÊU: TẤN CÔNG (10 DMG)"
	cta_button.custom_minimum_size = Vector2(280, 44)
	cta_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cta_box: StyleBoxFlat = _create_solid_box(Color(0.12, 0.55, 0.82, 0.98), 8)
	cta_box.border_width_left = 1
	cta_box.border_width_top = 1
	cta_box.border_width_right = 1
	cta_box.border_width_bottom = 1
	cta_box.border_color = Color(0.45, 0.90, 1.0, 0.95)
	cta_box.shadow_color = Color(0.15, 0.75, 1.0, 0.45)
	cta_box.shadow_size = 6
	cta_button.add_theme_stylebox_override("normal", cta_box)
	cta_button.add_theme_font_size_override("font_size", 13)
	cta_button.pressed.connect(_on_cta_pressed)
	action_hbox.add_child(cta_button)

	helper_label = Label.new()
	helper_label.text = "Quy tắc: Chọn thẻ bài và phương án đúng để xuất chiêu. Sai: STOCHAS phản đòn 10 DMG."
	helper_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	helper_label.add_theme_font_size_override("font_size", 10)
	helper_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	main_vbox.add_child(helper_label)

func _build_card_bar() -> void:
	var card_container: HBoxContainer = HBoxContainer.new()
	card_container.name = "CardBarContainer"
	card_container.position = Vector2(340, 498)
	card_container.add_theme_constant_override("separation", 14)
	add_child(card_container)

	card_panels.clear()
	card_art_rects.clear()
	card_badges.clear()

	for i in range(cards_data.size()):
		var data: Dictionary = cards_data[i]
		var card_panel: PanelContainer = PanelContainer.new()
		card_panel.name = "CardShell_%s" % data["id"]
		card_panel.custom_minimum_size = Vector2(CARD_SHELL_WIDTH, CARD_SHELL_HEIGHT)
		card_panel.size = Vector2(CARD_SHELL_WIDTH, CARD_SHELL_HEIGHT)

		var shell_box: StyleBoxFlat = _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 8)
		card_panel.add_theme_stylebox_override("panel", shell_box)
		card_container.add_child(card_panel)
		card_panels.append(card_panel)

		var hit_btn: Button = Button.new()
		hit_btn.flat = true
		hit_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		hit_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		hit_btn.pressed.connect(select_card.bind(i))
		card_panel.add_child(hit_btn)

		var card_vbox: VBoxContainer = VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 2)
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_panel.add_child(card_vbox)

		var header_hbox: HBoxContainer = HBoxContainer.new()
		header_hbox.custom_minimum_size = Vector2(CARD_ART_WIDTH, 16)
		header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.add_child(header_hbox)

		var card_title: Label = Label.new()
		card_title.text = data["name"]
		card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_title.add_theme_font_size_override("font_size", 10)
		card_title.add_theme_color_override("font_color", data["color"])
		header_hbox.add_child(card_title)
		card_badges.append(card_title)

		var art_frame: PanelContainer = PanelContainer.new()
		art_frame.custom_minimum_size = Vector2(CARD_ART_WIDTH, CARD_ART_HEIGHT)
		art_frame.size = Vector2(CARD_ART_WIDTH, CARD_ART_HEIGHT)
		var art_box: StyleBoxFlat = _create_solid_box(Color(0.04, 0.05, 0.08, 0.70), 4)
		art_frame.add_theme_stylebox_override("panel", art_box)
		card_vbox.add_child(art_frame)

		var art_rect: TextureRect = TextureRect.new()
		art_rect.name = "Art_%s" % data["id"]
		art_rect.custom_minimum_size = Vector2(CARD_ART_WIDTH, CARD_ART_HEIGHT)
		art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(data["asset"]):
			art_rect.texture = load(data["asset"])
		art_frame.add_child(art_rect)
		card_art_rects.append(art_rect)

		var footer_lbl: Label = Label.new()
		footer_lbl.text = data["desc"]
		footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		footer_lbl.add_theme_font_size_override("font_size", 9)
		footer_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
		card_vbox.add_child(footer_lbl)

		if data["disabled"]:
			card_panel.modulate = Color(0.55, 0.55, 0.60, 0.65)
			footer_lbl.text = "BỊ KHÓA"

func _build_controls_bar() -> void:
	var legend_panel: PanelContainer = PanelContainer.new()
	legend_panel.name = "LabControlsLegend"
	legend_panel.position = Vector2(365, 12)
	legend_panel.custom_minimum_size = Vector2(550, 30)
	var leg_box: StyleBoxFlat = _create_glass_box(Color(0.05, 0.07, 0.12, 0.80), Color(0.20, 0.40, 0.60, 0.50), 6)
	leg_box.content_margin_left = 12
	leg_box.content_margin_right = 12
	legend_panel.add_theme_stylebox_override("panel", leg_box)
	add_child(legend_panel)

	var leg_lbl: Label = Label.new()
	leg_lbl.text = "[1-4] Chọn Card   |   [Q] Đổi Câu Hỏi   |   [A] Đổi Đáp Án   |   [D] Viền Debug   |   [R] Đặt lại"
	leg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leg_lbl.add_theme_font_size_override("font_size", 10)
	leg_lbl.add_theme_color_override("font_color", Color(0.70, 0.85, 0.95, 0.90))
	legend_panel.add_child(leg_lbl)

	var settings_btn: Button = Button.new()
	settings_btn.name = "SettingsButton"
	settings_btn.text = "⚙ CÀI ĐẶT"
	settings_btn.position = Vector2(1150, 665)
	settings_btn.custom_minimum_size = Vector2(105, 38)
	var set_box: StyleBoxFlat = _create_glass_box(Color(0.08, 0.10, 0.16, 0.85), Color(0.30, 0.45, 0.60, 0.60), 6)
	settings_btn.add_theme_stylebox_override("normal", set_box)
	settings_btn.add_theme_font_size_override("font_size", 11)
	add_child(settings_btn)

	var open_view_tag: Label = Label.new()
	open_view_tag.name = "OpenForestTag"
	open_view_tag.position = Vector2(24, 680)
	open_view_tag.text = "KHÔNG GIAN MỞ (ĐÃ BỎ NHẬT KÝ CHIẾN ĐẤU)"
	open_view_tag.add_theme_font_size_override("font_size", 10)
	open_view_tag.add_theme_color_override("font_color", Color(0.40, 0.60, 0.50, 0.60))
	add_child(open_view_tag)

func _build_debug_overlay() -> void:
	debug_overlay = Control.new()
	debug_overlay.name = "DebugOverlay"
	debug_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	debug_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_overlay.visible = false
	add_child(debug_overlay)

	var q_outline: ReferenceRect = ReferenceRect.new()
	q_outline.position = Vector2(315, 82)
	q_outline.size = Vector2(QUESTION_PANEL_WIDTH, QUESTION_PANEL_HEIGHT)
	q_outline.border_color = Color(1.0, 0.2, 0.8, 0.9)
	q_outline.border_width = 2.0
	q_outline.editor_only = false
	debug_overlay.add_child(q_outline)

	var q_dim_lbl: Label = Label.new()
	q_dim_lbl.text = "Question: 650 x 240 px"
	q_dim_lbl.position = Vector2(320, 64)
	q_dim_lbl.add_theme_font_size_override("font_size", 10)
	q_dim_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.8, 1.0))
	debug_overlay.add_child(q_dim_lbl)

	for i in range(4):
		var c_outline: ReferenceRect = ReferenceRect.new()
		c_outline.position = Vector2(340 + i * (CARD_SHELL_WIDTH + 14), 498)
		c_outline.size = Vector2(CARD_SHELL_WIDTH, CARD_SHELL_HEIGHT)
		c_outline.border_color = Color(0.2, 1.0, 0.3, 0.9)
		c_outline.border_width = 1.5
		c_outline.editor_only = false
		debug_overlay.add_child(c_outline)

		var c_art_outline: ReferenceRect = ReferenceRect.new()
		c_art_outline.position = Vector2(340 + i * (CARD_SHELL_WIDTH + 14) + 8, 498 + 22)
		c_art_outline.size = Vector2(CARD_ART_WIDTH, CARD_ART_HEIGHT)
		c_art_outline.border_color = Color(1.0, 0.8, 0.1, 0.9)
		c_art_outline.border_width = 1.0
		c_art_outline.editor_only = false
		debug_overlay.add_child(c_art_outline)

func _build_toast() -> void:
	status_toast = Label.new()
	status_toast.name = "StatusToast"
	status_toast.position = Vector2(340, 460)
	status_toast.custom_minimum_size = Vector2(600, 26)
	status_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_toast.add_theme_font_size_override("font_size", 11)
	status_toast.add_theme_color_override("font_color", COLOR_ACCENT_GOLD)
	status_toast.visible = false
	add_child(status_toast)

func _show_toast(msg: String) -> void:
	if status_toast == null:
		return
	status_toast.text = msg
	status_toast.visible = true
	var tw: Tween = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(status_toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		status_toast.visible = false
		status_toast.modulate.a = 1.0
	)

func _update_card_selection() -> void:
	for i in range(card_panels.size()):
		var panel: PanelContainer = card_panels[i]
		var is_selected: bool = (i == selected_card_idx)
		var is_disabled: bool = cards_data[i]["disabled"]

		if is_disabled:
			panel.position.y = 0
			var dis_style: StyleBoxFlat = _create_card_style(Color(0.06, 0.08, 0.12, 0.8), Color(0.25, 0.30, 0.40, 0.4), 8)
			panel.add_theme_stylebox_override("panel", dis_style)
		elif is_selected:
			panel.position.y = -8.0
			var sel_style: StyleBoxFlat = _create_card_style(Color(0.12, 0.16, 0.25, 0.98), COLOR_CARD_SELECTED_BORDER, 8)
			sel_style.border_width_left = 2
			sel_style.border_width_top = 2
			sel_style.border_width_right = 2
			sel_style.border_width_bottom = 2
			sel_style.shadow_color = Color(1.0, 0.85, 0.30, 0.35)
			sel_style.shadow_size = 8
			panel.add_theme_stylebox_override("panel", sel_style)
		else:
			panel.position.y = 0
			var norm_style: StyleBoxFlat = _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 8)
			panel.add_theme_stylebox_override("panel", norm_style)

func _update_question_view() -> void:
	var q_data: Dictionary = questions_data[current_question_idx]
	question_stage_label.text = q_data["stage"]
	question_prompt_label.text = q_data["prompt"]

	for i in range(4):
		var btn: Button = answer_buttons[i]
		btn.text = q_data["choices"][i]

	_update_answer_selection()
	_update_cta_button_text()

func _update_answer_selection() -> void:
	for i in range(answer_buttons.size()):
		var btn: Button = answer_buttons[i]
		var is_selected: bool = (i == selected_answer_idx)

		var btn_style: StyleBoxFlat = StyleBoxFlat.new()
		btn_style.corner_radius_top_left = 6
		btn_style.corner_radius_top_right = 6
		btn_style.corner_radius_bottom_right = 6
		btn_style.corner_radius_bottom_left = 6
		btn_style.content_margin_left = 12
		btn_style.content_margin_right = 12
		btn_style.content_margin_top = 6
		btn_style.content_margin_bottom = 6

		if is_selected:
			btn_style.bg_color = Color(0.12, 0.26, 0.44, 0.95)
			btn_style.border_width_left = 2
			btn_style.border_width_top = 2
			btn_style.border_width_right = 2
			btn_style.border_width_bottom = 2
			btn_style.border_color = COLOR_ACCENT_CYAN
			btn_style.shadow_color = Color(0.20, 0.75, 1.0, 0.30)
			btn_style.shadow_size = 4
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		else:
			btn_style.bg_color = Color(0.08, 0.11, 0.18, 0.75)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn_style.border_color = Color(0.22, 0.32, 0.45, 0.60)
			btn.add_theme_color_override("font_color", Color(0.85, 0.90, 0.96, 0.85))

		btn.add_theme_stylebox_override("normal", btn_style)

func _update_cta_button_text() -> void:
	if cta_button == null:
		return
	var card: Dictionary = cards_data[selected_card_idx]
	cta_button.text = "XUẤT CHIÊU: %s (%s)" % [card["name"], card["desc"]]

func _on_hint_pressed() -> void:
	hint_shown = not hint_shown
	var q_data: Dictionary = questions_data[current_question_idx]
	if hint_shown:
		_show_toast(q_data["hint"])
	else:
		_show_toast("Đã ẩn gợi ý.")

func _on_cta_pressed() -> void:
	var q_data: Dictionary = questions_data[current_question_idx]
	var is_correct: bool = (selected_answer_idx == q_data["correct"])
	var card: Dictionary = cards_data[selected_card_idx]

	if is_correct:
		_show_toast("CHÍNH XÁC! Thi triển %s gây %s lên STOCHAS!" % [card["name"], card["desc"]])
	else:
		_show_toast("SAI RỒI! STOCHAS phản kích gây 10 DMG!")

func _create_glass_box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.border_color = border
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_right = radius
	box.corner_radius_bottom_left = radius
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	box.shadow_size = 6
	box.content_margin_left = 8
	box.content_margin_top = 8
	box.content_margin_right = 8
	box.content_margin_bottom = 8
	return box

func _create_solid_box(bg: Color, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_right = radius
	box.corner_radius_bottom_left = radius
	return box

func _create_card_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.border_color = border
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_right = radius
	box.corner_radius_bottom_left = radius
	box.content_margin_left = 8
	box.content_margin_top = 6
	box.content_margin_right = 8
	box.content_margin_bottom = 6
	return box
