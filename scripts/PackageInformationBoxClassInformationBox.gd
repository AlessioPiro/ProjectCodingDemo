extends Node3D

@onready var ClassSprite = $ClassSprite/ClassSprite
@onready var TypeSprite = $ClassSprite/TypeSprite
@onready var ClassName = $ClassName
@onready var ClassDescription = $ClassDescription

var types_icon_folder_path = "res://assets/icons/type_icons/"

var game_class

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_class_window(class_id : String):
	game_class = Global.get_class_by_id(class_id)
	ClassSprite.texture = game_class.icon
	ClassName.text = game_class.object_class_name
	ClassDescription.text = game_class.description
	
	_set_type_sprite()


func _set_type_sprite():
	var type_name : String
	var type_sprite : Texture
	type_name = game_class.get_type()
	
	type_sprite = load(str(types_icon_folder_path, type_name, "_icon.png"))
	TypeSprite.texture = type_sprite

