extends PlayerState
class_name Spectate

func enter():
	if player:
		player.body.visible = false
		player.nickname.visible = false
		player.weapon.visible = false
		player.global_position = Vector3(12.5, 5, 10)
		player.collision_layer = 0
		player.collision_mask = 0
		

func exit():
	player.visible = true
	player.collision_layer = 1
	player.collision_mask = 1
	player.animation_tree["parameters/conditions/is_not_moving"] = false

func physics_update(_delta: float) -> void:
	player.velocity = Vector3.ZERO
