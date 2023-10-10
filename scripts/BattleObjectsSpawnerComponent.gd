extends Node2D
class_name BattleObjectsSpawnerComponent

#Spawna gli oggetti non appena viene creato questo component
@export var spawn_objects_on_ready : bool = true

var battle_objects = []
var caller_instance_id
var caller

# Called when the node enters the scene tree for the first time.
func _ready():
	var caller_id = get_caller_instance_id()
	caller = instance_from_id(caller_id)
	
	_fill_battle_objects_array()
	_make_objects_not_visible()
	
	if spawn_objects_on_ready:
		spawn_all_objects()


func get_caller_instance_id():
	var caller_instance_id
	
	var player_node = get_tree().get_first_node_in_group("player")
	var enemy_node = get_tree().get_first_node_in_group("enemy")
	if player_node.is_ancestor_of(self):
		caller_instance_id = player_node.get_instance_id()
	else:
		caller_instance_id = enemy_node.get_instance_id()
	
	return caller_instance_id

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func spawn_all_objects():
	#Spostiamo gli object come figli del caller
	for object in battle_objects:
		
		#Assegniamo un nuovo gruppo agli object
		if !caller.get_groups().is_empty():
			var caller_group_name = caller.get_groups()[0]
			var object_group_name = str(caller_group_name, "_object")
			object.add_to_group(object_group_name)
		
		#Attiviamoli
		if object.has_method("spawn"):
			object.spawn()

func _fill_battle_objects_array():
	for child in get_children():
		battle_objects.append(child)

func _make_objects_not_visible():
	for object in battle_objects:
		object.visible = false
