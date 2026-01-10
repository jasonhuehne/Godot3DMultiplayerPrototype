extends EnemyState
class_name EnemyJumpAttack

func enter():
	enemy.set_collision_layer_value(1, false)
	print_debug(self)
	enemy.animation_player.play("jumpAttack")
	if is_multiplayer_authority():
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

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if not is_multiplayer_authority():
		return
	if anim_name == "jumpAttack":
		enemy.groundTimeout.start()


func _on_jump_timeout() -> void:
	if not is_multiplayer_authority():
		return
	enemy.spawn_shockwave()
