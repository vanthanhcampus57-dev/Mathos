class_name CardModel
extends RefCounted

## Runtime Model representing a Combat Card in Mathos.
## Defines card identity, type (attack/shield/heal), energy cost, and deterministic effects.

var card_id: String = ""
var name: String = ""
var card_type: String = "attack"
var cost: int = 1
var effects: Array = []

func _init(
	p_card_id: String = "",
	p_name: String = "",
	p_card_type: String = "attack",
	p_cost: int = 1,
	p_effects: Array = []
) -> void:
	card_id = p_card_id
	name = p_name
	card_type = p_card_type
	cost = p_cost
	effects = p_effects.duplicate(true)

static func from_dict(d: Dictionary) -> CardModel:
	var c_id: String = String(d.get("card_id", ""))
	var c_name: String = String(d.get("name", c_id))
	var c_type: String = String(d.get("card_type", "attack"))
	var c_cost: int = int(d.get("cost", 1))
	var c_effects: Array = d.get("effects", []) as Array
	return CardModel.new(c_id, c_name, c_type, c_cost, c_effects)

static func load_cards(catalog: ValidatedCatalog, card_ids: Array) -> Array[CardModel]:
	var result: Array[CardModel] = []
	if catalog == null:
		return result
	for id_var in card_ids:
		var c_id: String = String(id_var)
		var c_dict: Dictionary = catalog.get_card(c_id)
		if not c_dict.is_empty():
			result.append(CardModel.from_dict(c_dict))
	return result

func get_summary_text() -> String:
	var parts: Array[String] = []
	for ef_var in effects:
		var ef: Dictionary = ef_var as Dictionary
		var e_type: String = String(ef.get("effect_type", ""))
		var amt: int = int(ef.get("amount", 0))
		match e_type:
			"damage":
				parts.append("⚔️ %d Sát thương" % amt)
			"shield":
				parts.append("🛡️ +%d Giáp" % amt)
			"heal":
				parts.append("💚 +%d HP" % amt)
			_:
				parts.append("%s %d" % [e_type, amt])
	return " | ".join(parts) if not parts.is_empty() else name

func get_icon() -> String:
	match card_type:
		"attack": return "⚔️"
		"shield": return "🛡️"
		"heal": return "💚"
		_: return "🃏"
