class_name ComponentShowcase
extends Control

## Visual showcase for shared UI components at 1280x720 resolution.
## Tests readable text, layout bounds, hierarchy, focus states, and card/status variations.
## Operates cleanly with authoritative res://src/ui/theme/mathos_theme.tres.

const MATHOS_THEME_PATH: String = "res://src/ui/theme/mathos_theme.tres"

@onready var showcase_container: VBoxContainer = $MarginContainer/ScrollContainer/VBoxContainer

func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	if ResourceLoader.exists(MATHOS_THEME_PATH):
		var mathos_theme: Theme = load(MATHOS_THEME_PATH) as Theme
		if mathos_theme != null:
			theme = mathos_theme

func verify_all_components_instantiable() -> bool:
	var surface := UiSurfacePanel.new()
	var primary_btn := UiPrimaryButton.new()
	var secondary_btn := UiSecondaryButton.new()
	var destructive_btn := UiDestructiveButton.new()
	var option_card := UiOptionCard.new()
	var title_lbl := UiTitleLabel.new()
	var heading_lbl := UiHeadingLabel.new()
	var body_lbl := UiBodyLabel.new()
	var meta_lbl := UiMetaLabel.new()
	var status_banner := UiStatusBanner.new()
	var spacer := UiLayoutSpacer.new()

	var ok: bool = (
		surface != null and
		primary_btn != null and
		secondary_btn != null and
		destructive_btn != null and
		option_card != null and
		title_lbl != null and
		heading_lbl != null and
		body_lbl != null and
		meta_lbl != null and
		status_banner != null and
		spacer != null
	)

	surface.free()
	primary_btn.free()
	secondary_btn.free()
	destructive_btn.free()
	option_card.free()
	title_lbl.free()
	heading_lbl.free()
	body_lbl.free()
	meta_lbl.free()
	status_banner.free()
	spacer.free()

	return ok
