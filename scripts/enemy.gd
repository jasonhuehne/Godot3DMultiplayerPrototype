
extends CharacterBody3D
@export var MIN_SPEED = 6
@export var MAX_SPEED = 8
@export var HEALTH = 100

signal death

#Knockback
var last_hit_direction: Vector3 = Vector3.ZERO
var last_damage: int

#Move
var waypointPositions: Array
var positionIndex: int = 0
var next_position: Vector3

#Chase
var aggroTable: Dictionary = {}
var aggressive = false
var target_player
var target_player_position
class Player:
	var is_in_range: bool
	var body: CharacterBody3D
	var damage_dealt: int

	func _init(_body: Node3D) -> void:
		body =_body
		damage_dealt = 0
var bodies: Array[Player] = []
var body_map: Dictionary = {}

#JumpAttack
var spawnedShockwave = false
var shockwave_scene = preload("res://scenes/level/shockwave.tscn")

#Nodes
@onready var hitbox = $hitbox
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D 
@onready var healTimer = $"State Machine/EnemyMove/HealTimer"
@onready var actionTimeout = $"State Machine/EnemyChase/ActionTimeout"
@onready var jumpAttackTimeout = $"State Machine/EnemyJumpAttack/Jump"
@onready var groundTimeout = $"State Machine/EnemyJumpAttack/Ground"
@onready var meleeTimeout = $"State Machine/EnemyMeleeAttack/Timeout"
@onready var stunTimeout = $"State Machine/EnemyKnockback/StunTime"
@onready var stateMachine = $"State Machine"
@onready var animationPlayer = $AnimationPlayer
@onready var players_container = get_node("/root/Level/PlayersContainer")
@onready var healtBar = $SubViewport/Healthbar3D

func _ready() -> void:
	if not is_multiplayer_authority():
		set_physics_process(false)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	if body.is_in_group("player"):
		var player_id = body.name.to_int()
		if body_map.has(player_id):
			var player: Player = body_map[player_id]
			player.is_in_range = true
		else:
			var new_player = Player.new(body)
			new_player.is_in_range = true
			bodies.append(new_player)
			body_map[player_id] = new_player
		aggressive = true
	_recalculate_aggro()

func _on_area_3d_body_exited(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	if body.is_in_group("player"):
		var player_id = body.name.to_int()
		
		if body_map.has(player_id):
			var player: Player = body_map[player_id]
			player.is_in_range = false
	print_debug(bodies)


#Shockwave (KI-Unterstützt)
func spawn_shockwave():
	if not is_multiplayer_authority():
		return
		
	print_debug("Server: Sende RPC und führe lokal aus")
	
	rpc("spawn_shockwave_on_clients") 
	
	_spawn_vfx()

@rpc("authority", "call_remote", "reliable")
func spawn_shockwave_on_clients():
	_spawn_vfx()

func _spawn_vfx():
	print_debug("VFX wird gespawnt auf: ", multiplayer.get_unique_id())
	if not shockwave_scene:
		print_debug("Shockwave-Szene ist nicht geladen!")
		return
	var shockwave_instance = shockwave_scene.instantiate()
	get_tree().get_root().add_child(shockwave_instance)
	shockwave_instance.global_position = self.global_position
	

#Take Damage
@rpc("any_peer", "call_local", "reliable")
func take_damage(damage, hit_direction):
	if not is_multiplayer_authority():
		return
	
	var attacker_id = multiplayer.get_remote_sender_id()
	if attacker_id == 0:
		attacker_id = 1
	
	var new_life = HEALTH - damage
	last_damage = damage
	last_hit_direction = hit_direction
	HEALTH = new_life
	healtBar.value = new_life
	if body_map.has(attacker_id):
		var player_data = body_map[attacker_id]
		player_data.damage_dealt += damage
		print_debug(attacker_id, " hat ", player_data.damage_dealt ," Schaden erzielt")
		_recalculate_aggro()
	# Fernangriff noch nicht safe wegen damage ohne Attacker
	if HEALTH <= 0:
		death.emit()
		queue_free()
	elif not stateMachine.currentState == $"State Machine/EnemyKnockback":
		stateMachine.transition_to(stateMachine.currentState.name, "EnemyKnockback")
	print_debug("health: ", HEALTH)

func _recalculate_aggro():
	var highest_damage = -1	
	var best_target = null
	for player in body_map.values():
		if player.is_in_range:
			if player.damage_dealt > highest_damage:
				highest_damage = player.damage_dealt
				best_target = player
	if best_target != null:
		if best_target != target_player:
			set_target_player(best_target) #Triggert Chase State
	else:
		set_target_player(null) #Triggert Move State
		

func set_target_player(player):
	target_player = player
	if target_player:
		target_player_position = target_player.body.transform.origin


func set_new_position():
	if positionIndex >= waypointPositions.size():
		positionIndex = 0
		waypointPositions.shuffle()
	next_position = waypointPositions[positionIndex]
	navigation_agent_3d.target_position = next_position
	positionIndex += 1
