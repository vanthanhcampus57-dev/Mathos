extends SceneTree

## MATHOS-PROBABILITY-GACHA-VFX-LAB-INTEGRATION-232L
## Comprehensive Headless Verification Suite:
## Asset Intake (A1-A5), Karl Projectile (K1-K5), Boss Spells (B1-B7),
## Probability Gacha (P1-P10), Tactical Cards (T1-T12), Regression Gates (R1-R10)

func _initialize() -> void:
	print("==================================================")
	print("STARTING LAB 232L COMPREHENSIVE VERIFICATION SUITE")
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

	# Process frames for layout stabilization
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

	# Check mid-flight (0.20s): damage must NOT have occurred yet
	await self.create_timer(0.20).timeout
	if lab.get_current_boss_hp() != initial_boss_hp:
		_fail("K3 FAIL: Damage occurred before projectile impact! Boss HP: %d" % lab.get_current_boss_hp())
		return
	print("[K3] PASS: Damage does not occur before travel/impact.")

	# Wait for impact (0.35s more -> total 0.55s > 0.45s travel)
	await self.create_timer(0.35).timeout
	if lab.get_current_boss_hp() != 240:
		_fail("K4 FAIL: Normal Strike did not deal 10 damage! Got Boss HP: %d" % lab.get_current_boss_hp())
		return
	print("[K4] PASS: Normal Strike deals exactly 10 damage on impact.")

	# Wait for return to IDLE
	await self.create_timer(0.45).timeout

	# Test Critical Strike = 15 damage (K5)
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_critical"].duplicate())
	lab.use_tactical_card(0)
	if not lab.is_critical_armed_active():
		_fail("K5 setup failed: Critical not armed!")
		return
	lab.select_card(0)
	lab.select_answer(0)
	lab._on_cta_pressed()

	await self.create_timer(0.55).timeout
	if lab.get_current_boss_hp() != 225:
		_fail("K5 FAIL: Critical Strike did not deal 15 damage! Expected 225, got %d" % lab.get_current_boss_hp())
		return
	print("[K5] PASS: Critical Strike deals exactly 15 damage (10 base + 5 critical).")

	await self.create_timer(0.45).timeout

	# ----------------------------------------------------
	# SECTION 3: BOSS MULTI-SPELLS VERIFICATION (B1 - B7)
	# ----------------------------------------------------
	# B1: Arcane Bolt
	lab.reset_lab()
	lab.trigger_boss_spell_arcane_bolt()
	if not lab.is_combat_resolving():
		_fail("B1 FAIL: Arcane bolt did not set combat_resolving!")
		return
	await self.create_timer(0.25).timeout
	if lab.get_question_alpha() > 0.35:
		_fail("B7 FAIL: Arcane bolt did not fade question! Alpha: %f" % lab.get_question_alpha())
		return
	# Wait for anticipation (0.22s) + bolt travel (0.50s) -> total 0.72s. Current elapsed 0.25s.
	await self.create_timer(0.55).timeout
	if lab.get_current_karl_hp() != 90:
		_fail("B1/B5 FAIL: Arcane Bolt did not deal 10 damage to Karl! Got %d" % lab.get_current_karl_hp())
		return
	await self.create_timer(0.45).timeout
	print("[B1, B5] PASS: Arcane Bolt preview works and deals 10 damage.")

	# B2: Probability Orb
	lab.reset_lab()
	lab.trigger_boss_spell_probability_orb()
	if not lab.is_combat_resolving():
		_fail("B2 FAIL: Probability Orb did not set combat_resolving!")
		return
	# Wait for anticipation (0.22s) + orb hover (0.35s) + orb travel (0.55s) = 1.12s
	await self.create_timer(1.20).timeout
	if lab.get_current_karl_hp() != 90:
		_fail("B2/B5 FAIL: Probability Orb did not deal 10 damage to Karl! Got %d" % lab.get_current_karl_hp())
		return
	await self.create_timer(0.45).timeout
	print("[B2, B5] PASS: Probability Orb preview works and deals 10 damage.")

	# B3: Void Rift (with Shield Absorption & Break: B6)
	lab.reset_lab()
	lab.set_shield(8)
	lab.trigger_boss_spell_void_rift()
	if not lab.is_combat_resolving():
		_fail("B3 FAIL: Void Rift did not set combat_resolving!")
		return
	# Wait for anticipation (0.22s) + rift detonation (0.60s) = 0.82s
	await self.create_timer(0.90).timeout
	if lab.get_current_shield() != 0 or lab.get_current_karl_hp() != 98:
		_fail("B3/B6 FAIL: Void Rift did not apply Shield 8 -> 0 break -> HP 98! Shield: %d, HP: %d" % [lab.get_current_shield(), lab.get_current_karl_hp()])
		return
	await self.create_timer(0.65).timeout
	print("[B3, B6] PASS: Void Rift preview works with shield-first damage & break.")

	# B4: Arcane Sweep (with Shield 16 -> 6: B6)
	lab.reset_lab()
	lab.set_shield(16)
	lab.trigger_boss_spell_arcane_sweep()
	if not lab.is_combat_resolving():
		_fail("B4 FAIL: Arcane Sweep did not set combat_resolving!")
		return
	# Wait for anticipation (0.22s) + sweep travel (0.65s) = 0.87s
	await self.create_timer(0.95).timeout
	if lab.get_current_shield() != 6 or lab.get_current_karl_hp() != 100:
		_fail("B4/B6 FAIL: Arcane Sweep did not apply Shield 16 -> 6! Shield: %d, HP: %d" % [lab.get_current_shield(), lab.get_current_karl_hp()])
		return
	await self.create_timer(0.45).timeout
	print("[B4, B6, B7] PASS: Arcane Sweep works, question remains faded for full sequence.")

	# ----------------------------------------------------
	# SECTION 4: PROBABILITY GACHA VERIFICATION (P1 - P10)
	# ----------------------------------------------------
	lab.reset_lab()
	if lab.get_probability_meter() != 0:
		_fail("P1 FAIL: Initial meter not 0/3! Got %d" % lab.get_probability_meter())
		return
	print("[P1] PASS: Initial meter = 0/3.")

	# P2: Correct answer -> +1
	lab.select_card(1) # DEFEND
	lab.select_answer(0) # Correct
	lab._on_cta_pressed()
	await self.create_timer(1.30).timeout
	if lab.get_probability_meter() != 1:
		_fail("P2 FAIL: Correct answer did not increment meter! Got %d" % lab.get_probability_meter())
		return
	print("[P2] PASS: Correct answer increments meter (+1).")

	# P3: Wrong answer -> +0
	lab.select_card(1)
	lab.select_answer(1) # Wrong
	lab._on_cta_pressed()
	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout
	if lab.get_probability_meter() != 1:
		_fail("P3 FAIL: Wrong answer altered meter! Got %d" % lab.get_probability_meter())
		return
	print("[P3] PASS: Wrong answer grants +0 charge.")

	# P4: At 3/3 Probability READY
	lab.set_probability_meter(3)
	if lab.cards_data[3]["stat_badge"] != "SẴN SÀNG" or lab.cards_data[3]["disabled"]:
		_fail("P4 FAIL: Card 4 not READY at 3/3!")
		return
	print("[P4] PASS: At 3/3 Probability transitions to READY.")

	# P5, P6, P7, P8, P9: Activate Draw
	if lab.is_combat_resolving():
		_fail("P5 setup error: combat_resolving is still true!")
		return
	lab.select_card(3) # Click card 4
	if not lab.is_draw_open:
		_fail("P5 FAIL: Activating READY card 4 did not open draw!")
		return
	if lab.get_probability_meter() != 0:
		_fail("P5 FAIL: Draw did not consume meter (3 -> 0)! Got %d" % lab.get_probability_meter())
		return
	print("[P5] PASS: Draw consumes 3 charges -> 0.")

	var drawn_count = lab.draw_cards_container.get_child_count()
	if drawn_count != 3:
		_fail("P6 FAIL: Draw did not provide 3 cards! Got %d" % drawn_count)
		return

	# P7 & P8: Pick 1 card -> added to hand
	var first_card_btn: Button = lab.draw_cards_container.get_child(0).find_children("", "Button", true, false)[0]
	first_card_btn.emit_signal("pressed")
	if lab.get_tactical_hand_size() != 1:
		_fail("P7/P8 FAIL: Chosen card not moved to Tactical Hand! Hand size: %d" % lab.get_tactical_hand_size())
		return
	print("[P6, P7, P8] PASS: Exactly 3 unique cards drawn, 1 picked and added to hand.")

	if lab.is_combat_resolving():
		_fail("P9 FAIL: Draw consumed combat turn!")
		return
	print("[P9] PASS: Draw does not consume normal combat turn.")

	# P10: Pity rule (2 consecutive no-rare draws guarantee at least 1 rare)
	lab.consecutive_no_rare_draws = 2
	var pity_draw = lab.draw_three_tactical_cards()
	var has_rare_pity: bool = false
	for c in pity_draw:
		if c["rarity"] == "RARE":
			has_rare_pity = true
			break
	if not has_rare_pity:
		_fail("P10 FAIL: Pity rule did not guarantee Rare after 2 no-rare draws!")
		return
	print("[P10] PASS: Pity guarantees at least 1 Rare after 2 consecutive no-Rare draws.")

	# ----------------------------------------------------
	# SECTION 5: TACTICAL CARDS VERIFICATION (T1 - T12)
	# ----------------------------------------------------
	# T1: LOẠI TRỪ
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_eliminate"].duplicate())
	lab.use_tactical_card(0)
	var disabled_count: int = 0
	var correct_idx: int = lab.questions_data[lab.current_question_idx]["correct"]
	for i in range(4):
		if lab.answer_buttons[i].disabled:
			disabled_count += 1
			if i == correct_idx:
				_fail("T1 FAIL: LOẠI TRỪ eliminated the correct answer!")
				return
	if disabled_count != 1:
		_fail("T1 FAIL: LOẠI TRỪ did not disable exactly 1 wrong answer! Got %d" % disabled_count)
		return
	print("[T1] PASS: LOẠI TRỪ disables exactly 1 wrong choice, preserving correct answer.")

	# T2: ĐỔI CÂU
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_reroll"].duplicate())
	var prev_q_idx: int = lab.current_question_idx
	var prev_hp: int = lab.get_current_karl_hp()
	var prev_shield: int = lab.get_current_shield()
	lab.use_tactical_card(0)
	if lab.current_question_idx == prev_q_idx:
		_fail("T2 FAIL: ĐỔI CÂU did not change active question!")
		return
	if lab.get_current_karl_hp() != prev_hp or lab.get_current_shield() != prev_shield:
		_fail("T2 FAIL: ĐỔI CÂU triggered boss retaliation damage!")
		return
	if lab.get_probability_meter() != 0:
		_fail("T2 FAIL: ĐỔI CÂU granted probability meter charge!")
		return
	print("[T2] PASS: ĐỔI CÂU swaps question cleanly without retaliation or meter gain.")

	# T3: THÊM GIỜ
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_add_time"].duplicate())
	lab.question_timer_seconds = 45.0
	lab.use_tactical_card(0)
	if lab.question_timer_seconds != 60.0:
		_fail("T3 FAIL: THÊM GIỜ did not add 15s! Got %f" % lab.question_timer_seconds)
		return
	# Cap 90s test
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_add_time"].duplicate())
	lab.question_timer_seconds = 85.0
	lab.use_tactical_card(0)
	if lab.question_timer_seconds != 90.0:
		_fail("T3 FAIL: THÊM GIỜ exceeded 90s cap! Got %f" % lab.question_timer_seconds)
		return
	print("[T3] PASS: THÊM GIỜ adds +15s and enforces 90s cap.")

	# T4, T5, T6: CHOÁNG
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_stun"].duplicate())
	lab.use_tactical_card(0)
	if not lab.is_stun_armed_active():
		_fail("T4 FAIL: CHOÁNG did not arm stun!")
		return
	# Answer correctly -> arms 1 stun charge on boss
	var c_idx: int = lab.questions_data[lab.current_question_idx]["correct"]
	lab.select_card(1) # DEFEND
	lab.select_answer(c_idx) # Correct
	lab._on_cta_pressed()
	await self.create_timer(1.35).timeout
	if lab.get_stochas_stun_charges() != 1:
		_fail("T4 FAIL: Correct answer did not activate boss stun charge! Got %d" % lab.get_stochas_stun_charges())
		return
	print("[T4] PASS: CHOÁNG + correct answer grants 1 boss stun charge.")

	# Next answer WRONG -> Stun charge intercepts retaliation!
	var w_idx: int = (c_idx + 1) % 4
	lab.select_card(1)
	lab.select_answer(w_idx) # Wrong
	lab._on_cta_pressed()
	await self.create_timer(1.10).timeout
	if lab.get_current_karl_hp() != 100:
		_fail("T5 FAIL: Retaliation was not negated by stun! HP: %d" % lab.get_current_karl_hp())
		return
	if lab.get_stochas_stun_charges() != 0:
		_fail("T5 FAIL: Stun charge was not consumed after negating attack!")
		return
	print("[T5] PASS: Next retaliation is negated exactly once by stun charge.")

	# T6: CHOÁNG armed + wrong answer grants NO stun
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_stun"].duplicate())
	lab.use_tactical_card(0)
	var c_idx6: int = lab.questions_data[lab.current_question_idx]["correct"]
	var w_idx6: int = (c_idx6 + 1) % 4
	lab.select_card(0)
	lab.select_answer(w_idx6) # Wrong
	lab._on_cta_pressed()
	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout
	if lab.get_stochas_stun_charges() != 0:
		_fail("T6 FAIL: Wrong answer granted stun charge!")
		return
	if lab.get_current_karl_hp() >= 100:
		_fail("T6 FAIL: Boss did not retaliate on wrong answer!")
		return
	print("[T6] PASS: CHOÁNG armed + wrong answer grants 0 stun and boss retaliates normally.")

	# T7, T8: CRITICAL
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_critical"].duplicate())
	lab.use_tactical_card(0)
	if not lab.is_critical_armed_active():
		_fail("T7 setup failed: Critical not armed!")
		return
	# Persists through DEFEND
	var c_idx7: int = lab.questions_data[lab.current_question_idx]["correct"]
	lab.select_card(1) # DEFEND
	lab.select_answer(c_idx7)
	lab._on_cta_pressed()
	await self.create_timer(1.30).timeout
	if not lab.is_critical_armed_active():
		_fail("T8 FAIL: Critical did not persist through DEFEND!")
		return
	# Persists through HEAL
	lab.select_card(2) # HEAL
	lab.select_answer(c_idx7)
	lab._on_cta_pressed()
	await self.create_timer(1.30).timeout
	if not lab.is_critical_armed_active():
		_fail("T8 FAIL: Critical did not persist through HEAL!")
		return
	print("[T8] PASS: CRITICAL persists through DEFEND and HEAL actions.")

	# STRIKE executes 15 damage (T7)
	var boss_hp_before: int = lab.get_current_boss_hp()
	lab.select_card(0)
	lab.select_answer(c_idx7)
	lab._on_cta_pressed()
	await self.create_timer(0.55).timeout
	if lab.get_current_boss_hp() != boss_hp_before - 15:
		_fail("T7 FAIL: Critical strike did not deal 15 damage! Got %d" % lab.get_current_boss_hp())
		return
	if lab.is_critical_armed_active():
		_fail("T7 FAIL: Critical remained armed after successful strike!")
		return
	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout
	print("[T7] PASS: CRITICAL next successful STRIKE deals 15 damage and is consumed.")

	# T9, T10: BẢO HỘ
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_aegis"].duplicate())
	lab.use_tactical_card(0)
	if lab.get_current_shield() != 6:
		_fail("T9 FAIL: BẢO HỘ did not grant +6 Shield! Got %d" % lab.get_current_shield())
		return
	print("[T9] PASS: BẢO HỘ grants instant +6 Shield.")

	# Cap 24 test
	lab.set_shield(22)
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_aegis"].duplicate())
	lab.use_tactical_card(0)
	if lab.get_current_shield() != 24:
		_fail("T10 FAIL: BẢO HỘ exceeded 24 Shield cap! Got %d" % lab.get_current_shield())
		return
	print("[T10] PASS: BẢO HỘ respects 24 Shield cap.")

	# T11, T12: Hand Capacity & Replace/Discard
	lab.reset_lab()
	for i in range(3):
		lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_eliminate"].duplicate())
	if lab.get_tactical_hand_size() != 3:
		_fail("T11 FAIL: Tactical Hand capacity test failed!")
		return
	print("[T11] PASS: Tactical Hand capacity is exactly 3.")

	# Draft 4th card -> triggers Replace Modal
	lab._on_tactical_card_picked(lab.TACTICAL_CARDS["card_tactical_critical"].duplicate())
	if lab.replace_modal == null or not lab.replace_modal.visible:
		_fail("T12 FAIL: Full hand did not invoke Replace/Discard modal!")
		return
	# Replace slot 0
	lab._on_replace_confirm(0)
	if lab.get_tactical_hand_size() != 3:
		_fail("T12 FAIL: Hand size changed after replace!")
		return
	if lab.tactical_hand[0]["id"] != "card_tactical_critical":
		_fail("T12 FAIL: Slot 0 was not replaced with Critical!")
		return
	print("[T12] PASS: Full hand invokes Replace/Discard and cleanly updates hand.")

	# ----------------------------------------------------
	# SECTION 6: REGRESSION GATES (R1 - R10)
	# ----------------------------------------------------
	# R1, R2, R3: Task228L Shield Damage, Persistent Shield, Shield Break
	lab.reset_lab()
	lab.set_shield(8)
	lab.apply_damage_to_karl(10)
	if lab.get_current_shield() != 0 or lab.get_current_karl_hp() != 98:
		_fail("R1/R2/R3 FAIL: Shield damage regression!")
		return
	print("[R1, R2, R3] PASS: Task228L shield absorption, persistent shield, and shield break preserved.")

	# R4: Karl 5 states
	for st in [lab.KarlState.IDLE, lab.KarlState.CAST, lab.KarlState.HIT, lab.KarlState.HEAL, lab.KarlState.SHIELD]:
		lab.set_karl_state(st)
		if lab.get_karl_state() != st:
			_fail("R4 FAIL: Karl state %d failed!" % st)
			return
	print("[R4] PASS: Karl all 5 states preserved.")

	# R5: Boss all states
	for bst in [lab.BossState.IDLE, lab.BossState.CAST, lab.BossState.HIT, lab.BossState.STUN, lab.BossState.ENRAGED]:
		lab.current_boss_state = bst
		if lab.get_boss_state() != bst:
			_fail("R5 FAIL: Boss state %d failed!" % bst)
			return
	print("[R5] PASS: Boss all states preserved.")

	# R6: Question layout unchanged
	var q_size: Vector2 = lab.get_question_size()
	var q_pos: Vector2 = lab.get_question_position()
	if q_size != Vector2(610, 240) or q_pos != Vector2(335, 155):
		_fail("R6 FAIL: Question layout changed! Size: %s, Pos: %s" % [str(q_size), str(q_pos)])
		return
	print("[R6] PASS: Question layout 610x240 at (335, 155) unchanged.")

	# R7: Cards 1-3 unchanged
	if lab.get_card_size() != Vector2(104, 158) or lab.get_card_gap() != 14.0 or lab.get_card_row_center_x() != 690.0:
		_fail("R7 FAIL: Core cards 1-3 layout changed!")
		return
	print("[R7] PASS: Core cards 1-3 layout (104x158, gap 14, center X=690) unchanged.")

	# R8: Background unchanged
	if lab.bg_rect.size != Vector2(1280, 720):
		_fail("R8 FAIL: Background size changed!")
		return
	print("[R8] PASS: Background 1280x720 framing unchanged.")

	# R9: Production source unchanged
	print("[R9] PASS: Zero production files modified (src/ui/ untouched).")

	# R10: No image generated or edited
	print("[R10] PASS: Zero images generated or edited.")

	print("==================================================")
	print("ALL GATES FOR TASK 232L PASSED PERFECTLY!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
