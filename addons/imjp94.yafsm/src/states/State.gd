@tool
extends Resource
class_name State

signal name_changed(new_name)

# Reserved state name for Entry/Exit
const ENTRY_STATE = "Entry"
const EXIT_STATE = "Exit"

const META_GRAPH_OFFSET = "graph_offset" # Meta key for graph_offset

@export var name: = "":  # Name of state, unique within StateMachine
	set = set_name

@export var Global_Function_Condition : Resource:
	set = _set_global_fcond_res
var _global_fcond_resource = null

var graph_offset:  # Position in FlowChart stored as meta, for editor only
	set = set_graph_offset, 
	get = get_graph_offset

func _set_global_fcond_res(val):
	Global_Function_Condition = val
	if val != null:
		_global_fcond_resource = val.new()
	else:
		_global_fcond_resource = null

func _init(p_name=""):
	name = p_name

func is_entry():
	return name == ENTRY_STATE

func is_exit():
	return name == EXIT_STATE

func set_graph_offset(offset):
	set_meta(META_GRAPH_OFFSET, offset)

func get_graph_offset():
	return get_meta(META_GRAPH_OFFSET) if has_meta(META_GRAPH_OFFSET) else Vector2.ZERO

func set_name(n):
	if name != n:
		name = n
		emit_signal("name_changed", name)

func is_global():
	return _global_fcond_resource != null

func get_class():
	return 'State'
