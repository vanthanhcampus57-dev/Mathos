class_name TestProgressIntegration
extends RefCounted

static func run_all_tests() -> bool:
	print("--- RUNNING PROGRESS INTEGRATION CONTRACTS ---")
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	if not report.publication_allowed or repo.get_catalog() == null:
		print("[PROGRESS-INT-001] FAIL: valid catalog did not publish")
		return false
	var catalog: ValidatedCatalog = repo.get_catalog()
	var player: PlayerPersistentState = PlayerPersistentState.new()
	var service: ProgressService = ProgressService.new(catalog, player)
	var grant: RewardGrant = RewardGrant.new("reward_01_01", "stage_01_01", 5, 9, [])
	var result: StageCompletionResult = service.commit_stage_clear("stage_01_01", grant)
	if result == null or result.reward_grant != grant:
		print("[PROGRESS-INT-001] FAIL: StageCompletionResult does not carry the exact RewardGrant input")
		return false
	if result.progress_snapshot.cleared_stage_ids != ["stage_01_01"]:
		print("[PROGRESS-INT-001] FAIL: StageCompletionResult snapshot is not post-commit")
		return false
	var leaked_snapshot: ProgressState = result.progress_snapshot
	leaked_snapshot.cleared_stage_ids.clear()
	if service.create_snapshot_view().cleared_stage_ids != ["stage_01_01"]:
		print("[PROGRESS-INT-001] FAIL: external snapshot mutation leaked into owner state")
		return false
	print("[PROGRESS-INT-001] PASS")
	return true
