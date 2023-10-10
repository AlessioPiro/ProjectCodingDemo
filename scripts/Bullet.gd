extends Node3D
class_name Bullet

##OPPONENT: colpisce solo l'avversario; OPPONENT_OBJECTS: colpisce solo l'avversario e/o ciò che ha spawnato; OPPONENT_AND_NEUTRAL_OBJECTS: colpisce solo l'avversario e/o oggetti che ha spawnato e neutrali; EVERYTHING: copisce qualsiasi oggetto di gioco
@export_enum("opponent", "opponent_objects", "opponent_and_neutral_objects", "everything") var target_mode = "opponent"

@export_enum("straight") var behavior = "straight"
@export var bullet_speed : float = 5

var opponents_groups = [] #Nomi dei gruppi dei bersagli
var main_opponent_group #Gruppo di cui fa parte l'avversario principale (enemy o player)

var is_in_movement = false

var caller_node
var main_opponent_node

func _init():
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_in_movement:
		_move(delta)


func get_caller_instance_id():
	var caller_instance_id
	
	var player_node = get_tree().get_first_node_in_group("player")
	var enemy_node = get_tree().get_first_node_in_group("enemy")
	if player_node.is_ancestor_of(self):
		caller_instance_id = player_node.get_instance_id()
	else:
		caller_instance_id = enemy_node.get_instance_id()
	
	return caller_instance_id



func spawn():
	
	#Ricava informazioni sull'ambiente
	caller_node = instance_from_id(get_caller_instance_id())
	##Setta gli opponents groups
	_set_opponents_groups()
	main_opponent_node = get_tree().get_first_node_in_group(main_opponent_group)
	
	#Setta la posizione di spawn
	if caller_node.has_node("BulletSpawnPoint"):
		global_position = caller_node.get_node("BulletSpawnPoint").global_position
	else: 
		global_position = caller_node.global_position
	
	#Si mostra
	visible = true
	
	#Inizia movimento
	is_in_movement = true

func _move(delta):
	match behavior:
		"straight":
			var direction_z
			if main_opponent_node.global_position.z - caller_node.global_position.z > 0:
				direction_z = 1
			else:
				direction_z = -1
			global_position.z += direction_z * bullet_speed * delta
			
			#var new_position = Vector3(global_position.x, global_position.y, lerp(caller_node.global_position.z, main_opponent_node.global_position.z, bullet_speed * delta))
			#global_position = new_position


func _set_opponents_groups():
	if caller_node.is_in_group("player"):
		main_opponent_group = "enemy"
	elif caller_node.is_in_group("enemy"):
		main_opponent_group = "player"
	
	match target_mode:
		"opponent":
			opponents_groups.append(main_opponent_group)
		"opponent_objects":
			opponents_groups.append(main_opponent_group) 
			opponents_groups.append(str(main_opponent_group, "_object"))
		"opponent_and_neutral_objects":
			opponents_groups.append(main_opponent_group) 
			opponents_groups.append(str(main_opponent_group, "_object"))
			opponents_groups.append("neutral")
		"everything":
			opponents_groups.append(main_opponent_group) 
			opponents_groups.append(str(main_opponent_group, "_object"))
			opponents_groups.append("neutral")
			opponents_groups.append(caller_node.get_groups()[0])


func get_opponents_groups() -> Array:
	return opponents_groups
