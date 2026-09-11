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

	# 3. Verify Defect 3: STOCHAS is dominant on right side
	var boss_stage: Control = bp.get_node_or_null("BossStageContainer") as Control
	if boss_stage == null or not boss_stage.visible:
		_fail("BossStageContainer missing or not visible!")
		return
	var boss_rect: Rect2 = boss_stage.get_global_rect()
	if boss_rect.position.x < 750.0 or boss_rect.size.x < 400.0:
		_fail("STOCHAS BossStageContainer not dominant on right: " + str(boss_rect))
		return
	print("[RL-006] PASS: STOCHAS BossStageContainer dominant on right: ", boss_rect)

	# 4. Verify Defect 4: Combat Feed is at BOTTOM-LEFT
	var feed: Control = bp.get_node_or_null("CombatFeedPanel") as Control
	if feed == null or not feed.visible:
		_fail("CombatFeedPanel missing or not visible!")
		return
	var feed_rect: Rect2 = feed.get_global_rect()
	if feed_rect.position.y < 500.0 or feed_rect.position.x > 60.0 or feed_rect.size.x > 320.0 or feed_rect.size.y > 180.0:
		_fail("CombatFeedPanel not in bottom-left: " + str(feed_rect))
		return
	print("[RL-007] PASS: CombatFeedPanel positioned at bottom-left: ", feed_rect)

	# 5. Verify Defect 5: Math Challenge is TOP-CENTER and compact
	var qp_host: Control = gh.get_node_or_null("QuestionPanelHost") as Control
	if qp_host == null or not qp_host.visible:
		_fail("QuestionPanelHost missing or not visible!")
		return
	var qp_rect: Rect2 = qp_host.get_global_rect()
	if qp_rect.position.y < 60.0 or qp_rect.position.y > 130.0 or qp_rect.size.y > 360.0 or qp_rect.size.x < 460.0 or qp_rect.size.x > 600.0:
		_fail("QuestionPanelHost not top-center compact: " + str(qp_rect))
		return
	var center_diff: float = abs((qp_rect.position.x + qp_rect.size.x * 0.5) - 640.0)
	if center_diff > 40.0:
		_fail("QuestionPanelHost not horizontally centered: center_diff = " + str(center_diff))
		return
	print("[RL-008] PASS: Math Challenge is top-center, compact, non-modal: ", qp_rect)

	# 6. Verify Defect 6: Tactical Card Row is BOTTOM-CENTER
	var cards_container: Control = bp.get_node_or_null("BottomCenterContainer") as Control
	if cards_container == null or not cards_container.visible:
		_fail("BottomCenterContainer missing or not visible!")
		return
	var cards_rect: Rect2 = cards_container.get_global_rect()
	if cards_rect.position.y < 480.0 or cards_rect.size.x < 400.0:
		_fail("BottomCenterContainer not at bottom-center: " + str(cards_rect))
		return
	var cards_center_diff: float = abs((cards_rect.position.x + cards_rect.size.x * 0.5) - 640.0)
	if cards_center_diff > 40.0:
		_fail("BottomCenterContainer not horizontally centered: " + str(cards_center_diff))
		return
	print("[RL-009] PASS: Tactical card row at bottom-center: ", cards_rect)

	# 7. Verify Defect 7: Settings button is BOTTOM-RIGHT
	var settings_btn: Control = bp.get_node_or_null("CombatSettingsButton") as Control
	if settings_btn == null or not settings_btn.visible:
		_fail("CombatSettingsButton missing or not visible!")
		return
	var settings_rect: Rect2 = settings_btn.get_global_rect()
	if settings_rect.position.x < 1180.0 or settings_rect.position.y < 630.0:
		_fail("CombatSettingsButton not at bottom-right: " + str(settings_rect))
		return
	print("[RL-010] PASS: Settings button positioned at bottom-right: ", settings_rect)

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

	# 9. Verify Task 204 Combat Interaction Logic
	var ctrl: CardCombatController = root.get("_active_combat_controller") as CardCombatController
	if ctrl == null:
		_fail("Combat controller is null!")
		return
	var q_panel: QuestionPanel = shell.get_question_panel()
	if q_panel == null:
		_fail("QuestionPanel is null!")
		return

	# Card selection
	bp.get_card_button("card_defend").emit_signal("pressed")
	if not bp.is_card_selected("card_defend"):
		_fail("BossCombatPanel card_defend not selected")
		return
	var cta_text: String = q_panel.get_combat_action_text()
	if not cta_text.contains("PHÒNG THỦ"):
		_fail("CTA text did not update for DEFEND: " + cta_text)
		return
	print("[RL-012] PASS: Card switching DEFEND updates controller and CTA: ", cta_text)

	# Answer resolution: correct DEFEND adds shield
	var p_rt: PlayerRuntime = ctrl.player_runtime
	var prev_shield: int = p_rt.shield
	var q_ctrl: QuestionPresentationController = root.get_question_controller()
	q_ctrl.question_completed.emit({"is_correct": true, "question_id": "q_test"})
	await process_frame
	var new_shield: int = p_rt.shield
	if new_shield <= prev_shield:
		_fail("DEFEND did not increase shield: prev=" + str(prev_shield) + " new=" + str(new_shield))
		return
	print("[RL-013] PASS: Correct answer with DEFEND increases shield: ", prev_shield, " -> ", new_shield)

	print("==================================================")
	print("TASK 211 ACTUAL RUNTIME LAYOUT VERIFICATION: ALL 13/13 PASSED!")
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
