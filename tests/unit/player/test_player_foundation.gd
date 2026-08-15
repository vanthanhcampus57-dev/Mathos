class_name TestPlayerFoundation
extends RefCounted

static func run_all_tests() -> bool:
	print("--- RUNNING PLAYER FOUNDATION TESTS ---")
	var config: Dictionary = {
		"player_stats": {
			"max_hp": 137,
			"starting_hp": 91,
			"hand_size": 7
		}
	}
	var stats: PlayerStats = PlayerStats.new(config)
	if stats.max_hp != 137 or stats.starting_hp != 91 or stats.hand_size != 7:
		print("[PLAYER-001] FAIL: PlayerStats did not use validated config values")
		return false
	var runtime: PlayerRuntime = PlayerRuntime.new("stage_01_01", stats)
	if runtime.max_hp != 137 or runtime.current_hp != 91 or runtime.shield != 0:
		print("[PLAYER-001] FAIL: PlayerRuntime was not derived from PlayerStats")
		return false
	runtime.apply_shield(10)
	runtime.apply_damage(15)
	if runtime.shield != 0 or runtime.current_hp != 86:
		print("[PLAYER-001] FAIL: PlayerRuntime effect boundary is incorrect")
		return false
	runtime.reset_stage_runtime(stats)
	if runtime.current_hp != 91 or runtime.shield != 0 or runtime.is_defeated:
		print("[PLAYER-001] FAIL: PlayerRuntime did not reset transient values")
		return false
	var persistent: PlayerPersistentState = PlayerPersistentState.new()
	if persistent.player_id != "char_karl" or persistent.coin_balance != 0 or persistent.exp_total != 0:
		print("[PLAYER-001] FAIL: PlayerPersistentState fresh contract is incorrect")
		return false
	print("[PLAYER-001] PASS")
	return true
