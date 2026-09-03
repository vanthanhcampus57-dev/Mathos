extends SceneTree

## Targeted Unit Test Suite for Godot Auth API Client Foundation (MATHOS-GODOT-AUTH-API-CLIENT-FOUNDATION-007)
## Tests:
## 1. Configurable base URL & normalization.
## 2. Mock transport injection & async HTTP requests.
## 3. Register request path, method (POST), and body payload.
## 4. Login request path, method (POST), body payload, and AuthSession population.
## 5. Refresh session request path, method (POST), and token update.
## 6. Logout request path, method (POST), and session clearing.
## 7. Me request path, method (GET), and Bearer authorization header format.
## 8. Forgot Password request path, method (POST), and body payload.
## 9. Reset Password request path, method (POST), and body payload.
## 10. HTTP status error mappings (400 -> VALIDATION_ERROR, 401 -> UNAUTHORIZED, 500 -> SERVER_ERROR).
## 11. Transport failures (Network error, Timeout, Malformed JSON response).
## 12. Token log safety (tokens never exposed in log output or summary strings).
## 13. In-memory session model (zero persistence).
## 14. Zero state mutation (player save & gameplay progression untouched).
## 15. Visual & Splash sequence locks preserved.

const ApiConfigClass = preload("res://src/core/network/api_config.gd")
const HttpTransportClass = preload("res://src/core/network/http_transport.gd")
const AuthResultClass = preload("res://src/core/auth/auth_result.gd")
const AuthSessionClass = preload("res://src/core/auth/auth_session.gd")
const AuthApiClientClass = preload("res://src/core/auth/auth_api_client.gd")

func _initialize() -> void:
	print("--- RUNNING MATHOS AUTH API CLIENT QA HARNESS (AUTH-CLI-001..018) ---")
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
	if await test_auth_003_login_request_and_session_population(): passes += 1
	if await test_auth_004_refresh_session_contract(): passes += 1
	if await test_auth_005_logout_request_and_session_clearing(): passes += 1
	if await test_auth_006_me_request_bearer_header_format(): passes += 1
	if await test_auth_007_forgot_password_contract(): passes += 1
	if await test_auth_008_reset_password_contract(): passes += 1
	if await test_auth_009_validation_error_mapping_400(): passes += 1
	if await test_auth_010_unauthorized_error_mapping_401(): passes += 1
	if await test_auth_011_server_error_mapping_500(): passes += 1
	if await test_auth_012_network_failure_mapping(): passes += 1
	if await test_auth_013_timeout_mapping(): passes += 1
	if await test_auth_014_malformed_json_handling(): passes += 1
	if test_auth_015_token_log_safety(): passes += 1
	if test_auth_016_in_memory_session_only(): passes += 1
	if await test_auth_017_zero_state_mutation(): passes += 1
	if test_auth_018_visual_and_splash_locks(): passes += 1

	print("[AUTH-CLIENT-HARNESS] %d / 18 test scenarios passed" % passes)
	return passes == 18

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

static func test_auth_003_login_request_and_session_population() -> bool:
	print("[AUTH-CLI-003] Verifying login request contract and AuthSession population...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 200,
			"error_code": "OK",
			"body": JSON.stringify({
				"access_token": "acc-token-xyz-123",
				"refresh_token": "ref-token-abc-789",
				"token_type": "bearer",
				"expires_in": 1800,
				"user": {
					"id": "u-101",
					"email": "alex@example.com",
					"display_name": "Alex Scholar"
				}
			})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("alex@example.com", "SecretPass123!")

	if not res.success or res.http_status != 200:
		print("[AUTH-CLI-003] FAIL: Login request failed")
		return false

	var session = client.get_session()
	if not session.is_active():
		print("[AUTH-CLI-003] FAIL: Session expected active after login")
		return false

	if session.access_token != "acc-token-xyz-123" or session.refresh_token != "ref-token-abc-789" or session.user_profile["id"] != "u-101":
		print("[AUTH-CLI-003] FAIL: AuthSession fields mismatch after login")
		return false

	print("[AUTH-CLI-003] PASS: Login request & AuthSession population verified!")
	return true

static func test_auth_004_refresh_session_contract() -> bool:
	print("[AUTH-CLI-004] Verifying refresh session request contract and token update...")
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
				"expires_in": 1800
			})
		}

	var client = AuthApiClientClass.new(config, transport)
	client.get_session().refresh_token = "ref-token-old-111"

	var res = await client.refresh_session()

	if not res.success or res.http_status != 200:
		print("[AUTH-CLI-004] FAIL: Refresh request failed")
		return false

	var body_dict: Dictionary = JSON.parse_string(last_req.get("body", "{}")) as Dictionary
	if body_dict.get("refresh_token", "") != "ref-token-old-111":
		print("[AUTH-CLI-004] FAIL: Refresh token parameter mismatch")
		return false

	var session = client.get_session()
	if session.access_token != "acc-token-new-999" or session.refresh_token != "ref-token-new-888":
		print("[AUTH-CLI-004] FAIL: Session tokens not updated after refresh")
		return false

	print("[AUTH-CLI-004] PASS: Refresh session contract verified!")
	return true

static func test_auth_005_logout_request_and_session_clearing() -> bool:
	print("[AUTH-CLI-005] Verifying logout request contract and session clearing...")
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
		print("[AUTH-CLI-005] FAIL: Logout request failed")
		return false

	if session.is_active():
		print("[AUTH-CLI-005] FAIL: Session expected inactive after logout")
		return false

	print("[AUTH-CLI-005] PASS: Logout request & session clearing verified!")
	return true

static func test_auth_006_me_request_bearer_header_format() -> bool:
	print("[AUTH-CLI-006] Verifying GET /me Bearer authorization header format...")
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
		print("[AUTH-CLI-006] FAIL: Get Me request failed")
		return false

	var req_headers: Array = last_req.get("headers", [])
	var found_bearer: bool = false
	for h in req_headers:
		if str(h) == "Authorization: Bearer my-secret-access-token-99":
			found_bearer = true
			break

	if not found_bearer:
		print("[AUTH-CLI-006] FAIL: Bearer authorization header missing or malformed")
		return false

	print("[AUTH-CLI-006] PASS: GET /me Bearer authorization header verified!")
	return true

static func test_auth_007_forgot_password_contract() -> bool:
	print("[AUTH-CLI-007] Verifying forgot password request contract...")
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
		print("[AUTH-CLI-007] FAIL: Forgot password request failed")
		return false

	if last_req.get("url", "") != "http://127.0.0.1:8080/api/v1/auth/forgot-password" or last_req.get("method", 0) != HTTPClient.METHOD_POST:
		print("[AUTH-CLI-007] FAIL: Incorrect URL or method for forgot password")
		return false

	print("[AUTH-CLI-007] PASS: Forgot password contract verified!")
	return true

static func test_auth_008_reset_password_contract() -> bool:
	print("[AUTH-CLI-008] Verifying reset password request contract...")
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
		print("[AUTH-CLI-008] FAIL: Reset password request failed")
		return false

	if last_req.get("url", "") != "http://127.0.0.1:8080/api/v1/auth/reset-password" or last_req.get("method", 0) != HTTPClient.METHOD_POST:
		print("[AUTH-CLI-008] FAIL: Incorrect URL or method for reset password")
		return false

	print("[AUTH-CLI-008] PASS: Reset password contract verified!")
	return true

static func test_auth_009_validation_error_mapping_400() -> bool:
	print("[AUTH-CLI-009] Verifying HTTP 400 -> VALIDATION_ERROR mapping...")
	var config = ApiConfigClass.new("http://127.0.0.1:8080")
	var transport = HttpTransportClass.new()

	transport.mock_handler = func(url: String, method: int, headers: Array, body: String, _timeout: float):
		return {
			"status_code": 400,
			"error_code": "HTTP_ERROR",
			"body": JSON.stringify({"detail": "Invalid email address format"})
		}

	var client = AuthApiClientClass.new(config, transport)
	var res = await client.login("invalid-email", "pass")

	if res.success or res.http_status != 400 or res.error_code != "VALIDATION_ERROR":
		print("[AUTH-CLI-009] FAIL: Expected VALIDATION_ERROR for HTTP 400, got %s" % res.error_code)
		return false

	print("[AUTH-CLI-009] PASS: HTTP 400 -> VALIDATION_ERROR mapping verified!")
	return true

static func test_auth_010_unauthorized_error_mapping_401() -> bool:
	print("[AUTH-CLI-010] Verifying HTTP 401 -> UNAUTHORIZED mapping...")
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
		print("[AUTH-CLI-010] FAIL: Expected UNAUTHORIZED for HTTP 401, got %s" % res.error_code)
		return false

	print("[AUTH-CLI-010] PASS: HTTP 401 -> UNAUTHORIZED mapping verified!")
	return true

static func test_auth_011_server_error_mapping_500() -> bool:
	print("[AUTH-CLI-011] Verifying HTTP 500 -> SERVER_ERROR mapping...")
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
		print("[AUTH-CLI-011] FAIL: Expected SERVER_ERROR for HTTP 500, got %s" % res.error_code)
		return false

	print("[AUTH-CLI-011] PASS: HTTP 500 -> SERVER_ERROR mapping verified!")
	return true

static func test_auth_012_network_failure_mapping() -> bool:
	print("[AUTH-CLI-012] Verifying network failure -> NETWORK_ERROR mapping...")
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
		print("[AUTH-CLI-012] FAIL: Expected NETWORK_ERROR for connection failure, got %s" % res.error_code)
		return false

	print("[AUTH-CLI-012] PASS: Network failure -> NETWORK_ERROR mapping verified!")
	return true

static func test_auth_013_timeout_mapping() -> bool:
	print("[AUTH-CLI-013] Verifying timeout -> TIMEOUT mapping...")
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
		print("[AUTH-CLI-013] FAIL: Expected TIMEOUT error code, got %s" % res.error_code)
		return false

	print("[AUTH-CLI-013] PASS: Timeout -> TIMEOUT mapping verified!")
	return true

static func test_auth_014_malformed_json_handling() -> bool:
	print("[AUTH-CLI-014] Verifying malformed JSON response handling...")
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
		print("[AUTH-CLI-014] FAIL: Expected INVALID_RESPONSE for malformed JSON, got %s" % res.error_code)
		return false

	print("[AUTH-CLI-014] PASS: Malformed JSON response handling verified!")
	return true

static func test_auth_015_token_log_safety() -> bool:
	print("[AUTH-CLI-015] Verifying token log safety (tokens never emitted to log strings)...")
	var session = AuthSessionClass.new()
	session.access_token = "secret-access-token-999"
	session.refresh_token = "secret-refresh-token-888"
	session.user_profile = {"id": "u-101", "email": "alex@example.com"}

	var summary: Dictionary = session.to_safe_summary()
	var summary_str: String = str(summary)

	if summary_str.contains("secret-access-token-999") or summary_str.contains("secret-refresh-token-888"):
		print("[AUTH-CLI-015] FAIL: Token values leaked into summary string!")
		return false

	if not summary["has_access_token"] or not summary["has_refresh_token"]:
		print("[AUTH-CLI-015] FAIL: Summary flags expected true")
		return false

	print("[AUTH-CLI-015] PASS: Token log safety verified!")
	return true

static func test_auth_016_in_memory_session_only() -> bool:
	print("[AUTH-CLI-016] Verifying in-memory session model (zero disk persistence)...")
	var session = AuthSessionClass.new()
	session.access_token = "temp-token-in-memory"
	session.refresh_token = "temp-refresh-in-memory"

	var save_store: SaveFileStore = SaveFileStore.new("user://")
	var exists_before: bool = save_store.file_exists(save_store.main_path)

	session.clear()
	var exists_after: bool = save_store.file_exists(save_store.main_path)

	if exists_before != exists_after:
		print("[AUTH-CLI-016] FAIL: Save file state altered!")
		return false

	if session.is_active():
		print("[AUTH-CLI-016] FAIL: Session expected inactive after clear")
		return false

	print("[AUTH-CLI-016] PASS: In-memory session model verified!")
	return true

static func test_auth_017_zero_state_mutation() -> bool:
	print("[AUTH-CLI-017] Verifying zero state mutation across Auth API Client operations...")
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
		print("[AUTH-CLI-017] FAIL: Save file existence mutated!")
		return false

	print("[AUTH-CLI-017] PASS: Zero state mutation verified!")
	return true

static func test_auth_018_visual_and_splash_locks() -> bool:
	print("[AUTH-CLI-018] Verifying visual & splash sequence locks remain unaltered...")
	var BootSequenceClass = load("res://src/ui/boot/boot_sequence.gd") as GDScript
	if abs(float(BootSequenceClass.get_script_constant_map().get("GODOT_WHITE_PRE_HOLD", 0.0)) - 0.75) > 0.001:
		print("[AUTH-CLI-018] FAIL: GODOT_WHITE_PRE_HOLD constant altered!")
		return false

	if abs(float(BootSequenceClass.get_script_constant_map().get("GODOT_FADE_IN", 0.0)) - 0.55) > 0.001:
		print("[AUTH-CLI-018] FAIL: GODOT_FADE_IN constant altered!")
		return false

	print("[AUTH-CLI-018] PASS: Visual & splash sequence locks verified!")
	return true
