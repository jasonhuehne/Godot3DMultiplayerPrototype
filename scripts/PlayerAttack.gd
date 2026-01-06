extends PlayerState
class_name PlayerAttack

var did_damage: bool
var charge_time: float
@export var damage_curve: Curve

func enter():
	player.animationTree["parameters/conditions/attacking"] = true
	player.set_collision_layer_value(1, false)
	did_damage = false
	charge_time = 1.5 - player.chargeTime.time_left
	print_debug(self)
func exit():
	player.animationTree["parameters/conditions/attacking"] = false
	player.set_collision_layer_value(1, true)

func physics_update(delta: float) -> void:
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

func _on_hitbox_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	if body and body.is_in_group("enemies") and not did_damage:
		did_damage = true
		var final_damage: int
		if charge_time < 1.5:
			var curve_value = damage_curve.sample(charge_time / 1.5)
			final_damage = int(round(20.0 * curve_value))
		else:
			final_damage = 20
		var knockback_direction = -player.camera.global_transform.basis.z
		knockback_direction.y = 0
		knockback_direction = knockback_direction.normalized()
		body.take_damage.rpc(final_damage, knockback_direction)

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	player.set_collision_layer_value(1, true)
	if anim_name == "attack":
		Transitioned.emit(self, "PlayerMove")