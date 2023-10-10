extends Area3D

var class_id : String
var sprites = []
var original_colors = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_object(id : String):
	class_id = id
	$ClassIcon.texture = Global.get_class_by_id(id).icon
	
	for node in self.get_children():
		if node.is_class("Sprite3D"):
			sprites.append(node)


func on_puzzle_piece_drag():
	for sprite in sprites:
		original_colors.append(sprite.modulate)
		sprite.modulate = sprite.modulate.darkened(0.3) 

func on_puzzle_piece_drop():
	var iterator : int = 0
	for sprite in sprites:
		sprite.modulate = original_colors[iterator]
		iterator += 1
