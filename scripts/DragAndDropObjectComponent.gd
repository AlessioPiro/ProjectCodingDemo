extends Node3D
class_name DragAndDropComponent

#COME FUNZIONA
#1: AL MOMENTO DEL CLICK ATTIVA UN'ANIMAZIONE SUL PULSANTE
#2: SE IL DITO VIENE MOSSO DURANTE IL CLICK, QUESTO COMPONENT PASSA ALLO STATO "DRAGGED", VIENE LANCIATA L'ANIMAZIONE DEL DRAG E IL SEGNALE "drag_and_drop_object_on_drag" CONTENENTE L'OGGETTO E IL TARGET DI PARTENZA
#3: LA POSIZIONE DELL'OGGETTO SARÀ UGUALE A QUELLA DEL DITO FINCHÈ IL TOCCO NON TERMINERÀ
#4: AL RILASCIO VENGONO VERIFICATE LE COLLISIONI:
	#SE L'OGGETTO È IN COLLISIONE CON UN SOLO OGGETTO CHE POSSIEDE UN "DragAndDropTargetComponent" VIENE LANCIATO UN SEGNALE "dropped_drag_and_drop_object" CHE CONTIENE L'OGGETTO E UN ARRAY CONTENENTE SOLO IL TARGET
	#SE L'OGGETTO È IN COLLISIONE CON PIÙ DI UN OGGETTO CHE POSSIEDE UN  "DragAndDropTargetComponent" VIENE LANCIATO UN SEGNALE "dropped_drag_and_drop_object" CHE CONTIENE L'OGGETTO E UN ARRAY CONTENENTE TUTTI I TARGET
	#SE L'OGGETTO NON È IN COLLISIONE CON ALCUN OGGETTO "DragAndDropTargetComponent" VIENE LANCIATO UN SEGNALE "dropped_drag_and_drop_object" CHE CONTIENE L'OGGETTO E UN ARRAY VUOTO



#SEGNALI
signal on_drag_drag_and_drop_object (object : Area3D, overlapping_targets : Array)
signal on_drop_drag_and_drop_object (object : Area3D, overlapping_targets : Array)
signal on_button_pressed_drag_and_drop_object (object : Area3D)


#VARIABILI ESPORTATE
@export_enum ("no_reaction","darken") var press_animation : String = "no_reaction"
@export_enum ("no_reaction","enlarge", "enlarge_and_glow") var drag_animation : String = "no_reaction"
@export_enum ("no_warning") var warning_messagge : String = "no_warning"
@export_enum ("x","y","z") var blocked_axis : String = "z" 
#Le animazioni avranno effetto anche sui nodi figli dell'emitter
@export var animation_affects_children : bool = false

#ALTRE VARIABILI

var emitter #Nodo che emette il segnale della pressione (Deve essere un'Area3D)
var sprites = [] #Tutti gli sprite e label che formano il pulsante
var original_sprites_color = [] #I colori originali degli sprite dell'oggetto

var overlapping_targets = []


var state = "" #Stati dell'oggetto drag_and_drop: idle, tapped, disable, dragged
	#STATE MACHINE: 
		#da idle: tapped, disabled
		#da tapped: idle, dragged
		#da dragged: idle
		#da disable: idle



# Called when the node enters the scene tree for the first time.
func _ready():
	emitter = get_parent()
	
	if animation_affects_children:
		_create_sprite_array_with_children(emitter.get_children())
	else:
		_create_sprites_array()
	
	emitter.input_event.connect(_on_input_event)
	
	state = "idle"
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _create_sprites_array():
	for i in emitter.get_children():
		if i.is_class("Sprite3D") or i.is_class("Label3D"):
			sprites.append(i)

func _create_sprite_array_with_children(array : Array):
	for i in array:
		if i.get_child_count() != 0:
			_create_sprite_array_with_children(i.get_children())
		elif i.is_class("Sprite3D") or i.is_class("Label3D"):
			sprites.append(i)


func _launch_pressed_object_animation():
	for sprite in sprites:
		original_sprites_color.append(sprite.modulate)
	
	match press_animation:
		"no_reaction":
			pass
		
		"darken":
			if emitter.find_child("GlowComponent"):
				emitter.get_node("GlowComponent").stop_glow()
			for sprite in sprites:
				sprite.modulate = sprite.modulate.darkened(0.5)


func _launch_pressed_object_end_animation():
	match press_animation:
		"no_reaction":
			pass
		
		"darken":
			if emitter.find_child("GlowComponent"):
				emitter.get_node("GlowComponent").start_glow()
			var counter = 0
			for sprite in sprites:
				sprite.modulate = original_sprites_color[counter]
				counter += 1
	
	original_sprites_color.clear()


func _launch_dragged_object_animation():
	for sprite in sprites:
		original_sprites_color.append(sprite.modulate)
	
	
	
	_increase_sprites_render_priority()
	
	match drag_animation:
		"no_reaction":
			pass
		
		"enlarge":
			emitter.scale += Vector3(0.1, 0.1, 0.1)
		
		"enlarge_and_glow":
			emitter.scale += Vector3(0.1, 0.1, 0.1)
			if emitter.find_child("GlowComponent"):
				emitter.get_node("GlowComponent").start_glow()


func _launch_dropped_object_animation():
	_decrease_sprites_render_priority()
	
	match drag_animation:
		"no_reaction":
			pass
		
		"enlarge":
			emitter.scale -= Vector3(0.1, 0.1, 0.1)
		
		"enlarge_and_glow":
			emitter.scale -= Vector3(0.1, 0.1, 0.1)
			if emitter.find_child("GlowComponent"):
				emitter.get_node("GlowComponent").stop_glow()
	
	original_sprites_color.clear()


#Gestione dell'input
func _on_input_event(camera, event, position, normal, shape_idx):
	#Se disabilitato
	if state == "disabled":
		#Lancia il messaggio di warning che ha la key uguale a quella immessa in input nel campo "warning_messagge"
		_launch_warning_message()
		return
	
	
	if event.is_class("InputEventMouseButton"):
		#Pressione dell'oggetto
		if event.is_pressed() and state == "idle":
			_launch_pressed_object_animation()
			state = "tapped"
		
		#Rilascio dell'oggetto
		elif !event.pressed:
			if state == "tapped":
				_launch_pressed_object_end_animation()
				emit_signal("on_button_pressed_drag_and_drop_object", emitter)
				state = "idle"
			elif state == "dragged":
				#Verifica la collisione e lancia il segnale di conseguenza
				state = "idle"
				_launch_dropped_object_animation()
				overlapping_targets = emitter.get_overlapping_areas()
				emit_signal("on_drop_drag_and_drop_object", emitter, overlapping_targets)
			else:
				state = "idle"

	if event.is_class("InputEventMouseMotion"):
		if state == "tapped" and event.get_relative() != Vector2(0, 0):
			#Si passa a dragged
			state = "dragged"
			_launch_pressed_object_end_animation()
			_launch_dragged_object_animation()
			
			var overlapping_target_by_method = emitter.get_overlapping_areas()
			for area in overlapping_target_by_method:
				if !area.has_node("DragAndDropTargetComponent"):
					overlapping_target_by_method.erase(area)
			
			#Sposta l'oggetto nella posizione del dito
			_update_object_position_on_finger_movement(event)
			
			emit_signal("on_drag_drag_and_drop_object", emitter, overlapping_target_by_method)
			
			
		
		elif state == "dragged" and event.get_relative() != Vector2(0, 0):
			_update_object_position_on_finger_movement(event)


func _update_object_position_on_finger_movement(event : InputEventMouseMotion):
	var camera = get_viewport().get_camera_3d()
	if camera.projection == 0:
		var touch_position = camera.project_ray_normal(event.position)
		emitter.position = Vector3(touch_position.x, touch_position.y, emitter.position.z) #* abs(get_viewport().get_camera_3d().project_ray_origin(event.position).z - touch_position.z) * touch_position.length()
	elif camera.projection == 1:
		var touch_position = camera.project_ray_origin(event.position) + camera.project_ray_normal(event.position)
		
		match blocked_axis:
			"x":
				touch_position = Vector3(emitter.global_position.x, touch_position.y, touch_position.z)
			"y":
				touch_position = Vector3(touch_position.x, emitter.global_position.y, touch_position.z)
			"z":
				touch_position = Vector3(touch_position.x, touch_position.y, emitter.global_position.z)
		
		#emitter.position = touch_position - emitter.get_parent().global_position
		emitter.global_position = touch_position



func _increase_sprites_render_priority():
	for sprite in sprites:
		sprite.render_priority += 1
	if emitter.find_child("GlowComponent"):
		emitter.get_node("GlowComponent").update_render_priority(emitter.get_node("GlowComponent").render_priority + 1)

func _decrease_sprites_render_priority():
	for sprite in sprites:
		sprite.render_priority -= 1
	if emitter.find_child("GlowComponent"):
		emitter.get_node("GlowComponent").update_render_priority(emitter.get_node("GlowComponent").render_priority - 1)

func set_disabled():
	state = "disabled"

func set_enabled():
	state = "idle"

func is_enabled():
	return !(state == "disabled")

func force_drag():
	state = "dragged"
	_launch_dragged_object_animation()

func force_drop():
	if state == "dragged":
		state = "idle"
		_launch_dropped_object_animation()

func reset():
	state = "idle"

#Lancia il messaggio di Warning
func _launch_warning_message():
	pass

