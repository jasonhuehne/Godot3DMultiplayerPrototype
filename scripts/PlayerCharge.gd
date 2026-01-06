extends PlayerState
class_name PlayerCharge

func enter():
	if player:
		player.animationTree["parameters/conditions/charging"] = true
	print_debug(self)
	player.can_attack = false
	player.chargeTime.start()
	player.attackTimeout.start()
func exit():
	player.animationTree["parameters/conditions/charging"] = false

func physics_update(delta: float) -> void:

	if Input.is_action_pressed("attack"):
		if player.chargeTime.time_left <= 0:
			Transitioned.emit(self, "PlayerCharged")

	elif Input.is_action_just_released("attack"):
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