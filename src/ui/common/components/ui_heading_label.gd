class_name UiHeadingLabel
extends Label

## Shared heading label primitive.
## Consumes authoritative Mathos Theme variation "MathosHeading".

func _init() -> void:
	theme_type_variation = &"MathosHeading"

func _ready() -> void:
	theme_type_variation = &"MathosHeading"
