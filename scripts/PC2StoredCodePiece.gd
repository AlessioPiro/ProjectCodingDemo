extends Area3D
class_name PC2StoredCodePiece

var code_piece_id : String
var state : String = "enabled" #stati: enabled, disabled

@onready var drag_and_drop_component = $DragAndDropObjectComponent

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_object(id : String):
	code_piece_id = id
	$CodePieceIcon.texture = Global.get_code_piece_by_id(id).icon


func set_disabled():
	state = "disabled"
	drag_and_drop_component.set_disabled()

func set_enabled():
	state = "enabled"
	drag_and_drop_component.set_enabled()
	
