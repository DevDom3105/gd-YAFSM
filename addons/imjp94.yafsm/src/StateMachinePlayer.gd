tool
extends "StackPlayer.gd"
const State = preload("states/State.gd")
const StateMachine = preload("states/StateMachine.gd")

signal transited(from, to) # Transition of state
signal entered(to) # Entry of state machine(including nested), empty string equals to root
signal exited(from) # Exit of state machine(including nested, empty string equals to root
signal updated(state, delta) # Time to update(based on process_mode), up to user to handle any logic, for example, update movement of KinematicBody

# Enum to define how state machine should be updated
enum ProcessMode {
	PHYSICS,
	IDLE,
	MANUAL
}

export(Resource) var state_machine # StateMachine being played 
export(bool) var active = true setget set_active # Activeness of player
export(bool) var autostart = true # Automatically enter Entry state on ready if true
export(ProcessMode) var process_mode = ProcessMode.IDLE setget set_process_mode # ProcessMode of player
export(Dictionary) var externals = {}

var _is_started = false
var _parameters # Parameters to be passed to condition
var _local_parameters
var _is_update_locked = true
var _was_transited = false # If last transition was successful
var _is_param_edited = false
var _global_states = []


func _init():
	if Engine.editor_hint:
		return

	_parameters = {}
	_local_parameters = {}
	_was_transited = true # Trigger _transit on _ready

func _get_configuration_warning():
	if state_machine:
		if not state_machine.has_entry():
			return "State Machine will not function properly without Entry node"
	else:
		return "State Machine Player is not going anywhere without default State Machine"
	return ""

func _ready():
	if Engine.editor_hint:
		return

	set_process(false)
	set_physics_process(false)
	call_deferred("_initiate") # Make sure connection of signals can be done in _ready to receive all signal callback
	_register_in_state_workers(self)
	_register_in_funconds_nested(state_machine)

func _register_in_state_workers(node):
	for n in node.get_children():
		if n.get_class() == 'StateWorker':
			n._smp = self
		elif n is Node:
			_register_in_state_workers(n)
		else:
			print("Unexpected Node type under StateMachinePlayer ", n.get_class())

func _register_in_funconds_nested(state_machine, state_machine_path='root'):
	_register_in_funconds(state_machine, state_machine_path)
	for s in state_machine.states.values():
		if s is StateMachine:
			_register_in_funconds_nested(s, state_machine_path+'/'+s.name)


func _register_in_funconds(state_machine, state_machine_path):
	for from_transitions in state_machine.transitions.values():
		for t in from_transitions.values():
			if t.has_FunctionCondition():
				t._fcond_resource._smp = self
				print("Registered SMP in transition ", t.from, t.to)
	for state in state_machine.states.values():
		if state.Global_FCond_Resource != null:
			print('Registered GLOBAL state ', state_machine_path + '/'+state.name)
			state._global_fcond_resource._smp = self
			_global_states.append(state_machine_path + '/'+state.name)

func _initiate():
	if autostart:
		start()
	_on_active_changed()
	_on_process_mode_changed()

func _process(delta):
	if Engine.editor_hint:
		return

	_update_start()
	update(delta)
	_update_end()

func _physics_process(delta):
	if Engine.editor_hint:
		return

	_update_start()
	update(delta)
	_update_end()

# Only get called in 4 conditions: _parameters edited, last transition was successful, current
# state has transition with a FuncitonCondition, or global state exists
func _transit(global_transits=true):
	if not active:
		return
	# Attempt to transit if parameter edited, last transition was successful, or when current state has a FunctionCondition
	var has_function_condition = false
	var state_path = get_current()
	var nested_states = state_path.split("/")
	var is_nested = nested_states.size() > 1
	var is_nested_exit = nested_states[nested_states.size()-1] == State.EXIT_STATE
	if is_nested and is_nested_exit:
		state_path = path_backward(state_path)
	var nested_state_machine = _get_nested_state_machine(state_path)
	var nested_state = path_end_dir(state_path)
	if nested_state in nested_state_machine.transitions.keys():
		var from_transitions = nested_state_machine.transitions.get(nested_state)
		for t in from_transitions.values():
			if t.has_FunctionCondition():
				has_function_condition = true
				break
	if (not _is_param_edited and not _was_transited) and not has_function_condition and len(_global_states)==0:
		return
	
	var from = get_current()
	var local_params = _local_parameters.get(path_backward(from), {})
	var next_state = null
	# check for global transition
	if global_transits:
		for gstate_path in _global_states:
			# TODO: Make get_nested_state function like get_nested_state_machine
			gstate_path = node_path_to_state_path(gstate_path)
			var gstate_name = path_end_dir(gstate_path)
			var gstate = _get_nested_state_machine(gstate_path).states[gstate_name]
			if gstate._global_fcond_resource.condition() and get_current() != gstate_path:
				next_state = gstate_path
				break
	
	# local transition gets priority by overwriting next_state
	var local_next_state = state_machine.transit(get_current(), _parameters, local_params)
	if local_next_state:
		next_state = local_next_state
	
	if next_state:
		if stack.has(next_state):
			reset(stack.find(next_state))
		else:
			push(next_state)
	var to = next_state
	_was_transited = !!next_state
	_is_param_edited = false
	_flush_trigger(_parameters)
	_flush_trigger(_local_parameters, true)

	if _was_transited:
		_on_state_changed(from, to)

func _on_state_changed(from, to):
	match to:
		State.ENTRY_STATE:
			emit_signal("entered", "")
		State.EXIT_STATE:
			set_active(false) # Disable on exit
			emit_signal("exited", "")
	
	if to.ends_with(State.ENTRY_STATE) and to.length() > State.ENTRY_STATE.length():
		# Nexted Entry state
		var state = path_backward(get_current())
		emit_signal("entered", state)
	elif to.ends_with(State.EXIT_STATE) and to.length() > State.EXIT_STATE.length():
		# Nested Exit state, clear "local" params
		var state = path_backward(get_current())
		clear_param(state, false) # Clearing params internally, do not update
		emit_signal("exited", state)
	var from_worker = get_state_worker(from)
	var to_worker = get_state_worker(to)
	if from_worker != null:
		from_worker.exit()
	if to_worker != null:
		to_worker.enter()
	#print(Engine.get_frames_drawn(), " StateMachinePlayer: transit ", from, " -> ", to)
	emit_signal("transited", from, to)

# Called internally if process_mode is PHYSICS/IDLE to unlock update()
func _update_start():
	_is_update_locked = false

# Called internally if process_mode is PHYSICS/IDLE to lock update() from external call
func _update_end():
	_is_update_locked = true

# Called after update() which is dependant on process_mode, override to process current state
func _on_updated(delta, state):
	pass

func _on_process_mode_changed():
	if not active:
		return

	match process_mode:
		ProcessMode.PHYSICS:
			set_physics_process(true)
			set_process(false)
		ProcessMode.IDLE:
			set_physics_process(false)
			set_process(true)
		ProcessMode.MANUAL:
			set_physics_process(false)
			set_process(false)

func _on_active_changed():
	if Engine.editor_hint:
		return

	if active:
		_on_process_mode_changed()
		_transit()
	else:
		set_physics_process(false)
		set_process(false)

# Remove all trigger(param with null value) from provided params, only get called after _transit
# Trigger another call of _flush_trigger on first layer of dictionary if nested is true
func _flush_trigger(params, nested=false):
	for param_key in params.keys():
		var value = params[param_key]
		if nested and value is Dictionary:
			_flush_trigger(value)
		if value == null: # Param with null as value is treated as trigger
			params.erase(param_key)

func reset(to=-1, event=ResetEventTrigger.LAST_TO_DEST):
	.reset(to, event)
	_was_transited = true # Make sure to call _transit on next update

# Manually start the player, automatically called if autostart is true
func start():
	push(State.ENTRY_STATE)
	emit_signal("entered", "")
	_was_transited = true
	_is_started = true

# Restart player
func restart(is_active=true, preserve_params=false):
	reset()
	set_active(is_active)
	if not preserve_params:
		clear_param("", false)
	start()

func external(name):
	if not name in externals.keys():
		printerr('StateMachine does not have entry for extern name ', name)
		return null
	else:
		return get_node(externals[name])

# Update player to, first initiate transition, then call _on_updated, finally emit "update" signal, delta will be given based on process_mode.
# Can only be called manually if process_mode is MANUAL, otherwise, assertion error will be raised.
# *delta provided will be reflected in signal updated(state, delta)
func update(delta=get_physics_process_delta_time(), global_transits=true):
	if not active:
		return
	if process_mode != ProcessMode.MANUAL:
		assert(not _is_update_locked, "Attempting to update manually with ProcessMode.%s" % ProcessMode.keys()[process_mode])

	_transit(global_transits)
	var current_state = get_current()
	_on_updated(current_state, delta)
	emit_signal("updated", current_state, delta)
	if process_mode == ProcessMode.MANUAL:
		# Make sure to auto advance even in MANUAL mode
		if _was_transited:
			call_deferred("update", "global_transits", false)
	var state_worker = get_state_worker(current_state)
	if state_worker != null:
		#print(Engine.get_frames_drawn(), ' State worker update from SMP')
		state_worker.update()

# Set trigger to be tested with condition, then trigger _transit on next update, 
# automatically call update() if process_mode set to MANUAL and auto_update true
# Nested trigger can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func set_trigger(name, auto_update=true):
	set_param(name, null, auto_update)

func set_nested_trigger(path, name, auto_update=true):
	set_nested_param(path, name, null, auto_update)

# Set param(null value treated as trigger) to be tested with condition, then trigger _transit on next update, 
# automatically call update() if process_mode set to MANUAL and auto_update true
# Nested param can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func set_param(name, value, auto_update=true):
	var path = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	set_nested_param(path, name, value, auto_update)

func set_nested_param(path, name, value, auto_update=true):
	if path.empty():
		_parameters[name] = value
	else:
		var local_params = _local_parameters.get(path)
		if local_params is Dictionary:
			local_params[name] = value
		else:
			local_params = {}
			local_params[name] = value
			_local_parameters[path] = local_params
	_on_param_edited(auto_update)

# Remove param, then trigger _transit on next update, 
# automatically call update() if process_mode set to MANUAL and auto_update true
# Nested param can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func erase_param(name, auto_update=true):
	var path = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	return erase_nested_param(path, name, auto_update)

func erase_nested_param(path, name, auto_update=true):
	var result = false
	if path.empty():
		result = _parameters.erase(name)
	else:
		result = _local_parameters.get(path, {}).erase(name)
	_on_param_edited(auto_update)
	return result

# Clear params from specified path, empty string to clear all, then trigger _transit on next update, 
# automatically call update() if process_mode set to MANUAL and auto_update true
# Nested param can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func clear_param(path="", auto_update=true):
	if path.empty():
		_parameters.clear()
	else:
		_local_parameters.get(path, {}).clear()
		# Clear nested params
		for param_key in _local_parameters.keys():
			if param_key.begins_with(path):
				_local_parameters.erase(param_key)

# Called when param edited, automatically call update() if process_mode set to MANUAL and auto_update true
func _on_param_edited(auto_update=true):
	_is_param_edited = true
	if process_mode == ProcessMode.MANUAL and auto_update and _is_started:
		update()

# Get value of param
# Nested param can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func get_param(name, default=null):
	var path = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	return get_nested_param(path, name, default)

func get_nested_param(path, name, default=null):
	if path.empty():
		return _parameters.get(name, default)
	else:
		var local_params = _local_parameters.get(path, {})
		return local_params.get(name, default)

# Get duplicate of whole parameter dictionary
func get_params():
	return _parameters.duplicate()

# Return true if param exists
# Nested param can be accessed through path "path/to/param_name", for example, "App/Game/is_playing"
func has_param(name):
	var path = ""
	if "/" in name:
		path = path_backward(name)
		name = path_end_dir(name)
	return has_nested_param(path, name)

func has_nested_param(path, name):
	if path.empty():
		return name in _parameters
	else:
		var local_params = _local_parameters.get(path, {})
		return name in local_params

# Return if player started
func is_entered():
	return State.ENTRY_STATE in stack

# Return if player ended
func is_exited():
	return get_current() == State.EXIT_STATE

func set_active(v):
	if active != v:
		if v:
			if is_exited():
				push_warning("Attempting to make exited StateMachinePlayer active, call reset() then set_active() instead")
				return
		active = v
		_on_active_changed()

func set_process_mode(mode):
	if process_mode != mode:
		process_mode = mode
		_on_process_mode_changed()

func get_current():
	var v = .get_current()
	return v if v else ""

func get_previous():
	var v = .get_previous()
	return v if v else ""

static func join_path(base, dirs):
	var path = base
	for dir in dirs:
		if path.empty():
			path = dir
		else:
			path = str(path, "/", dir)
	return path

func _get_nested_state_machine(state_path):
	var nested_states = state_path.split("/")
	var is_nested = nested_states.size() > 1
	var end_state_machine = state_machine
	var base_path = ""
	for i in nested_states.size() - 1: # Ignore last one, to get its parent StateMachine
		var state = nested_states[i]
		# Construct absolute base path
		base_path = join_path(base_path, [state])
		if end_state_machine != state_machine:
			end_state_machine = end_state_machine.states[state]
		else:
			end_state_machine = state_machine.states[state] # First level state
	return end_state_machine

# Convert node path to state path that can be used to query state with StateMachine.get_state.
# Node path, "root/path/to/state", equals to State path, "path/to/state"
static func node_path_to_state_path(node_path):
	var p = node_path.replace("root", "")
	if p.begins_with("/"):
		p = p.substr(1)
	return p

# Convert state path to node path that can be used for query node in scene tree.
# State path, "path/to/state", equals to Node path, "root/path/to/state"
static func state_path_to_node_path(state_path):
	var path = state_path
	if path.empty():
		path = "root"
	else:
		path = str("root/", path)
	return path

# Return parent path, "path/to/state" return "path/to"
static func path_backward(path):
	return path.substr(0, path.rfind("/"))

# Return end directory of path, "path/to/state" returns "state"
static func path_end_dir(path):
	return path.right(path.rfind("/") + 1)

func get_state_worker(state_path):
	return get_node_or_null(state_path)

func get_current_state_worker():
	return get_state_worker(get_current())

