class_name Cria
extends EnemyBase
## Cria de Ammit: pequena y rapida, prefiere atacar cultivos (GDD 6.4).

@export var crop_search_radius: float = 22.0


func _choose_target() -> Node3D:
	var best: Node3D = null
	var best_d := crop_search_radius
	for p in get_tree().get_nodes_in_group("farm_plots"):
		if p.state != FarmPlot.State.PLANTED:
			continue
		var d: float = global_position.distance_to(p.global_position)
		if d < best_d:
			best_d = d
			best = p
	if best:
		return best
	return get_tree().get_first_node_in_group("player")
