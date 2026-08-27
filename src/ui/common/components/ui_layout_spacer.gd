class_name UiLayoutSpacer
extends Control

## Shared layout spacing helper.
## Provides standardized spacing elements between containers without hardcoded script margins.

enum SpacerSize {
	SMALL,
	MEDIUM,
	LARGE,
	EXTRA_LARGE
}

@export var spacer_size: SpacerSize = SpacerSize.MEDIUM:
	set(value):
		spacer_size = value
		_update_spacer_size()

func _ready() -> void:
	_update_spacer_size()

func _update_spacer_size() -> void:
	var dim: float = 16.0
	match spacer_size:
		SpacerSize.SMALL:
			dim = 8.0
		SpacerSize.MEDIUM:
			dim = 16.0
		SpacerSize.LARGE:
			dim = 24.0
		SpacerSize.EXTRA_LARGE:
			dim = 32.0

	custom_minimum_size = Vector2(dim, dim)
