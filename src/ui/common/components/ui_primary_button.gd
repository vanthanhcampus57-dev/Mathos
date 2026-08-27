class_name UiPrimaryButton
extends Button

## Shared primary action button primitive.
## Consumes authoritative Mathos Theme variation "MathosPrimaryButton".

@export var action_text: String = "Action":
	set(value):
		action_text = value
		text = action_text

func _init() -> void:
	theme_type_variation = &"MathosPrimaryButton"

func _ready() -> void:
	theme_type_variation = &"MathosPrimaryButton"
	if text.is_empty():
		text = action_text
