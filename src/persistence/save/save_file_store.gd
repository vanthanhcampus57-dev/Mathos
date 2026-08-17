class_name SaveFileStore
extends RefCounted

## File system abstraction seam for SaveService disk operations.
## Supports isolated test directories and failure injection seams.

var _base_dir: String = "user://"
var main_path: String = ""
var temp_path: String = ""
var backup_path: String = ""

# Failure injection flags for testing
var inject_fail_temp_write: bool = false
var inject_fail_temp_read: bool = false
var inject_fail_backup: bool = false
var inject_fail_replace: bool = false
var inject_fail_final_read: bool = false

func _init(base_dir: String = "user://") -> void:
	_base_dir = base_dir
	if not _base_dir.ends_with("/"):
		_base_dir += "/"
	main_path = _base_dir + "save_v1.json"
	temp_path = _base_dir + "save_v1.tmp"
	backup_path = _base_dir + "save_v1.bak"

func get_base_dir() -> String:
	return _base_dir

func file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)

func read_text(path: String) -> Dictionary:
	if path == temp_path and inject_fail_temp_read:
		return _error(SaveErrorCodes.READ_ERROR, "Injected temp read failure")
	if path == main_path and inject_fail_final_read:
		return _error(SaveErrorCodes.READ_ERROR, "Injected main read failure")

	if not FileAccess.file_exists(path):
		return _error(SaveErrorCodes.READ_ERROR, "File does not exist: %s" % path)

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var err_code: int = FileAccess.get_open_error()
		return _error(SaveErrorCodes.READ_ERROR, "Failed to open file for reading: %s (error %d)" % [path, err_code])

	var text: String = file.get_as_text()
	file.close()
	return {"success": true, "content": text}

func write_text(path: String, text: String) -> Dictionary:
	if path == temp_path and inject_fail_temp_write:
		return _error(SaveErrorCodes.WRITE_ERROR, "Injected temp write failure")

	_ensure_directory_exists(path)

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err_code: int = FileAccess.get_open_error()
		return _error(SaveErrorCodes.WRITE_ERROR, "Failed to open file for writing: %s (error %d)" % [path, err_code])

	file.store_string(text)
	file.flush()
	file.close()
	return {"success": true}

func copy_file(src_path: String, dst_path: String) -> Dictionary:
	if dst_path == backup_path and inject_fail_backup:
		return _error(SaveErrorCodes.WRITE_ERROR, "Injected backup failure")

	if not FileAccess.file_exists(src_path):
		return _error(SaveErrorCodes.READ_ERROR, "Source file for copy does not exist: %s" % src_path)

	_ensure_directory_exists(dst_path)
	var err: Error = DirAccess.copy_absolute(src_path, dst_path)
	if err != OK:
		return _error(SaveErrorCodes.WRITE_ERROR, "Failed to copy %s to %s (error %d)" % [src_path, dst_path, err])

	return {"success": true}

func replace_main_with_temp() -> Dictionary:
	if inject_fail_replace:
		return _error(SaveErrorCodes.WRITE_ERROR, "Injected replacement failure")

	if not FileAccess.file_exists(temp_path):
		return _error(SaveErrorCodes.WRITE_ERROR, "Temp file missing for replacement: %s" % temp_path)

	_ensure_directory_exists(main_path)
	var err: Error = DirAccess.copy_absolute(temp_path, main_path)
	if err != OK:
		return _error(SaveErrorCodes.WRITE_ERROR, "Failed to replace main save file with temp (error %d)" % err)

	DirAccess.remove_absolute(temp_path)
	return {"success": true}

func remove_file(path: String) -> Dictionary:
	if FileAccess.file_exists(path):
		var err: Error = DirAccess.remove_absolute(path)
		if err != OK:
			return _error(SaveErrorCodes.WRITE_ERROR, "Failed to remove file: %s (error %d)" % [path, err])
	return {"success": true}

func _ensure_directory_exists(path: String) -> void:
	var dir_path: String = path.get_base_dir()
	if not dir_path.is_empty() and not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

func _error(code: String, message: String) -> Dictionary:
	return {
		"success": false,
		"error_code": code,
		"error_message": message
	}
