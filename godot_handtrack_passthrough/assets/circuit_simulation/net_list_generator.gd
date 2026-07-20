class_name NetListGenerator

## [NetListGenerator] is a utility that, once it recieves a signal, generates
## a netlist representation of the current circuit(s) built in the field.
## The netlist is returned as seperate "islands", where an island is an
## independent electrical system (i.e. fully disconnected)
##
## This class is not instanced, only used as a [RefCounted]. It will
## never enter the actual scene tree. Call the [method extract_netlist]
## method to use. This is the entrypoint.

## Main entrypoint. Will return an array of all dicts for each "island". Island
## defined semantically above
## [param components]: Input an array with all components you want included
## in the export.
static func extract_netlist(components: Array) -> Array:
	# Off topic note, good resource I found on understanding union-finding https://yuminlee2.medium.com/union-find-algorithm-ffa9cd7d2dba

	# union-find over SnapPoints
	var parent := {}

	# We will start by seperating the net on a node level.
	for component in components:

		# For all SnapPoints, ensure they exist in the tree, then union all the
		# connected snappoints.
		for sp in component.get_snap_points():
			_make_set(sp, parent)
			for other in sp.connections:
				_make_set(other, parent)
				_union(sp, other, parent)

		# All the short components also need to be handled. For now these are
		# only wires. Ensure all nodes that are connected by a short component
		# are unioned.
		for short in component.get_shorts():
			_make_set(short[0], parent)
			_make_set(short[1], parent)
			_union(short[0], short[1], parent)


	# At this point, we have a tree with the proper node groups connected to
	# root nodes. We will clean this up and compact it down into a format that
	# is easier to work with:
	var sp_to_net := {}
	var net_to_sps := []
	var root_to_net := {}
	for sp in parent:
		var root = _find(sp, parent)
		if not root_to_net.has(root):
			root_to_net[root] = net_to_sps.size()
			net_to_sps.append([])
		var net_index: int = root_to_net[root]
		sp_to_net[sp] = net_index
		net_to_sps[net_index].append(sp)

	# Now the data is presented as such:
	# sp_to_net: dict, maps each SnapPoint to an integer representing that net.
	# net_to_sps: list, maps the integer of the net (index) to the SnapPoints in it.
	# root_to_net: dict, maps each root node to its net id.

	# union-find again, but over nets this time. An element sitting between two
	# nets ties them into the same island.
	var parent_islands = {}
	
	# seed each net as its own island
	for i in range(0, net_to_sps.size()):
		parent_islands[i] = i

	# for each element, union the nets its terminals sit on
	for component in components:
		for element in component.get_elements():
			var sps = element["terminals"] # List of SnapPoints that are shorted
			var net_ids = {} # Set dict

			# Populate net_ids with net ids from SnapPoints
			for sp in sps:
				net_ids[sp_to_net[sp]] = null

			# Union all internal component shorts
			var unique_nets: Array = net_ids.keys()
			for i in range(1, unique_nets.size()):
				_union(unique_nets[0], unique_nets[i], parent_islands)

	# Compact the net down
	for i in parent_islands:
		parent_islands[i] = _find(i, parent_islands)

	# Collapse the net union-find into islands. Remaining roots are islands
	# island_to_index maps that root to its slot in the output array.
	var island_to_index := {}	# Island mapped to its own index
	var islands := []			# List of islands
	var net_to_local := {}		# Each net mapped to its local index (within island)

	for net in range(0, net_to_sps.size()):
		var root = _find(net, parent_islands)
		if not island_to_index.has(root):
			island_to_index[root] = islands.size()
			islands.append({
				"net_count": 0,
				"elements": [],
				"ground_nets": [],
				"net_to_snappoints": [],
			})

		var island = islands[island_to_index[root]]
		net_to_local[net] = island["net_count"]
		island["net_count"] += 1
		island["net_to_snappoints"].append(net_to_sps[net])

	# Drop every element into its island with locally-reindexed nets. We know all
	# terminals of an element are in the same island. Additional checks are redundant
	for component in components:
		for element in component.get_elements():
			var element_nets := []
			for sp in element["terminals"]:
				element_nets.append(net_to_local[sp_to_net[sp]])

			var root = _find(sp_to_net[element["terminals"][0]], parent_islands)
			var island = islands[island_to_index[root]]
			island["elements"].append({
				"type": element["type"],
				"nets": element_nets,
				"value": element["value"],
			})
	return islands


# Union find helpers

# Create entry if not already existing
static func _make_set(x, parent: Dictionary) -> void:
	if not parent.has(x):
		parent[x] = x

# Find and return the root of the net. Useful for collapsing
static func _find(x, parent: Dictionary):   # No return type here as its either a SnapPoint (first phase)
	while parent[x] != x:                   # or an integer (second phase)
		x = parent[x]
	return x

# Union two nets. Sets the top parent to the other net's parent. One change so
# no full O(n) list manipulation is needed
static func _union(a, b, parent: Dictionary) -> void:
	var ra = _find(a, parent)
	var rb = _find(b, parent)
	if ra != rb:
		parent[ra] = rb
