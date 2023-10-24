extends Node3D


##OPPONENT: colpisce solo l'avversario; OPPONENT_OBJECTS: colpisce solo l'avversario e/o ciò che ha spawnato; OPPONENT_AND_NEUTRAL_OBJECTS: colpisce solo l'avversario e/o oggetti che ha spawnato e neutrali; EVERYTHING: copisce qualsiasi oggetto di gioco
@export_enum("opponent", "opponent_objects", "opponent_and_neutral_objects", "everything") var target_mode = "opponent"
@export_enum("based_on_user", "fixed") var spawn_point = "fixed"

var opponents_groups = [] #Nomi dei gruppi dei bersagli
var main_opponent_group #Gruppo di cui fa parte l'avversario principale (enemy o player)

var caller_node
var main_opponent_node

# Called when the node enters the scene tree for the first time.
func _ready():
	_init_move()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _init_move():
	#Ricava informazioni sull'ambiente
	caller_node = instance_from_id(get_caller_instance_id())
	##Setta gli opponents groups
	_set_opponents_groups()
	main_opponent_node = get_tree().get_first_node_in_group(main_opponent_group)
	
	#Setta la posizione di spawn
	_set_move_position()
	
	#Si mostra
	visible = true

func get_caller_instance_id():
	var caller_instance_id
	
	var player_node = get_tree().get_first_node_in_group("player")
	var enemy_node = get_tree().get_first_node_in_group("enemy")
	if player_node.is_ancestor_of(self):
		caller_instance_id = player_node.get_instance_id()
	else:
		caller_instance_id = enemy_node.get_instance_id()
	
	return caller_instance_id


func _set_move_position():
	#Settiamo posizione
	match spawn_point:
		"based_on_user":
			if caller_node.has_node("BulletSpawnPoint"):
				global_position = caller_node.get_node("BulletSpawnPoint").global_position
			else: 
				global_position = caller_node.global_position
		"fixed":
			if caller_node.has_node("BulletSpawnPoint"):
				global_position.z = caller_node.get_node("BulletSpawnPoint").global_position.z
				global_position.x = caller_node.get_node("BulletSpawnPoint").global_position.x
			else: 
				global_position.z = caller_node.global_position.z
				global_position.x = caller_node.global_position.x
	
	#Settiamo rotazione
	if caller_node.get_groups().size() > 0 and caller_node.get_groups()[0].contains("enemy"):
		global_rotation -= Vector3(0,0,0)


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


func spawn():
	var animation_player
	if self.has_node("AnimationPlayer"):
		animation_player = self.get_node("AnimationPlayer")
		animation_player.play("start_move")



func get_opponents_groups() -> Array:
	return opponents_groups
