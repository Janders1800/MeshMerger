tool
class_name MeshMerger extends MeshInstance


export (bool) var btn_merge_meshes: bool setget bake_meshes
export (bool) var btn_clean_meshes: bool setget clean_meshes
export (bool) var children_visibility: bool = true setget set_children_visibility
export (bool) var delete_child_meshes_on_play: bool
export var generate_collisions: bool = false


var material_counter: int = 0
var collision_parent: Node


func _ready():
	if delete_child_meshes_on_play:
		for node in get_children():
			if node is StaticBody:
				pass
			else:
				node.queue_free()


# warning-ignore:unused_argument
func bake_meshes(value):
	if !Engine.editor_hint:
		return
	
	if mesh != null:
		mesh = null
	
	if generate_collisions:
		collision_parent = StaticBody.new()
		add_child(collision_parent)
		collision_parent.owner = get_tree().edited_scene_root
	else:
		clean_collisions()
	
	material_counter = 0
	var new_mesh := ArrayMesh.new()
	
	# A bit sketchy, but I know no other way to get MeshInstances at more that one level deep
	for node in get_children():
		if node is MeshInstance:
			new_mesh = extract_mesh(node, new_mesh)
			generate_collison(node)
		for nodeChild in node.get_children():
			if nodeChild is MeshInstance:
				new_mesh = extract_mesh(nodeChild, new_mesh)
				generate_collison(nodeChild)
	
	set_children_visibility(false)
	self.mesh = new_mesh


# warning-ignore:unused_argument
func clean_meshes(value):
	if !Engine.editor_hint:
		return

	mesh = null
	clean_collisions()
	set_children_visibility(true)


func extract_mesh(node: MeshInstance, new_mesh: ArrayMesh):
	for i in node.mesh.get_surface_count():
		var data = node.mesh.surface_get_arrays(i)
		var offset: PoolVector3Array = data[ArrayMesh.ARRAY_VERTEX]
		
		for o in offset.size():
			offset.set(o, node.global_transform.basis.xform(offset[o]) + node.global_transform.origin)
		
		data[ArrayMesh.ARRAY_VERTEX] = offset
		
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
		new_mesh.surface_set_material(material_counter, node.mesh.surface_get_material(i))
		material_counter +=1
		
		return new_mesh


func generate_collison(node):
	if !collision_parent:
		return
	for child in node.get_children():
		if child is StaticBody and child.get_child_count() > 0:
			for grandchild in child.get_children():
				if grandchild is CollisionShape:
					var new_col := CollisionShape.new()
					new_col.global_transform = child.global_transform
					collision_parent.add_child(new_col)
					new_col.shape = grandchild.shape
					new_col.set_owner(get_tree().get_edited_scene_root())


func clean_collisions():
	for child in get_children():
		if child is StaticBody:
			child.queue_free()


func set_children_visibility(value):
	children_visibility = value
	for node in get_children():
		if not node is StaticBody:
			node.visible = value
