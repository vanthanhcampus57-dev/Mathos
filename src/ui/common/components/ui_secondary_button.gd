class_name UiSecondaryButton
extends Button

## Shared secondary action button primitive.
## Consumes semantic Theme type variation "SecondaryButton".

@export var action_text: String = "Secondary":
	set(value):
		action_text = value
		text = action_text

func _init() -> void:
	theme_type_variation = &"SecondaryButton"

func _ready() -> void:
	theme_type_variation = &"SecondaryButton"
	if text.is_empty():
		text = action_text
