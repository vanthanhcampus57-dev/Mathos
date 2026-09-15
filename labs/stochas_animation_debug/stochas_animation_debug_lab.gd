extends Control

## ==============================================================================
## STOCHAS ANIMATION DEBUG & INSPECTION LAB
## TASK_ID: MATHOS-STOCHAS-ULTIMATE-CHARGE-FINAL-INTEGRATE-239L
##
## Dedicated diagnostic studio for inspecting, timing, and refining STOCHAS
## boss animation states, distinct spell profiles, speed scaling, and the
## human-approved 6-frame Ultimate Charge sequence (F01 - F06).
## ==============================================================================

# Assets
const ASSET_STOCHAS_BOSS: String = "res://assets/characters/bosses/dungeon_1/stochas_boss.png"
const ASSET_STOCHAS_ULTIMATE_SEQUENCE: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_sequence.png"

# WAD2 Human-Approved Final Ultimate Charge Frames (6 Independent Textures)
const ASSET_STOCHAS_ULTIMATE_CHARGE_F01: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f01.png"
const ASSET_STOCHAS_ULTIMATE_CHARGE_F02: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f02.png"
const ASSET_STOCHAS_ULTIMATE_CHARGE_F03: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f03.png"
const ASSET_STOCHAS_ULTIMATE_CHARGE_F04: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f04.png"
const ASSET_STOCHAS_ULTIMATE_CHARGE_F05: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f05.png"
const ASSET_STOCHAS_ULTIMATE_CHARGE_F06: String = "res://assets/characters/bosses/dungeon_1/stochas_ultimate_charge/stochas_ultimate_charge_f06.png"

const ASSET_VFX_BOLT: String = "res://assets/vfx/combat/stochas_arcane_bolt.png"
const ASSET_VFX_ORB: String = "res://assets/vfx/combat/stochas_probability_orb.png"
const ASSET_VFX_RIFT: String = "res://assets/vfx/combat/stochas_void_rift.png"
const ASSET_VFX_SWEEP: String = "res://assets/vfx/combat/stochas_arcane_sweep.png"
const ASSET_BG: String = "res://assets/ui/combat/boss_combat_bg_placeholder.png"

# Geometry & Layout (1280 x 720)
const BOSS_BASE_POS: Vector2 = Vector2(180.0, 50.0)
const BOSS_BASE_SIZE: Vector2 = Vector2(520.0, 560.0)
const BASELINE_Y: float = 610.0 # 50.0 + 560.0 = 610.0

# 11 Selectable Animation States
enum AnimationState {
	IDLE,
	CAST_BOLT,
	CAST_ORB,
	CAST_RIFT,
	CAST_SWEEP,
	HIT,
	STUN,
	ENRAGED,
	ULTIMATE_CHARGE,
	ULTIMATE_RELEASE,
	ULTIMATE_FULL
}

const STATE_NAMES: Dictionary = {
	AnimationState.IDLE: "IDLE",
	AnimationState.CAST_BOLT: "CAST_BOLT",
	AnimationState.CAST_ORB: "CAST_ORB",
	AnimationState.CAST_RIFT: "CAST_RIFT",
	AnimationState.CAST_SWEEP: "CAST_SWEEP",
	AnimationState.HIT: "HIT",
	AnimationState.STUN: "STUN",
	AnimationState.ENRAGED: "ENRAGED",
	AnimationState.ULTIMATE_CHARGE: "ULTIMATE_CHARGE",
	AnimationState.ULTIMATE_RELEASE: "ULTIMATE_RELEASE",
	AnimationState.ULTIMATE_FULL: "ULTIMATE_FULL"
}

# Distinct Spell Motion Profiles
const SPELL_PROFILES: Dictionary = {
	AnimationState.CAST_BOLT: {
		"name": "ARCANE_BOLT",
		"description": "Fast/snappy, backward anticipation, rapid forward snap, cyan projectile flare",
		"duration": 0.45,
		"anticipation_offset": Vector2(16.0, 0.0),
		"anticipation_rotation": -1.5,
		"anticipation_time": 0.12,
		"snap_offset": Vector2(-32.0, 0.0),
		"snap_rotation": 2.5,
		"snap_time": 0.15,
		"recoil_time": 0.18,
		"max_lateral_displacement": 48.0,
		"max_rotation_swing": 4.0,
		"vfx_type": "cyan_flare_projectile"
	},
	AnimationState.CAST_ORB: {
		"name": "PROBABILITY_ORB",
		"description": "Ritual/controlled, vertical float, scale expansion, circular orbiting orb VFX",
		"duration": 0.80,
		"float_offset": Vector2(0.0, -26.0),
		"float_rotation": -2.5,
		"float_time": 0.35,
		"peak_scale": Vector2(1.05, 1.05),
		"release_offset": Vector2(10.0, -10.0),
		"release_rotation": 0.0,
		"release_time": 0.25,
		"recoil_time": 0.20,
		"max_lateral_displacement": 10.0,
		"max_rotation_swing": 2.5,
		"vfx_type": "circular_orbiting_orb"
	},
	AnimationState.CAST_RIFT: {
		"name": "VOID_RIFT",
		"description": "Heavy summon/hold, lateral torso lean, downward sink, held pose while rift opens",
		"duration": 0.95,
		"sink_offset": Vector2(22.0, 20.0),
		"sink_rotation": 3.8,
		"windup_time": 0.30,
		"hold_duration": 0.40,
		"recoil_time": 0.25,
		"max_lateral_displacement": 22.0,
		"max_rotation_swing": 3.8,
		"vfx_type": "void_rift_portal"
	},
	AnimationState.CAST_SWEEP: {
		"name": "ARCANE_SWEEP",
		"description": "Wide/forceful, strong wind-up, massive lateral sweep, wide arc sweep VFX",
		"duration": 1.00,
		"windup_offset": Vector2(40.0, -5.0),
		"windup_rotation": -6.2,
		"windup_scale": Vector2(1.08, 0.96),
		"windup_time": 0.35,
		"sweep_offset": Vector2(-45.0, 5.0),
		"sweep_rotation": 5.5,
		"sweep_scale": Vector2(0.96, 1.04),
		"sweep_time": 0.35,
		"recoil_time": 0.30,
		"max_lateral_displacement": 85.0,
		"max_rotation_swing": 11.7,
		"vfx_type": "wide_arc_slash"
	}
}

# State Durations
const STATE_DURATIONS: Dictionary = {
	AnimationState.IDLE: 3.20,
	AnimationState.CAST_BOLT: 0.45,
	AnimationState.CAST_ORB: 0.80,
	AnimationState.CAST_RIFT: 0.95,
	AnimationState.CAST_SWEEP: 1.00,
	AnimationState.HIT: 0.35,
	AnimationState.STUN: 1.00,
	AnimationState.ENRAGED: 1.80,
	AnimationState.ULTIMATE_CHARGE: 2.40,
	AnimationState.ULTIMATE_RELEASE: 1.02, # 0.72s frames + 0.30s recovery
	AnimationState.ULTIMATE_FULL: 3.42 # 2.40s charge + 1.02s release/recovery
}

# Runtime Variables
var current_state: AnimationState = AnimationState.IDLE
var playback_speed: float = 1.0
var is_paused: bool = false
var is_loop_enabled: bool = false
var is_compare_casts_active: bool = false
var compare_step_idx: int = 0
var compare_timer: float = 0.0
var compare_sequence: Array[AnimationState] = [
	AnimationState.CAST_BOLT,
	AnimationState.CAST_ORB,
	AnimationState.CAST_RIFT,
	AnimationState.CAST_SWEEP
]

var current_atlas_frame: int = -1 # -1 = canonical boss / charge frame, 0..7 = release atlas frames
var current_charge_frame: int = -1 # -1 = canonical boss / atlas frame, 0..5 = F01..F06
var elapsed_time: float = 0.0
var state_duration: float = 3.20
var active_tween: Tween = null
var is_animating: bool = false

# Motion Path Overlay
var motion_path_enabled: bool = false
var motion_trail_points: Array[Vector2] = []
const MAX_MOTION_POINTS: int = 150

# Loaded Assets
var canonical_boss_tex: Texture2D = null
var stochas_ultimate_frames: Array[AtlasTexture] = []
var stochas_ultimate_charge_frames: Array[Texture2D] = []
var vfx_bolt_tex: Texture2D = null
var vfx_orb_tex: Texture2D = null
var vfx_rift_tex: Texture2D = null
var vfx_sweep_tex: Texture2D = null
var bg_tex: Texture2D = null

# Scene Node References
var bg_rect: TextureRect = null
var pedestal_panel: Panel = null
var baseline_marker: ColorRect = null
var boss_rect: TextureRect = null
var boss_vfx_container: Control = null
var stun_overlay: Control = null
var stun_stars: Array[Label] = []
var dim_overlay: ColorRect = null
var motion_path_line: Line2D = null

# UI Control Elements
var right_panel: PanelContainer = null
var state_buttons: Dictionary = {}
var speed_slider: HSlider = null
var speed_label: Label = null
var btn_pause: Button = null
var btn_loop: Button = null
var btn_compare: Button = null
var btn_motion_path: Button = null
var btn_prev_frame: Button = null
var btn_next_frame: Button = null
var btn_reset_baseline: Button = null

# Diagnostic Readout UI
var bottom_panel: PanelContainer = null
var lbl_diag_state: Label = null
var lbl_diag_details: Label = null

func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_resources()
	_build_ui_environment()
	_build_boss_preview()
	_build_controls_ui()
	_build_diagnostic_ui()
	restore_canonical_baseline()
	play_animation(AnimationState.IDLE)

func _load_resources() -> void:
	if ResourceLoader.exists(ASSET_BG):
		bg_tex = load(ASSET_BG)
	if ResourceLoader.exists(ASSET_STOCHAS_BOSS):
		canonical_boss_tex = load(ASSET_STOCHAS_BOSS)
	if ResourceLoader.exists(ASSET_VFX_BOLT):
		vfx_bolt_tex = load(ASSET_VFX_BOLT)
	if ResourceLoader.exists(ASSET_VFX_ORB):
		vfx_orb_tex = load(ASSET_VFX_ORB)
	if ResourceLoader.exists(ASSET_VFX_RIFT):
		vfx_rift_tex = load(ASSET_VFX_RIFT)
	if ResourceLoader.exists(ASSET_VFX_SWEEP):
		vfx_sweep_tex = load(ASSET_VFX_SWEEP)

	# 1. Load 6 Independent WAD2 Ultimate Charge Textures (F01 - F06)
	stochas_ultimate_charge_frames.clear()
	var charge_paths: Array[String] = [
		ASSET_STOCHAS_ULTIMATE_CHARGE_F01,
		ASSET_STOCHAS_ULTIMATE_CHARGE_F02,
		ASSET_STOCHAS_ULTIMATE_CHARGE_F03,
		ASSET_STOCHAS_ULTIMATE_CHARGE_F04,
		ASSET_STOCHAS_ULTIMATE_CHARGE_F05,
		ASSET_STOCHAS_ULTIMATE_CHARGE_F06
	]
	for p in charge_paths:
		if ResourceLoader.exists(p):
			var tex: Texture2D = load(p) as Texture2D
			stochas_ultimate_charge_frames.append(tex)
		elif FileAccess.file_exists(p):
			var img: Image = Image.load_from_file(p)
			if img != null and not img.is_empty():
				var tex: ImageTexture = ImageTexture.create_from_image(img)
				stochas_ultimate_charge_frames.append(tex)

	# 2. Slice 8 frames of 384x384 Ultimate Release sequence
	stochas_ultimate_frames.clear()
	if ResourceLoader.exists(ASSET_STOCHAS_ULTIMATE_SEQUENCE):
		var full_seq = load(ASSET_STOCHAS_ULTIMATE_SEQUENCE)
		for i in range(8):
			var at = AtlasTexture.new()
			at.atlas = full_seq
			at.region = Rect2(i * 384.0, 0.0, 384.0, 384.0)
			stochas_ultimate_frames.append(at)

func _build_ui_environment() -> void:
	# Studio dark background
	var studio_bg = ColorRect.new()
	studio_bg.name = "StudioBackground"
	studio_bg.size = Vector2(1280, 720)
	studio_bg.color = Color(0.07, 0.07, 0.10, 1.0)
	add_child(studio_bg)

	if bg_tex != null:
		bg_rect = TextureRect.new()
		bg_rect.name = "CombatBGSubtle"
		bg_rect.texture = bg_tex
		bg_rect.size = Vector2(1280, 720)
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_rect.modulate = Color(0.35, 0.35, 0.45, 0.40) # Muted studio backdrop
		add_child(bg_rect)

	# Studio ground pedestal & baseline marker
	pedestal_panel = Panel.new()
	pedestal_panel.name = "StudioPedestal"
	pedestal_panel.position = Vector2(140.0, 600.0)
	pedestal_panel.size = Vector2(600.0, 18.0)
	var ped_style = StyleBoxFlat.new()
	ped_style.bg_color = Color(0.12, 0.14, 0.20, 0.90)
	ped_style.border_color = Color(0.30, 0.50, 0.85, 0.80)
	ped_style.border_width_top = 2
	ped_style.corner_radius_top_left = 6
	ped_style.corner_radius_top_right = 6
	pedestal_panel.add_theme_stylebox_override("panel", ped_style)
	add_child(pedestal_panel)

	# Baseline Y=610 marker
	baseline_marker = ColorRect.new()
	baseline_marker.name = "BaselineMarker"
	baseline_marker.position = Vector2(140.0, BASELINE_Y)
	baseline_marker.size = Vector2(600.0, 2.0)
	baseline_marker.color = Color(0.40, 0.80, 1.0, 0.70)
	add_child(baseline_marker)

	var baseline_lbl = Label.new()
	baseline_lbl.text = "GROUND BASELINE Y = 610.0"
	baseline_lbl.position = Vector2(145.0, BASELINE_Y + 4.0)
	baseline_lbl.add_theme_font_size_override("font_size", 10)
	baseline_lbl.modulate = Color(0.5, 0.8, 1.0, 0.8)
	add_child(baseline_lbl)

	# Dim overlay for Ultimate charge
	dim_overlay = ColorRect.new()
	dim_overlay.name = "UltimateDimOverlay"
	dim_overlay.size = Vector2(1280, 720)
	dim_overlay.color = Color(0.02, 0.02, 0.05, 1.0)
	dim_overlay.modulate.a = 0.0
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim_overlay)

	# Motion path line
	motion_path_line = Line2D.new()
	motion_path_line.name = "MotionPathLine"
	motion_path_line.width = 3.0
	motion_path_line.default_color = Color(0.2, 0.9, 1.0, 0.75)
	motion_path_line.visible = false
	add_child(motion_path_line)

func _build_boss_preview() -> void:
	boss_rect = TextureRect.new()
	boss_rect.name = "StochasPreviewBoss"
	boss_rect.position = BOSS_BASE_POS
	boss_rect.size = BOSS_BASE_SIZE
	boss_rect.custom_minimum_size = BOSS_BASE_SIZE
	boss_rect.pivot_offset = BOSS_BASE_SIZE * 0.5
	boss_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if canonical_boss_tex != null:
		boss_rect.texture = canonical_boss_tex
	add_child(boss_rect)

	# Boss VFX container attached to boss
	boss_vfx_container = Control.new()
	boss_vfx_container.name = "BossVFXContainer"
	boss_vfx_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_vfx_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_rect.add_child(boss_vfx_container)

	# Stun overlay (stars circling above head)
	stun_overlay = Control.new()
	stun_overlay.name = "StunOverlay"
	stun_overlay.position = Vector2(BOSS_BASE_SIZE.x * 0.5, 30.0)
	stun_overlay.visible = false
	boss_rect.add_child(stun_overlay)

	for i in range(3):
		var star = Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", 28)
		star.modulate = Color(1.0, 0.88, 0.25, 0.95)
		star.position = Vector2((i - 1) * 35.0 - 10.0, -15.0)
		stun_overlay.add_child(star)
		stun_stars.append(star)

func _build_controls_ui() -> void:
	right_panel = PanelContainer.new()
	right_panel.name = "ControlPanel"
	right_panel.position = Vector2(760.0, 20.0)
	right_panel.size = Vector2(490.0, 590.0)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.10, 0.14, 0.95)
	panel_style.border_color = Color(0.22, 0.28, 0.40, 0.90)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	right_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(right_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	right_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Header Title
	var title = Label.new()
	title.text = "STOCHAS ANIMATION STUDIO [DEBUG LAB]"
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color(0.4, 0.8, 1.0, 1.0)
	vbox.add_child(title)

	# Section 1: Animation States Grid
	var sec1 = Label.new()
	sec1.text = "ANIMATION STATES (11)"
	sec1.add_theme_font_size_override("font_size", 12)
	sec1.modulate = Color(0.8, 0.8, 0.9, 0.8)
	vbox.add_child(sec1)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid)

	for state in [
		AnimationState.IDLE, AnimationState.CAST_BOLT, AnimationState.CAST_ORB,
		AnimationState.CAST_RIFT, AnimationState.CAST_SWEEP, AnimationState.HIT,
		AnimationState.STUN, AnimationState.ENRAGED, AnimationState.ULTIMATE_CHARGE,
		AnimationState.ULTIMATE_RELEASE, AnimationState.ULTIMATE_FULL
	]:
		var btn = Button.new()
		btn.text = STATE_NAMES[state]
		btn.custom_minimum_size = Vector2(148, 30)
		btn.add_theme_font_size_override("font_size", 11)
		var s_capture = state
		btn.pressed.connect(func(): play_animation(s_capture))
		grid.add_child(btn)
		state_buttons[state] = btn

	# Section 2: Speed Controls
	var sec2 = Label.new()
	sec2.text = "PLAYBACK SPEED (0.10x – 2.00x) [Keys 1-5]"
	sec2.add_theme_font_size_override("font_size", 12)
	sec2.modulate = Color(0.8, 0.8, 0.9, 0.8)
	vbox.add_child(sec2)

	var speed_box = HBoxContainer.new()
	speed_box.add_theme_constant_override("separation", 6)
	vbox.add_child(speed_box)

	for spd in [0.10, 0.25, 0.50, 1.00, 2.00]:
		var spd_btn = Button.new()
		spd_btn.text = "%.2fx" % spd
		spd_btn.custom_minimum_size = Vector2(65, 26)
		spd_btn.add_theme_font_size_override("font_size", 11)
		var spd_val = spd
		spd_btn.pressed.connect(func(): set_playback_speed(spd_val))
		speed_box.add_child(spd_btn)

	var slider_row = HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 8)
	vbox.add_child(slider_row)

	speed_slider = HSlider.new()
	speed_slider.min_value = 0.10
	speed_slider.max_value = 2.00
	speed_slider.step = 0.05
	speed_slider.value = 1.00
	speed_slider.custom_minimum_size = Vector2(340, 24)
	speed_slider.value_changed.connect(func(val): set_playback_speed(val))
	slider_row.add_child(speed_slider)

	speed_label = Label.new()
	speed_label.text = "1.00x"
	speed_label.custom_minimum_size = Vector2(60, 24)
	speed_label.add_theme_font_size_override("font_size", 12)
	slider_row.add_child(speed_label)

	# Section 3: Transport & Stepping Controls
	var sec3 = Label.new()
	sec3.text = "TRANSPORT & FRAME STEPPING"
	sec3.add_theme_font_size_override("font_size", 12)
	sec3.modulate = Color(0.8, 0.8, 0.9, 0.8)
	vbox.add_child(sec3)

	var trans_row1 = HBoxContainer.new()
	trans_row1.add_theme_constant_override("separation", 8)
	vbox.add_child(trans_row1)

	btn_pause = Button.new()
	btn_pause.text = "PAUSE [Space]"
	btn_pause.custom_minimum_size = Vector2(130, 28)
	btn_pause.pressed.connect(toggle_pause)
	trans_row1.add_child(btn_pause)

	btn_loop = Button.new()
	btn_loop.text = "LOOP: OFF [L]"
	btn_loop.custom_minimum_size = Vector2(120, 28)
	btn_loop.pressed.connect(toggle_loop)
	trans_row1.add_child(btn_loop)

	btn_compare = Button.new()
	btn_compare.text = "COMPARE CASTS [V]"
	btn_compare.custom_minimum_size = Vector2(160, 28)
	btn_compare.pressed.connect(start_compare_casts)
	trans_row1.add_child(btn_compare)

	var trans_row2 = HBoxContainer.new()
	trans_row2.add_theme_constant_override("separation", 8)
	vbox.add_child(trans_row2)

	btn_prev_frame = Button.new()
	btn_prev_frame.text = "PREV FRAME [<-]"
	btn_prev_frame.custom_minimum_size = Vector2(130, 28)
	btn_prev_frame.pressed.connect(func(): step_frame(-1))
	trans_row2.add_child(btn_prev_frame)

	btn_next_frame = Button.new()
	btn_next_frame.text = "NEXT FRAME [->]"
	btn_next_frame.custom_minimum_size = Vector2(130, 28)
	btn_next_frame.pressed.connect(func(): step_frame(1))
	trans_row2.add_child(btn_next_frame)

	btn_motion_path = Button.new()
	btn_motion_path.text = "PATH: OFF [M]"
	btn_motion_path.custom_minimum_size = Vector2(120, 28)
	btn_motion_path.pressed.connect(toggle_motion_path)
	trans_row2.add_child(btn_motion_path)

	btn_reset_baseline = Button.new()
	btn_reset_baseline.text = "RESET BASELINE [R]"
	btn_reset_baseline.custom_minimum_size = Vector2(430, 30)
	btn_reset_baseline.pressed.connect(func():
		restore_canonical_baseline()
		play_animation(AnimationState.IDLE)
	)
	vbox.add_child(btn_reset_baseline)

func _build_diagnostic_ui() -> void:
	bottom_panel = PanelContainer.new()
	bottom_panel.name = "DiagnosticPanel"
	bottom_panel.position = Vector2(40.0, 625.0)
	bottom_panel.size = Vector2(1200.0, 85.0)

	var bg_box = StyleBoxFlat.new()
	bg_box.bg_color = Color(0.06, 0.07, 0.10, 0.95)
	bg_box.border_color = Color(0.25, 0.35, 0.50, 0.85)
	bg_box.border_width_left = 2
	bg_box.border_width_top = 2
	bg_box.border_width_right = 2
	bg_box.border_width_bottom = 2
	bg_box.corner_radius_top_left = 6
	bg_box.corner_radius_top_right = 6
	bg_box.corner_radius_bottom_left = 6
	bg_box.corner_radius_bottom_right = 6
	bottom_panel.add_theme_stylebox_override("panel", bg_box)
	add_child(bottom_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	bottom_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	lbl_diag_state = Label.new()
	lbl_diag_state.text = "STATE: IDLE | SPEED: 1.00x | FRAME: Canonical (stochas_boss.png) | ELAPSED: 0.00s / 3.20s"
	lbl_diag_state.add_theme_font_size_override("font_size", 13)
	lbl_diag_state.modulate = Color(0.3, 0.9, 1.0, 1.0)
	vbox.add_child(lbl_diag_state)

	lbl_diag_details = Label.new()
	lbl_diag_details.text = "POS: (180.0, 50.0) [d: +0.0, +0.0] | ROT: 0.0 deg | SCALE: (1.00, 1.00) | MOD: (1.0, 1.0, 1.0) | FLAGS: Loop: OFF | Paused: NO | Compare: NO"
	lbl_diag_details.add_theme_font_size_override("font_size", 12)
	lbl_diag_details.modulate = Color(0.75, 0.85, 0.95, 0.90)
	vbox.add_child(lbl_diag_details)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				toggle_pause()
			KEY_1:
				set_playback_speed(0.10)
			KEY_2:
				set_playback_speed(0.25)
			KEY_3:
				set_playback_speed(0.50)
			KEY_4:
				set_playback_speed(1.00)
			KEY_5:
				set_playback_speed(2.00)
			KEY_L:
				toggle_loop()
			KEY_V:
				start_compare_casts()
			KEY_M:
				toggle_motion_path()
			KEY_LEFT:
				step_frame(-1)
			KEY_RIGHT:
				step_frame(1)
			KEY_R:
				restore_canonical_baseline()
				play_animation(AnimationState.IDLE)

func _process(delta: float) -> void:
	if stun_overlay != null and stun_overlay.visible:
		var t = Time.get_ticks_msec() / 1000.0 * 4.0 * playback_speed
		for i in range(stun_stars.size()):
			var star = stun_stars[i]
			var angle = t + (i * TAU / 3.0)
			star.position = Vector2(cos(angle) * 35.0 - 10.0, sin(angle) * 10.0 - 15.0)

	if is_compare_casts_active and not is_paused:
		compare_timer -= delta * playback_speed
		if compare_timer <= 0.0:
			_advance_compare_cast()

	if not is_paused and active_tween != null and active_tween.is_valid():
		elapsed_time += delta * playback_speed
		if motion_path_enabled and boss_rect != null:
			var pt = boss_rect.position + boss_rect.pivot_offset
			if motion_trail_points.is_empty() or motion_trail_points.back().distance_to(pt) > 3.0:
				motion_trail_points.append(pt)
				if motion_trail_points.size() > MAX_MOTION_POINTS:
					motion_trail_points.pop_front()
				if motion_path_line != null:
					motion_path_line.points = PackedVector2Array(motion_trail_points)

	_update_diagnostic_labels()

func _update_diagnostic_labels() -> void:
	if lbl_diag_state == null or lbl_diag_details == null or boss_rect == null:
		return

	var frame_desc: String = get_frame_display_text()

	lbl_diag_state.text = "STATE: %s | SPEED: %.2fx | FRAME: %s | ELAPSED: %.2fs / %.2fs" % [
		STATE_NAMES[current_state],
		playback_speed,
		frame_desc,
		minf(elapsed_time, state_duration),
		state_duration
	]

	var delta_pos: Vector2 = boss_rect.position - BOSS_BASE_POS
	lbl_diag_details.text = "POS: (%.1f, %.1f) [d: %+.1f, %+.1f] | ROT: %+.1f deg | SCALE: (%.2f, %.2f) | MOD: (%.1f, %.1f, %.1f) | FLAGS: Loop: %s | Paused: %s | Compare: %s" % [
		boss_rect.position.x,
		boss_rect.position.y,
		delta_pos.x,
		delta_pos.y,
		boss_rect.rotation_degrees,
		boss_rect.scale.x,
		boss_rect.scale.y,
		boss_rect.modulate.r,
		boss_rect.modulate.g,
		boss_rect.modulate.b,
		"ON" if is_loop_enabled else "OFF",
		"YES" if is_paused else "NO",
		"YES" if is_compare_casts_active else "NO"
	]

# ==============================================================================
# ANIMATION CONTROLLER
# ==============================================================================

func play_animation(state: AnimationState) -> void:
	current_state = state
	elapsed_time = 0.0
	state_duration = STATE_DURATIONS.get(state, 1.0)
	_clear_transient_vfx()

	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	# Highlight current button
	for s in state_buttons:
		if state_buttons[s] != null:
			state_buttons[s].modulate = Color(1.3, 1.2, 0.4) if s == state else Color.WHITE

	match state:
		AnimationState.IDLE:
			_play_idle()
		AnimationState.CAST_BOLT:
			_play_cast_bolt()
		AnimationState.CAST_ORB:
			_play_cast_orb()
		AnimationState.CAST_RIFT:
			_play_cast_rift()
		AnimationState.CAST_SWEEP:
			_play_cast_sweep()
		AnimationState.HIT:
			_play_hit()
		AnimationState.STUN:
			_play_stun()
		AnimationState.ENRAGED:
			_play_enraged()
		AnimationState.ULTIMATE_CHARGE:
			_play_ultimate_charge()
		AnimationState.ULTIMATE_RELEASE:
			_play_ultimate_release()
		AnimationState.ULTIMATE_FULL:
			_play_ultimate_full()

	if active_tween != null and active_tween.is_valid():
		active_tween.set_speed_scale(playback_speed)
		if is_paused:
			active_tween.pause()

func _play_idle() -> void:
	restore_canonical_baseline()
	state_duration = 3.20

	active_tween = create_tween().set_loops()
	var half_dur: float = 1.60
	active_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y - 6.0, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2(1.008, 0.995), half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_cast_bolt() -> void:
	restore_canonical_baseline()
	var prof = SPELL_PROFILES[AnimationState.CAST_BOLT]
	state_duration = prof["duration"]

	active_tween = create_tween()
	# Anticipation backward (+16px, -1.5 deg)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["anticipation_offset"], prof["anticipation_time"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["anticipation_rotation"], prof["anticipation_time"])

	# Rapid forward snap (-32px, +2.5 deg) + cyan flare
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["snap_offset"], prof["snap_time"]).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["snap_rotation"], prof["snap_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.2, 1.8, 2.2), prof["snap_time"])
	active_tween.parallel().tween_callback(Callable(self, "_spawn_bolt_vfx"))

	# Recoil back to baseline
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, prof["recoil_time"]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, prof["recoil_time"])

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_cast_orb() -> void:
	restore_canonical_baseline()
	var prof = SPELL_PROFILES[AnimationState.CAST_ORB]
	state_duration = prof["duration"]

	active_tween = create_tween()
	# Float upward (-26px Y, -2.5 deg) + scale expansion
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["float_offset"], prof["float_time"]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["float_rotation"], prof["float_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", prof["peak_scale"], prof["float_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.3, 1.3, 1.0), prof["float_time"])
	active_tween.parallel().tween_callback(Callable(self, "_spawn_orb_vfx"))

	# Controlled forward release (+10px X, -10px Y)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["release_offset"], prof["release_time"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["release_rotation"], prof["release_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2(1.02, 1.02), prof["release_time"])

	# Settle back to baseline
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, prof["recoil_time"]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, prof["recoil_time"])

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_cast_rift() -> void:
	restore_canonical_baseline()
	var prof = SPELL_PROFILES[AnimationState.CAST_RIFT]
	state_duration = prof["duration"]

	active_tween = create_tween()
	# Heavy summon windup & sink (+22px X, +20px Y, +3.8 deg)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["sink_offset"], prof["windup_time"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["sink_rotation"], prof["windup_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(0.85, 0.70, 1.15), prof["windup_time"])

	# Held pose for 0.40s while rift opens
	active_tween.tween_callback(Callable(self, "_spawn_rift_vfx"))
	active_tween.tween_interval(prof["hold_duration"])

	# Settle back to baseline
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, prof["recoil_time"]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, prof["recoil_time"])

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_cast_sweep() -> void:
	restore_canonical_baseline()
	var prof = SPELL_PROFILES[AnimationState.CAST_SWEEP]
	state_duration = prof["duration"]

	active_tween = create_tween()
	# Strong windup (+40px X, -5px Y, -6.2 deg)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["windup_offset"], prof["windup_time"]).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["windup_rotation"], prof["windup_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", prof["windup_scale"], prof["windup_time"])

	# Massive lateral sweep across (-45px X, +5px Y, +5.5 deg)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + prof["sweep_offset"], prof["sweep_time"]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", prof["sweep_rotation"], prof["sweep_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", prof["sweep_scale"], prof["sweep_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.35, 1.10, 1.70), prof["sweep_time"])
	active_tween.parallel().tween_callback(Callable(self, "_spawn_sweep_vfx"))

	# Settle back to baseline
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, prof["recoil_time"]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, prof["recoil_time"])
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, prof["recoil_time"])

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_hit() -> void:
	restore_canonical_baseline()
	state_duration = STATE_DURATIONS[AnimationState.HIT]

	active_tween = create_tween()
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(18.0, -8.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", -3.0, 0.15)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(2.2, 0.6, 0.6), 0.15)

	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, 0.20)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, 0.20)

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_stun() -> void:
	restore_canonical_baseline()
	state_duration = STATE_DURATIONS[AnimationState.STUN]

	active_tween = create_tween()
	# Slump forward and stay
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS + Vector2(-15.0, 15.0), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", -4.5, 0.30)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(0.70, 0.70, 0.90), 0.30)
	active_tween.parallel().tween_callback(func():
		if stun_overlay != null:
			stun_overlay.visible = true
	)

func _play_enraged() -> void:
	restore_canonical_baseline()
	state_duration = STATE_DURATIONS[AnimationState.ENRAGED]
	boss_rect.modulate = Color(1.35, 0.85, 0.85)

	active_tween = create_tween().set_loops()
	var half_dur: float = 0.90
	active_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y - 10.0, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2(1.03, 0.97), half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_ultimate_charge() -> void:
	restore_canonical_baseline()
	state_duration = STATE_DURATIONS[AnimationState.ULTIMATE_CHARGE] # 2.40s
	_set_charge_frame(0)

	active_tween = create_tween()

	# WAD2 Human-Approved 6 Independent Charge Frames (F01 -> F02 -> F03 -> F04 -> F05 -> F06)
	# Total duration 2.40s deterministic distribution: 0.40s per frame (6 * 0.40s = 2.40s)

	# F01 (0.00s - 0.40s): Initiate rise & dim overlay
	active_tween.tween_callback(func(): _set_charge_frame(0))
	active_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y - 20.0, 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(dim_overlay, "modulate:a", 0.45, 0.40)

	# F02 (0.40s - 0.80s)
	active_tween.tween_callback(func(): _set_charge_frame(1))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.04, 1.04), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# F03 (0.80s - 1.20s)
	active_tween.tween_callback(func(): _set_charge_frame(2))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.07, 1.07), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.30, 1.20, 1.60), 0.40)

	# F04 (1.20s - 1.60s)
	active_tween.tween_callback(func(): _set_charge_frame(3))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.10, 1.10), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.50, 1.40, 1.80), 0.40)

	# F05 (1.60s - 2.00s)
	active_tween.tween_callback(func(): _set_charge_frame(4))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.12, 1.12), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.70, 1.50, 2.00), 0.40)

	# F06 (2.00s - 2.40s): Peak charge hold
	active_tween.tween_callback(func(): _set_charge_frame(5))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.10, 1.10), 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.80, 1.60, 2.20), 0.40)

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_ultimate_release() -> void:
	state_duration = STATE_DURATIONS[AnimationState.ULTIMATE_RELEASE]

	active_tween = create_tween()
	# Frame 4: Anticipation hold (0.12s)
	active_tween.tween_callback(func(): _set_atlas_frame(4))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.08, 1.08), 0.12)

	# Frame 5: Discharge flash (0.15s)
	active_tween.tween_callback(func(): _set_atlas_frame(5))
	active_tween.tween_property(boss_rect, "modulate", Color(2.5, 2.5, 3.0), 0.15)

	# Frame 6: Peak impact (0.25s)
	active_tween.tween_callback(func():
		_set_atlas_frame(6)
		_spawn_sweep_vfx()
	)
	active_tween.tween_property(boss_rect, "modulate", Color(1.8, 1.4, 2.2), 0.25)

	# Frame 7: Follow-through (0.20s)
	active_tween.tween_callback(func(): _set_atlas_frame(7))
	active_tween.tween_interval(0.20)

	# Recovery Phase (0.30s) -> Restores canonical boss texture & baseline
	active_tween.tween_callback(func():
		_set_canonical_boss()
	)
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, 0.30)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, 0.30)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, 0.30)
	active_tween.parallel().tween_property(dim_overlay, "modulate:a", 0.0, 0.30)

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _play_ultimate_full() -> void:
	restore_canonical_baseline()
	state_duration = STATE_DURATIONS[AnimationState.ULTIMATE_FULL] # 3.42s
	_set_charge_frame(0)

	active_tween = create_tween()

	# 1. Charge Phase (2.40s) using 6 independent frames (F01 -> F06)
	active_tween.tween_callback(func(): _set_charge_frame(0))
	active_tween.tween_property(boss_rect, "position:y", BOSS_BASE_POS.y - 20.0, 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(dim_overlay, "modulate:a", 0.45, 0.40)

	active_tween.tween_callback(func(): _set_charge_frame(1))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.04, 1.04), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	active_tween.tween_callback(func(): _set_charge_frame(2))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.07, 1.07), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.30, 1.20, 1.60), 0.40)

	active_tween.tween_callback(func(): _set_charge_frame(3))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.10, 1.10), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.50, 1.40, 1.80), 0.40)

	active_tween.tween_callback(func(): _set_charge_frame(4))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.12, 1.12), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.70, 1.50, 2.00), 0.40)

	active_tween.tween_callback(func(): _set_charge_frame(5))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.10, 1.10), 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color(1.80, 1.60, 2.20), 0.40)

	# 2. Release Phase (0.72s)
	active_tween.tween_callback(func(): _set_atlas_frame(4))
	active_tween.tween_property(boss_rect, "scale", Vector2(1.08, 1.08), 0.12)

	active_tween.tween_callback(func(): _set_atlas_frame(5))
	active_tween.tween_property(boss_rect, "modulate", Color(2.5, 2.5, 3.0), 0.15)

	active_tween.tween_callback(func():
		_set_atlas_frame(6)
		_spawn_sweep_vfx()
	)
	active_tween.tween_property(boss_rect, "modulate", Color(1.8, 1.4, 2.2), 0.25)

	active_tween.tween_callback(func(): _set_atlas_frame(7))
	active_tween.tween_interval(0.20)

	# 3. Recovery Phase (0.30s)
	active_tween.tween_callback(func(): _set_canonical_boss())
	active_tween.tween_property(boss_rect, "position", BOSS_BASE_POS, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	active_tween.parallel().tween_property(boss_rect, "rotation_degrees", 0.0, 0.30)
	active_tween.parallel().tween_property(boss_rect, "scale", Vector2.ONE, 0.30)
	active_tween.parallel().tween_property(boss_rect, "modulate", Color.WHITE, 0.30)
	active_tween.parallel().tween_property(dim_overlay, "modulate:a", 0.0, 0.30)

	active_tween.tween_callback(Callable(self, "_on_animation_finished"))

func _on_animation_finished() -> void:
	if is_compare_casts_active:
		# Wait 0.5s before next compare cast
		compare_timer = 0.50
		return

	if is_loop_enabled:
		play_animation(current_state)
	else:
		if current_state == AnimationState.ULTIMATE_CHARGE:
			# Hold on F06 / remain in ULTIMATE_CHARGE without auto-transitioning
			current_charge_frame = 5
			_set_charge_frame(5)
			elapsed_time = state_duration
		else:
			restore_canonical_baseline()
			play_animation(AnimationState.IDLE)

# ==============================================================================
# SPEED & TRANSPORT CONTROLS
# ==============================================================================

func set_playback_speed(speed: float) -> void:
	playback_speed = clampf(speed, 0.10, 2.00)
	if speed_slider != null and not is_equal_approx(speed_slider.value, playback_speed):
		speed_slider.value = playback_speed
	if speed_label != null:
		speed_label.text = "%.2fx" % playback_speed
	if active_tween != null and active_tween.is_valid():
		active_tween.set_speed_scale(playback_speed)

func get_playback_speed() -> float:
	return playback_speed

func toggle_pause() -> void:
	set_paused(not is_paused)

func set_paused(paused: bool) -> void:
	is_paused = paused
	if btn_pause != null:
		btn_pause.text = "RESUME [Space]" if is_paused else "PAUSE [Space]"
		btn_pause.modulate = Color(1.3, 0.8, 0.3) if is_paused else Color.WHITE
	if active_tween != null and active_tween.is_valid():
		if is_paused:
			active_tween.pause()
		else:
			active_tween.play()

func is_paused_active() -> bool:
	return is_paused

func toggle_loop() -> void:
	set_loop(not is_loop_enabled)

func set_loop(enabled: bool) -> void:
	is_loop_enabled = enabled
	if btn_loop != null:
		btn_loop.text = "LOOP: ON [L]" if is_loop_enabled else "LOOP: OFF [L]"
		btn_loop.modulate = Color(0.4, 1.2, 0.4) if is_loop_enabled else Color.WHITE

func is_loop_active() -> bool:
	return is_loop_enabled

func step_frame(direction: int) -> void:
	# Stop active playback to inspect static frames
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	if current_state == AnimationState.ULTIMATE_CHARGE or current_charge_frame >= 0:
		if current_charge_frame < 0:
			current_charge_frame = 0 if direction >= 0 else 5
		else:
			var next_f: int = current_charge_frame + direction
			if next_f > 5:
				current_charge_frame = 0 if is_loop_enabled else 5
			elif next_f < 0:
				current_charge_frame = 5 if is_loop_enabled else 0
			else:
				current_charge_frame = next_f
		_set_charge_frame(current_charge_frame)
	else:
		if current_atlas_frame < 0:
			current_atlas_frame = 0 if direction >= 0 else 7
		else:
			var next_a: int = current_atlas_frame + direction
			if next_a > 7:
				current_atlas_frame = 0 if is_loop_enabled else 7
			elif next_a < 0:
				current_atlas_frame = 7 if is_loop_enabled else 0
			else:
				current_atlas_frame = next_a
		_set_atlas_frame(current_atlas_frame)

func get_current_atlas_frame() -> int:
	return current_atlas_frame

func get_current_charge_frame() -> int:
	return current_charge_frame

func get_frame_display_text() -> String:
	if current_charge_frame >= 0 and current_charge_frame < stochas_ultimate_charge_frames.size():
		return "Charge Frame %d / 6 (F0%d)" % [current_charge_frame + 1, current_charge_frame + 1]
	if current_atlas_frame >= 0 and current_atlas_frame < stochas_ultimate_frames.size():
		return "Release Atlas Frame %d / 8" % (current_atlas_frame + 1)
	return "Canonical (stochas_boss.png)"

func toggle_motion_path() -> void:
	motion_path_enabled = not motion_path_enabled
	if btn_motion_path != null:
		btn_motion_path.text = "PATH: ON [M]" if motion_path_enabled else "PATH: OFF [M]"
		btn_motion_path.modulate = Color(0.3, 1.0, 1.0) if motion_path_enabled else Color.WHITE
	if motion_path_line != null:
		motion_path_line.visible = motion_path_enabled
		if not motion_path_enabled:
			motion_trail_points.clear()
			motion_path_line.points = PackedVector2Array()

func is_motion_path_active() -> bool:
	return motion_path_enabled

func start_compare_casts() -> void:
	is_compare_casts_active = true
	compare_step_idx = 0
	compare_timer = 0.0
	if btn_compare != null:
		btn_compare.modulate = Color(1.3, 1.1, 0.3)
	_play_next_compare_cast()

func is_compare_casts_running() -> bool:
	return is_compare_casts_active

func _play_next_compare_cast() -> void:
	if compare_step_idx < compare_sequence.size():
		var next_state = compare_sequence[compare_step_idx]
		play_animation(next_state)
	else:
		# Sequence completed
		is_compare_casts_active = false
		if btn_compare != null:
			btn_compare.modulate = Color.WHITE
		restore_canonical_baseline()
		play_animation(AnimationState.IDLE)

func _advance_compare_cast() -> void:
	compare_step_idx += 1
	_play_next_compare_cast()

# ==============================================================================
# BASELINE & FRAME HELPERS
# ==============================================================================

func restore_canonical_baseline() -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	if boss_rect != null:
		boss_rect.position = BOSS_BASE_POS
		boss_rect.rotation = 0.0
		boss_rect.scale = Vector2.ONE
		boss_rect.modulate = Color.WHITE
		_set_canonical_boss()

	if dim_overlay != null:
		dim_overlay.modulate.a = 0.0
	if stun_overlay != null:
		stun_overlay.visible = false

	_clear_transient_vfx()

func _set_canonical_boss() -> void:
	current_atlas_frame = -1
	current_charge_frame = -1
	if boss_rect != null and canonical_boss_tex != null:
		boss_rect.texture = canonical_boss_tex

func _set_charge_frame(idx: int) -> void:
	current_charge_frame = idx
	current_atlas_frame = -1
	if boss_rect != null and idx >= 0 and idx < stochas_ultimate_charge_frames.size():
		boss_rect.texture = stochas_ultimate_charge_frames[idx]

func _set_atlas_frame(idx: int) -> void:
	current_atlas_frame = idx
	current_charge_frame = -1
	if boss_rect != null and idx >= 0 and idx < stochas_ultimate_frames.size():
		boss_rect.texture = stochas_ultimate_frames[idx]

func _clear_transient_vfx() -> void:
	if boss_vfx_container != null:
		for child in boss_vfx_container.get_children():
			child.queue_free()

func _spawn_bolt_vfx() -> void:
	if vfx_bolt_tex == null or boss_vfx_container == null:
		return
	var bolt = TextureRect.new()
	bolt.texture = vfx_bolt_tex
	bolt.size = Vector2(160, 80)
	bolt.position = Vector2(50.0, 240.0)
	bolt.modulate = Color(1.3, 1.8, 2.4, 0.95)
	boss_vfx_container.add_child(bolt)

	var t = create_tween()
	t.set_speed_scale(playback_speed)
	t.tween_property(bolt, "position:x", -280.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(bolt, "modulate:a", 0.0, 0.25)
	t.tween_callback(bolt.queue_free)

func _spawn_orb_vfx() -> void:
	if vfx_orb_tex == null or boss_vfx_container == null:
		return
	var orb = TextureRect.new()
	orb.texture = vfx_orb_tex
	orb.size = Vector2(120, 120)
	orb.position = Vector2(200.0, 150.0)
	orb.modulate = Color(1.4, 1.4, 0.9, 0.95)
	boss_vfx_container.add_child(orb)

	var t = create_tween()
	t.set_speed_scale(playback_speed)
	t.tween_property(orb, "position", Vector2(-150.0, 180.0), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(orb, "scale", Vector2(1.3, 1.3), 0.45)
	t.parallel().tween_property(orb, "modulate:a", 0.0, 0.45)
	t.tween_callback(orb.queue_free)

func _spawn_rift_vfx() -> void:
	if vfx_rift_tex == null or boss_vfx_container == null:
		return
	var rift = TextureRect.new()
	rift.texture = vfx_rift_tex
	rift.size = Vector2(200, 160)
	rift.position = Vector2(-80.0, 360.0)
	rift.modulate = Color(1.2, 0.8, 2.0, 0.0)
	boss_vfx_container.add_child(rift)

	var t = create_tween()
	t.set_speed_scale(playback_speed)
	t.tween_property(rift, "modulate:a", 0.90, 0.20)
	t.tween_interval(0.40)
	t.tween_property(rift, "modulate:a", 0.0, 0.25)
	t.tween_callback(rift.queue_free)

func _spawn_sweep_vfx() -> void:
	if vfx_sweep_tex == null or boss_vfx_container == null:
		return
	var sweep = TextureRect.new()
	sweep.texture = vfx_sweep_tex
	sweep.size = Vector2(380, 220)
	sweep.position = Vector2(-220.0, 180.0)
	sweep.modulate = Color(1.4, 1.0, 2.2, 0.95)
	sweep.scale = Vector2(0.5, 0.5)
	sweep.pivot_offset = Vector2(190.0, 110.0)
	boss_vfx_container.add_child(sweep)

	var t = create_tween()
	t.set_speed_scale(playback_speed)
	t.tween_property(sweep, "scale", Vector2(1.2, 1.2), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(sweep, "rotation_degrees", 25.0, 0.30)
	t.parallel().tween_property(sweep, "modulate:a", 0.0, 0.30)
	t.tween_callback(sweep.queue_free)

# ==============================================================================
# PUBLIC GETTERS FOR HEADLESS TESTING & VERIFICATION
# ==============================================================================

func get_current_state() -> AnimationState:
	return current_state

func get_current_state_name() -> String:
	return STATE_NAMES.get(current_state, "UNKNOWN")

func get_boss_base_position() -> Vector2:
	return BOSS_BASE_POS

func get_boss_position() -> Vector2:
	return boss_rect.position if boss_rect != null else BOSS_BASE_POS

func get_boss_rotation() -> float:
	return boss_rect.rotation_degrees if boss_rect != null else 0.0

func get_boss_scale() -> Vector2:
	return boss_rect.scale if boss_rect != null else Vector2.ONE

func get_boss_modulate() -> Color:
	return boss_rect.modulate if boss_rect != null else Color.WHITE

func get_boss_texture() -> Texture2D:
	return boss_rect.texture if boss_rect != null else null

func get_boss_size() -> Vector2:
	return boss_rect.size if boss_rect != null else BOSS_BASE_SIZE

func get_baseline_y() -> float:
	return BASELINE_Y

func get_spell_profile(state: AnimationState) -> Dictionary:
	return SPELL_PROFILES.get(state, {})

func get_animation_duration(state: AnimationState) -> float:
	return STATE_DURATIONS.get(state, 0.0)

func get_diagnostic_text() -> String:
	var t1 = lbl_diag_state.text if lbl_diag_state != null else ""
	var t2 = lbl_diag_details.text if lbl_diag_details != null else ""
	return t1 + "\n" + t2

func get_ultimate_frames() -> Array[AtlasTexture]:
	return stochas_ultimate_frames

func get_ultimate_charge_frames() -> Array[Texture2D]:
	return stochas_ultimate_charge_frames
