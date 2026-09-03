class_name AuthApiClient
extends RefCounted

## Central Typed Auth API Client for Mathos Engine.
## Communicates with Auth Backend API (default http://127.0.0.1:8080) over HTTP/HTTPS.
## Enforces typed AuthResult returns, in-memory session management, token log safety,
## lightweight client validation, and zero player save/progression state mutation.

const ApiConfigClass = preload("res://src/core/network/api_config.gd")
const HttpTransportClass = preload("res://src/core/network/http_transport.gd")
const AuthResultClass = preload("res://src/core/auth/auth_result.gd")
const AuthSessionClass = preload("res://src/core/auth/auth_session.gd")

var _config: RefCounted = null
var _transport: RefCounted = null
var _session: RefCounted = null

func _init(config: RefCounted = null, transport: RefCounted = null) -> void:
	_config = config if config != null else ApiConfigClass.new()
	_transport = transport if transport != null else HttpTransportClass.new()
	_session = AuthSessionClass.new()

func set_config(config: RefCounted) -> void:
	if config != null:
		_config = config

func get_config() -> RefCounted:
	return _config

func set_transport(transport: RefCounted) -> void:
	if transport != null:
		_transport = transport

func get_transport() -> RefCounted:
	return _transport

func get_session() -> RefCounted:
	return _session

# 1. REGISTER ACCOUNT
func register_account(display_name: String, email: String, password: String):
	var clean_name: String = display_name.strip_edges()
	var clean_email: String = email.strip_edges()
	var clean_pass: String = password.strip_edges()

	if clean_name.is_empty():
		return AuthResultClass.fail("VALIDATION_ERROR", "Display name cannot be empty")
	if clean_email.is_empty():
		return AuthResultClass.fail("VALIDATION_ERROR", "Email address cannot be empty")
	if clean_pass.is_empty():
		return AuthResultClass.fail("VALIDATION_ERROR", "Password cannot be empty")

	var url: String = _config.get_endpoint_url(ApiConfigClass.REGISTER_PATH)
	var body: String = JSON.stringify({
		"display_name": clean_name,
		"email": clean_email,
		"password": clean_pass
	})

	var headers: Array = []
	var resp: Dictionary = await _transport.request(url, HTTPClient.METHOD_POST, headers, body)
	return _process_response(resp)

# 2. LOGIN
func login(email: String, password: String):
	var clean_email: String = email.strip_edges()
	var clean_pass: String = password.strip_edges()

	if clean_email.is_empty():
		return AuthResultClass.fail("VALIDATION_ERROR", "Email address cannot be empty")
	if clean_pass.is_empty():
		return AuthResultClass.fail("VALIDATION_ERROR", "Password cannot be empty")

	var url: String = _config.get_endpoint_url(ApiConfigClass.LOGIN_PATH)
	var body: String = JSON.stringify({
		"email": clean_email,
		"password": clean_pass
	})

	var headers: Array = []
	var resp: Dictionary = await _transport.request(url, HTTPClient.METHOD_POST, headers, body)
	var result = _process_response(resp)

	if result.success and result.data is Dictionary:
		_session.update_from_dict(result.data)

	return result

# 3. REFRESH SESSION
func refresh_session(refresh_token: String = ""):
	var token_to_use: String = refresh_token.strip_edges()
	if token_to_use.is_empty():
		token_to_use = _session.refresh_token

	if token_to_use.is_empty():
		return AuthResultClass.fail("VALIDATION_ERROR", "Refresh token is required")

	var url: String = _config.get_endpoint_url(ApiConfigClass.REFRESH_PATH)
	var body: String = JSON.stringify({
		"refresh_token": token_to_use
	})

	var headers: Array = []
	var resp: Dictionary = await _transport.request(url, HTTPClient.METHOD_POST, headers, body)
	var result = _process_response(resp)

	if result.success and result.data is Dictionary:
		_session.update_from_dict(result.data)

	return result

# 4. LOGOUT
func logout(refresh_token: String = ""):
	var token_to_use: String = refresh_token.strip_edges()
	if token_to_use.is_empty():
		token_to_use = _session.refresh_token

	var url: String = _config.get_endpoint_url(ApiConfigClass.LOGOUT_PATH)
	var body: String = JSON.stringify({
		"refresh_token": token_to_use
	})

	var headers: Array = []
	var resp: Dictionary = await _transport.request(url, HTTPClient.METHOD_POST, headers, body)
	var result = _process_response(resp)

	_session.clear()
	return result

# 5. GET ME (AUTHENTICATED)
func get_me(access_token: String = ""):
	var token_to_use: String = access_token.strip_edges()
	if token_to_use.is_empty():
		token_to_use = _session.access_token

	if token_to_use.is_empty():
		return AuthResultClass.fail("UNAUTHORIZED", "Authentication access token is required", 401)

	var url: String = _config.get_endpoint_url(ApiConfigClass.ME_PATH)
	var headers: Array = ["Authorization: Bearer " + token_to_use]

	var resp: Dictionary = await _transport.request(url, HTTPClient.METHOD_GET, headers, "")
	var result = _process_response(resp)

	if result.success and result.data is Dictionary:
		_session.user_profile = result.data.duplicate(true)

	return result

# 6. FORGOT PASSWORD
func forgot_password(email: String):
	var clean_email: String = email.strip_edges()
	if clean_email.is_empty():
		return AuthResultClass.fail("VALIDATION_ERROR", "Email address cannot be empty")

	var url: String = _config.get_endpoint_url(ApiConfigClass.FORGOT_PASSWORD_PATH)
	var body: String = JSON.stringify({
		"email": clean_email
	})

	var headers: Array = []
	var resp: Dictionary = await _transport.request(url, HTTPClient.METHOD_POST, headers, body)
	return _process_response(resp)

# 7. RESET PASSWORD
func reset_password(reset_token: String, new_password: String):
	var clean_token: String = reset_token.strip_edges()
	var clean_pass: String = new_password.strip_edges()

	if clean_token.is_empty():
		return AuthResultClass.fail("VALIDATION_ERROR", "Reset token cannot be empty")
	if clean_pass.is_empty():
		return AuthResultClass.fail("VALIDATION_ERROR", "New password cannot be empty")

	var url: String = _config.get_endpoint_url(ApiConfigClass.RESET_PASSWORD_PATH)
	var body: String = JSON.stringify({
		"token": clean_token,
		"new_password": clean_pass
	})

	var headers: Array = []
	var resp: Dictionary = await _transport.request(url, HTTPClient.METHOD_POST, headers, body)
	return _process_response(resp)

# CENTRALIZED PUBLIC ERROR MESSAGE EXTRACTION HELPER
# Safely handles String, Array (FastAPI/Pydantic validation errors), Dictionary, or null/missing
func _extract_public_error_message(parsed_data: Dictionary, default_fallback: String) -> String:
	if parsed_data.is_empty():
		return default_fallback

	var detail_val: Variant = parsed_data.get("detail", parsed_data.get("message", parsed_data.get("msg", null)))

	if detail_val == null:
		return default_fallback

	# Case 1: String
	if detail_val is String:
		var s: String = (detail_val as String).strip_edges()
		return s if not s.is_empty() else default_fallback

	# Case 2: Array of validation objects (FastAPI / Pydantic style detail)
	if detail_val is Array:
		var arr: Array = detail_val as Array
		var msgs: Array[String] = []
		for item in arr:
			if item is Dictionary:
				var item_dict: Dictionary = item as Dictionary
				var m: String = item_dict.get("msg", item_dict.get("message", item_dict.get("detail", ""))) as String
				m = m.strip_edges()
				if not m.is_empty() and not msgs.has(m):
					msgs.append(m)
			elif item is String:
				var s_item: String = (item as String).strip_edges()
				if not s_item.is_empty() and not msgs.has(s_item):
					msgs.append(s_item)

		if not msgs.is_empty():
			var max_msgs: int = mini(msgs.size(), 3)
			var sub_list: Array[String] = []
			for i in range(max_msgs):
				sub_list.append(msgs[i])
			return "; ".join(sub_list)

		return default_fallback

	# Case 3: Dictionary
	if detail_val is Dictionary:
		var dict_val: Dictionary = detail_val as Dictionary
		var m_str: String = dict_val.get("message", dict_val.get("msg", dict_val.get("detail", ""))) as String
		m_str = m_str.strip_edges()
		return m_str if not m_str.is_empty() else default_fallback

	return default_fallback

# CENTRALIZED RESPONSE PARSER & ERROR MAPPER
func _process_response(resp: Dictionary):
	var status: int = resp.get("status_code", 0) as int
	var err_code: String = resp.get("error_code", "") as String
	var body_str: String = resp.get("body", "") as String

	# 1. Transport Level Network Error or Timeout
	if status == 0:
		if err_code == "TIMEOUT":
			return AuthResultClass.fail("TIMEOUT", "Network request timed out", 0)
		return AuthResultClass.fail("NETWORK_ERROR", resp.get("error_message", "Network connection failed"), 0)

	# 2. Parse JSON Response Body
	var parsed_data: Dictionary = {}
	if not body_str.is_empty():
		var json_val: Variant = JSON.parse_string(body_str)
		if json_val is Dictionary:
			parsed_data = json_val as Dictionary
		elif json_val == null and not body_str.strip_edges().is_empty():
			return AuthResultClass.fail("INVALID_RESPONSE", "Failed to parse JSON server response", status)

	# 3. Handle Successful HTTP Response (200..299)
	if status >= 200 and status < 300:
		var ok_msg: String = _extract_public_error_message(parsed_data, "Request successful")
		return AuthResultClass.ok(parsed_data, ok_msg, status)

	# 4. Map Error HTTP Status Codes
	if status == 401 or status == 403:
		var msg: String = _extract_public_error_message(parsed_data, "Unauthorized or expired session")
		return AuthResultClass.fail("UNAUTHORIZED", msg, status, parsed_data)

	if status == 400 or status == 422:
		var msg: String = _extract_public_error_message(parsed_data, "Validation failed for request parameters")
		return AuthResultClass.fail("VALIDATION_ERROR", msg, status, parsed_data)

	if status >= 500:
		var msg: String = _extract_public_error_message(parsed_data, "Server error encountered. Please try again later.")
		return AuthResultClass.fail("SERVER_ERROR", msg, status, parsed_data)

	var default_msg: String = _extract_public_error_message(parsed_data, "Request failed with HTTP status %d" % status)
	return AuthResultClass.fail("SERVER_ERROR", default_msg, status, parsed_data)
