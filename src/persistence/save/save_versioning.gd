class_name SaveVersioning
extends RefCounted

## Schema version support gate and versioning policy for SaveSnapshot V1.

static func is_supported_version(version: int) -> bool:
	return version == SaveSchema.SAVE_SCHEMA_VERSION

static func check_version(version: int) -> Dictionary:
	if version > SaveSchema.SAVE_SCHEMA_VERSION:
		return {
			"success": false,
			"error_code": SaveErrorCodes.UNSUPPORTED_SAVE_VERSION,
			"error_message": "Unsupported save schema version: %d (expected <= %d)" % [version, SaveSchema.SAVE_SCHEMA_VERSION]
		}
	if version < SaveSchema.SAVE_SCHEMA_VERSION:
		return {
			"success": false,
			"error_code": SaveErrorCodes.CORRUPT_SAVE,
			"error_message": "Invalid save schema version: %d" % version
		}
	return {"success": true}
