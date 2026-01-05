extends Node
@export var initial_state : State

var currentState : State
var states: Dictionary = {}

func _ready():
	if not is_multiplayer_authority():
		set_physics_process(false)
		set_process(false)
		return
	for child in get_children():
		if child is State :
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_child_transition)
	if initial_state:
		initial_state.enter()
		currentState = initial_state
func _physics_process(delta: float) -> void:
	if currentState:
		currentState.update(delta)
func _process(delta: float) -> void:
	#print_debug(currentState)
	if currentState:
		currentState.physics_update(delta)
func transition_to(new_state_name: String):
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
