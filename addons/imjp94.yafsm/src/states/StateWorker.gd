extends Node
class_name State

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
	return "StateWorker"
