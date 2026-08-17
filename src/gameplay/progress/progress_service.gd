class_name ProgressService
extends RefCounted

## Authoritative committed progression service. Reads only the already-validated
## catalog/config boundary and never performs raw JSON or Save IO.

var _catalog: ValidatedCatalog
var _player_persistent: PlayerPersistentState
var _state: ProgressState

func _init(
	catalog: ValidatedCatalog,
	player_persistent: PlayerPersistentState,
	restored_state: ProgressState = null
) -> void:
	assert(catalog != null, "ProgressService requires a validated catalog")
	assert(player_persistent != null, "ProgressService requires PlayerPersistentState")
	_catalog = catalog
	_player_persistent = player_persistent

	if restored_state != null:
		_state = restored_state._copy()
	else:
		_state = _create_fresh_progress_state()

func can_enter(stage_id: String) -> bool:
	if _catalog.get_stage(stage_id).is_empty():
		push_error("ProgressService.can_enter: unknown stage_id '" + stage_id + "'")
		return false
	return _state.unlocked_stage_ids.has(stage_id)

func commit_stage_clear(stage_id: String, reward: RewardGrant) -> StageCompletionResult:
	var stage: Dictionary = _catalog.get_stage(stage_id)
	if stage.is_empty():
		push_error("ProgressService.commit_stage_clear: unknown stage_id '" + stage_id + "'")
		return null
	if reward == null:
		push_error("ProgressService.commit_stage_clear: RewardGrant is required")
		return null
	if not _is_reward_valid_for_stage(stage, reward):
		return null
	if not can_enter(stage_id):
		push_error("ProgressService.commit_stage_clear: stage is locked '" + stage_id + "'")
		return null

	if _state.cleared_stage_ids.has(stage_id):
		return StageCompletionResult.new(
			stage_id,
			reward,
			[],
			[],
			[],
			stage_id == "stage_04_05" and _state.fragment_ids.has("fragment_04"),
			_state
		)

	_state.cleared_stage_ids.append(stage_id)
	_player_persistent.coin_balance += reward.coin_delta
	_player_persistent.exp_total += reward.exp_delta

	var newly_unlocked_stage_ids: Array[String] = []
	var newly_unlocked_dungeon_ids: Array[String] = []
	var newly_collected_fragment_ids: Array[String] = []

	_commit_fragments(reward.fragment_ids, newly_collected_fragment_ids)
	_unlock_after_stage(stage, newly_unlocked_stage_ids, newly_unlocked_dungeon_ids)

	return StageCompletionResult.new(
		stage_id,
		reward,
		newly_unlocked_stage_ids,
		newly_unlocked_dungeon_ids,
		newly_collected_fragment_ids,
		stage_id == "stage_04_05",
		_state
	)

func unlock_next() -> Array[String]:
	if _state.cleared_stage_ids.is_empty():
		return []
	var latest_stage_id: String = _state.cleared_stage_ids[_state.cleared_stage_ids.size() - 1]
	var stage: Dictionary = _catalog.get_stage(latest_stage_id)
	if stage.is_empty():
		push_error("ProgressService.unlock_next: latest cleared stage is unknown")
		return []
	var newly_unlocked_stages: Array[String] = []
	var ignored_dungeons: Array[String] = []
	_unlock_after_stage(stage, newly_unlocked_stages, ignored_dungeons)
	return newly_unlocked_stages

func mark_game_complete() -> bool:
	if _state.game_complete:
		return true
	var all_stages: Array[Dictionary] = _catalog.get_all_stages()
	var all_dungeons: Array[Dictionary] = _catalog.get_all_dungeons()
	if all_stages.size() != 20 or all_dungeons.size() != 4:
		push_error("ProgressService.mark_game_complete: canonical 4x5 catalog is required")
		return false
	for stage in all_stages:
		var stage_id: String = String(stage.get("stage_id", ""))
		if stage_id == "" or not _state.cleared_stage_ids.has(stage_id):
			push_error("ProgressService.mark_game_complete: all canonical stages must be cleared")
			return false
	for dungeon in all_dungeons:
		var fragment_id: String = String(dungeon.get("fragment_id", ""))
		if fragment_id == "" or not _state.fragment_ids.has(fragment_id):
			push_error("ProgressService.mark_game_complete: all canonical fragments must be committed")
			return false
	if not _state.cleared_stage_ids.has("stage_04_05"):
		push_error("ProgressService.mark_game_complete: stage_04_05 must be cleared")
		return false
	_state.game_complete = true
	return true

func create_snapshot_view() -> ProgressState:
	return _state._copy()

func _create_fresh_progress_state() -> ProgressState:
	var config: Dictionary = _catalog.get_config()
	var initial_dungeon_id: String = String(config.get("initial_dungeon_id", ""))
	var initial_stage_id: String = String(config.get("initial_stage_id", ""))
	assert(initial_dungeon_id != "", "Validated GameConfig.initial_dungeon_id is required")
	assert(initial_stage_id != "", "Validated GameConfig.initial_stage_id is required")
	var initial_dungeon: Dictionary = _catalog.get_dungeon(initial_dungeon_id)
	var initial_stage: Dictionary = _catalog.get_stage(initial_stage_id)
	assert(not initial_dungeon.is_empty(), "Configured initial_dungeon_id must exist in validated catalog")
	assert(not initial_stage.is_empty(), "Configured initial_stage_id must exist in validated catalog")
	assert(String(initial_stage.get("dungeon_id", "")) == initial_dungeon_id, "Configured initial stage must belong to configured initial dungeon")
	return ProgressState.new([initial_dungeon_id], [initial_stage_id], [], [], false)

func _is_reward_valid_for_stage(stage: Dictionary, reward: RewardGrant) -> bool:
	var stage_id: String = String(stage.get("stage_id", ""))
	if reward.stage_id != stage_id:
		push_error("ProgressService.commit_stage_clear: RewardGrant.stage_id mismatch")
		return false
	if reward.reward_id != String(stage.get("reward_id", "")):
		push_error("ProgressService.commit_stage_clear: RewardGrant.reward_id mismatch")
		return false
	if reward.coin_delta < 0 or reward.exp_delta < 0:
		push_error("ProgressService.commit_stage_clear: RewardGrant deltas must be non-negative")
		return false
	var reward_fragments: Array[String] = reward.fragment_ids
	if not _has_unique_values(reward_fragments):
		push_error("ProgressService.commit_stage_clear: RewardGrant.fragment_ids must be unique")
		return false

	var dungeon_id: String = String(stage.get("dungeon_id", ""))
	var dungeon: Dictionary = _catalog.get_dungeon(dungeon_id)
	if dungeon.is_empty():
		push_error("ProgressService.commit_stage_clear: stage dungeon is missing")
		return false
	var stage_ids: Array[String] = _to_string_array(dungeon.get("stage_ids", []))
	var is_final_stage: bool = not stage_ids.is_empty() and stage_ids[stage_ids.size() - 1] == stage_id
	var expected_fragment_id: String = String(dungeon.get("fragment_id", ""))
	if is_final_stage:
		if reward_fragments.size() != 1 or reward_fragments[0] != expected_fragment_id:
			push_error("ProgressService.commit_stage_clear: x.5 RewardGrant must contain exactly the canonical dungeon fragment")
			return false
	elif not reward_fragments.is_empty():
		push_error("ProgressService.commit_stage_clear: non-x.5 RewardGrant must not contain a fragment")
		return false
	return true

func _commit_fragments(fragment_ids: Array[String], newly_collected: Array[String]) -> void:
	for fragment_id in fragment_ids:
		if not _state.fragment_ids.has(fragment_id):
			_state.fragment_ids.append(fragment_id)
			newly_collected.append(fragment_id)

func _unlock_after_stage(
	stage: Dictionary,
	newly_unlocked_stages: Array[String],
	newly_unlocked_dungeons: Array[String]
) -> void:
	var stage_id: String = String(stage.get("stage_id", ""))
	var dungeon_id: String = String(stage.get("dungeon_id", ""))
	var dungeon: Dictionary = _catalog.get_dungeon(dungeon_id)
	if dungeon.is_empty():
		push_error("ProgressService: cannot unlock after stage with unknown dungeon")
		return
	var stage_ids: Array[String] = _to_string_array(dungeon.get("stage_ids", []))
	var stage_index: int = stage_ids.find(stage_id)
	if stage_index < 0:
		push_error("ProgressService: stage missing from owning DungeonDefinition.stage_ids")
		return

	if stage_index < stage_ids.size() - 1:
		_add_stage_unlock(stage_ids[stage_index + 1], newly_unlocked_stages)
		return

	var next_dungeon: Dictionary = _find_next_dungeon(dungeon)
	if next_dungeon.is_empty():
		return
	var next_dungeon_id: String = String(next_dungeon.get("dungeon_id", ""))
	if not _state.unlocked_dungeon_ids.has(next_dungeon_id):
		_state.unlocked_dungeon_ids.append(next_dungeon_id)
		newly_unlocked_dungeons.append(next_dungeon_id)
	var next_stage_ids: Array[String] = _to_string_array(next_dungeon.get("stage_ids", []))
	if not next_stage_ids.is_empty():
		_add_stage_unlock(next_stage_ids[0], newly_unlocked_stages)

func _find_next_dungeon(current_dungeon: Dictionary) -> Dictionary:
	var current_id: String = String(current_dungeon.get("dungeon_id", ""))
	var current_order: int = int(current_dungeon.get("order", 0))
	for candidate in _catalog.get_all_dungeons():
		if int(candidate.get("order", 0)) != current_order + 1:
			continue
		if String(candidate.get("prerequisite_dungeon_id", "")) != current_id:
			continue
		return candidate
	return {}

func _add_stage_unlock(stage_id: String, newly_unlocked_stages: Array[String]) -> void:
	if stage_id == "" or _catalog.get_stage(stage_id).is_empty():
		push_error("ProgressService: attempted to unlock unknown stage_id '" + stage_id + "'")
		return
	if not _state.unlocked_stage_ids.has(stage_id):
		_state.unlocked_stage_ids.append(stage_id)
		newly_unlocked_stages.append(stage_id)

static func _has_unique_values(values: Array[String]) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if seen.has(value):
			return false
		seen[value] = true
	return true

static func _to_string_array(values: Variant) -> Array[String]:
	var result: Array[String] = []
	if not (values is Array):
		return result
	var array_values: Array = values as Array
	for value in array_values:
		result.append(String(value))
	return result
