extends EditorInspectorPlugin

func _can_handle(object):
	return object.get_class() == 'State'

func _parse_property(object, type, path, hint, hint_text, usage, wide) -> bool:
	# Hide all properties except global function condition
	if path in ['Global_Function_Condition']:
		return false
	return true
