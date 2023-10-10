extends Node2D
class_name InputComponent

signal swipe(swipe_direction, swipe_force, time)
signal tap(tap_position)
signal on_tap_start(tap_position)

var swipe_start
var swipe_end
var swipe_difference

var cancel_time = Global.max_tap_time
var timer : Timer = Timer.new()
var time = 0
@export var tap_distance : float = 100.0


# Called when the node enters the scene tree for the first time.
func _ready():
	timer.one_shot = true
	add_child(timer)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _input_detection():
		if _is_swipe():
			_swipe_signal()
		else:
			_tap_signal()

#Rileva i tocchi sullo schermo
func _input_detection():
	if Input.is_action_just_pressed("click"):
		swipe_start = get_global_mouse_position()
		timer.start(cancel_time)
		_tap_start(swipe_start)
	
	if Input.is_action_just_released("click"):
		swipe_end = get_global_mouse_position()
		time = cancel_time - timer.get_time_left()
		if (time == cancel_time):
			return false
		return true


#Restituisce vero se il movimento effettuato è uno swipe, altrimenti restituisce false
func _is_swipe():
	swipe_difference = swipe_start - swipe_end
	if (-tap_distance <= swipe_difference.x and swipe_difference.x <= tap_distance) and (-tap_distance <= swipe_difference.y and swipe_difference.y <= tap_distance):
		return false
	return true

func _tap_start(start_tap_position):
	emit_signal("on_tap_start", start_tap_position)

func _tap_signal():
	emit_signal("tap", swipe_start)

#Emette il segnale in caso di swipe
func _swipe_signal():
	var swipe_x = swipe_start.x - swipe_end.x
	var swipe_x_absolute
	var swipe_y = swipe_start.y - swipe_end.y
	var swipe_y_absolute
	
	if swipe_x < 0:
		swipe_x_absolute = -swipe_x
	else:
		swipe_x_absolute = swipe_x
	
	if swipe_y < 0:
		swipe_y_absolute = -swipe_y
	else:
		swipe_y_absolute = swipe_y
	
	if swipe_x_absolute > swipe_y_absolute:
		if swipe_x < 0:
			emit_signal("swipe", "right", swipe_difference, time)
		else:
			emit_signal("swipe", "left", swipe_difference, time)
	else:
		if swipe_y < 0:
			emit_signal("swipe", "down", swipe_difference, time)
		else:
			emit_signal("swipe", "up", swipe_difference, time)
	
	time = 0





func _on_swipe(swipe_direction, swipe_force, time):
	pass # Replace with function body.


func _on_tap(tap_position):
	pass # Replace with function body.
