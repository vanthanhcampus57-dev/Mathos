class_name AuthLoginBackground
extends Control

## Standalone Animated Auth/Login Academy Background Component.
## Renders clean Academy background, 2 top-pinned swaying banners, procedural crystal glow,
## 2 independent ground fog layers, and magic dust particles.
## Enforces zero save/progress mutation, zero per-frame resource allocations, and edge safety.

# Default Constants
const BG_ASSET_PATH: String = "res://assets/backgrounds/auth/login_academy_bg_clean.png"
const FOG_ASSET_PATH: String = "res://assets/backgrounds/auth/login_ground_fog.png"
const BANNER_ASSET_PATH: String = "res://assets/backgrounds/auth/login_academy_banner.png"

# Shader for Banner Top-Pin Deformation
const BANNER_SHADER_CODE: String = """shader_type canvas_item;

uniform float sway_amplitude : hint_range(0.0, 20.0) = 3.0;
uniform float sway_speed : hint_range(0.0, 3.0) = 0.45;
uniform float ripple_amplitude : hint_range(0.0, 10.0) = 0.8;
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;

void vertex() {
	// Top 12% is fixed (rod attachment protection)
	float pin_factor = smoothstep(0.12, 0.95, UV.y);
	float t = TIME * sway_speed + time_offset;
	float sway = sin(t + VERTEX.y * 0.005) * sway_amplitude * pin_factor;
	float ripple = sin(t * 2.3 + VERTEX.y * 0.02) * ripple_amplitude * pin_factor;
	VERTEX.x += sway + ripple;
}
"""

# Default Parameter Values
const DEFAULT_FOG_MASTER_OPACITY: float = 1.0
const DEFAULT_FOG_DRIFT_MULT: float = 1.0
const DEFAULT_FOG_SPEED_MULT: float = 1.0
const DEFAULT_FOG_BREATH_MULT: float = 1.0
const DEFAULT_FOG_L1_ENABLE: bool = true
const DEFAULT_FOG_L2_ENABLE: bool = true

const DEFAULT_BANNER_A_VISIBLE: bool = true
const DEFAULT_BANNER_B_VISIBLE: bool = true
const DEFAULT_BANNER_SWAY: float = 3.5
const DEFAULT_BANNER_SPEED: float = 0.45
const DEFAULT_BANNER_RIPPLE: float = 0.8

const DEFAULT_CRYSTAL_MASTER: float = 0.65
const DEFAULT_CRYSTAL_PULSE_AMT: float = 0.35
const DEFAULT_CRYSTAL_PULSE_SPEED: float = 0.6

const DEFAULT_DUST_ENABLE: bool = true
const DEFAULT_DUST_DENSITY: int = 16
const DEFAULT_DUST_SPEED: float = 18.0
const DEFAULT_DUST_OPACITY: float = 0.35

# Node References
var _bg_rect: TextureRect = null
var _crystal_container: Control = null
var _crystal_glow_nodes: Array[ColorRect] = []
var _banner_container: Control = null
var _banner_a: TextureRect = null
var _banner_b: TextureRect = null
var _banner_mat_a: ShaderMaterial = null
var _banner_mat_b: ShaderMaterial = null
var _fog_container: Control = null
var _fog_layer_1: TextureRect = null
var _fog_layer_2: TextureRect = null
var _dust_particles: CPUParticles2D = null

# Shared Loaded Textures (Zero duplicate allocations)
var _bg_texture: Texture2D = null
var _fog_texture: Texture2D = null
var _banner_texture: Texture2D = null
var _banner_shader: Shader = null

# State Variables
var _is_playing: bool = true
var _accum_time: float = 0.0

# Adjustable Parameters
var fog_master_opacity: float = DEFAULT_FOG_MASTER_OPACITY
var fog_drift_mult: float = DEFAULT_FOG_DRIFT_MULT
var fog_speed_mult: float = DEFAULT_FOG_SPEED_MULT
var fog_breath_mult: float = DEFAULT_FOG_BREATH_MULT
var fog_l1_enabled: bool = DEFAULT_FOG_L1_ENABLE
var fog_l2_enabled: bool = DEFAULT_FOG_L2_ENABLE

var banner_a_visible: bool = DEFAULT_BANNER_A_VISIBLE
var banner_b_visible: bool = DEFAULT_BANNER_B_VISIBLE
var banner_sway: float = DEFAULT_BANNER_SWAY
var banner_speed: float = DEFAULT_BANNER_SPEED
var banner_ripple: float = DEFAULT_BANNER_RIPPLE

var crystal_master_opacity: float = DEFAULT_CRYSTAL_MASTER
var crystal_pulse_amount: float = DEFAULT_CRYSTAL_PULSE_AMT
var crystal_pulse_speed: float = DEFAULT_CRYSTAL_PULSE_SPEED

var dust_enabled: bool = DEFAULT_DUST_ENABLE
var dust_density: int = DEFAULT_DUST_DENSITY
var dust_speed: float = DEFAULT_DUST_SPEED
var dust_opacity: float = DEFAULT_DUST_OPACITY

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_load_resources()
	_build_layer_hierarchy()
	reset_defaults()

func _process(delta: float) -> void:
	if _is_playing:
		_accum_time += delta
	_update_animations(_accum_time)

func _load_resources() -> void:
	if _bg_texture == null:
		_bg_texture = _load_texture_safe(BG_ASSET_PATH)
	if _fog_texture == null:
		_fog_texture = _load_texture_safe(FOG_ASSET_PATH)
	if _banner_texture == null:
		_banner_texture = _load_texture_safe(BANNER_ASSET_PATH)

	if _banner_shader == null:
		_banner_shader = Shader.new()
		_banner_shader.code = BANNER_SHADER_CODE

func _load_texture_safe(p: String) -> Texture2D:
	if ResourceLoader.exists(p) or FileAccess.file_exists(p):
		var tex: Texture2D = load(p) as Texture2D
		if tex != null:
			return tex
	var global_p: String = ProjectSettings.globalize_path(p)
	if FileAccess.file_exists(global_p):
		var tex: Texture2D = load(global_p) as Texture2D
		if tex != null:
			return tex
	return null

func _build_layer_hierarchy() -> void:
	# 1. STATIC ACADEMY BG
	_bg_rect = TextureRect.new()
	_bg_rect.name = "AcademyBackground"
	_bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.texture = _bg_texture
	_bg_rect.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	# 2. CRYSTAL GLOW CONTAINER
	_crystal_container = Control.new()
	_crystal_container.name = "CrystalGlowContainer"
	_crystal_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_crystal_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_crystal_container)

	# Position crystal glow overlays over Academy crystals
	var crystal_positions: Array[Vector2] = [
		Vector2(0.12, 0.32),
		Vector2(0.24, 0.42),
		Vector2(0.31, 0.58),
		Vector2(0.08, 0.52)
	]
	_crystal_glow_nodes.clear()
	for i in range(crystal_positions.size()):
		var glow: ColorRect = ColorRect.new()
		glow.name = "CrystalGlow_%d" % i
		glow.custom_minimum_size = Vector2(48, 48)
		glow.mouse_filter = MOUSE_FILTER_IGNORE
		glow.color = Color(0.2, 0.85, 1.0, 0.6)
		_crystal_container.add_child(glow)
		_crystal_glow_nodes.append(glow)

	# 3. BANNERS CONTAINER
	_banner_container = Control.new()
	_banner_container.name = "BannerContainer"
	_banner_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_banner_container)

	_banner_mat_a = ShaderMaterial.new()
	_banner_mat_a.shader = _banner_shader
	_banner_mat_a.set_shader_parameter("time_offset", 0.0)

	_banner_a = TextureRect.new()
	_banner_a.name = "Banner_A"
	_banner_a.texture = _banner_texture
	_banner_a.material = _banner_mat_a
	_banner_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_banner_a.custom_minimum_size = Vector2(130, 260)
	_banner_a.mouse_filter = MOUSE_FILTER_IGNORE
	_banner_container.add_child(_banner_a)

	_banner_mat_b = ShaderMaterial.new()
	_banner_mat_b.shader = _banner_shader
	_banner_mat_b.set_shader_parameter("time_offset", 1.85)

	_banner_b = TextureRect.new()
	_banner_b.name = "Banner_B"
	_banner_b.texture = _banner_texture
	_banner_b.material = _banner_mat_b
	_banner_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_banner_b.custom_minimum_size = Vector2(110, 220)
	_banner_b.mouse_filter = MOUSE_FILTER_IGNORE
	_banner_container.add_child(_banner_b)

	# 4. GROUND FOG CONTAINER
	_fog_container = Control.new()
	_fog_container.name = "GroundFogContainer"
	_fog_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fog_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_fog_container)

	_fog_layer_1 = TextureRect.new()
	_fog_layer_1.name = "FogLayer_1"
	_fog_layer_1.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fog_layer_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fog_layer_1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fog_layer_1.texture = _fog_texture
	_fog_layer_1.mouse_filter = MOUSE_FILTER_IGNORE
	_fog_container.add_child(_fog_layer_1)

	_fog_layer_2 = TextureRect.new()
	_fog_layer_2.name = "FogLayer_2"
	_fog_layer_2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fog_layer_2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fog_layer_2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fog_layer_2.texture = _fog_texture
	_fog_layer_2.mouse_filter = MOUSE_FILTER_IGNORE
	_fog_container.add_child(_fog_layer_2)

	# 5. MAGIC DUST PARTICLES
	_dust_particles = CPUParticles2D.new()
	_dust_particles.name = "MagicDustParticles"
	_dust_particles.amount = DEFAULT_DUST_DENSITY
	_dust_particles.lifetime = 4.0
	_dust_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust_particles.emission_rect_extents = Vector2(250, 200)
	_dust_particles.gravity = Vector2(0, -8.0)
	_dust_particles.direction = Vector2(-0.2, -1.0)
	_dust_particles.spread = 25.0
	_dust_particles.initial_velocity_min = 10.0
	_dust_particles.initial_velocity_max = 25.0
	_dust_particles.scale_amount_min = 2.0
	_dust_particles.scale_amount_max = 4.5
	_dust_particles.color = Color(0.4, 0.9, 1.0, 0.4)
	add_child(_dust_particles)

func reset_defaults() -> void:
	fog_master_opacity = DEFAULT_FOG_MASTER_OPACITY
	fog_drift_mult = DEFAULT_FOG_DRIFT_MULT
	fog_speed_mult = DEFAULT_FOG_SPEED_MULT
	fog_breath_mult = DEFAULT_FOG_BREATH_MULT
	fog_l1_enabled = DEFAULT_FOG_L1_ENABLE
	fog_l2_enabled = DEFAULT_FOG_L2_ENABLE

	banner_a_visible = DEFAULT_BANNER_A_VISIBLE
	banner_b_visible = DEFAULT_BANNER_B_VISIBLE
	banner_sway = DEFAULT_BANNER_SWAY
	banner_speed = DEFAULT_BANNER_SPEED
	banner_ripple = DEFAULT_BANNER_RIPPLE

	crystal_master_opacity = DEFAULT_CRYSTAL_MASTER
	crystal_pulse_amount = DEFAULT_CRYSTAL_PULSE_AMT
	crystal_pulse_speed = DEFAULT_CRYSTAL_PULSE_SPEED

	dust_enabled = DEFAULT_DUST_ENABLE
	dust_density = DEFAULT_DUST_DENSITY
	dust_speed = DEFAULT_DUST_SPEED
	dust_opacity = DEFAULT_DUST_OPACITY

	_update_animations(_accum_time)

func _update_animations(time: float) -> void:
	var vp_size: Vector2 = size if size.x > 0 and size.y > 0 else Vector2(1280, 720)

	# 1. FOG LAYER ANIMATIONS
	if _fog_layer_1 != null:
		_fog_layer_1.visible = fog_l1_enabled
		var l1_base_opacity: float = 0.22 * fog_master_opacity
		var l1_drift: float = 70.0 * fog_drift_mult
		var l1_speed: float = 0.07 * fog_speed_mult
		var l1_breath: float = 0.035 * fog_breath_mult

		var l1_offset_x: float = sin(time * l1_speed) * l1_drift
		var l1_scale: float = 1.0 + sin(time * l1_speed * 1.3) * l1_breath

		_fog_layer_1.modulate = Color(1.0, 1.0, 1.0, l1_base_opacity)
		_fog_layer_1.position = Vector2(l1_offset_x, (1.0 - l1_scale) * vp_size.y * 0.5)

	if _fog_layer_2 != null:
		_fog_layer_2.visible = fog_l2_enabled
		var l2_base_opacity: float = 0.12 * fog_master_opacity
		var l2_drift: float = -95.0 * fog_drift_mult
		var l2_speed: float = 0.045 * fog_speed_mult
		var l2_breath: float = 0.025 * fog_breath_mult

		var l2_offset_x: float = sin(time * l2_speed + 2.4) * l2_drift
		var l2_scale: float = 1.05 + cos(time * l2_speed * 1.1 + 1.2) * l2_breath

		_fog_layer_2.modulate = Color(1.0, 1.0, 1.0, l2_base_opacity)
		_fog_layer_2.position = Vector2(l2_offset_x, (1.0 - l2_scale) * vp_size.y * 0.5)

	# 2. BANNERS SHADER & POSITIONS
	if _banner_a != null:
		_banner_a.visible = banner_a_visible
		_banner_a.position = Vector2(vp_size.x * 0.16, vp_size.y * 0.22)
		if _banner_mat_a != null:
			_banner_mat_a.set_shader_parameter("sway_amplitude", banner_sway)
			_banner_mat_a.set_shader_parameter("sway_speed", banner_speed)
			_banner_mat_a.set_shader_parameter("ripple_amplitude", banner_ripple)

	if _banner_b != null:
		_banner_b.visible = banner_b_visible
		_banner_b.position = Vector2(vp_size.x * 0.34, vp_size.y * 0.26)
		if _banner_mat_b != null:
			_banner_mat_b.set_shader_parameter("sway_amplitude", banner_sway * 0.85)
			_banner_mat_b.set_shader_parameter("sway_speed", banner_speed * 1.1)
			_banner_mat_b.set_shader_parameter("ripple_amplitude", banner_ripple * 0.9)

	# 3. CRYSTAL GLOW PULSES (Phase offsets)
	var crystal_positions: Array[Vector2] = [
		Vector2(vp_size.x * 0.12, vp_size.y * 0.32),
		Vector2(vp_size.x * 0.24, vp_size.y * 0.42),
		Vector2(vp_size.x * 0.31, vp_size.y * 0.58),
		Vector2(vp_size.x * 0.08, vp_size.y * 0.52)
	]
	var phase_offsets: Array[float] = [0.0, 1.25, 2.7, 4.1]

	for i in range(_crystal_glow_nodes.size()):
		if i < crystal_positions.size():
			var glow: ColorRect = _crystal_glow_nodes[i]
			glow.position = crystal_positions[i]
			var pulse: float = sin(time * crystal_pulse_speed * TAU + phase_offsets[i]) * 0.5 + 0.5
			var alpha: float = crystal_master_opacity * (1.0 - crystal_pulse_amount + crystal_pulse_amount * pulse)
			glow.color = Color(0.2, 0.85, 1.0, alpha)

	# 4. MAGIC DUST PARTICLES
	if _dust_particles != null:
		_dust_particles.emitting = dust_enabled and _is_playing
		_dust_particles.visible = dust_enabled
		_dust_particles.position = Vector2(vp_size.x * 0.22, vp_size.y * 0.55)
		_dust_particles.amount = max(1, dust_density)
		_dust_particles.color = Color(0.4, 0.9, 1.0, dust_opacity)

func set_playing(playing: bool) -> void:
	_is_playing = playing
	if _dust_particles != null:
		_dust_particles.emitting = playing and dust_enabled

func is_playing() -> bool:
	return _is_playing

func get_bg_texture() -> Texture2D:
	_load_resources()
	return _bg_texture

func get_fog_texture() -> Texture2D:
	_load_resources()
	return _fog_texture

func get_banner_texture() -> Texture2D:
	_load_resources()
	return _banner_texture

func get_fog_layer_count() -> int:
	return 2
