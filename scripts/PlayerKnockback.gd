extends PlayerState
class_name PlayerKnockback

var knockback_force: float = 10
var friction: float = 20
var timer_started = false

func enter():
	print_debug("PlayerKnocknack")
	player.change_anim_state.rpc("knockback")
	player.set_collision_layer_value(1, false)
	timer_started = false
	var direction = player.last_hit_direction
	if direction == Vector3.ZERO:
		direction = -player.global_transform.basis.z
	if player.last_damage == 10:
		knockback_force = 15
	player.velocity = direction * knockback_force
func exit():
	player.set_collision_layer_value(1, true)
	player.stunTimeout.stop()
func physics_update(delta: float) -> void:
	player.velocity = player.velocity.move_toward(Vector3.ZERO, friction * delta)
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta
	player.move_and_slide()

func _on_stun_time_timeout() -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	if Input.is_action_pressed("attack") and player.can_attack:
		Transitioned.emit(self, "PlayerAttack")
	elif Input.is_action_just_pressed("dash") and player.canDash:
		Transitioned.emit(self, "PlayerDash")	
	elif not input_dir == Vector2.ZERO:
		Transitioned.emit(self, "PlayerMove")
	else:
		Transitioned.emit(self, "PlayerIdle")

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "knockback":
		player.stunTimeout.start()	
