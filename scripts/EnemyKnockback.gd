extends EnemyState
class_name EnemyKnockback

var knockback_force: float = 24
var friction: float = 20
var timer_started = false
var positionIndex: int
@export var knockback_curve: Curve

func enter():
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
	enemy.stun_timeout.stop()
func physics_update(delta: float) -> void:
	enemy.velocity = enemy.velocity.move_toward(Vector3.ZERO, friction * delta)
	
	enemy.move_and_slide()
	
	if enemy.velocity.length() < 0.1:
		if not timer_started:
			timer_started = true
			enemy.stun_timeout.start()		

func _on_stun_time_timeout() -> void:
	if enemy.aggressive:
		Transitioned.emit(self, "EnemyChase")
	else:
		Transitioned.emit(self, "EnemyMove")
