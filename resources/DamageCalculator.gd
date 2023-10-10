extends Resource
class_name DamageCalculator

var super_effective_multiplier = 2
var not_effective_multiplier = 0.5

var base_crit_probability = 8 #%
var crit_multiplier_value = 1.5

var rng_multiplier_min = 0.85
var rng_multiplier_max = 1

var stab_multiplier_value = 1.5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#Restituisce un dizionario contenente il danno, se è stato un crit, se è stato un attacco superefficace o poco efficace
func calculate_damage(attacker_stats : Dictionary, attacker_type : String, defenser_stats : Dictionary, defenser_type : String, attack_power : int, attack_type : String) -> Dictionary:
	var attacker_atk = attacker_stats.get("atk")
	var attacker_luk = attacker_stats.get("luk")
	var defenser_def = defenser_stats.get("def")
	var defenser_luk = defenser_stats.get("luk")
	
	var type_multiplier = _calculate_type_multiplier(defenser_type, attack_type)
	var crit_multiplier = _calculate_crit_multiplier(attacker_luk, defenser_luk)
	var rng_multiplier = _calculate_rng_multiplier()
	var stab_multiplier = _calculate_stab_multiplier(attacker_type, attack_type)
	
	var damage = (((((2 * attacker_atk)/5) * attack_power * (attacker_atk/defenser_def)) / 50) + 2) * type_multiplier * crit_multiplier * rng_multiplier * stab_multiplier
	
	var damage_data = {}
	damage_data["damage"] = damage
	damage_data["is_super_effective"] = type_multiplier == super_effective_multiplier
	damage_data["is_not_effective"] = type_multiplier == not_effective_multiplier
	damage_data["is_crit"] = crit_multiplier == crit_multiplier_value
	
	return damage_data


func _calculate_type_multiplier(defenser_type : String, attack_type : String):
	var type_multiplier = 1
	
	if (attack_type == "fire" and defenser_type == "grass") or (attack_type == "grass" and defenser_type == "water") or (attack_type == "water" and defenser_type == "fire"):
		type_multiplier = super_effective_multiplier
	elif (attack_type == "grass" and defenser_type == "fire") or (attack_type == "water" and defenser_type == "grass") or (attack_type == "fire" and defenser_type == "water"):
		type_multiplier = not_effective_multiplier
	
	return type_multiplier


func _calculate_crit_multiplier(attacker_luk : int, defenser_luk : int):
	var probability = base_crit_probability * (attacker_luk/defenser_luk)
	var rng = RandomNumberGenerator.new()
	var is_crit = rng.randi_range(1, 100) < probability
	
	var multiplier = 1
	if is_crit:
		multiplier = crit_multiplier_value
	
	return multiplier


func _calculate_rng_multiplier():
	var rng = RandomNumberGenerator.new()
	var multiplier = round(rng.randf_range(rng_multiplier_min, rng_multiplier_max) * 100) / 100
	return multiplier


func _calculate_stab_multiplier(attacker_type, attack_type):
	var multiplier = 1
	if attacker_type == attack_type:
		multiplier = stab_multiplier_value
	
	return multiplier
