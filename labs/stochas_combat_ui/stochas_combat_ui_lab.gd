extends Control

## MATHOS-KARL-PIXEL-LAB-INTEGRATION-221B
## Native Godot LAB Parity Implementation with Karl Pixel Combat-State Integration
## Viewport: 1280 x 720

# Authoritative Composition Grid & Axis
const CENTER_INTERACTION_X: float = 690.0

# Question Module
const QUESTION_WIDTH: float = 640.0
const QUESTION_TOP: float = 160.0
const QUESTION_HEIGHT: float = 210.0

# Card Specifications (Approved Stitch visual size)
const CARD_WIDTH: float = 104.0
const CARD_HEIGHT: float = 158.0
const CARD_GAP: float = 14.0
const CARD_ROW_BOTTOM: float = 20.0

# Hover Detail Panel
const HOVER_DETAIL_WIDTH: float = 440.0
const HOVER_DETAIL_HEIGHT: float = 42.0
const HOVER_DETAIL_Y: float = 486.0

# Boss Battlefield Entity
const BOSS_WIDTH: float = 480.0
const BOSS_HEIGHT: float = 520.0
const BOSS_RIGHT: float = 0.0
const BOSS_BOTTOM: float = 70.0

# Karl Battlefield Entity (Target Left ~55–90px, Bottom ~60–80px, Height ~190–250px)
const KARL_ENTITY_LEFT: float = 70.0
const KARL_ENTITY_BOTTOM: float = 70.0
const KARL_ENTITY_WIDTH: float = 220.0
const KARL_ENTITY_HEIGHT: float = 220.0

# Asset paths (canonical production assets)
const ASSET_BG: String = "res://assets/backgrounds/d1_misty_forest_bg.png"
const ASSET_KARL_PORTRAIT: String = "res://assets/characters/player/karl/karl_portrait.png"
const ASSET_BOSS: String = "res://assets/characters/bosses/dungeon_1/stochas_boss.png"
const ASSET_CARD_STRIKE: String = "res://assets/ui/combat/cards_v1/STRIKE.png"
const ASSET_CARD_DEFEND: String = "res://assets/ui/combat/cards_v1/DEFEND.png"
const ASSET_CARD_HEAL: String = "res://assets/ui/combat/cards_v1/HEAL.png"
const ASSET_CARD_PROBABILITY: String = "res://assets/ui/combat/cards_v1/PROBABILITY.png"

# Karl 5-State Pixel Combat Sprites
const ASSET_KARL_IDLE: String = "res://assets/characters/player/karl/combat_pixel/karl_idle.png"
const ASSET_KARL_CAST: String = "res://assets/characters/player/karl/combat_pixel/karl_cast.png"
const ASSET_KARL_HIT: String = "res://assets/characters/player/karl/combat_pixel/karl_hit.png"
const ASSET_KARL_HEAL: String = "res://assets/characters/player/karl/combat_pixel/karl_heal.png"
const ASSET_KARL_SHIELD: String = "res://assets/characters/player/karl/combat_pixel/karl_shield.png"

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

# Karl Combat States
enum KarlState { IDLE, CAST, HIT, HEAL, SHIELD }
var current_karl_state: KarlState = KarlState.IDLE
var karl_textures: Dictionary = {}
var karl_sprite_rect: TextureRect = null
var karl_vfx_container: Control = null
var karl_state_tween: Tween = null

# Baseline offsets for exact 650.0 ground alignment
# In 1254px source, bottom non-transparent pixel offsets:
# idle: 26px -> 4.5px at 220px scale
# cast: 0px -> 0.0px
# hit: 26px -> 4.5px
# heal: 0px -> 0.0px
# shield: 16px -> 2.8px
const KARL_BASELINE_OFFSETS: Dictionary = {
	KarlState.IDLE: 4.5,
	KarlState.CAST: 0.0,
	KarlState.HIT: 4.5,
	KarlState.HEAL: 0.0,
	KarlState.SHIELD: 2.8,
}

# State
var selected_card_idx: int = 0
var hovered_card_idx: int = 0
var selected_answer_idx: int = 0
var current_question_idx: int = 0
var debug_mode: bool = false
var hint_shown: bool = false

# UI References
var bg_rect: TextureRect = null
var boss_rect: TextureRect = null
var karl_hud: PanelContainer = null
var boss_hud: PanelContainer = null
var karl_portrait_rect: TextureRect = null
var karl_battlefield_entity: Control = null
var question_panel: PanelContainer = null
var question_prompt_label: Label = null
var question_stage_label: Label = null
var answer_buttons: Array[Button] = []
var hint_button: Button = null
var cta_button: Button = null
var helper_label: Label = null
var hover_detail_panel: PanelContainer = null
var hover_title_lbl: Label = null
var hover_desc_lbl: Label = null
var card_panels: Array[PanelContainer] = []
var card_art_rects: Array[TextureRect] = []
var debug_overlay: Control = null
var floating_status_container: Control = null

# Sample Questions
var questions_data: Array[Dictionary] = [
	{
		"stage": "ARCANE CHALLENGE • CÂU HỎI 1 / 3",
		"round": "GIAI ĐOẠN 1 • 45s",
		"prompt": "Tính xác suất rút được 1 thẻ bài Tấn công từ bộ bài 20 lá gồm 8 Tấn công, 6 Phòng thủ, 6 Hồi máu?",
		"choices": [
			{"code": "A", "val": "40%", "sub": "8 / 20"},
			{"code": "B", "val": "30%", "sub": "6 / 20"},
			{"code": "C", "val": "60%", "sub": "12 / 20"},
			{"code": "D", "val": "70%", "sub": "14 / 20"}
		],
		"correct": 0,
		"hint": "Gợi ý: Xác suất P = Số lá thuận lợi (8) / Tổng số lá (20) = 40%."
	},
	{
		"stage": "ARCANE CHALLENGE • CÂU HỎI 2 / 3",
		"round": "GIAI ĐOẠN 1 • 45s",
		"prompt": "Gieo một xúc xắc 6 mặt cân đối. Xác suất xuất hiện mặt là số nguyên tố bằng bao nhiêu?",
		"choices": [
			{"code": "A", "val": "16.7%", "sub": "1 / 6"},
			{"code": "B", "val": "33.3%", "sub": "2 / 6"},
			{"code": "C", "val": "50.0%", "sub": "3 / 6"},
			{"code": "D", "val": "66.7%", "sub": "4 / 6"}
		],
		"correct": 2,
		"hint": "Gợi ý: Các số nguyên tố là {2, 3, 5} -> có 3/6 = 50%."
	},
	{
		"stage": "ARCANE CHALLENGE • CÂU HỎI 3 / 3",
		"round": "GIAI ĐOẠN 1 • 45s",
		"prompt": "Một túi có 5 viên bi đỏ và 3 viên bi xanh. Rút ngẫu nhiên 1 viên, xác suất rút được bi đỏ là:",
		"choices": [
			{"code": "A", "val": "37.5%", "sub": "3 / 8"},
			{"code": "B", "val": "62.5%", "sub": "5 / 8"},
			{"code": "C", "val": "50.0%", "sub": "4 / 8"},
			{"code": "D", "val": "75.0%", "sub": "6 / 8"}
		],
		"correct": 1,
		"hint": "Gợi ý: Tổng 8 viên, 5 viên đỏ -> 5/8 = 62.5%."
	}
]

# Locked Mathos Combat Contract (Canonical values: 10 / +8 / +15)
var cards_data: Array[Dictionary] = [
	{
		"id": "strike",
		"name": "TẤN CÔNG",
		"effect": "Gây 10 sát thương",
		"stat_badge": "10 DMG",
		"color": COLOR_ACCENT_RED,
		"asset": ASSET_CARD_STRIKE,
		"disabled": false
	},
	{
		"id": "defend",
		"name": "PHÒNG THỦ",
		"effect": "Nhận +8 Giáp",
		"stat_badge": "+8 GIÁP",
		"color": COLOR_ACCENT_CYAN,
		"asset": ASSET_CARD_DEFEND,
		"disabled": false
	},
	{
		"id": "heal",
		"name": "HỒI PHỤC",
		"effect": "Hồi +15 HP",
		"stat_badge": "+15 HP",
		"color": COLOR_ACCENT_GREEN,
		"asset": ASSET_CARD_HEAL,
		"disabled": false
	},
	{
		"id": "probability",
		"name": "KỸ NĂNG XÁC SUẤT",
		"effect": "CHƯA KÍCH HOẠT",
		"stat_badge": "BỊ KHÓA",
		"color": COLOR_ACCENT_PURPLE,
		"asset": ASSET_CARD_PROBABILITY,
		"disabled": true
	}
]

func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	clip_contents = true

	_load_karl_textures()
	_build_scene()
	_update_card_selection()
	_update_hover_detail(selected_card_idx)
	_update_question_view()

	# Trigger initial demonstration floating combat status feedback
	_spawn_floating_feedback(Vector2(180, 410), "+8 GIÁP", COLOR_ACCENT_CYAN)
	_spawn_floating_feedback(Vector2(180, 380), "+15 HP", COLOR_ACCENT_GREEN)
	_spawn_floating_feedback(Vector2(1040, 240), "-10 HP", COLOR_ACCENT_RED)
	_spawn_floating_feedback(Vector2(1040, 210), "CRITICAL!", COLOR_ACCENT_GOLD)

func _load_karl_textures() -> void:
	if ResourceLoader.exists(ASSET_KARL_IDLE):
		karl_textures[KarlState.IDLE] = load(ASSET_KARL_IDLE)
	if ResourceLoader.exists(ASSET_KARL_CAST):
		karl_textures[KarlState.CAST] = load(ASSET_KARL_CAST)
	if ResourceLoader.exists(ASSET_KARL_HIT):
		karl_textures[KarlState.HIT] = load(ASSET_KARL_HIT)
	if ResourceLoader.exists(ASSET_KARL_HEAL):
		karl_textures[KarlState.HEAL] = load(ASSET_KARL_HEAL)
	if ResourceLoader.exists(ASSET_KARL_SHIELD):
		karl_textures[KarlState.SHIELD] = load(ASSET_KARL_SHIELD)

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
		KEY_I:
			trigger_idle_state()
		KEY_C:
			trigger_cast_effect()
		KEY_H:
			trigger_hit_effect()
		KEY_E:
			trigger_heal_effect()
		KEY_S:
			trigger_shield_effect()

# Getters for Verification
func get_center_interaction_x() -> float:
	return CENTER_INTERACTION_X

func get_question_center_x() -> float:
	if question_panel == null:
		return 0.0
	return question_panel.position.x + (question_panel.size.x / 2.0)

func get_hover_detail_center_x() -> float:
	if hover_detail_panel == null:
		return 0.0
	return hover_detail_panel.position.x + (hover_detail_panel.size.x / 2.0)

func get_card_row_center_x() -> float:
	var total_width: float = 4.0 * CARD_WIDTH + 3.0 * CARD_GAP
	var row_start_x: float = CENTER_INTERACTION_X - (total_width / 2.0)
	return row_start_x + (total_width / 2.0)

func get_card_size() -> Vector2:
	return Vector2(CARD_WIDTH, CARD_HEIGHT)

func get_card_gap() -> float:
	return CARD_GAP

func get_question_position() -> Vector2:
	return Vector2(CENTER_INTERACTION_X - (QUESTION_WIDTH / 2.0), QUESTION_TOP)

func get_question_size() -> Vector2:
	return Vector2(QUESTION_WIDTH, QUESTION_HEIGHT)

func get_hover_detail_position() -> Vector2:
	return Vector2(CENTER_INTERACTION_X - (HOVER_DETAIL_WIDTH / 2.0), HOVER_DETAIL_Y)

func get_boss_position() -> Vector2:
	return Vector2(1280.0 - BOSS_WIDTH - BOSS_RIGHT, 720.0 - BOSS_HEIGHT - BOSS_BOTTOM)

func get_boss_size() -> Vector2:
	return Vector2(BOSS_WIDTH, BOSS_HEIGHT)

func get_karl_position() -> Vector2:
	if karl_battlefield_entity == null:
		return Vector2.ZERO
	return karl_battlefield_entity.position

func get_karl_size() -> Vector2:
	if karl_battlefield_entity == null:
		return Vector2.ZERO
	return karl_battlefield_entity.size

func get_karl_baseline() -> float:
	if karl_battlefield_entity == null:
		return 0.0
	return karl_battlefield_entity.position.y + karl_battlefield_entity.size.y

func get_karl_state() -> int:
	return current_karl_state

func get_karl_texture_path() -> String:
	match current_karl_state:
		KarlState.IDLE: return ASSET_KARL_IDLE
		KarlState.CAST: return ASSET_KARL_CAST
		KarlState.HIT: return ASSET_KARL_HIT
		KarlState.HEAL: return ASSET_KARL_HEAL
		KarlState.SHIELD: return ASSET_KARL_SHIELD
	return ""

func is_karl_standee_present() -> bool:
	if karl_battlefield_entity == null:
		return false
	for child in karl_battlefield_entity.find_children("*", "TextureRect", true, false):
		var tr = child as TextureRect
		if tr.texture != null and "karl_portrait" in tr.texture.resource_path:
			return true
	return false

func is_combat_feed_present() -> bool:
	return false

func has_permanent_card_stats() -> bool:
	for panel in card_panels:
		for child in panel.find_children("*", "Label", true, false):
			var lbl = child as Label
			var txt = lbl.text.strip_edges()
			if txt in ["10 DMG", "+8 GIÁP", "+15 HP", "BỊ KHÓA"]:
				return true
	return false

func select_card(idx: int) -> void:
	if idx < 0 or idx >= cards_data.size():
		return
	if cards_data[idx]["disabled"]:
		_spawn_floating_feedback(Vector2(690, 460), "CHƯA KÍCH HOẠT (CẦN 3 MP)", COLOR_ACCENT_PURPLE)
		return
	selected_card_idx = idx
	hovered_card_idx = idx
	_update_card_selection()
	_update_hover_detail(selected_card_idx)
	_update_cta_button_text()

	# Trigger Karl state preview based on card
	var card_id: String = cards_data[idx]["id"]
	if card_id == "strike":
		trigger_cast_effect()
	elif card_id == "defend":
		trigger_shield_effect()
	elif card_id == "heal":
		trigger_heal_effect()

func cycle_question() -> void:
	current_question_idx = (current_question_idx + 1) % questions_data.size()
	selected_answer_idx = 0
	hint_shown = false
	_update_question_view()
	_spawn_floating_feedback(Vector2(690, 130), "CÂU HỎI MỚI", COLOR_ACCENT_CYAN)

func cycle_answer() -> void:
	selected_answer_idx = (selected_answer_idx + 1) % 4
	_update_answer_selection()

func select_answer(idx: int) -> void:
	if idx >= 0 and idx < 4:
		selected_answer_idx = idx
		_update_answer_selection()

func reset_lab() -> void:
	selected_card_idx = 0
	hovered_card_idx = 0
	selected_answer_idx = 0
	current_question_idx = 0
	hint_shown = false
	trigger_idle_state()
	_update_card_selection()
	_update_hover_detail(0)
	_update_question_view()
	_spawn_floating_feedback(Vector2(690, 460), "ĐÃ RESET LAB", COLOR_ACCENT_GOLD)

func toggle_debug_overlay() -> void:
	debug_mode = not debug_mode
	if debug_overlay != null:
		debug_overlay.visible = debug_mode

func set_karl_state(state: KarlState) -> void:
	current_karl_state = state
	if karl_sprite_rect == null:
		return
	if karl_textures.has(state):
		karl_sprite_rect.texture = karl_textures[state]
	var y_offset: float = KARL_BASELINE_OFFSETS.get(state, 0.0)
	karl_sprite_rect.position = Vector2(0.0, y_offset)
	karl_sprite_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)

func trigger_idle_state() -> void:
	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()
	set_karl_state(KarlState.IDLE)

func trigger_cast_effect() -> void:
	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()
	set_karl_state(KarlState.CAST)

	# Light cyan magic pulse near casting hand (Karl faces right, hand around (160, 85))
	_spawn_cast_hand_spark()

	# STOCHAS receives floating -10 HP
	_spawn_floating_feedback(Vector2(1040, 240), "-10 HP", COLOR_ACCENT_RED)
	_spawn_floating_feedback(Vector2(1040, 210), "CRITICAL!", COLOR_ACCENT_GOLD)

	# Auto-return to IDLE after 0.9s
	karl_state_tween = create_tween()
	karl_state_tween.tween_interval(0.9)
	karl_state_tween.tween_callback(func(): set_karl_state(KarlState.IDLE))

func trigger_shield_effect() -> void:
	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()
	set_karl_state(KarlState.SHIELD)

	# Floating +8 GIÁP above Karl
	_spawn_floating_feedback(Vector2(180, 410), "+8 GIÁP", COLOR_ACCENT_CYAN)

	# Cyan/blue arcane barrier pulse around Karl
	_spawn_barrier_pulse()

	# Auto-return to IDLE after 1.1s
	karl_state_tween = create_tween()
	karl_state_tween.tween_interval(1.1)
	karl_state_tween.tween_callback(func(): set_karl_state(KarlState.IDLE))

func trigger_heal_effect() -> void:
	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()
	set_karl_state(KarlState.HEAL)

	# Floating +15 HP above Karl
	_spawn_floating_feedback(Vector2(180, 410), "+15 HP", COLOR_ACCENT_GREEN)

	# Green/emerald aura pulse around Karl
	_spawn_emerald_pulse()

	# Auto-return to IDLE after 1.2s
	karl_state_tween = create_tween()
	karl_state_tween.tween_interval(1.2)
	karl_state_tween.tween_callback(func(): set_karl_state(KarlState.IDLE))

func trigger_hit_effect() -> void:
	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()
	set_karl_state(KarlState.HIT)

	# Floating -10 HP above Karl
	_spawn_floating_feedback(Vector2(180, 410), "-10 HP", COLOR_ACCENT_RED)

	# Brief red flash / impact pulse
	_spawn_hit_pulse()

	# Auto-return to IDLE after 0.7s
	karl_state_tween = create_tween()
	karl_state_tween.tween_interval(0.7)
	karl_state_tween.tween_callback(func(): set_karl_state(KarlState.IDLE))

func _spawn_cast_hand_spark() -> void:
	if karl_vfx_container == null:
		return
	var spark: Panel = Panel.new()
	spark.position = Vector2(160, 85)
	spark.size = Vector2(24, 24)
	spark.pivot_offset = Vector2(12, 12)
	var s_box: StyleBoxFlat = StyleBoxFlat.new()
	s_box.bg_color = Color(0.40, 0.90, 1.0, 0.85)
	s_box.border_width_left = 2
	s_box.border_width_top = 2
	s_box.border_width_right = 2
	s_box.border_width_bottom = 2
	s_box.border_color = Color(1.0, 1.0, 1.0, 0.95)
	s_box.corner_radius_top_left = 12
	s_box.corner_radius_top_right = 12
	s_box.corner_radius_bottom_right = 12
	s_box.corner_radius_bottom_left = 12
	s_box.shadow_color = Color(0.2, 0.85, 1.0, 0.7)
	s_box.shadow_size = 12
	spark.add_theme_stylebox_override("panel", s_box)
	karl_vfx_container.add_child(spark)

	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(spark, "scale", Vector2(1.8, 1.8), 0.5)
	tw.tween_property(spark, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(spark.queue_free)

func _spawn_barrier_pulse() -> void:
	if karl_vfx_container == null:
		return
	var barrier: Panel = Panel.new()
	barrier.position = Vector2(10, 10)
	barrier.size = Vector2(200, 200)
	barrier.pivot_offset = Vector2(100, 100)
	var b_box: StyleBoxFlat = StyleBoxFlat.new()
	b_box.bg_color = Color(0.12, 0.45, 0.75, 0.20)
	b_box.border_width_left = 3
	b_box.border_width_top = 3
	b_box.border_width_right = 3
	b_box.border_width_bottom = 3
	b_box.border_color = Color(0.30, 0.85, 1.0, 0.85)
	b_box.corner_radius_top_left = 100
	b_box.corner_radius_top_right = 100
	b_box.corner_radius_bottom_right = 100
	b_box.corner_radius_bottom_left = 100
	b_box.shadow_color = Color(0.20, 0.80, 1.0, 0.55)
	b_box.shadow_size = 14
	barrier.add_theme_stylebox_override("panel", b_box)
	karl_vfx_container.add_child(barrier)

	barrier.scale = Vector2(0.85, 0.85)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(barrier, "scale", Vector2(1.15, 1.15), 1.0)
	tw.tween_property(barrier, "modulate:a", 0.0, 1.0)
	tw.chain().tween_callback(barrier.queue_free)

func _spawn_emerald_pulse() -> void:
	if karl_vfx_container == null:
		return
	var aura: Panel = Panel.new()
	aura.position = Vector2(15, 10)
	aura.size = Vector2(190, 200)
	aura.pivot_offset = Vector2(95, 100)
	var a_box: StyleBoxFlat = StyleBoxFlat.new()
	a_box.bg_color = Color(0.15, 0.65, 0.35, 0.22)
	a_box.border_width_left = 3
	a_box.border_width_top = 3
	a_box.border_width_right = 3
	a_box.border_width_bottom = 3
	a_box.border_color = Color(0.35, 0.95, 0.55, 0.85)
	a_box.corner_radius_top_left = 95
	a_box.corner_radius_top_right = 95
	a_box.corner_radius_bottom_right = 95
	a_box.corner_radius_bottom_left = 95
	a_box.shadow_color = Color(0.25, 0.90, 0.50, 0.55)
	a_box.shadow_size = 14
	aura.add_theme_stylebox_override("panel", a_box)
	karl_vfx_container.add_child(aura)

	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(aura, "position:y", aura.position.y - 25.0, 1.1)
	tw.tween_property(aura, "scale", Vector2(1.10, 1.10), 1.1)
	tw.tween_property(aura, "modulate:a", 0.0, 1.1)
	tw.chain().tween_callback(aura.queue_free)

func _spawn_hit_pulse() -> void:
	if karl_sprite_rect == null:
		return
	karl_sprite_rect.modulate = Color(2.0, 0.4, 0.4, 1.0)
	var tw: Tween = create_tween()
	tw.tween_property(karl_sprite_rect, "position:x", -6.0, 0.06)
	tw.tween_property(karl_sprite_rect, "position:x", 5.0, 0.06)
	tw.tween_property(karl_sprite_rect, "position:x", -3.0, 0.06)
	tw.tween_property(karl_sprite_rect, "position:x", 0.0, 0.06)
	tw.parallel().tween_property(karl_sprite_rect, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.55)

func _build_scene() -> void:
	# 1. Background
	_build_background()

	# 2. STOCHAS Battlefield Entity (Right 0px, Bottom 70px)
	_build_boss_render()

	# 3. Karl Battlefield Entity (Left 70px, Bottom 70px, 220x220px)
	_build_karl_battlefield_entity()

	# 4. Top HUDs (Karl Top-Left, Stochas Top-Right)
	_build_top_huds()

	# 5. Question Module (Center X = 690px, Top = 160px, Width = 640px)
	_build_question_module()

	# 6. Card Hover Detail Panel (Center X = 690px, above card row)
	_build_card_hover_detail()

	# 7. Card Row (Center X = 690px, Bottom = 20px, 104x158px each)
	_build_card_row()

	# 8. Settings Button (Bottom-Right: 24px right, 20px bottom)
	_build_settings_button()

	# 9. Floating Combat Feedback Container
	_build_floating_status_container()

	# 10. Debug Overlay
	_build_debug_overlay()

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

	# Atmospheric dark fantasy vignette overlay
	var dark_overlay: ColorRect = ColorRect.new()
	dark_overlay.name = "AtmosphereOverlay"
	dark_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_overlay.color = Color(0.02, 0.04, 0.08, 0.32)
	add_child(dark_overlay)

func _build_boss_render() -> void:
	# Right 0px, Bottom 70px, 480x520px
	boss_rect = TextureRect.new()
	boss_rect.name = "StochasBossRender"
	boss_rect.position = Vector2(1280.0 - BOSS_WIDTH - BOSS_RIGHT, 720.0 - BOSS_HEIGHT - BOSS_BOTTOM)
	boss_rect.size = Vector2(BOSS_WIDTH, BOSS_HEIGHT)
	boss_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(ASSET_BOSS):
		boss_rect.texture = load(ASSET_BOSS)
	add_child(boss_rect)

func _build_karl_battlefield_entity() -> void:
	# Left 70px, Bottom 70px, 220x220px (Ground baseline = 650px)
	karl_battlefield_entity = Control.new()
	karl_battlefield_entity.name = "KarlBattlefieldEntity"
	karl_battlefield_entity.position = Vector2(KARL_ENTITY_LEFT, 720.0 - KARL_ENTITY_BOTTOM - KARL_ENTITY_HEIGHT)
	karl_battlefield_entity.size = Vector2(KARL_ENTITY_WIDTH, KARL_ENTITY_HEIGHT)
	karl_battlefield_entity.custom_minimum_size = Vector2(KARL_ENTITY_WIDTH, KARL_ENTITY_HEIGHT)
	add_child(karl_battlefield_entity)

	# Ground shadow under Karl's feet to anchor naturally in misty forest
	var shadow: Panel = Panel.new()
	shadow.name = "GroundShadow"
	shadow.position = Vector2(30, 204)
	shadow.custom_minimum_size = Vector2(160, 18)
	shadow.size = Vector2(160, 18)
	var sbox: StyleBoxFlat = StyleBoxFlat.new()
	sbox.bg_color = Color(0.01, 0.02, 0.05, 0.55)
	sbox.corner_radius_top_left = 9
	sbox.corner_radius_top_right = 9
	sbox.corner_radius_bottom_right = 9
	sbox.corner_radius_bottom_left = 9
	shadow.add_theme_stylebox_override("panel", sbox)
	karl_battlefield_entity.add_child(shadow)

	# Dedicated VFX container behind/around sprite
	karl_vfx_container = Control.new()
	karl_vfx_container.name = "KarlVFXContainer"
	karl_vfx_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	karl_vfx_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	karl_battlefield_entity.add_child(karl_vfx_container)

	# Native pixel character TextureRect (no rectangular frame, no portrait standee)
	karl_sprite_rect = TextureRect.new()
	karl_sprite_rect.name = "KarlSpriteRect"
	karl_sprite_rect.size = Vector2(KARL_ENTITY_WIDTH, KARL_ENTITY_HEIGHT)
	karl_sprite_rect.custom_minimum_size = Vector2(KARL_ENTITY_WIDTH, KARL_ENTITY_HEIGHT)
	karl_sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	karl_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	karl_battlefield_entity.add_child(karl_sprite_rect)

	# Initialize IDLE state
	set_karl_state(KarlState.IDLE)

func _build_top_huds() -> void:
	# Karl HUD: Left 24px, Top 20px, 260x68px
	karl_hud = PanelContainer.new()
	karl_hud.name = "KarlHUD"
	karl_hud.position = Vector2(24, 20)
	karl_hud.custom_minimum_size = Vector2(260, 68)
	karl_hud.size = Vector2(260, 68)
	var karl_box: StyleBoxFlat = _create_glass_box(Color(0.06, 0.09, 0.15, 0.85), Color(0.20, 0.60, 0.85, 0.70), 8)
	karl_hud.add_theme_stylebox_override("panel", karl_box)
	add_child(karl_hud)

	var karl_hbox: HBoxContainer = HBoxContainer.new()
	karl_hbox.add_theme_constant_override("separation", 10)
	karl_hud.add_child(karl_hbox)

	var port_frame: PanelContainer = PanelContainer.new()
	port_frame.custom_minimum_size = Vector2(50, 50)
	var pbox: StyleBoxFlat = _create_glass_box(Color(0.1, 0.14, 0.22, 1.0), COLOR_ACCENT_CYAN, 6)
	port_frame.add_theme_stylebox_override("panel", pbox)
	karl_hbox.add_child(port_frame)

	karl_portrait_rect = TextureRect.new()
	karl_portrait_rect.name = "KarlPortrait"
	karl_portrait_rect.custom_minimum_size = Vector2(46, 46)
	karl_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	karl_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(ASSET_KARL_PORTRAIT):
		karl_portrait_rect.texture = load(ASSET_KARL_PORTRAIT)
	port_frame.add_child(karl_portrait_rect)

	var karl_vbox: VBoxContainer = VBoxContainer.new()
	karl_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	karl_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	karl_hbox.add_child(karl_vbox)

	var karl_name: Label = Label.new()
	karl_name.text = "KARL • TOÁN SƯ TẬP SỰ"
	karl_name.add_theme_font_size_override("font_size", 11)
	karl_name.add_theme_color_override("font_color", COLOR_ACCENT_CYAN)
	karl_vbox.add_child(karl_name)

	var hp_bar: ProgressBar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(170, 14)
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	hp_bar.show_percentage = false
	var hp_bg: StyleBoxFlat = _create_solid_box(Color(0.12, 0.15, 0.22, 0.9), 3)
	var hp_fill: StyleBoxFlat = _create_solid_box(Color(0.20, 0.78, 0.42, 1.0), 3)
	hp_bar.add_theme_stylebox_override("background", hp_bg)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	karl_vbox.add_child(hp_bar)

	var hp_sub: Label = Label.new()
	hp_sub.text = "HP: 100 / 100   •   GIÁP: 0"
	hp_sub.add_theme_font_size_override("font_size", 9)
	hp_sub.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	karl_vbox.add_child(hp_sub)

	# Stochas Boss HUD: Right 24px, Top 20px, 300x68px
	boss_hud = PanelContainer.new()
	boss_hud.name = "StochasHUD"
	boss_hud.position = Vector2(1280.0 - 24.0 - 300.0, 20)
	boss_hud.custom_minimum_size = Vector2(300, 68)
	boss_hud.size = Vector2(300, 68)
	var boss_box: StyleBoxFlat = _create_glass_box(Color(0.12, 0.06, 0.08, 0.88), Color(0.95, 0.30, 0.35, 0.75), 8)
	boss_hud.add_theme_stylebox_override("panel", boss_box)
	add_child(boss_hud)

	var boss_vbox: VBoxContainer = VBoxContainer.new()
	boss_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	boss_vbox.add_theme_constant_override("separation", 2)
	boss_hud.add_child(boss_vbox)

	var boss_name: Label = Label.new()
	boss_name.text = "STOCHAS • CHÚA TỂ XÁC SUẤT"
	boss_name.add_theme_font_size_override("font_size", 12)
	boss_name.add_theme_color_override("font_color", COLOR_ACCENT_RED)
	boss_vbox.add_child(boss_name)

	var boss_hp_bar: ProgressBar = ProgressBar.new()
	boss_hp_bar.custom_minimum_size = Vector2(280, 14)
	boss_hp_bar.max_value = 250.0
	boss_hp_bar.value = 250.0
	boss_hp_bar.show_percentage = false
	var b_bg: StyleBoxFlat = _create_solid_box(Color(0.20, 0.10, 0.12, 0.9), 3)
	var b_fill: StyleBoxFlat = _create_solid_box(Color(0.90, 0.22, 0.25, 1.0), 3)
	boss_hp_bar.add_theme_stylebox_override("background", b_bg)
	boss_hp_bar.add_theme_stylebox_override("fill", b_fill)
	boss_vbox.add_child(boss_hp_bar)

	var boss_intent: Label = Label.new()
	boss_intent.text = "HP: 250 / 250   •   Ý ĐỊNH: 10 DMG (ĐÒN QUÉT)"
	boss_intent.add_theme_font_size_override("font_size", 9)
	boss_intent.add_theme_color_override("font_color", Color(1.0, 0.8, 0.8, 0.85))
	boss_vbox.add_child(boss_intent)

func _build_question_module() -> void:
	# Center X = 690px, Top = 160px, Width = 640px
	var start_x: float = CENTER_INTERACTION_X - (QUESTION_WIDTH / 2.0)
	question_panel = PanelContainer.new()
	question_panel.name = "QuestionPanel"
	question_panel.position = Vector2(start_x, QUESTION_TOP)
	question_panel.custom_minimum_size = Vector2(QUESTION_WIDTH, QUESTION_HEIGHT)
	question_panel.size = Vector2(QUESTION_WIDTH, QUESTION_HEIGHT)

	var q_box: StyleBoxFlat = _create_glass_box(COLOR_PANEL_BG, COLOR_PANEL_BORDER, 10)
	q_box.content_margin_left = 14
	q_box.content_margin_top = 10
	q_box.content_margin_right = 14
	q_box.content_margin_bottom = 10
	question_panel.add_theme_stylebox_override("panel", q_box)
	add_child(question_panel)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	question_panel.add_child(main_vbox)

	# 1. Header Row
	var header_hbox: HBoxContainer = HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	question_stage_label = Label.new()
	question_stage_label.text = "ARCANE CHALLENGE • CÂU HỎI 1 / 3"
	question_stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_stage_label.add_theme_font_size_override("font_size", 11)
	question_stage_label.add_theme_color_override("font_color", COLOR_ACCENT_CYAN)
	header_hbox.add_child(question_stage_label)

	var round_lbl: Label = Label.new()
	round_lbl.name = "RoundLabel"
	round_lbl.text = "GIAI ĐOẠN 1 • 45s"
	round_lbl.add_theme_font_size_override("font_size", 10)
	round_lbl.add_theme_color_override("font_color", COLOR_ACCENT_GOLD)
	header_hbox.add_child(round_lbl)

	# 2. Question Prompt (compact, readable)
	question_prompt_label = Label.new()
	question_prompt_label.custom_minimum_size = Vector2(612, 38)
	question_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_prompt_label.add_theme_font_size_override("font_size", 12)
	question_prompt_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	main_vbox.add_child(question_prompt_label)

	# 3. Answer Options: ONE HORIZONTAL 4-OPTION ROW (Approved Stitch Layout)
	var answer_row: HBoxContainer = HBoxContainer.new()
	answer_row.name = "AnswerRow"
	answer_row.add_theme_constant_override("separation", 8)
	main_vbox.add_child(answer_row)

	answer_buttons.clear()
	for i in range(4):
		var btn: Button = Button.new()
		btn.name = "AnswerBtn_%d" % i
		btn.custom_minimum_size = Vector2(146, 42)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(select_answer.bind(i))
		answer_row.add_child(btn)
		answer_buttons.append(btn)

	# 4. Action Row (Hint + Primary XUẤT CHIÊU CTA)
	var action_hbox: HBoxContainer = HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 10)
	action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(action_hbox)

	hint_button = Button.new()
	hint_button.name = "HintButton"
	hint_button.text = "💡 GỢI Ý"
	hint_button.custom_minimum_size = Vector2(100, 38)
	var hint_box: StyleBoxFlat = _create_glass_box(Color(0.12, 0.16, 0.24, 0.85), Color(0.40, 0.55, 0.70, 0.70), 6)
	hint_button.add_theme_stylebox_override("normal", hint_box)
	hint_button.add_theme_font_size_override("font_size", 11)
	hint_button.pressed.connect(_on_hint_pressed)
	action_hbox.add_child(hint_button)

	cta_button = Button.new()
	cta_button.name = "SubmitCTAButton"
	cta_button.text = "XUẤT CHIÊU: TẤN CÔNG (10 DMG)"
	cta_button.custom_minimum_size = Vector2(260, 42)
	cta_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cta_box: StyleBoxFlat = _create_solid_box(Color(0.12, 0.55, 0.82, 0.98), 6)
	cta_box.border_width_left = 1
	cta_box.border_width_top = 1
	cta_box.border_width_right = 1
	cta_box.border_width_bottom = 1
	cta_box.border_color = Color(0.45, 0.90, 1.0, 0.95)
	cta_box.shadow_color = Color(0.15, 0.75, 1.0, 0.45)
	cta_box.shadow_size = 6
	cta_button.add_theme_stylebox_override("normal", cta_box)
	cta_button.add_theme_font_size_override("font_size", 12)
	cta_button.pressed.connect(_on_cta_pressed)
	action_hbox.add_child(cta_button)

	# 5. Combat rule subtext + Shortcuts guide
	helper_label = Label.new()
	helper_label.text = "Quy tắc: Đúng -> Thi triển chiêu thức. Sai -> STOCHAS phản đòn 10 DMG. | Phím: [1-4] Thẻ, [I/C/H/E/S] Karl, [D] Debug"
	helper_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	helper_label.add_theme_font_size_override("font_size", 9)
	helper_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	main_vbox.add_child(helper_label)

func _build_card_hover_detail() -> void:
	# Shared center X = 690px, positioned ~20-30px above card row
	var start_x: float = CENTER_INTERACTION_X - (HOVER_DETAIL_WIDTH / 2.0)
	hover_detail_panel = PanelContainer.new()
	hover_detail_panel.name = "CardHoverDetailPanel"
	hover_detail_panel.position = Vector2(start_x, HOVER_DETAIL_Y)
	hover_detail_panel.custom_minimum_size = Vector2(HOVER_DETAIL_WIDTH, HOVER_DETAIL_HEIGHT)
	hover_detail_panel.size = Vector2(HOVER_DETAIL_WIDTH, HOVER_DETAIL_HEIGHT)

	var h_box: StyleBoxFlat = _create_glass_box(Color(0.06, 0.08, 0.14, 0.92), COLOR_PANEL_BORDER, 6)
	h_box.content_margin_left = 12
	h_box.content_margin_top = 4
	h_box.content_margin_right = 12
	h_box.content_margin_bottom = 4
	hover_detail_panel.add_theme_stylebox_override("panel", h_box)
	add_child(hover_detail_panel)

	var h_vbox: VBoxContainer = VBoxContainer.new()
	h_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	h_vbox.add_theme_constant_override("separation", 1)
	hover_detail_panel.add_child(h_vbox)

	hover_title_lbl = Label.new()
	hover_title_lbl.name = "HoverTitleLabel"
	hover_title_lbl.text = "TẤN CÔNG"
	hover_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_title_lbl.add_theme_font_size_override("font_size", 11)
	hover_title_lbl.add_theme_color_override("font_color", COLOR_ACCENT_RED)
	h_vbox.add_child(hover_title_lbl)

	hover_desc_lbl = Label.new()
	hover_desc_lbl.name = "HoverDescLabel"
	hover_desc_lbl.text = "Gây 10 sát thương chuẩn lên STOCHAS"
	hover_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_desc_lbl.add_theme_font_size_override("font_size", 10)
	hover_desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.9))
	h_vbox.add_child(hover_desc_lbl)

func _build_card_row() -> void:
	# Shared center X = 690px, Bottom = 20px
	var total_width: float = 4.0 * CARD_WIDTH + 3.0 * CARD_GAP
	var start_x: float = CENTER_INTERACTION_X - (total_width / 2.0)
	var start_y: float = 720.0 - CARD_ROW_BOTTOM - CARD_HEIGHT

	var card_container: HBoxContainer = HBoxContainer.new()
	card_container.name = "CardRowContainer"
	card_container.position = Vector2(start_x, start_y)
	card_container.add_theme_constant_override("separation", int(CARD_GAP))
	add_child(card_container)

	card_panels.clear()
	card_art_rects.clear()

	for i in range(cards_data.size()):
		var data: Dictionary = cards_data[i]
		var card_panel: PanelContainer = PanelContainer.new()
		card_panel.name = "CardShell_%s" % data["id"]
		card_panel.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card_panel.size = Vector2(CARD_WIDTH, CARD_HEIGHT)

		var shell_box: StyleBoxFlat = _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 6)
		card_panel.add_theme_stylebox_override("panel", shell_box)
		card_container.add_child(card_panel)
		card_panels.append(card_panel)

		# Make card clickable & hoverable
		var hit_btn: Button = Button.new()
		hit_btn.flat = true
		hit_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		hit_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		hit_btn.pressed.connect(select_card.bind(i))
		hit_btn.mouse_entered.connect(_on_card_mouse_entered.bind(i))
		hit_btn.mouse_exited.connect(_on_card_mouse_exited.bind(i))
		card_panel.add_child(hit_btn)

		# Artwork fills the body, NO permanent numbers below cards!
		var art_rect: TextureRect = TextureRect.new()
		art_rect.name = "Art_%s" % data["id"]
		art_rect.custom_minimum_size = Vector2(CARD_WIDTH - 8, CARD_HEIGHT - 8)
		art_rect.size = Vector2(CARD_WIDTH - 8, CARD_HEIGHT - 8)
		art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if ResourceLoader.exists(data["asset"]):
			art_rect.texture = load(data["asset"])
		card_panel.add_child(art_rect)
		card_art_rects.append(art_rect)

		if data["disabled"]:
			card_panel.modulate = Color(0.5, 0.5, 0.55, 0.60)

func _build_settings_button() -> void:
	var settings_btn: Button = Button.new()
	settings_btn.name = "SettingsButton"
	settings_btn.text = "⚙ CÀI ĐẶT"
	settings_btn.position = Vector2(1280.0 - 24.0 - 100.0, 720.0 - 20.0 - 36.0)
	settings_btn.custom_minimum_size = Vector2(100, 36)
	var set_box: StyleBoxFlat = _create_glass_box(Color(0.08, 0.10, 0.16, 0.85), Color(0.30, 0.45, 0.60, 0.60), 6)
	settings_btn.add_theme_stylebox_override("normal", set_box)
	settings_btn.add_theme_font_size_override("font_size", 11)
	add_child(settings_btn)

func _build_floating_status_container() -> void:
	floating_status_container = Control.new()
	floating_status_container.name = "FloatingStatusContainer"
	floating_status_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	floating_status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floating_status_container)

func _build_debug_overlay() -> void:
	debug_overlay = Control.new()
	debug_overlay.name = "DebugOverlay"
	debug_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	debug_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_overlay.visible = false
	add_child(debug_overlay)

	# Shared Center Axis Line (X = 690)
	var axis_line: Line2D = Line2D.new()
	axis_line.name = "CenterAxisLine"
	axis_line.default_color = Color(1.0, 0.8, 0.2, 0.6)
	axis_line.width = 1.0
	axis_line.add_point(Vector2(CENTER_INTERACTION_X, 100))
	axis_line.add_point(Vector2(CENTER_INTERACTION_X, 710))
	debug_overlay.add_child(axis_line)

	var axis_lbl: Label = Label.new()
	axis_lbl.text = "Axis X = 690"
	axis_lbl.position = Vector2(CENTER_INTERACTION_X - 35, 105)
	axis_lbl.add_theme_font_size_override("font_size", 9)
	axis_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 0.9))
	debug_overlay.add_child(axis_lbl)

	# Karl entity outline
	var k_outline: ReferenceRect = ReferenceRect.new()
	k_outline.position = Vector2(KARL_ENTITY_LEFT, 720.0 - KARL_ENTITY_BOTTOM - KARL_ENTITY_HEIGHT)
	k_outline.size = Vector2(KARL_ENTITY_WIDTH, KARL_ENTITY_HEIGHT)
	k_outline.border_color = Color(0.2, 0.7, 1.0, 0.9)
	k_outline.border_width = 1.5
	k_outline.editor_only = false
	debug_overlay.add_child(k_outline)

	var k_lbl: Label = Label.new()
	k_lbl.text = "Karl 220x220 (Left: 70, Bottom: 70, Base: 650)"
	k_lbl.position = Vector2(KARL_ENTITY_LEFT, 720.0 - KARL_ENTITY_BOTTOM - KARL_ENTITY_HEIGHT - 16)
	k_lbl.add_theme_font_size_override("font_size", 9)
	k_lbl.add_theme_color_override("font_color", Color(0.2, 0.7, 1.0, 0.9))
	debug_overlay.add_child(k_lbl)

	# Question outline
	var q_outline: ReferenceRect = ReferenceRect.new()
	q_outline.position = Vector2(CENTER_INTERACTION_X - (QUESTION_WIDTH / 2.0), QUESTION_TOP)
	q_outline.size = Vector2(QUESTION_WIDTH, QUESTION_HEIGHT)
	q_outline.border_color = Color(1.0, 0.2, 0.8, 0.9)
	q_outline.border_width = 1.5
	q_outline.editor_only = false
	debug_overlay.add_child(q_outline)

	# Hover detail outline
	var h_outline: ReferenceRect = ReferenceRect.new()
	h_outline.position = Vector2(CENTER_INTERACTION_X - (HOVER_DETAIL_WIDTH / 2.0), HOVER_DETAIL_Y)
	h_outline.size = Vector2(HOVER_DETAIL_WIDTH, HOVER_DETAIL_HEIGHT)
	h_outline.border_color = Color(0.2, 0.8, 1.0, 0.9)
	h_outline.border_width = 1.5
	h_outline.editor_only = false
	debug_overlay.add_child(h_outline)

	# Card row outline
	var total_w: float = 4.0 * CARD_WIDTH + 3.0 * CARD_GAP
	var c_outline: ReferenceRect = ReferenceRect.new()
	c_outline.position = Vector2(CENTER_INTERACTION_X - (total_w / 2.0), 720.0 - CARD_ROW_BOTTOM - CARD_HEIGHT)
	c_outline.size = Vector2(total_w, CARD_HEIGHT)
	c_outline.border_color = Color(0.2, 1.0, 0.3, 0.9)
	c_outline.border_width = 1.5
	c_outline.editor_only = false
	debug_overlay.add_child(c_outline)

func _update_card_selection() -> void:
	for i in range(card_panels.size()):
		var panel: PanelContainer = card_panels[i]
		var is_selected: bool = (i == selected_card_idx)
		var is_disabled: bool = cards_data[i]["disabled"]

		if is_disabled:
			panel.position.y = 0
			var dis_style: StyleBoxFlat = _create_card_style(Color(0.06, 0.08, 0.12, 0.8), Color(0.25, 0.30, 0.40, 0.4), 6)
			panel.add_theme_stylebox_override("panel", dis_style)
		elif is_selected:
			panel.position.y = -8.0 # Small lift
			var sel_style: StyleBoxFlat = _create_card_style(Color(0.12, 0.16, 0.25, 0.98), COLOR_CARD_SELECTED_BORDER, 6)
			sel_style.border_width_left = 2
			sel_style.border_width_top = 2
			sel_style.border_width_right = 2
			sel_style.border_width_bottom = 2
			sel_style.shadow_color = Color(1.0, 0.85, 0.30, 0.35)
			sel_style.shadow_size = 8
			panel.add_theme_stylebox_override("panel", sel_style)
		else:
			panel.position.y = 0
			var norm_style: StyleBoxFlat = _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 6)
			panel.add_theme_stylebox_override("panel", norm_style)

func _update_hover_detail(idx: int) -> void:
	if hover_title_lbl == null or hover_desc_lbl == null:
		return
	var card = cards_data[idx]
	hover_title_lbl.text = card["name"]
	hover_title_lbl.add_theme_color_override("font_color", card["color"])
	hover_desc_lbl.text = card["effect"]

func _on_card_mouse_entered(idx: int) -> void:
	hovered_card_idx = idx
	_update_hover_detail(idx)

func _on_card_mouse_exited(_idx: int) -> void:
	hovered_card_idx = selected_card_idx
	_update_hover_detail(selected_card_idx)

func _update_question_view() -> void:
	var q_data: Dictionary = questions_data[current_question_idx]
	question_stage_label.text = q_data["stage"]
	var round_lbl = question_panel.find_child("RoundLabel", true, false) as Label
	if round_lbl != null:
		round_lbl.text = q_data["round"]
	question_prompt_label.text = q_data["prompt"]

	for i in range(4):
		var btn: Button = answer_buttons[i]
		var c = q_data["choices"][i]
		btn.text = "[ %s ]  %s" % [c["code"], c["val"]]

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
		btn_style.content_margin_left = 8
		btn_style.content_margin_right = 8
		btn_style.content_margin_top = 4
		btn_style.content_margin_bottom = 4

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
	cta_button.text = "XUẤT CHIÊU: %s (%s)" % [card["name"], card["stat_badge"]]

func _on_hint_pressed() -> void:
	hint_shown = not hint_shown
	var q_data: Dictionary = questions_data[current_question_idx]
	if hint_shown:
		_spawn_floating_feedback(Vector2(690, 130), q_data["hint"], COLOR_ACCENT_GOLD)

func _on_cta_pressed() -> void:
	var q_data: Dictionary = questions_data[current_question_idx]
	var is_correct: bool = (selected_answer_idx == q_data["correct"])
	var card: Dictionary = cards_data[selected_card_idx]

	if is_correct:
		if card["id"] == "strike":
			trigger_cast_effect()
		elif card["id"] == "defend":
			trigger_shield_effect()
		elif card["id"] == "heal":
			trigger_heal_effect()
	else:
		trigger_hit_effect()
		_spawn_floating_feedback(Vector2(1040, 240), "PHẢN ĐÒN!", COLOR_ACCENT_RED)

func _spawn_floating_feedback(pos: Vector2, text: String, color: Color) -> void:
	if floating_status_container == null:
		return
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.position = pos - Vector2(100, 10)
	lbl.custom_minimum_size = Vector2(200, 24)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", color)
	floating_status_container.add_child(lbl)

	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", pos.y - 35.0, 1.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.8).set_delay(0.6)
	tw.chain().tween_callback(lbl.queue_free)

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
	box.content_margin_left = 4
	box.content_margin_top = 4
	box.content_margin_right = 4
	box.content_margin_bottom = 4
	return box
