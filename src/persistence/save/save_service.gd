class_name SaveService
extends RefCounted

## Public boundary for SaveService disk persistence, transactional commit,
## backup preservation, corrupt raw byte preservation, and explicit backup recovery.
## Conforms strictly to locked Save public interface (File 06, File 08, File 12) + M1 authority.

var _catalog: ValidatedCatalog = null
var _file_store: SaveFileStore = null

func _init(catalog: ValidatedCatalog = null, file_store: SaveFileStore = null) -> void:
	_catalog = catalog
	if file_store != null:
		_file_store = file_store
	else:
		_file_store = SaveFileStore.new("user://")

func get_file_store() -> SaveFileStore:
	return _file_store

func set_catalog(catalog: ValidatedCatalog) -> void:
	_catalog = catalog

## Validates a SaveSnapshot dictionary against structural, version, and catalog constraints.
func validate_persisted_snapshot(snapshot: Dictionary) -> Dictionary:
	return SaveSnapshotValidator.validate_snapshot(snapshot, _catalog)

## Checks whether a valid Continue save snapshot is available on disk.
## Does not equate file existence with valid save data if main is corrupt.
## Read-only operation; does not mutate disk state.
func has_save() -> bool:
	if _file_store.file_exists(_file_store.main_path):
		var read_res: Dictionary = _file_store.read_text(_file_store.main_path)
		if bool(read_res.get("success", false)):
			var codec_res: Dictionary = SaveSnapshotCodec.deserialize(str(read_res.get("content", "")))
			if bool(codec_res.get("success", false)):
				var val_res: Dictionary = validate_persisted_snapshot(codec_res["snapshot"] as Dictionary)
				if bool(val_res.get("success", false)):
					return true

	# Fallback check: if main is missing/corrupt, check if a valid backup exists
	if _file_store.file_exists(_file_store.backup_path):
		var bak_read: Dictionary = _file_store.read_text(_file_store.backup_path)
		if bool(bak_read.get("success", false)):
			var bak_codec: Dictionary = SaveSnapshotCodec.deserialize(str(bak_read.get("content", "")))
			if bool(bak_codec.get("success", false)):
				var bak_val: Dictionary = validate_persisted_snapshot(bak_codec["snapshot"] as Dictionary)
				if bool(bak_val.get("success", false)):
					return true

	return false

## Transactional save flow.
## Validates pre-write -> serializes -> writes temp -> validates temp readback ->
## preserves valid main as backup -> replaces main -> validates final main readback.
func save(snapshot: Dictionary) -> Dictionary:
	return _save_internal(snapshot, false)

## Internal transactional save helper with recovery flag seam.
func _save_internal(snapshot: Dictionary, is_recovery: bool) -> Dictionary:
	# 1. Pre-write validation
	var val_res: Dictionary = validate_persisted_snapshot(snapshot)
	if not bool(val_res.get("success", false)):
		return val_res

	# 2. Serialize to UTF-8 JSON
	var json_text: String = SaveSnapshotCodec.serialize(snapshot)

	# 3. Write temp file
	var temp_write: Dictionary = _file_store.write_text(_file_store.temp_path, json_text)
	if not bool(temp_write.get("success", false)):
		return temp_write

	# 4. Read temp back
	var temp_read: Dictionary = _file_store.read_text(_file_store.temp_path)
	if not bool(temp_read.get("success", false)):
		_file_store.remove_file(_file_store.temp_path)
		return temp_read

	# 5. Parse + validate temp readback
	var temp_codec: Dictionary = SaveSnapshotCodec.deserialize(str(temp_read.get("content", "")))
	if not bool(temp_codec.get("success", false)):
		_file_store.remove_file(_file_store.temp_path)
		return temp_codec

	var temp_val: Dictionary = validate_persisted_snapshot(temp_codec["snapshot"] as Dictionary)
	if not bool(temp_val.get("success", false)):
		_file_store.remove_file(_file_store.temp_path)
		return temp_val

	# 6. Preserve existing valid main as backup (ONLY during ordinary save, NOT recovery)
	if not is_recovery and _file_store.file_exists(_file_store.main_path):
		var existing_read: Dictionary = _file_store.read_text(_file_store.main_path)
		if bool(existing_read.get("success", false)):
			var existing_codec: Dictionary = SaveSnapshotCodec.deserialize(str(existing_read.get("content", "")))
			if bool(existing_codec.get("success", false)):
				var existing_val: Dictionary = validate_persisted_snapshot(existing_codec["snapshot"] as Dictionary)
				# Only promote existing main to backup if it is VALID
				if bool(existing_val.get("success", false)):
					var backup_res: Dictionary = _file_store.copy_file(_file_store.main_path, _file_store.backup_path)
					if not bool(backup_res.get("success", false)):
						_file_store.remove_file(_file_store.temp_path)
						return backup_res

	# 7. Replace main with temp
	var replace_res: Dictionary = _file_store.replace_main_with_temp()
	if not bool(replace_res.get("success", false)):
		_file_store.remove_file(_file_store.temp_path)
		return replace_res

	# 8. Read main back
	var main_read: Dictionary = _file_store.read_text(_file_store.main_path)
	if not bool(main_read.get("success", false)):
		return main_read

	# 9. Parse + validate final main readback
	var main_codec: Dictionary = SaveSnapshotCodec.deserialize(str(main_read.get("content", "")))
	if not bool(main_codec.get("success", false)):
		return main_codec

	var main_val: Dictionary = validate_persisted_snapshot(main_codec["snapshot"] as Dictionary)
	if not bool(main_val.get("success", false)):
		return main_val

	# 10. Report persistence success
	return {"success": true, "snapshot": (main_codec["snapshot"] as Dictionary).duplicate(true)}

## Loads committed save snapshot from disk.
## Read-only operation. Performs deserialization and validation of main save file.
## Does not write to disk or mutate save state.
func load() -> Dictionary:
	if not _file_store.file_exists(_file_store.main_path):
		if _file_store.file_exists(_file_store.backup_path):
			var bak_read: Dictionary = _file_store.read_text(_file_store.backup_path)
			if bool(bak_read.get("success", false)):
				var bak_codec: Dictionary = SaveSnapshotCodec.deserialize(str(bak_read.get("content", "")))
				if bool(bak_codec.get("success", false)):
					var bak_val: Dictionary = validate_persisted_snapshot(bak_codec["snapshot"] as Dictionary)
					if bool(bak_val.get("success", false)):
						return {
							"success": false,
							"error_code": SaveErrorCodes.READ_ERROR,
							"error_message": "Main save file missing, valid backup available",
							"can_recover_backup": true
						}
		return _error(SaveErrorCodes.READ_ERROR, "Save file does not exist: %s" % _file_store.main_path)

	var read_res: Dictionary = _file_store.read_text(_file_store.main_path)
	if not bool(read_res.get("success", false)):
		return read_res

	var codec_res: Dictionary = SaveSnapshotCodec.deserialize(str(read_res.get("content", "")))
	if not bool(codec_res.get("success", false)):
		return codec_res

	var snapshot: Dictionary = codec_res["snapshot"] as Dictionary
	var val_res: Dictionary = validate_persisted_snapshot(snapshot)
	if not bool(val_res.get("success", false)):
		return val_res

	var clean_snapshot: Dictionary = _sanitize_snapshot_for_playable_content(snapshot)
	return {"success": true, "snapshot": clean_snapshot.duplicate(true)}

func _sanitize_snapshot_for_playable_content(snapshot: Dictionary) -> Dictionary:
	if _catalog == null or not _catalog.has_method("is_dungeon_playable"):
		return snapshot

	var config: Dictionary = _catalog.get_config()
	if not config.has("playable_dungeon_ids"):
		return snapshot

	var clean: Dictionary = snapshot.duplicate(true)
	var progress: Dictionary = clean.get("progress", {}) as Dictionary
	if progress.is_empty():
		return clean

	var raw_unlocked_dungeons: Array = progress.get("unlocked_dungeon_ids", []) as Array
	var raw_unlocked_stages: Array = progress.get("unlocked_stage_ids", []) as Array

	var clean_dungeons: Array[String] = []
	for d in raw_unlocked_dungeons:
		var d_id: String = String(d)
		if _catalog.is_dungeon_playable(d_id):
			clean_dungeons.append(d_id)

	var clean_stages: Array[String] = []
	for s in raw_unlocked_stages:
		var s_id: String = String(s)
		var stage_info: Dictionary = _catalog.get_stage(s_id)
		var d_id: String = String(stage_info.get("dungeon_id", ""))
		if _catalog.is_dungeon_playable(d_id):
			clean_stages.append(s_id)

	if clean_dungeons.is_empty() and raw_unlocked_dungeons.has("dungeon_01"):
		clean_dungeons.append("dungeon_01")
	if clean_stages.is_empty() and raw_unlocked_stages.has("stage_01_01"):
		clean_stages.append("stage_01_01")

	progress["unlocked_dungeon_ids"] = clean_dungeons
	progress["unlocked_stage_ids"] = clean_stages
	clean["progress"] = progress
	return clean

## Preservation handler for corrupt save file (M1 Authorized).
## Copies RAW main bytes to user://save_v1_corrupt_diagnostic.json iff main is invalid.
## Does not deserialize or rewrite bytes. Must NOT overwrite save_v1.bak.
## Returns true on success, false if main is absent/valid or copy fails.
func backup_corrupt_save() -> bool:
	if not _file_store.file_exists(_file_store.main_path):
		return false

	# Check if main is valid; only operate when main is INVALID
	var read_res: Dictionary = _file_store.read_text(_file_store.main_path)
	if bool(read_res.get("success", false)):
		var codec_res: Dictionary = SaveSnapshotCodec.deserialize(str(read_res.get("content", "")))
		if bool(codec_res.get("success", false)):
			var val_res: Dictionary = validate_persisted_snapshot(codec_res["snapshot"] as Dictionary)
			if bool(val_res.get("success", false)):
				# Main is valid! Do not pretend to preserve a corrupt save.
				return false

	# Main is corrupt/invalid. Copy raw main bytes to diagnostic path
	var copy_res: Dictionary = _file_store.copy_file(_file_store.main_path, _file_store.diagnostic_path)
	return bool(copy_res.get("success", false))

## Explicit backup recovery operation (M1 Authorized).
## Validates user://save_v1.bak -> preserves raw corrupt main if present ->
## feeds backup snapshot through validated write path without overwriting backup.
## Returns true iff newly written main validates successfully.
func recover_from_backup() -> bool:
	if not _file_store.file_exists(_file_store.backup_path):
		return false

	var bak_read: Dictionary = _file_store.read_text(_file_store.backup_path)
	if not bool(bak_read.get("success", false)):
		return false

	var bak_codec: Dictionary = SaveSnapshotCodec.deserialize(str(bak_read.get("content", "")))
	if not bool(bak_codec.get("success", false)):
		return false

	var bak_snapshot: Dictionary = bak_codec["snapshot"] as Dictionary
	var bak_val: Dictionary = validate_persisted_snapshot(bak_snapshot)
	if not bool(bak_val.get("success", false)):
		return false

	# Backup is valid! Check if current main exists and is invalid
	if _file_store.file_exists(_file_store.main_path):
		var main_read: Dictionary = _file_store.read_text(_file_store.main_path)
		var is_main_invalid: bool = true
		if bool(main_read.get("success", false)):
			var main_codec: Dictionary = SaveSnapshotCodec.deserialize(str(main_read.get("content", "")))
			if bool(main_codec.get("success", false)):
				var main_val: Dictionary = validate_persisted_snapshot(main_codec["snapshot"] as Dictionary)
				if bool(main_val.get("success", false)):
					is_main_invalid = false

		if is_main_invalid:
			# Preserve raw corrupt main bytes before replacement
			backup_corrupt_save()

	# Re-commit backup snapshot through normal write flow with is_recovery=true
	var save_res: Dictionary = _save_internal(bak_snapshot, true)
	return bool(save_res.get("success", false))

func _error(code: String, message: String) -> Dictionary:
	return {
		"success": false,
		"error_code": code,
		"error_message": message
	}
