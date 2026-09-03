class_name AuthResult
extends RefCounted

## Common Typed Result Model for Mathos Auth API Client.
## Encapsulates success state, HTTP status, error codes, public message, and payload data.

var success: bool = false
var http_status: int = 0
var error_code: String = "OK"
var message: String = ""
var data: Dictionary = {}

static func ok(p_data: Dictionary = {}, p_message: String = "OK", p_status: int = 200) -> AuthResult:
	var res: AuthResult = AuthResult.new()
	res.success = true
	res.http_status = p_status
	res.error_code = "OK"
	res.message = p_message
	res.data = p_data
	return res

static func fail(p_error_code: String, p_message: String, p_status: int = 400, p_data: Dictionary = {}) -> AuthResult:
	var res: AuthResult = AuthResult.new()
	res.success = false
	res.http_status = p_status
	res.error_code = p_error_code
	res.message = p_message
	res.data = p_data
	return res

func to_summary() -> Dictionary:
	return {
		"success": success,
		"http_status": http_status,
		"error_code": error_code,
		"message": message,
		"data_keys": data.keys()
	}
