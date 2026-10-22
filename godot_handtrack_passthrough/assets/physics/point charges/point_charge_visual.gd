extends Area3D

@export var start_scale := 0.7
@export var overshoot_scale := 1.1
@export var expand_duration := 0.12
@export var settle_duration := 0.16
@export var pulse_brightness := 0.35
@export var particle_burst_scale := 0.8

var _spawn_tween: Tween
var _material_tween: Tween
var _label_tween: Tween


func play_spawn_animation() -> void:
	var charge_mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if charge_mesh == null:
		return

	_stop_active_tweens()

	var resting_scale := charge_mesh.scale
	charge_mesh.scale = resting_scale * start_scale

	_spawn_tween = create_tween()
	_spawn_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_spawn_tween.tween_property(
		charge_mesh,
		"scale",
		resting_scale * overshoot_scale,
		expand_duration
	)
	_spawn_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_spawn_tween.tween_property(
		charge_mesh,
		"scale",
		resting_scale,
		settle_duration
	)

	_animate_material(charge_mesh)
	_animate_label()
	_play_particle_burst(charge_mesh)


func _animate_material(charge_mesh: MeshInstance3D) -> void:
	var material := charge_mesh.material_override as StandardMaterial3D
	if material == null:
		material = charge_mesh.get_active_material(0) as StandardMaterial3D
	if material == null:
		return

	var resting_color := material.albedo_color
	var pulse_color := resting_color.lightened(pulse_brightness)
	var emission_was_enabled := material.emission_enabled
	var resting_emission := material.emission
	var resting_emission_energy := material.emission_energy_multiplier

	material.emission_enabled = true
	material.emission = pulse_color
	material.emission_energy_multiplier = maxf(resting_emission_energy, 2.0)

	_material_tween = create_tween()
	_material_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_material_tween.tween_property(material, "albedo_color", pulse_color, 0.08)
	_material_tween.tween_property(
		material,
		"albedo_color",
		resting_color,
		expand_duration + settle_duration - 0.08
	)
	_material_tween.tween_callback(
		_restore_material.bind(
			material,
			emission_was_enabled,
			resting_emission,
			resting_emission_energy
		)
	)


func _animate_label() -> void:
	var label := get_node_or_null("ChargeLabel") as Label3D
	if label == null:
		return

	var resting_modulate := label.modulate
	var hidden_modulate := resting_modulate
	var label_start_scale := label.scale
	hidden_modulate.a = 0.0
	label.modulate = hidden_modulate
	label.scale = label_start_scale * 0.8

	_label_tween = create_tween()
	_label_tween.set_parallel(true)
	_label_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_label_tween.tween_property(
		label,
		"modulate",
		resting_modulate,
		expand_duration + settle_duration
	)
	_label_tween.tween_property(
		label,
		"scale",
		label_start_scale,
		expand_duration + settle_duration
	)


func _play_particle_burst(charge_mesh: MeshInstance3D) -> void:
	var particles := charge_mesh.get_node_or_null("GPUParticles3D") as GPUParticles3D
	if particles == null:
		return

	particles.one_shot = true
	particles.scale = Vector3.ONE * particle_burst_scale
	particles.visible = true
	particles.restart()
	particles.emitting = true
	_hide_particles_after_burst(particles)


func _hide_particles_after_burst(particles: GPUParticles3D) -> void:
	await get_tree().create_timer(particles.lifetime + 0.05).timeout
	if is_instance_valid(particles):
		particles.emitting = false
		particles.visible = false


func _restore_material(
	material: StandardMaterial3D,
	emission_was_enabled: bool,
	resting_emission: Color,
	resting_emission_energy: float
) -> void:
	if material == null:
		return
	material.emission_enabled = emission_was_enabled
	material.emission = resting_emission
	material.emission_energy_multiplier = resting_emission_energy


func _stop_active_tweens() -> void:
	for tween in [_spawn_tween, _material_tween, _label_tween]:
		if tween and tween.is_valid():
			tween.kill()
