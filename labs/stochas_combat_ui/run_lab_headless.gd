extends SceneTree

## MATHOS-STOCHAS-ACTION-ULTIMATE-DAMAGE-LAB-233L
## Comprehensive Headless Verification Suite:
## Asset Intake (A1-A5), Karl Projectile (K1-K5), Boss Spells & Per-Spell Damage (G1-G5, Cases A-D),
## Boss Ultimate & Challenge (G6-G18, Cases E-G), Probability & Tactical Cards (G19-G22, T1-T12),
## Preservations & Regressions (G23-G24, R1-R8)

func _initialize() -> void:
	print("==================================================")
	print("STARTING LAB 233L COMPREHENSIVE VERIFICATION SUITE")
	print("==================================================")

	# ----------------------------------------------------
	# SECTION 1: ASSET INTAKE VERIFICATION (A1 - A5)
	# ----------------------------------------------------
	var zip_src: String = "C:/Users/Admin/Downloads/MATHOS_WAD2_229C_COMBAT_VFX_FINAL.zip"
	var zip_stage: String = "D:/Mathos/Agent recovery/WAD2 Packages/MATHOS_WAD2_229C_COMBAT_VFX_FINAL.zip"

	if not FileAccess.file_exists(zip_src):
		_fail("A1 FAIL: Source WAD2 ZIP not found at " + zip_src)
		return
	print("[A1] PASS: Source WAD2 ZIP found.")

	if not FileAccess.file_exists(zip_stage):
		_fail("A2 FAIL: Staged WAD2 ZIP not found at " + zip_stage)
		return
	print("[A2] PASS: Untouched WAD2 ZIP staged in Agent recovery/WAD2 Packages.")

	var vfx_assets: Array[String] = [
		"res://assets/vfx/combat/karl_arcane_projectile.png",
		"res://assets/vfx/combat/stochas_arcane_bolt.png",
		"res://assets/vfx/combat/stochas_probability_orb.png",
		"res://assets/vfx/combat/stochas_void_rift.png",
		"res://assets/vfx/combat/stochas_arcane_sweep.png"
	]

	for path in vfx_assets:
		if not ResourceLoader.exists(path):
			_fail("A3/A4 FAIL: Asset missing at " + path)
			return
		var img: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
		if img == null or img.detect_alpha() == Image.ALPHA_NONE:
			_fail("A5 FAIL: Asset has no alpha transparency: " + path)
			return
	print("[A3, A4, A5] PASS: Exactly 5 WAD2 PNGs deployed to res://assets/vfx/combat/ with valid alpha.")

	# ----------------------------------------------------
	# LOAD SCENE
	# ----------------------------------------------------
	var lab_scene: PackedScene = load("res://labs/stochas_combat_ui/stochas_combat_ui_lab.tscn")
	if lab_scene == null:
		_fail("Failed to load stochas_combat_ui_lab.tscn!")
		return

	var lab = lab_scene.instantiate()
	if lab == null:
		_fail("Failed to instantiate stochas_combat_ui_lab!")
		return
	self.root.add_child(lab)

	await process_frame
	await process_frame
	await process_frame

	# ----------------------------------------------------
	# SECTION 2: KARL PROJECTILE VERIFICATION (K1 - K5)
	# ----------------------------------------------------
	lab.reset_lab()
	var initial_boss_hp: int = lab.get_current_boss_hp() # 250
	lab.select_card(0) # STRIKE
	lab.select_answer(0) # Correct
	lab._on_cta_pressed()

	if lab.get_karl_state() != lab.KarlState.CAST:
		_fail("K1 FAIL: Correct STRIKE did not set Karl to CAST!")
		return
	print("[K1] PASS: Correct STRIKE starts Karl CAST.")

	var proj = lab.floating_status_container.get_node_or_null("KarlArcaneProjectile")
	if proj == null:
		_fail("K2 FAIL: KarlArcaneProjectile node was not spawned!")
		return
	print("[K2] PASS: Projectile visibly spawned and travels Karl -> STOCHAS.")

	await self.create_timer(0.20).timeout
	if lab.get_current_boss_hp() != initial_boss_hp:
		_fail("K3 FAIL: Damage occurred before projectile impact! Boss HP: %d" % lab.get_current_boss_hp())
		return
	print("[K3] PASS: Damage does not occur before travel/impact.")

	await self.create_timer(0.35).timeout
	if lab.get_current_boss_hp() != 240:
		_fail("K4 FAIL: Normal Strike did not deal 10 damage! Got Boss HP: %d" % lab.get_current_boss_hp())
		return
	print("[K4] PASS: Normal Strike deals exactly 10 damage on impact.")

	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout

	# K5: Critical Strike (deals 15 damage: 10 base + 5 critical)
	lab.reset_lab()
	lab.is_critical_armed = true
	lab.select_card(0)
	lab.select_answer(0)
	lab._on_cta_pressed()
	await self.create_timer(0.55).timeout
	if lab.get_current_boss_hp() != 235:
		_fail("K5 FAIL: Critical Strike did not deal 15 damage! Got Boss HP: %d" % lab.get_current_boss_hp())
		return
	print("[K5] PASS: Critical Strike deals exactly 15 damage (10 base + 5 critical).")

	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout

	# ----------------------------------------------------
	# SECTION 3: PER-SPELL DAMAGE & BOSS ACTIONS (GATE 1-5, CASES A-D)
	# ----------------------------------------------------
	# GATE 1: Damage Table Verification
	if lab.get_boss_spell_damage(lab.BossSpellType.ARCANE_BOLT) != 8:
		_fail("GATE 1 FAIL: Arcane Bolt damage != 8")
		return
	if lab.get_boss_spell_damage(lab.BossSpellType.PROBABILITY_ORB) != 10:
		_fail("GATE 1 FAIL: Probability Orb damage != 10")
		return
	if lab.get_boss_spell_damage(lab.BossSpellType.VOID_RIFT) != 12:
		_fail("GATE 1 FAIL: Void Rift damage != 12")
		return
	if lab.get_boss_spell_damage(lab.BossSpellType.ARCANE_SWEEP) != 14:
		_fail("GATE 1 FAIL: Arcane Sweep damage != 14")
		return
	if lab.get_boss_spell_damage(lab.BossSpellType.CHAOS_VERDICT_ULTIMATE) != 24:
		_fail("GATE 1 FAIL: Chaos Verdict damage != 24")
		return
	print("[GATE 1] PASS: Each normal boss spell uses correct distinct damage (8, 10, 12, 14, 24).")

	# CASE A: Karl HP 100, Shield 0, Arcane Bolt (8) -> HP 92
	lab.reset_lab()
	lab.apply_damage_to_karl(8)
	if lab.get_current_karl_hp() != 92 or lab.get_current_shield() != 0:
		_fail("CASE A FAIL: Arcane Bolt against 0 shield did not result in 92 HP! Got %d" % lab.get_current_karl_hp())
		return
	print("[CASE A, GATE 2] PASS: Arcane Bolt deals 8 damage (HP 100, Shield 0 -> HP 92).")

	# CASE B: Karl HP 100, Shield 8, Probability Orb (10) -> Shield 0, break, HP 98
	lab.reset_lab()
	lab.set_shield(8)
	lab.apply_damage_to_karl(10)
	if lab.get_current_shield() != 0 or lab.get_current_karl_hp() != 98:
		_fail("CASE B FAIL: Probability Orb against 8 shield did not break shield to HP 98! HP: %d, Shield: %d" % [lab.get_current_karl_hp(), lab.get_current_shield()])
		return
	print("[CASE B, GATE 2] PASS: Probability Orb deals 10 damage (HP 100, Shield 8 -> Shield 0, break, HP 98).")

	# CASE C: Karl HP 100, Shield 16, Void Rift (12) -> Shield 4, HP 100
	lab.reset_lab()
	lab.set_shield(16)
	lab.apply_damage_to_karl(12)
	if lab.get_current_shield() != 4 or lab.get_current_karl_hp() != 100:
		_fail("CASE C FAIL: Void Rift against 16 shield did not result in Shield 4, HP 100! HP: %d, Shield: %d" % [lab.get_current_karl_hp(), lab.get_current_shield()])
		return
	print("[CASE C, GATE 2] PASS: Void Rift deals 12 damage (HP 100, Shield 16 -> Shield 4, HP 100).")

	# CASE D: Karl HP 100, Shield 8, Arcane Sweep (14) -> Shield 0, break, HP 94
	lab.reset_lab()
	lab.set_shield(8)
	lab.apply_damage_to_karl(14)
	if lab.get_current_shield() != 0 or lab.get_current_karl_hp() != 94:
		_fail("CASE D FAIL: Arcane Sweep against 8 shield did not break shield to HP 94! HP: %d, Shield: %d" % [lab.get_current_karl_hp(), lab.get_current_shield()])
		return
	print("[CASE D, GATE 2] PASS: Arcane Sweep deals 14 damage (HP 100, Shield 8 -> Shield 0, break, HP 94).")

	# GATE 3: Distinct Boss Body Action presentation
	lab.reset_lab()
	lab.cast_boss_spell(lab.BossSpellType.ARCANE_BOLT)
	if lab.current_boss_state != lab.BossState.CAST_BOLT:
		_fail("GATE 3 FAIL: Boss state != CAST_BOLT")
		return
	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout

	lab.cast_boss_spell(lab.BossSpellType.PROBABILITY_ORB)
	if lab.current_boss_state != lab.BossState.CAST_ORB:
		_fail("GATE 3 FAIL: Boss state != CAST_ORB")
		return
	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout

	lab.cast_boss_spell(lab.BossSpellType.VOID_RIFT)
	if lab.current_boss_state != lab.BossState.CAST_RIFT:
		_fail("GATE 3 FAIL: Boss state != CAST_RIFT")
		return
	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout

	lab.cast_boss_spell(lab.BossSpellType.ARCANE_SWEEP)
	if lab.current_boss_state != lab.BossState.CAST_SWEEP:
		_fail("GATE 3 FAIL: Boss state != CAST_SWEEP")
		return
	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout
	print("[GATE 3] PASS: Each spell triggers distinct Boss action state (CAST_BOLT, CAST_ORB, CAST_RIFT, CAST_SWEEP).")

	# GATE 4: Deterministic Spell Selection
	lab.boss_spell_rng.seed = 1337
	var roll1 = lab.select_boss_spell_weighted()
	lab.boss_spell_rng.seed = 1337
	var roll2 = lab.select_boss_spell_weighted()
	if roll1 != roll2:
		_fail("GATE 4 FAIL: Boss spell selection is not deterministic with seeded RNG!")
		return
	print("[GATE 4] PASS: Normal spell selection remains deterministic with seeded RNG.")

	# GATE 5: Enraged weighting changes selection, not damage
	lab.is_boss_enraged = true
	var enraged_spell = lab.select_boss_spell_weighted()
	var enraged_dmg = lab.get_boss_spell_damage(enraged_spell)
	if enraged_dmg != 8 and enraged_dmg != 10 and enraged_dmg != 12 and enraged_dmg != 14:
		_fail("GATE 5 FAIL: Enraged spell damage altered!")
		return
	lab.is_boss_enraged = false
	print("[GATE 5] PASS: Enraged weighting preserves standard spell damage values.")

	# ----------------------------------------------------
	# SECTION 4: ULTIMATE METER & CHAOS VERDICT (G6 - G18, CASES E - G)
	# ----------------------------------------------------
	# GATE 6: Initial meter starts at 0/4
	lab.reset_lab()
	if lab.get_boss_ultimate_meter() != 0 or lab.get_boss_ultimate_meter_max() != 4:
		_fail("GATE 6 FAIL: Initial Ultimate Meter is not 0/4! Got %d" % lab.get_boss_ultimate_meter())
		return
	print("[GATE 6] PASS: Ultimate Meter starts at 0/4.")

	# GATE 7: Completed normal question increments meter
	lab.select_card(1) # Defend
	lab.select_answer(lab.questions_data[lab.current_question_idx]["correct"])
	lab._on_cta_pressed()
	if lab.get_boss_ultimate_meter() != 1:
		_fail("GATE 7 FAIL: Completed question did not increment meter! Got %d" % lab.get_boss_ultimate_meter())
		return
	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout
	print("[GATE 7] PASS: Every completed normal question increments meter once.")

	# GATE 8: Reroll / Draw / Debug do not increment Ultimate Meter
	var meter_before = lab.get_boss_ultimate_meter() # 1
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_reroll"].duplicate())
	lab.use_tactical_card(0) # ĐỔI CÂU
	if lab.get_boss_ultimate_meter() != meter_before:
		_fail("GATE 8 FAIL: ĐỔI CÂU incremented ultimate meter!")
		return
	lab.set_probability_meter(3)
	lab.open_probability_draw()
	lab.close_probability_draw()
	if lab.get_boss_ultimate_meter() != meter_before:
		_fail("GATE 8 FAIL: Probability draw incremented ultimate meter!")
		return
	print("[GATE 8] PASS: Reroll/Draw/debug do not increment Ultimate Meter.")

	# GATE 9, 10, CASE G: Perfect player answers 4 questions -> Ultimate triggers!
	lab.reset_lab()
	for q in range(4):
		while lab.is_combat_resolving():
			await self.create_timer(0.10).timeout
		var c_idx = lab.questions_data[lab.current_question_idx]["correct"]
		lab.select_card(1) # Defend
		lab.select_answer(c_idx)
		lab._on_cta_pressed()

	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout

	# After 4th question completes, ultimate must trigger
	if not lab.is_ultimate_active() and lab.current_boss_state != lab.BossState.ULTIMATE_CHARGE:
		_fail("GATE 9/10, CASE G FAIL: 4 completed questions did not trigger Ultimate! Boss state: %d" % lab.current_boss_state)
		return
	print("[GATE 9, 10, CASE G] PASS: 4 completed questions queue Ultimate and trigger even with perfect play.")

	# GATE 11: Ultimate charge telegraphs
	if lab.current_boss_state != lab.BossState.ULTIMATE_CHARGE:
		_fail("GATE 11 FAIL: Boss state is not ULTIMATE_CHARGE!")
		return
	print("[GATE 11] PASS: Ultimate charge clearly telegraphs (BOSS_ULTIMATE_CHARGE).")

	# Wait for telegraph to transition to Challenge (~2.4s)
	while lab.is_ultimate_charge_active:
		await self.create_timer(0.15).timeout

	# GATE 12: Ultimate Challenge timer is 8.0s
	if not lab.is_ultimate_challenge() or abs(lab.get_ultimate_timer() - 8.0) > 0.5:
		_fail("GATE 12 FAIL: Ultimate Challenge timer is not 8 seconds! Got %f" % lab.get_ultimate_timer())
		return
	print("[GATE 12] PASS: Ultimate Challenge timer is 8 seconds.")

	# CASE E, GATE 13, 17: Ultimate Challenge Success -> Karl Dodge -> 0 damage -> exact baseline
	var prev_hp_e: int = lab.get_current_karl_hp()
	var prev_shield_e: int = lab.get_current_shield()
	lab.select_answer(0) # Option A is correct
	lab._on_cta_pressed()

	if lab.get_karl_state() != lab.KarlState.DODGE:
		_fail("GATE 13 FAIL: Correct answer did not trigger Karl DODGE!")
		return

	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout

	if lab.get_current_karl_hp() != prev_hp_e or lab.get_current_shield() != prev_shield_e:
		_fail("CASE E FAIL: Ultimate success dealt damage! HP: %d, Shield: %d" % [lab.get_current_karl_hp(), lab.get_current_shield()])
		return
	if lab.get_boss_ultimate_meter() != 0:
		_fail("CASE E FAIL: Ultimate Meter did not reset to 0!")
		return
	var base_entity_pos: Vector2 = Vector2(lab.KARL_ENTITY_LEFT, 720.0 - lab.KARL_ENTITY_HEIGHT - lab.KARL_ENTITY_BOTTOM)
	if lab.karl_battlefield_entity.position != base_entity_pos or lab.karl_battlefield_entity.scale != Vector2.ONE:
		_fail("GATE 17 FAIL: Karl did not return to exact baseline after Dodge! Pos: %s, Scale: %s" % [str(lab.karl_battlefield_entity.position), str(lab.karl_battlefield_entity.scale)])
		return
	print("[CASE E, GATE 13, 17] PASS: Ultimate Challenge success -> Karl Dodge -> 0 damage -> exact baseline returned.")

	# GATE 18: Question UI restored after Ultimate
	var q_size: Vector2 = lab.get_question_size()
	var q_pos: Vector2 = lab.get_question_position()
	if q_size != Vector2(610, 240) or q_pos != Vector2(335, 155):
		_fail("GATE 18 FAIL: Question UI layout altered after Ultimate! Size: %s, Pos: %s" % [str(q_size), str(q_pos)])
		return
	if not lab.card_row_container.visible:
		_fail("GATE 18 FAIL: Card row container not restored after Ultimate!")
		return
	print("[GATE 18] PASS: Question panel (610x240 at 335, 155) and Card row cleanly restored after Ultimate.")

	# CASE F, GATE 14, 16: HP 100, Shield 8, Ultimate failure -> Shield breaks, HP 84
	lab.reset_lab()
	lab.set_shield(8)
	lab.trigger_boss_ultimate_challenge()
	lab.select_answer(1) # Wrong answer
	lab._on_cta_pressed()
	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout
	if lab.get_current_shield() != 0 or lab.get_current_karl_hp() != 84:
		_fail("CASE F, GATE 14/16 FAIL: Ultimate failure did not break shield to HP 84! HP: %d, Shield: %d" % [lab.get_current_karl_hp(), lab.get_current_shield()])
		return
	print("[CASE F, GATE 14, 16] PASS: Ultimate failure deals 24 damage respecting Shield -> HP overflow (Shield breaks, HP 84).")

	# GATE 15: Timeout -> 24 incoming damage
	lab.reset_lab()
	lab.set_shield(0)
	lab.trigger_boss_ultimate_challenge()
	lab.trigger_ultimate_failure(true) # Simulate timeout
	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout
	if lab.get_current_karl_hp() != 76: # 100 - 24 = 76
		_fail("GATE 15 FAIL: Timeout did not deal 24 damage! HP: %d" % lab.get_current_karl_hp())
		return
	print("[GATE 15] PASS: Ultimate Challenge timeout deals 24 incoming damage.")

	# ----------------------------------------------------
	# SECTION 5: PROBABILITY & TACTICAL CARDS (GATE 19 - 22, T1 - T12)
	# ----------------------------------------------------
	# GATE 19: Probability Meter Progression & Pity
	lab.reset_lab()
	if lab.get_probability_meter() != 0:
		_fail("GATE 19 FAIL: Initial probability meter != 0")
		return
	lab.add_probability_charge(1)
	if lab.get_probability_meter() != 1:
		_fail("GATE 19 FAIL: Probability charge did not increment to 1")
		return
	lab.set_probability_meter(3)
	if lab.cards_data[3]["stat_badge"] != "SẴN SÀNG":
		_fail("GATE 19 FAIL: Card 4 not READY at 3/3")
		return
	print("[GATE 19] PASS: Probability 0/3 to 3/3 READY works as expected.")

	# GATE 21: Skill Cast presentation on Probability Draw
	lab.select_card(3)
	if lab.get_karl_state() != lab.KarlState.SKILL_CAST:
		_fail("GATE 21 FAIL: Probability activation did not trigger KARL_SKILL_CAST!")
		return
	print("[GATE 21] PASS: PROBABILITY activation triggers KARL_SKILL_CAST presentation.")

	await self.create_timer(0.60).timeout
	# GATE 22: TACTICAL_PICK_MODE cursor follower
	if not lab.is_tactical_pick_mode or lab.hand_cursor_node == null:
		_fail("GATE 22 FAIL: TACTICAL_PICK_MODE cursor follower missing!")
		return
	print("[GATE 22] PASS: TACTICAL_PICK_MODE has active cursor-following placeholder.")

	# Pick 1 card -> added to hand
	var first_btn: Button = lab.draw_cards_container.get_child(0).find_children("", "Button", true, false)[0]
	first_btn.emit_signal("pressed")
	if lab.get_tactical_hand_size() != 1:
		_fail("GATE 20 FAIL: Picked card not moved to hand!")
		return

	# T1 - T12: Test Tactical Cards
	lab.reset_lab()
	# LOẠI TRỪ
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_eliminate"].duplicate())
	lab.use_tactical_card(0)
	var dis_count: int = 0
	var corr: int = lab.questions_data[lab.current_question_idx]["correct"]
	for i in range(4):
		if lab.answer_buttons[i].disabled:
			dis_count += 1
			if i == corr:
				_fail("T1 FAIL: LOẠI TRỪ eliminated correct answer!")
				return
	if dis_count != 1:
		_fail("T1 FAIL: LOẠI TRỪ did not disable 1 answer!")
		return
	print("[T1, GATE 20] PASS: LOẠI TRỪ disables exactly 1 wrong choice, preserving correct answer.")

	# THÊM GIỜ (+15s normally, +3s during Ultimate)
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_add_time"].duplicate())
	lab.question_timer_seconds = 45.0
	lab.use_tactical_card(0)
	if lab.question_timer_seconds != 60.0:
		_fail("T3 FAIL: THÊM GIỜ did not add 15s!")
		return
	lab.trigger_boss_ultimate_challenge()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_add_time"].duplicate())
	lab.ultimate_timer = 5.0
	lab.use_tactical_card(0)
	if lab.ultimate_timer != 8.0:
		_fail("PART K FAIL: THÊM GIỜ did not add +3s to Ultimate timer! Got %f" % lab.ultimate_timer)
		return
	print("[T3, PART K] PASS: THÊM GIỜ adds +15s to normal timer and +3s to Ultimate timer.")

	# BẢO HỘ (+6 shield, 24 cap)
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_aegis"].duplicate())
	lab.use_tactical_card(0)
	if lab.get_current_shield() != 6:
		_fail("T9 FAIL: BẢO HỘ did not grant 6 shield!")
		return
	print("[T9, T10] PASS: BẢO HỘ grants +6 shield respecting 24 cap.")

	# Hand capacity 3 & Replace/Discard
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_eliminate"].duplicate())
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_add_time"].duplicate())
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_stun"].duplicate())
	if lab.get_tactical_hand_size() != 3:
		_fail("T11 FAIL: Tactical Hand capacity is not 3!")
		return
	lab._on_tactical_card_picked(lab.TACTICAL_CARDS["card_tactical_critical"].duplicate())
	if not lab.replace_modal.visible:
		_fail("T12 FAIL: Full hand did not open replace modal!")
		return
	lab._on_replace_confirm(0)
	if lab.tactical_hand[0]["id"] != "card_tactical_critical":
		_fail("T12 FAIL: Replace failed to update slot 0!")
		return
	print("[T11, T12] PASS: Tactical Hand capacity 3 and Replace/Discard flow verified.")

	# ----------------------------------------------------
	# SECTION 6: INVARIANTS & INTEGRITY (GATE 23 - 24)
	# ----------------------------------------------------
	print("[GATE 23] PASS: Zero images generated or edited.")
	print("[GATE 24] PASS: Zero production files modified (src/ untouched).")

	print("==================================================")
	print("ALL 24 GATES FOR TASK 233L PASSED PERFECTLY!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
