extends Node3D



# Called when the node enters the scene tree for the first time.
func _ready():
	$InformationDisplay.texture = $InformationViewport.get_texture();
	$MoneyDisplay.texture = $MoneyViewport.get_texture();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
