extends EnemyState
class_name EnemyMeleeAttack

func enter():
	enemy.animation_player.play("attack")
	print_debug(self)

func exit():
	return

func physics_update(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if enemy.target_player:
		enemy.look_at(enemy.target_player.body.global_position)
func update(_delta: float) -> void:
	return	
	
func _on_hitbox_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server():
		return
	if body is Character:
		body.take_damage.rpc(20, -enemy.global_transform.basis.z) #player.gd


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if not is_multiplayer_authority():
		return
	if anim_name == "attack":
		var target = enemy.hitbox.get_collider()
		if target:
			enemy.meleeTimeout.start()
			enemy.animation_player.play("attack")
		elif enemy.aggressive:
			Transitioned.emit(self, "EnemyChase")
		else:
			Transitioned.emit(self, "EnemyMove")
