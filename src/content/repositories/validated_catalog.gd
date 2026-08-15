class_name ValidatedCatalog
extends RefCounted

## Immutable, indexed container of validated game static content definitions.
## Published ONLY by ContentRepository after successful validation gate.

const TOPIC_BY_DUNGEON: Dictionary = {
	"dungeon_01": "trial_sample_event",
	"dungeon_02": "classical_probability",
	"dungeon_03": "addition_rule",
	"dungeon_04": "multiplication_independence"
}
const SUBTOPICS_BY_TOPIC: Dictionary = {
	"trial_sample_event": ["random_trial", "sample_space", "event_subset", "event_classification", "counting_outcomes"],
	"classical_probability": ["equally_likely", "classical_probability_formula", "probability_representation", "compare_probability", "multi_data_classical"],
	"addition_rule": ["union_intersection", "mutually_exclusive", "addition_simple", "addition_general", "addition_selection"],
	"multiplication_independence": ["independence", "tree_diagram", "multiplication_two_step", "multiplication_chain", "independence_application"]
}

var _config: Dictionary = {}
var _dungeons: Dictionary = {} # id -> Dictionary
var _stages: Dictionary = {}   # id -> Dictionary
var _story: Dictionary = {}    # id -> Dictionary
var _lessons: Dictionary = {}  # id -> Dictionary
var _practice: Dictionary = {} # id -> Dictionary
var _questions: Dictionary = {}# id -> Dictionary
var _cards: Dictionary = {}    # id -> Dictionary
var _enemies: Dictionary = {}  # id -> Dictionary
var _rewards: Dictionary = {}  # id -> Dictionary

func _init(
	p_config: Dictionary,
	p_dungeons: Dictionary,
	p_stages: Dictionary,
	p_story: Dictionary,
	p_lessons: Dictionary,
	p_practice: Dictionary,
	p_questions: Dictionary,
	p_cards: Dictionary,
	p_enemies: Dictionary,
	p_rewards: Dictionary
) -> void:
	_config = p_config.duplicate(true)
	_dungeons = p_dungeons.duplicate(true)
	_stages = p_stages.duplicate(true)
	_story = p_story.duplicate(true)
	_lessons = p_lessons.duplicate(true)
	_practice = p_practice.duplicate(true)
	_questions = p_questions.duplicate(true)
	_cards = p_cards.duplicate(true)
	_enemies = p_enemies.duplicate(true)
	_rewards = p_rewards.duplicate(true)

func get_config() -> Dictionary:
	return _config.duplicate(true)

func get_dungeon(id: String) -> Dictionary:
	if _dungeons.has(id):
		return (_dungeons[id] as Dictionary).duplicate(true)
	return {}

func get_stage(id: String) -> Dictionary:
	if _stages.has(id):
		return (_stages[id] as Dictionary).duplicate(true)
	return {}

func get_story(id: String) -> Dictionary:
	if _story.has(id):
		return (_story[id] as Dictionary).duplicate(true)
	return {}

func get_lesson(id: String) -> Dictionary:
	if _lessons.has(id):
		return (_lessons[id] as Dictionary).duplicate(true)
	return {}

func get_practice(id: String) -> Dictionary:
	if _practice.has(id):
		return (_practice[id] as Dictionary).duplicate(true)
	return {}

func get_question(id: String) -> Dictionary:
	if _questions.has(id):
		return (_questions[id] as Dictionary).duplicate(true)
	return {}

func get_card(id: String) -> Dictionary:
	if _cards.has(id):
		return (_cards[id] as Dictionary).duplicate(true)
	return {}

func get_enemy(id: String) -> Dictionary:
	if _enemies.has(id):
		return (_enemies[id] as Dictionary).duplicate(true)
	return {}

func get_reward(id: String) -> Dictionary:
	if _rewards.has(id):
		return (_rewards[id] as Dictionary).duplicate(true)
	return {}

func get_all_dungeons() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in _dungeons:
		result.append((_dungeons[key] as Dictionary).duplicate(true))
	return result

func get_all_stages() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in _stages:
		result.append((_stages[key] as Dictionary).duplicate(true))
	return result

## Queries questions matching scope and context filters.
func query_questions(scope: Dictionary, context: String = "") -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var req_dungeon: String = scope.get("dungeon_id", "")
	var req_topic: String = scope.get("topic_id", "")
	if not TOPIC_BY_DUNGEON.has(req_dungeon) or String(TOPIC_BY_DUNGEON[req_dungeon]) != req_topic:
		return []
	# Canonical QuestionScope uses subtopic_ids only. Legacy `subtopics` is rejected
	# here instead of being interpreted or widened into an empty canonical filter.
	if scope.has("subtopics") or not scope.has("subtopic_ids"):
		return []
	var raw_subtopics: Variant = scope["subtopic_ids"]
	if not (raw_subtopics is Array):
		return []
	var req_subtopics: Array = raw_subtopics as Array
	for subtopic_variant in req_subtopics:
		if not (subtopic_variant is String):
			return []
	var req_min_diff: int = int(scope.get("difficulty_min", 1))
	var req_max_diff: int = int(scope.get("difficulty_max", 5))

	for q_id in _questions:
		var q: Dictionary = _questions[q_id] as Dictionary
		if req_dungeon != "" and q.get("dungeon_id", "") != req_dungeon:
			continue
		if req_topic != "" and q.get("topic_id", "") != req_topic:
			continue
		var q_diff: int = int(q.get("difficulty", 1))
		if q_diff < req_min_diff or q_diff > req_max_diff:
			continue
		if context != "":
			var allowed_contexts: Array = q.get("allowed_contexts", [])
			if not allowed_contexts.has(context):
				continue
		var q_subtopic: String = q.get("subtopic_id", "")
		var canonical_subtopics: Array = SUBTOPICS_BY_TOPIC.get(req_topic, [])
		if not canonical_subtopics.has(q_subtopic):
			continue
		if req_subtopics.size() > 0:
			if not req_subtopics.has(q_subtopic):
				continue
		candidates.append(q.duplicate(true))
	return candidates
