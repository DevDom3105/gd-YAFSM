@tool
extends "Condition.gd"
class_name FunctionConditionTrigger

signal condition_resource_set(resource_fpath)

var condition_script
# TODO can be dropped after newly added class_name ?
func get_class():
	return 'FunctionConditionTrigger'

# Return human readable display string. For FunctionCondition just stick with name entered by user.
func display_string():
	return name
