extends EnemyState
class_name EnemyMove
var waited = false
func enter():
	enemy.aggressive = false
	enemy.set_new_position()
	print_debug(self)
	return

func exit():
	return
func physics_update(delta: float) -> void:

	if enemy.navigation_agent_3d.is_navigation_finished():
		enemy.velocity = enemy.velocity.move_toward(Vector3.ZERO, 1 * delta)
		return

	enemy.look_at(enemy.next_position)
	var destination = enemy.navigation_agent_3d.get_next_path_position()
	var local_destination = destination - enemy.global_position
	var direction = local_destination.normalized()
	enemy.velocity = direction * randf_range(enemy.MIN_SPEED, enemy.MAX_SPEED)
	if not enemy.is_on_floor():
		enemy.velocity += enemy.get_gravity() * delta

	enemy.move_and_slide();
func update(_delta: float) -> void:
	if enemy.navigation_agent_3d.is_navigation_finished() and not waited:
		waited = true
		enemy.healTimer.start()
	if enemy.aggressive:
		Transitioned.emit(self, "EnemyChase")

func _on_heal_timer_timeout() -> void:
	waited = false
	enemy.set_new_position()
