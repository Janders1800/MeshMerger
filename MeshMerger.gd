tool
class_name MeshMerger extends MeshInstance


export (bool) var btn_merge_meshes: bool setget bake_meshes
export (bool) var btn_clean_meshes: bool setget clean_meshes
export (bool) var children_visibility: bool = true setget set_children_visibility
export (bool) var delete_child_meshes_on_play: bool
export var generate_collisions: bool = false


var material_counter: int
var collision_node: StaticBody


func _ready() -> void:
	if Engine.editor_hint:
		return
	if delete_child_meshes_on_play:
		for node in get_children():
			if not node is StaticBody:
				node.queue_free()


# warning-ignore:unused_argument
func bake_meshes(value: bool) -> void:
	if !Engine.editor_hint:
		return
	
	mesh = null
	
	if generate_collisions:
		collision_node = StaticBody.new()
		add_child(collision_node)
		collision_node.owner = get_tree().edited_scene_root
	else:
		clean_collisions()
	
	material_counter = 0
	var new_mesh := ArrayMesh.new()
	
	var all_meshes := []
	for child in get_children():
		all_meshes.append_array(get_meshinstances(child))
	
	for node in all_meshes:
		new_mesh = extract_mesh(node, new_mesh)
		generate_collison(node)
	
	new_mesh = combine_materials(new_mesh)
	
	set_children_visibility(false)
	self.mesh = new_mesh


func get_meshinstances(node: Node):
	var meshInstances := []

	# Check if the current node is a MeshInstance
	if node is MeshInstance:
		meshInstances.append(node)
	
	# Recursively traverse child nodes
	for child in node.get_children():
		var childMeshInstances = get_meshinstances(child)
		meshInstances.append_array(childMeshInstances)
	
	return meshInstances


# warning-ignore:unused_argument
func clean_meshes(value: bool) -> void:
	if !Engine.editor_hint:
		return
	
	mesh = null
	clean_collisions()
	set_children_visibility(true)


func extract_mesh(node: MeshInstance, new_mesh: ArrayMesh) -> ArrayMesh:
	for i in range(node.mesh.get_surface_count()):
		var surf_tool := SurfaceTool.new()
		var final_transform: Transform = Transform(node.global_transform.basis, node.global_transform.origin - global_transform.origin)
		surf_tool.append_from(node.mesh, i, final_transform)
		
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf_tool.commit_to_arrays())
		new_mesh.surface_set_material(material_counter, node.mesh.surface_get_material(i))
		material_counter += 1
		
	return new_mesh


func combine_materials(mesh: ArrayMesh) -> ArrayMesh:
	var result_mesh := ArrayMesh.new()
	var mat_counter := 0
	var materials: Array
	
	for i in range(mesh.get_surface_count()):
		if not materials.has(mesh.surface_get_material(i)):
			materials.append(mesh.surface_get_material(i))
	
	for mat in materials:
		var surf_tool := SurfaceTool.new()
		
		for i in range(mesh.get_surface_count()):
			if mat == mesh.surface_get_material(i):
				surf_tool.append_from(mesh, i, Transform.IDENTITY)
		
		result_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf_tool.commit_to_arrays())
		result_mesh.surface_set_material(mat_counter, mat)
		mat_counter += 1
	
	return result_mesh


func get_shapes(node: Node) -> Array:
	var shapes := []
	
	if node is CollisionShape:
		shapes.append(node)
	
	for child in node.get_children():
		var child_shapes := get_shapes(child)
		shapes.append_array(child_shapes)
	
	return shapes


func generate_collison(node):
	if !collision_node:
		return
	
	var collisions := []
	for node in get_children():
		collisions.append_array(get_shapes(node))
	
	for shape in collisions:
		var new_col := CollisionShape.new()
		new_col.global_transform = shape.global_transform
		new_col.transform.origin = new_col.transform.origin - global_transform.origin
		collision_node.add_child(new_col)
		new_col.shape = shape.shape
		new_col.set_owner(get_tree().get_edited_scene_root())


func clean_collisions() -> void:
	for child in get_children():
		if child is StaticBody:
			child.queue_free()


func set_children_visibility(value: bool) -> void:
	children_visibility = value
	for node in get_children():
		if not node is StaticBody:
			node.visible = value
