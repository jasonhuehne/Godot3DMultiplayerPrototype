extends PlayerState
class_name PlayerIdle

func enter():
	if player:
		player.animation_tree["parameters/conditions/is_not_moving"] = true
	print_debug(self)
	if player:
		player.velocity = Vector3.ZERO
func exit():
	player.animation_tree["parameters/conditions/is_not_moving"] = false
func physics_update(_delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	if not input_dir == Vector2.ZERO:
		Transitioned.emit(self, "PlayerMove")
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * _delta
	player.move_and_slide()
		
