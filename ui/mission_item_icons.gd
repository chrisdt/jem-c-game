extends RefCounted

# Dialogue keeps its plain story text. Match whole item names, longest first,
# then supplement them with the same textures used by pickups and equipment.
const CATALOG = preload("res://ui/world_catalog.gd")
const TRIAL = preload("res://environment/trial_art.gd")
const FROST = preload("res://environment/frost_art.gd")
const EMBER = preload("res://environment/ember_art.gd")
const EARTH_PROPS: Texture2D = preload("res://assets/npcs/earth_quest_props.png")
const HUMAN = preload("res://environment/human_npc.gd")
const COMMON := {
	"copper":"copper", "blue crystals":"blue", "blue crystal":"blue",
	"fallen wood":"wood", "wood":"wood", "fallen branches":"wood", "logs":"wood",
	"Earth sword":"sword", "copper sword":"sword", "starter sword":"sword", "reinforced sword":"sword", "sword":"sword",
	"hand drill":"drill", "upgraded drill":"drill", "reinforced drill":"drill", "starter pick":"pick",
	"Frostfang Sword":"frost_sword", "Frostfang":"frost_sword", "Crystal Drill":"frost_drill", "Magma Drill":"ember_drill", "Sunfang Sword":"ember_sword",
}
const WORLDS := [
	{
		"crystals":"blue", "crystal":"blue",
		"supply box":"supplies", "tied wooden box":"supplies", "tied box":"supplies", "supplies":"supplies",
		"expedition locker":"locker", "locker":"locker", "seal kit":"seals",
		"damaged spacesuit":"suit", "sealed spacesuit":"suit", "spacesuit":"suit", "damaged suit":"suit", "suit":"suit",
		"engine component":"engine",
	},
	{
		"frost ore":"frost", "amethysts":"amethyst", "amethyst":"amethyst",
		"brass-and-crystal beacon fragments":"beacon", "beacon fragments":"beacon", "beacon fragment":"beacon",
		"heart-crystal":"heart", "power coupling":"coupling", "keepsake":"keepsake", "frozen rock":"cache", "frozen cache":"cache",
	},
	{
		"gold":"gold", "fire rubies":"ruby", "fire ruby":"ruby",
		"cooling parts":"cooler", "three parts":"cooler",
		"glowleaf plants":"glowleaf", "Oasis glowleaf":"glowleaf", "glowleaf":"glowleaf",
		"empty flask":"flask", "antidote canteen":"flask", "power core":"core", "star map":"map",
	},
]
static var patterns: Dictionary = {}
static var names: Dictionary = {}
static var textures: Dictionary = {}

static func matches(text: String, world: int) -> Array[Dictionary]:
	world = clampi(world,0,2)
	if not patterns.has(world):
		var aliases := COMMON.duplicate()
		aliases.merge(WORLDS[world])
		var terms := aliases.keys()
		terms.sort_custom(func(a: String,b: String): return a.length() > b.length())
		var alternatives := PackedStringArray()
		var lookup := {}
		for term: String in terms:
			alternatives.append(term)
			lookup[term.to_lower()] = aliases[term]
		var pattern := RegEx.new()
		pattern.compile("(?i)\\b(?:"+"|".join(alternatives)+")\\b")
		patterns[world] = pattern
		names[world] = lookup
	var result: Array[Dictionary] = []
	for found: RegExMatch in patterns[world].search_all(text):
		result.append({"start":found.get_start(),"end":found.get_end(),"name":found.get_string(),"id":names[world][found.get_string().to_lower()]})
	return result

static func texture(id: String) -> Texture2D:
	if textures.has(id): return textures[id]
	var result: Texture2D
	match id:
		"copper": result = CATALOG.ORES[0][0]
		"blue", "frost": result = CATALOG.ORES[1][0]
		"amethyst": result = CATALOG.ORES[1][1]
		"gold": result = CATALOG.ORES[2][0]
		"ruby": result = CATALOG.ORES[2][1]
		"wood": result = TRIAL.wood()
		"sword": result = TRIAL.icon(0)
		"pick", "drill": result = CATALOG.tool_icon(id == "drill")
		"frost_sword", "frost_drill", "beacon", "heart", "coupling", "keepsake", "cache":
			result = FROST.item({"frost_sword":0,"frost_drill":1,"beacon":2,"heart":3,"coupling":4,"keepsake":5,"cache":7}[id])
		"ember_sword", "ember_drill", "cooler", "glowleaf", "flask", "core", "map":
			result = EMBER.item({"ember_sword":0,"ember_drill":1,"cooler":2,"glowleaf":3,"flask":4,"core":5,"map":7}[id])
		"supplies", "locker", "seals", "engine", "suit":
			var part := AtlasTexture.new()
			part.atlas = EARTH_PROPS
			var region: Rect2i = {"supplies":Rect2i(0,0,440,480),"locker":Rect2i(1050,0,486,460),"seals":Rect2i(0,480,515,544),"engine":Rect2i(520,480,510,544),"suit":Rect2i(1035,480,501,544)}[id]
			var bounds := HUMAN.visible_bounds(EARTH_PROPS.get_image().get_region(region))
			part.region = Rect2(bounds.position+region.position,bounds.size)
			part.filter_clip = true
			result = part
	textures[id] = result
	return result

static func fill(label: RichTextLabel, text: String, world: int) -> void:
	label.clear()
	var cursor := 0
	for item in matches(text,world):
		label.add_text(text.substr(cursor,item.end-cursor))
		# Use a nonbreaking space between the item name and its icon.
		label.add_text("\u00a0(")
		var icon := texture(item.id)
		var dimensions := icon.get_size()*(24.0/maxf(icon.get_width(),icon.get_height()))
		# Keep the default pixel units: Godot 4.7 replaced the optional
		# percentage booleans with ImageUnit enums. The common arguments work
		# in both the editor and our 4.6 Web export runtime.
		label.add_image(icon,maxi(1,roundi(dimensions.x)),maxi(1,roundi(dimensions.y)),Color.WHITE,INLINE_ALIGNMENT_CENTER,Rect2(),null,false,item.name)
		label.add_text(")")
		cursor = item.end
	label.add_text(text.substr(cursor))
