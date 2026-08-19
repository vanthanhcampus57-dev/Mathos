class_name SaveTestHelper
extends RefCounted

## Helper utilities for Save QA and isolated test path hygiene.

func get_temp_store() -> SaveFileStore:
	var tmp_dir: String = "user://temp_qa_save_%d_%d/" % [Time.get_ticks_msec(), randi_range(1000, 9999)]
	return SaveFileStore.new(tmp_dir)

func cleanup_temp_store(store: SaveFileStore) -> void:
	if store != null and store.get_base_dir().begins_with("user://temp_qa_save_"):
		var dir_path: String = store.get_base_dir()
		if DirAccess.dir_exists_absolute(dir_path):
			var dir: DirAccess = DirAccess.open(dir_path)
			if dir != null:
				dir.list_dir_begin()
				var fname: String = dir.get_next()
				while fname != "":
					if fname != "." and fname != "..":
						dir.remove(fname)
					fname = dir.get_next()
				dir.list_dir_end()
				DirAccess.remove_absolute(dir_path)

func get_synthetic_catalog() -> ValidatedCatalog:
	var repo: ContentRepository = ContentRepository.new()
	repo.load_and_validate("res://tests/fixtures/content/valid_catalog")
	if repo.get_catalog() != null:
		return repo.get_catalog()

	# Fallback synthetic builder if fixture root is unreadable
	var config: Dictionary = {
		"adaptive_recent_record_limit": 100,
		"initial_dungeon_id": "dungeon_01",
		"initial_stage_id": "stage_01_01"
	}
	var dungeons: Dictionary = {}
	for i in range(1, 5):
		var did: String = "dungeon_0%d" % i
		var stage_ids: Array = []
		for j in range(1, 6):
			stage_ids.append("stage_0%d_0%d" % [i, j])
		dungeons[did] = {"dungeon_id": did, "topic_id": ValidatedCatalog.TOPIC_BY_DUNGEON.get(did, ""), "stage_ids": stage_ids}

	var stages: Dictionary = {}
	for i in range(1, 5):
		var did: String = "dungeon_0%d" % i
		for j in range(1, 6):
			var sid: String = "stage_0%d_0%d" % [i, j]
			var reward_id: String = "reward_0%d_0%d" % [i, j]
			stages[sid] = {"stage_id": sid, "dungeon_id": did, "reward_id": reward_id}
	var rewards: Dictionary = {}
	for i in range(1, 5):
		for j in range(1, 6):
			var sid: String = "stage_0%d_0%d" % [i, j]
			var rid: String = "reward_0%d_0%d" % [i, j]
			var frag: Variant = null
			if j == 5:
				frag = "fragment_0%d" % i
			rewards[rid] = {"reward_id": rid, "stage_id": sid, "coin_amount": 10, "exp_amount": 20, "fragment_id": frag}
	var questions: Dictionary = {
		"q_001": {"question_id": "q_001", "dungeon_id": "dungeon_01", "topic_id": "trial_sample_event", "subtopic_id": "sample_space"}
	}
	return ValidatedCatalog.new(config, dungeons, stages, {}, {}, {}, questions, {}, {}, rewards)

func create_valid_fresh_snapshot_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"game_version": "1.0.0",
		"content_version": 1,
		"saved_at_utc": "2026-08-18T00:00:00Z",
		"profile_id": "local_player",
		"player_persistent": {
			"player_id": "char_karl",
			"coin_balance": 0,
			"exp_total": 0
		},
		"progress": {
			"unlocked_dungeon_ids": ["dungeon_01"],
			"unlocked_stage_ids": ["stage_01_01"],
			"cleared_stage_ids": [],
			"fragment_ids": [],
			"game_complete": false
		},
		"adaptive_profile": {
			"attempts_total": 0,
			"correct_total": 0,
			"consecutive_correct": 0,
			"consecutive_incorrect": 0,
			"topic_stats": {},
			"recent_records": []
		}
	}
