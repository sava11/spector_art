extends Node
class_name FadeController

@export var albedo_texture:Texture2D:
	set(value):
		albedo_texture = value
		_update_shader_params()

@export var roughness_texture:Texture2D:
	set(value):
		roughness_texture = value
		_update_shader_params()

@export var metallic_texture:Texture2D:
	set(value):
		metallic_texture = value
		_update_shader_params()

@export var target_node_path:=NodePath(".."):
	set(value):
		target_node_path=value
		if is_node_ready():
			target_node=get_node_or_null(target_node_path)

@export var material_parametr_name:="material"

@export var fade_start_height: float = 0.0:
	set(value):
		fade_start_height = value
		_update_shader_params()

@export var fade_end_height: float = 5.0:
	set(value):
		fade_end_height = value
		_update_shader_params()

var target_node:Node3D
var _shader_material: ShaderMaterial

func _ready():
	target_node=get_node_or_null(target_node_path)
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = load("res://materials/extra/fade/height_fade_shader.gdshader")
	get_parent().set(material_parametr_name,_shader_material)
	_update_shader_params()

func _update_shader_params():
	if _shader_material:
		_shader_material.render_priority=-1
		_shader_material.set_shader_parameter("base_position", target_node.global_position)
		_shader_material.set_shader_parameter("fade_start_height", fade_start_height)
		_shader_material.set_shader_parameter("fade_end_height", fade_end_height)
		_shader_material.set_shader_parameter("albedo_texture", albedo_texture)
		_shader_material.set_shader_parameter("roughness_texture", roughness_texture)
		_shader_material.set_shader_parameter("metallic_texture", metallic_texture)
		_update_position()

func _process(_delta: float) -> void:
	_update_position()

func _update_position():
	if _shader_material:
		_shader_material.set_shader_parameter("base_position", target_node.global_position)
		print(_shader_material.get_shader_parameter("base_position"))
