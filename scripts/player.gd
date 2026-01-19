extends CharacterBody3D
class_name Character

enum SkinColor { BLUE, YELLOW, GREEN, RED }
signal health_changed(new_value)


const SPEED = 5
const SENSITIVITY = 0.002
const DASH_SPEED = 25
@export var HEALTH = 100 #Wird repliziert von Synchronizer
var _current_speed: float


@onready var head = $Head
@onready var body: MeshInstance3D = $MeshInstance3D
@onready var body_collider: CollisionShape3D = $CollisionShape3D
@onready var nickname: Label3D = $PlayerNick/Nickname
@onready var camera: Node3D = $Head/Camera3D


@onready var state_machine = $"State Machine"
@onready var charge_time: Timer = $"State Machine/ChargeTime"
@onready var attack_timeout: Timer = $"State Machine/AttackTimeout"
@onready var dash_timeout: Timer = $"State Machine/DashTimeout"
@onready var stun_timeout: Timer = $"State Machine/StunTime"
var can_dash = true
var can_attack = true
var is_dashing = false


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
var animation_state




var last_hit_direction: Vector3 = Vector3.ZERO
var last_damage: int
var player_inventory: PlayerInventory
func _enter_tree():
	var id = str(name).to_int()
	if id > 0:
		set_multiplayer_authority(id)

func _ready():
	animation_tree.active = true
	animation_state = animation_tree.get("parameters/playback")
	var is_local_player = is_multiplayer_authority()
	var local_client_id = multiplayer.get_unique_id()

	print("Debug: Player ", name, " ready - authority: ", get_multiplayer_authority(), ", local client: ", local_client_id, ", is_local: ", is_local_player)

	if is_local_player:
		player_inventory = PlayerInventory.new()
		_add_starting_items()
		
	elif multiplayer.is_server():
		player_inventory = PlayerInventory.new()
		_add_starting_items()
	else:
		if get_multiplayer_authority() == local_client_id:
			request_inventory_sync.rpc_id(1)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _check_fall_and_respawn():
	if global_transform.origin.y < -15.0:
		take_damage(20, null)
		_respawn()
func get_spawn_point() -> Vector3:
	var spawn_point = Vector2.from_angle(randf() * 2 * PI) * 10 # spawn radius
	return Vector3(spawn_point.x, 2, spawn_point.y)
func _respawn():
	global_transform.origin = get_spawn_point()
	velocity = Vector3.ZERO

func _physics_process(_delta: float) -> void:
	_check_fall_and_respawn()

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if state_machine.currentState.name == "PlayerMove":
		if event.is_action_pressed("attack") and can_attack:
			state_machine.transition_to(state_machine.currentState.name, "PlayerCharge")
			return
		elif event.is_action_pressed("dash") and can_dash and can_attack:
			state_machine.transition_to(state_machine.currentState.name, "PlayerDash")
	if event.is_action_pressed("escape"):
		get_tree().quit()
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		nickname.rotate_y(-event.relative.x * SENSITIVITY)
		body.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-20), deg_to_rad(80))
func freeze():
	velocity.x = 0
	velocity.z = 0
	_current_speed = 0
func death():
	velocity.x = 0
	velocity.z = 0
	_current_speed = 0
	request_death.rpc()
	_respawn()
	
func _on_dash_timeout_timeout() -> void:
	can_dash = true

func _on_attack_timeout_timeout() -> void:
	can_attack = true

func change_anim_state(state_name: String):
		animation_state.travel(state_name)

# Health Network Funtions - Server authorative, client-specific
@rpc ("any_peer","call_local", "reliable", 0)
func take_damage(DAMAGE, knockback_direction) -> void:
	if not multiplayer.is_server():
		return

	HEALTH -= DAMAGE #Wird repliziert von Synchronizer

	var owner_id = get_multiplayer_authority()
	sync_health_to_owner.rpc_id(owner_id, HEALTH, knockback_direction, DAMAGE)

@rpc ("any_peer","call_local", "reliable", 1)
func request_death() -> void:
	if not multiplayer.is_server():
		return
	HEALTH = 100
	var owner_id = get_multiplayer_authority()
	sync_health_to_owner.rpc_id(owner_id, HEALTH, null, null)
	
@rpc("any_peer", "call_local", "reliable", 1)
func sync_health_to_owner(new_health: int, direction, amount):
	if multiplayer.get_remote_sender_id() != 1:
		print_debug("Wrong sender of Health Sync")
		return
	if is_multiplayer_authority():
		if direction != null:
			last_hit_direction = direction
		state_machine.transition_to(state_machine.currentState.name, "PlayerKnockback")
		if amount != null:
			last_damage = amount
		HEALTH = new_health
		health_changed.emit(HEALTH, get_multiplayer_authority())


# Inventory Network Functions - Server authoritative, client-specific
@rpc("any_peer", "call_local", "reliable")
func request_inventory_sync():
	print("Debug: request_inventory_sync called on player ", name, " (authority: ", get_multiplayer_authority(), ") by client ", multiplayer.get_remote_sender_id())

	if not multiplayer.is_server():
		return

	var requesting_client = multiplayer.get_remote_sender_id()
	if requesting_client != get_multiplayer_authority():
		push_warning("Client " + str(requesting_client) + " tried to request inventory for player " + str(get_multiplayer_authority()))
		return

	if player_inventory:
		sync_inventory_to_owner.rpc_id(requesting_client, player_inventory.to_dict())

@rpc("any_peer", "call_local", "reliable")
func sync_inventory_to_owner(inventory_data: Dictionary):
	print("Debug: sync_inventory_to_owner called on player ", name, " (authority: ", get_multiplayer_authority(), ") - local unique id: ", multiplayer.get_unique_id(), " from: ", multiplayer.get_remote_sender_id())

	if multiplayer.get_remote_sender_id() != 1:
		return

	if not is_multiplayer_authority():
		return

	if not player_inventory:
		player_inventory = PlayerInventory.new()
	player_inventory.from_dict(inventory_data)

	var level_scene = get_tree().get_current_scene()
	if level_scene:
		if is_multiplayer_authority() or get_multiplayer_authority() == multiplayer.get_unique_id():
			print("Debug: This is the local player, updating UI")
			if level_scene.has_method("update_local_inventory_display"):
				level_scene.update_local_inventory_display()
			if level_scene.has_node("InventoryUI"):
				var inventory_ui = level_scene.get_node("InventoryUI")
				if inventory_ui.visible and inventory_ui.has_method("refresh_display"):
					print("Debug: Calling refresh_display directly on InventoryUI")
					inventory_ui.refresh_display()
		else:
			print("Debug: Not the local player, skipping UI update")

@rpc("any_peer", "call_local", "reliable")
func request_move_item(from_slot: int, to_slot: int, quantity: int = -1):
	print("Debug: request_move_item called - from:", from_slot, " to:", to_slot, " on player ", name, " (authority: ", get_multiplayer_authority(), ") by client ", multiplayer.get_remote_sender_id())

	if not multiplayer.is_server():
		return

	var requesting_client = multiplayer.get_remote_sender_id()
	if requesting_client != get_multiplayer_authority():
		push_warning("Client " + str(requesting_client) + " tried to modify inventory for player " + str(get_multiplayer_authority()))
		return

	if not player_inventory:
		return

	if from_slot < 0 or from_slot >= PlayerInventory.INVENTORY_SIZE or to_slot < 0 or to_slot >= PlayerInventory.INVENTORY_SIZE:
		push_warning("Invalid slot indices: from=" + str(from_slot) + " to=" + str(to_slot))
		return

	var success = false
	if quantity == -1:
		success = player_inventory.move_item(from_slot, to_slot)
		if not success:
			success = player_inventory.swap_items(from_slot, to_slot)
			print("Debug: Swapped items between slots ", from_slot, " and ", to_slot)
		else:
			print("Debug: Moved item from slot ", from_slot, " to ", to_slot)
	else:
		success = player_inventory.move_item(from_slot, to_slot, quantity)
		print("Debug: Moved ", quantity, " items from slot ", from_slot, " to ", to_slot)

	if success:
		print("Debug: Move successful, syncing inventory to owner ", get_multiplayer_authority())
		var owner_id = get_multiplayer_authority()
		if owner_id != 1:
			sync_inventory_to_owner.rpc_id(owner_id, player_inventory.to_dict())
		else:
			var level_scene = get_tree().get_current_scene()
			if level_scene and level_scene.has_method("update_local_inventory_display"):
				level_scene.update_local_inventory_display()
	else:
		print("Debug: Move/swap failed")

@rpc("any_peer", "call_local", "reliable")
func request_add_item(item_id: String, quantity: int = 1):
	print("Debug: request_add_item called on player ", name, " (authority: ", get_multiplayer_authority(), ") by client ", multiplayer.get_remote_sender_id())

	if not multiplayer.is_server():
		return

	var requesting_client = multiplayer.get_remote_sender_id()
	if requesting_client != get_multiplayer_authority() and requesting_client != 1:
		push_warning("Client " + str(requesting_client) + " tried to add items to player " + str(get_multiplayer_authority()))
		return

	if not player_inventory:
		return

	if quantity <= 0:
		push_warning("Invalid quantity: " + str(quantity))
		return

	var item = ItemDatabase.get_item(item_id)
	if not item:
		push_warning("Item not found: " + item_id)
		return

	var remaining = player_inventory.add_item(item, quantity)
	var added = quantity - remaining
	print("Debug: Added ", added, " ", item_id, " to inventory (", remaining, " remaining)")

	if added > 0:
		var owner_id = get_multiplayer_authority()
		print("Debug: Syncing inventory to owner ", owner_id)
		if owner_id != 1:
			sync_inventory_to_owner.rpc_id(owner_id, player_inventory.to_dict())
		else:
			var level_scene = get_tree().get_current_scene()
			if level_scene and level_scene.has_method("update_local_inventory_display"):
				level_scene.update_local_inventory_display()

@rpc("any_peer", "call_local", "reliable")
func request_remove_item(item_id: String, quantity: int = 1):
	print("Debug: request_remove_item called on player ", name, " (authority: ", get_multiplayer_authority(), ") by client ", multiplayer.get_remote_sender_id())

	if not multiplayer.is_server():
		return

	var requesting_client = multiplayer.get_remote_sender_id()
	if requesting_client != get_multiplayer_authority():
		push_warning("Client " + str(requesting_client) + " tried to remove items from player " + str(get_multiplayer_authority()))
		return

	if not player_inventory:
		return

	if quantity <= 0:
		push_warning("Invalid quantity: " + str(quantity))
		return

	var removed = player_inventory.remove_item(item_id, quantity)

	if removed > 0:
		var owner_id = get_multiplayer_authority()
		if owner_id != 1:
			sync_inventory_to_owner.rpc_id(owner_id, player_inventory.to_dict())

func get_inventory() -> PlayerInventory:
	return player_inventory

func _add_starting_items():
	if not player_inventory:
		return

	var sword = ItemDatabase.get_item("iron_sword")
	var potion = ItemDatabase.get_item("health_potion")

	if sword:
		player_inventory.add_item(sword, 1)
	if potion:
		player_inventory.add_item(potion, 3)
