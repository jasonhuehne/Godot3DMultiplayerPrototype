extends EnemyState
class_name EnemyJumpAttack

func enter():
		if enemy:
			enemy.set_collision_layer_value(1, false)
			print_debug(self)
			enemy.animation_tree["parameters/conditions/no_player_in_attackrange"] = true
			enemy.jumpAttackTimeout.start()

func exit():
	enemy.set_collision_layer_value(1, true)

	
func _on_ground_timeout() -> void:
	if not multiplayer.is_server():
		return
	if enemy.target_player:
		Transitioned.emit(self, "EnemyChase")
	else:
		Transitioned.emit(self, "EnemyMove")

func _on_jump_timeout() -> void:
	if not is_multiplayer_authority():
		return
	enemy.spawn_shockwave()


func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	
	if not is_multiplayer_authority():
		return
	if anim_name == "jumpAttack":
		enemy.animation_tree["parameters/conditions/no_player_in_attackrange"] = false
		enemy.groundTimeout.start()
