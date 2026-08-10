extends CharacterBody2D

@export var speed := 32.0
@export var jump_velocity := 90.0
@export var gravity := 280.0
@export var tilemap_path: NodePath = ^"../TileMapLayer"

const SURFACE_TILE_ATLAS_X := [1, 2]

var _tilemap: TileMapLayer
var _jump_offset := 0.0
var _vertical_velocity := 0.0
var _is_jumping := false
var _on_elevated_surface := false
var _sprite: Sprite2D
var _collision_shape: CollisionShape2D
var _base_sprite_y := -7.0


func _ready() -> void:
	_tilemap = get_node_or_null(tilemap_path) as TileMapLayer
	_sprite = $Player as Sprite2D
	_collision_shape = $CollisionShape2D
	if _sprite:
		_base_sprite_y = _sprite.position.y


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed if direction != Vector2.ZERO else Vector2.ZERO

	_handle_jump(delta)
	collision_mask = 0 if _is_jumping or _on_elevated_surface else 1

	move_and_slide()

	if not _is_jumping:
		_update_surface_state()


func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and not _is_jumping:
		_vertical_velocity = jump_velocity
		_is_jumping = true

	if not _is_jumping:
		return

	_vertical_velocity -= gravity * delta
	_jump_offset += _vertical_velocity * delta

	if _jump_offset <= 0.0:
		_jump_offset = 0.0
		_vertical_velocity = 0.0
		_is_jumping = false

	_apply_jump_offset()


func _apply_jump_offset() -> void:
	var visual_offset := -_jump_offset
	if _sprite:
		_sprite.position.y = _base_sprite_y + visual_offset
	if _collision_shape:
		_collision_shape.position.y = visual_offset


func _update_surface_state() -> void:
	_on_elevated_surface = _is_surface_tile(_get_tile_atlas_coords(_get_tile_map_position()))


func _get_tile_map_position() -> Vector2i:
	if _tilemap == null:
		return Vector2i.MAX
	return _tilemap.local_to_map(_tilemap.to_local(global_position))


func _get_tile_atlas_coords(map_pos: Vector2i) -> Vector2i:
	if _tilemap == null or map_pos == Vector2i.MAX:
		return Vector2i(-1, -1)
	if _tilemap.get_cell_source_id(map_pos) == -1:
		return Vector2i(-1, -1)
	return _tilemap.get_cell_atlas_coords(map_pos)


func _is_surface_tile(atlas: Vector2i) -> bool:
	return atlas.x in SURFACE_TILE_ATLAS_X
