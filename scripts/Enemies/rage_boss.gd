extends Node3D

func _ready() -> void:
	# Play animation
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("aura")
	
	if has_node("aura"):
		var aura = get_node("aura")
		aura.emitting = true
		aura.one_shot = false
	
	if has_node("aura2"):
		var aura2 = get_node("aura2")
		aura2.emitting = true
		aura2.one_shot = false
	
	print("[rage_boss] VFX initialized and emitting")
