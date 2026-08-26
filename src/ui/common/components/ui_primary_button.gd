class_name UiPrimaryButton
extends Button

## Shared primary action button primitive.
## Consumes semantic Theme type variation "PrimaryButton".

@export var action_text: String = "Action":
	set(value):
		action_text = value
		text = action_text

func _init() -> void:
	theme_type_variation = &"PrimaryButton"

func _ready() -> void:
	theme_type_variation = &"PrimaryButton"
	if text.is_empty():
		text = action_text
