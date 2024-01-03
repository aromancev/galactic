# Helper class that provides an efficient (both compute and space) way to serialize data.
# The implementation is mostly inspired by Protobuf. It is not as efficient as Protobuf but
# allows inspecting the data without knowing the schema.
#
# A simple usage example:
#   var a := BinaryPayload.new()
#   a.set_var(1, "test")
#   var buff := a.encode()

#   var b := BinaryPayload.decoded(buff)
#   print(b.get_ver(1)) # prints "test"
#
# It works similarly to a dictionary with integer keys. 
# It uses Binary Serialization API (`var_to_bin`) to store values.
# See https://docs.godotengine.org/en/stable/tutorials/io/binary_serialization_api.html.
#
# You can also store another payload like so:
#   var outer := BinaryPayload.new()
#   var inner := BinaryPayload.new()
#   inner.set_var(1, "test")
#   outer.set_payload(1, inner)

#   var test = BinaryPayload.decoded(outer.encode()).get_payload(1).get_var(1)
#   print(test) # prints "test"
#
# IMPORTANT: Maximum key (index) value is 255 because it is stored as uint8.
# 
# One of the main goals of this format is to preserve compatability with different versions.
# Here are the general guidelines that will help you to retain backward compatability for network and persistance (saves):
#   * Always assume that any field can be null.
#   * NEVER change key (index) numbers of the same field.
#   * NEVER delete key (index) numbers. If some field is not needed any more, keep the original number in a comment 
#       to prevent future changes from reusing the same number.
#   * If you need to store large arrays of data, use array functions (`append_int32`, `append_vector2`, etc.) 
#       or manually create Packed*Array and set it as a var. For example, if you need to store positions of thousands of Nodes,
#       storing them in a packed array (which `append_*` functions also use) is much more efficient because we don't need to store 
#       type information with each one.
#   * If the encoding logic becomes complicated, use constants or enums to store index values.
class_name BinaryPayload
extends RefCounted

const VERSION = 1
const MIN_INDEX = 1
const MAX_INDEX = (1 << 8) - 1 # 255

# Values are stored in an array rather than in a dictionary because keys are likely to be 
# monotonically increasing and not exceeding 255. In such a case, hash tables are going to be 
# both slower and require more memory.
var _values: Array[Variant] = []

static func decoded(data: PackedByteArray) -> BinaryPayload:
    var p := BinaryPayload.new()
    p.decode(data)
    return p

func get_var(index: int) -> Variant:
    if index < 0 || index >= _values.size():
        return null

    return _values[index]

# Tries to decode a PackedByteArray field as BinaryPayload.
func get_payload(index: int) -> BinaryPayload:
    if index < 0 || index >= _values.size():
        return null

    return BinaryPayload.decoded((_values as Array[PackedByteArray])[index])

func get_payload_array(index: int) -> Array[BinaryPayload]:
    if index < 0 || index >= _values.size():
        return []

    if !(_values[index] is Array):
        return []

    return _BinaryPayloadArray.decoded((_values as Array[PackedByteArray])).items

func set_var(index: int, value: Variant) -> void:
    _ensure_size(index)
    _values[index] = value

func set_payload(index: int, value: BinaryPayload) -> void:
    set_var(index, value)

# Appends a value to an array stored in the index.
# If the value is not set, a new array will be created.
# If the value already exists and is not an array, it will be overridden.
func append_var(index: int, value: Variant) -> void:
    _ensure_size(index)
    if !(_values[index] is Array):
        _values[index] = []

    (_values as Array[PackedByteArray]).append(value)

# Appends a value to an array stored in the index.
# If the value is not set, a new array will be created.
# If the value already exists and is not an array, it will be overridden.
func append_payload(index: int, value: BinaryPayload) -> void:
    _ensure_size(index)
    if !(_values[index] is _BinaryPayloadArray):
        _values[index] = _BinaryPayloadArray.new()

    (_values as Array[_BinaryPayloadArray])[index].items.append(value)

# Appends a value to an array stored in the index.
# If the value is not set, a new array will be created.
# If the value already exists and is not an array, it will be overridden.
func append_int32(index: int, value: int) -> void:
    _ensure_size(index)
    if !(_values[index] is PackedInt32Array):
        _values[index] = PackedInt32Array()

    (_values as Array[PackedInt32Array])[index].append(value)

# Appends a value to an array stored in the index.
# If the value is not set, a new array will be created.
# If the value already exists and is not an array, it will be overridden.
func append_vector2(index: int, value: Vector2) -> void:
    _ensure_size(index)
    if !(_values[index] is PackedVector2Array):
        _values[index] = PackedVector2Array()

    (_values as Array[PackedVector2Array])[index].append(value)

func encode() -> PackedByteArray:
    var buff := StreamPeerBuffer.new()
    buff.put_u8(VERSION)

    for i in _values.size():
        # Null values are not stored because any non-existent index will return null anyway.
        if _values[i] == null:
            continue

        buff.put_u8(i)
        if _values[i] is BinaryPayload:
            buff.put_var((_values as Array[BinaryPayload])[i].encode())
        elif _values[i] is _BinaryPayloadArray:
            buff.put_var((_values as Array[_BinaryPayloadArray])[i].encode())
        else:
            buff.put_var(_values[i])

    return buff.data_array

func decode(data: PackedByteArray) -> void:
    _values.clear()

    var buff := StreamPeerBuffer.new()
    buff.data_array = data

    var version := buff.get_u8()
    assert(version > 0 && version <= VERSION, "Unknown payload version.")

    while buff.get_position() < buff.get_size():
        var i := buff.get_u8()
        _ensure_size(i)
        _values[i] = buff.get_var()

# Ensures values array is enough to store all indexes.
func _ensure_size(index: int) -> void:
    assert(index >= MIN_INDEX && index <= MAX_INDEX, "Index must be between %s and %s." % [MIN_INDEX, MAX_INDEX])

    # Every time index is higher than size, increase size by two. This ensures logarythmic complexity even if
    # resize doesn't do it internally. 
    if index >= _values.size():
        _values.resize(min(index * 2, MAX_INDEX) as int + 1)

# Helper class to encode and decode array of payloads.
# DO NOT expose this to avoid creating a complicated API.
class _BinaryPayloadArray:
    var items: Array[BinaryPayload]

    static func decoded(data: Array[PackedByteArray]) -> _BinaryPayloadArray:
        var arr := _BinaryPayloadArray.new()
        arr.items.resize(data.size())
        for i in data.size():
            arr.items[i] = BinaryPayload.decoded(data[i] as PackedByteArray)
        return arr

    func encode() -> Array[PackedByteArray]:
        var data: Array[PackedByteArray] = []
        data.resize(items.size())
        for i in items.size():
            data[i] = items[i].encode()
        return data
