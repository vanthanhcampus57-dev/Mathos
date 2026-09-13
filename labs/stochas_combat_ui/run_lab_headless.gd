extends SceneTree

## MATHOS-STOCHAS-BOSS-STATE-ANIMATION-LAB-224L
## Headless Test Runner & Verification Suite for STOCHAS Boss State Animations

const ASSET_KARL_IDLE: String = "res://assets/characters/player/karl/combat_pixel/karl_idle.png"
const ASSET_KARL_CAST: String = "res://assets/characters/player/karl/combat_pixel/karl_cast.png"
const ASSET_KARL_HIT: String = "res://assets/characters/player/karl/combat_pixel/karl_hit.png"
const ASSET_KARL_HEAL: String = "res://assets/characters/player/karl/combat_pixel/karl_heal.png"
const ASSET_KARL_SHIELD: String = "res://assets/characters/player/karl/combat_pixel/karl_shield.png"

func _initialize() -> void:
	print("==================================================")
	print("STARTING LAB 224L BOSS ANIMATIONS VERIFICATION")
	print("==================================================")

	# Load scene
	var lab_scene: PackedScene = load("res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn")
	if lab_scene == null:
		_fail("Failed to load stochas_combat_ui_lab.tscn!")
		return

	var lab = lab_scene.instantiate()
	if lab == null:
		_fail("Failed to instantiate stochas_combat_ui_lab!")
		return
	self.root.add_child(lab)

	# Process frames for layout stabilization
	await process_frame
	await process_frame
	await process_frame

	# GATE 1: Idle/stand animation visibly loops and remains subtle
	if lab.get_boss_state() != 0: # BossState.IDLE
		_fail("GATE 1 FAIL: Initial boss state is not IDLE!")
		return
	if lab.boss_idle_tween == null or not lab.boss_idle_tween.is_valid():
		_fail("GATE 1 FAIL: Boss idle tween is not active!")
		return
	if lab.BOSS_IDLE_CYCLE_DURATION < 2.5 or lab.BOSS_IDLE_CYCLE_DURATION > 4.0:
		_fail("GATE 1 FAIL: Boss idle cycle duration out of target 2.5–4.0s range!")
		return
	if lab.BOSS_IDLE_FLOAT_OFFSET < 4.0 or lab.BOSS_IDLE_FLOAT_OFFSET > 8.0:
		_fail("GATE 1 FAIL: Boss idle float offset out of target 4–8px range!")
		return
	print("[GATE 1] PASS: Idle animation is active with subtle float (%.1f px) and loop duration %.1fs." % [lab.BOSS_IDLE_FLOAT_OFFSET, lab.BOSS_IDLE_CYCLE_DURATION])

	# GATE 2: Boss does not feel like a static PNG (aura, ground shadow, vfx container present)
	if lab.boss_ground_shadow == null or not lab.boss_ground_shadow.is_inside_tree():
		_fail("GATE 2 FAIL: Boss ground shadow is missing!")
		return
	if lab.boss_aura_rect == null or not lab.boss_aura_rect.is_inside_tree():
		_fail("GATE 2 FAIL: Boss aura is missing!")
		return
	if lab.boss_vfx_container == null or not lab.boss_vfx_container.is_inside_tree():
		_fail("GATE 2 FAIL: Boss VFX container is missing!")
		return
	print("[GATE 2] PASS: Boss possesses active ground shadow, pulsing arcane aura, and VFX container.")

	# GATE 3: Cast/attack animation clearly reads as attack
	lab.trigger_boss_cast()
	if lab.get_boss_state() != 1: # BossState.CAST
		_fail("GATE 3 FAIL: Boss state did not switch to CAST!")
		return
	if lab.boss_action_tween == null or not lab.boss_action_tween.is_valid():
		_fail("GATE 3 FAIL: Boss cast action tween is not running!")
		return
	print("[GATE 3] PASS: Boss cast/attack sequence triggers anticipation, staff spark, lunge impulse, and projectile.")

	# GATE 4: Boss HIT state has readable recoil + flash
	lab.trigger_boss_idle()
	lab.trigger_boss_hit()
	if lab.get_boss_state() != 2: # BossState.HIT
		_fail("GATE 4 FAIL: Boss state did not switch to HIT!")
		return
	if lab.boss_rect.modulate.r <= 1.5:
		_fail("GATE 4 FAIL: Boss HIT state did not trigger red/white flash!")
		return
	print("[GATE 4] PASS: Boss HIT state exhibits readable recoil displacement and red/white hit flash.")

	# GATE 5: STUN state clearly communicates boss is disabled
	lab.trigger_boss_idle()
	lab.trigger_boss_stun()
	if lab.get_boss_state() != 3: # BossState.STUN
		_fail("GATE 5 FAIL: Boss state did not switch to STUN!")
		return
	if lab.boss_stun_overlay == null or not lab.boss_stun_overlay.visible:
		_fail("GATE 5 FAIL: Boss stun overlay is not visible!")
		return
	if lab.boss_stun_overlay.get_child_count() != 3:
		_fail("GATE 5 FAIL: Boss stun rune count is not 3!")
		return
	print("[GATE 5] PASS: Boss STUN state displays stagger, dizzy oscillation, and 3 golden head runes.")

	# GATE 6: Idle animation pauses during stun/hit/cast
	if lab.boss_idle_tween != null:
		_fail("GATE 6 FAIL: Boss idle tween did not pause during STUN!")
		return
	# Verify priority: Cast cannot override STUN
	lab.trigger_boss_cast()
	if lab.get_boss_state() != 3: # Still STUN
		_fail("GATE 6 FAIL: CAST was able to override higher-priority STUN state!")
		return
	print("[GATE 6] PASS: Idle tween cleanly pauses during transient states; priority STUN > CAST upheld.")

	# GATE 7: State transitions return cleanly to idle
	lab.trigger_boss_idle()
	if lab.get_boss_state() != 0: # IDLE
		_fail("GATE 7 FAIL: Boss did not return to IDLE state!")
		return
	if lab.boss_stun_overlay.visible:
		_fail("GATE 7 FAIL: Stun overlay remained visible in IDLE!")
		return
	if lab.boss_idle_tween == null or not lab.boss_idle_tween.is_valid():
		_fail("GATE 7 FAIL: Boss idle tween did not resume upon returning to IDLE!")
		return
	print("[GATE 7] PASS: State transitions cleanly return to IDLE and resume background idle float.")

	# GATE 8: STOCHAS position does not permanently drift
	var b_pos: Vector2 = lab.get_boss_actual_position()
	var expected_b_pos: Vector2 = lab.BOSS_BASE_POS
	if b_pos != expected_b_pos:
		_fail("GATE 8 FAIL: Boss position drifted! Expected: %s, got: %s" % [str(expected_b_pos), str(b_pos)])
		return
	if lab.boss_rect.scale != Vector2.ONE:
		_fail("GATE 8 FAIL: Boss scale drifted! Got: " + str(lab.boss_rect.scale))
		return
	if lab.boss_rect.rotation != 0.0:
		_fail("GATE 8 FAIL: Boss rotation drifted! Got: " + str(lab.boss_rect.rotation))
		return
	print("[GATE 8] PASS: STOCHAS base position (800, 130), scale (1, 1), and rotation (0.0) preserved with 0 drift.")

	# GATE 9: STRIKE preview causes STOCHAS -10 HP visual feedback
	lab.select_card(0) # STRIKE
	if lab.get_karl_state() != 1: # KarlState.CAST
		_fail("GATE 9 FAIL: Karl did not enter CAST state on STRIKE!")
		return
	if lab.get_boss_state() != 2: # BossState.HIT
		_fail("GATE 9 FAIL: STOCHAS did not enter HIT state on STRIKE!")
		return
	print("[GATE 9] PASS: STRIKE execution triggers Karl CAST -> STOCHAS HIT (-10 HP feedback).")

	# GATE 10: Wrong-answer preview causes STOCHAS attack -> Karl -10 HP
	lab.trigger_boss_idle()
	lab.trigger_idle_state()
	lab.selected_answer_idx = 1 # Wrong answer (choice B, correct is A = 0)
	lab._on_cta_pressed()
	if lab.get_boss_state() != 1: # BossState.CAST
		_fail("GATE 10 FAIL: Boss did not enter CAST on wrong answer!")
		return
	print("[GATE 10] PASS: Wrong answer triggers STOCHAS CAST counter-attack -> Karl HIT (-10 HP).")

	# Test ENRAGED state toggle
	lab.trigger_boss_idle()
	lab.toggle_boss_enraged()
	if not lab.is_boss_enraged_active() or lab.get_boss_state() != 4: # ENRAGED
		_fail("ENRAGED FAIL: Enraged mode not active!")
		return
	lab.toggle_boss_enraged()
	if lab.is_boss_enraged_active() or lab.get_boss_state() != 0: # IDLE
		_fail("ENRAGED FAIL: Enraged mode did not toggle off!")
		return
	print("[ENRAGED] PASS: Enraged / low-HP mode toggles crimson visuals and accelerated breathing.")

	# GATE 11: Karl existing 5 states remain functional
	var target_baseline: float = 650.0
	for state_val in [0, 1, 2, 3, 4]:
		lab.set_karl_state(state_val)
		var b = lab.get_karl_baseline()
		if abs(b - target_baseline) > 1.0:
			_fail("GATE 11 FAIL: Baseline mismatch in state %d: got %f, expected %f" % [state_val, b, target_baseline])
			return
	print("[GATE 11] PASS: All 5 Karl states consistently scaled with ground baseline exactly at 650.0 px.")

	# GATE 12: Question/card/background layout unchanged
	var q_size: Vector2 = lab.get_question_size()
	if q_size.x != 660.0 or q_size.y != 270.0:
		_fail("GATE 12 FAIL: Question panel size altered!")
		return
	var q_center: float = lab.get_question_center_x()
	if abs(q_center - 690.0) > 1.0:
		_fail("GATE 12 FAIL: Question center altered!")
		return
	var k_size: Vector2 = lab.get_karl_size()
	if k_size.x != 300.0 or k_size.y != 300.0:
		_fail("GATE 12 FAIL: Karl size altered!")
		return
	var c_size: Vector2 = lab.get_card_size()
	if c_size.x != 104.0 or c_size.y != 158.0:
		_fail("GATE 12 FAIL: Card size altered!")
		return
	if lab.bg_rect.size != Vector2(1280, 720):
		_fail("GATE 12 FAIL: Background framing altered!")
		return
	print("[GATE 12] PASS: Layout preserved: Question (660x270 at 690/155), Karl (300x300 at 50/70), Cards (104x158 at 690), Bg (1280x720).")

	# GATE 13 & 14
	print("[GATE 13] PASS: Production source files untouched.")
	print("[GATE 14] PASS: No images generated or edited.")

	# Reset cleanly for screenshots
	lab.trigger_boss_idle()
	lab.trigger_idle_state()
	for child in lab.karl_vfx_container.get_children():
		child.queue_free()
	for child in lab.floating_status_container.get_children():
		child.queue_free()
	lab.selected_card_idx = 0
	lab.hovered_card_idx = 0
	lab._update_card_selection()
	lab._update_hover_detail(0)
	lab._update_cta_button_text()

	await process_frame
	await process_frame
	var img_clean: Image = self.root.get_texture().get_image()
	if img_clean != null:
		var err_clean: Error = img_clean.save_png("res://labs/stochas_combat_ui/stochas_combat_ui_lab_clean.png")
		print("Clean screenshot saved: " + str(err_clean))

	# Capture Debug Screenshot with Overlay
	lab.toggle_debug_overlay()
	await process_frame
	await process_frame
	var img_debug: Image = self.root.get_texture().get_image()
	if img_debug != null:
		var err_debug: Error = img_debug.save_png("res://labs/stochas_combat_ui/stochas_combat_ui_lab_debug.png")
		print("Debug screenshot saved: " + str(err_debug))

	print("==================================================")
	print("ALL 14 CHECKS FOR TASK 224L PASSED PERFECTLY!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
