class_name UiDestructiveButton
extends Button

## Shared destructive action button primitive.
## Consumes authoritative Mathos Theme variation "MathosDestructiveButton".

@export var action_text: String = "Delete":
	set(value):
		action_text = value
		text = action_text

func _init() -> void:
	theme_type_variation = &"MathosDestructiveButton"

func _ready() -> void:
	theme_type_variation = &"MathosDestructiveButton"
	if text.is_empty():
		text = action_text
