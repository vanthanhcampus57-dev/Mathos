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

	# Safe type parsing for expires_in (handles int, float, string)
	if d.has("expires_in"):
		var raw_exp: Variant = d["expires_in"]
		if raw_exp is int or raw_exp is float:
			expires_in = int(raw_exp)
		elif raw_exp is String and (raw_exp as String).is_valid_int():
			expires_in = (raw_exp as String).to_int()

	# User Profile parsing (supports BOTH flat backend shape and nested "user" dict fallback)
	var prof: Dictionary = user_profile.duplicate(true)

	# 1. Flat backend fields (Primary contract: user_id, email, display_name)
	if d.has("user_id"):
		prof["id"] = str(d["user_id"])
	elif d.has("id"):
		prof["id"] = str(d["id"])

	if d.has("email") and d["email"] is String:
		prof["email"] = d["email"]
	if d.has("display_name") and d["display_name"] is String:
		prof["display_name"] = d["display_name"]

	# 2. Nested "user" dictionary fallback
	if d.has("user") and d["user"] is Dictionary:
		var u_dict: Dictionary = d["user"] as Dictionary
		if u_dict.has("id"): prof["id"] = str(u_dict["id"])
		if u_dict.has("user_id"): prof["id"] = str(u_dict["user_id"])
		if u_dict.has("email") and u_dict["email"] is String: prof["email"] = u_dict["email"]
		if u_dict.has("display_name") and u_dict["display_name"] is String: prof["display_name"] = u_dict["display_name"]

	user_profile = prof

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
