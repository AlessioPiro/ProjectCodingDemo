extends Node3D

@onready var WindowTitleLabel = $PackageInformationWindow/WindowTitle
@onready var PackageNameLabel = $PackageInformationWindow/PackageName
@onready var PackageDescriptionLabel = $PackageInformationWindow/PackageDescription
@onready var OneClassContainerNode = $PackageInformationWindow/ClassesWindows/OneClass
@onready var TwoClassesContainerNode = $PackageInformationWindow/ClassesWindows/TwoClasses
@onready var ThreeClassesContainerNode = $PackageInformationWindow/ClassesWindows/ThreeClasses
@onready var PackageIconSprite = $IconWindow/PackageIcon
@onready var trash_button_component = $PackageInformationWindow/Buttons/TrashButton/ButtonComponent
@onready var background_sprite = $Screen/MeshInstance3D
@onready var animation_player = $AnimationPlayer

var package

@export var background_transparency : float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	background_sprite.set_instance_shader_parameter("alpha_multiplier", background_transparency)


func pop_in(package_id: String):
	_set_package_information_box(package_id)
	global_position = _calculate_box_position()
	rotation = get_viewport().get_camera_3d().global_rotation
	animation_player.play("pop_in")


func pop_out():
	OneClassContainerNode.visible = false
	TwoClassesContainerNode.visible = false
	ThreeClassesContainerNode.visible = false
	animation_player.play("pop_out")

func _set_package_information_box(package_id : String):
	package = Global.get_package_by_id(package_id)
	var num_classes = package.classes.size()
	
	WindowTitleLabel.text = str(package.package_name, ".jar")
	PackageNameLabel.text = package.package_name
	PackageDescriptionLabel.text = package.unlocked_description
	PackageIconSprite.texture = package.icon
	
	var container_node
	match num_classes:
		1:
			container_node = OneClassContainerNode
		2:
			container_node = TwoClassesContainerNode
		3:
			container_node = ThreeClassesContainerNode
	_set_classes_window(container_node)
	container_node.visible = true
	
	_set_trash_button()

func _set_classes_window(container_node : Node3D):
	var counter = 0
	for class_window in container_node.get_children():
		class_window.set_class_window(package.classes[counter])
		counter += 1


func _calculate_box_position():
	# Ottiene la camera
	var camera = get_viewport().get_camera_3d()
	# Ottene la posizione della camera
	var camera_position = camera.global_transform.origin
	# Ottene il vettore d'avanti della telecamera
	var camera_forward = -camera.global_transform.basis.z.normalized()
	# Lunghezza desiderata (distanza tra la telecamera e l'oggetto)
	var distance_from_camera = 0.5
	# Calcola la posizione dell'oggetto
	var alert_box_position = camera_position + camera_forward * distance_from_camera
	return alert_box_position


func _set_trash_button():
	trash_button_component.object_id = package.id
	trash_button_component.object_type = "package"


func set_end_position():
	global_position += Vector3(0, 100, 0)
