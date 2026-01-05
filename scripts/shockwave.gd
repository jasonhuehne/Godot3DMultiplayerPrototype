extends Area3D

# Adjust these in the Inspector
@export var speed = 15.0
@export var max_radius = 15.0
@export var max_thickness = 1
@export var damage = 10
@export var start_radius = 1  # NEU: Einstellbarer Startradius

# Array to store bodies we've already hit
@export var bodies_hit = []
@export var current_radius = 0.0  # Wird in _ready() auf start_radius gesetzt

@onready var mesh = $MeshInstance3D
@onready var collision = $CollisionShape3D

func _ready():
	# Setze den aktuellen Radius auf den definierten Startwert
	current_radius = start_radius
	
	# Dupliziere die Ressourcen, um sie instanzspezifisch zu machen
	mesh.mesh = mesh.mesh.duplicate()
	collision.shape = collision.shape.duplicate()
	
	# Monitoring muss an sein, um get_overlapping_bodies() nutzen zu können
	self.monitoring = true
	
	# Setze die initiale Größe für Mesh und Collision
	_update_visuals_and_collision()

func _physics_process(delta):
	# Erweitere den Radius
	current_radius += speed * delta
	if current_radius > max_radius:
		queue_free()
		return
	_update_visuals_and_collision()
	
	var current_thickness = mesh.mesh.outer_radius - mesh.mesh.inner_radius
	if is_multiplayer_authority():
		check_for_damage(current_thickness)

func _update_visuals_and_collision():
	# Berechne den Fortschritt von 0.0 bis 1.0
	var progress = current_radius / max_radius
	progress = clamp(progress, 0.0, 1.0) # GEÄNDERT: Klemmung von 0.0 statt 0.1
	
	# "Ease" den Fortschritt (hier: schneller am Anfang, langsamer am Ende)
	var eased_progress = pow(progress, 2.0)
	
	# Dicke nimmt ab, je größer der Radius wird
	var current_thickness = max_thickness * (1.0 - eased_progress)
	
	# WICHTIG: Verhindert, dass der innere Radius < 0 wird
	# Die Dicke kann nicht größer sein als der aktuelle Radius
	current_thickness = min(current_thickness, 1)
	
	# Wende die Radien auf das Mesh (TorusMesh) an
	mesh.mesh.outer_radius = current_radius
	if current_thickness == 0:
		mesh.mesh.inner_radius = current_radius - 0.001
	else: 
		mesh.mesh.inner_radius = current_radius - current_thickness
	# Wende den (äußeren) Radius auf die CollisionShape (SphereShape3D) an
	collision.shape.radius = current_radius

func check_for_damage(thickness):
	# Definiere die "Hit-Zone" als Ring
	var hit_zone_outer = current_radius
	var hit_zone_inner = current_radius - thickness
	
	# Wir ignorieren die Y-Achse für eine 2D-Boden-Schockwelle
	var self_pos_xz = self.global_position * Vector3(1, 0, 1)
	
	# Hole alle Körper, die sich innerhalb des *äußeren* Radius der Area3D befinden
	var overlapping_bodies = get_overlapping_bodies()
	
	for body in overlapping_bodies:
		# Prüfe, ob es ein Spieler ist und wir ihn nicht schon getroffen haben
		if body.is_in_group("player") and not body in bodies_hit:
			var body_pos_xz = body.global_position * Vector3(1, 0, 1)
			var distance = self_pos_xz.distance_to(body_pos_xz)
			var knockback_direction = (body_pos_xz - self_pos_xz).normalized()
			# Prüfe, ob sich der Körper *innerhalb des Rings* befindet
			if distance >= hit_zone_inner and distance <= hit_zone_outer:
				bodies_hit.append(body)
				if body.has_method("take_damage"):
					body.take_damage(damage,  knockback_direction)
