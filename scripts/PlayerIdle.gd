extends PlayerState
class_name PlayerIdle

func enter():
	if player:
		player.animationTree["parameters/conditions/is_not_moving"] = true
	print_debug(self)
	if player:
		player.velocity = Vector3.ZERO
func exit():
	player.animationTree["parameters/conditions/is_not_moving"] = false
func physics_update(_delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	if Input.is_action_pressed("attack") and player.can_attack:
		Transitioned.emit(self, "PlayerCharge")
	if Input.is_action_just_pressed("dash") and player.canDash:
		Transitioned.emit(self, "PlayerDash")	
	if not input_dir == Vector2.ZERO:
		Transitioned.emit(self, "PlayerMove")
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * _delta
	player.move_and_slide()
		
