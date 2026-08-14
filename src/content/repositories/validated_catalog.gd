class_name ValidatedCatalog
extends RefCounted

## Immutable, indexed container of validated game static content definitions.
## Published ONLY by ContentRepository after successful validation gate.

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
	var req_subtopics: Array = scope.get("subtopics", [])
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
		if req_subtopics.size() > 0:
			var q_subtopic: String = q.get("subtopic_id", "")
			if not req_subtopics.has(q_subtopic):
				continue
		candidates.append(q.duplicate(true))
	return candidates
