extends Node2D

#LE MOSSE VANNO FATTE AGGIUNGERE COME FIGLI DEL NODO CHE LE HA LANCIATE (NEMICO, GIOCATORE, ECC.)

@export var class_id : String
##OPPONENT: colpisce solo l'avversario; OPPONENT_OBJECTS: colpisce solo l'avversario e/o ciò che ha spawnato; OPPONENT_AND_NEUTRAL_OBJECTS: colpisce solo l'avversario e/o oggetti che ha spawnato e neutrali; EVERYTHING: copisce qualsiasi oggetto di gioco
@export_enum("opponent", "opponent_objects", "opponent_and_neutral_objects", "everything") var target_mode = "opponent"

var caller_instance_id : int #Id dell'istanza di chi ha effettuato la mossa
var opponents_groups = [] #Nomi dei gruppi dei bersagli

func _ready():
	_init_move()

func _init_move():
	caller_instance_id = get_parent().get_instance_id()
	
	#Setta il gruppo dell'avversario
	_set_opponents_groups()


func _set_opponents_groups():
	var main_opponent_group
	
	if get_parent().is_in_group("player"):
		main_opponent_group = "enemy"
	elif get_parent().is_in_group("enemy"):
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
			opponents_groups.append(get_parent().get_groups()[0])


#Setta il chiamante della mossa e i suoi avversari
func reset_move(input_caller : int, input_opponents : Array):
	caller_instance_id = input_caller
	opponents_groups = input_opponents


#GETTER

func get_caller_instance_id() -> int:
	return caller_instance_id

func get_opponents_groups() -> Array:
	return opponents_groups

func get_id() -> String:
	return class_id
