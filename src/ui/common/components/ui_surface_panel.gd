class_name UiSurfacePanel
extends PanelContainer

## Shared panel/surface container primitive.
## Uses theme_type_variation for semantic styling across header, card, and overlay surfaces.

enum SurfaceStyle {
	DEFAULT,
	HEADER,
	CARD,
	OVERLAY
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
		SurfaceStyle.HEADER:
			theme_type_variation = &"SurfacePanelHeader"
		SurfaceStyle.CARD:
			theme_type_variation = &"SurfacePanelCard"
		SurfaceStyle.OVERLAY:
			theme_type_variation = &"SurfacePanelOverlay"
		_:
			theme_type_variation = &"SurfacePanel"
