@tool
extends "Condition.gd"
class_name FunctionConditionTrigger

signal condition_resource_set(resource_fpath)

var condition_script

# Return human readable display string. For FunctionCondition just stick with name entered by user.
func display_string():
	return name
