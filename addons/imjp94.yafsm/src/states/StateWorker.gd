extends Node
class_name StateWorker

#export(Resource) var global_transition_Fcond setget _set_fcond_res
#var _fcond_resource = null
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




#func _set_fcond_res(val):
#	global_transition_Fcond = val
#	if val != null:
#		_fcond_resource = val.new()
#	else:
#		_fcond_resource = null
