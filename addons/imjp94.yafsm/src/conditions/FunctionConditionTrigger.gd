tool
extends "Condition.gd"

signal condition_resource_set(resource_fpath)

var condition_script

func get_class():
	return 'FunctionConditionTrigger'

# Return human readable display string. For FunctionCondition just stick with name entered by user.
func display_string():
	return name
