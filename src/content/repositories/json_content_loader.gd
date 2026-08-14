class_name JSONContentLoader
extends RefCounted

## Utility loader for reading JSON files with UTF-8 and duplicate key detection.

static func load_json_file(file_path: String) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"data": null,
		"error": "",
		"has_duplicate_keys": false,
		"duplicate_key": ""
	}

	if not FileAccess.file_exists(file_path):
		result["error"] = "File not found: " + file_path
		return result

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		result["error"] = "Failed to open file: " + file_path
		return result

	var text: String = file.get_as_text()
	file.close()

	if text.strip_edges() == "":
		result["error"] = "File is empty: " + file_path
		return result

	# Check for duplicate keys
	var dup_check: Dictionary = detect_duplicate_keys(text)
	if dup_check["has_duplicate"]:
		result["has_duplicate_keys"] = true
		result["duplicate_key"] = dup_check["key"]
		result["error"] = "Duplicate object key detected: '" + dup_check["key"] + "'"
		return result

	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(text)
	if parse_err != OK:
		result["error"] = "JSON parse error at line " + str(json.get_error_line()) + ": " + json.get_error_message()
		return result

	result["success"] = true
	result["data"] = json.get_data()
	return result

## Tokenizer-based duplicate key detector for JSON objects.
static func detect_duplicate_keys(json_str: String) -> Dictionary:
	var res: Dictionary = {"has_duplicate": false, "key": ""}
	var length: int = json_str.length()
	var i: int = 0
	
	# Stack of Dictionaries tracking keys at each object depth level
	var object_stack: Array = []
	var expecting_key: Array = []
	
	var in_string: bool = false
	var is_escaped: bool = false
	var current_string: String = ""

	while i < length:
		var c: String = json_str[i]

		if in_string:
			if is_escaped:
				current_string += c
				is_escaped = false
			elif c == "\\":
				is_escaped = true
			elif c == "\"":
				in_string = false
				# Process string token
				# Peek if next non-whitespace char is ':'
				var j: int = i + 1
				while j < length and (json_str[j] == " " or json_str[j] == "\t" or json_str[j] == "\n" or json_str[j] == "\r"):
					j += 1
				if j < length and json_str[j] == ":" and object_stack.size() > 0 and expecting_key.back() == true:
					var current_keys: Dictionary = object_stack.back() as Dictionary
					if current_keys.has(current_string):
						res["has_duplicate"] = true
						res["key"] = current_string
						return res
					current_keys[current_string] = true
					expecting_key[expecting_key.size() - 1] = false
			else:
				current_string += c
		else:
			if c == "{":
				object_stack.append({})
				expecting_key.append(true)
			elif c == "}":
				if object_stack.size() > 0:
					object_stack.pop_back()
					expecting_key.pop_back()
			elif c == ",":
				if expecting_key.size() > 0:
					expecting_key[expecting_key.size() - 1] = true
			elif c == "\"":
				in_string = true
				is_escaped = false
				current_string = ""
		i += 1

	return res
