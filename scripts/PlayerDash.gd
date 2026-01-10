extends PlayerState
class_name PlayerDash

func enter():
	player.animation_tree["parameters/conditions/dashing"] = true
	player.dash_timeout.start()
	print_debug(self)
	player.set_collision_layer_value(5, false)
	player.can_dash = false
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction = (player.head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		player.velocity.x = direction.x * player.DASH_SPEED
		player.velocity.z = direction.z * player.DASH_SPEED
	else:
		var forward_direction = -player.head.global_transform.basis.z
		player.velocity.x = forward_direction.x * player.DASH_SPEED
		player.velocity.z = forward_direction.z * player.DASH_SPEED

func exit():
	player.animation_tree["parameters/conditions/dashing"] = false
	player.set_collision_layer_value(5, true)

func physics_update(_delta: float) -> void:
	player.velocity = player.velocity.move_toward(Vector3.ZERO, 50 * _delta)
	player.move_and_slide()


func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "dash":
		Transitioned.emit(self, "PlayerMove")