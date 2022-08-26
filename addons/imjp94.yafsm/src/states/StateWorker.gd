extends Node
class_name StateWorker

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
