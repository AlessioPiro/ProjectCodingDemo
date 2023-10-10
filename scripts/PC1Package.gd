extends Area3D

var package_id : String

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_pc1_package(id : String):
	package_id = id
	$PackageIcon.texture = Global.get_package_by_id(id).icon
