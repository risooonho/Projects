extends "res://addons/gut/test.gd"

const SerializerGd           = preload("res://HierarchicalSerializer.gd")
const NodeGuardGd            = preload("res://NodeGuard.gd")
const FiveNodeBranchScn      = preload("res://tests/files/FiveNodeBranch.tscn")
const PostDeserializeScn     = preload("res://tests/files/PostDeserialize.tscn")

const EPSILON = 0.00001

var resourceExtension := ".tres" if OS.has_feature("debug") else ".res"
var childrenNumberBeforeTest := 0


func _init():
	name = (get_script() as Script).resource_path.get_file()


func before_each():
	childrenNumberBeforeTest = get_child_count()


func after_each():
	assert_eq( childrenNumberBeforeTest, get_child_count(), "No new nodes" )


func test_saveToFile():
	var serializer = SerializerGd.new()

	var saveFileNoDir = "noDirectory"
	var err = serializer.saveToFile( saveFileNoDir )
	assert_eq( err, OK )
	assert_file_exists( saveFileNoDir + resourceExtension )
# warning-ignore:return_value_discarded
	Directory.new().remove( saveFileNoDir + resourceExtension )

	var saveFileUserDir = "user://ww/userDir.tres"
	err = serializer.saveToFile( saveFileUserDir )
	assert_eq( err, OK )
	assert_file_exists( saveFileUserDir )
# warning-ignore:return_value_discarded
	Directory.new().remove( saveFileUserDir )

	var saveFileWrongPath = "bah://wrong/Path.tres"
	err = serializer.saveToFile( saveFileWrongPath )
	assert_eq( err, ERR_CANT_CREATE )
	assert_file_does_not_exist( saveFileWrongPath )
# warning-ignore:return_value_discarded
	Directory.new().remove( saveFileWrongPath )


func test_saveVersion():
	var version := "0.4.3"
	var serializer = SerializerGd.new()
	var saveFile = "user://versionSave.tres"

	ProjectSettings.set_setting( "application/config/version", version )

	var err = serializer.saveToFile( saveFile )
	assert_file_exists( saveFile )
	assert_eq( err, OK )
	assert_eq( serializer.getVersion(), version )

	err = serializer.loadFromFile( saveFile )
	assert_eq( err, OK )
	assert_eq( serializer.getVersion(), version )

# warning-ignore:return_value_discarded
	Directory.new().remove( saveFile )


func test_saveUserData():
	var serializer = SerializerGd.new()
	var saveFile = "user://userDataSave.tres"
	var dict = { "d":5, 1:2, 3:4.5678 }
	var arr = [0, Vector2(1.1, 2.2), 8, null]

	serializer.userData["DICT"] = dict
	serializer.userData["ARR"] = arr
	var err = serializer.saveToFile( saveFile )
	assert_file_exists( saveFile )
	assert_eq( err, OK )

	serializer = SerializerGd.new()

	err = serializer.loadFromFile( saveFile )
	assert_eq( err, OK )

	assert_almost_eq( serializer.userData["DICT"][3], dict[3], EPSILON )
	assert_eq( serializer.userData["DICT"]["d"], dict["d"] )
	assert_eq( serializer.userData["ARR"][1], arr[1] )
	assert_eq( serializer.userData["ARR"][3], arr[3] )

# warning-ignore:return_value_discarded
	Directory.new().remove( saveFile )


func test_godotBuiltinTypes():
	pending()


# serializing object references is wrong but i want to see if my code doesn't blow up
func test_serializeNodeReference():
	var serializer = SerializerGd.new()
	var saveFile = "user://NodeReference.tres"
	var node = Node.new()
	add_child(node)
	var ref = Reference.new()

	serializer.userData["node"] = node
	serializer.userData["ref"] = ref

	var err = serializer.saveToFile( saveFile )
	assert_file_exists( saveFile )
	assert_eq( err, OK )

	serializer = SerializerGd.new()

	err = serializer.loadFromFile( saveFile )
	assert_eq( err, OK )

	node.queue_free()
	remove_child( node )
# warning-ignore:return_value_discarded
	Directory.new().remove( saveFile )