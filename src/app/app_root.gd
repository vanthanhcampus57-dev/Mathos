class_name AppRoot
extends Node

## Composition Root Placeholder for Mathos engine.
## Bootstraps minimal neutral UI in foundation build.

@onready var title_label: Label = $BootstrapUI/MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $BootstrapUI/MarginContainer/VBoxContainer/SubtitleLabel
@onready var version_label: Label = $BootstrapUI/MarginContainer/VBoxContainer/VersionLabel

func _ready() -> void:
	title_label.text = "Mathos"
	subtitle_label.text = "Foundation Build"
	version_label.text = "0.1.0-dev"
	print("[AppRoot] Mathos Foundation Build 0.1.0-dev initialized.")
