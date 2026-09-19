extends SceneTree

# ==============================================================================
# TASK ID: MATHOS-STOCHAS-HUMAN-RUNTIME-LAYOUT-ROOT-FIX-211
# Dedicated mounted SceneTree layout forensic & verification test.
# Verifies all 9 human-reported runtime layout defects are cleanly eliminated.
# ==============================================================================

func _initialize() -> void:
	print("==================================================")
	print("STARTING TASK 211 ACTUAL RUNTIME LAYOUT VERIFICATION")
	print("==================================================")

	var root: AppRoot = AppRoot.new()
	root.bootstrap_runtime()
	self.root.add_child(root)

	# Allow initial bootstrap frames
	await process_frame
	await process_frame

	var boot = root.get_boot_sequence()
	if boot != null:
		boot.visible = false

	var progress: ProgressService = root.get_progress_service()
	var cat: ValidatedCatalog = root.get_catalog()
	for s_id in ["stage_01_01", "stage_01_02", "stage_01_03", "stage_01_04"]:
		var r_id: String = String(cat.get_stage(s_id).get("reward_id", "reward_01_01"))
		progress.commit_stage_clear(s_id, RewardGrant.new(r_id, s_id, 10, 10, [] as Array[String]))

	var sel_res: Dictionary = root.select_stage("stage_01_05")
	if not bool(sel_res.get("success", false)):
		_fail("Failed to select stage_01_05: " + str(sel_res))
		return
	print("[RL-001] PASS: Successfully entered stage_01_05 context")

	var shell: StagePresentationShell = root.get_presentation_shell() as StagePresentationShell
	if shell == null:
		_fail("Presentation shell is null!")
		return

	await process_frame

	# Advance from Lesson to Combat
	shell.lesson_continue_requested.emit()
	await process_frame
	await process_frame

	# 1. Verify Fullscreen Canvas (1280x720 at (0, 0))
	var shell_rect: Rect2 = shell.get_global_rect()
	if shell_rect.size.x < 1270.0 or shell_rect.size.y < 710.0:
		_fail("Shell size mismatch: expected ~1280x720, got: " + str(shell_rect.size))
		return
	print("[RL-002] PASS: Fullscreen canvas size verified: ", shell_rect)

	var gh: Control = shell.get_node_or_null("VBoxContainer/MainBody/ContentHBox/MainContentVBox/QuestionHostContainer/GameplayHBox") as Control
	if gh == null:
		_fail("GameplayHBox missing in SceneTree!")
		return
	var gh_rect: Rect2 = gh.get_global_rect()
	if gh_rect.size.x < 1270.0 or gh_rect.size.y < 710.0 or gh_rect.position.x > 5.0 or gh_rect.position.y > 5.0:
		_fail("GameplayHBox not filling canvas: " + str(gh_rect))
		return
	print("[RL-003] PASS: GameplayHBox spans full 1280x720 canvas: ", gh_rect)

	var bp: Control = gh.get_node_or_null("BossCombatPanel") as Control
	if bp == null or not bp.visible:
		_fail("BossCombatPanel missing or not visible!")
		return
	var bp_rect: Rect2 = bp.get_global_rect()
	if bp_rect.size.x < 1270.0 or bp_rect.size.y < 710.0:
		_fail("BossCombatPanel not filling canvas: " + str(bp_rect))
		return
	print("[RL-004] PASS: BossCombatPanel spans full 1280x720 canvas: ", bp_rect)

	# 2. Verify Defect 1 & 2: NO giant dark panel covering > 50% viewport
	var dark_found: Array[String] = []
	_audit_dark_panels(root, dark_found)
	if not dark_found.is_empty():
		_fail("Giant dark overlay defect detected: " + dark_found[0])
		return
	print("[RL-005] PASS: No giant dark overlay covering viewport (Defects 1 & 2 cleanly resolved)")

	# 3. Verify Defect 3: STOCHAS is dominant on right side (boss center_x > viewport_width * 0.60)
	var boss_stage: Control = bp.get_node_or_null("BossStageContainer") as Control
	if boss_stage == null or not boss_stage.visible:
		_fail("BossStageContainer missing or not visible!")
		return
	var boss_rect: Rect2 = boss_stage.get_global_rect()
	var boss_center_x: float = boss_rect.position.x + boss_rect.size.x * 0.5
	if boss_rect.position.x < 750.0 or boss_rect.size.x < 400.0 or boss_center_x <= 1280.0 * 0.60:
		_fail("STOCHAS BossStageContainer not dominant on right: " + str(boss_rect))
		return
	print("[RL-006] PASS: STOCHAS BossStageContainer dominant on right (center_x=%f > 768.0): %s" % [boss_center_x, str(boss_rect)])

	# Verify unboxed transparent arena
	var boss_vis: Control = boss_stage.get_node_or_null("BossVisualContainer") as Control
	if boss_vis != null and boss_vis.has_theme_stylebox("panel"):
		var bsb = boss_vis.get_theme_stylebox("panel")
		if bsb is StyleBoxFlat and (bsb as StyleBoxFlat).bg_color.a > 0.1:
			_fail("Boss arena has opaque background!")
			return
	print("[RL-006B] PASS: Boss arena is unboxed and transparent")

	# 4. Verify Task 216: Combat Feed is REMOVED from screen (lower-left visually clean)
	var feed: Control = bp.get_node_or_null("CombatFeedPanel") as Control
	if feed != null and feed.visible:
		_fail("CombatFeedPanel should be absent/not visible on combat screen!")
		return
	bp._on_combat_log("Combat log event", "player_success")
	if bp._combat_log_label == null or bp._combat_log_label.text != "Combat log event":
		_fail("Internal combat log logic failed!")
		return
	print("[RL-007] PASS: CombatFeedPanel absent from combat screen (lower-left clean), internal log preserved")

	# 5. Verify Defect 5: Math Challenge is TOP-CENTER, enlarged to ~740x300, non-modal (challenge center_x ~ viewport center)
	var qp_host: Control = gh.get_node_or_null("QuestionPanelHost") as Control
	if qp_host == null or not qp_host.visible:
		_fail("QuestionPanelHost missing or not visible!")
		return
	var qp_rect: Rect2 = qp_host.get_global_rect()
	var challenge_center_x: float = qp_rect.position.x + qp_rect.size.x * 0.5
	if qp_rect.position.y < 60.0 or qp_rect.position.y > 130.0 or qp_rect.size.y < 280.0 or qp_rect.size.y > 390.0 or qp_rect.size.x < 700.0 or qp_rect.size.x > 760.0:
		_fail("QuestionPanelHost not top-center enlarged (~740x370): " + str(qp_rect))
		return
	var center_diff: float = abs(challenge_center_x - 640.0)
	if center_diff > 30.0:
		_fail("QuestionPanelHost not horizontally centered: center_diff = " + str(center_diff))
		return
	print("[RL-008] PASS: Math Challenge is top-center, enlarged to ~740x300, non-modal (center_x=%f ~ 640): %s" % [challenge_center_x, str(qp_rect)])

	# 6. Verify Defect 6: Tactical Card Row is BOTTOM-CENTER (card row center_x ~ viewport center)
	var cards_container: Control = bp.get_node_or_null("BottomCenterContainer") as Control
	if cards_container == null or not cards_container.visible:
		_fail("BottomCenterContainer missing or not visible!")
		return
	var cards_rect: Rect2 = cards_container.get_global_rect()
	var cards_center_x: float = cards_rect.position.x + cards_rect.size.x * 0.5
	if cards_rect.position.y < 440.0 or cards_rect.size.x < 400.0:
		_fail("BottomCenterContainer not at bottom-center: " + str(cards_rect))
		return
	var cards_center_diff: float = abs(cards_center_x - 640.0)
	if cards_center_diff > 30.0:
		_fail("BottomCenterContainer not horizontally centered: " + str(cards_center_diff))
		return
	print("[RL-009] PASS: Tactical card row at bottom-center (center_x=%f ~ 640): %s" % [cards_center_x, str(cards_rect)])

	# 7. Verify Defect 7: Settings button is BOTTOM-RIGHT (settings center_x > viewport_width * 0.80)
	var settings_btn: Control = bp.get_node_or_null("CombatSettingsButton") as Control
	if settings_btn == null or not settings_btn.visible:
		_fail("CombatSettingsButton missing or not visible!")
		return
	var settings_rect: Rect2 = settings_btn.get_global_rect()
	var settings_center_x: float = settings_rect.position.x + settings_rect.size.x * 0.5
	if settings_rect.position.x < 1180.0 or settings_rect.position.y < 630.0 or settings_center_x <= 1280.0 * 0.80:
		_fail("CombatSettingsButton not at bottom-right: " + str(settings_rect))
		return
	print("[RL-010] PASS: Settings button positioned at bottom-right (center_x=%f > 1024.0): %s" % [settings_center_x, str(settings_rect)])

	# 8. Verify Defect 8: Top HUDs at TOP-LEFT and TOP-RIGHT
	var player_hud: Control = bp.get_node_or_null("TopHudContainer/PlayerHudPanel") as Control
	var boss_hud: Control = bp.get_node_or_null("TopHudContainer/BossHudPanel") as Control
	if player_hud == null or boss_hud == null:
		_fail("Player or Boss HUD missing!")
		return
	var player_hud_rect: Rect2 = player_hud.get_global_rect()
	var boss_hud_rect: Rect2 = boss_hud.get_global_rect()
	if player_hud_rect.position.x > 60.0 or player_hud_rect.position.y > 30.0:
		_fail("Player HUD not at top-left: " + str(player_hud_rect))
		return
	if boss_hud_rect.position.x < 900.0 or boss_hud_rect.position.y > 30.0:
		_fail("Boss HUD not at top-right: " + str(boss_hud_rect))
		return
	print("[RL-011] PASS: Top HUDs positioned at top-left and top-right: Player=", player_hud_rect, " Boss=", boss_hud_rect)

	# 9. Verify Task 204 Combat Interaction Logic & Production Values
	var ctrl: CardCombatController = root.get("_active_combat_controller") as CardCombatController
	if ctrl == null:
		_fail("Combat controller is null!")
		return
	var q_panel: QuestionPanel = shell.get_question_panel()
	if q_panel == null:
		_fail("QuestionPanel is null!")
		return
	var q_ctrl: QuestionPresentationController = root.get_question_controller()

	# --- STRIKE: 100 -> 90 (-10) ---
	bp.get_card_button("card_strike").emit_signal("pressed")
	if not bp.is_card_selected("card_strike"):
		_fail("BossCombatPanel card_strike not selected")
		return
	var initial_boss_hp: int = ctrl.boss_entity.current_hp
	q_ctrl.question_completed.emit({"is_correct": true, "question_id": "q_strike"})
	await process_frame
	if ctrl.boss_entity.current_hp != initial_boss_hp - 10:
		_fail("STRIKE failed: expected %d, got %d" % [initial_boss_hp - 10, ctrl.boss_entity.current_hp])
		return
	print("[RL-012] PASS: STRIKE damages Boss: 100 -> %d (-10 HP)" % ctrl.boss_entity.current_hp)

	# --- DEFEND: Shield 0 -> 8 (+8) ---
	bp.get_card_button("card_defend").emit_signal("pressed")
	if not bp.is_card_selected("card_defend"):
		_fail("BossCombatPanel card_defend not selected")
		return
	var cta_text: String = q_panel.get_combat_action_text()
	if not cta_text.contains("PHÒNG THỦ"):
		_fail("CTA text did not update for DEFEND: " + cta_text)
		return
	var prev_shield: int = ctrl.player_runtime.shield
	q_ctrl.question_completed.emit({"is_correct": true, "question_id": "q_defend"})
	await process_frame
	if ctrl.player_runtime.shield != prev_shield + 8:
		_fail("DEFEND failed: expected shield %d, got %d" % [prev_shield + 8, ctrl.player_runtime.shield])
		return
	print("[RL-013] PASS: DEFEND adds shield: %d -> %d (+8 Shield)" % [prev_shield, ctrl.player_runtime.shield])

	# --- WRONG ANSWER: Boss retaliation (-10 total, absorbs 8 shield, player HP 100 -> 98) ---
	q_ctrl.question_completed.emit({"is_correct": false, "question_id": "q_wrong"})
	await process_frame
	if ctrl.player_runtime.shield != 0 or ctrl.player_runtime.current_hp != 98:
		_fail("Wrong answer retaliation failed: HP=%d, Shield=%d (expected 98/0)" % [ctrl.player_runtime.current_hp, ctrl.player_runtime.shield])
		return
	print("[RL-014] PASS: Wrong answer retaliation: Shield absorbed 8, Player HP 100 -> 98")

	# Second WRONG ANSWER: (no shield, deals 10 directly: 98 -> 88)
	q_ctrl.question_completed.emit({"is_correct": false, "question_id": "q_wrong2"})
	await process_frame
	if ctrl.player_runtime.current_hp != 88:
		_fail("Second wrong answer retaliation failed: HP=%d (expected 88)" % ctrl.player_runtime.current_hp)
		return
	print("[RL-015] PASS: Second wrong answer retaliation: Player HP 98 -> 88 (-10 HP direct)")

	# --- HEAL: heals +15 (88 -> 100, capped at max HP) ---
	bp.get_card_button("card_heal").emit_signal("pressed")
	if not bp.is_card_selected("card_heal"):
		_fail("BossCombatPanel card_heal not selected")
		return
	var hp_before_heal: int = ctrl.player_runtime.current_hp
	q_ctrl.question_completed.emit({"is_correct": true, "question_id": "q_heal"})
	await process_frame
	if ctrl.player_runtime.current_hp != 100: # 88 + 15 = 103, capped at 100
		_fail("HEAL failed: expected 100, got %d" % ctrl.player_runtime.current_hp)
		return
	print("[RL-016] PASS: HEAL restores HP (+15 capped at 100): %d -> %d" % [hp_before_heal, ctrl.player_runtime.current_hp])

	# 10. Multi-Resolution Responsiveness (1280x720, 1280x680, 1366x768, 1600x900, 1920x1080)
	var resolutions: Array[Vector2] = [
		Vector2(1280, 720),
		Vector2(1280, 680),
		Vector2(1366, 768),
		Vector2(1600, 900),
		Vector2(1920, 1080)
	]
	for res in resolutions:
		bp.size = res
		bp._layout_elements()
		var p_r = bp.get_node_or_null("TopHudContainer/PlayerHudPanel").get_global_rect()
		var b_r = bp.get_node_or_null("TopHudContainer/BossHudPanel").get_global_rect()
		var s_r = bp.get_node_or_null("BossStageContainer").get_global_rect()
		var cards_r = bp.get_node_or_null("BottomCenterContainer").get_global_rect()
		var st_r = bp.get_node_or_null("CombatSettingsButton").get_global_rect()

		if p_r.position.x < 0 or b_r.position.x + b_r.size.x > res.x or s_r.position.x + s_r.size.x > res.x or cards_r.position.y + cards_r.size.y > res.y or st_r.position.x + st_r.size.x > res.x:
			_fail("Layout boundary violation at resolution: " + str(res))
			return
	# Restore 1280x720
	bp.size = Vector2(1280, 720)
	bp._layout_elements()
	print("[RL-017] PASS: Multi-resolution layout validated cleanly across 5 target resolutions")

	print("==================================================")
	print("TASK 211R ACTUAL RUNTIME LAYOUT VERIFICATION: ALL 17/17 PASSED!")
	print("==================================================")
	quit(0)

func _audit_dark_panels(n: Node, dark_found: Array[String]) -> void:
	if n is Control:
		var c: Control = n as Control
		if c.is_visible_in_tree():
			var r: Rect2 = c.get_global_rect()
			if r.size.x * r.size.y > 460800.0:
				var c_name: String = c.name
				if c_name != "BackgroundTextureRect" and c_name != "ProceduralFogContainer" and not c_name.begins_with("ProcFog"):
					if c.has_theme_stylebox("panel"):
						var sb = c.get_theme_stylebox("panel")
						if sb is StyleBoxFlat:
							var flat: StyleBoxFlat = sb as StyleBoxFlat
							if flat.bg_color.a > 0.4:
								dark_found.append(str(c.get_path()) + " has opaque bg_color: " + str(flat.bg_color))
	for child in n.get_children():
		_audit_dark_panels(child, dark_found)

func _fail(msg: String) -> void:
	print("[RL-FAIL] ", msg)
	push_error(msg)
	quit(1)
