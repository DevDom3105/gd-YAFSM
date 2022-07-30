tool
extends "Condition.gd"
class_name FunctionCondition

signal condition_resource_set(resource_fpath)

#export(String) var condition_fpath setget _set_condition_fpath
var condition_script

#var _fpath = null

func condition(plyr):
	return funcref(condition_script, 'condition').call_func(plyr)

#func _set_condition_fpath(value):
#	var file = load(value).new()
#	#TODO: has_method() does not exist? 
#	#if not file.has_method('condition'):
#	#	print('But issue! ')
#	#	return
#	#condition_fpath = value
#	condition_script = file
#	emit_signal("condition_resource_set", value)
	

#TODO: What is displayed? this needed?
# Return human readable display string, for example, "condition_name == True"
func display_string():
	return name
