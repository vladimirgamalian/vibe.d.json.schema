module jsonschemanew;

import vibe.d;

bool testType(Json json, string type)
{
	assert(json.type != Json.Type.undefined);

	switch (type)
	{
		case "array":
			return json.type == Json.Type.array;

		case "boolean":
			return json.type == Json.Type.bool_;

		case "integer":
			return (json.type == Json.Type.int_) || (json.type == Json.Type.bigInt);

		case "null":
			return (json.type == Json.Type.null_);

		case "number":
			return (json.type == Json.Type.int_) || (json.type == Json.Type.bigInt) || (json.type == Json.Type.float_);

		case "object":
			return (json.type == Json.Type.object);

		case "string":
			return (json.type == Json.Type.string);

		default:
			throw new Exception("Unknown \"type\" value: " ~ type);
	}
}

unittest {
	try testType(Json(false), "foo"); catch (Exception e) assert(e.msg == "Unknown \"type\" value: foo");
	try testType(Json(42), "bar"); catch (Exception e) assert(e.msg == "Unknown \"type\" value: bar");

	assert(testType(Json.emptyArray, "array"));
	assert(!testType(Json.emptyArray, "boolean"));
	assert(!testType(Json.emptyArray, "integer"));
	assert(!testType(Json.emptyArray, "null"));
	assert(!testType(Json.emptyArray, "number"));
	assert(!testType(Json.emptyArray, "object"));
	assert(!testType(Json.emptyArray, "string"));

	assert(testType(Json([Json(0), Json(1)]), "array"));
	assert(testType(Json([Json("foo"), Json(false)]), "array"));

	assert(!testType(Json(false), "array"));
	assert(testType(Json(false), "boolean"));
	assert(!testType(Json(false), "integer"));
	assert(!testType(Json(false), "null"));
	assert(!testType(Json(false), "number"));
	assert(!testType(Json(false), "object"));
	assert(!testType(Json(false), "string"));

	assert(!testType(Json(true), "array"));
	assert(testType(Json(true), "boolean"));
	assert(!testType(Json(true), "integer"));
	assert(!testType(Json(true), "null"));
	assert(!testType(Json(true), "number"));
	assert(!testType(Json(true), "object"));
	assert(!testType(Json(true), "string"));

	assert(!testType(Json(0), "array"));
	assert(!testType(Json(0), "boolean"));
	assert(testType(Json(0), "integer"));
	assert(!testType(Json(0), "null"));
	assert(testType(Json(0), "number"));
	assert(!testType(Json(0), "object"));
	assert(!testType(Json(0), "string"));

	assert(!testType(Json(0.0), "array"));
	assert(!testType(Json(0.0), "boolean"));
	assert(!testType(Json(0.0), "integer"));
	assert(!testType(Json(0.0), "null"));
	assert(testType(Json(0.0), "number"));
	assert(!testType(Json(0.0), "object"));
	assert(!testType(Json(0.0), "string"));

	assert(testType(Json(0), "integer"));
	assert(testType(Json(0), "number"));
	assert(testType(Json(0.0), "number"));
	assert(testType(Json(1), "integer"));
	assert(testType(Json(1), "number"));
	assert(testType(Json(1.0), "number"));
	assert(testType(Json(-1), "integer"));
	assert(testType(Json(-1), "number"));
	assert(testType(Json(-1.0), "number"));
	assert(testType(Json(0x1ffffffff), "integer"));
	assert(testType(Json(0x1ffffffff), "number"));

	assert(!testType(Json(null), "array"));
	assert(!testType(Json(null), "boolean"));
	assert(!testType(Json(null), "integer"));
	assert(testType(Json(null), "null"));
	assert(!testType(Json(null), "number"));
	assert(!testType(Json(null), "object"));
	assert(!testType(Json(null), "string"));

	assert(!testType(Json(""), "array"));
	assert(!testType(Json(""), "boolean"));
	assert(!testType(Json(""), "integer"));
	assert(!testType(Json(""), "null"));
	assert(!testType(Json(""), "number"));
	assert(!testType(Json(""), "object"));
	assert(testType(Json(""), "string"));

	assert(!testType(Json("foo"), "array"));
	assert(!testType(Json("foo"), "boolean"));
	assert(!testType(Json("foo"), "integer"));
	assert(!testType(Json("foo"), "null"));
	assert(!testType(Json("foo"), "number"));
	assert(!testType(Json("foo"), "object"));
	assert(testType(Json("foo"), "string"));

	assert(!testType(Json.emptyObject, "array"));
	assert(!testType(Json.emptyObject, "boolean"));
	assert(!testType(Json.emptyObject, "integer"));
	assert(!testType(Json.emptyObject, "null"));
	assert(!testType(Json.emptyObject, "number"));
	assert(testType(Json.emptyObject, "object"));
	assert(!testType(Json.emptyObject, "string"));
	assert(testType(Json(["foo": Json("bar")]), "object"));
}

bool validatorType(Json schema, Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.5.2

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("type" in schema);

	Json value = schema["type"];

	switch (value.type)
	{
		case Json.Type.array:
			//TODO: Check array items for unique
			//TODO: Size of array can not be bigger than 7
			if (value.length == 0)
				throw new Exception("The value of\"type\" keyword MUST NOT be an empty array");
			foreach (size_t i, Json e; value) 
			{
				if (e.type != Json.Type.string)
					throw new Exception("Elements of \"type\" keyword array MUST be strings");
				if (testType(json, e.get!string))
					return true;
			}
			return false;

		case Json.Type.string:
			return testType(json, value.get!string);

		default:
			throw new Exception("The value of \"type\" keyword MUST be either a string or an array of string");
	}
}

unittest {
	try validatorType(Json(["type": Json(42)]), Json(0)); catch (Exception e) assert(e.msg == "The value of \"type\" keyword MUST be either a string or an array of string");
	try validatorType(Json(["type": Json(null)]), Json(0)); catch (Exception e) assert(e.msg == "The value of \"type\" keyword MUST be either a string or an array of string");
	try validatorType(Json(["type": Json(true)]), Json(0)); catch (Exception e) assert(e.msg == "The value of \"type\" keyword MUST be either a string or an array of string");
	try validatorType(Json(["type": Json.emptyObject]), Json(0)); catch (Exception e) assert(e.msg == "The value of \"type\" keyword MUST be either a string or an array of string");

	try validatorType(Json(["type": Json("foo")]), Json("foo")); catch (Exception e) assert(e.msg == "Unknown \"type\" value: foo");

	try validatorType(Json(["type": Json.emptyArray]), Json(0)); catch (Exception e) assert(e.msg == "The value of\"type\" keyword MUST NOT be an empty array");
	try validatorType(Json(["type": Json([Json(42), Json(0)])]), Json(0)); catch (Exception e) assert(e.msg == "Elements of \"type\" keyword array MUST be strings");
	try validatorType(Json(["type": Json([Json(true)])]), Json(0)); catch (Exception e) assert(e.msg == "Elements of \"type\" keyword array MUST be strings");
	try validatorType(Json(["type": Json([Json("foo")])]), Json(0)); catch (Exception e) assert(e.msg == "Unknown \"type\" value: foo");
	
	assert(validatorType(Json(["type": Json("string")]), Json("foo")));
	assert(!validatorType(Json(["type": Json("string")]), Json(42)));
	assert(!validatorType(Json(["type": Json("string")]), Json(null)));
	assert(!validatorType(Json(["type": Json("string")]), Json(false)));

	assert(validatorType(Json(["type": Json("integer")]), Json(42)));
	assert(!validatorType(Json(["type": Json("integer")]), Json(3.14)));
	assert(validatorType(Json(["type": Json("number")]), Json(42)));
	assert(validatorType(Json(["type": Json("number")]), Json(3.14)));

	assert(validatorType(Json(["type": Json([Json("number"), Json("string")])]), Json(3.14)));
	assert(validatorType(Json(["type": Json([Json("number"), Json("string")])]), Json("foo")));
}

bool validatorMinimum(Json schema, Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.1.3

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("minimum" in schema);

	if (!testType(json, "number"))
		return true;

	Json value = schema["minimum"];
	if (!testType(value, "number"))
		throw new Exception("The value of \"minimum\" MUST be a number");

	bool exclusive = false;
	Json exclusiveMinimum = schema["exclusiveMinimum"];
	if (exclusiveMinimum.type() != Json.Type.undefined)
	{
		if (exclusiveMinimum.type() != Json.Type.bool_)
			throw new Exception("The value of \"exclusiveMinimum\" MUST be a boolean");
		exclusive = exclusiveMinimum.get!bool;
	}

	bool floatComprasion = ((value.type == Json.Type.float_) || (json.type == Json.Type.float_));
	if (floatComprasion)
	{
		double v = json.to!double;
		double m = value.to!double;
		if (exclusive)
			return (v > m);
		return (v >= m);
	}

	long v = json.to!long;
	long m = value.to!long;

	if (exclusive)
		return (v > m);
	return (v >= m);
}

bool validateJson(Json schema, Json json)
{
	assert(schema.type == Json.Type.object);

	foreach (string key, value; schema)
	{
		switch (key)
		{
			case "type":
				if (!validatorType(schema, json))
					return false;
				break;

			case "minimum":
				if (!validatorMinimum(schema, json))
					return false;
				break;

			default:
				break;
		}
	}

	return true;
}

unittest {
	Json scheme = parseJsonString(`{"type": "integer", "minimum": 0}`);
	assert(validateJson(scheme, Json(42)));
}
