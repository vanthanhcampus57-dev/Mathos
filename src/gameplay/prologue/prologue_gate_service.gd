class_name PrologueGateService
extends RefCounted

## Manages the first-run gate for the Mathos Prologue.
## Ensures the Prologue is presented exactly once before the player's first Dungeon I entry.
## Operates safely without mutating or expanding SaveSchema V1.

const PROLOGUE_GATE_FILE_PATH: String = "user://prologue_gate.json"
const INITIAL_STAGE_ID: String = "stage_01_01"

var _prologue_completed: bool = false
var _custom_file_path: String = ""

func _init(custom_path: String = "") -> void:
	if not custom_path.is_empty():
		_custom_file_path = custom_path
	load_state()

## Returns true if the target stage is the first-ever entry to Dungeon I and Prologue hasn't been seen.
func is_first_dungeon_entry(stage_id: String, progress: ProgressState = null) -> bool:
	# Only stage 1.1 can trigger the first Dungeon I entry prologue
	if stage_id != INITIAL_STAGE_ID:
		return false

	# If prologue has already been marked completed, skip
	if has_completed_prologue():
		return false

	# Defensive progress check: if any stages are cleared or fragments collected, this is a replay/continuation
	if progress != null:
		if not progress.cleared_stage_ids.is_empty():
			return false
		if not progress.fragment_ids.is_empty():
			return false
		if progress.unlocked_dungeon_ids.size() > 1:
			return false

	return true

func has_completed_prologue() -> bool:
	return _prologue_completed

func mark_prologue_completed() -> void:
	_prologue_completed = true
	save_state()

func reset_state() -> void:
	_prologue_completed = false
	var path: String = _get_file_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func save_state() -> bool:
	var path: String = _get_file_path()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("PrologueGateService: could not write gate state to " + path)
		return false

	var payload: Dictionary = {
		"prologue_completed": _prologue_completed,
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(true)
	}
	file.store_string(JSON.stringify(payload, "	"))
	file.close()
	return true

func load_state() -> bool:
	var path: String = _get_file_path()
	if not FileAccess.file_exists(path):
		return false

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: Error = json.parse(text)
	if err != OK or not (json.data is Dictionary):
		return false

	var dict: Dictionary = json.data as Dictionary
	if dict.has("prologue_completed"):
		_prologue_completed = bool(dict["prologue_completed"])
		return true

	return false

func _get_file_path() -> String:
	return _custom_file_path if not _custom_file_path.is_empty() else PROLOGUE_GATE_FILE_PATH
