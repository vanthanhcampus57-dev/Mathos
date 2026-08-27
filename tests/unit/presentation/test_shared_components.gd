class_name TestSharedComponents
extends SceneTree

## Unit test suite for shared reusable UI components aligned to accepted Mathos Theme contract.
## Verifies instantiation, state transitions, Mathos theme_type_variation resolution, and domain-neutral contracts.

func _init() -> void:
	var success: bool = run_all_tests()
	quit(0 if success else 1)

static func run_all_tests() -> bool:
	print("--- RUNNING SHARED REUSABLE UI COMPONENTS SUITE (MATHOS THEME CONTRACT) ---")
	var success: bool = true

	success = test_surface_panel() and success
	success = test_primary_button() and success
	success = test_secondary_button() and success
	success = test_destructive_button() and success
	success = test_option_card() and success
	success = test_typography_labels() and success
	success = test_status_banner() and success
	success = test_layout_spacer() and success
	success = test_component_showcase() and success

	return success

static func test_surface_panel() -> bool:
	var panel := UiSurfacePanel.new()
	if panel.theme_type_variation != &"MathosPanelPrimary":
		print("[FAIL] UiSurfacePanel default variation mismatch: %s" % String(panel.theme_type_variation))
		panel.free()
		return false

	panel.surface_style = UiSurfacePanel.SurfaceStyle.CARD
	if panel.theme_type_variation != &"MathosCard":
		print("[FAIL] UiSurfacePanel CARD variation mismatch: %s" % String(panel.theme_type_variation))
		panel.free()
		return false

	panel.surface_style = UiSurfacePanel.SurfaceStyle.ELEVATED
	if panel.theme_type_variation != &"MathosPanelElevated":
		print("[FAIL] UiSurfacePanel ELEVATED variation mismatch: %s" % String(panel.theme_type_variation))
		panel.free()
		return false

	panel.free()
	print("[UI-COMPONENTS-001] UiSurfacePanel (MathosPanelPrimary / MathosCard / MathosPanelElevated)... PASS")
	return true

static func test_primary_button() -> bool:
	var btn := UiPrimaryButton.new()
	btn._ready()
	if btn.theme_type_variation != &"MathosPrimaryButton":
		print("[FAIL] UiPrimaryButton theme_type_variation mismatch: %s" % String(btn.theme_type_variation))
		btn.free()
		return false

	btn.action_text = "Submit"
	if btn.text != "Submit":
		print("[FAIL] UiPrimaryButton action_text failed to update text")
		btn.free()
		return false

	btn.free()
	print("[UI-COMPONENTS-002] UiPrimaryButton (MathosPrimaryButton)... PASS")
	return true

static func test_secondary_button() -> bool:
	var btn := UiSecondaryButton.new()
	btn._ready()
	if btn.theme_type_variation != &"MathosSecondaryButton":
		print("[FAIL] UiSecondaryButton theme_type_variation mismatch: %s" % String(btn.theme_type_variation))
		btn.free()
		return false

	btn.action_text = "Cancel"
	if btn.text != "Cancel":
		print("[FAIL] UiSecondaryButton action_text failed to update text")
		btn.free()
		return false

	btn.free()
	print("[UI-COMPONENTS-003] UiSecondaryButton (MathosSecondaryButton)... PASS")
	return true

static func test_destructive_button() -> bool:
	var btn := UiDestructiveButton.new()
	btn._ready()
	if btn.theme_type_variation != &"MathosDestructiveButton":
		print("[FAIL] UiDestructiveButton theme_type_variation mismatch: %s" % String(btn.theme_type_variation))
		btn.free()
		return false

	btn.action_text = "Delete"
	if btn.text != "Delete":
		print("[FAIL] UiDestructiveButton action_text failed to update text")
		btn.free()
		return false

	btn.free()
	print("[UI-COMPONENTS-004] UiDestructiveButton (MathosDestructiveButton)... PASS")
	return true

static func test_option_card() -> bool:
	var card := UiOptionCard.new()
	card._ready()
	if card.theme_type_variation != &"MathosOption":
		print("[FAIL] UiOptionCard default theme_type_variation mismatch: %s" % String(card.theme_type_variation))
		card.free()
		return false

	card.set_selected(true)
	if card.card_state != UiOptionCard.CardVisualState.SELECTED:
		print("[FAIL] UiOptionCard set_selected failed to update card_state")
		card.free()
		return false

	card.set_feedback(true)
	if card.card_state != UiOptionCard.CardVisualState.CORRECT:
		print("[FAIL] UiOptionCard set_feedback(true) failed to set CORRECT state")
		card.free()
		return false

	card.set_feedback(false)
	if card.card_state != UiOptionCard.CardVisualState.INCORRECT:
		print("[FAIL] UiOptionCard set_feedback(false) failed to set INCORRECT state")
		card.free()
		return false

	card.free()
	print("[UI-COMPONENTS-005] UiOptionCard MathosOption state transitions... PASS")
	return true

static func test_typography_labels() -> bool:
	var title := UiTitleLabel.new()
	title._ready()
	var heading := UiHeadingLabel.new()
	heading._ready()
	var body := UiBodyLabel.new()
	body._ready()
	var meta := UiMetaLabel.new()
	meta._ready()

	var ok: bool = (
		title.theme_type_variation == &"MathosTitle" and
		heading.theme_type_variation == &"MathosHeading" and
		body.theme_type_variation == &"MathosBody" and
		meta.theme_type_variation == &"MathosMeta"
	)

	title.free()
	heading.free()
	body.free()
	meta.free()

	if not ok:
		print("[FAIL] Typography labels theme_type_variation mismatch")
		return false

	print("[UI-COMPONENTS-006] Typography Labels (MathosTitle, MathosHeading, MathosBody, MathosMeta)... PASS")
	return true

static func test_status_banner() -> bool:
	var banner := UiStatusBanner.new()
	banner._ready()
	if banner.theme_type_variation != &"MathosPanelSecondary":
		print("[FAIL] UiStatusBanner default panel variation mismatch: %s" % String(banner.theme_type_variation))
		banner.free()
		return false

	banner.show_status(UiStatusBanner.StatusType.SUCCESS, "Great", "Success message")
	if banner.theme_type_variation != &"MathosPanelElevated":
		print("[FAIL] UiStatusBanner SUCCESS panel variation mismatch: %s" % String(banner.theme_type_variation))
		banner.free()
		return false

	banner.show_status(UiStatusBanner.StatusType.ERROR, "Error", "Error message")
	if banner.theme_type_variation != &"MathosPanelElevated":
		print("[FAIL] UiStatusBanner ERROR panel variation mismatch: %s" % String(banner.theme_type_variation))
		banner.free()
		return false

	banner.free()
	print("[UI-COMPONENTS-007] UiStatusBanner (MathosPanelSecondary / MathosPanelElevated / MathosSuccess / MathosError)... PASS")
	return true

static func test_layout_spacer() -> bool:
	var spacer := UiLayoutSpacer.new()
	spacer._ready()
	if spacer.custom_minimum_size != Vector2(16, 16):
		print("[FAIL] UiLayoutSpacer default MEDIUM size mismatch")
		spacer.free()
		return false

	spacer.spacer_size = UiLayoutSpacer.SpacerSize.LARGE
	if spacer.custom_minimum_size != Vector2(24, 24):
		print("[FAIL] UiLayoutSpacer LARGE size mismatch")
		spacer.free()
		return false

	spacer.free()
	print("[UI-COMPONENTS-008] UiLayoutSpacer... PASS")
	return true

static func test_component_showcase() -> bool:
	var showcase := ComponentShowcase.new()
	if not showcase.verify_all_components_instantiable():
		print("[FAIL] ComponentShowcase failed to verify all components")
		showcase.free()
		return false

	showcase.free()
	print("[UI-COMPONENTS-009] ComponentShowcase (1280x720)... PASS")
	return true
