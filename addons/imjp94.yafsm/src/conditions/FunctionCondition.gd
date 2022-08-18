tool
extends "Condition.gd"
class_name FunctionCondition

signal condition_resource_set(resource_fpath)

var condition_script

func condition(plyr):
	return funcref(condition_script, 'condition').call_func(plyr)

# Return human readable display string. For FunctionCondition just stick with name entered by user.
func display_string():
	return name
