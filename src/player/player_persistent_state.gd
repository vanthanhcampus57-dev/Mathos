class_name PlayerPersistentState
extends RefCounted

## Player values that survive app restart. Runtime HP/shield/modifiers do not
## belong in this model.

const CANONICAL_PLAYER_ID: String = "char_karl"

var player_id: String = CANONICAL_PLAYER_ID
var coin_balance: int = 0
var exp_total: int = 0

func _init(
	p_player_id: String = CANONICAL_PLAYER_ID,
	p_coin_balance: int = 0,
	p_exp_total: int = 0
) -> void:
	assert(p_player_id == CANONICAL_PLAYER_ID, "PlayerPersistentState.player_id must be char_karl")
	assert(p_coin_balance >= 0, "PlayerPersistentState.coin_balance must be >= 0")
	assert(p_exp_total >= 0, "PlayerPersistentState.exp_total must be >= 0")
	player_id = p_player_id
	coin_balance = p_coin_balance
	exp_total = p_exp_total
