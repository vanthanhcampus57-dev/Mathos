class_name SaveSchema
extends RefCounted

## Schema definitions, locked field contracts, and canonical paths for SaveSnapshot V1.

const SAVE_SCHEMA_VERSION: int = 1
const GAME_VERSION_V1: String = "1.0.0"
const CONTENT_VERSION_V1: int = 1

const SAVE_PATH_MAIN: String = "user://save_v1.json"
const SAVE_PATH_TEMP: String = "user://save_v1.tmp"
const SAVE_PATH_BACKUP: String = "user://save_v1.bak"

const PROFILE_ID_CANONICAL: String = "local_player"
const PLAYER_ID_CANONICAL: String = "char_karl"

const TOP_LEVEL_FIELDS: Array[String] = [
	"schema_version",
	"game_version",
	"content_version",
	"saved_at_utc",
	"profile_id",
	"player_persistent",
	"progress",
	"adaptive_profile"
]

const PLAYER_PERSISTENT_FIELDS: Array[String] = [
	"player_id",
	"coin_balance",
	"exp_total"
]

const PROGRESS_FIELDS: Array[String] = [
	"unlocked_dungeon_ids",
	"unlocked_stage_ids",
	"cleared_stage_ids",
	"fragment_ids",
	"game_complete"
]

const ADAPTIVE_PROFILE_FIELDS: Array[String] = [
	"attempts_total",
	"correct_total",
	"consecutive_correct",
	"consecutive_incorrect",
	"topic_stats",
	"recent_records"
]

const ADAPTIVE_TOPIC_STATS_FIELDS: Array[String] = [
	"attempts",
	"correct",
	"average_time_seconds",
	"last_difficulty"
]

const PERFORMANCE_RECORD_FIELDS: Array[String] = [
	"attempt_id",
	"question_id",
	"dungeon_id",
	"topic_id",
	"subtopic_id",
	"context",
	"difficulty",
	"is_correct",
	"elapsed_seconds"
]

const ALLOWED_TOPIC_IDS: Array[String] = [
	"trial_sample_event",
	"classical_probability",
	"addition_rule",
	"multiplication_independence"
]

const ALLOWED_PERFORMANCE_CONTEXTS: Array[String] = [
	"lesson_check",
	"practice",
	"combat"
]

const DUNGEON_TOPIC_MAP: Dictionary = {
	"dungeon_01": "trial_sample_event",
	"dungeon_02": "classical_probability",
	"dungeon_03": "addition_rule",
	"dungeon_04": "multiplication_independence"
}

const CANONICAL_DUNGEONS: Array[String] = [
	"dungeon_01", "dungeon_02", "dungeon_03", "dungeon_04"
]

const CANONICAL_FRAGMENTS: Array[String] = [
	"fragment_01", "fragment_02", "fragment_03", "fragment_04"
]
