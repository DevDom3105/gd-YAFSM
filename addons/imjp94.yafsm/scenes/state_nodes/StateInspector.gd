extends EditorInspectorPlugin

func can_handle(object):
	return object.get_class() == 'State'

func parse_property(object, type, path, hint, hint_text, usage):
	if path in ['Global_Function_Condition']:
		return false

	return true
