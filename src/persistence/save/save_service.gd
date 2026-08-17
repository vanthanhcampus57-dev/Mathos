class_name SaveService
extends RefCounted

## Public boundary for SaveService disk persistence, transactional commit,
## backup preservation, corrupt diagnostic handling, and load validation.
## Conforms strictly to locked Save public interface (File 06, File 08, File 12).

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

	# 6. Preserve existing valid main as backup
	if _file_store.file_exists(_file_store.main_path):
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

	return {"success": true, "snapshot": snapshot.duplicate(true)}

## Preservation handler for corrupt save file.
## File 12 locks user://save_v1.json, user://save_v1.tmp, and user://save_v1.bak.
## Unspecified corrupt diagnostic path requires explicit contract authority.
func backup_corrupt_save() -> Dictionary:
	return _error(SaveErrorCodes.READ_ERROR, "CONTRACT DETAIL MISSING — CORRUPT DIAGNOSTIC PATH")

func _error(code: String, message: String) -> Dictionary:
	return {
		"success": false,
		"error_code": code,
		"error_message": message
	}
