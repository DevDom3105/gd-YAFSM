extends Resource
class_name FunctionCondition

var _smp = null

func external(val):
	return _smp.external(val)

func condition():
	# User defined FunctionConditions inheriting from this class need to overwrite this function.
	# It will be called when the transition to which this FunctionCondition belongs will be checked.
	# The external() function can be called as in the StateWorker class to access any relevant node as 
	# defined in the statemachineplayer, so any relevant information can be accessed to conclude
	# whether the condition is met.
	pass
