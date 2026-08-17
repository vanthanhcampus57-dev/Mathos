class_name SaveSnapshotCodec
extends RefCounted

## Plain-data serialization and deserialization codec for SaveSnapshot V1.
## It performs no disk I/O, user:// access, default injection, or alias rewriting.

static func serialize(snapshot: Dictionary) -> String:
	return JSON.stringify(snapshot, "\t")

static func deserialize(json_string: String) -> Dictionary:
	if json_string.is_empty():
		return {
			"success": false,
			"error_code": SaveErrorCodes.CORRUPT_SAVE,
			"error_message": "Save data string is empty"
		}
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		return {
			"success": false,
			"error_code": SaveErrorCodes.CORRUPT_SAVE,
			"error_message": "Malformed JSON: %s (line %d)" % [json.get_error_message(), json.get_error_line()]
		}
	var data: Variant = json.data
	if not (data is Dictionary):
		return {
			"success": false,
			"error_code": SaveErrorCodes.CORRUPT_SAVE,
			"error_message": "Save snapshot root must be a JSON Object"
		}
	return {
		"success": true,
		"snapshot": data as Dictionary
	}
