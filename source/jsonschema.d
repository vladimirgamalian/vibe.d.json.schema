module jsonschema;

//TODO: import only json
import vibe.d;
import std.regex;

private {

version(unittest)
{
	alias j = parseJsonString;
}

void checkObject(const ref Json json, string keyword)
{
	if (json.type != Json.Type.object)
	    throw new Exception("The value of \"" ~ keyword ~ "\" MUST be an object");
}

void checkArray(const ref Json json, string keyword)
{
	if (json.type != Json.Type.array)
	    throw new Exception("The value of \"" ~ keyword ~ "\" MUST be an array");
}

void checkNonEmptyArray(const ref Json json, string keyword)
{
	checkArray(json, keyword);
	if (json.length == 0)
		throw new Exception("The \"" ~ keyword ~ "\" array MUST have at least one element");
}

Json getPropAsObject(const ref Json json, string keyword)
{
	Json result = json[keyword];
	checkObject(result, keyword);
	return result;
}

void setDefaultEmptyObject(ref Json schema, string prop)
{
	if (!(prop in schema))
		schema[prop] = Json.emptyObject;
}

unittest {
	Json j = Json(["foo": Json(42)]);
	assert(j["bar"].type == Json.Type.undefined);
	setDefaultEmptyObject(j, "bar");
	assert(j["bar"].type == Json.Type.object);
}

bool testType(in Json json, string type)
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

	assert(testType(j(`[0, 1]`), "array"));
	assert(testType(j(`["foo", false]`), "array"));

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
	assert(testType(j(`{"foo": "bar"}`), "object"));
}

bool validatorType(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.5.2

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("type" in schema);

	const Json value = schema["type"];

	switch (value.type)
	{
		case Json.Type.array:
			//TODO: Check array items for unique
			//TODO: Size of array can not be bigger than 7
			if (value.length == 0)
				throw new Exception("The value of\"type\" keyword MUST NOT be an empty array");
			foreach (const ref Json e; value) 
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
	try validatorType(j(`{"type": 42}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"type\" keyword MUST be either a string or an array of string");
	try validatorType(j(`{"type": null}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"type\" keyword MUST be either a string or an array of string");
	try validatorType(j(`{"type": true}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"type\" keyword MUST be either a string or an array of string");
	try validatorType(j(`{"type": {}}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"type\" keyword MUST be either a string or an array of string");

	try validatorType(j(`{"type": "foo"}`), Json("foo")); catch (Exception e) assert(e.msg == "Unknown \"type\" value: foo");

	try validatorType(j(`{"type": []}`), Json(0)); catch (Exception e) assert(e.msg == "The value of\"type\" keyword MUST NOT be an empty array");
	try validatorType(j(`{"type": [42, 0]}`), Json(0)); catch (Exception e) assert(e.msg == "Elements of \"type\" keyword array MUST be strings");
	try validatorType(j(`{"type": [true]}`), Json(0)); catch (Exception e) assert(e.msg == "Elements of \"type\" keyword array MUST be strings");
	try validatorType(j(`{"type": ["foo"]}`), Json(0)); catch (Exception e) assert(e.msg == "Unknown \"type\" value: foo");
	
	assert(validatorType(j(`{"type": "string"}`), Json("foo")));
	assert(!validatorType(j(`{"type": "string"}`), Json(42)));
	assert(!validatorType(j(`{"type": "string"}`), Json(null)));
	assert(!validatorType(j(`{"type": "string"}`), Json(false)));

	assert(validatorType(j(`{"type": "integer"}`), Json(42)));
	assert(!validatorType(j(`{"type": "integer"}`), Json(3.14)));
	assert(validatorType(j(`{"type": "number"}`), Json(42)));
	assert(validatorType(j(`{"type": "number"}`), Json(3.14)));

	assert(validatorType(j(`{"type": ["number", "string"]}`), Json(3.14)));
	assert(validatorType(j(`{"type": ["number", "string"]}`), Json("foo")));
}

bool validatorMinimum(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.1.3

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("minimum" in schema);

	if (!testType(json, "number"))
		return true;

	const Json value = schema["minimum"];
	if (!testType(value, "number"))
		throw new Exception("The value of \"minimum\" MUST be a number");

	bool exclusive = false;
	const Json exclusiveMinimum = schema["exclusiveMinimum"];
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

unittest {
	try validatorMinimum(j(`{"minimum": false}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"minimum\" MUST be a number");
	assert(validatorMinimum(j(`{"minimum": 0}`), Json(0)));
	assert(validatorMinimum(j(`{"minimum": 0}`), Json(1)));
	assert(!validatorMinimum(j(`{"minimum": 0}`), Json(-1)));

	assert(validatorMinimum(j(`{"minimum": 0}`), Json(1)));
	assert(!validatorMinimum(j(`{"minimum": 0}`), Json(-1)));

	assert(validatorMinimum(j(`{"minimum": 1}`), Json(2)));
	assert(!validatorMinimum(j(`{"minimum": 1}`), Json(0)));
	assert(validatorMinimum(j(`{"minimum": 1.1}`), Json(2)));
	assert(!validatorMinimum(j(`{"minimum": 1.1}`), Json(0)));
	assert(validatorMinimum(j(`{"minimum": 1}`), Json(2.1)));
	assert(!validatorMinimum(j(`{"minimum": 1}`), Json(0.1)));
	assert(validatorMinimum(j(`{"minimum": 1.1}`), Json(2.1)));
	assert(!validatorMinimum(j(`{"minimum": 1.1}`), Json(0.1)));

	try validatorMinimum(j(`{"minimum": 0, "exclusiveMinimum": null}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"exclusiveMinimum\" MUST be a boolean");
	try validatorMinimum(j(`{"minimum": 0, "exclusiveMinimum": 42}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"exclusiveMinimum\" MUST be a boolean");
	assert(validatorMinimum(j(`{"minimum": 0, "exclusiveMinimum": false}`), Json(0)));
	assert(!validatorMinimum(j(`{"minimum": 0, "exclusiveMinimum": true}`), Json(0)));
}

bool validatorExclusiveMinimum(in Json schema, in Json json)
{
	// covered in validatorMinimum, just check minimum field presense

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("exclusiveMinimum" in schema);

	if (!("minimum" in schema))
		throw new Exception("If \"exclusiveMinimum\" is present, \"minimum\" MUST also be present.");

	return true;
}

unittest
{
	try validatorExclusiveMinimum(j(`{"exclusiveMinimum": false}`), Json(0)); catch (Exception e) assert(e.msg == "If \"exclusiveMinimum\" is present, \"minimum\" MUST also be present.");
	validatorExclusiveMinimum(j(`{"minimum": 1, "exclusiveMinimum": false}`), Json(42));
}

bool validatorMaximum(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.1.2

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("maximum" in schema);

	if (!testType(json, "number"))
		return true;

	const Json value = schema["maximum"];
	if (!testType(value, "number"))
		throw new Exception("The value of \"maximum\" MUST be a number");

	bool exclusive = false;
	const Json exclusiveMaximum = schema["exclusiveMaximum"];
	if (exclusiveMaximum.type() != Json.Type.undefined)
	{
		if (exclusiveMaximum.type() != Json.Type.bool_)
			throw new Exception("The value of \"exclusiveMaximum\" MUST be a boolean");
		exclusive = exclusiveMaximum.get!bool;
	}

	bool floatComprasion = ((value.type == Json.Type.float_) || (json.type == Json.Type.float_));
	if (floatComprasion)
	{
		double v = json.to!double;
		double m = value.to!double;
		if (exclusive)
			return (v < m);
		return (v <= m);
	}

	long v = json.to!long;
	long m = value.to!long;

	if (exclusive)
		return (v < m);
	return (v <= m);
}

unittest {
	try validatorMaximum(j(`{"maximum": false}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"maximum\" MUST be a number");
	assert(validatorMaximum(j(`{"maximum": 0}`), Json(0)));
	assert(validatorMaximum(j(`{"maximum": 0}`), Json(-1)));
	assert(!validatorMaximum(j(`{"maximum": 0}`), Json(1)));

	assert(validatorMaximum(j(`{"maximum": 2}`), Json(1)));
	assert(!validatorMaximum(j(`{"maximum": 2}`), Json(3)));

	assert(validatorMaximum(j(`{"maximum": 1}`), Json(0)));
	assert(!validatorMaximum(j(`{"maximum": 1}`), Json(2)));
	assert(validatorMaximum(j(`{"maximum": 1.1}`), Json(0)));
	assert(!validatorMaximum(j(`{"maximum": 1.1}`), Json(2)));
	assert(validatorMaximum(j(`{"maximum": 1}`), Json(0.1)));
	assert(!validatorMaximum(j(`{"maximum": 1}`), Json(2.1)));
	assert(validatorMaximum(j(`{"maximum": 1.1}`), Json(0.1)));
	assert(!validatorMaximum(j(`{"maximum": 1.1}`), Json(2.1)));

	try validatorMaximum(j(`{"maximum": 0, "exclusiveMaximum": null}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"exclusiveMaximum\" MUST be a boolean");
	try validatorMaximum(j(`{"maximum": 0, "exclusiveMaximum": 42}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"exclusiveMaximum\" MUST be a boolean");
	assert(validatorMaximum(j(`{"maximum": 1, "exclusiveMaximum": false}`), Json(1)));
	assert(!validatorMaximum(j(`{"maximum": 1, "exclusiveMaximum": true}`), Json(1)));
}

bool validatorExclusiveMaximum(in Json schema, in Json json)
{
	// covered in validatorMinimum, just check minimum field presense

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("exclusiveMaximum" in schema);

	if (!("maximum" in schema))
		throw new Exception("If \"exclusiveMaximum\" is present, \"maximum\" MUST also be present.");

	return true;
}

unittest
{
	try validatorExclusiveMaximum(j(`{"exclusiveMaximum": false}`), Json(0)); catch (Exception e) assert(e.msg == "If \"exclusiveMaximum\" is present, \"maximum\" MUST also be present.");
	validatorExclusiveMaximum(j(`{"maximum": 1, "exclusiveMaximum": false}`), Json(42));
}

bool validatorMultipleOf(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.1.1

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("multipleOf" in schema);

	const Json multipleOf = schema["multipleOf"];
	if (!testType(multipleOf, "number"))
		throw new Exception("The value of \"multipleOf\" MUST be a number");
	
	bool floatComprasion = ((multipleOf.type == Json.Type.float_) || (json.type == Json.Type.float_));
	if (floatComprasion)
	{
		double m = multipleOf.to!double;
		if (m <= 0)
			throw new Exception("The value of \"multipleOf\" MUST be greater than 0");
		if (!testType(json, "number"))
			return true;
		double v = json.to!double;
		//TODO: tolerance
		double k = v / m;
		return ((k - std.math.trunc(k)) < 0.0000001);
	}
	
	long m = multipleOf.to!long;
	if (m <= 0)
		throw new Exception("The value of \"multipleOf\" MUST be greater than 0");
	if (!testType(json, "number"))
		return true;
	long v = json.to!long;
	return ((v % m) == 0);
}

unittest {
	try validatorMultipleOf(j(`{"multipleOf": false}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"multipleOf\" MUST be a number");
	try validatorMultipleOf(j(`{"multipleOf": "foo"}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"multipleOf\" MUST be a number");
	try validatorMultipleOf(j(`{"multipleOf": null}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"multipleOf\" MUST be a number");

	try validatorMultipleOf(j(`{"multipleOf": 0}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"multipleOf\" MUST be greater than 0");
	try validatorMultipleOf(j(`{"multipleOf": -1}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"multipleOf\" MUST be greater than 0");
	try validatorMultipleOf(j(`{"multipleOf": 0.0}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"multipleOf\" MUST be greater than 0");
	try validatorMultipleOf(j(`{"multipleOf": -1.1}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"multipleOf\" MUST be greater than 0");

	assert(validatorMultipleOf(j(`{"multipleOf": 2}`), Json("foo")));
	assert(validatorMultipleOf(j(`{"multipleOf": 2}`), Json(false)));
	assert(validatorMultipleOf(j(`{"multipleOf": 2}`), Json(0)));
	assert(validatorMultipleOf(j(`{"multipleOf": 2}`), Json(2)));
	assert(validatorMultipleOf(j(`{"multipleOf": 2}`), Json(-2)));
	assert(validatorMultipleOf(j(`{"multipleOf": 2}`), Json(4)));
	assert(!validatorMultipleOf(j(`{"multipleOf": 2}`), Json(3)));
	assert(!validatorMultipleOf(j(`{"multipleOf": 2}`), Json(-3)));

	assert(validatorMultipleOf(j(`{"multipleOf": 2.0}`), Json(0)));
	assert(validatorMultipleOf(j(`{"multipleOf": 2.0}`), Json(2)));
	assert(validatorMultipleOf(j(`{"multipleOf": 2.0}`), Json(-2)));

	assert(validatorMultipleOf(j(`{"multipleOf": 2}`), Json(0.0)));
	assert(validatorMultipleOf(j(`{"multipleOf": 2}`), Json(2.0)));
	assert(validatorMultipleOf(j(`{"multipleOf": 2}`), Json(-2.0)));

	assert(validatorMultipleOf(j(`{"multipleOf": 2.0}`), Json(0.0)));
	assert(validatorMultipleOf(j(`{"multipleOf": 2.0}`), Json(2.0)));
	assert(validatorMultipleOf(j(`{"multipleOf": 2.0}`), Json(-2.0)));
}

bool validatorMinLength(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.2.2

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("minLength" in schema);

	const Json minLength = schema["minLength"];
	if (!testType(minLength, "integer"))
		throw new Exception("The value of \"minLength\" MUST be an integer");
	long m = minLength.to!long;
	if (m < 0)
		throw new Exception("The value of \"minLength\" MUST be greater than, or equal to, 0");

	if (json.type != Json.Type.string)
		return true;

	return (json.length >= m);
}

unittest {
	try validatorMinLength(j(`{"minLength": false}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"minLength\" MUST be an integer");
	try validatorMinLength(j(`{"minLength": "foo"}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"minLength\" MUST be an integer");
	try validatorMinLength(j(`{"minLength": 1.2}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"minLength\" MUST be an integer");
	try validatorMinLength(j(`{"minLength": -1.2}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"minLength\" MUST be an integer");
	try validatorMinLength(j(`{"minLength": -1}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"minLength\" MUST be greater than, or equal to, 0");

	assert(validatorMinLength(j(`{"minLength": 0}`), Json(0)));
	assert(validatorMinLength(j(`{"minLength": 0}`), Json(false)));

	assert(validatorMinLength(j(`{"minLength": 0}`), Json("")));
	assert(!validatorMinLength(j(`{"minLength": 1}`), Json("")));
	assert(validatorMinLength(j(`{"minLength": 1}`), Json("1")));
	assert(validatorMinLength(j(`{"minLength": 3}`), Json("foo")));
	assert(!validatorMinLength(j(`{"minLength": 4}`), Json("foo")));
}

bool validatorMaxLength(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.2.1

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("maxLength" in schema);

	const Json maxLength = schema["maxLength"];
	if (!testType(maxLength, "integer"))
	    throw new Exception("The value of \"maxLength\" MUST be an integer");
	long m = maxLength.to!long;
	if (m < 0)
		throw new Exception("The value of \"maxLength\" MUST be greater than, or equal to, 0");

	if (json.type != Json.Type.string)
		return true;

	return (json.length <= m);
}

unittest {
	try validatorMaxLength(j(`{"maxLength": false}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"maxLength\" MUST be an integer");
	try validatorMaxLength(j(`{"maxLength": "foo"}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"maxLength\" MUST be an integer");
	try validatorMaxLength(j(`{"maxLength": 1.2}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"maxLength\" MUST be an integer");
	try validatorMaxLength(j(`{"maxLength": -1.2}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"maxLength\" MUST be an integer");
	try validatorMaxLength(j(`{"maxLength": -1}`), Json(0)); catch (Exception e) assert(e.msg == "The value of \"maxLength\" MUST be greater than, or equal to, 0");

	assert(validatorMaxLength(j(`{"maxLength": 0}`), Json(0)));
	assert(validatorMaxLength(j(`{"maxLength": 0}`), Json(false)));
	
	assert(validatorMaxLength(j(`{"maxLength": 0}`), Json("")));
	assert(!validatorMaxLength(j(`{"maxLength": 0}`), Json("0")));
	assert(!validatorMaxLength(j(`{"maxLength": 0}`), Json("foo")));
	assert(!validatorMaxLength(j(`{"maxLength": 2}`), Json("foo")));
	assert(validatorMaxLength(j(`{"maxLength": 3}`), Json("foo")));
}

bool validatorProperties(in Json schema_, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.8.3
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.4.4

	Json schema = schema_;

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);

	// set some default values
	setDefaultEmptyObject(schema, "properties");
	setDefaultEmptyObject(schema, "patternProperties");
	setDefaultEmptyObject(schema, "additionalProperties");

	const Json properties = getPropAsObject(schema, "properties");
	const Json patternProperties = getPropAsObject(schema, "patternProperties");

	Json additionalProperties = schema["additionalProperties"];
	if ((additionalProperties.type != Json.Type.object) && (additionalProperties.type != Json.Type.bool_))
		throw new Exception("The value of \"additionalProperties\" MUST be an object or boolean");

	if (json.type != Json.Type.object)
		return true;

	bool allowAdditionalPropertites = true;
	if (additionalProperties.type == Json.Type.bool_)
	{
		allowAdditionalPropertites = additionalProperties.get!bool;
		additionalProperties = Json.emptyObject;
	}

	foreach (string k, v; json)
	{
		// all schemas to pass
		Json[] schemas;
		
		// first, add a schema from "properties"
		if (k in properties)
			schemas ~= properties[k];

		// next, add all matched schemas from "patternProperties"
		foreach (string r, v; patternProperties)
			if (matchFirst(k, r))
				schemas ~= v;

		// then, if schemas have not been found and additionalProperties allowed, add "additionalProperties"
		if (allowAdditionalPropertites && (schemas.length == 0))
			schemas ~= additionalProperties;

		if (schemas.length == 0)
			return false;

		// now test all schemas
		foreach (s; schemas)
			if (!validateJsonRecursively(s, v))
				return false;
	}

	return true;
}

unittest {
	Json schema = j(`{"properties": {"foo": { "type": "integer" }, "bar": { "type": "string" }}}`);
	assert(validatorProperties(schema, j(`{"foo": 42, "bar": "baz"}`)));
	assert(!validatorProperties(schema, j(`{"foo": "s", "bar": "baz"}`)));
	assert(!validatorProperties(schema, j(`{"foo": 42, "bar": 0}`)));

	//TODO: more tests
}

bool validatorRequired(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.4.3

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("required" in schema);

	//TODO: replace with check functions
	const Json required = schema["required"];
	if (required.type != Json.Type.array)
	    throw new Exception("The value of \"required\" MUST be an array");
	if (required.length == 0)
		throw new Exception("The \"required\" array MUST have at least one element");

	//TODO: test required items for unique

	if (json.type != Json.Type.object)
		return true;

	foreach (const ref Json e; required)
	{
		if (e.type != Json.Type.string)
			throw new Exception("Elements of \"required\" array MUST be strings");
		if (!((e.to!string) in json))
			return false;
	}

	return true;
}

unittest {
	//TODO: more tests

	Json schema = j(`{"required": ["foo"]}`);
	assert(validatorRequired(schema, j(`{"foo": 42}`)));
	assert(validatorRequired(schema, j(`{"foo": false}`)));
	assert(validatorRequired(schema, j(`{"foo": 42, "bar": "baz"}`)));
	assert(!validatorRequired(schema, j(`{"bar": "baz"}`)));
	assert(!validatorRequired(schema, j(`{"baz": 42, "bar": "baz"}`)));
}

bool validatorItems(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.3.1

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("items" in schema);

	const Json items = schema["items"];
	if ((items.type != Json.Type.object) && (items.type != Json.Type.array))
	    throw new Exception("The value of \"items\" MUST be either an object or an array");

	const Json additionalItems = schema["additionalItems"];
	if ((additionalItems.type != Json.Type.undefined) && (additionalItems.type != Json.Type.bool_) && (additionalItems.type != Json.Type.object))
	    throw new Exception("The value of \"additionalItems\" MUST be either a boolean or an object.");

	if (json.type != Json.Type.array)
		return true;

	bool addItems = true;
	if (additionalItems.type == Json.Type.bool_)
		addItems = additionalItems.to!bool;

	if (items.type == Json.Type.object)
	{
		if (additionalItems.type != Json.Type.undefined)
			logWarn("When \"items\" is a single schema, the \"additionalItems\" keyword is meaningless, and it should not be used.");

		foreach (const ref Json e; json)
			if (!validateJsonRecursively(items, e))
				return false;
	}

	if (items.type == Json.Type.array)
	{
		foreach (size_t i, const ref Json e; json)
		{
			if (i < items.length)
			{
				Json subSchema = items[i];

				if (subSchema.type != Json.Type.object)
					throw new Exception("items of \"items\" array MUST be objects");
				if (!validateJsonRecursively(subSchema, e))
					return false;
			}
			else if (addItems)
			{
				if (additionalItems.type == Json.Type.object)
					if (!validateJsonRecursively(additionalItems, e))
						return false;
			}
			else
				return false;
		}
	}

	return true;
}

unittest {
	//TODO: more tests
}

bool validatorMinItems(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.3.3

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("minItems" in schema);

	const Json minItems = schema["minItems"];
	if (!testType(minItems, "integer"))
	    throw new Exception("The value of \"minItems\" MUST be an integer");
	long m = minItems.to!long;
	if (m < 0)
		throw new Exception("The value of \"minItems\" MUST be greater than, or equal to, 0");

	if (json.type != Json.Type.array)
		return true;

	return (json.length >= m);
}

unittest {
	//TODO: more tests
}

bool validatorMaxItems(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.3.2

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("maxItems" in schema);

	const Json maxItems = schema["maxItems"];
	if (!testType(maxItems, "integer"))
	    throw new Exception("The value of \"maxItems\" MUST be an integer");
	long m = maxItems.to!long;
	if (m < 0)
		throw new Exception("The value of \"maxItems\" MUST be greater than, or equal to, 0");

	if (json.type != Json.Type.array)
		return true;

	return (json.length <= m);
}

unittest {
	//TODO: more tests
}

bool validatorUniqueItems(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.3.4

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("uniqueItems" in schema);

	const Json uniqueItems = schema["uniqueItems"];
	if (uniqueItems.type != Json.Type.bool_)
	    throw new Exception("The value of \"uniqueItems\" MUST be a boolean");

	if (json.type != Json.Type.array)
		return true;

	if (uniqueItems.get!bool)
	{
		//TODO: use RedBlackTree
		bool[string] a;
		foreach (const ref Json e; json)
		{
			//TODO: check if string with qoutes
			string s = e.toString;
			if (s in a)
				return false;
			a[s] = true;
		}
	}

	return true;
}

unittest {
	//TODO: more tests
}

bool validatorMinProperties(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.4.2

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("minProperties" in schema);

	const Json minProperties = schema["minProperties"];
	if (!testType(minProperties, "integer"))
	    throw new Exception("The value of \"minProperties\" MUST be an integer");
	long m = minProperties.to!long;
	if (m < 0)
		throw new Exception("The value of \"minProperties\" MUST be greater than, or equal to, 0");

	if (json.type != Json.Type.object)
		return true;

	return (json.length >= m);
}

unittest {
	//TODO: more tests
}

bool validatorMaxProperties(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.4.1

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("maxProperties" in schema);

	const Json maxProperties = schema["maxProperties"];
	if (!testType(maxProperties, "integer"))
	    throw new Exception("The value of \"maxProperties\" MUST be an integer");
	long m = maxProperties.to!long;
	if (m < 0)
		throw new Exception("The value of \"maxProperties\" MUST be greater than, or equal to, 0");

	if (json.type != Json.Type.object)
		return true;

	return (json.length <= m);
}

unittest {
	//TODO: more tests
}

bool validatorAnyOf(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.5.4

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("anyOf" in schema);

	const Json anyOf = schema["anyOf"];
	checkNonEmptyArray(anyOf, "anyOf");

	foreach (const ref Json e; anyOf)
	{
		if (e.type != Json.Type.object)
			throw new Exception("items of \"anyOf\" array MUST be objects");

		if (validateJsonRecursively(e, json))
			return true;
	}

	return false;
}

unittest {
	//TODO: more tests
}

bool validatorAllOf(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.5.3

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("allOf" in schema);

	const Json allOf = schema["allOf"];
	checkNonEmptyArray(allOf, "allOf");

	foreach (const ref Json e; allOf)
	{
		if (e.type != Json.Type.object)
			throw new Exception("items of \"allOf\" array MUST be objects");

		if (!validateJsonRecursively(e, json))
			return false;
	}

	return true;
}

unittest {
	//TODO: more tests

}
bool validatorOneOf(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.5.5

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("oneOf" in schema);

	const Json oneOf = schema["oneOf"];
	checkNonEmptyArray(oneOf, "oneOf");

	int valid = 0;
	foreach (const ref Json e; oneOf)
	{
		if (e.type != Json.Type.object)
			throw new Exception("items of \"oneOf\" array MUST be objects");

		if (validateJsonRecursively(e, json))
		{
			valid++;
			if (valid > 1)
				break;
		}
	}

	return (valid == 1);
}

unittest {
	//TODO: more tests

}
bool validatorNot(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.5.6

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("not" in schema);

	const Json not = schema["not"];
	if (not.type != Json.Type.object)
		throw new Exception("The value of \"not\" MUST be an object");

	return !validateJsonRecursively(not, json);
}

unittest {
	//TODO: more tests
}

bool validatorEnum(in Json schema, in Json json)
{
	// http://json-schema.org/latest/json-schema-validation.html#rfc.section.5.5.1

	assert(schema.type == Json.Type.object);
	assert(json.type != Json.Type.undefined);
	assert("enum" in schema);

	const Json enum_ = schema["enum"];
	checkNonEmptyArray(enum_, "enum");

	foreach (const ref Json e; enum_)
		if (e == json)
			return true;

	return false;
}

unittest {
	//TODO: more tests
}

bool validateJsonRecursively(in Json schema, in Json json)
{
	assert(schema.type == Json.Type.object);

	if (!validatorProperties(schema, json))
		return false;

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

			case "exclusiveMinimum":
				if (!validatorExclusiveMinimum(schema, json))
					return false;
				break;

			case "maximum":
				if (!validatorMaximum(schema, json))
					return false;
				break;

			case "exclusiveMaximum":
				if (!validatorExclusiveMaximum(schema, json))
					return false;
				break;

			case "multipleOf":
				if (!validatorMultipleOf(schema, json))
					return false;
				break;

			case "minLength":
				if (!validatorMinLength(schema, json))
					return false;
				break;

			case "maxLength":
				if (!validatorMaxLength(schema, json))
					return false;
				break;

			case "required":
				if (!validatorRequired(schema, json))
					return false;
				break;

			case "items":
				if (!validatorItems(schema, json))
					return false;
				break;

			case "minItems":
				if (!validatorMinItems(schema, json))
					return false;
				break;

			case "maxItems":
				if (!validatorMaxItems(schema, json))
					return false;
				break;

			case "uniqueItems":
				if (!validatorUniqueItems(schema, json))
					return false;
				break;

			case "minProperties":
				if (!validatorMinProperties(schema, json))
					return false;
				break;

			case "maxProperties":
				if (!validatorMaxProperties(schema, json))
					return false;
				break;

			case "anyOf":
				if (!validatorAnyOf(schema, json))
					return false;
				break;

			case "allOf":
				if (!validatorAllOf(schema, json))
					return false;
				break;

			case "oneOf":
				if (!validatorOneOf(schema, json))
					return false;
				break;

			case "not":
				if (!validatorNot(schema, json))
					return false;
				break;

			case "enum":
				if (!validatorEnum(schema, json))
					return false;
				break;
	
			case "pattern":
			case "format":
			case "dependencies":
				assert(0, "todo");

			default:
				break;
		}
	}

	return true;
}

} // private

bool validateJson(in Json schema, in Json json)
{
	return validateJsonRecursively(schema, json);
}

unittest {
	Json scheme = parseJsonString(`{"type": "integer", "minimum": 0}`);
	assert(validateJson(scheme, Json(42)));
}
