extends EnemyState
class_name EnemyMeleeAttack

func enter():
	enemy.meleeTimeout.start()
	enemy.animationPlayer.play("attack")
	print_debug(self)

func exit():
	return

func physics_update(_delta: float) -> void:
	if enemy.target_player:
		enemy.look_at(enemy.target_player.body.global_position)
func update(_delta: float) -> void:
	return

func _on_timeout_timeout() -> void:
	var target = enemy.hitbox.get_collider()
	if target:
		enemy.meleeTimeout.start()
		enemy.animationPlayer.play("attack")
	elif enemy.aggressive:
		Transitioned.emit(self, "EnemyChase")
	else:
		Transitioned.emit(self, "EnemyMove")
	
func _on_hitbox_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	if body is Character:
		body.take_damage.rpc(20, -enemy.global_transform.basis.z)
