extends Resource
class_name Array2D

var array2D := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_value(x, y, value):
	if !array2D.has(x):
		array2D[x] = {}
	array2D[x][y] = value

func get_value(x, y):
	if array2D.has(x) and array2D[x].has(y):
		return array2D[x][y]
	return null
