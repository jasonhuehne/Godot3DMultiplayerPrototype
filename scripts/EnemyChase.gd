extends EnemyState
class_name EnemyChase
var speed
func enter():
	enemy.aggressive = true
	speed = randf_range(enemy.MIN_SPEED, enemy.MAX_SPEED)
	print_debug(self)
func exit():
	return
func physics_update(delta: float) -> void:


	if enemy.target_player:
		enemy.navigation_agent_3d.target_position = Vector3(enemy.target_player.body.global_position.x, enemy.global_position.y, enemy.target_player.body.global_position.z)		
		var look_target = enemy.target_player.body.global_position
		look_target.y = enemy.global_position.y # Nur auf der Y-Achse drehen
		enemy.look_at(look_target, Vector3.UP)
		var target = enemy.hitbox.get_collider()
		if target and target.is_in_group("player"):
			Transitioned.emit(self, "EnemyMeleeAttack")
			return
		if enemy.actionTimeout and enemy.actionTimeout.is_stopped():
			enemy.actionTimeout.start()	
	var destination = enemy.navigation_agent_3d.get_next_path_position()
	var local_destination = destination - enemy.global_position
	var direction = local_destination.normalized()
	enemy.velocity = direction * speed
	if not enemy.is_on_floor():
		enemy.velocity += enemy.get_gravity() * delta
	enemy.move_and_slide();
		
		
func _update(_delta: float) -> void:
	if enemy.target_player == null:
		Transitioned.emit(self, "EnemyMove")

func _on_action_timeout_timeout() -> void:
	var target = enemy.hitbox.get_collider()
	if enemy.actionTimeout and target:
		Transitioned.emit(self, "EnemyMeleeAttack")
	else:
		Transitioned.emit(self, "EnemyJumpAttack")
