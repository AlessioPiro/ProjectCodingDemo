extends Node3D
class_name ButtonComponent

#COME FUNZIONA
#1: AL MOMENTO DEL CLICK ATTIVA UN'ANIMAZIONE SUL PULSANTE
#2: SE IL DITO VIENE MOSSO DURANTE IL CLICK O LA PRESSIONE DURA PIÙ DI 5 SECONDI, IL TOCCO VIENE ANNULLATO
#3: SE IL TOCCO È VALIDO, AL RILASCIO VIENE EMESSO UN SEGNALE DIVERSO A SECONDA DELLA TIPOLOGIA DI PULSANTE (DA SPECIFICARE ALL'INTERNO DEL CAMPO "ACTION")
#4: È COMPITO DEL NODO CHE RICEVE IL SEGNALE GESTIRE LE OPERAZIONI SUCCESSIVE


#SEGNALI
	#GENERALI
signal launch_alert_box (name : String)
signal change_scene_to_menu (from_scene : String, progress : bool)
signal cancel_alert_box (name : String)
signal pop_out_window (window : Node)

signal remove_player_object (object_id : String, object_type: String)

	#LUNAS
#Avvisa che è necessario cambiare menu passando da menu1 a menu2
signal lunas_change_menu(menu1 : String, menu2 : String)
signal lunas_change_menu_to_pc2(method : String)
signal lunas_product_click(index : int)
signal lunas_shop_buy_click()
signal lunas_rest_click()
signal lunas_change_page_in_object_window_in_pc2_menu(is_next : bool) 
signal lunas_change_object_type_in_object_window_in_pc2_menu(to_type : String)


#VARIABILI ESPORTATE

##Nome del pulsante
@export_enum ("launch_alert_box","change_scene_to_menu","cancel_alert_box","no_reaction","lunas_change_menu", 
"lunas_product_click", "lunas_shop_buy_click", "lunas_rest_click", "remove_player_object", "pop_out_window", "lunas_change_menu_to_pc2", "lunas_change_page_in_object_window_in_pc2_menu", "lunas_change_object_type_in_object_window_in_pc2_menu") 
var action : String = "no_reaction"
##Nome dell'animazione da usare al click del pulsante
@export_enum ("no_reaction","pink_press", "exit_sign_press", "darken") var press_animation : String = "no_reaction"
@export_enum ("no_warning") var warning_messagge : String = "no_warning"

	# VARIABILI ESPORTATE PER IL CAMBIO DELLA SCENA
##Raccolta di informazioni necessarie al cambio della scena
@export_group("Change Scene Properties")
##Indica la scena di arrivo
@export_enum ("lunas", "battle", "unknown", "main_menu") var from_scene : String
##Indica se si può procedere al prossimo nodo nel menù
@export var map_progress : bool = true

	# VARIABILI ESPORTATE PER L'USO DI UN ALERT BOX
##Raccolta di informazioni necessarie al cambio della scena
@export_group("Alert Box Properties")
##Indica la scena di arrivo
@export var alert_box_name : String

	# VARIABILI ESPORTATE PER IL CAMBIO DEL MENU DEL LUNA'S

##Raccolta di informazioni necessarie al cambio di menu all'interno del Luna's
@export_group("Lunas Change Menu Button Properties")
##Indica il menu di partenza
@export_enum ("main_menu", "shop_menu", "bench_menu", "pc1_menu", "pc2_menu") var from_menu : String
##Indica il menu di arrivo
@export_enum ("main_menu", "shop_menu", "bench_menu", "pc1_menu", "pc2_menu") var to_menu : String

# VARIABILI ESPORTATE PER IL CAMBIO DEL MENU DEL LUNA'S IN PC2

##Raccolta di informazioni necessarie al cambio di menu all'interno del Luna's
@export_group("Lunas Change Menu In PC2 Button Properties")
@export_enum ("constructor", "move1", "move2") var pc2_method : String


	#VARIABILI PER LA RIMOZIONE DI UN OGGETTO (PACCHETTO O PEZZO DI CODICE) TRA QUELLI DEL GIOCATORE. I DATI DEVONO ESSERE PASSATI A RUNTIME

var object_id : String
var object_type : String

	#VARIABILI ESPORTATE PER IL POP_OUT DI UNA FINESTRA. (LA FINESTRA DEVE AVERE UN METODO "pop_out")

@export_group("Window Pop Out")
@export var pop_out_window_node : Node3D


# VARIABILI ESPORTATE PER IL CAMBIO DEL TIPO DI OGGETTO PER LA FINESTRA NEL MENU PC2

@export_group("Lunas Change Window Type In PC2 Menu")
##Indica il nuovo tipo della finestra
@export_enum ("classes", "code_pieces") var pc2_window_to_type : String

# VARIABILI ESPORTATE PER CAMBIARE LA PAGINA DELLA FINESTRA DEGLI OGGETTI NEL MENU PC2

@export_group("Lunas Change Window Page In PC2 Menu")
##Indica se passare alla pagina successiva (true) o alla precedente (false)
@export var pc2_menu_is_next : bool

#ALTRE VARIABILI

var emitter #Nodo che emette il segnale della pressione (Deve essere un'Area3D)
var sprites = [] #Tutti gli sprite e label che formano il pulsante
var state = "idle" #Stati del pulsante: tapped, disabled, idle
var timer = Timer.new() #Timer per misurare la durata della pressione del pulsante
var max_tap_time = Global.max_tap_time #Importa la durata massima di una pressione prolungata del pulsante per ritenerlo valido (Importato dalle variabili Globali)
var original_sprites_color = []


# Called when the node enters the scene tree for the first time.
func _ready():
	emitter = get_parent()
	
	
	for i in emitter.get_children():
		if i.is_class("Sprite3D") or i.is_class("Label3D"):
			sprites.append(i)
	emitter.input_event.connect(_on_input_event)
	add_child(timer)
	timer.one_shot = true
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if timer.time_left == 0 and state == "tapped":
		_invalid_tap()


func _launch_pressed_button_animation():
	for sprite in sprites:
		original_sprites_color.append(sprite.modulate)
	
	match press_animation:
		"no_reaction":
			pass
		
		"pink_press":
			for sprite in sprites:
				sprite.scale -= Vector3(0.01, 0.01, 0.01)
				sprite.modulate = Color("F8B8D4")
		
		"exit_sign_press":
			var anim_player = emitter.get_node("AnimationPlayer")
			anim_player.play("ExitPressedIn")
		
		"darken":
			if emitter.find_child("GlowComponent"):
				emitter.get_node("GlowComponent").stop_glow()
			for sprite in sprites:
				sprite.modulate = Color("#7a7a7a")


func _launch_released_button_animation():
	match press_animation:
		"no_reaction":
			pass
		
		"pink_press":
			for sprite in sprites:
				sprite.scale += Vector3(0.01, 0.01, 0.01)
				sprite.modulate = Color("WHITE")
		
		"exit_sign_press":
			var anim_player = emitter.get_node("AnimationPlayer")
			anim_player.play("ExitPressedOut")
		
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


func _on_input_event(camera, event, position, normal, shape_idx):
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
		"lunas_change_menu":
			emit_signal("lunas_change_menu", from_menu, to_menu)
		"lunas_change_menu_to_pc2":
			emit_signal("lunas_change_menu_to_pc2", pc2_method)
		"lunas_product_click":
			var index = emitter.index
			emit_signal("lunas_product_click", index)
		"lunas_shop_buy_click":
			emit_signal("lunas_shop_buy_click")
		"lunas_rest_click":
			emit_signal("lunas_rest_click")
		"lunas_change_page_in_object_window_in_pc2_menu":
			emit_signal("lunas_change_page_in_object_window_in_pc2_menu", pc2_menu_is_next)
		"lunas_change_object_type_in_object_window_in_pc2_menu":
			emit_signal("lunas_change_object_type_in_object_window_in_pc2_menu", pc2_window_to_type)
		"launch_alert_box":
			emit_signal("launch_alert_box", alert_box_name)
		"change_scene_to_menu":
			emit_signal("change_scene_to_menu", from_scene, map_progress)
		"cancel_alert_box":
			emit_signal("cancel_alert_box", alert_box_name)
		"remove_player_object":
			emit_signal("remove_player_object", object_id, object_type)
		"pop_out_window":
			emit_signal("pop_out_window", pop_out_window_node)
		"no_reaction":
			pass


func set_disabled():
	state = "disabled"


func set_enabled():
	state = "idle"

#Lancia il messaggio di Warning
func _launch_warning_message():
	pass
