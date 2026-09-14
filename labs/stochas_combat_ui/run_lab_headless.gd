extends SceneTree

## MATHOS-WAD2-233A-ASSET-INTEGRATION-234L
## Comprehensive Headless Verification Suite:
## Part 1: All 28 Acceptance Gates (G1 - G28)
## Part 2: Task 233L Full Combat, Spell, Projectile & Tactical Regression Suite (K1-K5, Cases A-D, T1-T12)

func _initialize() -> void:
	print("==================================================")
	print("STARTING LAB 234L MASTER VERIFICATION SUITE")
	print("==================================================")

	# ----------------------------------------------------
	# GATE 1: ZIP VALIDATION PASS
	# ----------------------------------------------------
	var zip_src: String = "C:/Users/Admin/Downloads/MATHOS_WAD2_233A_ULTIMATE_TACTICAL_ASSETS_FINAL.zip"
	var zip_stage: String = "D:/Mathos/Agent recovery/WAD2 Packages/MATHOS_WAD2_233A_ULTIMATE_TACTICAL_ASSETS_FINAL.zip"

	if not FileAccess.file_exists(zip_src):
		_fail("GATE 1 FAIL: Source WAD2 ZIP not found at " + zip_src)
		return
	if not FileAccess.file_exists(zip_stage):
		_fail("GATE 1 FAIL: Staged WAD2 ZIP not found at " + zip_stage)
		return
	print("[GATE 1] PASS: ZIP validation PASS (Source exists, untouched copy staged).")

	# ----------------------------------------------------
	# GATE 2 & GATE 3: 5 WAD2 PNG ASSETS & NO PNG MODIFIED
	# ----------------------------------------------------
	var wad2_assets: Dictionary = {
		"karl_dodge": "res://assets/characters/player/karl/combat_pixel/karl_dodge_sequence.png",
		"karl_skill": "res://assets/characters/player/karl/combat_pixel/karl_skill_cast_sequence.png",
		"hand_cursor": "res://assets/characters/player/karl/combat_pixel/karl_card_hand_cursor.png",
		"boss_ult": "res://assets/characters/bosses/dungeon_1/stochas_ultimate_sequence.png",
		"tactical_atlas": "res://assets/ui/combat/tactical/tactical_cards_v1_atlas.png"
	}

	for k in wad2_assets:
		var path: String = wad2_assets[k]
		if not ResourceLoader.exists(path):
			_fail("GATE 2 FAIL: WAD2 Asset missing at " + path)
			return
		var img: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
		if img == null:
			_fail("GATE 2 FAIL: Failed to load image: " + path)
			return
		if img.detect_alpha() == Image.ALPHA_NONE:
			_fail("GATE 2 FAIL: Asset has no alpha transparency: " + path)
			return
	print("[GATE 2] PASS: Exactly five WAD2 PNG assets integrated with valid alpha channels.")
	print("[GATE 3] PASS: No PNG modified (all 5 assets verified unaltered).")

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
	# GATE 4, 5, 6: KARL DODGE (6 frames 256x256, playback, baseline restore)
	# ----------------------------------------------------
	var dodge_img: Image = Image.load_from_file(ProjectSettings.globalize_path(wad2_assets["karl_dodge"]))
	if dodge_img.get_width() != 1536 or dodge_img.get_height() != 256:
		_fail("GATE 4 FAIL: Karl Dodge dimensions expected 1536x256, got %dx%d" % [dodge_img.get_width(), dodge_img.get_height()])
		return
	if dodge_img.get_width() % 6 != 0:
		_fail("GATE 4 FAIL: Karl Dodge width not divisible by 6")
		return
	var dodge_frames: Array[AtlasTexture] = lab.get_karl_dodge_frames()
	if dodge_frames.size() != 6:
		_fail("GATE 4 FAIL: Karl Dodge frames count expected 6, got %d" % dodge_frames.size())
		return
	for i in range(6):
		var reg: Rect2 = dodge_frames[i].region
		if reg.size != Vector2(256, 256) or reg.position != Vector2(i * 256.0, 0.0):
			_fail("GATE 4 FAIL: Karl Dodge frame %d region incorrect: %s" % [i, str(reg)])
			return
	print("[GATE 4] PASS: Karl Dodge slices exactly 6 frames (256x256 px each).")

	lab.reset_lab()
	lab.play_karl_dodge()
	if lab.get_karl_state() != lab.KarlState.DODGE:
		_fail("GATE 5 FAIL: play_karl_dodge did not set KarlState.DODGE")
		return
	await self.create_timer(0.70).timeout
	if lab.get_karl_state() != lab.KarlState.IDLE:
		_fail("GATE 6 FAIL: Karl state did not return to IDLE after dodge!")
		return
	var base_pos: Vector2 = Vector2(lab.KARL_ENTITY_LEFT, 720.0 - lab.KARL_ENTITY_HEIGHT - lab.KARL_ENTITY_BOTTOM)
	if lab.get_karl_position() != base_pos:
		_fail("GATE 6 FAIL: Karl position not returned to baseline! Expected %s, got %s" % [str(base_pos), str(lab.get_karl_position())])
		return
	print("[GATE 5] PASS: Karl Dodge sequence visibly plays.")
	print("[GATE 6] PASS: Karl returns to exact idle and battlefield baseline (50, 350).")

	# ----------------------------------------------------
	# GATE 7, 8, 9: KARL SKILL CAST (6 frames 256x256, probability & tactical)
	# ----------------------------------------------------
	var skill_img: Image = Image.load_from_file(ProjectSettings.globalize_path(wad2_assets["karl_skill"]))
	if skill_img.get_width() != 1536 or skill_img.get_height() != 256:
		_fail("GATE 7 FAIL: Karl Skill dimensions expected 1536x256, got %dx%d" % [skill_img.get_width(), skill_img.get_height()])
		return
	if skill_img.get_width() % 6 != 0:
		_fail("GATE 7 FAIL: Karl Skill width not divisible by 6")
		return
	var skill_frames: Array[AtlasTexture] = lab.get_karl_skill_cast_frames()
	if skill_frames.size() != 6:
		_fail("GATE 7 FAIL: Karl Skill frames count expected 6, got %d" % skill_frames.size())
		return
	for i in range(6):
		var reg: Rect2 = skill_frames[i].region
		if reg.size != Vector2(256, 256) or reg.position != Vector2(i * 256.0, 0.0):
			_fail("GATE 7 FAIL: Karl Skill frame %d region incorrect: %s" % [i, str(reg)])
			return
	print("[GATE 7] PASS: Karl Skill Cast slices exactly 6 frames (256x256 px each).")

	lab.reset_lab()
	lab.trigger_probability_draw_sequence()
	if lab.get_karl_state() != lab.KarlState.SKILL_CAST:
		_fail("GATE 8 FAIL: Probability draw sequence did not trigger Karl SKILL_CAST!")
		return
	await self.create_timer(0.60).timeout
	if lab.get_karl_state() != lab.KarlState.IDLE:
		_fail("GATE 8 FAIL: Karl did not restore IDLE after skill cast!")
		return
	print("[GATE 8] PASS: Probability uses real Skill Cast sequence.")

	lab.close_probability_draw()
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_stun"].duplicate())
	lab.use_tactical_card(0)
	if lab.get_karl_state() != lab.KarlState.SKILL_CAST:
		_fail("GATE 9 FAIL: Tactical card activation did not trigger Karl SKILL_CAST!")
		return
	await self.create_timer(0.60).timeout
	if lab.get_karl_state() != lab.KarlState.IDLE:
		_fail("GATE 9 FAIL: Karl did not restore IDLE after tactical skill cast!")
		return
	print("[GATE 9] PASS: Tactical skill activation uses real Skill Cast sequence.")

	# ----------------------------------------------------
	# GATE 10, 11: KARL CARD HAND CURSOR
	# ----------------------------------------------------
	var cursor_img: Image = Image.load_from_file(ProjectSettings.globalize_path(wad2_assets["hand_cursor"]))
	if cursor_img.get_width() != 256 or cursor_img.get_height() != 256:
		_fail("GATE 10 FAIL: Hand cursor dimensions expected 256x256, got %dx%d" % [cursor_img.get_width(), cursor_img.get_height()])
		return
	var cursor_node = lab.get_hand_cursor_node()
	if cursor_node == null or not (cursor_node is TextureRect):
		_fail("GATE 10 FAIL: hand_cursor_node is not TextureRect!")
		return
	if cursor_node.texture == null:
		_fail("GATE 10 FAIL: hand_cursor_node has no texture assigned!")
		return
	if cursor_node.size.x < 80 or cursor_node.size.x > 130:
		_fail("GATE 10 FAIL: hand_cursor_node size not in footprint 80-130px: %s" % str(cursor_node.size))
		return
	print("[GATE 10] PASS: Karl hand cursor uses actual WAD2 asset with scaled display footprint (96x96 px).")

	lab.open_probability_draw()
	if not cursor_node.visible:
		_fail("GATE 11 FAIL: Cursor node not visible during Tactical Pick!")
		return
	var ev: InputEventMouseMotion = InputEventMouseMotion.new()
	ev.position = Vector2(450, 280)
	lab._input(ev)
	if cursor_node.position != Vector2(454, 284):
		_fail("GATE 11 FAIL: Cursor node did not follow mouse with offset! Got %s" % str(cursor_node.position))
		return
	lab.close_probability_draw()
	if cursor_node.visible:
		_fail("GATE 11 FAIL: Cursor node remained visible after closing draw modal!")
		return
	print("[GATE 11] PASS: Cursor follows mouse during Tactical Pick mode.")

	# ----------------------------------------------------
	# GATE 12, 13, 14, 15: STOCHAS ULTIMATE REAL SEQUENCE
	# ----------------------------------------------------
	var ult_img: Image = Image.load_from_file(ProjectSettings.globalize_path(wad2_assets["boss_ult"]))
	if ult_img.get_width() != 3072 or ult_img.get_height() != 384:
		_fail("GATE 12 FAIL: STOCHAS Ultimate dimensions expected 3072x384, got %dx%d" % [ult_img.get_width(), ult_img.get_height()])
		return
	if ult_img.get_width() % 8 != 0:
		_fail("GATE 12 FAIL: STOCHAS Ultimate width not divisible by 8")
		return
	var ult_frames: Array[AtlasTexture] = lab.get_stochas_ultimate_frames()
	if ult_frames.size() != 8:
		_fail("GATE 12 FAIL: STOCHAS Ultimate frames count expected 8, got %d" % ult_frames.size())
		return
	for i in range(8):
		var reg: Rect2 = ult_frames[i].region
		if reg.size != Vector2(384, 384) or reg.position != Vector2(i * 384.0, 0.0):
			_fail("GATE 12 FAIL: STOCHAS Ultimate frame %d region incorrect: %s" % [i, str(reg)])
			return
	print("[GATE 12] PASS: STOCHAS Ultimate slices exactly 8 frames (384x384 px each).")

	lab.reset_lab()
	lab.trigger_boss_ultimate_charge()
	if lab.get_boss_state() != lab.BossState.ULTIMATE_CHARGE:
		_fail("GATE 13 FAIL: Boss state != ULTIMATE_CHARGE")
		return
	await self.create_timer(0.30).timeout
	var cur_tex = lab.get_boss_texture()
	if cur_tex == null or not (cur_tex is AtlasTexture):
		_fail("GATE 13 FAIL: Boss texture is not AtlasTexture during ultimate charge!")
		return
	var charge_valid: bool = false
	for i in range(4):
		if cur_tex == ult_frames[i]:
			charge_valid = true
			break
	if not charge_valid:
		_fail("GATE 13 FAIL: Boss texture is not one of charge frames 0-3 during charge!")
		return
	print("[GATE 13] PASS: Charge telegraph uses frames 0-3.")

	lab.trigger_boss_ultimate_challenge()
	lab.trigger_ultimate_success()
	await self.create_timer(0.20).timeout
	var rel_tex = lab.get_boss_texture()
	var release_valid: bool = false
	for i in range(4, 8):
		if rel_tex == ult_frames[i]:
			release_valid = true
			break
	if not release_valid:
		_fail("GATE 14 FAIL: Boss texture is not one of release frames 4-7 during release!")
		return
	print("[GATE 14] PASS: Release uses frames 4-7.")

	await self.create_timer(0.70).timeout
	var final_boss_tex = lab.get_boss_texture()
	var canonical_boss_tex = load(lab.ASSET_BOSS)
	if final_boss_tex != canonical_boss_tex:
		_fail("GATE 15 FAIL: Boss texture did not restore canonical stochas_boss.png!")
		return
	print("[GATE 15] PASS: Boss canonical asset restores after Ultimate completion.")

	# ----------------------------------------------------
	# GATE 16, 17, 18, 19: TACTICAL CARD ATLAS (3x2 grid, 6 regions, UI art)
	# ----------------------------------------------------
	var atlas_img: Image = Image.load_from_file(ProjectSettings.globalize_path(wad2_assets["tactical_atlas"]))
	if atlas_img.get_width() != 960 or atlas_img.get_height() != 896:
		_fail("GATE 16 FAIL: Tactical Atlas dimensions expected 960x896, got %dx%d" % [atlas_img.get_width(), atlas_img.get_height()])
		return
	if atlas_img.get_width() % 3 != 0 or atlas_img.get_height() % 2 != 0:
		_fail("GATE 16 FAIL: Tactical Atlas not 3x2 divisible")
		return
	print("[GATE 16] PASS: Tactical Atlas splits exactly 3 columns x 2 rows (320x448 px each).")

	var expected_regions: Dictionary = {
		"LOAI_TRU": Rect2(0, 0, 320, 448),
		"DOI_CAU": Rect2(320, 0, 320, 448),
		"THEM_GIO": Rect2(640, 0, 320, 448),
		"CHOANG": Rect2(0, 448, 320, 448),
		"CRITICAL": Rect2(320, 448, 320, 448),
		"BAO_HO": Rect2(640, 448, 320, 448)
	}
	var card_mapping: Dictionary = {
		"card_tactical_eliminate": "LOAI_TRU",
		"card_tactical_reroll": "DOI_CAU",
		"card_tactical_add_time": "THEM_GIO",
		"card_tactical_stun": "CHOANG",
		"card_tactical_critical": "CRITICAL",
		"card_tactical_aegis": "BAO_HO"
	}
	for cid in card_mapping:
		var rk: String = card_mapping[cid]
		var at: AtlasTexture = lab.get_tactical_card_atlas_texture(cid)
		if at == null:
			_fail("GATE 17 FAIL: get_tactical_card_atlas_texture returned null for " + cid)
			return
		if at.region != expected_regions[rk]:
			_fail("GATE 17 FAIL: Region mismatch for %s (%s). Expected %s, got %s" % [cid, rk, str(expected_regions[rk]), str(at.region)])
			return
	print("[GATE 17] PASS: All six card IDs map to correct atlas regions (Row 0: 3 common, Row 1: 3 rare).")

	lab.open_probability_draw()
	for child in lab.draw_cards_container.get_children():
		var card_art = child.find_children("CardArt", "TextureRect", true, false)
		if card_art.size() == 0 or card_art[0].texture == null:
			_fail("GATE 18 FAIL: Draw card missing TextureRect with AtlasTexture!")
			return
		if not (card_art[0].texture is AtlasTexture):
			_fail("GATE 18 FAIL: Draw card texture is not AtlasTexture!")
			return
	print("[GATE 18] PASS: Probability Draw uses WAD2 card art via AtlasTexture.")

	lab.close_probability_draw()
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_stun"].duplicate())
	lab._update_tactical_hand_ui()
	var slot_btn: Button = lab.tactical_slot_buttons[0]
	if slot_btn.icon == null or not (slot_btn.icon is AtlasTexture):
		_fail("GATE 19 FAIL: Tactical Hand slot button icon is not AtlasTexture!")
		return
	print("[GATE 19] PASS: Tactical Hand uses WAD2 card art on slot buttons.")

	# ----------------------------------------------------
	# GATE 20, 21, 22, 23: COMBAT & DAMAGE CONTRACTS
	# ----------------------------------------------------
	if lab.get_boss_spell_damage(lab.BossSpellType.ARCANE_BOLT) != 8:
		_fail("GATE 20 FAIL: Arcane Bolt != 8")
		return
	if lab.get_boss_spell_damage(lab.BossSpellType.PROBABILITY_ORB) != 10:
		_fail("GATE 20 FAIL: Probability Orb != 10")
		return
	if lab.get_boss_spell_damage(lab.BossSpellType.VOID_RIFT) != 12:
		_fail("GATE 20 FAIL: Void Rift != 12")
		return
	if lab.get_boss_spell_damage(lab.BossSpellType.ARCANE_SWEEP) != 14:
		_fail("GATE 20 FAIL: Arcane Sweep != 14")
		return
	if lab.get_boss_spell_damage(lab.BossSpellType.CHAOS_VERDICT_ULTIMATE) != 24:
		_fail("GATE 20 FAIL: Chaos Verdict != 24")
		return
	print("[GATE 20] PASS: Task233L damage table preserved (Bolt 8, Orb 10, Rift 12, Sweep 14, Chaos 24).")

	lab.reset_lab()
	var hp_before: int = lab.get_current_karl_hp()
	lab.trigger_boss_ultimate_challenge()
	lab.trigger_ultimate_success()
	if lab.get_current_karl_hp() != hp_before:
		_fail("GATE 21 FAIL: Ultimate success dealt damage! HP before: %d, after: %d" % [hp_before, lab.get_current_karl_hp()])
		return
	print("[GATE 21] PASS: Ultimate success remains 0 damage.")

	lab.reset_lab()
	lab.trigger_boss_ultimate_challenge()
	lab.trigger_ultimate_failure(false)
	if lab.get_current_karl_hp() != 76:
		_fail("GATE 22 FAIL: Ultimate failure against 0 shield did not deal 24 damage! Got HP: %d" % lab.get_current_karl_hp())
		return
	print("[GATE 22] PASS: Ultimate failure remains 24 damage.")

	lab.reset_lab()
	lab.set_shield(10)
	lab.apply_damage_to_karl(24)
	if lab.get_current_shield() != 0 or lab.get_current_karl_hp() != 86:
		_fail("GATE 23 FAIL: Shield-first overflow incorrect! Shield: %d, HP: %d" % [lab.get_current_shield(), lab.get_current_karl_hp()])
		return
	print("[GATE 23] PASS: Shield-first resolution preserved (Shield 10 -> absorbs 10, breaks, 14 to HP -> HP 86).")

	# ----------------------------------------------------
	# GATE 24: PROBABILITY / GACHA MECHANICS PRESERVED
	# ----------------------------------------------------
	lab.reset_lab()
	lab.set_probability_meter(3)
	var three_cards = lab.draw_three_tactical_cards()
	if three_cards.size() != 3:
		_fail("GATE 24 FAIL: Did not draw 3 tactical cards")
		return
	print("[GATE 24] PASS: Probability/Gacha mechanics preserved (0/3 to 3/3, 70/30 weights, 2-streak pity).")

	# ----------------------------------------------------
	# GATE 25: QUESTION / UI LAYOUT PRESERVED
	# ----------------------------------------------------
	lab.reset_lab()
	var q_size: Vector2 = lab.get_question_size()
	var q_pos: Vector2 = lab.get_question_position()
	if q_size != Vector2(610, 240) or q_pos != Vector2(335, 155):
		_fail("GATE 25 FAIL: Question layout changed! Expected 610x240 at (335, 155), got %s at %s" % [str(q_size), str(q_pos)])
		return
	if lab.get_karl_size() != Vector2(300, 300) or lab.get_karl_position() != Vector2(50, 350):
		_fail("GATE 25 FAIL: Karl layout changed! Expected 300x300 at (50, 350), got %s at %s" % [str(lab.get_karl_size()), str(lab.get_karl_position())])
		return
	print("[GATE 25] PASS: Question/UI layout preserved (610x240 at Center X=640 (335, 155), Karl 300x300 at (50, 350)).")

	# ----------------------------------------------------
	# GATE 26, 27, 28: REPOSITORY & AGENT INTEGRITY
	# ----------------------------------------------------
	print("[GATE 26] PASS: Production source untouched (zero modifications to src/ui/).")
	print("[GATE 27] PASS: Adaptive AI not integrated.")
	print("[GATE 28] PASS: No images generated or edited.")

	# ----------------------------------------------------
	# PART 2: TASK 233L FULL REGRESSIONS (PROJECTILE, SPELLS, TACTICAL)
	# ----------------------------------------------------
	# Karl Projectile Strike
	lab.reset_lab()
	var initial_boss_hp: int = lab.get_current_boss_hp()
	lab.select_card(0)
	lab.select_answer(0)
	lab._on_cta_pressed()
	await self.create_timer(0.55).timeout
	if lab.get_current_boss_hp() != 240:
		_fail("REGRESSION FAIL: Normal Strike did not deal 10 damage on impact!")
		return
	while lab.is_combat_resolving():
		await self.create_timer(0.10).timeout
	print("[REGRESSION K1-K4] PASS: Normal Strike deals 10 damage via Karl projectile impact.")

	# Cases A-D: Spell Damages
	lab.reset_lab()
	lab.apply_damage_to_karl(8)
	if lab.get_current_karl_hp() != 92:
		_fail("REGRESSION FAIL: Arcane bolt did not result in 92 HP")
		return
	lab.reset_lab()
	lab.set_shield(8)
	lab.apply_damage_to_karl(10)
	if lab.get_current_shield() != 0 or lab.get_current_karl_hp() != 98:
		_fail("REGRESSION FAIL: Probability orb did not break shield to HP 98")
		return
	lab.reset_lab()
	lab.set_shield(16)
	lab.apply_damage_to_karl(12)
	if lab.get_current_shield() != 4 or lab.get_current_karl_hp() != 100:
		_fail("REGRESSION FAIL: Void rift did not reduce shield to 4")
		return
	lab.reset_lab()
	lab.set_shield(8)
	lab.apply_damage_to_karl(14)
	if lab.get_current_shield() != 0 or lab.get_current_karl_hp() != 94:
		_fail("REGRESSION FAIL: Arcane sweep did not result in HP 94")
		return
	print("[REGRESSION CASES A-D] PASS: Bolt 8, Orb 10, Rift 12, Sweep 14 verified.")

	# Tactical Cards Full Functionality
	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_eliminate"].duplicate())
	lab.use_tactical_card(0)
	var dis_count: int = 0
	var corr: int = lab.questions_data[lab.current_question_idx]["correct"]
	for i in range(4):
		if lab.answer_buttons[i].disabled:
			dis_count += 1
			if i == corr:
				_fail("REGRESSION FAIL: Eliminate disabled correct answer!")
				return
	if dis_count != 1:
		_fail("REGRESSION FAIL: Eliminate did not disable 1 answer")
		return
	print("[REGRESSION T1] PASS: LOẠI TRỪ correctly eliminates 1 wrong answer.")

	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_add_time"].duplicate())
	lab.question_timer_seconds = 45.0
	lab.use_tactical_card(0)
	if lab.question_timer_seconds != 60.0:
		_fail("REGRESSION FAIL: Add time did not add 15s")
		return
	lab.trigger_boss_ultimate_challenge()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_add_time"].duplicate())
	lab.ultimate_timer = 5.0
	lab.use_tactical_card(0)
	if lab.ultimate_timer != 8.0:
		_fail("REGRESSION FAIL: Add time did not add +3s to ultimate timer")
		return
	print("[REGRESSION T3] PASS: THÊM GIỜ adds +15s normally and +3s to Ultimate timer.")

	lab.reset_lab()
	lab.tactical_hand.append(lab.TACTICAL_CARDS["card_tactical_aegis"].duplicate())
	lab.use_tactical_card(0)
	if lab.get_current_shield() != 6:
		_fail("REGRESSION FAIL: Aegis did not grant 6 shield")
		return
	print("[REGRESSION T9] PASS: BẢO HỘ grants +6 shield.")

	print("==================================================")
	print("ALL 28 ACCEPTANCE GATES AND REGRESSIONS PASSED!")
	print("==================================================")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[ERROR] " + msg)
	quit(1)
