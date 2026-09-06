class_name ProloguePlayer
extends Control

## Production Prologue Player for Mathos (TASK-073).
## Plays the human-accepted Beat 1 ("MATHOS WORLD") and Beat 2 ("THE CALAMITY").
## Exactly 3 player controls: Volume, Settings, BỎ QUA.
## Zero Lab tools or debug gizmos exposed.
## Supports responsive multi-resolution scaling, projectile transform separation (Root/Visual),
## and zero clipping across 1280x720, 1366x768, 1600x900, 1920x1080.

signal prologue_completed()
signal prologue_skipped()
signal beat_transitioned(from_beat: int, to_beat: int)
signal volume_pressed()
signal settings_pressed()

# Canvas Dimensions
const CANVAS_WIDTH: float = 1280.0
const CANVAS_HEIGHT: float = 720.0
const BEAT1_DURATION: float = 9.0
const BEAT2_DURATION: float = 9.5
const CROSSFADE_DURATION: float = 0.6

# Authoritative Production Layout Paths (Inside project res://)
const BEAT01_LAYOUT_RES_PATH: String = "res://assets/prologue/beat_01/layout/prologue_lab_beat01_layout_human_accepted.json"
const BEAT02_LAYOUT_RES_PATH: String = "res://assets/prologue/beat_02/layout/prologue_lab_beat02_layout_human_tuned.json"

# State
var _current_beat: int = 0 # 1 or 2 (0 = stopped)
var _playback_time: float = 0.0
var _is_transitioning: bool = false
var _is_completed: bool = false
var _speed_scale: float = 1.0 # For fast testing

# Beat Containers
var _canvas_container: Control = null
var _beat01_root: Control = null
var _beat02_root: Control = null

# Controls (Exactly 3)
var _controls_node: Control = null
var _volume_btn: Button = null
var _settings_btn: Button = null
var _skip_btn: Button = null

# Beat 1 Layers & Runtime Data
var _b1_layers: Dictionary = {} # name -> Control/TextureRect
var _b1_layout_data: Dictionary = {}

# Beat 2 Layers & Runtime Data
var _b2_layers: Dictionary = {} # name -> Control/TextureRect
var _b2_visual_nodes: Dictionary = {} # name -> TextureRect
var _b2_layout_data: Dictionary = {}
var _b2_projectile_state: Dictionary = {} # name -> {current_dist: float, travel_dist: float, speed: float, loop: bool, fade: bool, start_offset: float}

# Narration Nodes
var _b1_narration: Control = null
var _b1_title_lbl: Label = null
var _b1_body_lbl: Label = null

var _b2_narration: Control = null
var _b2_phrase1_lbl: Label = null
var _b2_phrase2_lbl: RichTextLabel = null

func _ready() -> void:
	_ensure_built()

func _ensure_built() -> void:
	if _canvas_container != null:
		return

	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(CANVAS_WIDTH, CANVAS_HEIGHT)
	if get_parent() != null:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 1. Canvas Container (maintains 1280x720 centered/scaled)
	_canvas_container = Control.new()
	_canvas_container.name = "CanvasContainer"
	_canvas_container.custom_minimum_size = Vector2(CANVAS_WIDTH, CANVAS_HEIGHT)
	_canvas_container.size = Vector2(CANVAS_WIDTH, CANVAS_HEIGHT)
	_canvas_container.clip_contents = false
	_canvas_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas_container)

	# 2. Build Beat 1 & Beat 2 Subtrees
	_build_beat01_structure()
	_build_beat02_structure()

	# 3. Build Player Controls (Exactly 3 controls, top level overlay)
	_build_controls_structure()

	# 4. Load Authoritative Layouts
	load_beat01_layout()
	load_beat02_layout()

	_update_responsive_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_responsive_layout()

func update_responsive_layout(target_size: Vector2 = Vector2.ZERO) -> void:
	if _canvas_container == null:
		return

	var vp_size: Vector2 = target_size if (target_size.x > 0.0 and target_size.y > 0.0) else size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		vp_size = Vector2(CANVAS_WIDTH, CANVAS_HEIGHT)

	var scale_x: float = vp_size.x / CANVAS_WIDTH
	var scale_y: float = vp_size.y / CANVAS_HEIGHT
	var fit_scale: float = minf(scale_x, scale_y)

	_canvas_container.scale = Vector2(fit_scale, fit_scale)
	var scaled_w: float = CANVAS_WIDTH * fit_scale
	var scaled_h: float = CANVAS_HEIGHT * fit_scale
	_canvas_container.position = Vector2((vp_size.x - scaled_w) * 0.5, (vp_size.y - scaled_h) * 0.5)

func _update_responsive_layout() -> void:
	update_responsive_layout()


# =========================================================================
# CONTROLS BUILDER (EXACTLY 3 PLAYER CONTROLS)
# =========================================================================

func _build_controls_structure() -> void:
	_controls_node = Control.new()
	_controls_node.name = "PlayerControls"
	_controls_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_controls_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_node.clip_contents = false
	add_child(_controls_node)

	# Top-right container for Volume and Settings
	var top_right_hbox: HBoxContainer = HBoxContainer.new()
	top_right_hbox.name = "TopRightHBox"
	top_right_hbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right_hbox.offset_left = -110.0
	top_right_hbox.offset_top = 20.0
	top_right_hbox.offset_right = -24.0
	top_right_hbox.offset_bottom = 60.0
	top_right_hbox.add_theme_constant_override("separation", 10)
	top_right_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_node.add_child(top_right_hbox)

	# 1. Volume Button
	_volume_btn = Button.new()
	_volume_btn.name = "VolumeBtn"
	_volume_btn.text = "🔊"
	_volume_btn.tooltip_text = "Âm lượng"
	_volume_btn.custom_minimum_size = Vector2(38, 36)
	_volume_btn.pressed.connect(func(): volume_pressed.emit())
	top_right_hbox.add_child(_volume_btn)

	# 2. Settings Button
	_settings_btn = Button.new()
	_settings_btn.name = "SettingsBtn"
	_settings_btn.text = "⚙"
	_settings_btn.tooltip_text = "Cài đặt"
	_settings_btn.custom_minimum_size = Vector2(38, 36)
	_settings_btn.pressed.connect(func(): settings_pressed.emit())
	top_right_hbox.add_child(_settings_btn)

	# 3. Skip Button (Bottom-Right)
	_skip_btn = Button.new()
	_skip_btn.name = "SkipBtn"
	_skip_btn.text = "BỎ QUA >>"
	_skip_btn.tooltip_text = "Bỏ qua đoạn dẫn nhập"
	_skip_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_btn.offset_left = -140.0
	_skip_btn.offset_top = -60.0
	_skip_btn.offset_right = -24.0
	_skip_btn.offset_bottom = -20.0
	_skip_btn.custom_minimum_size = Vector2(116, 40)
	_skip_btn.pressed.connect(_on_skip_pressed)
	_controls_node.add_child(_skip_btn)

func get_player_controls() -> Array[Button]:
	_ensure_built()
	var arr: Array[Button] = []
	if _volume_btn != null: arr.append(_volume_btn)
	if _settings_btn != null: arr.append(_settings_btn)
	if _skip_btn != null: arr.append(_skip_btn)
	return arr

# =========================================================================
# BEAT 1 STRUCTURE BUILDER (14 LAYERS)
# =========================================================================

func _build_beat01_structure() -> void:
	_beat01_root = Control.new()
	_beat01_root.name = "Beat01Root"
	_beat01_root.custom_minimum_size = Vector2(CANVAS_WIDTH, CANVAS_HEIGHT)
	_beat01_root.size = Vector2(CANVAS_WIDTH, CANVAS_HEIGHT)
	_beat01_root.clip_contents = false
	_beat01_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_container.add_child(_beat01_root)

	var b1_layer_specs: Array[Dictionary] = [
		{"name": "Background", "path": "res://assets/prologue/beat_01/prologue_bg_01_mathos_world.png", "sz": Vector2(1340, 760)},
		{"name": "MistFar", "path": "res://assets/prologue/beat_01/ambient/mist/beat01_mist_01.png", "sz": Vector2(1440, 480)},
		{"name": "Birds", "path": "res://assets/prologue/beat_01/ambient/birds/beat01_birds_far_01.png", "sz": Vector2(340, 113)},
		{"name": "FlyingCreatures", "path": "res://assets/prologue/beat_01/ambient/creatures/beat01_flying_creatures_far_v2_01.png", "sz": Vector2(280, 157)},
		{"name": "GoldFlicker01", "path": "res://assets/prologue/beat_01/ambient/lights/beat01_gold_flicker_01.png", "sz": Vector2(90, 90)},
		{"name": "GoldFlicker02", "path": "res://assets/prologue/beat_01/ambient/lights/beat01_gold_flicker_02.png", "sz": Vector2(75, 75)},
		{"name": "GoldFlicker03", "path": "res://assets/prologue/beat_01/ambient/lights/beat01_gold_flicker_03.png", "sz": Vector2(65, 65)},
		{"name": "ArcaneTrails", "path": "res://assets/prologue/beat_01/ambient/trails/beat01_arcane_trails.png", "sz": Vector2(700, 394)},
		{"name": "RunePrimary", "path": "res://assets/prologue/beat_01/ambient/runes/beat01_rune_pulse.png", "sz": Vector2(220, 220)},
		{"name": "MistNear", "path": "res://assets/prologue/beat_01/ambient/mist/beat01_mist_02.png", "sz": Vector2(1500, 400)},
		{"name": "CyanMotes", "path": "res://assets/prologue/beat_01/ambient/particles/beat01_cyan_motes.png", "sz": Vector2(1280, 720)},
		{"name": "FoliageLeft", "path": "res://assets/prologue/beat_01/ambient/foliage/beat01_foliage_left.png", "sz": Vector2(400, 740)},
		{"name": "FoliageRight", "path": "res://assets/prologue/beat_01/ambient/foliage/beat01_foliage_right.png", "sz": Vector2(460, 720)},
		{"name": "FoliageTop", "path": "res://assets/prologue/beat_01/ambient/foliage/beat01_foliage_top.png", "sz": Vector2(1340, 280)}
	]

	for spec in b1_layer_specs:
		var l_name: String = spec["name"]
		var tex_rect: TextureRect = TextureRect.new()
		tex_rect.name = l_name
		tex_rect.size = spec["sz"]
		tex_rect.pivot_offset = spec["sz"] * 0.5
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex_rect.texture = _load_texture_safely(spec["path"])
		_beat01_root.add_child(tex_rect)
		_b1_layers[l_name] = tex_rect

	# Bottom cinematic dark gradient overlay for text readability
	var b1_gradient: ColorRect = ColorRect.new()
	b1_gradient.name = "CinematicGradient"
	b1_gradient.set_anchors_preset(Control.PRESET_FULL_RECT)
	b1_gradient.color = Color(0.0, 0.0, 0.0, 0.45)
	b1_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beat01_root.add_child(b1_gradient)

	# Beat 1 Narration UI
	_b1_narration = Control.new()
	_b1_narration.name = "NarrationContainer"
	_b1_narration.set_anchors_preset(Control.PRESET_FULL_RECT)
	_b1_narration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beat01_root.add_child(_b1_narration)

	var b1_vbox: VBoxContainer = VBoxContainer.new()
	b1_vbox.name = "NarrationVBox"
	b1_vbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	b1_vbox.offset_top = -180.0
	b1_vbox.offset_bottom = -30.0
	b1_vbox.offset_left = 60.0
	b1_vbox.offset_right = -60.0
	b1_vbox.add_theme_constant_override("separation", 10)
	b1_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_b1_narration.add_child(b1_vbox)

	_b1_title_lbl = Label.new()
	_b1_title_lbl.name = "TitleLabel"
	_b1_title_lbl.text = "MATHOS"
	_b1_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_b1_title_lbl.add_theme_color_override("font_color", Color(0.96, 0.82, 0.38, 1.0)) # Gold
	_b1_title_lbl.add_theme_font_size_override("font_size", 28)
	b1_vbox.add_child(_b1_title_lbl)

	_b1_body_lbl = Label.new()
	_b1_body_lbl.name = "BodyLabel"
	_b1_body_lbl.text = "Tại một thế giới nơi tri thức và ma thuật cùng tồn tại,\nMathos từng được giữ cân bằng bởi một nguồn sức mạnh cổ xưa —\nViên Đá Trật Tự."
	_b1_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_b1_body_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 0.95))
	_b1_body_lbl.add_theme_font_size_override("font_size", 18)
	b1_vbox.add_child(_b1_body_lbl)

# =========================================================================
# BEAT 2 STRUCTURE BUILDER (20 LAYERS + PROJECTILE ROOT/VISUAL)
# =========================================================================

func _build_beat02_structure() -> void:
	_beat02_root = Control.new()
	_beat02_root.name = "Beat02Root"
	_beat02_root.custom_minimum_size = Vector2(CANVAS_WIDTH, CANVAS_HEIGHT)
	_beat02_root.size = Vector2(CANVAS_WIDTH, CANVAS_HEIGHT)
	_beat02_root.clip_contents = false
	_beat02_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beat02_root.modulate.a = 0.0
	_beat02_root.visible = false
	_canvas_container.add_child(_beat02_root)

	var b2_specs: Array[Dictionary] = [
		{"name": "Background", "path": "res://assets/prologue/beat_02/prologue_bg_02_calamity.png", "sz": Vector2(1672, 941), "is_proj": false},
		{"name": "SmokeFar", "path": "res://assets/prologue/beat_02/ambient/smoke/beat02_smoke_far.png", "sz": Vector2(600, 350), "is_proj": false},
		{"name": "MonsterSwarm01", "path": "res://assets/prologue/beat_02/ambient/monsters/beat02_monster_swarm_far_01.png", "sz": Vector2(340, 192), "is_proj": false},
		{"name": "MonsterSwarm02", "path": "res://assets/prologue/beat_02/ambient/monsters/beat02_monster_swarm_far_02.png", "sz": Vector2(388, 209), "is_proj": false},
		{"name": "Lightning01", "path": "res://assets/prologue/beat_02/ambient/lightning/beat02_lightning_01.png", "sz": Vector2(201, 270), "is_proj": false},
		{"name": "Lightning02", "path": "res://assets/prologue/beat_02/ambient/lightning/beat02_lightning_02.png", "sz": Vector2(251, 318), "is_proj": false},
		{"name": "Lightning03", "path": "res://assets/prologue/beat_02/ambient/lightning/beat02_lightning_03.png", "sz": Vector2(210, 297), "is_proj": false},
		{"name": "Projectile01", "path": "res://assets/prologue/beat_02/ambient/projectiles/beat02_chaos_projectiles_01.png", "sz": Vector2(264, 225), "is_proj": true},
		{"name": "Projectile02", "path": "res://assets/prologue/beat_02/ambient/projectiles/beat02_chaos_projectiles_02.png", "sz": Vector2(320, 235), "is_proj": true},
		{"name": "Projectile03", "path": "res://assets/prologue/beat_02/ambient/projectiles/beat02_chaos_projectiles_03.png", "sz": Vector2(316, 236), "is_proj": true},
		{"name": "CorruptionWisp01", "path": "res://assets/prologue/beat_02/ambient/corruption/beat02_corruption_wisp_01.png", "sz": Vector2(241, 330), "is_proj": false},
		{"name": "CorruptionWisp02", "path": "res://assets/prologue/beat_02/ambient/corruption/beat02_corruption_wisp_02.png", "sz": Vector2(261, 350), "is_proj": false},
		{"name": "CorruptionWisp03", "path": "res://assets/prologue/beat_02/ambient/corruption/beat02_corruption_wisp_03.png", "sz": Vector2(271, 360), "is_proj": false},
		{"name": "FireGlow01", "path": "res://assets/prologue/beat_02/ambient/fire/beat02_fire_glow_01.png", "sz": Vector2(320, 260), "is_proj": false},
		{"name": "FireGlow02", "path": "res://assets/prologue/beat_02/ambient/fire/beat02_fire_glow_02.png", "sz": Vector2(340, 280), "is_proj": false},
		{"name": "Embers", "path": "res://assets/prologue/beat_02/ambient/fire/beat02_embers.png", "sz": Vector2(400, 300), "is_proj": false},
		{"name": "SmokeNear", "path": "res://assets/prologue/beat_02/ambient/smoke/beat02_smoke_near.png", "sz": Vector2(650, 400), "is_proj": false},
		{"name": "FloatingDebris", "path": "res://assets/prologue/beat_02/ambient/debris/beat02_floating_debris.png", "sz": Vector2(280, 280), "is_proj": false},
		{"name": "MagicImpact01", "path": "res://assets/prologue/beat_02/ambient/impacts/beat02_magic_impact_01.png", "sz": Vector2(200, 200), "is_proj": false},
		{"name": "MagicImpact02", "path": "res://assets/prologue/beat_02/ambient/impacts/beat02_magic_impact_02.png", "sz": Vector2(220, 220), "is_proj": false}
	]

	for spec in b2_specs:
		var l_name: String = spec["name"]
		var is_proj: bool = bool(spec["is_proj"])
		var sz: Vector2 = spec["sz"]

		if is_proj:
			# Projectile Root Node: Owns position and motion path, rotation = 0.0
			var root_node: Control = Control.new()
			root_node.name = l_name
			root_node.size = sz
			root_node.pivot_offset = sz * 0.5
			root_node.clip_contents = false
			root_node.mouse_filter = Control.MOUSE_FILTER_IGNORE

			# Projectile Visual Node: Child TextureRect, owns sprite rendering & rotation
			var vis_node: TextureRect = TextureRect.new()
			vis_node.name = "Visual"
			vis_node.position = Vector2.ZERO
			vis_node.size = sz
			vis_node.pivot_offset = sz * 0.5
			vis_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			vis_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			vis_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vis_node.clip_contents = false
			vis_node.texture = _load_texture_safely(spec["path"])
			root_node.add_child(vis_node)

			_beat02_root.add_child(root_node)
			_b2_layers[l_name] = root_node
			_b2_visual_nodes[l_name] = vis_node
		else:
			var tex_rect: TextureRect = TextureRect.new()
			tex_rect.name = l_name
			tex_rect.size = sz
			tex_rect.pivot_offset = sz * 0.5
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tex_rect.clip_contents = false
			tex_rect.texture = _load_texture_safely(spec["path"])
			_beat02_root.add_child(tex_rect)
			_b2_layers[l_name] = tex_rect

	# Bottom cinematic gradient
	var b2_gradient: ColorRect = ColorRect.new()
	b2_gradient.name = "CinematicGradient"
	b2_gradient.set_anchors_preset(Control.PRESET_FULL_RECT)
	b2_gradient.color = Color(0.02, 0.0, 0.04, 0.50)
	b2_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beat02_root.add_child(b2_gradient)

	# Beat 2 Narration UI
	_b2_narration = Control.new()
	_b2_narration.name = "NarrationContainer"
	_b2_narration.set_anchors_preset(Control.PRESET_FULL_RECT)
	_b2_narration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beat02_root.add_child(_b2_narration)

	var b2_vbox: VBoxContainer = VBoxContainer.new()
	b2_vbox.name = "NarrationVBox"
	b2_vbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	b2_vbox.offset_top = -170.0
	b2_vbox.offset_bottom = -30.0
	b2_vbox.offset_left = 60.0
	b2_vbox.offset_right = -60.0
	b2_vbox.add_theme_constant_override("separation", 10)
	b2_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_b2_narration.add_child(b2_vbox)

	_b2_phrase1_lbl = Label.new()
	_b2_phrase1_lbl.name = "Phrase1Label"
	_b2_phrase1_lbl.text = "Nhưng rồi một biến cố đã xảy ra."
	_b2_phrase1_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_b2_phrase1_lbl.add_theme_color_override("font_color", Color(0.95, 0.35, 0.25, 1.0)) # Red/Crimson
	_b2_phrase1_lbl.add_theme_font_size_override("font_size", 24)
	b2_vbox.add_child(_b2_phrase1_lbl)

	_b2_phrase2_lbl = RichTextLabel.new()
	_b2_phrase2_lbl.name = "Phrase2Label"
	_b2_phrase2_lbl.bbcode_enabled = true
	_b2_phrase2_lbl.text = "[center]Từ trong bóng tối, Aphodius trỗi dậy,\nkéo theo lũ quái vật và sự hỗn loạn lan rộng khắp Mathos.[/center]"
	_b2_phrase2_lbl.fit_content = true
	_b2_phrase2_lbl.add_theme_color_override("default_color", Color(0.92, 0.94, 0.98, 0.95))
	_b2_phrase2_lbl.add_theme_font_size_override("normal_font_size", 18)
	b2_vbox.add_child(_b2_phrase2_lbl)

# =========================================================================
# LAYOUT RESTORE (HUMAN-ACCEPTED FILES)
# =========================================================================

func load_beat01_layout() -> bool:
	var dict: Dictionary = _load_json_file(BEAT01_LAYOUT_RES_PATH)
	if dict.is_empty() or not dict.has("layers"):
		return false
	_b1_layout_data = dict["layers"] as Dictionary
	apply_beat01_layout()
	return true

func apply_beat01_layout() -> void:
	for layer_name in _b1_layout_data.keys():
		var k_str: String = String(layer_name)
		if _b1_layers.has(k_str):
			var node: Control = _b1_layers[k_str] as Control
			var l_dict: Dictionary = _b1_layout_data[layer_name] as Dictionary
			node.position = Vector2(float(l_dict.get("x", node.position.x)), float(l_dict.get("y", node.position.y)))
			node.scale = Vector2(float(l_dict.get("scale_x", 1.0)), float(l_dict.get("scale_y", 1.0)))
			node.modulate.a = float(l_dict.get("opacity", 1.0))
			node.visible = bool(l_dict.get("visible", true))
			node.rotation_degrees = float(l_dict.get("rotation", 0.0))

func load_beat02_layout() -> bool:
	var dict: Dictionary = _load_json_file(BEAT02_LAYOUT_RES_PATH)
	if dict.is_empty() or not dict.has("layers"):
		return false
	_b2_layout_data = dict["layers"] as Dictionary
	apply_beat02_layout()
	return true

func apply_beat02_layout() -> void:
	for layer_name in _b2_layout_data.keys():
		var k_str: String = String(layer_name)
		if _b2_layers.has(k_str):
			var node: Control = _b2_layers[k_str] as Control
			var l_dict: Dictionary = _b2_layout_data[layer_name] as Dictionary

			var is_proj: bool = _b2_visual_nodes.has(k_str)
			node.position = Vector2(float(l_dict.get("x", node.position.x)), float(l_dict.get("y", node.position.y)))
			node.scale = Vector2(float(l_dict.get("scale_x", 1.0)), float(l_dict.get("scale_y", 1.0)))
			node.visible = bool(l_dict.get("visible", true))
			if l_dict.has("z_index"):
				node.z_index = int(l_dict["z_index"])

			if is_proj:
				# Root rotation MUST be 0.0 (owns movement path)
				node.rotation_degrees = 0.0
				var vis: TextureRect = _b2_visual_nodes[k_str]
				if vis != null:
					var traj_ang: float = float(l_dict.get("trajectory_angle", 0.0))
					var art_off: float = float(l_dict.get("artwork_forward_offset", 0.0))
					var usr_off: float = float(l_dict.get("user_sprite_offset", 0.0))
					vis.rotation_degrees = traj_ang + art_off + usr_off
					vis.modulate.a = float(l_dict.get("opacity", 1.0))

				# Initialize projectile state
				_b2_projectile_state[k_str] = {
					"base_pos": node.position,
					"current_dist": 0.0,
					"trajectory_angle": float(l_dict.get("trajectory_angle", 0.0)),
					"travel_distance": float(l_dict.get("travel_distance", 500.0)),
					"speed": float(l_dict.get("speed", 180.0)),
					"loop": bool(l_dict.get("loop", true)),
					"fade_out": bool(l_dict.get("fade_out", true)),
					"start_offset": float(l_dict.get("start_offset", 0.0)),
					"base_opacity": float(l_dict.get("opacity", 1.0))
				}
			else:
				node.modulate.a = float(l_dict.get("opacity", 1.0))
				node.rotation_degrees = float(l_dict.get("rotation", 0.0))

func get_projectile_root_node(layer_name: String) -> Control:
	return _b2_layers.get(layer_name, null) as Control

func get_projectile_visual_node(layer_name: String) -> TextureRect:
	return _b2_visual_nodes.get(layer_name, null) as TextureRect

func get_layer_node(beat_num: int, layer_name: String) -> Control:
	if beat_num == 1:
		return _b1_layers.get(layer_name, null) as Control
	elif beat_num == 2:
		return _b2_layers.get(layer_name, null) as Control
	return null

func get_current_beat() -> int:
	return _current_beat

# =========================================================================
# PLAYBACK & SEQUENCING (BEAT 1 -> BEAT 2 -> FINISH)
# =========================================================================

func start_prologue() -> void:
	_ensure_built()
	_is_completed = false
	_current_beat = 1
	_playback_time = 0.0
	_is_transitioning = false

	# Show Beat 1, Hide Beat 2
	_beat01_root.visible = true
	_beat01_root.modulate.a = 1.0
	_beat02_root.visible = false
	_beat02_root.modulate.a = 0.0

	visible = true

func advance_to_beat2() -> void:
	if _current_beat == 2 or _is_transitioning:
		return
	_is_transitioning = true

	beat_transitioned.emit(1, 2)
	_current_beat = 2
	_playback_time = 0.0

	_beat02_root.visible = true
	_beat02_root.modulate.a = 0.0

	if is_inside_tree() and _speed_scale > 0.0:
		var tween: Tween = create_tween().set_parallel(true)
		var duration: float = CROSSFADE_DURATION / _speed_scale
		tween.tween_property(_beat01_root, "modulate:a", 0.0, duration)
		tween.tween_property(_beat02_root, "modulate:a", 1.0, duration)
		tween.finished.connect(func():
			_beat01_root.visible = false
			_is_transitioning = false
		)
	else:
		_beat01_root.visible = false
		_beat01_root.modulate.a = 0.0
		_beat02_root.modulate.a = 1.0
		_is_transitioning = false

func complete_prologue() -> void:
	if _is_completed:
		return
	_is_completed = true
	_current_beat = 0

	if is_inside_tree() and _speed_scale > 0.0:
		var tween: Tween = create_tween()
		var duration: float = CROSSFADE_DURATION / _speed_scale
		tween.tween_property(_beat02_root, "modulate:a", 0.0, duration)
		tween.finished.connect(func():
			visible = false
			prologue_completed.emit()
		)
	else:
		visible = false
		prologue_completed.emit()

func _on_skip_pressed() -> void:
	if _is_completed:
		return
	_is_completed = true
	_current_beat = 0
	visible = false
	prologue_skipped.emit()
	prologue_completed.emit()

func set_speed_scale(scale_val: float) -> void:
	_speed_scale = maxf(0.0, scale_val)

# =========================================================================
# RUNTIME AMBIENT MOTION & PROJECTILE SIMULATION
# =========================================================================

func _process(delta: float) -> void:
	if not visible or _is_completed:
		return

	var scaled_delta: float = delta * _speed_scale
	_playback_time += scaled_delta

	if _current_beat == 1:
		_process_beat01_ambient(scaled_delta)
		if _playback_time >= (BEAT1_DURATION / _speed_scale) and not _is_transitioning:
			advance_to_beat2()
	elif _current_beat == 2:
		_process_beat02_ambient(scaled_delta)
		_process_beat02_projectiles(scaled_delta)
		if _playback_time >= (BEAT2_DURATION / _speed_scale) and not _is_transitioning:
			complete_prologue()

func _process_beat01_ambient(_delta: float) -> void:
	var bg: Control = _b1_layers.get("Background", null) as Control
	if bg != null:
		var prog: float = clampf(_playback_time / (BEAT1_DURATION / _speed_scale), 0.0, 1.0)
		var base_scl: Vector2 = Vector2.ONE
		bg.scale = base_scl * lerpf(1.0, 1.04, prog)

	var birds: Control = _b1_layers.get("Birds", null) as Control
	if birds != null:
		var b_base: Vector2 = Vector2(260.0, 48.0)
		birds.position = b_base + Vector2(fmod(_playback_time * 12.0, 150.0), sin(_playback_time * 1.5) * 4.0)

	var creatures: Control = _b1_layers.get("FlyingCreatures", null) as Control
	if creatures != null:
		var c_base: Vector2 = Vector2(110.0, 110.0)
		creatures.position = c_base + Vector2(fmod(_playback_time * 6.0, 100.0), cos(_playback_time * 0.8) * 3.0)

	var mist_far: Control = _b1_layers.get("MistFar", null) as Control
	if mist_far != null:
		mist_far.position.x = -60.0 + sin(_playback_time * 0.25) * 12.0

	var mist_near: Control = _b1_layers.get("MistNear", null) as Control
	if mist_near != null:
		mist_near.position.x = -100.0 - cos(_playback_time * 0.45) * 18.0

func _process_beat02_ambient(_delta: float) -> void:
	var bg: Control = _b2_layers.get("Background", null) as Control
	if bg != null:
		var prog: float = clampf(_playback_time / (BEAT2_DURATION / _speed_scale), 0.0, 1.0)
		bg.scale = Vector2.ONE * lerpf(1.0, 1.03, prog)

	# Intermittent lightning flickers
	var l1: Control = _b2_layers.get("Lightning01", null) as Control
	if l1 != null:
		var flash: float = sin(_playback_time * 8.0) * cos(_playback_time * 3.5)
		l1.modulate.a = clampf(0.85 + (flash * 0.4), 0.2, 1.0)

	var l2: Control = _b2_layers.get("Lightning02", null) as Control
	if l2 != null:
		var flash2: float = cos(_playback_time * 7.0) * sin(_playback_time * 4.2)
		l2.modulate.a = clampf(0.80 + (flash2 * 0.45), 0.15, 1.0)

func _process_beat02_projectiles(delta: float) -> void:
	for p_name in _b2_projectile_state.keys():
		var state: Dictionary = _b2_projectile_state[p_name] as Dictionary
		var root: Control = _b2_layers.get(p_name, null) as Control
		var vis: TextureRect = _b2_visual_nodes.get(p_name, null) as TextureRect
		if root == null or vis == null:
			continue

		var start_off: float = float(state.get("start_offset", 0.0))
		if _playback_time < (start_off / _speed_scale):
			root.visible = false
			continue

		root.visible = true
		var speed: float = float(state.get("speed", 180.0))
		var max_dist: float = float(state.get("travel_distance", 500.0))
		var angle_deg: float = float(state.get("trajectory_angle", 0.0))
		var base_pos: Vector2 = state.get("base_pos", Vector2.ZERO) as Vector2

		var dist: float = float(state.get("current_dist", 0.0)) + speed * delta
		var is_loop: bool = bool(state.get("loop", true))

		if dist > max_dist:
			if is_loop:
				dist = fmod(dist, max_dist)
			else:
				dist = max_dist

		state["current_dist"] = dist

		# Move Root node along trajectory direction vector
		var dir_vec: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(angle_deg))
		root.position = base_pos + dir_vec * dist
		root.rotation_degrees = 0.0 # Ownership strictly isolated: root NEVER rotates

		# Fade out near the end of the path
		var base_op: float = float(state.get("base_opacity", 1.0))
		if bool(state.get("fade_out", true)) and max_dist > 0.0:
			var frac: float = dist / max_dist
			if frac > 0.75:
				var fade_frac: float = 1.0 - ((frac - 0.75) / 0.25)
				vis.modulate.a = base_op * clampf(fade_frac, 0.0, 1.0)
			else:
				vis.modulate.a = base_op
		else:
			vis.modulate.a = base_op

# =========================================================================
# HELPER LOADER
# =========================================================================

static func _load_texture_safely(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res: Resource = ResourceLoader.load(path)
		if res is Texture2D:
			return res as Texture2D
	var global_path: String = ProjectSettings.globalize_path(path)
	var check_path: String = global_path if FileAccess.file_exists(global_path) else path
	if FileAccess.file_exists(check_path):
		var img: Image = Image.new()
		var err: Error = img.load(check_path)
		if err == OK:
			return ImageTexture.create_from_image(img)
	return null

static func _load_json_file(path: String) -> Dictionary:
	var check_path: String = path
	if not FileAccess.file_exists(check_path):
		var global_p: String = ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(global_p):
			check_path = global_p
	if not FileAccess.file_exists(check_path):
		return {}

	var fa: FileAccess = FileAccess.open(check_path, FileAccess.READ)
	if fa == null:
		return {}
	var text: String = fa.get_as_text()
	fa.close()

	var parse_res: Variant = JSON.parse_string(text)
	if parse_res is Dictionary:
		return parse_res as Dictionary
	return {}
