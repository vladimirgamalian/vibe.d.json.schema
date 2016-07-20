module jsonpointer;

//https://tools.ietf.org/html/rfc6901

import vibe.data.json;
import std.string;

immutable string InvalidJsonPointerException = "Invalid JSON Pointer";

version(unittest)
{
	alias j = parseJsonString;
}

Json jsonPointer(in Json json, string path)
{
	if ((path.length > 0) && (!path.startsWith("/")))
		throw new Exception(InvalidJsonPointerException);

	string[] tokens = split(path, "/");
	if (tokens.length > 0)
		tokens = tokens[1..$];

	Json result = json;
	foreach (token; tokens)
	{
		token = token.replace("~1", "/").replace("~0", "~");

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
	try jsonPointer(Json(), "baz"); catch (Exception e) assert(e.msg == InvalidJsonPointerException);
	try jsonPointer(Json(), "baz/"); catch (Exception e) assert(e.msg == InvalidJsonPointerException);
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

unittest {
	Json json = j(`{
				  "foo": ["bar", "baz"],
				  "": 0,
				  "a/b": 1,
				  "c%d": 2,
				  "e^f": 3,
				  "g|h": 4,
				  "i\\j": 5,
				  "k\"l": 6,
				  " ": 7,
				  "m~n": 8
				  }`);

	assert(jsonPointer(json, "") == json);
	assert(jsonPointer(json, "/foo") == Json([Json("bar"), Json("baz")]));
	assert(jsonPointer(json, "/foo/0") == Json("bar"));
	assert(jsonPointer(json, "/") == Json(0));
	assert(jsonPointer(json, "/a~1b") == Json(1));
	assert(jsonPointer(json, "/c%d") == Json(2));
	assert(jsonPointer(json, "/e^f") == Json(3));
	assert(jsonPointer(json, "/g|h") == Json(4));
	assert(jsonPointer(json, "/i\\j") == Json(5));
	assert(jsonPointer(json, "/k\"l") == Json(6));
	assert(jsonPointer(json, "/ ") == Json(7));
	assert(jsonPointer(json, "/m~0n") == Json(8));
}
