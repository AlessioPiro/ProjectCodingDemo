extends Node2D

@onready var progress_bar_1 = $TextureProgressBar
@onready var progress_bar_2 = $TextureProgressBar2
@onready var progress_bar_3 = $TextureProgressBar3

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func set_progress_bar_value(value):
	progress_bar_1.value = value
	progress_bar_2.value = value
	progress_bar_3.value = value

