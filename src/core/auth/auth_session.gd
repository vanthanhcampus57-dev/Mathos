class_name AuthSession
extends RefCounted

## In-Memory Auth Session Model for Mathos Auth API Client.
## Stores access_token, refresh_token, token_type, expires_in, and user_profile in-memory ONLY.
## MUST NOT be written to disk, save files, plain text configs, or logs.

var access_token: String = ""
var refresh_token: String = ""
var token_type: String = "bearer"
var expires_in: int = 0
var user_profile: Dictionary = {}

func is_active() -> bool:
	return not access_token.strip_edges().is_empty()

func clear() -> void:
	access_token = ""
	refresh_token = ""
	token_type = "bearer"
	expires_in = 0
	user_profile.clear()

func update_from_dict(d: Dictionary) -> void:
	if d.has("access_token") and d["access_token"] is String:
		access_token = d["access_token"]
	if d.has("refresh_token") and d["refresh_token"] is String:
		refresh_token = d["refresh_token"]
	if d.has("token_type") and d["token_type"] is String:
		token_type = d["token_type"]
	if d.has("expires_in") and (d["expires_in"] is int or d["expires_in"] is float):
		expires_in = int(d["expires_in"])
	if d.has("user") and d["user"] is Dictionary:
		user_profile = d["user"].duplicate(true)

func to_safe_summary() -> Dictionary:
	return {
		"is_active": is_active(),
		"token_type": token_type,
		"expires_in": expires_in,
		"has_access_token": not access_token.is_empty(),
		"has_refresh_token": not refresh_token.is_empty(),
		"user_id": user_profile.get("id", ""),
		"user_email": user_profile.get("email", ""),
		"user_name": user_profile.get("display_name", "")
	}
