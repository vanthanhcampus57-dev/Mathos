class_name UiMetaLabel
extends Label

## Shared meta/subcaption label primitive.
## Consumes semantic Theme type variation "MetaLabel".

func _init() -> void:
	theme_type_variation = &"MetaLabel"

func _ready() -> void:
	theme_type_variation = &"MetaLabel"
