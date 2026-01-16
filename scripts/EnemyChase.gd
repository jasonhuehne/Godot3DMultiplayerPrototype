extends EnemyState
class_name EnemyChase
var speed
@export var rotation_speed : float = 15.0 # Wie schnell sich der Gegner dreht
func enter():
	if enemy:
		enemy.animation_tree["parameters/conditions/player_in_range"] = true
		enemy.aggressive = true
		speed = randf_range(enemy.MIN_SPEED, enemy.MAX_SPEED)
	print_debug(self)
func exit():
	return
func physics_update(delta: float) -> void:


	if enemy.target_player:
		var player_pos = enemy.target_player.body.global_position
		enemy.navigation_agent_3d.target_position = player_pos
		enemy.look_at(player_pos)
		# Angriff-Check
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
