extends Area3D
class_name ColliderComponent

var parent_instance_id

# Called when the node enters the scene tree for the first time.
func _ready():
	parent_instance_id = get_parent().get_instance_id()
	if !is_connected("area_entered", _on_area_entered):
		self.area_entered.connect(_on_area_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_entered(area):
	Global.scene_signal_manager.get_battle_element_signal_manager(parent_instance_id).collision.emit(area)
