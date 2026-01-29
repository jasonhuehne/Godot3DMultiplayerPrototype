class_name EnemyState extends State
var enemy: CharacterBody3D

func _ready() -> void:
	if not is_multiplayer_authority():
		set_physics_process(false)
		return
	await owner.ready
	enemy = owner as CharacterBody3D