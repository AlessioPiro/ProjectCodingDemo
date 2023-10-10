extends Node2D
class_name ButtonComponent2D

#COME FUNZIONA
#1: AL MOMENTO DEL CLICK ATTIVA UN'ANIMAZIONE SUL PULSANTE
#2: SE IL DITO VIENE MOSSO DURANTE IL CLICK O LA PRESSIONE DURA PIÙ DI 5 SECONDI, IL TOCCO VIENE ANNULLATO
#3: SE IL TOCCO È VALIDO, AL RILASCIO VIENE EMESSO UN SEGNALE DIVERSO A SECONDA DELLA TIPOLOGIA DI PULSANTE (DA SPECIFICARE ALL'INTERNO DEL CAMPO "ACTION")
#4: È COMPITO DEL NODO CHE RICEVE IL SEGNALE GESTIRE LE OPERAZIONI SUCCESSIVE


#SEGNALI
	#GENERALI
signal battle_player_launch_move(button : String)



#VARIABILI ESPORTATE
##Nome del pulsante
@export_enum ("no_reaction", "battle_player_launch_move") 
var action : String = "no_reaction"
##Nome dell'animazione da usare al click del pulsante
@export_enum ("no_reaction","pink_press", "darken") var press_animation : String = "no_reaction"
@export_enum ("no_warning") var warning_messagge : String = "no_warning"

#ALTRE VARIABILI

var emitter #Nodo che emette il segnale della pressione (Deve essere un'Area2D)
var sprites = [] #Tutti gli sprite e label che formano il pulsante
var state = "idle" #Stati del pulsante: tapped, disabled, idle
var timer = Timer.new() #Timer per misurare la durata della pressione del pulsante
var max_tap_time = Global.max_tap_time #Importa la durata massima di una pressione prolungata del pulsante per ritenerlo valido (Importato dalle variabili Globali)
var original_sprites_color = []


# Called when the node enters the scene tree for the first time.
func _ready():
	emitter = get_parent()
	
	
	for i in emitter.get_children():
		if i.is_class("Sprite2D") or i.is_class("Label"):
			sprites.append(i)
	emitter.input_event.connect(_on_input_event)
	add_child(timer)
	timer.one_shot = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if timer.time_left == 0 and state == "tapped":
		_invalid_tap()


func _launch_pressed_button_animation():
	original_sprites_color.clear()
	for sprite in sprites:
		original_sprites_color.append(sprite.modulate)
	
	match press_animation:
		"no_reaction":
			pass
		
		"pink_press":
			for sprite in sprites:
				sprite.scale -= Vector3(0.01, 0.01, 0.01)
				sprite.modulate = Color("F8B8D4")
		
		"darken":
			if emitter.find_child("GlowComponent"):
				emitter.get_node("GlowComponent").stop_glow()
			for sprite in sprites:
				sprite.modulate = sprite.modulate.darkened(0.4)


func _launch_released_button_animation():
	match press_animation:
		"no_reaction":
			pass
		
		"pink_press":
			for sprite in sprites:
				sprite.scale += Vector3(0.01, 0.01, 0.01)
				sprite.modulate = Color("WHITE")
		
		"darken":
			if emitter.find_child("GlowComponent"):
				emitter.get_node("GlowComponent").start_glow()
			var counter = 0
			for sprite in sprites:
				sprite.modulate = original_sprites_color[counter]
				counter += 1


func _invalid_tap():
	_launch_released_button_animation()
	state = "idle"

func _button_pressed_successfully():
	state = "idle"
	_choose_signal()
	pass


func _on_input_event(viewport, event, shape_idx):
	if state == "disabled":
		#Lancia il messaggio di warning che ha la key uguale a quella immessa in input nel campo "warning_messagge"
		_launch_warning_message()
		return
	
	if event.is_class("InputEventMouseMotion"):
		if state == "tapped" and event.get_relative() != Vector2(0, 0):
			_invalid_tap()
	
	
	if event.is_class("InputEventMouseButton"):
		if event.is_pressed() and state == "idle":
			_launch_pressed_button_animation()
			state = "tapped"
			timer.start(max_tap_time)
		
		elif !event.pressed:
			if state == "tapped":
				_launch_released_button_animation()
				_button_pressed_successfully()
			else:
				state = "idle"


func _choose_signal():
	match action:
		"no_reaction":
			pass
		"battle_player_launch_move":
			emit_signal("battle_player_launch_move", emitter.get_groups()[0])


func set_disabled():
	#Se il pulsante ha i suoi colori originali, viene scurito per indicare che è disabilitato
	if state == "idle":
		original_sprites_color.clear()
		for sprite in sprites:
			original_sprites_color.append(sprite.modulate)
			sprite.modulate = sprite.modulate.darkened(0.4)
	
	state = "disabled"


func set_enabled():
	state = "idle"
	var counter = 0
	for sprite in sprites:
		sprite.modulate = original_sprites_color[counter]
		counter += 1

#Lancia il messaggio di Warning
func _launch_warning_message():
	pass
