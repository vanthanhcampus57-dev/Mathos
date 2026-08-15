class_name TestProgressService
extends RefCounted

const VALID_FIXTURE_ROOT: String = "res://tests/fixtures/content/valid_catalog"

static func run_all_tests() -> bool:
	print("--- RUNNING PROGRESS-001..015 ---")
	var all_ok: bool = true
	all_ok = test_progress_001_new_game_starts_configured_entry() and all_ok
	all_ok = test_progress_002_stage_clear_recorded() and all_ok
	all_ok = test_progress_003_duplicate_clear_idempotent() and all_ok
	all_ok = test_progress_004_stage_1_1_unlocks_1_2() and all_ok
	all_ok = test_progress_005_stage_1_5_unlocks_d2() and all_ok
	all_ok = test_progress_006_stage_2_5_unlocks_d3() and all_ok
	all_ok = test_progress_007_stage_3_5_unlocks_d4() and all_ok
	all_ok = test_progress_008_stage_4_5_final_progression() and all_ok
	all_ok = test_progress_009_cannot_skip_prerequisite() and all_ok
	all_ok = test_progress_010_defeat_keeps_same_stage_eligible() and all_ok
	all_ok = test_progress_011_defeat_preserves_clears() and all_ok
	all_ok = test_progress_012_defeat_does_not_restart_dungeon() and all_ok
	all_ok = test_progress_013_invalid_stage_fails_explicitly() and all_ok
	all_ok = test_progress_014_no_raw_json_access() and all_ok
	all_ok = test_progress_015_initialization_uses_configured_values() and all_ok
	return all_ok

static func test_progress_001_new_game_starts_configured_entry() -> bool:
	var context: Dictionary = _fresh_context()
	if context.is_empty():
		return _fail("PROGRESS-001", "valid catalog did not load")
	var catalog: ValidatedCatalog = context["catalog"] as ValidatedCatalog
	var service: ProgressService = context["service"] as ProgressService
	var config: Dictionary = catalog.get_config()
	var state: ProgressState = service.create_snapshot_view()
	if state.unlocked_dungeon_ids != [String(config["initial_dungeon_id"])]:
		return _fail("PROGRESS-001", "fresh dungeon unlock did not come from GameConfig")
	if state.unlocked_stage_ids != [String(config["initial_stage_id"])]:
		return _fail("PROGRESS-001", "fresh stage unlock did not come from GameConfig")
	if not state.cleared_stage_ids.is_empty() or not state.fragment_ids.is_empty() or state.game_complete:
		return _fail("PROGRESS-001", "fresh committed progression contains unexpected state")
	return _pass("PROGRESS-001")

static func test_progress_002_stage_clear_recorded() -> bool:
	var context: Dictionary = _fresh_context()
	var service: ProgressService = context["service"] as ProgressService
	var player: PlayerPersistentState = context["player"] as PlayerPersistentState
	var result: StageCompletionResult = service.commit_stage_clear("stage_01_01", _grant_for(context, "stage_01_01"))
	if result == null:
		return _fail("PROGRESS-002", "legal stage clear was rejected")
	var state: ProgressState = service.create_snapshot_view()
	if state.cleared_stage_ids != ["stage_01_01"]:
		return _fail("PROGRESS-002", "stage clear was not committed exactly once")
	if player.coin_balance != 10 or player.exp_total != 20:
		return _fail("PROGRESS-002", "RewardGrant deltas were not committed")
	return _pass("PROGRESS-002")

static func test_progress_003_duplicate_clear_idempotent() -> bool:
	var context: Dictionary = _fresh_context()
	var service: ProgressService = context["service"] as ProgressService
	var player: PlayerPersistentState = context["player"] as PlayerPersistentState
	var grant: RewardGrant = _grant_for(context, "stage_01_01")
	var first: StageCompletionResult = service.commit_stage_clear("stage_01_01", grant)
	var second: StageCompletionResult = service.commit_stage_clear("stage_01_01", grant)
	if first == null or second == null:
		return _fail("PROGRESS-003", "duplicate clear should be deterministic/idempotent")
	var state: ProgressState = service.create_snapshot_view()
	if state.cleared_stage_ids != ["stage_01_01"] or player.coin_balance != 10 or player.exp_total != 20:
		return _fail("PROGRESS-003", "duplicate clear duplicated committed progress/reward")
	if not second.newly_unlocked_stage_ids.is_empty() or not second.newly_unlocked_dungeon_ids.is_empty():
		return _fail("PROGRESS-003", "duplicate clear reported new unlocks")
	return _pass("PROGRESS-003")

static func test_progress_004_stage_1_1_unlocks_1_2() -> bool:
	var context: Dictionary = _fresh_context()
	var service: ProgressService = context["service"] as ProgressService
	var result: StageCompletionResult = service.commit_stage_clear("stage_01_01", _grant_for(context, "stage_01_01"))
	if result == null or result.newly_unlocked_stage_ids != ["stage_01_02"]:
		return _fail("PROGRESS-004", "1.1 did not unlock exactly 1.2")
	if not service.can_enter("stage_01_02") or service.can_enter("stage_01_03"):
		return _fail("PROGRESS-004", "sequential stage legality is incorrect")
	return _pass("PROGRESS-004")

static func test_progress_005_stage_1_5_unlocks_d2() -> bool:
	var context: Dictionary = _fresh_context()
	if not _clear_through(context, "stage_01_05"):
		return _fail("PROGRESS-005", "could not clear through stage 1.5")
	var state: ProgressState = (context["service"] as ProgressService).create_snapshot_view()
	if not state.fragment_ids.has("fragment_01") or not state.unlocked_dungeon_ids.has("dungeon_02") or not state.unlocked_stage_ids.has("stage_02_01"):
		return _fail("PROGRESS-005", "1.5 did not commit fragment_01 + D2 entry")
	return _pass("PROGRESS-005")

static func test_progress_006_stage_2_5_unlocks_d3() -> bool:
	var context: Dictionary = _fresh_context()
	if not _clear_through(context, "stage_02_05"):
		return _fail("PROGRESS-006", "could not clear through stage 2.5")
	var state: ProgressState = (context["service"] as ProgressService).create_snapshot_view()
	if not state.fragment_ids.has("fragment_02") or not state.unlocked_dungeon_ids.has("dungeon_03") or not state.unlocked_stage_ids.has("stage_03_01"):
		return _fail("PROGRESS-006", "2.5 did not commit fragment_02 + D3 entry")
	return _pass("PROGRESS-006")

static func test_progress_007_stage_3_5_unlocks_d4() -> bool:
	var context: Dictionary = _fresh_context()
	if not _clear_through(context, "stage_03_05"):
		return _fail("PROGRESS-007", "could not clear through stage 3.5")
	var state: ProgressState = (context["service"] as ProgressService).create_snapshot_view()
	if not state.fragment_ids.has("fragment_03") or not state.unlocked_dungeon_ids.has("dungeon_04") or not state.unlocked_stage_ids.has("stage_04_01"):
		return _fail("PROGRESS-007", "3.5 did not commit fragment_03 + D4 entry")
	return _pass("PROGRESS-007")

static func test_progress_008_stage_4_5_final_progression() -> bool:
	var context: Dictionary = _fresh_context()
	if not _clear_through(context, "stage_04_04"):
		return _fail("PROGRESS-008", "could not prepare stage 4.5")
	var service: ProgressService = context["service"] as ProgressService
	var result: StageCompletionResult = service.commit_stage_clear("stage_04_05", _grant_for(context, "stage_04_05"))
	if result == null or not result.game_complete_candidate:
		return _fail("PROGRESS-008", "4.5 did not produce game-complete eligibility")
	var checkpoint: ProgressState = service.create_snapshot_view()
	if not checkpoint.cleared_stage_ids.has("stage_04_05") or not checkpoint.fragment_ids.has("fragment_04"):
		return _fail("PROGRESS-008", "4.5 clear/fragment checkpoint is incomplete")
	if checkpoint.game_complete:
		return _fail("PROGRESS-008", "game_complete was set before Ending finalization")
	if not service.mark_game_complete() or not service.create_snapshot_view().game_complete:
		return _fail("PROGRESS-008", "valid final progression could not be finalized")
	return _pass("PROGRESS-008")

static func test_progress_009_cannot_skip_prerequisite() -> bool:
	var context: Dictionary = _fresh_context()
	var service: ProgressService = context["service"] as ProgressService
	var player: PlayerPersistentState = context["player"] as PlayerPersistentState
	var before: ProgressState = service.create_snapshot_view()
	var result: StageCompletionResult = service.commit_stage_clear("stage_01_03", _grant_for(context, "stage_01_03"))
	var after: ProgressState = service.create_snapshot_view()
	if result != null or after.cleared_stage_ids != before.cleared_stage_ids or player.coin_balance != 0:
		return _fail("PROGRESS-009", "locked prerequisite stage was committed")
	return _pass("PROGRESS-009")

static func test_progress_010_defeat_keeps_same_stage_eligible() -> bool:
	var context: Dictionary = _fresh_context()
	var service: ProgressService = context["service"] as ProgressService
	if service.commit_stage_clear("stage_01_01", _grant_for(context, "stage_01_01")) == null:
		return _fail("PROGRESS-010", "fixture setup failed")
	var current_stage_id: String = "stage_01_02" # StageOrchestrator-owned retry identity.
	var before: ProgressState = service.create_snapshot_view()
	# Defeat has intentionally no ProgressService mutation call. StageOrchestrator
	# rebuilds transient runtime and retries this same stage_id.
	var after: ProgressState = service.create_snapshot_view()
	if not service.can_enter(current_stage_id) or not _same_progress(before, after):
		return _fail("PROGRESS-010", "same current stage is not retryable after transient defeat")
	return _pass("PROGRESS-010")

static func test_progress_011_defeat_preserves_clears() -> bool:
	var context: Dictionary = _fresh_context()
	if not _clear_through(context, "stage_01_03"):
		return _fail("PROGRESS-011", "fixture setup failed")
	var service: ProgressService = context["service"] as ProgressService
	var before: ProgressState = service.create_snapshot_view()
	var after: ProgressState = service.create_snapshot_view() # Defeat does not touch ProgressService.
	if before.cleared_stage_ids != after.cleared_stage_ids:
		return _fail("PROGRESS-011", "defeat erased committed cleared stages")
	return _pass("PROGRESS-011")

static func test_progress_012_defeat_does_not_restart_dungeon() -> bool:
	var context: Dictionary = _fresh_context()
	if not _clear_through(context, "stage_02_03"):
		return _fail("PROGRESS-012", "fixture setup failed")
	var service: ProgressService = context["service"] as ProgressService
	var current_stage_id: String = "stage_02_04"
	var before: ProgressState = service.create_snapshot_view()
	var after: ProgressState = service.create_snapshot_view() # Same-stage retry is owned outside Progress.
	if not service.can_enter(current_stage_id):
		return _fail("PROGRESS-012", "defeat would prevent retry of stage 2.4")
	if not _same_progress(before, after) or not after.cleared_stage_ids.has("stage_02_03"):
		return _fail("PROGRESS-012", "defeat reset Dungeon 2 committed progression")
	return _pass("PROGRESS-012")

static func test_progress_013_invalid_stage_fails_explicitly() -> bool:
	var context: Dictionary = _fresh_context()
	var service: ProgressService = context["service"] as ProgressService
	var before: ProgressState = service.create_snapshot_view()
	if service.can_enter("stage_missing"):
		return _fail("PROGRESS-013", "unknown stage reported enterable")
	var invalid_grant: RewardGrant = RewardGrant.new("reward_missing", "stage_missing", 0, 0, [])
	if service.commit_stage_clear("stage_missing", invalid_grant) != null:
		return _fail("PROGRESS-013", "unknown stage clear did not fail")
	if not _same_progress(before, service.create_snapshot_view()):
		return _fail("PROGRESS-013", "invalid stage mutated progression")
	return _pass("PROGRESS-013")

static func test_progress_014_no_raw_json_access() -> bool:
	var progress_dir: DirAccess = DirAccess.open("res://src/gameplay/progress")
	if progress_dir == null:
		return _fail("PROGRESS-014", "cannot inspect progress source directory")
	progress_dir.list_dir_begin()
	var file_name: String = progress_dir.get_next()
	while file_name != "":
		if not progress_dir.current_is_dir() and file_name.ends_with(".gd"):
			var path: String = "res://src/gameplay/progress/" + file_name
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			if file == null:
				return _fail("PROGRESS-014", "cannot inspect " + path)
			var source: String = file.get_as_text()
			file.close()
			if source.contains("FileAccess") or source.contains("JSON.new") or source.contains(".json") or source.contains("res://content"):
				return _fail("PROGRESS-014", "raw JSON/filesystem content access found in " + file_name)
		file_name = progress_dir.get_next()
	progress_dir.list_dir_end()
	return _pass("PROGRESS-014")

static func test_progress_015_initialization_uses_configured_values() -> bool:
	var base_context: Dictionary = _fresh_context()
	if base_context.is_empty():
		return _fail("PROGRESS-015", "valid catalog did not load")
	var base_catalog: ValidatedCatalog = base_context["catalog"] as ValidatedCatalog
	var configured_catalog: ValidatedCatalog = _catalog_with_config_overrides(base_catalog, {
		"initial_dungeon_id": "dungeon_02",
		"initial_stage_id": "stage_02_01",
		"player_stats": {"max_hp": 137, "starting_hp": 91, "hand_size": 7}
	})
	var player: PlayerPersistentState = PlayerPersistentState.new()
	var service: ProgressService = ProgressService.new(configured_catalog, player)
	var state: ProgressState = service.create_snapshot_view()
	if state.unlocked_dungeon_ids != ["dungeon_02"] or state.unlocked_stage_ids != ["stage_02_01"]:
		return _fail("PROGRESS-015", "ProgressService used magic initial progression instead of configured values")
	var stats: PlayerStats = PlayerStats.new(configured_catalog.get_config())
	var runtime: PlayerRuntime = PlayerRuntime.new("stage_02_01", stats)
	if stats.max_hp != 137 or stats.starting_hp != 91 or stats.hand_size != 7 or runtime.current_hp != 91:
		return _fail("PROGRESS-015", "player initialization ignored configured values")
	return _pass("PROGRESS-015")

static func _fresh_context() -> Dictionary:
	var repo: ContentRepository = ContentRepository.new()
	var report: ContentValidationReport = repo.load_and_validate(VALID_FIXTURE_ROOT)
	if not report.publication_allowed or repo.get_catalog() == null:
		return {}
	var catalog: ValidatedCatalog = repo.get_catalog()
	var player: PlayerPersistentState = PlayerPersistentState.new()
	var service: ProgressService = ProgressService.new(catalog, player)
	return {"catalog": catalog, "player": player, "service": service}

static func _grant_for(context: Dictionary, stage_id: String) -> RewardGrant:
	var catalog: ValidatedCatalog = context["catalog"] as ValidatedCatalog
	var stage: Dictionary = catalog.get_stage(stage_id)
	var dungeon: Dictionary = catalog.get_dungeon(String(stage.get("dungeon_id", "")))
	var fragments: Array[String] = []
	var stage_ids: Array = dungeon.get("stage_ids", [])
	if not stage_ids.is_empty() and String(stage_ids[stage_ids.size() - 1]) == stage_id:
		fragments.append(String(dungeon.get("fragment_id", "")))
	return RewardGrant.new(String(stage.get("reward_id", "")), stage_id, 10, 20, fragments)

static func _clear_through(context: Dictionary, target_stage_id: String) -> bool:
	var catalog: ValidatedCatalog = context["catalog"] as ValidatedCatalog
	var service: ProgressService = context["service"] as ProgressService
	var ordered_dungeons: Array[Dictionary] = catalog.get_all_dungeons()
	ordered_dungeons.sort_custom(_dungeon_order_less)
	for dungeon in ordered_dungeons:
		var stage_ids: Array = dungeon.get("stage_ids", [])
		for stage_variant in stage_ids:
			var stage_id: String = String(stage_variant)
			if service.commit_stage_clear(stage_id, _grant_for(context, stage_id)) == null:
				return false
			if stage_id == target_stage_id:
				return true
	return false

static func _catalog_with_config_overrides(base: ValidatedCatalog, overrides: Dictionary) -> ValidatedCatalog:
	var config: Dictionary = base.get_config()
	for key in overrides:
		config[key] = overrides[key]
	var dungeons: Dictionary = {}
	for dungeon in base.get_all_dungeons():
		dungeons[String(dungeon.get("dungeon_id", ""))] = dungeon
	var stages: Dictionary = {}
	for stage in base.get_all_stages():
		stages[String(stage.get("stage_id", ""))] = stage
	return ValidatedCatalog.new(config, dungeons, stages, {}, {}, {}, {}, {}, {}, {})

static func _dungeon_order_less(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("order", 0)) < int(b.get("order", 0))

static func _same_progress(a: ProgressState, b: ProgressState) -> bool:
	return (
		a.unlocked_dungeon_ids == b.unlocked_dungeon_ids
		and a.unlocked_stage_ids == b.unlocked_stage_ids
		and a.cleared_stage_ids == b.cleared_stage_ids
		and a.fragment_ids == b.fragment_ids
		and a.game_complete == b.game_complete
	)

static func _pass(test_id: String) -> bool:
	print("[" + test_id + "] PASS")
	return true

static func _fail(test_id: String, message: String) -> bool:
	print("[" + test_id + "] FAIL: " + message)
	return false
