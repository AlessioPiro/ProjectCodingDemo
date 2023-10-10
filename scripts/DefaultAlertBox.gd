extends Node3D

#ABILITA LA FUNZIONE "EDITABLE CHILDREN" PER MODIFICARE I BUTTON COMPONENTS

##Numero di pulsanti 
@export_enum("single_button", "double_button") var alert_box_type = "single_button"
##Titolo dell'Alert Box
@export var title : String = "Title"
##Testo dell'Alert Box
@export var text : String = "Text"


@export_group("Single Button Properties")
##Testo del secondo pulsante
@export var single_button_button_text : String = "Ok"

@export_group("Double Button Properties")
##Testo del primo pulsante
@export var double_button_first_button_text : String = "Ok"
##Testo del secondo pulsante
@export var double_button_second_button_text : String = "Ok"

@export_group("DO NOT TOUCH")
##GIÙ LE MANI
@export var background_alpha : float = 1.0


@onready var background = $Background
@onready var single_button = $AlertBox/SingleButton
@onready var double_button_1 = $AlertBox/DoubleButton1
@onready var double_button_2 = $AlertBox/DoubleButton2
@onready var animation_player = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	#Disabilita tutte le collisioni
	_disable_all_collisions()
	_set_alert_box()

#Setta l'alert box a seconda dei parametri inseriti tramite l'editor
func _set_alert_box():
	$AlertBox/TitleLabel.text = title
	$AlertBox/TextLabel.text = text
	if alert_box_type == "single_button":
		single_button.get_node("Label3D").text = single_button_button_text
	elif alert_box_type == "double_button":
		double_button_1.get_node("Label3D").text = double_button_first_button_text
		double_button_2.get_node("Label3D").text = double_button_second_button_text

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Aggiorna la trasparenza dello sfondo
	background.get_node("MeshInstance3D").material_override.set_shader_parameter("alpha_multiplier", background_alpha)
	background.get_node("MeshInstance3D").transparency = 1 - background_alpha

#Disabilita tutte le collisioni
func _disable_all_collisions():
	for parent in get_children():
		for i in parent.get_children():
			if i.is_class("CollisionShape3D"):
				i.disabled = true

#Abilita le collisioni di tutti i pulsanti
func _enable_all_collisions():
	for parent in get_children():
		for i in parent.get_children():
			if i.is_class("CollisionShape3D"):
				i.disabled = false

#Abilita le collisioni solo dei pulsanti necessari
func _enable_buttons_collisions():
	for parent in get_children():
		for i in parent.get_children():
			if i.is_class("CollisionShape3D") and (i.is_in_group(alert_box_type) or i.is_in_group("background")):
				i.disabled = false

#Disabilita i pulsanti non necessari a seconda del tipo di alert box selezionato
func _disable_unnecessary_buttons_visibility():
	for parent in get_children():
		for i in parent.get_children():
			if i.is_class("Area3D") and !(i.is_in_group(alert_box_type) or i.is_in_group("background")):
				i.visible = false

#Restituisce la posizione centrale della finestra
func _calculate_box_position():
	# Ottiene la camera
	var camera = get_viewport().get_camera_3d()
	# Ottene la posizione della camera
	var camera_position = camera.global_transform.origin
	# Ottene il vettore d'avanti della telecamera
	var camera_forward = -camera.global_transform.basis.z.normalized()
	# Distanza tra la telecamera e l'oggetto
	var distance_from_camera = 0.5
	# Calcola la posizione dell'oggetto
	var alert_box_position = camera_position + camera_forward * distance_from_camera
	return alert_box_position


func pop_in():
	#Se la camera ha una proiezione ortogonale è necessario ingrandire il box
	if get_viewport().get_camera_3d().projection == 1:
		scale = Vector3(1, 1, 1)
	else:
		scale = Vector3 (0.12, 0.12, 0.12)
	#Posiziona davanti alla camera attiva
	position = _calculate_box_position()
	rotation = get_viewport().get_camera_3d().global_rotation
	
	#Abilita le collisioni a seconda del tipo di Warning
	_enable_buttons_collisions()
	_disable_unnecessary_buttons_visibility()
	
	#Lancia l'animazione
	animation_player.play("pop_in")
	
	pass

func pop_out():
	#Disabilita tutte le collisioni
	_disable_all_collisions()
	
	#Lancia l'animazione
	animation_player.play("pop_out")
	
	pass

func set_end_position():
	position += Vector3(0, 10, 0)
