@icon("res://addons/imjp94.yafsm/assets/icons/state_worker_icon.png")
class_name StateWorker
extends Node

var _smp = null

func enter():
	pass

func update():
	pass 

func exit():
	pass

func external(ref):
	return self._smp.external(ref)

func get_class():
	# Used by statemachine player to identify a node as StateWorker, 
	# so do not override this function in inheriting classes
	return "StateWorker"
