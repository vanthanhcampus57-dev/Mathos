class_name UiSurfacePanel
extends PanelContainer

## Shared panel/surface container primitive.
## Consumes authoritative Mathos Theme variations for primary, secondary, card, elevated, and modal surfaces.

enum SurfaceStyle {
	DEFAULT,
	SECONDARY,
	CARD,
	ELEVATED,
	MODAL
}

@export var surface_style: SurfaceStyle = SurfaceStyle.DEFAULT:
	set(value):
		surface_style = value
		_update_surface_variation()

func _init() -> void:
	_update_surface_variation()

func _ready() -> void:
	_update_surface_variation()

func _update_surface_variation() -> void:
	match surface_style:
		SurfaceStyle.SECONDARY:
			theme_type_variation = &"MathosPanelSecondary"
		SurfaceStyle.CARD:
			theme_type_variation = &"MathosCard"
		SurfaceStyle.ELEVATED:
			theme_type_variation = &"MathosPanelElevated"
		SurfaceStyle.MODAL:
			theme_type_variation = &"MathosPanelModal"
		_:
			theme_type_variation = &"MathosPanelPrimary"
