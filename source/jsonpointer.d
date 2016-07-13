module jsonpointer;

//TODO: import only json
import vibe.d;

version(unittest)
{
	alias j = parseJsonString;
}

Json jsonPointer(in Json schema, string path)
{
	return Json.emptyObject;
}

unittest {
	Json json = j(`{
					"foo": "baz",
					"bar": [0, 1, 2]
				  }`);
	try jsonPointer(json, "/baz"); catch (Exception e) assert(e.msg == "Invalid JSON Pointer");
	assert(jsonPointer(json, "/foo") == Json("baz"));
	assert(jsonPointer(json, "/bar/1") == Json("1"));
}
