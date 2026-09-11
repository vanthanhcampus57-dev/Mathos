class_name GameplayContainer
extends Container

## Responsive container for GameplayHBox under QuestionHostContainer.
## Supports two presentation modes:
## 1. Normal stage mode (Stage 1.1–1.4): Side-by-side horizontal layout with QuestionPanelHost
##    on the left and AdvisorPanel on the right (16px gap).
## 2. Boss combat mode (Stage 1.5): Full-canvas layout with BossCombatPanel occupying
##    the full 1280x720 canvas and QuestionPanelHost positioned Top-Center (530px wide,
##    beneath the Top HUD), matching the authoritative Stitch reference.

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_resort_children()

func _resort_children() -> void:
	var boss_panel: Control = get_node_or_null("BossCombatPanel") as Control
	var q_host_panel: Control = get_node_or_null("QuestionPanelHost") as Control
	var advisor: Control = get_node_or_null("AdvisorPanel") as Control

	if boss_panel != null and boss_panel.visible:
		# Ensure QuestionPanelHost renders on top of BossCombatPanel if both are visible
		if q_host_panel != null and q_host_panel.get_index() < boss_panel.get_index():
			move_child(q_host_panel, -1)

		# 1. BossCombatPanel spans the entire container area
		fit_child_in_rect(boss_panel, Rect2(Vector2.ZERO, size))

		# 2. QuestionPanelHost is placed TOP-CENTER (width 580–650px, top ~88px)
		if q_host_panel != null and q_host_panel.visible:
			var min_w: float = q_host_panel.get_combined_minimum_size().x
			var target_w: float = 600.0
			var q_w: float = clampf(maxf(target_w, min_w), 580.0, minf(650.0, size.x))
			var q_x: float = (size.x - q_w) * 0.5
			var min_h: float = q_host_panel.get_combined_minimum_size().y
			var max_h: float = minf(290.0, maxf(220.0, size.y - 380.0))
			var q_h: float = clampf(min_h, 220.0, max_h)
			var q_y: float = 88.0
			if size.y < 700.0:
				q_y = 60.0
			fit_child_in_rect(q_host_panel, Rect2(Vector2(q_x, q_y), Vector2(q_w, q_h)))

		if advisor != null and advisor.visible:
			advisor.visible = false
	else:
		# Standard side-by-side layout for normal curriculum stages
		var sep: float = 16.0
		var adv_w: float = 0.0
		if advisor != null and advisor.visible:
			adv_w = advisor.get_combined_minimum_size().x
			if adv_w <= 0.0:
				adv_w = 260.0
		var q_w: float = size.x
		if adv_w > 0.0:
			q_w = maxf(0.0, size.x - adv_w - sep)
		if q_host_panel != null and q_host_panel.visible:
			fit_child_in_rect(q_host_panel, Rect2(Vector2.ZERO, Vector2(q_w, size.y)))
		if advisor != null and advisor.visible:
			fit_child_in_rect(advisor, Rect2(Vector2(size.x - adv_w, 0.0), Vector2(adv_w, size.y)))

func _get_minimum_size() -> Vector2:
	var boss_panel: Control = get_node_or_null("BossCombatPanel") as Control
	var q_host_panel: Control = get_node_or_null("QuestionPanelHost") as Control
	var advisor: Control = get_node_or_null("AdvisorPanel") as Control

	if boss_panel != null and boss_panel.visible:
		var bp_min: Vector2 = boss_panel.get_combined_minimum_size()
		var qp_min: Vector2 = q_host_panel.get_combined_minimum_size() if (q_host_panel != null and q_host_panel.visible) else Vector2.ZERO
		return Vector2(maxf(bp_min.x, qp_min.x), maxf(bp_min.y, qp_min.y))
	else:
		var total_w: float = 0.0
		var max_h: float = 0.0
		if q_host_panel != null and q_host_panel.visible:
			var q_min: Vector2 = q_host_panel.get_combined_minimum_size()
			total_w += q_min.x
			max_h = maxf(max_h, q_min.y)
		if advisor != null and advisor.visible:
			var a_min: Vector2 = advisor.get_combined_minimum_size()
			total_w += a_min.x + 16.0
			max_h = maxf(max_h, a_min.y)
		return Vector2(total_w, max_h)
