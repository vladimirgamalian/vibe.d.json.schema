module jsonpointer;

//TODO: import only json
import vibe.d;

immutable string InvalidJsonPointerException = "Invalid JSON Pointer";

version(unittest)
{
	alias j = parseJsonString;
}

//TODO: special characters (~0, ~1)
Json jsonPointer(in Json json, string path)
{
	if (path.length < 2)
		throw new Exception(InvalidJsonPointerException);
	if (!path.startsWith("/"))
		throw new Exception(InvalidJsonPointerException);
	if (path.endsWith("/"))
		throw new Exception(InvalidJsonPointerException);

	string[] tokens = split(path, "/")[1..$];

	Json result = json;
	foreach (token; tokens)
	{
		switch (result.type)
		{
			case Json.Type.object:
				result = result[token];
				break;
			case Json.Type.array:
				uint i;
				try i = token.to!uint; catch (Exception) throw new Exception(InvalidJsonPointerException);
				if (i >= result.length)
					return Json.undefined;
				result = result[i];
				break;
			default:
				return Json.undefined;
		}
	}

	return result;
}

unittest {
	try jsonPointer(Json(), ""); catch (Exception e) assert(e.msg == InvalidJsonPointerException);
	try jsonPointer(Json(), "baz"); catch (Exception e) assert(e.msg == InvalidJsonPointerException);
	try jsonPointer(Json(), "/baz/"); catch (Exception e) assert(e.msg == InvalidJsonPointerException);
}

unittest {
	Json json = j(`{"foo": 42}`);
	assert(jsonPointer(json, "/bar").type == Json.Type.undefined);
	assert(jsonPointer(json, "/bar/baz").type == Json.Type.undefined);
}

unittest {
	Json json = j(`{"foo": [0, 1, 2]}`);
	try jsonPointer(json, "/foo/bar"); catch (Exception e) assert(e.msg == InvalidJsonPointerException);
	try jsonPointer(json, "/foo/-1"); catch (Exception e) assert(e.msg == InvalidJsonPointerException);
	try jsonPointer(json, "/foo/01"); catch (Exception e) assert(e.msg == InvalidJsonPointerException);
	assert(jsonPointer(json, "/foo/3").type == Json.Type.undefined);
	assert(jsonPointer(json, "/foo/2").type == Json.Type.int_);
}

unittest {
	Json json = j(`{
				  "foo": "baz",
				  "bar": [0, 1, 2]
				  }`);
	try jsonPointer(json, "/baz"); catch (Exception e) assert(e.msg == InvalidJsonPointerException);
	assert(jsonPointer(json, "/foo") == Json("baz"));
	assert(jsonPointer(json, "/bar/1") == Json(1));
}

unittest {
	Json json = j(`{
				  "foo": {
					"bar": {
						"baz": [0, {
							"foo": [0, "bar"]
						}]
					}
				  }
				  }`);
	assert(jsonPointer(json, "/foo/bar/baz/1/foo/1") == Json("bar"));
}
