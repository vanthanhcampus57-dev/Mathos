class_name PresentationModels
extends RefCounted

## Presentation-local data models for neutral UI shell consumption.
## Pure view structures without domain, combat, progress, or save logic.

class LessonStepData extends RefCounted:
	var speaker_label: String = ""
	var body_text: String = ""
	var context_title: String = ""
	var step_index: int = 1
	var total_steps: int = 1

	func _init(p_speaker: String = "", p_body: String = "", p_title: String = "", p_step: int = 1, p_total: int = 1) -> void:
		speaker_label = p_speaker
		body_text = p_body
		context_title = p_title
		step_index = p_step
		total_steps = p_total

	static func from_dict(d: Dictionary) -> LessonStepData:
		return LessonStepData.new(
			str(d.get("speaker_label", "")),
			str(d.get("body_text", "")),
			str(d.get("context_title", "")),
			int(d.get("step_index", 1)),
			int(d.get("total_steps", 1))
		)

class StageContextInfo extends RefCounted:
	var stage_id: String = ""
	var stage_title: String = ""
	var dungeon_title: String = ""
	var lesson_steps: Array[LessonStepData] = []
	var encounter_mode: String = ""
	var enemy_id: String = ""
	var card_pool_ids: Array = []
	var intent_enabled: bool = false
	var is_restored_context: bool = false

	func _init(p_id: String = "", p_title: String = "", p_dungeon: String = "", p_steps: Array[LessonStepData] = [], p_restored: bool = false) -> void:
		stage_id = p_id
		stage_title = p_title
		dungeon_title = p_dungeon
		lesson_steps = p_steps
		is_restored_context = p_restored

	static func from_dict(d: Dictionary) -> StageContextInfo:
		var steps: Array[LessonStepData] = []
		var raw_steps: Variant = d.get("lesson_steps", [])
		if raw_steps is Array:
			for item in raw_steps:
				if item is Dictionary:
					steps.append(LessonStepData.from_dict(item as Dictionary))
				elif item is LessonStepData:
					steps.append(item as LessonStepData)

		var info: StageContextInfo = StageContextInfo.new(
			str(d.get("stage_id", "")),
			str(d.get("stage_title", "")),
			str(d.get("dungeon_title", "")),
			steps,
			bool(d.get("is_restored_context", false))
		)
		info.encounter_mode = str(d.get("encounter_mode", ""))
		info.enemy_id = str(d.get("enemy_id", ""))
		info.card_pool_ids = d.get("card_pool_ids", [])
		info.intent_enabled = bool(d.get("intent_enabled", false))
		return info

class FeedbackInfo extends RefCounted:
	var is_correct: bool = false
	var title: String = ""
	var message: String = ""
	var detail_text: String = ""

	func _init(p_correct: bool = false, p_title: String = "", p_message: String = "", p_detail: String = "") -> void:
		is_correct = p_correct
		title = p_title
		message = p_message
		detail_text = p_detail

	static func from_dict(d: Dictionary) -> FeedbackInfo:
		return FeedbackInfo.new(
			bool(d.get("is_correct", false)),
			str(d.get("title", "")),
			str(d.get("message", "")),
			str(d.get("detail_text", ""))
		)
