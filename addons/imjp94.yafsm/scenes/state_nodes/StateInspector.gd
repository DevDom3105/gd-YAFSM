extends EditorInspectorPlugin

const State = preload("res://addons/imjp94.yafsm/src/states/State.gd")

func can_handle(object):
	return object is State

func parse_property(object, type, path, hint, hint_text, usage):
	# Hide all property
	#return true
	return false
	#TODO: How to lock all parts except those the user need to modify (State resource, FunctionCondition resource)
	#return false
	#if object is State:
	#	return false
	#else:
	#	return true
