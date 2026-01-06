extends PlayerState
class_name PlayerCharged


func enter():
	print_debug(self)
func exit():
	return
func physics_update(delta: float) -> void:

	if Input.is_action_just_released("attack"):
		player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, player.SPEED)
		Transitioned.emit(self, "PlayerAttack")

	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction = (player.head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		player.velocity.x = direction.x * player.SPEED/3
		player.velocity.z = direction.z * player.SPEED/3  
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, player.SPEED)
	player.move_and_slide()
