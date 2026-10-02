class_name ApiConfig
extends RefCounted

## Centralized API Configuration & Endpoint Path Registry.
## Defaults to production endpoint (https://api.mathos.vn) with full runtime override capability.

const DEFAULT_BASE_URL: String = "https://api.mathos.vn"
const LOCAL_DEV_BASE_URL: String = "http://127.0.0.1:8080"

const REGISTER_PATH: String = "/api/v1/auth/register"
const LOGIN_PATH: String = "/api/v1/auth/login"
const REFRESH_PATH: String = "/api/v1/auth/refresh"
const LOGOUT_PATH: String = "/api/v1/auth/logout"
const ME_PATH: String = "/api/v1/auth/me"
const FORGOT_PASSWORD_PATH: String = "/api/v1/auth/forgot-password"
const RESET_PASSWORD_PATH: String = "/api/v1/auth/reset-password"

var _base_url: String = DEFAULT_BASE_URL

func _init(base_url: String = "") -> void:
	if base_url.is_empty():
		var env_url: String = OS.get_environment("MATHOS_API_URL")
		if not env_url.is_empty():
			base_url = env_url
		else:
			base_url = DEFAULT_BASE_URL
	set_base_url(base_url)

func set_base_url(url: String) -> void:
	var trimmed: String = url.strip_edges()
	if trimmed.ends_with("/"):
		trimmed = trimmed.substr(0, trimmed.length() - 1)
	if trimmed.is_empty():
		trimmed = DEFAULT_BASE_URL
	_base_url = trimmed

func get_base_url() -> String:
	return _base_url

func get_endpoint_url(path: String) -> String:
	var clean_path: String = path.strip_edges()
	if not clean_path.begins_with("/"):
		clean_path = "/" + clean_path
	return _base_url + clean_path
