extends EnemyState
class_name EnemyIdle
func enter():
	print_debug(self)
	if enemy:
		enemy.aggressive = false
		enemy.animationTree.travel("idle")
func exit():
	return
func physics_update(delta: float) -> void:
	if enemy.aggressive == true:
		Transitioned.emit(self, "EnemyChase")
func update(_delta: float) -> void:
	return
