extends PlayerState
class_name PlayerMove
func enter():
	if player:
		player.change_anim_state.rpc("walking")
	print_debug(self)
func exit():
	return	


func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta
		if player.global_position.z <= -10:
			player.global_position.z = 200
	var input_dir := Input.get_vector("left", "right", "forward", "backward")

	var direction = (player.head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		player.velocity.x = direction.x * player.SPEED
		player.velocity.z = direction.z * player.SPEED
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, player.SPEED)
		if player.velocity == Vector3.ZERO and input_dir == Vector2.ZERO:
			Transitioned.emit(self, "PlayerIdle")
	player.move_and_slide()

