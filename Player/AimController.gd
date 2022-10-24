class_name GrenadeAimController
extends Node3D

const GRENADE_SCENE = preload("res://Player/Grenade.tscn")
const SURFACE_AIM_COLOR = Color(1, 1, 1, 0.5)
const ENEMY_AIM_COLOR = Color(1, 0, 0, 0.5)

@export var min_throw_radius := 1.0
@export var max_throw_radius := 20.0

@onready var _aim_sprite: MeshInstance3D = $AimSprite
@onready var _grenade_path: Path3D = $Path3D
@onready var _csg_polygon: CSGPolygon3D = $Path3D/CSGPolygon3D


func _physics_process(delta: float) -> void:
	if visible:
		_aim_sprite.rotate_y(PI * delta)


func set_active(active: bool) -> void:
	visible = active


func throw_grenade(origin: Vector3, player: Node3D) -> bool:
	if not visible or not _aim_sprite.visible:
		return false
	
	var grenade = GRENADE_SCENE.instantiate()
	get_parent().add_child(grenade)
	grenade.transform = _grenade_path.transform
#	grenade.position += _grenade_path.curve.get_point_position(0)
	grenade.throw(_grenade_path.curve.duplicate(), player)
	
	return true


func set_aim_position(origin: Vector3, target: Vector3, normal: Vector3, camera_basis: Basis, collider: Object) -> void:
	var xz_distance := Vector3(target.x, 0.0, target.z)
	xz_distance -= Vector3(origin.x, 0.0, origin.z)
	var max_radius := xz_distance.normalized() * max_throw_radius
	
	if collider == null or xz_distance.length() > max_radius.length():
		_aim_sprite.hide()
		_csg_polygon.hide()
		return

	_aim_sprite.show()
	_csg_polygon.show()
	
	var trans = transform
	
	if collider is Node and collider.is_in_group("targeteables"):
		normal = (origin - collider.global_position).normalized()
		trans.origin = collider.global_position + normal
	else:
		var min_radius := xz_distance.normalized() * min_throw_radius
		if xz_distance.length() < min_radius.length():
			xz_distance = min_radius
		
		var height_vector := (target - origin) * Vector3.UP
		trans.origin = origin + xz_distance + height_vector + (normal * 0.1)
	
	trans.basis.y = normal
	trans.basis.z = -camera_basis.y
	trans.basis.x = trans.basis.z.cross(trans.basis.y).normalized()
	trans.basis.z = trans.basis.y.cross(trans.basis.x).normalized()
	trans.basis = trans.basis.orthonormalized()
	transform = trans
	
	_grenade_path.global_position = origin
	_grenade_path.look_at(trans.origin)
	var path_end_point: Vector3 = _grenade_path.transform.inverse() * trans.origin
	_grenade_path.curve.set_point_position(1, path_end_point)

