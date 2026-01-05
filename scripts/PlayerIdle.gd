extends PlayerState
class_name PlayerIdle

func enter():
	print_debug(self)
	if player:
		player.change_anim_state.rpc("idle")
		player.velocity = Vector3.ZERO

func physics_update(_delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	if Input.is_action_pressed("attack") and player.can_attack:
		Transitioned.emit(self, "PlayerAttack")
	if Input.is_action_just_pressed("dash") and player.canDash:
		Transitioned.emit(self, "PlayerDash")	
	if not input_dir == Vector2.ZERO:
		Transitioned.emit(self, "PlayerMove")
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * _delta
	player.move_and_slide()
		
