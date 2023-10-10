extends Node2D
class_name BattleEffect

@export_enum("damage", "healing", "support") var effect_type = "damage"
##OPPONENT: Il target è quello/i riconosciuti dal BattleEffectsActivatorComponent come "opponent"; SELF: Il bersaglio è il lanciatore; STRICKEN: Il bersaglio è comunicato dal nodo padre
@export_enum("opponent", "self", "stricken") var target = "opponent"

@export_group("Damage Settings")
@export var damage_power : int = 0
@export_enum("fire", "water", "grass", "normal") var damage_type = "normal"

@export_group("Healing Settings")
@export var is_healing_percentage : bool = true
@export var heal_hp : int = 0
@export_range(0, 100) var heal_percentage : int = 0

@export_group("Support Variables")
@export var stat_up : bool = true
@export_range(1, 10) var buff_debuff_level : int = 1
@export_enum("atk", "def", "luk") var stat_name = "atk"

#GETTER

func get_effect_type() -> String:
	return effect_type

func get_target() -> String:
	return target

func get_damage_power() -> int:
	return damage_power

func get_damage_type() -> String:
	return damage_type

func get_is_healing_percentage() -> bool:
	return is_healing_percentage

func get_heal_hp() -> int:
	return heal_hp

func get_heal_percentage() -> int:
	return heal_percentage

func get_stat_up() -> bool:
	return stat_up

func get_buff_debuff_level() -> int:
	return buff_debuff_level

func get_stat_name() -> String:
	return stat_name
