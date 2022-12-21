extends EditorInspectorPlugin

const State = preload("res://addons/imjp94.yafsm/src/states/State.gd")

func can_handle(object):
	return object is State

func parse_property(object, type, path, hint, hint_text, usage):
	# Hide all property
	# false to allow Global transition property to be edited
	# TODO: How to restrict access to this prperty? also this allowed accessing statemachineplayer nodes -> disable
	# Make similar EditorInspectorPlugin for StateMachine to deny property access? Used in Plugin.gd
	return false#true 
