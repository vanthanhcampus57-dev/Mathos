class_name TestRewardGrant
extends RefCounted

static func run_all_tests() -> bool:
	print("--- RUNNING REWARDGRANT CONTRACT TESTS ---")
	var fragments: Array[String] = ["fragment_01"]
	var grant: RewardGrant = RewardGrant.new("reward_01_05", "stage_01_05", 50, 100, fragments)
	if grant.reward_id != "reward_01_05" or grant.stage_id != "stage_01_05":
		print("[REWARD-GRANT-001] FAIL: identity fields changed")
		return false
	if grant.coin_delta != 50 or grant.exp_delta != 100:
		print("[REWARD-GRANT-001] FAIL: reward deltas changed")
		return false
	var returned_fragments: Array[String] = grant.fragment_ids
	returned_fragments.clear()
	if grant.fragment_ids != ["fragment_01"]:
		print("[REWARD-GRANT-001] FAIL: fragment_ids exposed mutable backing state")
		return false
	print("[REWARD-GRANT-001] PASS")
	return true
