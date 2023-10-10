extends Node2D
class_name PlayerMovementComponent

#NECESSITA DI: InputComponent (collegare i segnali)

@onready var character = get_parent()

#Variabili di movimento
@export var motion_speed : float = 16 #Velcotà del movimento sull'asse x
@export var distance_x : float = 1.0 #Distanza coperta da un movimento sull'asse x
@export var distance_y : float = 1.0 #Distanza coperta da un movimento sull'asse y
@export var limit_x : float = 1.0 #Limite del movimento sull'asse x (1, -1) dopo il quale non si può andare
@export var limit_max_y : float = 2.5  #Altezza massima raggiungibile dal personaggio
@export var limit_min_y : float = 0 #Altezza minima raggiungibile dal personaggio (quando è considerato sul pavimento)
@export var starting_pos = Vector3 (0, 0, 3.25) #Posizione in cui spawna il personaggio

var state: String = "on_floor" #Stato del personaggio (on_floor di default)


#Variabili di salto
@export var jump_force : float = 6.0 #Velocità del salto
@export var jump_slow_down_time : float = 0.8 #Momento del salto (da 0 a 1) in cui il movimento viene rallentato
@export var jump_slower : float = 10 #Forza del rallentamento del salto nella fase finale
@export var double_jump_slow_down_time : float = 0.8 #Momento del doppio salto (da 0 a 1) in cui il movimento viene rallentato
@export var double_jump_slower : float = 10 #Forza del rallentamento del doppio salto nella fase finale

var can_jump = true #Se vera, il personaggio può effettuare salti (disattivata in caso di doppio salto fino a quando non si tocca terra)

#Variabili di caduta
@export var gravity : float = 6.0 #Velocità di discesa
@export var fall_slower : float = 3 #Di quanto rallenta la caduta prima di un dato momento
@export var time_fall_slow_down : float = 0.6 #Quando la caduta (da 1 a 0) deve riprendere velocità
@export var timer_fall_divider: float = 5.0 #Valore per la quale viene diviso il timer_fall

var timer_fall : float = 0.0 #Timer che serve per far prendere velocità alla caduta

#Variabile di schianto a terra
@export var ground_pound_speed : float = 20 #Velocità dello schianto a terra 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	#Movimento a sinistra
	if state == "move_left":
		_move_x("left", delta)
		
		
		#Quando il movimento è finito
		if character.global_position.x < -limit_x or (starting_pos.x - character.global_position.x) >= distance_x:
			_end_move_x_left()
	
	#Movimento a destra
	if state == "move_right":
		_move_x("right", delta)
		
		#Quando il movimento è finito
		if character.global_position.x > limit_x or (starting_pos.x - character.global_position.x) <= -distance_x:
			_end_move_x_right()
	
	#Salto
	if state == "jump":
		
		#Vicino al picco del salto rallenta
		if character.global_position.y - starting_pos.y > jump_slow_down_time:
			_jump(delta/jump_slower)
		else:
			_jump(delta)
		
		#Nel momento più alto del salto
		if character.global_position.y > limit_max_y or (character.global_position.y - starting_pos.y) >= distance_y:
			_end_jump()
	
	#Caduta
	if state == "falling":
		
		#All'inizio cade più lentamente
		if character.global_position.y - starting_pos.y > time_fall_slow_down:
			_fall(delta/fall_slower)
		else:
			_fall(delta)
		
		#Quando tocca terra
		if character.global_position.y < limit_min_y:
			_end_fall()
	
	#Doppio salto
	if state == "double_jump":
		can_jump = false
		
		#Vicino al picco del salto rallenta
		if character.global_position.y - starting_pos.y > double_jump_slow_down_time:
			_jump(delta/double_jump_slower)
		else:
			_jump(delta)
		
		#Nel momento più alto del salto
		if character.global_position.y > limit_max_y or (character.global_position.y - starting_pos.y) >= distance_y:
			_end_jump()
	
	#Schianto a terra
	if state == "ground_pound":
		_ground_pound(delta)
		
		#Nel momento dello schianto
		if character.global_position.y < limit_min_y:
			_end_ground_pound()
	
	#print(state)


#Movimento del personaggio sull'asse x
func _move_x(direction, delta):
	var d = delta * motion_speed 
	if direction == "left":
		character.global_position.x -= (d * distance_x)
	elif direction == "right":
		character.global_position.x += (d * distance_x)


#FINE: Movimento a sinistra del personaggio sull'asse x
func _end_move_x_left():
	character.global_position.x = starting_pos.x - distance_x
	starting_pos = character.global_position
	if character.global_position.y == limit_min_y:
		state = "on_floor"
	else: 
		state = "falling"


#FINE: Movimento a destra del personaggio sull'asse x
func _end_move_x_right():
	character.global_position.x = starting_pos.x + distance_x
	starting_pos = character.global_position
	if character.global_position.y == limit_min_y:
		state = "on_floor"
	else: 
		state = "falling"


#Salto
func _jump(delta):
	var d = delta * jump_force
	character.global_position.y += (d * distance_y)


#FINE: Salto
func _end_jump():
	character.global_position.y = starting_pos.y + distance_y
	starting_pos = character.global_position
	state = "falling"


#Caduta
func _fall(delta):
	timer_fall += delta/timer_fall_divider
	var d = delta * gravity + timer_fall
	character.global_position.y -= (d * distance_y)


#FINE: Caduta
func _end_fall():
	character.global_position.y = limit_min_y
	starting_pos = character.global_position
	state = "on_ground"
	can_jump = true
	timer_fall = 0


#Schianto a terra
func _ground_pound(delta):
	var d = delta * ground_pound_speed
	character.global_position.y -= (d * distance_y)


#FINE: Schianto a terra
func _end_ground_pound():
	character.global_position.y = limit_min_y
	starting_pos = character.global_position
	state = "on_ground"
	can_jump = true
	timer_fall = 0


#Gestione degli input dei movimenti
func _on_input_component_swipe(direction, swipe_difference, swipe_time):
	#Gestione input movimento a sinistra
	if direction == "left" and (character.global_position.x > -limit_x):
		state = "move_left"
	
	#Gestione input movimento a destra
	elif direction == "right" and (character.global_position.x < limit_x):
		state = "move_right"
		
	#Gestione dell'input del salto
	elif direction == "up":
		if (state == "jump" or state == "falling") and can_jump:
			starting_pos = character.global_position
			state = "double_jump"
		elif state == "double_jump":
			pass
		elif can_jump:
			state = "jump"
	
	#Gestione input schianto a terra
	elif direction == "down" and (state == "falling" or state == "jump" or state == "double_jump"):
		state = "ground_pound"


func _on_input_component_tap(tap_position):
	pass
