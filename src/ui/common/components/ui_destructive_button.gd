class_name UiDestructiveButton
extends Button

## Shared destructive action button primitive.
## Consumes semantic Theme type variation "DestructiveButton".

@export var action_text: String = "Delete":
	set(value):
		action_text = value
		text = action_text

func _init() -> void:
	theme_type_variation = &"DestructiveButton"

func _ready() -> void:
	theme_type_variation = &"DestructiveButton"
	if text.is_empty():
		text = action_text
