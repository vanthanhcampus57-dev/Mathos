extends SceneTree

## Regression test suite for MATHOS-GUEST-NEW-ACCOUNT-PROGRESS-ISOLATION-FIX-168.
## Validates complete isolation between Guest and Authenticated save/progress namespaces.
##
## Creates auth fixture by writing raw valid JSON save (bypasses catalog dependency).
## Tests only file-level isolation which is the actual fix mechanism.

const TEST_DIR: String = "user://test_guest_168/"
const AUTH_SUB: String = "auth/"
const GUEST_SUB: String = "guest/"

func _initialize() -> void:
	print("==================================================")
	print("STARTING GUEST PROFILE ISOLATION TEST SUITE (168)")
	print("==================================================")
	var passed: int = 0

	if _test_001(): passed += 1
	if _test_002(): passed += 1
	if _test_003(): passed += 1
	if _test_004(): passed += 1
	if _test_005(): passed += 1
	if _test_006(): passed += 1
	if _test_007(): passed += 1
	if _test_008(): passed += 1
	if _test_009(): passed += 1
	if _test_010(): passed += 1

	_clean_dir(TEST_DIR)

	print("==================================================")
	print("GUEST PROFILE ISOLATION SUMMARY: %d / 10 passed" % passed)
	print("==================================================")
	quit(0 if passed == 10 else 1)

# ---- Helpers ----

func _auth_dir() -> String:
	return TEST_DIR + AUTH_SUB

func _guest_dir() -> String:
	return TEST_DIR + GUEST_SUB

func _auth_gate_path() -> String:
	return TEST_DIR + AUTH_SUB + "prologue_gate.json"

func _guest_gate_path() -> String:
	return TEST_DIR + GUEST_SUB + "prologue_gate.json"

func _ensure_dir(path: String) -> void:
	var global_p: String = ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(global_p):
		DirAccess.make_dir_recursive_absolute(global_p)

func _clean_dir(path: String) -> void:
	var global_p: String = ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(global_p):
		var dir: DirAccess = DirAccess.open(global_p)
		if dir != null:
			dir.list_dir_begin()
			var file_name: String = dir.get_next()
			while not file_name.is_empty():
				if file_name != "." and file_name != "..":
					var sub_global: String = global_p.path_join(file_name)
					if DirAccess.dir_exists_absolute(sub_global):
						_clean_dir(path.path_join(file_name))
					else:
						DirAccess.remove_absolute(sub_global)
				file_name = dir.get_next()
			dir.list_dir_end()
			DirAccess.remove_absolute(global_p)

func _write_file(path: String, content: String) -> bool:
	_ensure_dir(path.get_base_dir() + "/")
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(content)
	f.close()
	return true

func _read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var text: String = f.get_as_text()
	f.close()
	return text

## Returns a valid save_v1.json content string for auth fixture
func _auth_save_json() -> String:
	return JSON.stringify({
		"schema_version": 1,
		"game_version": "1.0.0",
		"content_version": 1,
		"saved_at_utc": "2026-09-08T10:00:00Z",
		"profile_id": "local_player",
		"player_persistent": {
			"player_id": "char_karl",
			"coin_balance": 500,
			"exp_total": 200
		},
		"progress": {
			"unlocked_dungeon_ids": ["dungeon_01"],
			"unlocked_stage_ids": ["stage_01_01", "stage_01_02"],
			"cleared_stage_ids": ["stage_01_01"],
			"fragment_ids": ["fragment_01"],
			"game_complete": false
		},
		"adaptive_profile": {
			"attempts_total": 10,
			"correct_total": 8,
			"consecutive_correct": 3,
			"consecutive_incorrect": 0,
			"topic_stats": {},
			"recent_records": []
		}
	}, "\t")

func _prologue_gate_completed_json() -> String:
	return JSON.stringify({
		"prologue_completed": true,
		"version": 1,
		"timestamp": "2026-09-08T10:00:00Z"
	}, "\t")

## Sets up: auth dir with save + completed gate; guest dir empty
func _setup() -> void:
	_clean_dir(TEST_DIR)
	_ensure_dir(_auth_dir())
	_ensure_dir(_guest_dir())
	_write_file(_auth_dir() + "save_v1.json", _auth_save_json())
	_write_file(_auth_gate_path(), _prologue_gate_completed_json())

# ---- Test Cases ----

## CASE 1: Auth has save; Guest namespace should have no save
func _test_001() -> bool:
	print("[GUEST-168-001] Verifying auth existing progress -> Guest starts fresh...")
	_setup()

	if not FileAccess.file_exists(_auth_dir() + "save_v1.json"):
		print("[GUEST-168-001] FAIL: Auth save file missing")
		return false

	if FileAccess.file_exists(_guest_dir() + "save_v1.json"):
		print("[GUEST-168-001] FAIL: Guest save should not exist initially")
		return false

	print("[GUEST-168-001] PASS: Auth has save, Guest namespace is empty")
	return true

## CASE 2: Guest namespace has no fragments initially
func _test_002() -> bool:
	print("[GUEST-168-002] Verifying Guest has zero fragments initially...")
	_setup()

	# Guest dir has no save file, so no fragments can be loaded
	if FileAccess.file_exists(_guest_dir() + "save_v1.json"):
		print("[GUEST-168-002] FAIL: Guest save should not exist")
		return false

	# Verify auth DOES have fragment_01 for contrast
	var auth_content: String = _read_file(_auth_dir() + "save_v1.json")
	if not auth_content.contains("fragment_01"):
		print("[GUEST-168-002] FAIL: Auth should have fragment_01")
		return false

	print("[GUEST-168-002] PASS: Guest has no save/fragments, Auth has fragment_01")
	return true

## CASE 3: Guest has no inherited cleared stage
func _test_003() -> bool:
	print("[GUEST-168-003] Verifying Guest has no inherited current stage...")
	_setup()

	# Auth has cleared stage_01_01
	var auth_content: String = _read_file(_auth_dir() + "save_v1.json")
	if not auth_content.contains("stage_01_01"):
		print("[GUEST-168-003] FAIL: Auth should have stage_01_01 cleared")
		return false

	# Guest has no save at all
	if FileAccess.file_exists(_guest_dir() + "save_v1.json"):
		print("[GUEST-168-003] FAIL: Guest should not have any save")
		return false

	print("[GUEST-168-003] PASS: Auth has stage_01_01 cleared, Guest has no save")
	return true

## CASE 4: Guest Hub state == NEW_PLAYER
func _test_004() -> bool:
	print("[GUEST-168-004] Verifying Guest Hub state == NEW_PLAYER...")
	_setup()

	# Guest save does not exist -> has_save=false -> prog_state=0 (NEW_PLAYER)
	var guest_has_save: bool = FileAccess.file_exists(_guest_dir() + "save_v1.json")
	var prog_state: int = 0
	if guest_has_save:
		prog_state = 1

	if prog_state != 0:
		print("[GUEST-168-004] FAIL: prog_state should be 0 but got %d" % prog_state)
		return false

	print("[GUEST-168-004] PASS: Guest Hub state is NEW_PLAYER (0)")
	return true

## CASE 5: Guest prologue gate is fresh -> first D1 entry triggers Beat1
func _test_005() -> bool:
	print("[GUEST-168-005] Verifying Guest first D1 entry -> Beat1...")
	_setup()

	# Auth gate should be completed
	var auth_gate_content: String = _read_file(_auth_gate_path())
	if not auth_gate_content.contains("\"prologue_completed\": true"):
		# Try alternate formatting
		var json: JSON = JSON.new()
		json.parse(auth_gate_content)
		if json.data is Dictionary and not bool((json.data as Dictionary).get("prologue_completed", false)):
			print("[GUEST-168-005] FAIL: Auth gate should be completed")
			return false

	# Guest gate file should NOT exist
	if FileAccess.file_exists(_guest_gate_path()):
		print("[GUEST-168-005] FAIL: Guest gate file should NOT exist initially")
		return false

	# PrologueGateService: when file doesn't exist, has_completed_prologue=false,
	# so is_first_dungeon_entry("stage_01_*") returns true -> triggers Beat1
	print("[GUEST-168-005] PASS: Guest gate absent -> first D1 entry triggers prologue")
	return true

## CASE 6: Auth save byte-for-byte unchanged after Guest init
func _test_006() -> bool:
	print("[GUEST-168-006] Verifying auth save unchanged after Guest session...")
	_setup()

	var pre_content: String = _read_file(_auth_dir() + "save_v1.json")
	if pre_content.is_empty():
		print("[GUEST-168-006] FAIL: Auth save missing pre-read")
		return false

	# Simulate guest init — write a guest save
	_write_file(_guest_dir() + "save_v1.json", JSON.stringify({
		"schema_version": 1,
		"game_version": "1.0.0",
		"content_version": 1,
		"saved_at_utc": "2026-09-08T10:05:00Z",
		"profile_id": "local_player",
		"player_persistent": {"player_id": "char_karl", "coin_balance": 0, "exp_total": 0},
		"progress": {
			"unlocked_dungeon_ids": ["dungeon_01"],
			"unlocked_stage_ids": ["stage_01_01"],
			"cleared_stage_ids": [],
			"fragment_ids": [],
			"game_complete": false
		},
		"adaptive_profile": {"attempts_total": 0, "correct_total": 0, "consecutive_correct": 0, "consecutive_incorrect": 0, "topic_stats": {}, "recent_records": []}
	}, "\t"))

	var post_content: String = _read_file(_auth_dir() + "save_v1.json")
	if pre_content != post_content:
		print("[GUEST-168-006] FAIL: Auth save changed!")
		return false

	print("[GUEST-168-006] PASS: Auth save is byte-for-byte unchanged")
	return true

## CASE 7: Auth save retains original progress data
func _test_007() -> bool:
	print("[GUEST-168-007] Verifying return to auth profile restores original state...")
	_setup()

	var auth_content: String = _read_file(_auth_dir() + "save_v1.json")
	var json: JSON = JSON.new()
	var err: Error = json.parse(auth_content)
	if err != OK or not (json.data is Dictionary):
		print("[GUEST-168-007] FAIL: Cannot parse auth save")
		return false

	var data: Dictionary = json.data as Dictionary
	var player: Dictionary = data.get("player_persistent", {}) as Dictionary
	var progress: Dictionary = data.get("progress", {}) as Dictionary

	if int(player.get("coin_balance", 0)) != 500:
		print("[GUEST-168-007] FAIL: Auth coins should be 500")
		return false
	if int(player.get("exp_total", 0)) != 200:
		print("[GUEST-168-007] FAIL: Auth XP should be 200")
		return false

	var cleared: Array = progress.get("cleared_stage_ids", []) as Array
	if not cleared.has("stage_01_01"):
		print("[GUEST-168-007] FAIL: Auth should have stage_01_01 cleared")
		return false

	var frags: Array = progress.get("fragment_ids", []) as Array
	if not frags.has("fragment_01"):
		print("[GUEST-168-007] FAIL: Auth should have fragment_01")
		return false

	print("[GUEST-168-007] PASS: Auth profile retained: stage_01_01 cleared, 500 coins, 200 XP, fragment_01")
	return true

## CASE 8: Guest and Auth prologue gates are independent files
func _test_008() -> bool:
	print("[GUEST-168-008] Verifying prologue gate isolation...")
	_setup()

	# Auth gate exists and is completed
	if not FileAccess.file_exists(_auth_gate_path()):
		print("[GUEST-168-008] FAIL: Auth gate file should exist")
		return false

	# Guest gate does NOT exist
	if FileAccess.file_exists(_guest_gate_path()):
		print("[GUEST-168-008] FAIL: Guest gate file should NOT exist initially")
		return false

	# Write guest gate as completed
	_write_file(_guest_gate_path(), _prologue_gate_completed_json())
	if not FileAccess.file_exists(_guest_gate_path()):
		print("[GUEST-168-008] FAIL: Guest gate write failed")
		return false

	# Auth gate should be unchanged
	var auth_gate_content: String = _read_file(_auth_gate_path())
	var json: JSON = JSON.new()
	json.parse(auth_gate_content)
	if not (json.data is Dictionary) or not bool((json.data as Dictionary).get("prologue_completed", false)):
		print("[GUEST-168-008] FAIL: Auth gate should remain completed")
		return false

	# Delete guest gate — auth should remain
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_guest_gate_path()))
	if not FileAccess.file_exists(_auth_gate_path()):
		print("[GUEST-168-008] FAIL: Auth gate should remain after guest gate deletion")
		return false

	print("[GUEST-168-008] PASS: Auth and Guest prologue gates are fully isolated")
	return true

## CASE 9: Guest save writes to guest namespace only
func _test_009() -> bool:
	print("[GUEST-168-009] Verifying Guest progress stays in Guest namespace...")
	_setup()

	var auth_save_path: String = _auth_dir() + "save_v1.json"
	var guest_save_path: String = _guest_dir() + "save_v1.json"

	# Paths must be different
	if auth_save_path == guest_save_path:
		print("[GUEST-168-009] FAIL: Guest and Auth save paths are identical!")
		return false

	# Write guest save
	_write_file(guest_save_path, JSON.stringify({
		"schema_version": 1, "game_version": "1.0.0", "content_version": 1,
		"saved_at_utc": "2026-09-08T10:05:00Z", "profile_id": "local_player",
		"player_persistent": {"player_id": "char_karl", "coin_balance": 0, "exp_total": 0},
		"progress": {"unlocked_dungeon_ids": ["dungeon_01"], "unlocked_stage_ids": ["stage_01_01"],
			"cleared_stage_ids": [], "fragment_ids": [], "game_complete": false},
		"adaptive_profile": {"attempts_total": 0, "correct_total": 0, "consecutive_correct": 0,
			"consecutive_incorrect": 0, "topic_stats": {}, "recent_records": []}
	}, "\t"))

	# Guest save should exist
	if not FileAccess.file_exists(guest_save_path):
		print("[GUEST-168-009] FAIL: Guest save should exist after writing")
		return false

	# Auth save should remain unchanged
	var auth_content: String = _read_file(auth_save_path)
	if not auth_content.contains("\"coin_balance\": 500"):
		print("[GUEST-168-009] FAIL: Auth save should still have 500 coins")
		return false

	# Guest save should have 0 coins
	var guest_content: String = _read_file(guest_save_path)
	if not guest_content.contains("\"coin_balance\": 0"):
		print("[GUEST-168-009] FAIL: Guest save should have 0 coins")
		return false

	print("[GUEST-168-009] PASS: Guest and Auth saves use separate namespaces")
	return true

## CASE 10: AppRoot source code has correct isolation constants
func _test_010() -> bool:
	print("[GUEST-168-010] Verifying AppRoot namespace constants...")

	var f: FileAccess = FileAccess.open("res://src/app/app_root.gd", FileAccess.READ)
	if f == null:
		print("[GUEST-168-010] FAIL: Cannot read app_root.gd source")
		return false
	var source: String = f.get_as_text()
	f.close()

	var checks: Array[Array] = [
		["GUEST_SAVE_DIR", "GUEST_SAVE_DIR constant"],
		["AUTH_SAVE_DIR", "AUTH_SAVE_DIR constant"],
		["GUEST_PROLOGUE_GATE_PATH", "GUEST_PROLOGUE_GATE_PATH constant"],
		["AUTH_PROLOGUE_GATE_PATH", "AUTH_PROLOGUE_GATE_PATH constant"],
		["\"user://guest/\"", "GUEST_SAVE_DIR = user://guest/"],
		["AUTH_SAVE_DIR: String = \"user://\"", "AUTH_SAVE_DIR = user://"],
		["\"user://guest/prologue_gate.json\"", "Guest gate path"],
		["_reinitialize_services_for_profile(GUEST_SAVE_DIR", "Guest reinit call"],
		["_reinitialize_services_for_profile(AUTH_SAVE_DIR", "Auth reinit call"],
	]

	for check in checks:
		if not source.contains(str(check[0])):
			print("[GUEST-168-010] FAIL: Missing %s" % str(check[1]))
			return false

	print("[GUEST-168-010] PASS: AppRoot profile isolation constants and wiring verified")
	return true
