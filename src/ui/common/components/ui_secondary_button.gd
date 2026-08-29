class_name UiSecondaryButton
extends Button

## Shared secondary action button primitive.
## Consumes authoritative Mathos Theme variation "MathosSecondaryButton".

@export var action_text: String = "Secondary":
	set(value):
		action_text = value
		text = action_text

func _init() -> void:
	theme_type_variation = &"MathosSecondaryButton"

func _ready() -> void:
	theme_type_variation = &"MathosSecondaryButton"
	if text.is_empty():
		text = action_text
