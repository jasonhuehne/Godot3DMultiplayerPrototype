extends EnemyState
class_name EnemyKnockback

var knockback_force: float = 24
var friction: float = 20
var timer_started = false
var positionIndex: int
@export var knockback_curve: Curve

func enter():
	if enemy:
		enemy.animation_tree["parameters/conditions/hit"] = true
	timer_started = false
	var direction = enemy.last_hit_direction
	if direction == Vector3.ZERO:
		direction = -enemy.global_transform.basis.z
	if enemy.last_damage == 20:
		knockback_force = 15
	else:
		var curve_value = knockback_curve.sample(enemy.last_damage / 10)
		knockback_force = 10*curve_value
	enemy.velocity = direction * knockback_force
func exit():
	enemy.animation_tree["parameters/conditions/hit"] = false
func physics_update(delta: float) -> void:
	enemy.velocity = enemy.velocity.move_toward(Vector3.ZERO, friction * delta)
	
	enemy.move_and_slide()



func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "knockback":
		if enemy.aggressive:
			Transitioned.emit(self, "EnemyChase")
		else:
			Transitioned.emit(self, "EnemyMove")
