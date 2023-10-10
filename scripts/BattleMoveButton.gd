extends Area2D

@onready var text = $Text
@onready var progress_bar = $ProgressBar
@onready var button_component = $ButtonComponent2D
@onready var timer = $Timer

var reload_time = 0

var state : String = "disabled"
#STATE MACHINE:
# -on_loading: Il pulsante sta caricando. Non può essere premuto mentre il timer di ricarica è attivo
# -ready: Il timer è scaduto e il pulsante può essere premuto
# -disabled: Il pulsante è disabilitato e il timer è fermo. Utile durante cutscene o simili
# -no_effect: Se la mossa non ha alcun effetto per come è attualmente settata, il pulsante viene disabilitato

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == "on_loading":
		_update_progress_bar()


func inizialize_button(input_reload_time : int, has_no_effect : bool):
	text.modulate = Color("WHITE")
	progress_bar.set_progress_bar_value(0)
	reload_time = input_reload_time
	
	if has_no_effect:
		set_state("no_effect")
	else:
		set_state("disabled")

func set_state(new_state : String):
	if state == "no_effect" or state == "new_state":
		return
	
	if new_state == "disabled":
		text.modulate = Color("WHITE")
		state == "disabled"
		button_component.set_disabled()
		progress_bar.set_progress_bar_value(0)
		timer.stop()
	
	elif new_state == "on_loading":
		text.modulate = Color("WHITE")
		#Setta lo stato on_loading
		state = "on_loading"
		#Fai partire il timer
		timer.start(reload_time)
		button_component.set_disabled()
	
	elif new_state == "no_effect":
		text.modulate = Color("WHITE")
		state = "no_effect"
		button_component.set_disabled()
		progress_bar.set_progress_bar_value(0)
		timer.stop()
	
	elif new_state == "ready":
		state = "ready"


func _update_progress_bar():
	#Ottieni il tempo dal timer
	var time_left = timer.time_left
	#Calcola la percentuale di completamento
	var time_percentage = (reload_time - time_left) / reload_time * 100
	#Aggiorna il valore della progress bar
	progress_bar.set_progress_bar_value(time_percentage)

func activate_button():
	set_state("ready")
	button_component.set_enabled()
	#Attiva l'animazione per la mossa pronta
	text.modulate = Color("#ffff00")

func _on_timer_timeout():
	activate_button()


