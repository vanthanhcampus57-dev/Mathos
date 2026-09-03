extends SceneTree

## Targeted Unit Test Suite for Godot Auth API Client Foundation (MATHOS-GODOT-AUTH-CLIENT-CONTRACT-FIX-009)
## Tests:
## 1. Configurable base URL & normalization.
## 2. Mock transport injection & async HTTP requests.
## 3. Register request path, method (POST), and body payload.
## 4. Login request path, method (POST), flat backend TokenResponse (user_id, email, display_name), and AuthSession population.
## 5. Login request nested "user" dictionary fallback.
## 6. Refresh session request path, method (POST), and token update.
## 7. Logout request path, method (POST), and session clearing.
## 8. Me request path, method (GET), and Bearer authorization header format.
## 9. Forgot Password request path, method (POST), and body payload.
## 10. Reset Password request path, method (POST), and body payload.
## 11. HTTP 400 -> VALIDATION_ERROR mapping.
## 12. Pydantic 422 Array detail -> VALIDATION_ERROR mapping with msg extraction.
## 13. Pydantic 422 String detail -> VALIDATION_ERROR mapping.
## 14. Pydantic 422 Dict detail -> VALIDATION_ERROR mapping.
## 15. Pydantic 422 null/missing detail -> VALIDATION_ERROR mapping fallback.
## 16. HTTP 401 -> UNAUTHORIZED mapping.
## 17. HTTP 500 -> SERVER_ERROR mapping.
## 18. Transport failures (Network error, Timeout, Malformed JSON response).
## 19. Token log safety (tokens never exposed in log output or summary strings).
## 20. In-memory session model (zero persistence).
## 21. Safe expires_in type parsing (int, float, string).
## 22. Zero state mutation (player save & gameplay progression untouched).
## 23. Visual & Splash sequence locks preserved.

const ApiConfigClass = preload("res://src/core/network/api_config.gd")
const HttpTransportClass = preload("res://src/core/network/http_transport.gd")
const AuthResultClass = preload("res://src/core/auth/auth_result.gd")
const AuthSessionClass = preload("res://src/core/auth/auth_session.gd")
const AuthApiClientClass = preload("res://src/core/auth/auth_api_client.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS AUTH API CLIENT QA HARNESS (AUTH-CLI-001..024) ---")
	var ok: bool = await run_all_tests()
	if ok:
		print("MATHOS AUTH API CLIENT QA HARNESS: PASS!")
		quit(0)
	else:
		print("MATHOS AUTH API CLIENT QA HARNESS: FAIL!")
		quit(1)

static func run_all_tests() -> bool:
	var passes: int = 0
	if test_auth_001_configurable_base_url_normalization(): passes += 1
	if await test_auth_002_register_request_contract(): passes += 1
	if await test_auth_003_login_request_flat_token_response(): passes += 1
	if await test_auth_004_login_request_nested_user_fallback(): passes += 1
	if await test_auth_005_refresh_session_contract(): passes += 1
	if await test_auth_006_logout_request_and_session_clearing(): passes += 1
	if await test_auth_007_me_request_bearer_header_format(): passes += 1
	if await test_auth_008_forgot_password_contract(): passes += 1
	if await test_auth_009_reset_password_contract(): passes += 1
	if await test_auth_010_validation_error_mapping_400(): passes += 1
	if await test_auth_011_pydantic_422_array_detail_mapping(): passes += 1
	if await test_auth_012_pydantic_422_string_detail_mapping(): passes += 1
	if await test_auth_013_pydantic_422_dict_detail_mapping(): passes += 1
	if await test_auth_014_pydantic_422_null_detail_mapping(): passes += 1
	if await test_auth_015_unauthorized_error_mapping_401(): passes += 1
	if await test_auth_016_server_error_mapping_500(): passes += 1
	if await test_auth_017_network_failure_mapping(): passes += 1
	if await test_auth_018_timeout_mapping(): passes += 1
	if await test_auth_019_malformed_json_handling(): passes += 1
	if test_auth_020_token_log_safety(): passes += 1
	if test_auth_021_in_memory_session_only(): passes += 1
	if test_auth_022_expires_in_type_safety(): passes += 1
	if await test_auth_023_zero_state_mutation(): passes += 1
	if test_auth_024_visual_and_splash_locks(): passes += 1

	print("[AUTH-CLIENT-HARNESS] %d / 24 test scenarios passed" % passes)
	return passes == 24

static func test_auth_001_configurable_base_url_normalization() -> bool:
	print("[AUTH-CLI-001] Verifying configurable base URL & trailing slash normalization...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080/")
	if config.get_base_url() != "http://127.0.0.1:8080":
		print("[AUTH-CLI-001] FAIL: Expected http://127.0.0.1:8080, got %s" % config.get_base_url())
		return false

	config.set_base_url("https://api.mathos.dev/")
	if config.get_base_url() != "https://api.mathos.dev":
		print("[AUTH-CLI-001] FAIL: Expected https://api.mathos.dev, got %s" % config.get_base_url())
		return false

	var full_url: String = config.get_endpoint_url("/api/v1/auth/login")
	if full_url != "https://api.mathos.dev/api/v1/auth/login":
		print("[AUTH-CLI-001] FAIL: Expected https://api.mathos.dev/api/v1/auth/login, got %s" % full_url)
		return false

	print("[AUTH-CLI-001] PASS: Configurable base URL & normalization verified!")
	return true

static func test_auth_002_register_request_contract() -> bool:
	print("[AUTH-CLI-002] Verifying register request path, method, and JSON body payload...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()
	var last_req: Dictionary = {}

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		last_req.clear()
		last_req["url"] = url
		last_req["method"] = method
		last_req["body"] = body
		return {
			"status_code": 201,
			"error_code": "OK",
			"body": JSON.stringify({"message": "User registered successfully", "id": "u-101"})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.register_account("Alex Scholar", "alex@example.com", "SecretPass123!")

	if not res.success or res.http_status != 201:
		print("[AUTH-CLI-002] FAIL: Register request failed")
		return false

	if last_req.get("url", "") != "http://127.0.0.1:8080/api/v1/auth/register" or last_req.get("method", 0) != HTTPClient.METHOD_POST:
		print("[AUTH-CLI-002] FAIL: Incorrect URL or HTTP method for register")
		return false

	var body_dict: Dictionary = JSON.parse_string(last_req.get("body", "{}")) as Dictionary
	if body_dict.get("display_name", "") != "Alex Scholar" or body_dict.get("email", "") != "alex@example.com" or body_dict.get("password", "") != "SecretPass123!":
		print("[AUTH-CLI-002] FAIL: Incorrect payload for register")
		return false

	print("[AUTH-CLI-002] PASS: Register request contract verified!")
	return true

static func test_auth_003_login_request_flat_token_response() -> bool:
	print("[AUTH-CLI-003] Verifying login with REAL backend flat TokenResponse (user_id, email, display_name)...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 200,
			"error_code": "OK",
			"body": JSON.stringify({
				"access_token": "acc-flat-token-123",
				"refresh_token": "ref-flat-token-456",
				"token_type": "bearer",
				"expires_in": 1800,
				"user_id": "u-flat-999",
				"email": "student@example.com",
				"display_name": "Student Scholar"
			})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("student@example.com", "SecretPass123!")

	if not res.success or res.http_status != 200:
		print("[AUTH-CLI-003] FAIL: Login request failed")
		return false

	var session = client.get_session()
	if not session.is_active():
		print("[AUTH-CLI-003] FAIL: Session expected active after login")
		return false

	if session.access_token != "acc-flat-token-123" or session.refresh_token != "ref-flat-token-456" or session.expires_in != 1800:
		print("[AUTH-CLI-003] FAIL: Token / expiry parsing failed")
		return false

	var prof: Dictionary = session.user_profile
	if prof.get("id", "") != "u-flat-999" or prof.get("email", "") != "student@example.com" or prof.get("display_name", "") != "Student Scholar":
		print("[AUTH-CLI-003] FAIL: Flat user_id, email, display_name mapping failed")
		return false

	print("[AUTH-CLI-003] PASS: Flat backend TokenResponse verified!")
	return true

static func test_auth_004_login_request_nested_user_fallback() -> bool:
	print("[AUTH-CLI-004] Verifying login with nested 'user' dictionary fallback...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 200,
			"error_code": "OK",
			"body": JSON.stringify({
				"access_token": "acc-nested-123",
				"refresh_token": "ref-nested-456",
				"token_type": "bearer",
				"expires_in": 3600,
				"user": {
					"id": "u-nested-777",
					"email": "nested@example.com",
					"display_name": "Nested User"
				}
			})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("nested@example.com", "Pass")

	if not res.success:
		print("[AUTH-CLI-004] FAIL: Login request failed")
		return false

	var session = client.get_session()
	var prof: Dictionary = session.user_profile
	if prof.get("id", "") != "u-nested-777" or prof.get("email", "") != "nested@example.com" or prof.get("display_name", "") != "Nested User":
		print("[AUTH-CLI-004] FAIL: Nested user dictionary fallback mapping failed")
		return false

	print("[AUTH-CLI-004] PASS: Nested 'user' dictionary fallback verified!")
	return true

static func test_auth_005_refresh_session_contract() -> bool:
	print("[AUTH-CLI-005] Verifying refresh session request contract and token update...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()
	var last_req: Dictionary = {}

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		last_req.clear()
		last_req["body"] = body
		return {
			"status_code": 200,
			"error_code": "OK",
			"body": JSON.stringify({
				"access_token": "acc-token-new-999",
				"refresh_token": "ref-token-new-888",
				"token_type": "bearer",
				"expires_in": 1800,
				"user_id": "u-flat-999",
				"email": "student@example.com",
				"display_name": "Student Scholar"
			})
		}

	var client = AuthApiClientClass.new(config, transport)
	client.get_session().refresh_token = "ref-token-old-111"

	var res = await client.refresh_session()

	if not res.success or res.http_status != 200:
		print("[AUTH-CLI-005] FAIL: Refresh request failed")
		return false

	var body_dict: Dictionary = JSON.parse_string(last_req.get("body", "{}")) as Dictionary
	if body_dict.get("refresh_token", "") != "ref-token-old-111":
		print("[AUTH-CLI-005] FAIL: Refresh token parameter mismatch")
		return false

	var session = client.get_session()
	if session.access_token != "acc-token-new-999" or session.refresh_token != "ref-token-new-888":
		print("[AUTH-CLI-005] FAIL: Session tokens not updated after refresh")
		return false

	print("[AUTH-CLI-005] PASS: Refresh session contract verified!")
	return true

static func test_auth_006_logout_request_and_session_clearing() -> bool:
	print("[AUTH-CLI-006] Verifying logout request contract and session clearing...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 200,
			"error_code": "OK",
			"body": JSON.stringify({"message": "Successfully logged out"})
		}

	var client = AuthApiClientClass.new(config, transport)
	var session = client.get_session()
	session.access_token = "acc-active"
	session.refresh_token = "ref-active"

	var res = await client.logout()

	if not res.success or res.http_status != 200:
		print("[AUTH-CLI-006] FAIL: Logout request failed")
		return false

	if session.is_active():
		print("[AUTH-CLI-006] FAIL: Session expected inactive after logout")
		return false

	print("[AUTH-CLI-006] PASS: Logout request & session clearing verified!")
	return true

static func test_auth_007_me_request_bearer_header_format() -> bool:
	print("[AUTH-CLI-007] Verifying GET /me Bearer authorization header format...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()
	var last_req: Dictionary = {}

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		last_req.clear()
		last_req["headers"] = headers.duplicate()
		return {
			"status_code": 200,
			"error_code": "OK",
			"body": JSON.stringify({"id": "u-101", "email": "alex@example.com", "display_name": "Alex Scholar"})
		}

	var client = AuthApiClientClass.new(config, transport)
	client.get_session().access_token = "my-secret-access-token-99"

	var res = await client.get_me()

	if not res.success or res.http_status != 200:
		print("[AUTH-CLI-007] FAIL: Get Me request failed")
		return false

	var req_headers: Array = last_req.get("headers", [])
	var found_bearer: bool = false
	for h in req_headers:
		if str(h) == "Authorization: Bearer my-secret-access-token-99":
			found_bearer = true
			break

	if not found_bearer:
		print("[AUTH-CLI-007] FAIL: Bearer authorization header missing or malformed")
		return false

	print("[AUTH-CLI-007] PASS: GET /me Bearer authorization header verified!")
	return true

static func test_auth_008_forgot_password_contract() -> bool:
	print("[AUTH-CLI-008] Verifying forgot password request contract...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()
	var last_req: Dictionary = {}

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		last_req.clear()
		last_req["url"] = url
		last_req["method"] = method
		last_req["body"] = body
		return {
			"status_code": 200,
			"error_code": "OK",
			"body": JSON.stringify({"message": "Password reset email sent if account exists"})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.forgot_password("alex@example.com")

	if not res.success or res.http_status != 200:
		print("[AUTH-CLI-008] FAIL: Forgot password request failed")
		return false

	if last_req.get("url", "") != "http://127.0.0.1:8080/api/v1/auth/forgot-password" or last_req.get("method", 0) != HTTPClient.METHOD_POST:
		print("[AUTH-CLI-008] FAIL: Incorrect URL or method for forgot password")
		return false

	print("[AUTH-CLI-008] PASS: Forgot password contract verified!")
	return true

static func test_auth_009_reset_password_contract() -> bool:
	print("[AUTH-CLI-009] Verifying reset password request contract...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()
	var last_req: Dictionary = {}

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		last_req.clear()
		last_req["url"] = url
		last_req["method"] = method
		last_req["body"] = body
		return {
			"status_code": 200,
			"error_code": "OK",
			"body": JSON.stringify({"message": "Password reset successfully"})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.reset_password("reset-tok-555", "NewSecretPass456!")

	if not res.success or res.http_status != 200:
		print("[AUTH-CLI-009] FAIL: Reset password request failed")
		return false

	if last_req.get("url", "") != "http://127.0.0.1:8080/api/v1/auth/reset-password" or last_req.get("method", 0) != HTTPClient.METHOD_POST:
		print("[AUTH-CLI-009] FAIL: Incorrect URL or method for reset password")
		return false

	print("[AUTH-CLI-009] PASS: Reset password contract verified!")
	return true

static func test_auth_010_validation_error_mapping_400() -> bool:
	print("[AUTH-CLI-010] Verifying HTTP 400 -> VALIDATION_ERROR mapping...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 400,
			"error_code": "HTTP_ERROR",
			"body": JSON.stringify({"detail": "Invalid email address format"})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("invalid-email@domain.com", "pass")

	if res.success or res.http_status != 400 or res.error_code != "VALIDATION_ERROR":
		print("[AUTH-CLI-010] FAIL: Expected VALIDATION_ERROR for HTTP 400, got %s" % res.error_code)
		return false

	if res.message != "Invalid email address format":
		print("[AUTH-CLI-010] FAIL: Expected 'Invalid email address format', got %s" % res.message)
		return false

	print("[AUTH-CLI-010] PASS: HTTP 400 -> VALIDATION_ERROR mapping verified!")
	return true

static func test_auth_011_pydantic_422_array_detail_mapping() -> bool:
	print("[AUTH-CLI-011] Verifying Pydantic 422 Array detail -> VALIDATION_ERROR with msg extraction...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 422,
			"error_code": "HTTP_ERROR",
			"body": JSON.stringify({
				"detail": [
					{"type": "missing", "loc": ["body", "email"], "msg": "Field required", "input": null},
					{"type": "string_too_short", "loc": ["body", "password"], "msg": "String should have at least 8 characters", "input": "short"}
				]
			})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("alex@example.com", "short")

	if res.success or res.http_status != 422 or res.error_code != "VALIDATION_ERROR":
		print("[AUTH-CLI-011] FAIL: Expected VALIDATION_ERROR for HTTP 422")
		return false

	if not res.message.contains("Field required") or not res.message.contains("String should have at least 8 characters"):
		print("[AUTH-CLI-011] FAIL: Pydantic error msgs not extracted properly: %s" % res.message)
		return false

	print("[AUTH-CLI-011] PASS: Pydantic 422 Array detail msg extraction verified!")
	return true

static func test_auth_012_pydantic_422_string_detail_mapping() -> bool:
	print("[AUTH-CLI-012] Verifying Pydantic 422 String detail -> VALIDATION_ERROR...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 422,
			"error_code": "HTTP_ERROR",
			"body": JSON.stringify({"detail": "Invalid password requirements"})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("alex@example.com", "abc")

	if res.success or res.http_status != 422 or res.error_code != "VALIDATION_ERROR" or res.message != "Invalid password requirements":
		print("[AUTH-CLI-012] FAIL: String detail 422 mapping failed: %s" % res.message)
		return false

	print("[AUTH-CLI-012] PASS: Pydantic 422 String detail mapping verified!")
	return true

static func test_auth_013_pydantic_422_dict_detail_mapping() -> bool:
	print("[AUTH-CLI-013] Verifying Pydantic 422 Dict detail -> VALIDATION_ERROR...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 422,
			"error_code": "HTTP_ERROR",
			"body": JSON.stringify({"detail": {"msg": "Email already registered"}})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("alex@example.com", "pass")

	if res.success or res.http_status != 422 or res.error_code != "VALIDATION_ERROR" or res.message != "Email already registered":
		print("[AUTH-CLI-013] FAIL: Dict detail 422 mapping failed: %s" % res.message)
		return false

	print("[AUTH-CLI-013] PASS: Pydantic 422 Dict detail mapping verified!")
	return true

static func test_auth_014_pydantic_422_null_detail_mapping() -> bool:
	print("[AUTH-CLI-014] Verifying Pydantic 422 null/missing detail -> VALIDATION_ERROR fallback...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 422,
			"error_code": "HTTP_ERROR",
			"body": "{}"
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("alex@example.com", "pass")

	if res.success or res.http_status != 422 or res.error_code != "VALIDATION_ERROR" or res.message.is_empty():
		print("[AUTH-CLI-014] FAIL: Missing detail 422 fallback failed")
		return false

	print("[AUTH-CLI-014] PASS: Pydantic 422 null/missing detail fallback verified!")
	return true

static func test_auth_015_unauthorized_error_mapping_401() -> bool:
	print("[AUTH-CLI-015] Verifying HTTP 401 -> UNAUTHORIZED mapping...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 401,
			"error_code": "HTTP_ERROR",
			"body": JSON.stringify({"detail": "Invalid credentials or expired session"})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("alex@example.com", "WrongPass")

	if res.success or res.http_status != 401 or res.error_code != "UNAUTHORIZED":
		print("[AUTH-CLI-015] FAIL: Expected UNAUTHORIZED for HTTP 401, got %s" % res.error_code)
		return false

	print("[AUTH-CLI-015] PASS: HTTP 401 -> UNAUTHORIZED mapping verified!")
	return true

static func test_auth_016_server_error_mapping_500() -> bool:
	print("[AUTH-CLI-016] Verifying HTTP 500 -> SERVER_ERROR mapping...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 500,
			"error_code": "HTTP_ERROR",
			"body": JSON.stringify({"detail": "Internal database error"})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("alex@example.com", "Pass")

	if res.success or res.http_status != 500 or res.error_code != "SERVER_ERROR":
		print("[AUTH-CLI-016] FAIL: Expected SERVER_ERROR for HTTP 500, got %s" % res.error_code)
		return false

	print("[AUTH-CLI-016] PASS: HTTP 500 -> SERVER_ERROR mapping verified!")
	return true

static func test_auth_017_network_failure_mapping() -> bool:
	print("[AUTH-CLI-017] Verifying network failure -> NETWORK_ERROR mapping...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 0,
			"error_code": "NETWORK_ERROR",
			"error_message": "Could not connect to host",
			"body": ""
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("alex@example.com", "Pass")

	if res.success or res.http_status != 0 or res.error_code != "NETWORK_ERROR":
		print("[AUTH-CLI-017] FAIL: Expected NETWORK_ERROR for connection failure, got %s" % res.error_code)
		return false

	print("[AUTH-CLI-017] PASS: Network failure -> NETWORK_ERROR mapping verified!")
	return true

static func test_auth_018_timeout_mapping() -> bool:
	print("[AUTH-CLI-018] Verifying timeout -> TIMEOUT mapping...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 0,
			"error_code": "TIMEOUT",
			"error_message": "Network request timed out",
			"body": ""
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("alex@example.com", "Pass")

	if res.success or res.http_status != 0 or res.error_code != "TIMEOUT":
		print("[AUTH-CLI-018] FAIL: Expected TIMEOUT error code, got %s" % res.error_code)
		return false

	print("[AUTH-CLI-018] PASS: Timeout -> TIMEOUT mapping verified!")
	return true

static func test_auth_019_malformed_json_handling() -> bool:
	print("[AUTH-CLI-019] Verifying malformed JSON response handling...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 200,
			"error_code": "OK",
			"body": "<html>502 Bad Gateway</html>"
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("alex@example.com", "Pass")

	if res.success or res.error_code != "INVALID_RESPONSE":
		print("[AUTH-CLI-019] FAIL: Expected INVALID_RESPONSE for malformed JSON, got %s" % res.error_code)
		return false

	print("[AUTH-CLI-019] PASS: Malformed JSON response handling verified!")
	return true

static func test_auth_020_token_log_safety() -> bool:
	print("[AUTH-CLI-020] Verifying token log safety (tokens never emitted to log strings)...")
	var session = AuthSessionClass.new()
	session.access_token = "secret-access-token-999"
	session.refresh_token = "secret-refresh-token-888"
	session.user_profile = {"id": "u-101", "email": "alex@example.com"}

	var summary: Dictionary = session.to_safe_summary()
	var summary_str: String = str(summary)

	if summary_str.contains("secret-access-token-999") or summary_str.contains("secret-refresh-token-888"):
		print("[AUTH-CLI-020] FAIL: Token values leaked into summary string!")
		return false

	if not summary["has_access_token"] or not summary["has_refresh_token"]:
		print("[AUTH-CLI-020] FAIL: Summary flags expected true")
		return false

	print("[AUTH-CLI-020] PASS: Token log safety verified!")
	return true

static func test_auth_021_in_memory_session_only() -> bool:
	print("[AUTH-CLI-021] Verifying in-memory session model (zero disk persistence)...")
	var session = AuthSessionClass.new()
	session.access_token = "temp-token-in-memory"
	session.refresh_token = "temp-refresh-in-memory"

	var save_store: SaveFileStore = SaveFileStore.new("user://")
	var exists_before: bool = save_store.file_exists(save_store.main_path)

	session.clear()
	var exists_after: bool = save_store.file_exists(save_store.main_path)

	if exists_before != exists_after:
		print("[AUTH-CLI-021] FAIL: Save file state altered!")
		return false

	if session.is_active():
		print("[AUTH-CLI-021] FAIL: Session expected inactive after clear")
		return false

	print("[AUTH-CLI-021] PASS: In-memory session model verified!")
	return true

static func test_auth_022_expires_in_type_safety() -> bool:
	print("[AUTH-CLI-022] Verifying safe expires_in type parsing (int, float, string)...")
	var session = AuthSessionClass.new()

	session.update_from_dict({"expires_in": 1800})
	if session.expires_in != 1800:
		print("[AUTH-CLI-022] FAIL: int expires_in failed")
		return false

	session.update_from_dict({"expires_in": 3600.0})
	if session.expires_in != 3600:
		print("[AUTH-CLI-022] FAIL: float expires_in failed")
		return false

	session.update_from_dict({"expires_in": "7200"})
	if session.expires_in != 7200:
		print("[AUTH-CLI-022] FAIL: string expires_in failed")
		return false

	print("[AUTH-CLI-022] PASS: Safe expires_in type parsing verified!")
	return true

static func test_auth_023_zero_state_mutation() -> bool:
	print("[AUTH-CLI-023] Verifying zero state mutation across Auth API Client operations...")
	var save_store: SaveFileStore = SaveFileStore.new("user://")
	var exists_before: bool = save_store.file_exists(save_store.main_path)

	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()
	transport.mock_handler = func(_u, _m, _h, _b, _t):
		return {"status_code": 200, "error_code": "OK", "body": "{}"}

	var client = AuthApiClientClass.new(config, transport)
	await client.login("alex@example.com", "Pass")
	await client.get_me()
	await client.logout()

	var exists_after: bool = save_store.file_exists(save_store.main_path)
	if exists_before != exists_after:
		print("[AUTH-CLI-023] FAIL: Save file existence mutated!")
		return false

	print("[AUTH-CLI-023] PASS: Zero state mutation verified!")
	return true

static func test_auth_024_visual_and_splash_locks() -> bool:
	print("[AUTH-CLI-024] Verifying visual & splash sequence locks remain unaltered...")
	var BootSequenceClass = load("res://src/ui/boot/boot_sequence.gd") as GDScript
	if abs(float(BootSequenceClass.get_script_constant_map().get("GODOT_WHITE_PRE_HOLD", 0.0)) - 0.75) > 0.001:
		print("[AUTH-CLI-024] FAIL: GODOT_WHITE_PRE_HOLD constant altered!")
		return false

	if abs(float(BootSequenceClass.get_script_constant_map().get("GODOT_FADE_IN", 0.0)) - 0.55) > 0.001:
		print("[AUTH-CLI-024] FAIL: GODOT_FADE_IN constant altered!")
		return false

	print("[AUTH-CLI-024] PASS: Visual & splash sequence locks verified!")
	return true
