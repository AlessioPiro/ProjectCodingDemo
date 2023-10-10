extends Area3D
class_name MapNode

@export var flash_energy : float
@export var max_flash : float = 3

@export var state : String = "disabled" #Possible states: traveled, unreachable, reachable, current, disabled,
@export var type : String #Possibili tipi: battle, lunas, treasure, unknown, boss
@export var next_nodes = []
@export var id : Vector2 #id del nodo dato dalla posizione all'interno della mappa
var type_related_variables : Dictionary = {} #Dizionario al cui interno vengono inserite tutte le informazioni che un nodo deve avere a seconda del suo tipo

# Called when the node enters the scene tree for the first time.
func _ready():
	if state == "disabled":
		visible = false
		return
	
	_change_icon()
	
	_change_state()
	
	if state == "reachable":
		$AnimationPlayer.play("Reachable")
	
	if state == "unreachable":
		$Sprite.modulate = Color (0.50, 0.50, 0.50)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Effetto flash
	$Mesh.material_override.emission_energy_multiplier = flash_energy


# Cambia l'icona del nodo a seconda del tipo
func _change_icon():
	if type == "battle":
		$Sprite.texture = preload("res://assets/icons/map_battle_icon.png")
	elif type == "lunas":
		$Sprite.texture = preload("res://assets/icons/map_lunas_icon.png")
	elif type == "treasure":
		$Sprite.texture = preload("res://assets/icons/map_treasure_icon.png")
	elif type == "unknown":
		$Sprite.texture = preload("res://assets/icons/map_unknown_icon.png")
	elif type == "boss":
		$Sprite.texture = preload("res://assets/icons/map_boss_icon.png")


#
func _change_state():
	if state == "traveled":
		$Mesh.material_override = preload("res://materials/map_node_traveled.tres")
	elif state == "unreachable":
		$Mesh.material_override = preload("res://materials/map_node_unreachable.tres")
	else:
		$Mesh.material_override = preload("res://materials/map_node_reachable.tres").duplicate() #Aggiunto il duplicate perchè altrimenti tutti i nodi cercano di modificare lo stesso materiale risultando in un nulla di fatto



func _on_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if state == "reachable":
			Global.map_node_movement_to = id
			var transfer_data = _select_transfer_data(type)
			
			################################################
			if type == "boss":
				type = "battle"
			################################################
			
			Global.change_scene_from_map(type, transfer_data)

func _select_transfer_data(type : String) -> Dictionary:
	var transfer_data = {}
	match type:
		"lunas":
			pass
		"battle":
			transfer_data.merge(type_related_variables)
		"unknown":
			transfer_data.merge(type_related_variables)
		"treasure":
			transfer_data.merge(type_related_variables)
		"boss":
			transfer_data.merge(type_related_variables)
	return transfer_data


func set_from_map_node_data(map_node_data : MapNodeData):
	id = map_node_data.get_id()
	state = map_node_data.get_state()
	type = map_node_data.get_type()
	next_nodes = map_node_data.get_next_nodes()
	type_related_variables = map_node_data.get_type_related_variables()

func set_id(value : Vector2):
	id = value

func set_flash_energy(value : float):
	flash_energy = value

func set_state(value : String):
	state = value
	_check_current()

func set_type(value : String):
	type = value

func set_max_flash(value : float):
	max_flash = value

func set_next_nodes(value):
	next_nodes = value

func _check_current():
	if state == "current":
		Global.map_node_movement_from = id

func set_type_related_variables(input_dictionary : Dictionary):
	type_related_variables = input_dictionary

func set_single_value_in_type_related_variables(key : String, value):
	type_related_variables[key] = value

func get_id() -> Vector2:
	return id

func get_state() -> String:
	return state

func get_type() -> String:
	return type

func get_next_nodes() -> Array:
	return next_nodes

func get_type_related_variables() -> Dictionary:
	return type_related_variables
