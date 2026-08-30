class_name UiPrimaryButton
extends Button

## Shared primary action button primitive.
## Consumes authoritative Mathos Theme variation "MathosPrimaryButton".

@export var action_text: String = "Action":
	set(value):
		action_text = value
		text = action_text

var _tween: Tween = null

func _init() -> void:
	theme_type_variation = &"MathosPrimaryButton"

func _ready() -> void:
	theme_type_variation = &"MathosPrimaryButton"
	if text.is_empty():
		text = action_text

	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	if not button_down.is_connected(_on_button_down):
		button_down.connect(_on_button_down)
	if not button_up.is_connected(_on_button_up):
		button_up.connect(_on_button_up)
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	_update_pivot()

func _on_resized() -> void:
	_update_pivot()

func _update_pivot() -> void:
	pivot_offset = size / 2.0

func _on_mouse_entered() -> void:
	if disabled:
		return
	_animate_scale(Vector2(1.03, 1.03), 0.1)

func _on_mouse_exited() -> void:
	_animate_scale(Vector2(1.0, 1.0), 0.1)

func _on_button_down() -> void:
	if disabled:
		return
	_animate_scale(Vector2(0.97, 0.97), 0.06)

func _on_button_up() -> void:
	if disabled:
		return
	_animate_scale(Vector2(1.0, 1.0), 0.08)

func _animate_scale(target_scale: Vector2, duration: float) -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	if _tween != null:
		_tween.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
