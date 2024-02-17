@icon("res://addons/imjp94.yafsm/assets/icons/state_worker_icon.png")
class_name StateWorker
extends Node

var _smp = null

func enter():
	pass

func update():
	pass 

func exit():
	pass

func external(ref):
	return self._smp.external(ref)
