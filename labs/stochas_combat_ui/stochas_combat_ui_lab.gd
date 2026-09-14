extends Control

## MATHOS-PROBABILITY-GACHA-VFX-LAB-INTEGRATION-232L
## Refined Visual Proportions: Question Panel (610 x 240 px) & Karl Entity (300 x 300 px)
## WAD2 Combat VFX + Karl Projectile + STOCHAS Multi-Spells + Probability Gacha V1
## Viewport: 1280 x 720

# AI / Presentation Event Signals (Contract for Future AI / Presentation Integration)
signal probability_charge_changed(current: int, max_val: int)
signal probability_ready()
signal probability_draw_started()
signal probability_cards_revealed(cards: Array)
signal tactical_card_selected(card_id: String, slot: int)
signal tactical_card_used(card_id: String)
signal stun_armed()
signal stun_triggered()
signal critical_armed()
signal critical_triggered(damage: int)
signal aegis_triggered(shield_gain: int)

# Authoritative Composition Grid & Axis
const CENTER_INTERACTION_X: float = 690.0
const QUESTION_CENTER_X: float = 640.0

# Question Module (Refined Compact Proportion: 610 x 240 px, Center X = 640.0)
const QUESTION_WIDTH: float = 610.0
const QUESTION_TOP: float = 155.0
const QUESTION_HEIGHT: float = 240.0

# Question Combat Mode
const QUESTION_COMBAT_ALPHA: float = 0.22
const QUESTION_FADE_OUT_DURATION: float = 0.20
const QUESTION_FADE_IN_DURATION: float = 0.24

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

# Karl Battlefield Entity (Refined Proportion: 300 x 300 px, Left: 50, Bottom: 70)
const KARL_ENTITY_LEFT: float = 50.0
const KARL_ENTITY_BOTTOM: float = 70.0
const KARL_ENTITY_WIDTH: float = 300.0
const KARL_ENTITY_HEIGHT: float = 300.0

# Asset paths (canonical production assets)
const ASSET_BG: String = "res://assets/backgrounds/d1_misty_forest_bg.png"
const ASSET_KARL_PORTRAIT: String = "res://assets/characters/player/karl/karl_portrait.png"
const ASSET_BOSS: String = "res://assets/characters/bosses/dungeon_1/stochas_boss.png"
const ASSET_CARD_STRIKE: String = "res://assets/ui/combat/cards_v1/STRIKE.png"
const ASSET_CARD_DEFEND: String = "res://assets/ui/combat/cards_v1/DEFEND.png"
const ASSET_CARD_HEAL: String = "res://assets/ui/combat/cards_v1/HEAL.png"
const ASSET_CARD_PROBABILITY: String = "res://assets/ui/combat/cards_v1/PROBABILITY.png"

# WAD2 Combat VFX Assets
const ASSET_VFX_KARL_PROJECTILE: String = "res://assets/vfx/combat/karl_arcane_projectile.png"
const ASSET_VFX_STOCHAS_BOLT: String = "res://assets/vfx/combat/stochas_arcane_bolt.png"
const ASSET_VFX_STOCHAS_ORB: String = "res://assets/vfx/combat/stochas_probability_orb.png"
const ASSET_VFX_STOCHAS_RIFT: String = "res://assets/vfx/combat/stochas_void_rift.png"
const ASSET_VFX_STOCHAS_SWEEP: String = "res://assets/vfx/combat/stochas_arcane_sweep.png"

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
enum KarlState { IDLE, CAST, HIT, HEAL, SHIELD, DODGE, SKILL_CAST }
const STRIKE_CAST = KarlState.CAST
var current_karl_state: KarlState = KarlState.IDLE
var karl_textures: Dictionary = {}
var karl_sprite_rect: TextureRect = null
var karl_vfx_container: Control = null
var karl_state_tween: Tween = null
var current_karl_hp: int = 100
var max_karl_hp: int = 100
var current_shield: int = 0
var karl_persistent_barrier: Panel = null
var karl_persistent_barrier_tween: Tween = null
var karl_hp_sub_label: Label = null
var combat_resolving: bool = false
var question_fade_tween: Tween = null

# Boss Combat States & Spells
enum BossState {
	IDLE,
	CAST,
	HIT,
	STUN,
	ENRAGED,
	CAST_BOLT,
	CAST_ORB,
	CAST_RIFT,
	CAST_SWEEP,
	ULTIMATE_CHARGE,
	ULTIMATE_RELEASE
}
enum BossSpellType { ARCANE_BOLT, PROBABILITY_ORB, VOID_RIFT, ARCANE_SWEEP, CHAOS_VERDICT_ULTIMATE }

const BOSS_SPELL_DAMAGE: Dictionary = {
	BossSpellType.ARCANE_BOLT: 8,
	BossSpellType.PROBABILITY_ORB: 10,
	BossSpellType.VOID_RIFT: 12,
	BossSpellType.ARCANE_SWEEP: 14,
	BossSpellType.CHAOS_VERDICT_ULTIMATE: 24
}

# Future Asset Hooks (Contract Placeholders)
const ASSET_KARL_DODGE_SEQUENCE: String = "res://assets/characters/player/karl/combat_pixel/karl_dodge_sequence.png"
const ASSET_KARL_SKILL_CAST_SEQUENCE: String = "res://assets/characters/player/karl/combat_pixel/karl_skill_cast_sequence.png"
const ASSET_KARL_CARD_HAND_CURSOR: String = "res://assets/ui/combat/karl_card_hand_cursor.png"
const ASSET_STOCHAS_ULTIMATE_SEQUENCE: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_sequence.png"
const ASSET_TACTICAL_ATLAS: String = "res://assets/ui/combat/tactical_cards_v1_atlas.png"

const TACTICAL_ATLAS_REGIONS: Dictionary = {
	"LOAI_TRU": Rect2(0, 0, 104, 158),
	"DOI_CAU": Rect2(104, 0, 104, 158),
	"THEM_GIO": Rect2(208, 0, 104, 158),
	"CHOANG": Rect2(312, 0, 104, 158),
	"CRITICAL": Rect2(416, 0, 104, 158),
	"BAO_HO": Rect2(520, 0, 104, 158)
}
const TACTICAL_CARD_ATLAS_MAP: Dictionary = {
	"card_tactical_eliminate": "LOAI_TRU",
	"card_tactical_reroll": "DOI_CAU",
	"card_tactical_add_time": "THEM_GIO",
	"card_tactical_stun": "CHOANG",
	"card_tactical_critical": "CRITICAL",
	"card_tactical_aegis": "BAO_HO"
}

# Boss Ultimate Parameters
const BOSS_ULTIMATE_METER_MAX: int = 4
const ULTIMATE_CHARGE_DURATION: float = 2.4
const ULTIMATE_CHALLENGE_DURATION: float = 8.0

var boss_ultimate_meter: int = 0
var is_ultimate_queued: bool = false
var is_ultimate_charge_active: bool = false
var is_ultimate_challenge_active: bool = false
var ultimate_timer: float = 8.0
var ultimate_telegraph_panel: Control = null
var ultimate_dim_overlay: ColorRect = null
var is_tactical_pick_mode: bool = false
var hand_cursor_node: Control = null
var card_row_container: HBoxContainer = null

var current_boss_state: BossState = BossState.IDLE
var is_boss_enraged: bool = false
var boss_idle_tween: Tween = null
var boss_action_tween: Tween = null
var boss_aura_rect: Panel = null
var boss_ground_shadow: Panel = null
var boss_vfx_container: Control = null
var boss_stun_overlay: Control = null
var current_boss_hp: int = 250
var max_boss_hp: int = 250
var boss_hp_bar: ProgressBar = null
var boss_intent_label: Label = null
var boss_spell_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# STOCHAS Base Constants & Animation Parameters
const BOSS_BASE_POS: Vector2 = Vector2(800.0, 130.0) # 1280 - 480 - 0 = 800, 720 - 520 - 70 = 130
const BOSS_BASE_SIZE: Vector2 = Vector2(480.0, 520.0)
const BOSS_IDLE_FLOAT_OFFSET: float = 6.0
const BOSS_IDLE_BREATHING_SCALE: Vector2 = Vector2(1.008, 0.995)
const BOSS_IDLE_CYCLE_DURATION: float = 3.2
const BOSS_ENRAGED_CYCLE_DURATION: float = 1.8

# Baseline offsets for exact 650.0 ground alignment at 300px scale
const KARL_BASELINE_OFFSETS: Dictionary = {
	KarlState.IDLE: 6.2,
	KarlState.CAST: 0.0,
	KarlState.HIT: 6.2,
	KarlState.HEAL: 0.0,
	KarlState.SHIELD: 3.8,
	KarlState.DODGE: 6.2,
	KarlState.SKILL_CAST: 0.0,
}

# Combat Buffs & Tactical State
var is_critical_armed: bool = false
var is_stun_armed: bool = false
var stochas_stun_charges: int = 0

# Probability Gacha V1 System
const PROBABILITY_METER_MAX: int = 3
var probability_meter: int = 0
var consecutive_no_rare_draws: int = 0
var gacha_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var is_draw_open: bool = false
var probability_draw_modal: Control = null
var draw_cards_container: HBoxContainer = null
var replace_modal: Control = null
var pending_draft_card: Dictionary = {}

# Tactical Hand (Capacity 3)
const MAX_TACTICAL_HAND: int = 3
var tactical_hand: Array[Dictionary] = []
var tactical_hand_tray: PanelContainer = null
var tactical_slot_buttons: Array[Button] = []

# Question Timer
var question_timer_seconds: float = 45.0
const QUESTION_TIMER_MAX: float = 90.0

# Tactical Cards Registry
const TACTICAL_CARDS: Dictionary = {
	"card_tactical_eliminate": {
		"id": "card_tactical_eliminate",
		"name": "LOẠI TRỪ",
		"rarity": "COMMON",
		"weight": 70,
		"desc": "Loại bỏ 1 đáp án sai trong câu hỏi hiện tại.",
		"color": Color(0.35, 0.75, 1.0, 1.0)
	},
	"card_tactical_reroll": {
		"id": "card_tactical_reroll",
		"name": "ĐỔI CÂU",
		"rarity": "COMMON",
		"weight": 70,
		"desc": "Đổi sang câu hỏi khác cùng độ khó. Không tốn lượt.",
		"color": Color(0.35, 0.75, 1.0, 1.0)
	},
	"card_tactical_add_time": {
		"id": "card_tactical_add_time",
		"name": "THÊM GIỜ",
		"rarity": "COMMON",
		"weight": 70,
		"desc": "+15 giây thời gian suy nghĩ (tối đa 90s).",
		"color": Color(0.35, 0.75, 1.0, 1.0)
	},
	"card_tactical_stun": {
		"id": "card_tactical_stun",
		"name": "CHOÁNG",
		"rarity": "RARE",
		"weight": 30,
		"desc": "Nếu đúng, làm choáng STOCHAS và vô hiệu hóa 1 đòn phản kích tiếp theo.",
		"color": Color(1.0, 0.82, 0.28, 1.0)
	},
	"card_tactical_critical": {
		"id": "card_tactical_critical",
		"name": "CRITICAL",
		"rarity": "RARE",
		"weight": 30,
		"desc": "Đòn Tấn Công chính xác tiếp theo gây 15 sát thương (+5 DMG).",
		"color": Color(1.0, 0.82, 0.28, 1.0)
	},
	"card_tactical_aegis": {
		"id": "card_tactical_aegis",
		"name": "BẢO HỘ",
		"rarity": "RARE",
		"weight": 30,
		"desc": "Nhận ngay +6 Giáp (tối đa 24 Giáp). Không tốn lượt.",
		"color": Color(1.0, 0.82, 0.28, 1.0)
	}
}

# State
var selected_card_idx: int = 0
var hovered_card_idx: int = 0
var selected_answer_idx: int = -1
var has_selected_answer: bool = false
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
		"name": "XÁC SUẤT",
		"effect": "Tích lũy 3 điểm khi trả lời đúng để Rút bài Chiến thuật.",
		"stat_badge": "0/3",
		"color": COLOR_ACCENT_PURPLE,
		"asset": ASSET_CARD_PROBABILITY,
		"disabled": true
	}
]

func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	clip_contents = true

	# Initialize deterministically seeded RNG
	gacha_rng.seed = 20260913
	boss_spell_rng.seed = 1337

	_load_karl_textures()
	_build_scene()
	_update_card_selection()
	_update_hover_detail(selected_card_idx)
	_update_question_view()
	_update_tactical_hand_ui()
	_update_probability_card_ui()

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

func _process(delta: float) -> void:
	if is_ultimate_challenge_active and not combat_resolving:
		ultimate_timer -= delta
		if helper_label != null:
			helper_label.text = "THỜI GIAN CÒN LẠI: %.1fs  •  PHÁ GIẢI TRƯỚC KHI HẾT GIỜ!" % max(0.0, ultimate_timer)
		if ultimate_timer <= 0.0:
			trigger_ultimate_failure(true)

func _input(event: InputEvent) -> void:
	if is_tactical_pick_mode and hand_cursor_node != null and event is InputEventMouseMotion:
		hand_cursor_node.position = event.position + Vector2(16, 16)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	if combat_resolving and event.keycode != KEY_D and event.keycode != KEY_R:
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
		KEY_K:
			clear_shield()
		KEY_B:
			trigger_boss_idle()
		KEY_V:
			trigger_boss_cast()
		KEY_N:
			trigger_boss_hit()
		KEY_M:
			trigger_boss_stun()
		KEY_L:
			toggle_boss_enraged()
		KEY_F1:
			trigger_boss_spell_arcane_bolt()
		KEY_F2:
			trigger_boss_spell_probability_orb()
		KEY_F3:
			trigger_boss_spell_void_rift()
		KEY_F4:
			trigger_boss_spell_arcane_sweep()
		KEY_F5:
			trigger_boss_ultimate_charge()
		KEY_F6:
			set_ultimate_meter(3)
		KEY_F7:
			simulate_ultimate_success()
		KEY_F8:
			simulate_ultimate_failure()

# Getters for Verification & Contract
func get_center_interaction_x() -> float:
	return CENTER_INTERACTION_X

func get_question_center_x() -> float:
	return QUESTION_CENTER_X

func get_boss_head_clearance() -> float:
	var q_pos: Vector2 = get_question_position()
	var q_sz: Vector2 = get_question_size()
	var question_right_x: float = q_pos.x + q_sz.x
	return 1040.0 - question_right_x

func get_current_karl_hp() -> int:
	return current_karl_hp

func get_max_karl_hp() -> int:
	return max_karl_hp

func get_current_boss_hp() -> int:
	return current_boss_hp

func get_max_boss_hp() -> int:
	return max_boss_hp

func is_combat_resolving() -> bool:
	return combat_resolving

func get_boss_ultimate_meter() -> int:
	return boss_ultimate_meter

func get_boss_ultimate_meter_max() -> int:
	return BOSS_ULTIMATE_METER_MAX

func get_ultimate_timer() -> float:
	return ultimate_timer

func is_ultimate_active() -> bool:
	return is_ultimate_charge_active or is_ultimate_challenge_active

func is_ultimate_challenge() -> bool:
	return is_ultimate_challenge_active

func get_boss_spell_damage(spell: BossSpellType) -> int:
	return BOSS_SPELL_DAMAGE.get(spell, 10)

func has_karl_dodge_asset() -> bool:
	return ResourceLoader.exists(ASSET_KARL_DODGE_SEQUENCE)

func has_karl_skill_cast_asset() -> bool:
	return ResourceLoader.exists(ASSET_KARL_SKILL_CAST_SEQUENCE)

func has_karl_hand_cursor_asset() -> bool:
	return ResourceLoader.exists(ASSET_KARL_CARD_HAND_CURSOR)

func has_stochas_ultimate_asset() -> bool:
	return ResourceLoader.exists(ASSET_STOCHAS_ULTIMATE_SEQUENCE)

func has_tactical_card_atlas() -> bool:
	return ResourceLoader.exists(ASSET_TACTICAL_ATLAS)

func get_question_alpha() -> float:
	if question_panel == null:
		return 1.0
	return question_panel.modulate.a

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
	if question_panel == null:
		return Vector2(QUESTION_CENTER_X - (QUESTION_WIDTH / 2.0), QUESTION_TOP)
	return question_panel.position

func get_question_size() -> Vector2:
	if question_panel == null:
		return Vector2(QUESTION_WIDTH, QUESTION_HEIGHT)
	return question_panel.size

func get_answer_button_size() -> Vector2:
	if answer_buttons.size() > 0 and answer_buttons[0] != null:
		return answer_buttons[0].size
	return Vector2(138, 44)

func get_hover_detail_position() -> Vector2:
	return Vector2(CENTER_INTERACTION_X - (HOVER_DETAIL_WIDTH / 2.0), HOVER_DETAIL_Y)

func get_boss_position() -> Vector2:
	return Vector2(1280.0 - BOSS_WIDTH - BOSS_RIGHT, 720.0 - BOSS_HEIGHT - BOSS_BOTTOM)

func get_boss_size() -> Vector2:
	return Vector2(BOSS_WIDTH, BOSS_HEIGHT)

func get_boss_actual_position() -> Vector2:
	if boss_rect != null:
		return boss_rect.position
	return BOSS_BASE_POS

func get_boss_state() -> int:
	return current_boss_state

func is_boss_enraged_active() -> bool:
	return is_boss_enraged

func get_karl_position() -> Vector2:
	return Vector2(KARL_ENTITY_LEFT, 720.0 - KARL_ENTITY_HEIGHT - KARL_ENTITY_BOTTOM)

func get_karl_size() -> Vector2:
	return Vector2(KARL_ENTITY_WIDTH, KARL_ENTITY_HEIGHT)

func get_karl_baseline() -> float:
	var base_y: float = 720.0 - KARL_ENTITY_HEIGHT - KARL_ENTITY_BOTTOM
	var baseline_offset: float = KARL_BASELINE_OFFSETS.get(current_karl_state, 0.0)
	return base_y + KARL_ENTITY_HEIGHT - baseline_offset

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
	return karl_battlefield_entity != null

func is_combat_feed_present() -> bool:
	return false

func has_permanent_card_stats() -> bool:
	return false

func get_probability_meter() -> int:
	return probability_meter

func get_tactical_hand_size() -> int:
	return tactical_hand.size()

func get_tactical_hand() -> Array[Dictionary]:
	return tactical_hand

func is_critical_armed_active() -> bool:
	return is_critical_armed

func is_stun_armed_active() -> bool:
	return is_stun_armed

func get_stochas_stun_charges() -> int:
	return stochas_stun_charges

func get_question_timer() -> float:
	return question_timer_seconds

func select_card(idx: int) -> void:
	if combat_resolving or is_draw_open or idx < 0 or idx >= cards_data.size():
		return

	if idx == 3:
		# Probability Card Interaction
		if probability_meter >= PROBABILITY_METER_MAX:
			set_probability_meter(0)
			trigger_probability_draw_sequence()
		else:
			_spawn_floating_feedback(Vector2(690, 460), "XÁC SUẤT %d/3" % probability_meter, COLOR_ACCENT_PURPLE)
		return

	selected_card_idx = idx
	hovered_card_idx = idx
	_update_card_selection()
	_update_hover_detail(selected_card_idx)
	_update_cta_button_text()

func cycle_question() -> void:
	if combat_resolving or is_draw_open:
		return
	current_question_idx = (current_question_idx + 1) % questions_data.size()
	selected_answer_idx = -1
	has_selected_answer = false
	hint_shown = false
	question_timer_seconds = 45.0
	for btn in answer_buttons:
		btn.disabled = false
	_update_question_view()

func cycle_answer() -> void:
	if combat_resolving or is_draw_open:
		return
	var next_idx: int = (selected_answer_idx + 1) % 4
	while answer_buttons[next_idx].disabled and next_idx != selected_answer_idx:
		next_idx = (next_idx + 1) % 4
	select_answer(next_idx)

func select_answer(idx: int) -> void:
	if combat_resolving or is_draw_open or idx < 0 or idx >= 4:
		return
	if answer_buttons.size() > idx and answer_buttons[idx].disabled:
		return
	selected_answer_idx = idx
	has_selected_answer = true
	_update_answer_selection()

func reset_lab() -> void:
	current_karl_hp = 100
	max_karl_hp = 100
	current_shield = 0
	current_boss_hp = 250
	max_boss_hp = 250
	combat_resolving = false
	is_boss_enraged = false
	is_critical_armed = false
	is_stun_armed = false
	stochas_stun_charges = 0
	probability_meter = 0
	consecutive_no_rare_draws = 0
	boss_ultimate_meter = 0
	is_ultimate_queued = false
	is_ultimate_charge_active = false
	is_ultimate_challenge_active = false
	ultimate_timer = 8.0
	is_tactical_pick_mode = false
	if ultimate_telegraph_panel != null:
		ultimate_telegraph_panel.visible = false
	if ultimate_dim_overlay != null:
		ultimate_dim_overlay.visible = false
	if hand_cursor_node != null:
		hand_cursor_node.visible = false
	if card_row_container != null:
		card_row_container.visible = true
		card_row_container.modulate.a = 1.0
	tactical_hand.clear()
	question_timer_seconds = 45.0
	current_question_idx = 0
	selected_card_idx = 0
	hovered_card_idx = 0
	selected_answer_idx = -1
	has_selected_answer = false
	hint_shown = false

	if is_draw_open:
		close_probability_draw()
	if replace_modal != null:
		replace_modal.visible = false

	for btn in answer_buttons:
		btn.disabled = false

	_update_probability_card_ui()
	_update_tactical_hand_ui()
	_update_strike_card_stat()
	_update_shield_hud()
	_update_boss_hud()
	_update_persistent_shield_visual()
	_update_card_selection()
	_update_hover_detail(selected_card_idx)
	_update_question_view()
	trigger_idle_state()
	trigger_boss_idle()
	restore_question_after_combat()

func set_shield(new_val: int) -> void:
	var old_val: int = current_shield
	var clamped_val: int = clamp(new_val, 0, 24)

	if old_val > 0 and clamped_val <= 0:
		break_shield()
	else:
		current_shield = clamped_val
		_update_shield_hud()
		_update_persistent_shield_visual()

func break_shield() -> void:
	if current_shield <= 0 and (karl_persistent_barrier == null or not karl_persistent_barrier.visible):
		return
	current_shield = 0
	_update_shield_hud()
	_trigger_shield_break_vfx()

func clear_shield() -> void:
	if current_shield > 0:
		set_shield(0)

func get_current_shield() -> int:
	return current_shield

func is_persistent_barrier_visible() -> bool:
	if karl_persistent_barrier == null:
		return false
	return karl_persistent_barrier.visible

func toggle_debug_overlay() -> void:
	debug_mode = not debug_mode
	if debug_overlay != null:
		debug_overlay.visible = debug_mode

func set_karl_state(state: KarlState) -> void:
	current_karl_state = state
	if karl_sprite_rect == null:
		return
	if state == KarlState.DODGE:
		if has_karl_dodge_asset():
			karl_sprite_rect.texture = load(ASSET_KARL_DODGE_SEQUENCE)
		elif karl_textures.has(KarlState.IDLE):
			karl_sprite_rect.texture = karl_textures[KarlState.IDLE]
	elif state == KarlState.SKILL_CAST:
		if has_karl_skill_cast_asset():
			karl_sprite_rect.texture = load(ASSET_KARL_SKILL_CAST_SEQUENCE)
		elif karl_textures.has(KarlState.CAST):
			karl_sprite_rect.texture = karl_textures[KarlState.CAST]
		elif karl_textures.has(KarlState.IDLE):
			karl_sprite_rect.texture = karl_textures[KarlState.IDLE]
	elif karl_textures.has(state):
		karl_sprite_rect.texture = karl_textures[state]
	var y_offset: float = KARL_BASELINE_OFFSETS.get(state, 0.0)
	karl_sprite_rect.position = Vector2(0.0, y_offset)
	karl_sprite_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)

func play_karl_dodge() -> void:
	set_karl_state(KarlState.DODGE)
	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()

	var base_entity_pos: Vector2 = Vector2(KARL_ENTITY_LEFT, 720.0 - KARL_ENTITY_HEIGHT - KARL_ENTITY_BOTTOM)
	if floating_status_container != null and karl_sprite_rect != null and karl_sprite_rect.texture != null:
		var ghost: TextureRect = TextureRect.new()
		ghost.texture = karl_sprite_rect.texture
		ghost.size = karl_sprite_rect.size
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.position = base_entity_pos
		ghost.modulate = Color(0.25, 0.85, 1.0, 0.55)
		floating_status_container.add_child(ghost)
		var g_tw: Tween = create_tween()
		g_tw.tween_property(ghost, "modulate:a", 0.0, 0.45)
		g_tw.tween_callback(ghost.queue_free)

	karl_state_tween = create_tween()
	karl_state_tween.tween_property(karl_battlefield_entity, "position:x", base_entity_pos.x - 50.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	karl_state_tween.parallel().tween_property(karl_battlefield_entity, "scale", Vector2(0.85, 1.15), 0.18)
	karl_state_tween.tween_interval(0.22)
	karl_state_tween.tween_property(karl_battlefield_entity, "position:x", base_entity_pos.x, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	karl_state_tween.parallel().tween_property(karl_battlefield_entity, "scale", Vector2.ONE, 0.25)
	karl_state_tween.tween_callback(func():
		set_karl_state(KarlState.IDLE)
		if karl_battlefield_entity != null:
			karl_battlefield_entity.position = base_entity_pos
			karl_battlefield_entity.scale = Vector2.ONE
	)

func play_karl_skill_cast(is_utility: bool = false) -> void:
	set_karl_state(KarlState.SKILL_CAST)
	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()

	_spawn_cast_hand_spark()

	var duration: float = 0.30 if is_utility else 0.50
	karl_state_tween = create_tween()
	karl_state_tween.set_parallel(true)
	karl_state_tween.tween_property(karl_battlefield_entity, "scale", Vector2(1.05, 1.05), duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	karl_state_tween.tween_property(karl_battlefield_entity, "modulate", Color(1.2, 1.3, 1.5, 1.0), duration * 0.5)
	karl_state_tween.chain().tween_property(karl_battlefield_entity, "scale", Vector2.ONE, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	karl_state_tween.parallel().tween_property(karl_battlefield_entity, "modulate", Color.WHITE, duration * 0.5)
	karl_state_tween.chain().tween_callback(func():
		set_karl_state(KarlState.IDLE)
		if karl_battlefield_entity != null:
			karl_battlefield_entity.scale = Vector2.ONE
			karl_battlefield_entity.modulate = Color.WHITE
	)

func trigger_probability_draw_sequence() -> void:
	play_karl_skill_cast(false)
	fade_question_for_combat()
	var tw: Tween = create_tween()
	tw.tween_interval(0.50)
	tw.tween_callback(open_probability_draw)

func trigger_idle_state() -> void:
	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()
	set_karl_state(KarlState.IDLE)

# Karl Cast & Projectile (WAD2 karl_arcane_projectile.png)
func trigger_cast_effect() -> void:
	if combat_resolving:
		return
	combat_resolving = true
	fade_question_for_combat()

	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()
	set_karl_state(KarlState.CAST)

	_spawn_cast_hand_spark()
	_fire_karl_arcane_projectile()

func _fire_karl_arcane_projectile() -> void:
	var proj: TextureRect = TextureRect.new()
	proj.name = "KarlArcaneProjectile"
	if ResourceLoader.exists(ASSET_VFX_KARL_PROJECTILE):
		proj.texture = load(ASSET_VFX_KARL_PROJECTILE)
	proj.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	proj.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	proj.size = Vector2(120, 46)
	proj.position = Vector2(KARL_ENTITY_LEFT + 218.0, 350.0 + 105.0 - 23.0) # (268, 432)
	floating_status_container.add_child(proj)

	var target_pos: Vector2 = Vector2(BOSS_BASE_POS.x + 150.0, BOSS_BASE_POS.y + 220.0) # (950, 350)
	var travel_tw: Tween = create_tween()
	travel_tw.tween_property(proj, "position", target_pos, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	travel_tw.tween_callback(func():
		proj.queue_free()
		_spawn_impact_particles(target_pos + Vector2(20, 20))
		var strike_damage: int = 15 if is_critical_armed else 10
		if is_critical_armed:
			is_critical_armed = false
			_update_strike_card_stat()
			emit_signal("critical_triggered", 15)
		trigger_boss_hit(strike_damage)
	)

	# Recovery timer after impact
	karl_state_tween = create_tween()
	karl_state_tween.tween_interval(0.45 + 0.45) # 0.45s travel + 0.45s hit recovery
	karl_state_tween.tween_callback(func():
		set_karl_state(KarlState.IDLE)
		combat_resolving = false
		restore_question_after_combat()
	)

func trigger_shield_effect() -> void:
	if combat_resolving:
		return
	combat_resolving = true
	fade_question_for_combat()

	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()
	set_karl_state(KarlState.SHIELD)

	# Persistent combat state: Shield +8
	current_shield += 8
	_update_shield_hud()
	_update_persistent_shield_visual()

	_spawn_floating_feedback(Vector2(200, 330), "+8 GIÁP", COLOR_ACCENT_CYAN)
	_spawn_barrier_pulse()

	karl_state_tween = create_tween()
	karl_state_tween.tween_interval(1.1)
	karl_state_tween.tween_callback(func():
		set_karl_state(KarlState.IDLE)
		combat_resolving = false
		restore_question_after_combat()
	)

func trigger_heal_effect() -> void:
	if combat_resolving:
		return
	combat_resolving = true
	fade_question_for_combat()

	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()
	set_karl_state(KarlState.HEAL)

	current_karl_hp = min(max_karl_hp, current_karl_hp + 15)
	_update_shield_hud()

	_spawn_floating_feedback(Vector2(200, 330), "+15 HP", COLOR_ACCENT_GREEN)
	_spawn_emerald_pulse()

	karl_state_tween = create_tween()
	karl_state_tween.tween_interval(1.2)
	karl_state_tween.tween_callback(func():
		set_karl_state(KarlState.IDLE)
		combat_resolving = false
		restore_question_after_combat()
	)

func apply_damage_to_karl(amount: int) -> void:
	var incoming: int = max(0, amount)
	var absorbed: int = 0

	if current_shield > 0:
		absorbed = min(current_shield, incoming)
		var new_shield: int = current_shield - absorbed
		incoming -= absorbed
		_spawn_floating_feedback(Vector2(200, 300), "-%d GIÁP" % absorbed, COLOR_ACCENT_CYAN)
		set_shield(new_shield)

	if incoming > 0:
		current_karl_hp = max(0, current_karl_hp - incoming)
		_update_shield_hud()
		_spawn_floating_feedback(Vector2(200, 360 if absorbed > 0 else 330), "-%d HP" % incoming, COLOR_ACCENT_RED)
		_play_karl_hit_animation()
	else:
		_spawn_barrier_pulse()

func _play_karl_hit_animation() -> void:
	if karl_state_tween != null and karl_state_tween.is_valid():
		karl_state_tween.kill()
	set_karl_state(KarlState.HIT)
	_spawn_hit_pulse()
	karl_state_tween = create_tween()
	karl_state_tween.tween_interval(0.7)
	karl_state_tween.tween_callback(func(): set_karl_state(KarlState.IDLE))

func trigger_hit_effect() -> void:
	apply_damage_to_karl(10)

func _spawn_cast_hand_spark() -> void:
	if karl_vfx_container == null:
		return
	var spark: Panel = Panel.new()
	spark.position = Vector2(218, 105)
	spark.size = Vector2(28, 28)
	spark.pivot_offset = Vector2(14, 14)
	var s_box: StyleBoxFlat = StyleBoxFlat.new()
	s_box.bg_color = Color(0.40, 0.90, 1.0, 0.85)
	s_box.border_width_left = 2
	s_box.border_width_top = 2
	s_box.border_width_right = 2
	s_box.border_width_bottom = 2
	s_box.border_color = Color(1.0, 1.0, 1.0, 0.95)
	s_box.corner_radius_top_left = 14
	s_box.corner_radius_top_right = 14
	s_box.corner_radius_bottom_right = 14
	s_box.corner_radius_bottom_left = 14
	s_box.shadow_color = Color(0.2, 0.85, 1.0, 0.7)
	s_box.shadow_size = 14
	spark.add_theme_stylebox_override("panel", s_box)
	karl_vfx_container.add_child(spark)

	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(spark, "scale", Vector2(1.8, 1.8), 0.5)
	tw.tween_property(spark, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(spark.queue_free)

func _spawn_impact_particles(pos: Vector2) -> void:
	if floating_status_container == null:
		return
	var spark: Panel = Panel.new()
	spark.position = pos - Vector2(16, 16)
	spark.size = Vector2(32, 32)
	spark.pivot_offset = Vector2(16, 16)
	var sbox: StyleBoxFlat = StyleBoxFlat.new()
	sbox.bg_color = Color(0.9, 0.95, 1.0, 0.9)
	sbox.border_width_left = 2
	sbox.border_width_top = 2
	sbox.border_width_right = 2
	sbox.border_width_bottom = 2
	sbox.border_color = Color(0.4, 0.8, 1.0, 1.0)
	sbox.corner_radius_top_left = 16
	sbox.corner_radius_top_right = 16
	sbox.corner_radius_bottom_right = 16
	sbox.corner_radius_bottom_left = 16
	sbox.shadow_color = Color(0.2, 0.7, 1.0, 0.8)
	sbox.shadow_size = 14
	spark.add_theme_stylebox_override("panel", sbox)
	floating_status_container.add_child(spark)

	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(spark, "scale", Vector2(2.0, 2.0), 0.35)
	tw.tween_property(spark, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(spark.queue_free)

func _spawn_barrier_pulse() -> void:
	if karl_vfx_container == null:
		return
	var barrier: Panel = Panel.new()
	barrier.position = Vector2(15, 15)
	barrier.size = Vector2(270, 270)
	barrier.pivot_offset = Vector2(135, 135)
	var b_box: StyleBoxFlat = StyleBoxFlat.new()
	b_box.bg_color = Color(0.12, 0.45, 0.75, 0.20)
	b_box.border_width_left = 3
	b_box.border_width_top = 3
	b_box.border_width_right = 3
	b_box.border_width_bottom = 3
	b_box.border_color = Color(0.30, 0.85, 1.0, 0.85)
	b_box.corner_radius_top_left = 135
	b_box.corner_radius_top_right = 135
	b_box.corner_radius_bottom_right = 135
	b_box.corner_radius_bottom_left = 135
	b_box.shadow_color = Color(0.20, 0.80, 1.0, 0.55)
	b_box.shadow_size = 16
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
	aura.position = Vector2(20, 15)
	aura.size = Vector2(260, 270)
	aura.pivot_offset = Vector2(130, 135)
	var a_box: StyleBoxFlat = StyleBoxFlat.new()
	a_box.bg_color = Color(0.15, 0.65, 0.35, 0.22)
	a_box.border_width_left = 3
	a_box.border_width_top = 3
	a_box.border_width_right = 3
	a_box.border_width_bottom = 3
	a_box.border_color = Color(0.35, 0.95, 0.55, 0.85)
	a_box.corner_radius_top_left = 130
	a_box.corner_radius_top_right = 130
	a_box.corner_radius_bottom_right = 130
	a_box.corner_radius_bottom_left = 130
	a_box.shadow_color = Color(0.25, 0.90, 0.50, 0.55)
	a_box.shadow_size = 16
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
	var tw: Tween = create_tween()
	tw.tween_property(karl_sprite_rect, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.08)
	tw.tween_property(karl_sprite_rect, "modulate", Color.WHITE, 0.15)

func _build_persistent_barrier() -> void:
	karl_persistent_barrier = Panel.new()
	karl_persistent_barrier.name = "KarlPersistentBarrier"
	karl_persistent_barrier.position = Vector2(8, 8)
	karl_persistent_barrier.size = Vector2(284, 284)
	karl_persistent_barrier.pivot_offset = Vector2(142, 142)
	karl_persistent_barrier.visible = false

	var b_box: StyleBoxFlat = StyleBoxFlat.new()
	b_box.bg_color = Color(0.10, 0.40, 0.70, 0.18)
	b_box.border_width_left = 3
	b_box.border_width_top = 3
	b_box.border_width_right = 3
	b_box.border_width_bottom = 3
	b_box.border_color = Color(0.35, 0.90, 1.0, 0.90)
	b_box.corner_radius_top_left = 142
	b_box.corner_radius_top_right = 142
	b_box.corner_radius_bottom_right = 142
	b_box.corner_radius_bottom_left = 142
	b_box.shadow_color = Color(0.20, 0.85, 1.0, 0.60)
	b_box.shadow_size = 18
	karl_persistent_barrier.add_theme_stylebox_override("panel", b_box)
	karl_vfx_container.add_child(karl_persistent_barrier)

func _update_shield_hud() -> void:
	if karl_hp_sub_label != null:
		karl_hp_sub_label.text = "HP: %d / %d   •   GIÁP: %d" % [current_karl_hp, max_karl_hp, current_shield]

func fade_question_for_combat() -> void:
	if question_panel == null:
		return
	_set_question_input_enabled(false)
	if question_fade_tween != null and question_fade_tween.is_valid():
		question_fade_tween.kill()
	question_fade_tween = create_tween()
	question_fade_tween.tween_property(question_panel, "modulate:a", QUESTION_COMBAT_ALPHA, QUESTION_FADE_OUT_DURATION)

func restore_question_after_combat() -> void:
	if is_ultimate_queued:
		is_ultimate_queued = false
		trigger_boss_ultimate_charge()
		return
	if question_panel == null:
		return
	if question_fade_tween != null and question_fade_tween.is_valid():
		question_fade_tween.kill()
	question_fade_tween = create_tween()
	question_fade_tween.tween_property(question_panel, "modulate:a", 1.0, QUESTION_FADE_IN_DURATION)
	question_fade_tween.tween_callback(func():
		_set_question_input_enabled(true)
	)

func _set_question_input_enabled(enabled: bool) -> void:
	for btn in answer_buttons:
		if btn != null:
			btn.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if hint_button != null:
		hint_button.disabled = not enabled
	if cta_button != null:
		cta_button.disabled = not enabled

func _update_persistent_shield_visual() -> void:
	if karl_persistent_barrier == null:
		return
	if current_shield > 0:
		karl_persistent_barrier.visible = true
		if karl_persistent_barrier_tween == null or not karl_persistent_barrier_tween.is_valid():
			karl_persistent_barrier_tween = create_tween().set_loops()
			karl_persistent_barrier_tween.tween_property(karl_persistent_barrier, "scale", Vector2(1.03, 1.03), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			karl_persistent_barrier_tween.parallel().tween_property(karl_persistent_barrier, "modulate:a", 0.95, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			karl_persistent_barrier_tween.tween_property(karl_persistent_barrier, "scale", Vector2(0.98, 0.98), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			karl_persistent_barrier_tween.parallel().tween_property(karl_persistent_barrier, "modulate:a", 0.70, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		if karl_persistent_barrier_tween != null and karl_persistent_barrier_tween.is_valid():
			karl_persistent_barrier_tween.kill()
			karl_persistent_barrier_tween = null
		karl_persistent_barrier.visible = false

func _trigger_shield_break_vfx() -> void:
	if karl_persistent_barrier != null and karl_persistent_barrier.visible:
		if karl_persistent_barrier_tween != null and karl_persistent_barrier_tween.is_valid():
			karl_persistent_barrier_tween.kill()
			karl_persistent_barrier_tween = null

		var flash_tw: Tween = create_tween()
		flash_tw.tween_property(karl_persistent_barrier, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flash_tw.parallel().tween_property(karl_persistent_barrier, "modulate", Color(2.5, 2.5, 3.0, 1.0), 0.12)
		flash_tw.tween_property(karl_persistent_barrier, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flash_tw.tween_callback(func():
			karl_persistent_barrier.visible = false
			karl_persistent_barrier.scale = Vector2.ONE
			karl_persistent_barrier.modulate = Color.WHITE
		)

	_spawn_shield_break_shards()
	_spawn_shockwave_ring()
	_spawn_floating_feedback(Vector2(200, 270), "VỠ GIÁP!", COLOR_ACCENT_RED)

func _spawn_shield_break_shards() -> void:
	if karl_vfx_container == null:
		return
	var center: Vector2 = Vector2(150, 150)
	var shard_count: int = 12

	for i in range(shard_count):
		var shard: Panel = Panel.new()
		var angle: float = (float(i) / float(shard_count)) * TAU + randf_range(-0.15, 0.15)
		var shard_w: float = randf_range(14.0, 24.0)
		var shard_h: float = randf_range(8.0, 14.0)
		shard.size = Vector2(shard_w, shard_h)
		shard.position = center - (shard.size * 0.5)
		shard.pivot_offset = shard.size * 0.5
		shard.rotation = angle

		var s_box: StyleBoxFlat = StyleBoxFlat.new()
		s_box.bg_color = Color(0.40, 0.85, 1.0, 0.90)
		s_box.border_width_left = 1
		s_box.border_width_top = 1
		s_box.border_width_right = 1
		s_box.border_width_bottom = 1
		s_box.border_color = Color(1.0, 1.0, 1.0, 1.0)
		s_box.corner_radius_top_left = 3
		s_box.corner_radius_bottom_right = 3
		s_box.shadow_color = Color(0.30, 0.90, 1.0, 0.80)
		s_box.shadow_size = 8
		shard.add_theme_stylebox_override("panel", s_box)
		karl_vfx_container.add_child(shard)

		var distance: float = randf_range(120.0, 180.0)
		var target_pos: Vector2 = shard.position + Vector2(cos(angle), sin(angle)) * distance
		var target_rot: float = shard.rotation + randf_range(-3.0, 3.0)

		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "position", target_pos, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(shard, "rotation", target_rot, 0.55)
		tw.tween_property(shard, "scale", Vector2(0.3, 0.3), 0.55).set_ease(Tween.EASE_IN)
		tw.tween_property(shard, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(shard.queue_free)

func _spawn_shockwave_ring() -> void:
	if karl_vfx_container == null:
		return
	var ring: Panel = Panel.new()
	ring.position = Vector2(30, 30)
	ring.size = Vector2(240, 240)
	ring.pivot_offset = Vector2(120, 120)
	var r_box: StyleBoxFlat = StyleBoxFlat.new()
	r_box.bg_color = Color(0.30, 0.80, 1.0, 0.0)
	r_box.border_width_left = 4
	r_box.border_width_top = 4
	r_box.border_width_right = 4
	r_box.border_width_bottom = 4
	r_box.border_color = Color(0.70, 0.95, 1.0, 0.95)
	r_box.corner_radius_top_left = 120
	r_box.corner_radius_top_right = 120
	r_box.corner_radius_bottom_right = 120
	r_box.corner_radius_bottom_left = 120
	r_box.shadow_color = Color(0.40, 0.90, 1.0, 0.85)
	r_box.shadow_size = 20
	ring.add_theme_stylebox_override("panel", r_box)
	karl_vfx_container.add_child(ring)

	ring.scale = Vector2(0.9, 0.9)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(1.35, 1.35), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(ring.queue_free)

func _start_boss_idle_loop() -> void:
	if boss_idle_tween != null and boss_idle_tween.is_valid():
		boss_idle_tween.kill()

	if boss_rect == null:
		return

	boss_rect.position = BOSS_BASE_POS
	boss_rect.scale = Vector2.ONE
	boss_rect.rotation = 0.0

	current_boss_state = BossState.ENRAGED if is_boss_enraged else BossState.IDLE

	var duration: float = BOSS_ENRAGED_CYCLE_DURATION if is_boss_enraged else BOSS_IDLE_CYCLE_DURATION
	var half_dur: float = duration * 0.5
	var float_y: float = BOSS_IDLE_FLOAT_OFFSET if not is_boss_enraged else (BOSS_IDLE_FLOAT_OFFSET * 1.25)
	var breath_scale: Vector2 = BOSS_IDLE_BREATHING_SCALE if not is_boss_enraged else Vector2(1.012, 0.992)

	boss_idle_tween = create_tween().set_loops()
	boss_idle_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y - float_y, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	boss_idle_tween.parallel().tween_property(boss_rect, "scale", breath_scale, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if boss_aura_rect != null:
		var aura_alpha: float = 0.85 if not is_boss_enraged else 1.0
		boss_idle_tween.parallel().tween_property(boss_aura_rect, "modulate:a", aura_alpha, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	boss_idle_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	boss_idle_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if boss_aura_rect != null:
		var aura_alpha_min: float = 0.40 if not is_boss_enraged else 0.60
		boss_idle_tween.parallel().tween_property(boss_aura_rect, "modulate:a", aura_alpha_min, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _pause_boss_idle() -> void:
	if boss_idle_tween != null and boss_idle_tween.is_valid():
		boss_idle_tween.kill()
		boss_idle_tween = null

func trigger_boss_idle() -> void:
	if boss_action_tween != null and boss_action_tween.is_valid():
		boss_action_tween.kill()
		boss_action_tween = null
	if boss_stun_overlay != null:
		boss_stun_overlay.visible = false
	if boss_rect != null:
		boss_rect.position = BOSS_BASE_POS
		boss_rect.scale = Vector2.ONE
		boss_rect.rotation = 0.0
		boss_rect.modulate = Color.WHITE
	_start_boss_idle_loop()

func set_boss_state(new_state: BossState) -> void:
	current_boss_state = new_state

func select_boss_spell_weighted() -> BossSpellType:
	var roll: int = boss_spell_rng.randi_range(0, 99)
	if is_boss_enraged:
		if roll < 15:
			return BossSpellType.ARCANE_BOLT
		elif roll < 40:
			return BossSpellType.PROBABILITY_ORB
		elif roll < 70:
			return BossSpellType.VOID_RIFT
		else:
			return BossSpellType.ARCANE_SWEEP
	else:
		if roll < 40:
			return BossSpellType.ARCANE_BOLT
		elif roll < 70:
			return BossSpellType.PROBABILITY_ORB
		elif roll < 90:
			return BossSpellType.VOID_RIFT
		else:
			return BossSpellType.ARCANE_SWEEP

# 4 Boss Spells Implementation (WAD2 Multi-Spells)
func cast_boss_spell(spell: BossSpellType) -> void:
	if current_boss_state == BossState.STUN:
		return
	if combat_resolving:
		return
	combat_resolving = true
	fade_question_for_combat()

	_pause_boss_idle()
	_spawn_boss_cast_spark()

	if boss_action_tween != null and boss_action_tween.is_valid():
		boss_action_tween.kill()
	boss_action_tween = create_tween()

	match spell:
		BossSpellType.ARCANE_BOLT:
			set_boss_state(BossState.CAST_BOLT)
			boss_action_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(8.0, -2.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			boss_action_tween.parallel().tween_property(boss_rect, "scale", Vector2(1.02, 0.98), 0.15)
			boss_action_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(-20.0, 2.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			boss_action_tween.parallel().tween_property(boss_rect, "rotation_degrees", -2.0, 0.18)
			boss_action_tween.parallel().tween_property(boss_rect, "modulate", Color(1.3, 1.8, 2.0, 1.0), 0.18)
			boss_action_tween.tween_property(boss_rect, "modulate", Color.WHITE, 0.15)
			boss_action_tween.tween_callback(_cast_stochas_arcane_bolt)

		BossSpellType.PROBABILITY_ORB:
			set_boss_state(BossState.CAST_ORB)
			boss_action_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(12.0, -12.0), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			boss_action_tween.parallel().tween_property(boss_rect, "rotation_degrees", 2.5, 0.35)
			boss_action_tween.parallel().tween_property(boss_rect, "scale", Vector2(0.98, 1.05), 0.35)
			boss_action_tween.parallel().tween_property(boss_rect, "modulate", Color(1.5, 1.4, 0.8, 1.0), 0.35)
			boss_action_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(-10.0, 0.0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			boss_action_tween.parallel().tween_property(boss_rect, "scale", Vector2(1.04, 0.98), 0.25)
			boss_action_tween.tween_callback(_cast_stochas_probability_orb)

		BossSpellType.VOID_RIFT:
			set_boss_state(BossState.CAST_RIFT)
			boss_action_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(5.0, -10.0), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			boss_action_tween.parallel().tween_property(boss_rect, "rotation_degrees", -3.5, 0.30)
			boss_action_tween.parallel().tween_property(boss_rect, "modulate", Color(0.9, 0.7, 1.3, 1.0), 0.30)
			boss_action_tween.tween_callback(_cast_stochas_void_rift)

		BossSpellType.ARCANE_SWEEP:
			set_boss_state(BossState.CAST_SWEEP)
			boss_action_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(20.0, -5.0), 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			boss_action_tween.parallel().tween_property(boss_rect, "rotation_degrees", 5.0, 0.30)
			boss_action_tween.parallel().tween_property(boss_rect, "scale", Vector2(1.08, 0.95), 0.30)
			boss_action_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(-25.0, 5.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			boss_action_tween.parallel().tween_property(boss_rect, "rotation_degrees", -4.5, 0.35)
			boss_action_tween.parallel().tween_property(boss_rect, "scale", Vector2(0.96, 1.04), 0.35)
			boss_action_tween.tween_callback(_cast_stochas_arcane_sweep)

func trigger_boss_cast() -> void:
	cast_boss_spell(BossSpellType.ARCANE_BOLT)

func trigger_boss_spell_arcane_bolt() -> void:
	cast_boss_spell(BossSpellType.ARCANE_BOLT)

func trigger_boss_spell_probability_orb() -> void:
	cast_boss_spell(BossSpellType.PROBABILITY_ORB)

func trigger_boss_spell_void_rift() -> void:
	cast_boss_spell(BossSpellType.VOID_RIFT)

func trigger_boss_spell_arcane_sweep() -> void:
	cast_boss_spell(BossSpellType.ARCANE_SWEEP)

func _cast_stochas_arcane_bolt() -> void:
	var bolt: TextureRect = TextureRect.new()
	bolt.name = "StochasArcaneBolt"
	if ResourceLoader.exists(ASSET_VFX_STOCHAS_BOLT):
		bolt.texture = load(ASSET_VFX_STOCHAS_BOLT)
	bolt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bolt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bolt.size = Vector2(136, 60)
	bolt.position = BOSS_BASE_POS + Vector2(60, 160)
	floating_status_container.add_child(bolt)

	var target_pos: Vector2 = Vector2(KARL_ENTITY_LEFT + 150, 450)
	var tw: Tween = create_tween()
	tw.tween_property(bolt, "position", target_pos, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		bolt.queue_free()
		apply_damage_to_karl(8)
	)

	var recovery_tw: Tween = create_tween()
	recovery_tw.tween_interval(0.50 + 0.35)
	recovery_tw.tween_callback(func():
		if boss_rect != null:
			boss_rect.position = BOSS_BASE_POS
			boss_rect.rotation_degrees = 0.0
			boss_rect.scale = Vector2.ONE
			boss_rect.modulate = Color.WHITE
		set_boss_state(BossState.ENRAGED if is_boss_enraged else BossState.IDLE)
		_start_boss_idle_loop()
		combat_resolving = false
		restore_question_after_combat()
	)

func _cast_stochas_probability_orb() -> void:
	var orb: TextureRect = TextureRect.new()
	orb.name = "StochasProbabilityOrb"
	if ResourceLoader.exists(ASSET_VFX_STOCHAS_ORB):
		orb.texture = load(ASSET_VFX_STOCHAS_ORB)
	orb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	orb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	orb.size = Vector2(80, 75)
	orb.position = BOSS_BASE_POS + Vector2(50, 150)
	orb.scale = Vector2(0.8, 0.8)
	floating_status_container.add_child(orb)

	var target_pos: Vector2 = Vector2(KARL_ENTITY_LEFT + 150, 450)
	var tw: Tween = create_tween()
	tw.tween_property(orb, "scale", Vector2(1.2, 1.2), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(orb, "position", target_pos, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(orb, "scale", Vector2(1.0, 1.0), 0.55)
	tw.tween_callback(func():
		orb.queue_free()
		apply_damage_to_karl(10)
	)

	var recovery_tw: Tween = create_tween()
	recovery_tw.tween_interval(0.35 + 0.55 + 0.30)
	recovery_tw.tween_callback(func():
		if boss_rect != null:
			boss_rect.position = BOSS_BASE_POS
			boss_rect.rotation_degrees = 0.0
			boss_rect.scale = Vector2.ONE
			boss_rect.modulate = Color.WHITE
		set_boss_state(BossState.ENRAGED if is_boss_enraged else BossState.IDLE)
		_start_boss_idle_loop()
		combat_resolving = false
		restore_question_after_combat()
	)

func _cast_stochas_void_rift() -> void:
	var rift: TextureRect = TextureRect.new()
	rift.name = "StochasVoidRift"
	if ResourceLoader.exists(ASSET_VFX_STOCHAS_RIFT):
		rift.texture = load(ASSET_VFX_STOCHAS_RIFT)
	rift.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rift.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rift.size = Vector2(95, 110)
	var rift_pos: Vector2 = Vector2(KARL_ENTITY_LEFT + 180, 450)
	rift.position = rift_pos
	rift.pivot_offset = Vector2(47.5, 55)
	rift.scale = Vector2(0.2, 0.2)
	rift.modulate.a = 0.0
	floating_status_container.add_child(rift)

	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(rift, "scale", Vector2(1.2, 1.2), 0.60).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(rift, "modulate:a", 1.0, 0.60)
	tw.chain().tween_callback(func():
		apply_damage_to_karl(12)
	)
	tw.tween_property(rift, "scale", Vector2(0.1, 0.1), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(rift, "modulate:a", 0.0, 0.30)
	tw.tween_callback(rift.queue_free)

	var recovery_tw: Tween = create_tween()
	recovery_tw.tween_interval(0.60 + 0.30 + 0.30)
	recovery_tw.tween_callback(func():
		if boss_rect != null:
			boss_rect.position = BOSS_BASE_POS
			boss_rect.rotation_degrees = 0.0
			boss_rect.scale = Vector2.ONE
			boss_rect.modulate = Color.WHITE
		set_boss_state(BossState.ENRAGED if is_boss_enraged else BossState.IDLE)
		_start_boss_idle_loop()
		combat_resolving = false
		restore_question_after_combat()
	)

func _cast_stochas_arcane_sweep() -> void:
	var sweep: TextureRect = TextureRect.new()
	sweep.name = "StochasArcaneSweep"
	if ResourceLoader.exists(ASSET_VFX_STOCHAS_SWEEP):
		sweep.texture = load(ASSET_VFX_STOCHAS_SWEEP)
	sweep.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sweep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sweep.size = Vector2(160, 118)
	sweep.position = Vector2(820, 380)
	floating_status_container.add_child(sweep)

	var target_pos: Vector2 = Vector2(KARL_ENTITY_LEFT + 40, 380)
	var tw: Tween = create_tween()
	tw.tween_property(sweep, "position", target_pos, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		apply_damage_to_karl(14)
	)
	tw.tween_property(sweep, "modulate:a", 0.0, 0.20)
	tw.tween_callback(sweep.queue_free)

	var recovery_tw: Tween = create_tween()
	recovery_tw.tween_interval(0.65 + 0.20 + 0.25)
	recovery_tw.tween_callback(func():
		if boss_rect != null:
			boss_rect.position = BOSS_BASE_POS
			boss_rect.rotation_degrees = 0.0
			boss_rect.scale = Vector2.ONE
			boss_rect.modulate = Color.WHITE
		_start_boss_idle_loop()
		combat_resolving = false
		restore_question_after_combat()
	)

func trigger_boss_hit(damage: int = 10) -> void:
	if current_boss_state == BossState.STUN:
		_flash_stunned_hit(damage)
		return

	_pause_boss_idle()
	current_boss_state = BossState.HIT

	if boss_action_tween != null and boss_action_tween.is_valid():
		boss_action_tween.kill()

	if boss_rect != null:
		boss_rect.modulate = Color(2.2, 0.6, 0.6, 1.0)

	boss_action_tween = create_tween()

	var feedback_text: String = "-%d HP (CRITICAL)" % damage if damage > 10 else "-%d HP" % damage
	_spawn_floating_feedback(Vector2(1040, 240), feedback_text, COLOR_ACCENT_RED)

	current_boss_hp = max(0, current_boss_hp - damage)
	_update_boss_hud()

	boss_action_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(16.0, -2.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	boss_action_tween.parallel().tween_property(boss_rect, "rotation_degrees", -1.5, 0.08)
	boss_action_tween.parallel().tween_property(boss_rect, "modulate", Color(2.2, 0.6, 0.6, 1.0), 0.08)

	boss_action_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(6.0, 0.0), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	boss_action_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.5, 0.12)
	boss_action_tween.parallel().tween_property(boss_rect, "modulate", Color(1.3, 0.9, 0.9, 1.0), 0.12)

	boss_action_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	boss_action_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, 0.22)
	boss_action_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, 0.22)
	boss_action_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, 0.22)

	boss_action_tween.tween_callback(_start_boss_idle_loop)

func _flash_stunned_hit(damage: int = 10) -> void:
	var feedback_text: String = "-%d HP (CRITICAL)" % damage if damage > 10 else "-%d HP" % damage
	_spawn_floating_feedback(Vector2(1040, 240), feedback_text, COLOR_ACCENT_RED)
	current_boss_hp = max(0, current_boss_hp - damage)
	_update_boss_hud()
	if boss_rect != null:
		var tw: Tween = create_tween()
		tw.tween_property(boss_rect, "modulate", Color(2.0, 0.6, 0.6, 1.0), 0.08)
		tw.tween_property(boss_rect, "modulate", Color.WHITE, 0.15)

func trigger_boss_stun() -> void:
	_pause_boss_idle()
	current_boss_state = BossState.STUN

	if boss_action_tween != null and boss_action_tween.is_valid():
		boss_action_tween.kill()

	if boss_stun_overlay != null:
		boss_stun_overlay.visible = true
		boss_stun_overlay.modulate.a = 1.0

	if boss_rect != null:
		boss_rect.modulate = Color(0.70, 0.75, 1.2, 0.85)

	boss_action_tween = create_tween().set_loops(2)
	boss_action_tween.tween_property(boss_rect, "rotation_degrees", -2.5, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	boss_action_tween.tween_property(boss_rect, "rotation_degrees", 2.5, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var finish_tw: Tween = create_tween()
	finish_tw.tween_interval(1.8)
	finish_tw.tween_callback(func():
		if boss_stun_overlay != null:
			boss_stun_overlay.visible = false
		if boss_rect != null:
			boss_rect.rotation_degrees = 0.0
			boss_rect.modulate = Color.WHITE
		_start_boss_idle_loop()
	)

func toggle_boss_enraged() -> void:
	is_boss_enraged = not is_boss_enraged
	_apply_enraged_visuals()
	if current_boss_state == BossState.IDLE or current_boss_state == BossState.ENRAGED:
		_start_boss_idle_loop()
	_spawn_floating_feedback(Vector2(1040, 240), "CUỒNG NỘ: " + ("BẬT" if is_boss_enraged else "TẮT"), COLOR_ACCENT_RED if is_boss_enraged else COLOR_ACCENT_CYAN)

func _apply_enraged_visuals() -> void:
	if boss_aura_rect != null:
		var abox: StyleBoxFlat = boss_aura_rect.get_theme_stylebox("panel") as StyleBoxFlat
		if abox != null:
			if is_boss_enraged:
				abox.bg_color = Color(0.75, 0.12, 0.25, 0.25)
				abox.shadow_color = Color(0.95, 0.20, 0.35, 0.65)
			else:
				abox.bg_color = Color(0.08, 0.35, 0.65, 0.18)
				abox.shadow_color = Color(0.12, 0.60, 0.95, 0.45)

	if boss_hud != null:
		var hbox: StyleBoxFlat = boss_hud.get_theme_stylebox("panel") as StyleBoxFlat
		if hbox != null:
			if is_boss_enraged:
				hbox.border_color = Color(1.0, 0.20, 0.25, 0.95)
				hbox.shadow_color = Color(0.90, 0.15, 0.25, 0.45)
				hbox.shadow_size = 12
			else:
				hbox.border_color = Color(0.95, 0.30, 0.35, 0.75)
				hbox.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
				hbox.shadow_size = 6

func _spawn_boss_cast_spark() -> void:
	if boss_vfx_container == null:
		return
	var spark: Panel = Panel.new()
	spark.position = Vector2(85, 175)
	spark.size = Vector2(36, 36)
	spark.pivot_offset = Vector2(18, 18)
	var sbox: StyleBoxFlat = StyleBoxFlat.new()
	sbox.bg_color = Color(0.65, 0.25, 0.95, 0.85)
	sbox.border_width_left = 2
	sbox.border_width_top = 2
	sbox.border_width_right = 2
	sbox.border_width_bottom = 2
	sbox.border_color = Color(1.0, 0.85, 1.0, 0.95)
	sbox.corner_radius_top_left = 18
	sbox.corner_radius_top_right = 18
	sbox.corner_radius_bottom_right = 18
	sbox.corner_radius_bottom_left = 18
	sbox.shadow_color = Color(0.70, 0.30, 1.0, 0.75)
	sbox.shadow_size = 18
	spark.add_theme_stylebox_override("panel", sbox)
	boss_vfx_container.add_child(spark)

	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(spark, "scale", Vector2(1.9, 1.9), 0.45)
	tw.tween_property(spark, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(spark.queue_free)

func _build_boss_stun_overlay() -> void:
	boss_stun_overlay = Control.new()
	boss_stun_overlay.name = "BossStunOverlay"
	boss_stun_overlay.position = Vector2(240, 60)
	boss_stun_overlay.visible = false
	boss_vfx_container.add_child(boss_stun_overlay)

	for i in range(3):
		var star: Label = Label.new()
		star.name = "StunStar_%d" % i
		star.text = "✦"
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.custom_minimum_size = Vector2(24, 24)
		star.position = Vector2(-36 + i * 28, -12)
		star.add_theme_font_size_override("font_size", 18)
		star.add_theme_color_override("font_color", COLOR_ACCENT_GOLD)
		boss_stun_overlay.add_child(star)

func _build_scene() -> void:
	_build_background()
	_build_boss_render()
	_build_karl_battlefield_entity()
	_build_top_huds()
	_build_question_module()
	_build_card_hover_detail()
	_build_card_row()
	_build_tactical_hand_tray()
	_build_settings_button()
	_build_floating_status_container()
	_build_debug_overlay()
	_build_probability_draw_modal()
	_build_replace_modal()

func _build_background() -> void:
	bg_rect = TextureRect.new()
	bg_rect.name = "Background"
	bg_rect.position = Vector2.ZERO
	bg_rect.size = Vector2(1280, 720)
	bg_rect.custom_minimum_size = Vector2(1280, 720)
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(ASSET_BG):
		bg_rect.texture = load(ASSET_BG)
	add_child(bg_rect)

func _build_boss_render() -> void:
	boss_rect = TextureRect.new()
	boss_rect.name = "StochasBoss"
	boss_rect.position = BOSS_BASE_POS
	boss_rect.size = BOSS_BASE_SIZE
	boss_rect.custom_minimum_size = BOSS_BASE_SIZE
	boss_rect.pivot_offset = BOSS_BASE_SIZE * 0.5
	boss_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(ASSET_BOSS):
		boss_rect.texture = load(ASSET_BOSS)
	add_child(boss_rect)

	boss_vfx_container = Control.new()
	boss_vfx_container.name = "BossVFXContainer"
	boss_vfx_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_vfx_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_rect.add_child(boss_vfx_container)

	_build_boss_stun_overlay()
	_start_boss_idle_loop()

func _build_karl_battlefield_entity() -> void:
	karl_battlefield_entity = Control.new()
	karl_battlefield_entity.name = "KarlBattlefieldEntity"
	karl_battlefield_entity.position = Vector2(KARL_ENTITY_LEFT, 720.0 - KARL_ENTITY_HEIGHT - KARL_ENTITY_BOTTOM)
	karl_battlefield_entity.size = Vector2(KARL_ENTITY_WIDTH, KARL_ENTITY_HEIGHT)
	karl_battlefield_entity.custom_minimum_size = Vector2(KARL_ENTITY_WIDTH, KARL_ENTITY_HEIGHT)
	karl_battlefield_entity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(karl_battlefield_entity)

	karl_vfx_container = Control.new()
	karl_vfx_container.name = "KarlVFXContainer"
	karl_vfx_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	karl_vfx_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	karl_battlefield_entity.add_child(karl_vfx_container)

	karl_sprite_rect = TextureRect.new()
	karl_sprite_rect.name = "KarlSprite"
	karl_sprite_rect.size = Vector2(KARL_ENTITY_WIDTH, KARL_ENTITY_HEIGHT)
	karl_sprite_rect.custom_minimum_size = Vector2(KARL_ENTITY_WIDTH, KARL_ENTITY_HEIGHT)
	karl_sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	karl_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	karl_sprite_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	karl_battlefield_entity.add_child(karl_sprite_rect)

	_build_persistent_barrier()
	set_karl_state(KarlState.IDLE)

func _build_top_huds() -> void:
	# Karl HUD: Left 24px, Top 20px, 300x68px
	karl_hud = PanelContainer.new()
	karl_hud.name = "KarlHUD"
	karl_hud.position = Vector2(24, 20)
	karl_hud.custom_minimum_size = Vector2(300, 68)
	karl_hud.size = Vector2(300, 68)
	var karl_box: StyleBoxFlat = _create_glass_box(COLOR_PANEL_BG, COLOR_PANEL_BORDER, 8)
	karl_hud.add_theme_stylebox_override("panel", karl_box)
	add_child(karl_hud)

	var karl_hbox: HBoxContainer = HBoxContainer.new()
	karl_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	karl_hbox.add_theme_constant_override("separation", 10)
	karl_hud.add_child(karl_hbox)

	karl_portrait_rect = TextureRect.new()
	karl_portrait_rect.custom_minimum_size = Vector2(48, 48)
	karl_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	karl_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(ASSET_KARL_PORTRAIT):
		karl_portrait_rect.texture = load(ASSET_KARL_PORTRAIT)
	karl_hbox.add_child(karl_portrait_rect)

	var karl_vbox: VBoxContainer = VBoxContainer.new()
	karl_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	karl_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	karl_hbox.add_child(karl_vbox)

	var karl_name: Label = Label.new()
	karl_name.text = "KARL • PHÁP SƯ TẬP SỰ"
	karl_name.add_theme_font_size_override("font_size", 12)
	karl_name.add_theme_color_override("font_color", COLOR_ACCENT_CYAN)
	karl_vbox.add_child(karl_name)

	var karl_hp_bar: ProgressBar = ProgressBar.new()
	karl_hp_bar.custom_minimum_size = Vector2(200, 10)
	karl_hp_bar.max_value = 100.0
	karl_hp_bar.value = 100.0
	karl_hp_bar.show_percentage = false
	var k_bg: StyleBoxFlat = _create_solid_box(Color(0.12, 0.15, 0.22, 0.9), 3)
	var k_fill: StyleBoxFlat = _create_solid_box(Color(0.20, 0.75, 0.90, 1.0), 3)
	karl_hp_bar.add_theme_stylebox_override("background", k_bg)
	karl_hp_bar.add_theme_stylebox_override("fill", k_fill)
	karl_vbox.add_child(karl_hp_bar)

	karl_hp_sub_label = Label.new()
	karl_hp_sub_label.text = "HP: %d / %d   •   GIÁP: %d" % [current_karl_hp, max_karl_hp, current_shield]
	karl_hp_sub_label.add_theme_font_size_override("font_size", 9)
	karl_hp_sub_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	karl_vbox.add_child(karl_hp_sub_label)

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

	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.custom_minimum_size = Vector2(280, 14)
	boss_hp_bar.max_value = 250.0
	boss_hp_bar.value = 250.0
	boss_hp_bar.show_percentage = false
	var b_bg: StyleBoxFlat = _create_solid_box(Color(0.20, 0.10, 0.12, 0.9), 3)
	var b_fill: StyleBoxFlat = _create_solid_box(Color(0.90, 0.22, 0.25, 1.0), 3)
	boss_hp_bar.add_theme_stylebox_override("background", b_bg)
	boss_hp_bar.add_theme_stylebox_override("fill", b_fill)
	boss_vbox.add_child(boss_hp_bar)

	boss_intent_label = Label.new()
	boss_intent_label.text = "HP: 250 / 250   •   Ý ĐỊNH: 10 DMG (ĐÒN ĐÁNH)"
	boss_intent_label.add_theme_font_size_override("font_size", 9)
	boss_intent_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.8, 0.85))
	boss_vbox.add_child(boss_intent_label)

func _update_boss_hud() -> void:
	if boss_hp_bar != null:
		boss_hp_bar.value = float(current_boss_hp)
	if boss_intent_label != null:
		boss_intent_label.text = "HP: %d / %d   •   ĐẠI PHÉP: %d/4   •   Ý ĐỊNH: BIẾN ĐỔI" % [current_boss_hp, max_boss_hp, boss_ultimate_meter]

func _build_question_module() -> void:
	# Center X = 640px, Top = 155px, Width = 610px, Height = 240px
	var start_x: float = QUESTION_CENTER_X - (QUESTION_WIDTH / 2.0)
	question_panel = PanelContainer.new()
	question_panel.name = "QuestionPanel"
	question_panel.position = Vector2(start_x, QUESTION_TOP)
	question_panel.custom_minimum_size = Vector2(QUESTION_WIDTH, QUESTION_HEIGHT)
	question_panel.size = Vector2(QUESTION_WIDTH, QUESTION_HEIGHT)

	var q_box: StyleBoxFlat = _create_glass_box(COLOR_PANEL_BG, COLOR_PANEL_BORDER, 8)
	q_box.content_margin_left = 14
	q_box.content_margin_top = 10
	q_box.content_margin_right = 14
	q_box.content_margin_bottom = 8
	question_panel.add_theme_stylebox_override("panel", q_box)
	add_child(question_panel)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	question_panel.add_child(main_vbox)

	# 1. Header Row (~24 px)
	var header_hbox: HBoxContainer = HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	question_stage_label = Label.new()
	question_stage_label.text = "ARCANE CHALLENGE • CÂU HỎI 1 / 3"
	question_stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_stage_label.add_theme_font_size_override("font_size", 10)
	question_stage_label.add_theme_color_override("font_color", COLOR_ACCENT_CYAN)
	header_hbox.add_child(question_stage_label)

	var round_lbl: Label = Label.new()
	round_lbl.name = "RoundLabel"
	round_lbl.text = "GIAI ĐOẠN 1 • 45s"
	round_lbl.add_theme_font_size_override("font_size", 10)
	round_lbl.add_theme_color_override("font_color", COLOR_ACCENT_GOLD)
	header_hbox.add_child(round_lbl)

	# 2. Question Prompt (~44 px, font 12)
	question_prompt_label = Label.new()
	question_prompt_label.custom_minimum_size = Vector2(580, 44)
	question_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_prompt_label.add_theme_font_size_override("font_size", 12)
	question_prompt_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	main_vbox.add_child(question_prompt_label)

	# 3. Answer Options: ONE HORIZONTAL 4-OPTION ROW (~44 px tall buttons)
	var answer_row: HBoxContainer = HBoxContainer.new()
	answer_row.name = "AnswerRow"
	answer_row.add_theme_constant_override("separation", 6)
	main_vbox.add_child(answer_row)

	answer_buttons.clear()
	for i in range(4):
		var btn: Button = Button.new()
		btn.name = "AnswerBtn_%d" % i
		btn.custom_minimum_size = Vector2(138, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(select_answer.bind(i))
		answer_row.add_child(btn)
		answer_buttons.append(btn)

	# 4. Action Row (Hint + Primary XUẤT CHIÊU CTA, ~42 px)
	var action_hbox: HBoxContainer = HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 8)
	action_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(action_hbox)

	hint_button = Button.new()
	hint_button.name = "HintButton"
	hint_button.text = "💡 GỢI Ý"
	hint_button.custom_minimum_size = Vector2(96, 42)
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

	# 5. Combat rule subtext + Shortcuts guide (~16 px)
	helper_label = Label.new()
	helper_label.text = "Quy tắc: Đúng -> Xuất chiêu. Sai -> STOCHAS phản đòn (Khiên -> HP). | [1-4] Thẻ, [I/C/H/E/S/K] Karl, [B/V/N/M/L] Boss"
	helper_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	helper_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	helper_label.custom_minimum_size = Vector2(580, 16)
	helper_label.add_theme_font_size_override("font_size", 9)
	helper_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	main_vbox.add_child(helper_label)

func _build_card_hover_detail() -> void:
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
	var total_width: float = 4.0 * CARD_WIDTH + 3.0 * CARD_GAP
	var start_x: float = CENTER_INTERACTION_X - (total_width / 2.0)
	var start_y: float = 720.0 - CARD_ROW_BOTTOM - CARD_HEIGHT

	var card_container: HBoxContainer = HBoxContainer.new()
	card_container.name = "CardRowContainer"
	card_container.position = Vector2(start_x, start_y)
	card_container.add_theme_constant_override("separation", int(CARD_GAP))
	add_child(card_container)
	card_row_container = card_container

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

		var hit_btn: Button = Button.new()
		hit_btn.flat = true
		hit_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		hit_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		hit_btn.pressed.connect(select_card.bind(i))
		hit_btn.mouse_entered.connect(_on_card_mouse_entered.bind(i))
		hit_btn.mouse_exited.connect(_on_card_mouse_exited.bind(i))
		card_panel.add_child(hit_btn)

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

func _build_tactical_hand_tray() -> void:
	tactical_hand_tray = PanelContainer.new()
	tactical_hand_tray.name = "TacticalHandTray"
	# Left 24px, Top 96px (directly beneath Karl HUD at 24, 20 with height 68)
	tactical_hand_tray.position = Vector2(24.0, 96.0)
	tactical_hand_tray.custom_minimum_size = Vector2(300, 52)
	tactical_hand_tray.size = Vector2(300, 52)
	var t_box: StyleBoxFlat = _create_glass_box(Color(0.06, 0.09, 0.16, 0.88), Color(0.25, 0.65, 0.85, 0.50), 6)
	t_box.content_margin_left = 6
	t_box.content_margin_top = 4
	t_box.content_margin_right = 6
	t_box.content_margin_bottom = 4
	tactical_hand_tray.add_theme_stylebox_override("panel", t_box)
	add_child(tactical_hand_tray)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.name = "SlotsContainer"
	hbox.add_theme_constant_override("separation", 6)
	tactical_hand_tray.add_child(hbox)

	tactical_slot_buttons.clear()
	for i in range(MAX_TACTICAL_HAND):
		var btn: Button = Button.new()
		btn.name = "TacticalSlot_%d" % i
		btn.text = "[ Trống ]"
		btn.custom_minimum_size = Vector2(92, 42)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 10)
		var s_style: StyleBoxFlat = _create_solid_box(Color(0.10, 0.14, 0.22, 0.80), 4)
		s_style.border_width_left = 1
		s_style.border_width_top = 1
		s_style.border_width_right = 1
		s_style.border_width_bottom = 1
		s_style.border_color = Color(0.25, 0.35, 0.48, 0.40)
		btn.add_theme_stylebox_override("normal", s_style)
		btn.pressed.connect(func(): use_tactical_card(i))
		hbox.add_child(btn)
		tactical_slot_buttons.append(btn)

func _update_tactical_hand_ui() -> void:
	for i in range(MAX_TACTICAL_HAND):
		if i >= tactical_slot_buttons.size():
			continue
		var btn: Button = tactical_slot_buttons[i]
		if i < tactical_hand.size():
			var card: Dictionary = tactical_hand[i]
			var is_rare: bool = (card.get("rarity", "") == "RARE")
			btn.text = card.get("name", "THẺ")
			btn.disabled = false
			var btn_style: StyleBoxFlat = _create_solid_box(
				Color(0.18, 0.14, 0.08, 0.90) if is_rare else Color(0.10, 0.18, 0.28, 0.90),
				4
			)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn_style.border_color = COLOR_ACCENT_GOLD if is_rare else COLOR_ACCENT_CYAN
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_color_override("font_color", COLOR_ACCENT_GOLD if is_rare else COLOR_ACCENT_CYAN)
		else:
			btn.text = "[ Trống ]"
			btn.disabled = true
			var btn_style: StyleBoxFlat = _create_solid_box(Color(0.08, 0.11, 0.16, 0.60), 4)
			btn_style.border_width_left = 1
			btn_style.border_width_top = 1
			btn_style.border_width_right = 1
			btn_style.border_width_bottom = 1
			btn_style.border_color = Color(0.20, 0.26, 0.35, 0.30)
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 0.5))

func _build_probability_draw_modal() -> void:
	probability_draw_modal = Control.new()
	probability_draw_modal.name = "ProbabilityDrawModal"
	probability_draw_modal.position = Vector2.ZERO
	probability_draw_modal.size = Vector2(1280, 720)
	probability_draw_modal.visible = false
	add_child(probability_draw_modal)

	var dimmer: ColorRect = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.size = Vector2(1280, 720)
	dimmer.color = Color(0.02, 0.04, 0.08, 0.65)
	probability_draw_modal.add_child(dimmer)

	var dialog: PanelContainer = PanelContainer.new()
	dialog.name = "DrawDialog"
	dialog.position = Vector2(300, 160)
	dialog.custom_minimum_size = Vector2(680, 380)
	dialog.size = Vector2(680, 380)
	var dbox: StyleBoxFlat = _create_glass_box(Color(0.06, 0.08, 0.14, 0.96), COLOR_ACCENT_CYAN, 12)
	dbox.content_margin_left = 16
	dbox.content_margin_top = 14
	dbox.content_margin_right = 16
	dbox.content_margin_bottom = 14
	dialog.add_theme_stylebox_override("panel", dbox)
	probability_draw_modal.add_child(dialog)

	hand_cursor_node = Panel.new()
	hand_cursor_node.name = "HandCursorNode"
	hand_cursor_node.size = Vector2(24, 24)
	hand_cursor_node.pivot_offset = Vector2(12, 12)
	hand_cursor_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_cursor_node.visible = false
	var c_box: StyleBoxFlat = StyleBoxFlat.new()
	c_box.bg_color = Color(0.25, 0.85, 1.0, 0.75)
	c_box.border_width_left = 2
	c_box.border_width_top = 2
	c_box.border_width_right = 2
	c_box.border_width_bottom = 2
	c_box.border_color = Color(1.0, 1.0, 1.0, 0.95)
	c_box.corner_radius_top_left = 12
	c_box.corner_radius_top_right = 12
	c_box.corner_radius_bottom_right = 12
	c_box.corner_radius_bottom_left = 12
	c_box.shadow_color = Color(0.2, 0.85, 1.0, 0.7)
	c_box.shadow_size = 10
	hand_cursor_node.add_theme_stylebox_override("panel", c_box)
	probability_draw_modal.add_child(hand_cursor_node)

	var dvbox: VBoxContainer = VBoxContainer.new()
	dvbox.add_theme_constant_override("separation", 10)
	dialog.add_child(dvbox)

	var title: Label = Label.new()
	title.text = "RÚT BÀI CHIẾN THUẬT (CHỌN 1 TRONG 3)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COLOR_ACCENT_GOLD)
	dvbox.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "Tỷ lệ: 70% Thường / 30% Hiếm. Đảm bảo ít nhất 1 thẻ Hiếm sau 2 lần rút thường liên tiếp."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	dvbox.add_child(subtitle)

	draw_cards_container = HBoxContainer.new()
	draw_cards_container.name = "CardsRow"
	draw_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	draw_cards_container.add_theme_constant_override("separation", 14)
	draw_cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dvbox.add_child(draw_cards_container)

func _build_replace_modal() -> void:
	replace_modal = Control.new()
	replace_modal.name = "ReplaceModal"
	replace_modal.position = Vector2.ZERO
	replace_modal.size = Vector2(1280, 720)
	replace_modal.visible = false
	add_child(replace_modal)

	var dimmer: ColorRect = ColorRect.new()
	dimmer.size = Vector2(1280, 720)
	dimmer.color = Color(0.02, 0.04, 0.08, 0.75)
	replace_modal.add_child(dimmer)

	var dialog: PanelContainer = PanelContainer.new()
	dialog.name = "ReplaceDialog"
	dialog.position = Vector2(360, 200)
	dialog.custom_minimum_size = Vector2(560, 300)
	dialog.size = Vector2(560, 300)
	var dbox: StyleBoxFlat = _create_glass_box(Color(0.06, 0.08, 0.14, 0.98), COLOR_ACCENT_GOLD, 10)
	dbox.content_margin_left = 16
	dbox.content_margin_top = 16
	dbox.content_margin_right = 16
	dbox.content_margin_bottom = 16
	dialog.add_theme_stylebox_override("panel", dbox)
	replace_modal.add_child(dialog)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "ContentVBox"
	vbox.add_theme_constant_override("separation", 10)
	dialog.add_child(vbox)

	var title: Label = Label.new()
	title.text = "TÚI BÀI ĐÃ ĐẦY (3/3) • CHỌN THAO TÁC"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COLOR_ACCENT_GOLD)
	vbox.add_child(title)

	var desc: Label = Label.new()
	desc.text = "Chọn 1 thẻ đang giữ để thay thế bằng thẻ mới, hoặc hủy bỏ thẻ mới:"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	vbox.add_child(desc)

	var slots_vbox: VBoxContainer = VBoxContainer.new()
	slots_vbox.name = "SlotsVBox"
	slots_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(slots_vbox)

	var discard_btn: Button = Button.new()
	discard_btn.text = "BỎ QUA THẺ MỚI (GIỮ NGUYÊN TÚI BÀI)"
	discard_btn.custom_minimum_size = Vector2(0, 36)
	var ds_style: StyleBoxFlat = _create_solid_box(Color(0.20, 0.24, 0.32, 0.9), 4)
	discard_btn.add_theme_stylebox_override("normal", ds_style)
	discard_btn.add_theme_font_size_override("font_size", 11)
	discard_btn.pressed.connect(_on_replace_discard_new)
	vbox.add_child(discard_btn)

func set_probability_meter(val: int) -> void:
	var old_val: int = probability_meter
	probability_meter = clamp(val, 0, PROBABILITY_METER_MAX)
	_update_probability_card_ui()
	emit_signal("probability_charge_changed", probability_meter, PROBABILITY_METER_MAX)
	if probability_meter == PROBABILITY_METER_MAX and old_val < PROBABILITY_METER_MAX:
		emit_signal("probability_ready")

func add_probability_charge(amount: int = 1) -> void:
	set_probability_meter(probability_meter + amount)

func _update_probability_card_ui() -> void:
	if cards_data.size() > 3:
		if probability_meter >= PROBABILITY_METER_MAX:
			cards_data[3]["stat_badge"] = "SẴN SÀNG"
			cards_data[3]["disabled"] = false
		else:
			cards_data[3]["stat_badge"] = "%d/3" % probability_meter
			cards_data[3]["disabled"] = true
	_update_card_selection()
	if hovered_card_idx == 3:
		_update_hover_detail(3)

func draw_three_tactical_cards() -> Array[Dictionary]:
	var candidate_keys: Array = TACTICAL_CARDS.keys().duplicate()
	var drawn: Array[Dictionary] = []

	var force_rare: bool = (consecutive_no_rare_draws >= 2)
	var rare_keys: Array = []
	for k in candidate_keys:
		if TACTICAL_CARDS[k]["rarity"] == "RARE":
			rare_keys.append(k)

	if force_rare and rare_keys.size() > 0:
		var forced_idx: int = gacha_rng.randi_range(0, rare_keys.size() - 1)
		var forced_key: String = rare_keys[forced_idx]
		drawn.append(TACTICAL_CARDS[forced_key].duplicate())
		candidate_keys.erase(forced_key)

	while drawn.size() < 3 and candidate_keys.size() > 0:
		var total_weight: int = 0
		for k in candidate_keys:
			total_weight += int(TACTICAL_CARDS[k]["weight"])
		var roll: int = gacha_rng.randi_range(0, total_weight - 1)
		var cumulative: int = 0
		var picked_key: String = candidate_keys[0]
		for k in candidate_keys:
			cumulative += int(TACTICAL_CARDS[k]["weight"])
			if roll < cumulative:
				picked_key = k
				break
		drawn.append(TACTICAL_CARDS[picked_key].duplicate())
		candidate_keys.erase(picked_key)

	var has_rare: bool = false
	for c in drawn:
		if c["rarity"] == "RARE":
			has_rare = true
			break
	if has_rare:
		consecutive_no_rare_draws = 0
	else:
		consecutive_no_rare_draws += 1

	return drawn


func set_ultimate_meter(val: int) -> void:
	boss_ultimate_meter = clamp(val, 0, BOSS_ULTIMATE_METER_MAX)
	_update_boss_hud()

func increment_ultimate_meter() -> void:
	if is_ultimate_challenge_active or is_ultimate_charge_active:
		return
	boss_ultimate_meter += 1
	if boss_ultimate_meter >= BOSS_ULTIMATE_METER_MAX:
		boss_ultimate_meter = 0
		is_ultimate_queued = true
	_update_boss_hud()

func trigger_boss_ultimate_charge() -> void:
	if is_ultimate_charge_active or is_ultimate_challenge_active:
		return
	is_ultimate_charge_active = true
	combat_resolving = true
	set_boss_state(BossState.ULTIMATE_CHARGE)
	_pause_boss_idle()

	_set_question_input_enabled(false)
	if question_panel != null:
		question_panel.visible = false
	if card_row_container != null:
		card_row_container.visible = false
	if tactical_hand_tray != null:
		tactical_hand_tray.visible = false

	if ultimate_dim_overlay == null:
		ultimate_dim_overlay = ColorRect.new()
		ultimate_dim_overlay.name = "UltimateDimOverlay"
		ultimate_dim_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		ultimate_dim_overlay.color = Color(0.04, 0.02, 0.08, 0.50)
		ultimate_dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ultimate_dim_overlay)
	ultimate_dim_overlay.visible = true
	ultimate_dim_overlay.modulate.a = 0.0

	if ultimate_telegraph_panel == null:
		ultimate_telegraph_panel = Control.new()
		ultimate_telegraph_panel.name = "UltimateTelegraphPanel"
		ultimate_telegraph_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		ultimate_telegraph_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ultimate_telegraph_panel)

		var banner_vbox: VBoxContainer = VBoxContainer.new()
		banner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		banner_vbox.position = Vector2(400, 220)
		banner_vbox.custom_minimum_size = Vector2(480, 100)
		banner_vbox.add_theme_constant_override("separation", 4)
		ultimate_telegraph_panel.add_child(banner_vbox)

		var t1: Label = Label.new()
		t1.text = "STOCHAS"
		t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t1.add_theme_font_size_override("font_size", 14)
		t1.add_theme_color_override("font_color", COLOR_ACCENT_RED)
		banner_vbox.add_child(t1)

		var t2: Label = Label.new()
		t2.text = "CHAOS VERDICT"
		t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t2.add_theme_font_size_override("font_size", 24)
		t2.add_theme_color_override("font_color", COLOR_ACCENT_PURPLE)
		banner_vbox.add_child(t2)

		var t3: Label = Label.new()
		t3.text = "ĐẠI PHÉP ĐANG ĐƯỢC NIỆM"
		t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t3.add_theme_font_size_override("font_size", 12)
		t3.add_theme_color_override("font_color", COLOR_ACCENT_CYAN)
		banner_vbox.add_child(t3)

	ultimate_telegraph_panel.visible = true
	ultimate_telegraph_panel.modulate.a = 0.0

	if boss_action_tween != null and boss_action_tween.is_valid():
		boss_action_tween.kill()
	boss_action_tween = create_tween()
	boss_action_tween.set_parallel(true)
	boss_action_tween.tween_property(ultimate_dim_overlay, "modulate:a", 1.0, 0.40)
	boss_action_tween.tween_property(ultimate_telegraph_panel, "modulate:a", 1.0, 0.40)
	boss_action_tween.tween_property(boss_rect, "position", Vector2(730.0, 120.0), 0.60).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	boss_action_tween.tween_property(boss_rect, "scale", Vector2(1.10, 1.10), 0.60).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	boss_action_tween.tween_property(boss_rect, "modulate", Color(1.4, 0.9, 1.6, 1.0), 0.60)

	var hold_tw: Tween = create_tween()
	hold_tw.tween_interval(ULTIMATE_CHARGE_DURATION)
	hold_tw.tween_callback(func():
		if ultimate_telegraph_panel != null:
			ultimate_telegraph_panel.visible = false
		if ultimate_dim_overlay != null:
			ultimate_dim_overlay.visible = false
		is_ultimate_charge_active = false
		trigger_boss_ultimate_challenge()
	)

func trigger_boss_ultimate_challenge() -> void:
	is_ultimate_challenge_active = true
	combat_resolving = false
	ultimate_timer = ULTIMATE_CHALLENGE_DURATION

	if question_panel != null:
		question_panel.visible = true
		question_panel.modulate.a = 1.0
	if tactical_hand_tray != null:
		tactical_hand_tray.visible = true
		tactical_hand_tray.modulate.a = 1.0

	if question_stage_label != null:
		question_stage_label.text = "CHAOS VERDICT • THỬ THÁCH ĐẠI PHÉP"
	if question_prompt_label != null:
		question_prompt_label.text = "Giải mã ma trận xác suất: Chọn biểu thức đúng để hoá giải nguồn năng lượng hỗn mang!"

	var choices: Array = [
		{"code": "A", "val": "P(A) + P(Ā) = 1", "sub": "Biến cố đối"},
		{"code": "B", "val": "P(A) + P(B) > 1", "sub": "Không chuẩn"},
		{"code": "C", "val": "P(Ω) = 0", "sub": "Sai quy tắc"},
		{"code": "D", "val": "P(∅) = 1", "sub": "Biến cố rỗng"}
	]
	for i in range(answer_buttons.size()):
		if i < choices.size():
			answer_buttons[i].visible = true
			answer_buttons[i].disabled = false
			answer_buttons[i].text = "%s. %s" % [choices[i]["code"], choices[i]["val"]]
			answer_buttons[i].add_theme_color_override("font_color", Color.WHITE)
			var n_style: StyleBoxFlat = _create_glass_box(COLOR_CARD_BG, COLOR_CARD_BORDER, 4)
			answer_buttons[i].add_theme_stylebox_override("normal", n_style)
		else:
			answer_buttons[i].visible = false

	selected_answer_idx = -1
	has_selected_answer = false
	if cta_button != null:
		cta_button.text = "PHÁ GIẢI ĐẠI PHÉP"
		cta_button.disabled = false
	if helper_label != null:
		helper_label.text = "THỜI GIAN: 8.0s  •  PHÁ GIẢI TRƯỚC KHI HẾT GIỜ!"

	_set_question_input_enabled(true)

func trigger_ultimate_success() -> void:
	if not is_ultimate_challenge_active and not is_ultimate_charge_active:
		return
	is_ultimate_challenge_active = false
	is_ultimate_charge_active = false
	combat_resolving = true
	_set_question_input_enabled(false)
	if question_panel != null:
		question_panel.visible = false

	play_karl_dodge()
	set_boss_state(BossState.ULTIMATE_RELEASE)

	_spawn_floating_feedback(Vector2(200, 320), "MISS / NÉ!", COLOR_ACCENT_GOLD)

	var rel_tw: Tween = create_tween()
	rel_tw.tween_interval(0.75)
	rel_tw.tween_callback(func():
		if boss_rect != null:
			boss_rect.position = BOSS_BASE_POS
			boss_rect.scale = Vector2.ONE
			boss_rect.rotation_degrees = 0.0
			boss_rect.modulate = Color.WHITE
		set_boss_state(BossState.ENRAGED if is_boss_enraged else BossState.IDLE)
		_start_boss_idle_loop()
		combat_resolving = false
		_restore_normal_ui_after_ultimate()
	)

func trigger_ultimate_failure(is_timeout: bool = false) -> void:
	if not is_ultimate_challenge_active and not is_ultimate_charge_active:
		return
	is_ultimate_challenge_active = false
	is_ultimate_charge_active = false
	combat_resolving = true
	_set_question_input_enabled(false)
	if question_panel != null:
		question_panel.visible = false

	set_boss_state(BossState.ULTIMATE_RELEASE)
	apply_damage_to_karl(24)

	if is_timeout:
		_spawn_floating_feedback(Vector2(200, 270), "HẾT GIỜ! ĐẠI PHÉP GIÁNG LÂM!", COLOR_ACCENT_RED)
	else:
		_spawn_floating_feedback(Vector2(200, 270), "PHÁ GIẢI THẤT BẠI! -24 DMG", COLOR_ACCENT_RED)

	var rel_tw: Tween = create_tween()
	rel_tw.tween_interval(0.85)
	rel_tw.tween_callback(func():
		if boss_rect != null:
			boss_rect.position = BOSS_BASE_POS
			boss_rect.scale = Vector2.ONE
			boss_rect.rotation_degrees = 0.0
			boss_rect.modulate = Color.WHITE
		set_boss_state(BossState.ENRAGED if is_boss_enraged else BossState.IDLE)
		_start_boss_idle_loop()
		combat_resolving = false
		_restore_normal_ui_after_ultimate()
	)

func simulate_ultimate_success() -> void:
	trigger_ultimate_success()

func simulate_ultimate_failure() -> void:
	trigger_ultimate_failure(false)

func _restore_normal_ui_after_ultimate() -> void:
	if question_panel != null:
		question_panel.visible = true
		question_panel.modulate.a = 1.0
		question_panel.position = Vector2(QUESTION_CENTER_X - (QUESTION_WIDTH / 2.0), QUESTION_TOP)
		question_panel.size = Vector2(QUESTION_WIDTH, QUESTION_HEIGHT)
	if card_row_container != null:
		card_row_container.visible = true
		card_row_container.modulate.a = 1.0
	if tactical_hand_tray != null:
		tactical_hand_tray.visible = true
		tactical_hand_tray.modulate.a = 1.0
	current_question_idx = (current_question_idx + 1) % questions_data.size()
	selected_answer_idx = -1
	has_selected_answer = false
	_update_question_view()
	_update_card_selection()
	_update_hover_detail(selected_card_idx)
	_update_cta_button_text()
	_set_question_input_enabled(true)

func open_probability_draw() -> void:
	if is_draw_open or combat_resolving:
		return
	is_draw_open = true
	is_tactical_pick_mode = true
	if hand_cursor_node != null:
		hand_cursor_node.visible = true
		hand_cursor_node.position = Vector2(640, 360)
	fade_question_for_combat()
	emit_signal("probability_draw_started")

	var drawn_cards: Array[Dictionary] = draw_three_tactical_cards()
	emit_signal("probability_cards_revealed", drawn_cards)

	for child in draw_cards_container.get_children():
		child.queue_free()

	for i in range(drawn_cards.size()):
		var card_data: Dictionary = drawn_cards[i]
		var is_rare: bool = (card_data.get("rarity", "") == "RARE")
		var pnl: PanelContainer = PanelContainer.new()
		pnl.custom_minimum_size = Vector2(196, 260)
		var pstyle: StyleBoxFlat = _create_glass_box(
			Color(0.12, 0.10, 0.06, 0.95) if is_rare else Color(0.07, 0.11, 0.18, 0.95),
			COLOR_ACCENT_GOLD if is_rare else COLOR_ACCENT_CYAN,
			8
		)
		pstyle.content_margin_left = 10
		pstyle.content_margin_top = 10
		pstyle.content_margin_right = 10
		pstyle.content_margin_bottom = 10
		pnl.add_theme_stylebox_override("panel", pstyle)

		var cvbox: VBoxContainer = VBoxContainer.new()
		cvbox.add_theme_constant_override("separation", 8)
		pnl.add_child(cvbox)

		var r_lbl: Label = Label.new()
		r_lbl.text = "✦ THẺ HIẾM ✦" if is_rare else "✦ THẺ THƯỜNG ✦"
		r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r_lbl.add_theme_font_size_override("font_size", 10)
		r_lbl.add_theme_color_override("font_color", COLOR_ACCENT_GOLD if is_rare else COLOR_ACCENT_CYAN)
		cvbox.add_child(r_lbl)

		var name_lbl: Label = Label.new()
		name_lbl.text = card_data.get("name", "")
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		cvbox.add_child(name_lbl)

		var desc_lbl: Label = Label.new()
		desc_lbl.text = card_data.get("desc", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cvbox.add_child(desc_lbl)

		var pick_btn: Button = Button.new()
		pick_btn.text = "CHỌN THẺ NÀY"
		pick_btn.custom_minimum_size = Vector2(0, 36)
		var b_style: StyleBoxFlat = _create_solid_box(
			Color(0.85, 0.65, 0.15, 1.0) if is_rare else Color(0.20, 0.55, 0.85, 1.0),
			4
		)
		pick_btn.add_theme_stylebox_override("normal", b_style)
		pick_btn.add_theme_color_override("font_color", Color(0.05, 0.08, 0.12, 1.0))
		pick_btn.add_theme_font_size_override("font_size", 12)
		pnl.mouse_entered.connect(func():
			var h_tw: Tween = create_tween()
			h_tw.tween_property(pnl, "position:y", pnl.position.y - 12.0, 0.12)
		)
		pnl.mouse_exited.connect(func():
			var h_tw: Tween = create_tween()
			h_tw.tween_property(pnl, "position:y", pnl.position.y + 12.0, 0.12)
		)

		pick_btn.pressed.connect(func():
			if hand_cursor_node != null:
				var c_tw: Tween = create_tween()
				c_tw.tween_property(hand_cursor_node, "scale", Vector2(0.85, 0.85), 0.10)
				c_tw.tween_property(hand_cursor_node, "scale", Vector2.ONE, 0.10)
			_on_tactical_card_picked(card_data)
		)
		cvbox.add_child(pick_btn)

		draw_cards_container.add_child(pnl)

	probability_draw_modal.visible = true

func close_probability_draw() -> void:
	is_draw_open = false
	is_tactical_pick_mode = false
	if hand_cursor_node != null:
		hand_cursor_node.visible = false
	if probability_draw_modal != null:
		probability_draw_modal.visible = false
	restore_question_after_combat()

func _on_tactical_card_picked(card_data: Dictionary) -> void:
	if tactical_hand.size() < MAX_TACTICAL_HAND:
		tactical_hand.append(card_data)
		_update_tactical_hand_ui()
		emit_signal("tactical_card_selected", card_data["id"], tactical_hand.size() - 1)
		_spawn_floating_feedback(Vector2(640, 350), "Đã nhận: " + card_data["name"], COLOR_ACCENT_GOLD if card_data["rarity"] == "RARE" else COLOR_ACCENT_CYAN)
		close_probability_draw()
	else:
		pending_draft_card = card_data
		_open_replace_modal()

func _open_replace_modal() -> void:
	if replace_modal == null:
		return
	var slots_vbox = replace_modal.find_child("SlotsVBox", true, false) as VBoxContainer
	if slots_vbox != null:
		for c in slots_vbox.get_children():
			c.queue_free()
		for i in range(tactical_hand.size()):
			var held = tactical_hand[i]
			var btn: Button = Button.new()
			btn.text = "Thay thế [%s] bằng [%s]" % [held["name"], pending_draft_card.get("name", "")]
			btn.custom_minimum_size = Vector2(0, 34)
			var b_style: StyleBoxFlat = _create_solid_box(Color(0.12, 0.18, 0.28, 0.9), 4)
			btn.add_theme_stylebox_override("normal", b_style)
			btn.add_theme_font_size_override("font_size", 11)
			btn.pressed.connect(func(): _on_replace_confirm(i))
			slots_vbox.add_child(btn)

	replace_modal.visible = true

func _on_replace_confirm(slot_idx: int) -> void:
	if slot_idx >= 0 and slot_idx < tactical_hand.size():
		var replaced_name: String = tactical_hand[slot_idx]["name"]
		tactical_hand[slot_idx] = pending_draft_card
		_update_tactical_hand_ui()
		emit_signal("tactical_card_selected", pending_draft_card["id"], slot_idx)
		_spawn_floating_feedback(Vector2(640, 350), "Đã đổi %s -> %s" % [replaced_name, pending_draft_card["name"]], COLOR_ACCENT_GOLD)
	replace_modal.visible = false
	close_probability_draw()

func _on_replace_discard_new() -> void:
	_spawn_floating_feedback(Vector2(640, 350), "Đã bỏ qua thẻ mới", COLOR_TEXT_MUTED)
	replace_modal.visible = false
	close_probability_draw()

func use_tactical_card(slot_idx: int) -> void:
	if combat_resolving or is_draw_open:
		return
	if slot_idx < 0 or slot_idx >= tactical_hand.size():
		return

	var card: Dictionary = tactical_hand[slot_idx]
	var card_id: String = card.get("id", "")

	if is_ultimate_challenge_active:
		match card_id:
			"card_tactical_eliminate":
				play_karl_skill_cast(true)
				var wrong_avail: Array[int] = []
				for i in range(1, 4):
					if not answer_buttons[i].disabled:
						wrong_avail.append(i)
				if wrong_avail.size() <= 1:
					_spawn_floating_feedback(Vector2(640, 350), "Không thể loại trừ thêm!", COLOR_ACCENT_GOLD)
					return
				var elim_idx: int = wrong_avail[0]
				answer_buttons[elim_idx].disabled = true
				var d_style: StyleBoxFlat = _create_solid_box(Color(0.12, 0.08, 0.10, 0.50), 4)
				answer_buttons[elim_idx].add_theme_stylebox_override("normal", d_style)
				answer_buttons[elim_idx].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
				tactical_hand.remove_at(slot_idx)
				_update_tactical_hand_ui()
				_spawn_floating_feedback(Vector2(640, 350), "Đã loại bỏ 1 đáp án sai!", COLOR_ACCENT_CYAN)
				emit_signal("tactical_card_used", card_id)
				return

			"card_tactical_add_time":
				play_karl_skill_cast(true)
				ultimate_timer = min(12.0, ultimate_timer + 3.0)
				tactical_hand.remove_at(slot_idx)
				_update_tactical_hand_ui()
				_spawn_floating_feedback(Vector2(640, 350), "+3s NÉ TRÁNH!", COLOR_ACCENT_GREEN)
				emit_signal("tactical_card_used", card_id)
				return

			"card_tactical_reroll":
				_spawn_floating_feedback(Vector2(640, 350), "Không thể đổi câu khi boss đang niệm Đại Phép!", COLOR_ACCENT_RED)
				return

			"card_tactical_stun":
				play_karl_skill_cast(false)
				is_stun_armed = true
				tactical_hand.remove_at(slot_idx)
				_update_tactical_hand_ui()
				_spawn_floating_feedback(Vector2(200, 300), "⚡ CHOÁNG ĐÃ NẠP (Áp dụng sau Đại Phép)!", COLOR_ACCENT_GOLD)
				emit_signal("stun_armed")
				emit_signal("tactical_card_used", card_id)
				return

			"card_tactical_critical":
				play_karl_skill_cast(false)
				is_critical_armed = true
				tactical_hand.remove_at(slot_idx)
				_update_tactical_hand_ui()
				_update_strike_card_stat()
				_spawn_floating_feedback(Vector2(200, 300), "⚔️ CRITICAL ĐÃ NẠP!", COLOR_ACCENT_RED)
				emit_signal("critical_armed")
				emit_signal("tactical_card_used", card_id)
				return

			"card_tactical_aegis":
				play_karl_skill_cast(false)
				var new_shield: int = min(24, current_shield + 6)
				set_shield(new_shield)
				tactical_hand.remove_at(slot_idx)
				_update_tactical_hand_ui()
				_spawn_floating_feedback(Vector2(200, 300), "+6 GIÁP (BẢO HỘ)", COLOR_ACCENT_CYAN)
				_spawn_barrier_pulse()
				emit_signal("aegis_triggered", 6)
				emit_signal("tactical_card_used", card_id)
				return

	match card_id:
		"card_tactical_eliminate":
			play_karl_skill_cast(true)
			var q_data: Dictionary = questions_data[current_question_idx]
			var correct_idx: int = q_data["correct"]
			var wrong_available: Array[int] = []
			for i in range(answer_buttons.size()):
				if i != correct_idx and not answer_buttons[i].disabled:
					wrong_available.append(i)
			if wrong_available.size() <= 1:
				_spawn_floating_feedback(Vector2(640, 350), "Không thể loại trừ thêm!", COLOR_ACCENT_GOLD)
				return
			var eliminate_idx: int = wrong_available[0]
			answer_buttons[eliminate_idx].disabled = true
			var d_style: StyleBoxFlat = _create_solid_box(Color(0.12, 0.08, 0.10, 0.50), 4)
			answer_buttons[eliminate_idx].add_theme_stylebox_override("normal", d_style)
			answer_buttons[eliminate_idx].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
			tactical_hand.remove_at(slot_idx)
			_update_tactical_hand_ui()
			_spawn_floating_feedback(Vector2(640, 350), "Đã loại bỏ 1 đáp án sai!", COLOR_ACCENT_CYAN)
			emit_signal("tactical_card_used", card_id)

		"card_tactical_reroll":
			play_karl_skill_cast(true)
			tactical_hand.remove_at(slot_idx)
			_update_tactical_hand_ui()
			cycle_question()
			for btn in answer_buttons:
				btn.disabled = false
			_spawn_floating_feedback(Vector2(640, 350), "Đã đổi câu hỏi!", COLOR_ACCENT_GOLD)
			emit_signal("tactical_card_used", card_id)

		"card_tactical_add_time":
			play_karl_skill_cast(true)
			if question_timer_seconds >= QUESTION_TIMER_MAX:
				_spawn_floating_feedback(Vector2(640, 350), "Đã đạt thời gian tối đa (90s)!", COLOR_ACCENT_GOLD)
				return
			question_timer_seconds = min(QUESTION_TIMER_MAX, question_timer_seconds + 15.0)
			tactical_hand.remove_at(slot_idx)
			_update_tactical_hand_ui()
			_spawn_floating_feedback(Vector2(640, 350), "+15s Thời gian!", COLOR_ACCENT_GREEN)
			emit_signal("tactical_card_used", card_id)

		"card_tactical_stun":
			play_karl_skill_cast(false)
			is_stun_armed = true
			tactical_hand.remove_at(slot_idx)
			_update_tactical_hand_ui()
			_spawn_floating_feedback(Vector2(200, 300), "⚡ CHOÁNG ĐÃ NẠP!", COLOR_ACCENT_GOLD)
			emit_signal("stun_armed")
			emit_signal("tactical_card_used", card_id)

		"card_tactical_critical":
			play_karl_skill_cast(false)
			is_critical_armed = true
			tactical_hand.remove_at(slot_idx)
			_update_tactical_hand_ui()
			_update_strike_card_stat()
			_spawn_floating_feedback(Vector2(200, 300), "⚔️ CRITICAL ĐÃ NẠP!", COLOR_ACCENT_RED)
			emit_signal("critical_armed")
			emit_signal("tactical_card_used", card_id)

		"card_tactical_aegis":
			play_karl_skill_cast(false)
			var new_shield: int = min(24, current_shield + 6)
			set_shield(new_shield)
			tactical_hand.remove_at(slot_idx)
			_update_tactical_hand_ui()
			_spawn_floating_feedback(Vector2(200, 300), "+6 GIÁP (BẢO HỘ)", COLOR_ACCENT_CYAN)
			_spawn_barrier_pulse()
			emit_signal("aegis_triggered", 6)
			emit_signal("tactical_card_used", card_id)

func _update_strike_card_stat() -> void:
	if cards_data.size() > 0:
		if is_critical_armed:
			cards_data[0]["stat_badge"] = "15 DMG"
			cards_data[0]["effect"] = "Gây 15 sát thương (CRITICAL)"
		else:
			cards_data[0]["stat_badge"] = "10 DMG"
			cards_data[0]["effect"] = "Gây 10 sát thương"
		_update_card_selection()
		if selected_card_idx == 0:
			_update_cta_button_text()
			_update_hover_detail(0)

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

func _update_card_selection() -> void:
	for i in range(card_panels.size()):
		var panel: PanelContainer = card_panels[i]
		var is_selected: bool = (i == selected_card_idx)
		var is_disabled: bool = cards_data[i]["disabled"]

		if is_disabled:
			panel.position.y = 0
			var dis_style: StyleBoxFlat = _create_card_style(Color(0.06, 0.08, 0.12, 0.8), Color(0.25, 0.30, 0.40, 0.4), 6)
			panel.add_theme_stylebox_override("panel", dis_style)
			panel.modulate = Color(0.5, 0.5, 0.55, 0.60)
		elif is_selected:
			panel.position.y = -8.0
			var sel_style: StyleBoxFlat = _create_card_style(Color(0.12, 0.16, 0.25, 0.98), COLOR_CARD_SELECTED_BORDER, 6)
			sel_style.border_width_left = 2
			sel_style.border_width_top = 2
			sel_style.border_width_right = 2
			sel_style.border_width_bottom = 2
			sel_style.shadow_color = Color(1.0, 0.85, 0.30, 0.35)
			sel_style.shadow_size = 8
			panel.add_theme_stylebox_override("panel", sel_style)
			panel.modulate = Color.WHITE
		else:
			panel.position.y = 0
			var norm_style: StyleBoxFlat = _create_card_style(COLOR_CARD_BG, COLOR_CARD_BORDER, 6)
			panel.add_theme_stylebox_override("panel", norm_style)
			panel.modulate = Color.WHITE

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
		var is_selected: bool = (has_selected_answer and i == selected_answer_idx)

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
		_spawn_floating_feedback(Vector2(690, 125), q_data["hint"], COLOR_ACCENT_GOLD)

func _on_cta_pressed() -> void:
	if combat_resolving or is_draw_open:
		return

	if is_ultimate_challenge_active:
		if not has_selected_answer or selected_answer_idx < 0:
			_spawn_floating_feedback(Vector2(690, 410), "Chọn đáp án để phá giải!", COLOR_ACCENT_GOLD)
			return
		var is_correct_ult: bool = (selected_answer_idx == 0)
		if is_correct_ult:
			trigger_ultimate_success()
		else:
			trigger_ultimate_failure(false)
		return

	if not has_selected_answer or selected_answer_idx < 0:
		_spawn_floating_feedback(Vector2(690, 410), "Chọn đáp án trước", COLOR_ACCENT_GOLD)
		return

	var card: Dictionary = cards_data[selected_card_idx]
	if card.get("disabled", false):
		_spawn_floating_feedback(Vector2(690, 460), "CHƯA KÍCH HOẠT", COLOR_ACCENT_PURPLE)
		return

	var q_data: Dictionary = questions_data[current_question_idx]
	var is_correct: bool = (selected_answer_idx == q_data["correct"])

	increment_ultimate_meter()

	if is_correct:
		add_probability_charge(1)

		if is_stun_armed:
			is_stun_armed = false
			stochas_stun_charges = 1
			trigger_boss_stun()
			_spawn_floating_feedback(Vector2(1040, 240), "STOCHAS BỊ CHOÁNG (1 charge)!", COLOR_ACCENT_GOLD)

		if card["id"] == "strike":
			trigger_cast_effect()
		elif card["id"] == "defend":
			trigger_shield_effect()
		elif card["id"] == "heal":
			trigger_heal_effect()
	else:
		if is_stun_armed:
			is_stun_armed = false
			stochas_stun_charges = 0
			_spawn_floating_feedback(Vector2(200, 300), "Choáng thất bại!", COLOR_ACCENT_RED)

		if stochas_stun_charges > 0:
			stochas_stun_charges -= 1
			combat_resolving = true
			fade_question_for_combat()
			_spawn_floating_feedback(Vector2(1040, 240), "STOCHAS BỊ CHOÁNG! Đòn đánh bị chặn!", COLOR_ACCENT_GOLD)
			emit_signal("stun_triggered")
			var tw: Tween = create_tween()
			tw.tween_interval(0.8)
			tw.tween_callback(func():
				combat_resolving = false
				restore_question_after_combat()
			)
		else:
			var chosen_spell: BossSpellType = select_boss_spell_weighted()
			cast_boss_spell(chosen_spell)

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
