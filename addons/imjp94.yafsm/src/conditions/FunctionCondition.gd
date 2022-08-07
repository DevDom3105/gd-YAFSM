tool
extends "Condition.gd"
class_name FunctionCondition

signal condition_resource_set(resource_fpath)

var condition_script

func condition(plyr):
	return funcref(condition_script, 'condition').call_func(plyr)

#TODO: What is displayed? this needed?
# Return human readable display string, for example, "condition_name == True"
func display_string():
	return name
