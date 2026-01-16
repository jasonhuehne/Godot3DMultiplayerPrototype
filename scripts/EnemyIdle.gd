extends EnemyState
class_name EnemyIdle
func rotate(_delta: float):
		enemy.global_rotate(Vector3.UP, _delta)
func enter():
	print_debug(self)
	if enemy:
		enemy.aggressive = false
func exit():
	return
func physics_update(delta: float) -> void:
	rotate(delta)
	if enemy.aggressive == true:
		Transitioned.emit(self, "EnemyChase")
func update(_delta: float) -> void:
	return
