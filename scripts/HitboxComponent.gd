extends Area3D
class_name HitboxComponent

signal hit(body)

@onready var character : CharacterBody3D = get_parent()
@export var health_component : HealthComponent 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass

#NO! IL PERSONAGGIO HA DELLE STATISTICHE
func _on_body_entered(body):
	if !(character.get_groups()[0] == body.get_groups()[0]):
		if body.heal != 0:
			health_component.heal(body.heal)
		if body.damage != 0:
			health_component.damage(body.damage)
