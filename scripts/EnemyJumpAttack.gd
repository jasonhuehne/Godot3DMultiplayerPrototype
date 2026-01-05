extends EnemyState
class_name EnemyJumpAttack

var waited = false
func enter():
	print_debug(self)
	waited = false
	enemy.set_collision_layer_value(1, false)
	enemy.jumpAttackTimeout.start()
func exit():
	enemy.set_collision_layer_value(1, true)
	waited = false
func physics_update(delta: float) -> void:
	if not waited:
		enemy.velocity = Vector3.UP * randf_range(3, 5)
	if waited:
		if not enemy.is_on_floor():
			enemy.velocity += enemy.get_gravity() * delta * 4
		if enemy.is_on_floor():
			if enemy.groundTimeout.is_stopped():
				enemy.groundTimeout.start()
				enemy.spawn_shockwave()
	enemy.move_and_slide();

	
func update(_delta: float) -> void:
	return
	

func _on_jump_timeout() -> void:
	if waited == false:
		waited = true


func _on_ground_timeout() -> void:
	if enemy.target_player:
		Transitioned.emit(self, "EnemyChase")
	else:
		Transitioned.emit(self, "EnemyMove")