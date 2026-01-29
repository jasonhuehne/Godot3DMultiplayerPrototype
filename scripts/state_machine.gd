extends Node
@export var initial_state : State
var currentState : State
@export var currentState_name: String:
	set(value):
		if is_multiplayer_authority():
			currentState_name = value
			return
		currentState_name = value
		_on_sync_state_changed(value)
var states: Dictionary = {}

func _ready():
	for child in get_children():
		if child is State :
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_child_transition)
	if not is_multiplayer_authority():
		set_physics_process(false)
		set_process(false)
		return
	if initial_state:
		initial_state.enter()
		currentState = initial_state
func _physics_process(delta: float) -> void:
	if currentState:
		currentState.physics_update(delta)

func _process(delta: float) -> void:
	if currentState:
		currentState.update(delta)
func transition_to(state, new_state_name: String):
	if state != currentState.name:
		return
	on_child_transition(currentState, new_state_name)
func on_child_transition(state, new_state_name):
	if state != currentState:
		return
	var new_state = states.get(new_state_name.to_lower())
	if !new_state:
		return
	if currentState:
		currentState.exit()
	new_state.enter()
	currentState = new_state
	currentState_name = new_state_name.to_lower()
	
func _on_sync_state_changed(new_node_name: String):

	var new_state = states.get(new_node_name.to_lower())
	if new_state == currentState:
		return
	if new_state:
		if currentState: currentState.exit()
		new_state.enter()
		currentState = new_state
