class_name CardCombatController
extends RefCounted

## Controller coordinating Stage 1.5 Card Combat against Boss STOCHAS.
## Manages turn transitions, player/boss HP & shield updates, card selection,
## question evaluation combat outcomes, defeat handling, and victory triggers.

signal combat_state_changed()
signal combat_log_emitted(message: String, type: String)
signal boss_hp_changed(current: int, max_val: int, delta: int)
signal player_hp_changed(current: int, max_val: int, delta: int)
signal card_selected(card: CardModel)
signal boss_defeated()
signal player_defeated()
signal combat_reset()

# Ultimate flow signals
signal boss_ultimate_meter_changed(current: int, max_val: int)
signal boss_ultimate_queued()
signal boss_ultimate_charge_started()
signal boss_ultimate_challenge_started()
signal boss_ultimate_resolved(success: bool, damage: int)

const BOSS_ULTIMATE_METER_MAX: int = 4
const ULTIMATE_CHARGE_DURATION: float = 2.4
const ULTIMATE_CHALLENGE_DURATION: float = 8.0
const ULTIMATE_DAMAGE: int = 24

var player_runtime: PlayerRuntime = null
var boss_entity: EnemyEntity = null
var hand_cards: Array[CardModel] = []
var selected_card: CardModel = null
var is_in_combat: bool = false
var turn_counter: int = 1

var boss_ultimate_meter: int = 0
var is_ultimate_queued: bool = false
var is_ultimate_charge_active: bool = false
var is_ultimate_challenge_active: bool = false

func start_combat(p_player: PlayerRuntime, p_boss: EnemyEntity, p_cards: Array[CardModel]) -> void:
	assert(p_player != null, "CardCombatController requires PlayerRuntime")
	assert(p_boss != null, "CardCombatController requires EnemyEntity")
	player_runtime = p_player
	boss_entity = p_boss
	hand_cards = p_cards.duplicate()
	selected_card = hand_cards[0] if not hand_cards.is_empty() else null
	is_in_combat = true
	turn_counter = 1
	boss_ultimate_meter = 0
	is_ultimate_queued = false
	is_ultimate_charge_active = false
	is_ultimate_challenge_active = false

	combat_state_changed.emit()
	boss_ultimate_meter_changed.emit(boss_ultimate_meter, BOSS_ULTIMATE_METER_MAX)
	if selected_card != null:
		card_selected.emit(selected_card)
	combat_log_emitted.emit("⚔️ Trận quyết chiến với %s bắt đầu!" % boss_entity.display_name, "info")

func select_card(card_id: String) -> bool:
	var target_id: String = card_id.strip_edges().to_lower()
	for c in hand_cards:
		var cid: String = c.card_id.strip_edges().to_lower()
		if cid == target_id or cid == "card_" + target_id or ("card_" + cid) == target_id or (target_id.begins_with("card_") and cid == target_id.substr(5)):
			selected_card = c
			card_selected.emit(selected_card)
			combat_state_changed.emit()
			return true
	return false

func get_selected_card() -> CardModel:
	if selected_card == null and not hand_cards.is_empty():
		selected_card = hand_cards[0]
	return selected_card

func increment_boss_ultimate_meter() -> void:
	if is_ultimate_challenge_active or is_ultimate_charge_active:
		return
	boss_ultimate_meter += 1
	boss_ultimate_meter_changed.emit(boss_ultimate_meter, BOSS_ULTIMATE_METER_MAX)
	if boss_ultimate_meter >= BOSS_ULTIMATE_METER_MAX:
		boss_ultimate_meter = 0
		is_ultimate_queued = true
		boss_ultimate_queued.emit()

func trigger_boss_ultimate_charge() -> void:
	if is_ultimate_charge_active or is_ultimate_challenge_active:
		return
	is_ultimate_charge_active = true
	is_ultimate_queued = false
	boss_ultimate_charge_started.emit()

func trigger_boss_ultimate_challenge() -> void:
	is_ultimate_charge_active = false
	is_ultimate_challenge_active = true
	boss_ultimate_challenge_started.emit()

func resolve_ultimate_outcome(is_correct: bool) -> Dictionary:
	var outcome: Dictionary = {
		"is_ultimate": true,
		"is_correct": is_correct,
		"damage_dealt": 0,
		"player_defeated": false,
		"effects_applied": []
	}
	is_ultimate_challenge_active = false
	is_ultimate_charge_active = false
	is_ultimate_queued = false

	if is_correct:
		# Karl Dodge, 0 damage
		combat_log_emitted.emit("✨ NÉ TRÁNH THÀNH CÔNG! STOCHAS CHAOS VERDICT VÔ HIỆU HOÁ", "player_success")
		boss_ultimate_resolved.emit(true, 0)
	else:
		# 24 damage: shield -> HP
		var prev_hp: int = player_runtime.current_hp
		player_runtime.apply_damage(ULTIMATE_DAMAGE)
		var actual_loss: int = prev_hp - player_runtime.current_hp
		outcome["damage_dealt"] = ULTIMATE_DAMAGE
		player_hp_changed.emit(player_runtime.current_hp, player_runtime.max_hp, -actual_loss)
		combat_log_emitted.emit("💥 CHAOS VERDICT OANH KÍCH -%d HP!" % ULTIMATE_DAMAGE, "boss_attack")
		boss_ultimate_resolved.emit(false, ULTIMATE_DAMAGE)

		if player_runtime.is_defeated:
			is_in_combat = false
			outcome["player_defeated"] = true
			combat_log_emitted.emit("💀 Bạn đã bị %s áp đảo!" % boss_entity.display_name, "defeat")
			player_defeated.emit()
			combat_state_changed.emit()
			return outcome

	turn_counter += 1
	combat_state_changed.emit()
	return outcome

func resolve_answer_outcome(is_correct: bool) -> Dictionary:
	if not is_in_combat or boss_entity == null or player_runtime == null:
		return {"success": false, "in_combat": false}

	if is_ultimate_challenge_active:
		return resolve_ultimate_outcome(is_correct)

	var active_card: CardModel = get_selected_card()
	var outcome: Dictionary = {
		"is_correct": is_correct,
		"card_id": active_card.card_id if active_card != null else "",
		"boss_defeated": false,
		"player_defeated": false,
		"effects_applied": []
	}

	if is_correct:
		# Player card executes successfully
		if active_card != null:
			for ef_var in active_card.effects:
				var ef: Dictionary = ef_var as Dictionary
				var e_type: String = String(ef.get("effect_type", ""))
				var amt: int = int(ef.get("amount", 0))

				match e_type:
					"damage":
						var hp_loss: int = boss_entity.apply_damage(amt)
						boss_hp_changed.emit(boss_entity.current_hp, boss_entity.max_hp, -hp_loss)
						combat_log_emitted.emit("⚔️ STRIKE — STOCHAS -%d HP" % hp_loss, "player_success")
						outcome["effects_applied"].append({"type": "damage", "target": "boss", "amount": amt})
					"shield":
						player_runtime.apply_shield(amt)
						player_hp_changed.emit(player_runtime.current_hp, player_runtime.max_hp, 0)
						combat_log_emitted.emit("🛡️ DEFEND — +%d SHIELD" % amt, "player_success")
						outcome["effects_applied"].append({"type": "shield", "target": "player", "amount": amt})
					"heal":
						var prev_hp: int = player_runtime.current_hp
						player_runtime.heal(amt)
						var healed: int = player_runtime.current_hp - prev_hp
						player_hp_changed.emit(player_runtime.current_hp, player_runtime.max_hp, healed)
						combat_log_emitted.emit("💚 HEAL — +%d HP" % healed, "player_success")
						outcome["effects_applied"].append({"type": "heal", "target": "player", "amount": amt})

		if boss_entity.is_defeated:
			is_in_combat = false
			outcome["boss_defeated"] = true
			combat_log_emitted.emit("🏆 BOSS %s ĐÃ BỊ ĐÁNH BẠI!" % boss_entity.display_name, "victory")
			boss_defeated.emit()
			combat_state_changed.emit()
			return outcome
	else:
		# Player answered incorrectly: card fails & boss attacks with intent
		var intent: Dictionary = boss_entity.get_current_intent()
		var dmg_amount: int = 10
		var raw_effects: Array = intent.get("effects", []) as Array
		for ef_var in raw_effects:
			var ef: Dictionary = ef_var as Dictionary
			if String(ef.get("effect_type", "")) == "damage":
				dmg_amount = int(ef.get("amount", 10))

		var prev_hp: int = player_runtime.current_hp
		player_runtime.apply_damage(dmg_amount)
		var actual_loss: int = prev_hp - player_runtime.current_hp
		player_hp_changed.emit(player_runtime.current_hp, player_runtime.max_hp, -actual_loss)

		combat_log_emitted.emit("❌ SAI — STOCHAS TẤN CÔNG -%d HP" % dmg_amount, "boss_attack")
		boss_entity.advance_intent()

		if player_runtime.is_defeated:
			is_in_combat = false
			outcome["player_defeated"] = true
			combat_log_emitted.emit("💀 Bạn đã bị %s áp đảo!" % boss_entity.display_name, "defeat")
			player_defeated.emit()
			combat_state_changed.emit()
			return outcome

	increment_boss_ultimate_meter()

	turn_counter += 1
	combat_state_changed.emit()
	return outcome

func reset_encounter(stats: PlayerStats) -> void:
	if player_runtime != null and stats != null:
		player_runtime.reset_stage_runtime(stats)
	if boss_entity != null:
		boss_entity.reset()

	is_in_combat = true
	turn_counter = 1
	boss_ultimate_meter = 0
	is_ultimate_queued = false
	is_ultimate_charge_active = false
	is_ultimate_challenge_active = false
	if not hand_cards.is_empty():
		selected_card = hand_cards[0]

	combat_reset.emit()
	boss_ultimate_meter_changed.emit(0, BOSS_ULTIMATE_METER_MAX)
	combat_state_changed.emit()
	combat_log_emitted.emit("🔄 Quyết chiến được tái thiết lập. Chuẩn bị tấn công!", "info")
