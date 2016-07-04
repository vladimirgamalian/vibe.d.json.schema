module jsonschema;

import vibe.d;

bool validateJson(Json scheme, Json json)
{
	string typeString = scheme["type"].get!string;
	Json.Type jsonType = json.type();

	// not supported yet
	assert(!("enum" in scheme));
	assert(!("anyOf" in scheme));
	assert(!("allOf" in scheme));
	assert(!("oneOf" in scheme));
	assert(!("not" in scheme));
	assert(!("definitions" in scheme));
	assert(!("$ref" in scheme));

	switch (typeString)
	{
		case "number":
		case "integer":

			assert(!("multipleOf" in scheme));

			bool isInteger = ((jsonType == Json.Type.int_) || (jsonType == Json.Type.bigInt));
			if ((!isInteger) && ((jsonType != Json.Type.float_) || (typeString == "integer")))
				return false;

			bool exclMin = false;
			Json exclusiveMinimum = scheme["exclusiveMinimum"];
			if (exclusiveMinimum.type() != Json.Type.undefined)
				exclMin = exclusiveMinimum.get!bool;

			bool exclMax = false;
			Json exclusiveMaximum = scheme["exclusiveMaximum"];
			if (exclusiveMaximum.type() != Json.Type.undefined)
				exclMax = exclusiveMaximum.get!bool;

			Json minimum = scheme["minimum"];
			Json maximum = scheme["maximum"];
			bool floatComprasion = ((jsonType == Json.Type.float_) || (minimum.type() == Json.Type.float_) || (maximum.type() == Json.Type.float_));

			if (floatComprasion)
			{
				double v = json.to!double;
				if (minimum.type() != Json.Type.undefined)
				{
					double min = minimum.to!double;
					if (exclMin)
					{
						if (v <= min)
							return false;
					}
					else
					{
						if (v < min)
							return false;
					}
				}
				if (maximum.type() != Json.Type.undefined)
				{
					double max = maximum.to!double;
					if (exclMax)
					{
						if (v >= max)
							return false;
					}
					else
					{
						if (v > max)
							return false;
					}
				}
			}
			else
			{
				long v = json.get!long;
				if (minimum.type() != Json.Type.undefined)
				{
					long min = minimum.get!long;
					if (exclMin)
					{
						if (v <= min)
							return false;
					}
					else
					{
						if (v < min)
							return false;
					}
				}
				if (maximum.type() != Json.Type.undefined)
				{
					long max = maximum.get!long;
					if (exclMax)
					{
						if (v >= max)
							return false;
					}
					else
					{
						if (v > max)
							return false;
					}
				}
			}

			break;

		case "string":

			assert(!("pattern" in scheme));
			assert(!("format" in scheme));

			if (jsonType != Json.Type.string)
				return false;

			Json minLength = scheme["minLength"];
			if (minLength.type() != Json.Type.undefined)
			{
				long min = minLength.get!long;
				if (json.length < min)
					return false;
			}

			Json maxLength = scheme["maxLength"];
			if (maxLength.type() != Json.Type.undefined)
			{
				long max = maxLength.get!long;
				if (json.length > max)
					return false;
			}

			break;

		case "object":

			assert(!("minProperties" in scheme));
			assert(!("maxProperties" in scheme));
			assert(!("dependencies" in scheme));
			assert(!("patternProperties" in scheme));

			if (jsonType != Json.Type.object)
				return false;

			bool additionalPropertiesAllowed = true;
			Json additionalProperties = scheme["additionalProperties"];
			if (additionalProperties.type() != Json.Type.undefined)
				additionalPropertiesAllowed = additionalProperties.get!bool;

			Json required = scheme["required"];
			if (required.type() != Json.Type.undefined)
			{
				assert(required.type() == Json.Type.array);
				foreach(Json j; required)
					if (!((j.get!string) in json))
						return false;
			}

			Json prop = scheme["properties"];
			assert((prop.type() == Json.Type.object) || (prop.type() == Json.Type.undefined));

			if (prop.type() == Json.Type.object)
			{
				foreach (string k, Json v; json)
				{
					Json p = prop[k];

					if (p.type() == Json.Type.undefined)
					{
						if (!additionalPropertiesAllowed)
							return false;
					}
					else
					{
						if (!validateJson(p, v))
							return false;
					}
				}
			}

			break;

		case "array":

			assert(!("additionalItems" in scheme));
			assert(!("uniqueItems" in scheme));

			if (jsonType != Json.Type.array)
				return false;

			Json minItems = scheme["minItems"];
			if (minItems.type() != Json.Type.undefined)
			{
				long min = minItems.get!long;
				if (json.length < min)
					return false;
			}

			Json maxItems = scheme["maxItems"];
			if (minItems.type() != Json.Type.undefined)
			{
				long max = maxItems.get!long;
				if (json.length > max)
					return false;
			}

			Json items = scheme["items"];
			switch (items.type())
			{
				case Json.Type.undefined:
					break;
				case Json.Type.object:
					foreach (Json i; json)
						if (!validateJson(items, i))
							return false;
					break;
				case Json.Type.array:
					assert(0);
				default:
					assert(0);
			}

			break;

		case "null":
			if (jsonType != Json.Type.null_)
				return false;
			break;

		case "boolean":
			if (jsonType != Json.Type.bool_)
				return false;
			break;

		default:
			assert(0);
	}

	return true;
}

unittest {
	Json scheme = parseJsonString(`{"type": "null"}`);
	assert(validateJson(scheme, Json(null)));
	assert(!validateJson(scheme, Json(false)));
	assert(!validateJson(scheme, Json(true)));
	assert(!validateJson(scheme, Json(1)));
	assert(!validateJson(scheme, Json(1.5)));
	assert(!validateJson(scheme, Json("1")));
	assert(!validateJson(scheme, Json.emptyArray));
	assert(!validateJson(scheme, Json.emptyObject));
}

unittest {
	Json scheme = parseJsonString(`{"type": "boolean"}`);
	assert(!validateJson(scheme, Json(null)));
	assert(validateJson(scheme, Json(false)));
	assert(validateJson(scheme, Json(true)));
	assert(!validateJson(scheme, Json(1)));
	assert(!validateJson(scheme, Json(1.5)));
	assert(!validateJson(scheme, Json("1")));
	assert(!validateJson(scheme, Json.emptyArray));
	assert(!validateJson(scheme, Json.emptyObject));
}

unittest {
	Json scheme = parseJsonString(`{"type": "number"}`);
	assert(!validateJson(scheme, Json(null)));
	assert(!validateJson(scheme, Json(false)));
	assert(!validateJson(scheme, Json(true)));
	assert(validateJson(scheme, Json(1)));
	assert(validateJson(scheme, Json(1.5)));
	assert(!validateJson(scheme, Json("1")));
	assert(!validateJson(scheme, Json.emptyArray));
	assert(!validateJson(scheme, Json.emptyObject));
}

unittest {
	Json scheme = parseJsonString(`{"type": "integer"}`);
	assert(!validateJson(scheme, Json(null)));
	assert(!validateJson(scheme, Json(false)));
	assert(!validateJson(scheme, Json(true)));
	assert(validateJson(scheme, Json(1)));
	assert(!validateJson(scheme, Json(1.5)));
	assert(!validateJson(scheme, Json("1")));
	assert(!validateJson(scheme, Json.emptyArray));
	assert(!validateJson(scheme, Json.emptyObject));
}

unittest {
	Json scheme = parseJsonString(`{"type": "string"}`);
	assert(!validateJson(scheme, Json(null)));
	assert(!validateJson(scheme, Json(false)));
	assert(!validateJson(scheme, Json(true)));
	assert(!validateJson(scheme, Json(1)));
	assert(!validateJson(scheme, Json(1.5)));
	assert(validateJson(scheme, Json("1")));
	assert(!validateJson(scheme, Json.emptyArray));
	assert(!validateJson(scheme, Json.emptyObject));
}

unittest {
	Json scheme = parseJsonString(`{"type": "object"}`);
	assert(!validateJson(scheme, Json(null)));
	assert(!validateJson(scheme, Json(false)));
	assert(!validateJson(scheme, Json(true)));
	assert(!validateJson(scheme, Json(1)));
	assert(!validateJson(scheme, Json(1.5)));
	assert(!validateJson(scheme, Json("1")));
	assert(!validateJson(scheme, Json.emptyArray));
	assert(validateJson(scheme, Json.emptyObject));
}

unittest {
	Json scheme = parseJsonString(`{"type": "array"}`);
	assert(!validateJson(scheme, Json(null)));
	assert(!validateJson(scheme, Json(false)));
	assert(!validateJson(scheme, Json(true)));
	assert(!validateJson(scheme, Json(1)));
	assert(!validateJson(scheme, Json(1.5)));
	assert(!validateJson(scheme, Json("1")));
	assert(validateJson(scheme, Json.emptyArray));
	assert(!validateJson(scheme, Json.emptyObject));
}

unittest {
	Json scheme = parseJsonString(`{"type": "string", "minLength": 2, "maxLength": 3}`);
	assert(!validateJson(scheme, Json("1")));
	assert(validateJson(scheme, Json("12")));
	assert(validateJson(scheme, Json("123")));
	assert(!validateJson(scheme, Json("1234")));
}

unittest {
	Json j = parseJsonString(`{"foo": 42, "bar": "baz"}`);
	assert(!validateJson(parseJsonString(`{"type": "string"}`), j));
	assert(!validateJson(parseJsonString(`{"type": "array"}`), j));

	Json scheme = parseJsonString(`
								  {
								  "type": "object",
								  "properties": {
								  "foo": { "type": "integer" },
								  "bar": { "type": "string" }
								  }
								  }
								  `);
	assert(validateJson(scheme, j));
	assert(validateJson(scheme, parseJsonString(`{"fee": 42, "bar": "baz"}`)));
	assert(!validateJson(scheme, parseJsonString(`{"foo": "s", "bar": "baz"}`)));
	assert(!validateJson(scheme, parseJsonString(`{"foo": 42, "bar": 0}`)));
}

unittest {
	Json scheme = parseJsonString(`
								  {
								  "type": "object",
								  "required": ["foo", "bar"],
								  "properties": {
								  "foo": { "type": "integer" },
								  "bar": { "type": "string" },
								  "baz": { "type": "boolean" },
								  }
								  }
								  `);
	assert(validateJson(scheme, parseJsonString(`{"foo": 42, "bar": "baz"}`)));
	assert(validateJson(scheme, parseJsonString(`{"foo": 42, "bar": "777", "baz": false}`)));
	assert(!validateJson(scheme, parseJsonString(`{"foo": 42, "baz": true}`)));
	assert(!validateJson(scheme, parseJsonString(`{"bar": "777"}`)));
}

unittest {
	Json scheme = parseJsonString(`
								  {
								  "type": "object",
								  "properties": {
								  "foo": { "type": "integer" },
								  "bar": { "type": "string" }
								  }
								  }
								  `);
	assert(validateJson(scheme, parseJsonString(`{"foo": 42, "bar": "baz"}`)));
	assert(validateJson(scheme, parseJsonString(`{"foo": 42, "bar": "baz", "value": 0}`)));
}

unittest {
	Json scheme = parseJsonString(`
								  {
								  "type": "object",
								  "additionalProperties": false,
								  "properties": {
								  "foo": { "type": "integer" },
								  "bar": { "type": "string" }
								  }
								  }
								  `);
	assert(validateJson(scheme, parseJsonString(`{"foo": 42, "bar": "baz"}`)));
	assert(!validateJson(scheme, parseJsonString(`{"foo": 42, "bar": "baz", "value": 0}`)));
}

unittest {
	Json j = parseJsonString(`[1, 2]`);
	assert(!validateJson(parseJsonString(`{"type": "string"}`), j));
	assert(!validateJson(parseJsonString(`{"type": "object"}`), j));

	Json scheme = parseJsonString(`
		{
			"type": "array"
		}
	`);
	assert(validateJson(scheme, j));
	assert(validateJson(scheme, parseJsonString(`[]`)));
	assert(!validateJson(scheme, parseJsonString(`{"foo": 42}`)));
	assert(validateJson(scheme, parseJsonString(`["1", "2"]`)));
	assert(validateJson(scheme, parseJsonString(`["1", 2, {}]`)));
	assert(validateJson(scheme, parseJsonString(`["1", 2, {"foo": 42}]`)));
}

unittest {
	Json scheme = parseJsonString(`
								  {
								  "type": "array",
								  "items": {
								  "type": "integer"
								  }
								  }
								  `);
	assert(validateJson(scheme, parseJsonString(`[]`)));
	assert(validateJson(scheme, parseJsonString(`[1]`)));
	assert(validateJson(scheme, parseJsonString(`[1, 2]`)));
	assert(!validateJson(scheme, parseJsonString(`["1"]`)));
	assert(!validateJson(scheme, parseJsonString(`["1", "2"]`)));
	assert(!validateJson(scheme, parseJsonString(`[1, "2"]`)));
	assert(!validateJson(scheme, parseJsonString(`[1, {}]`)));
}

unittest {
	Json scheme = parseJsonString(`
								  {
								  "type": "array",
								  "items": {
								  "type": "string"
								  }
								  }
								  `);
	assert(validateJson(scheme, parseJsonString(`[]`)));
	assert(validateJson(scheme, parseJsonString(`["foo"]`)));
	assert(validateJson(scheme, parseJsonString(`["foo", "43"]`)));
	assert(!validateJson(scheme, parseJsonString(`[1]`)));
	assert(!validateJson(scheme, parseJsonString(`[1, 2]`)));
	assert(!validateJson(scheme, parseJsonString(`[1, "foo"]`)));
}

unittest {
	Json scheme = parseJsonString(`
		{
			"type": "array",
			"minItems": 2,
			"maxItems": 3
		}
	`);
	assert(!validateJson(scheme, parseJsonString(`[]`)));
	assert(validateJson(scheme, parseJsonString(`["foo", "bar"]`)));
	assert(validateJson(scheme, parseJsonString(`[1, 2]`)));
	assert(validateJson(scheme, parseJsonString(`[1, "foo"]`)));
	assert(validateJson(scheme, parseJsonString(`[1, "foo", 3]`)));
	assert(validateJson(scheme, parseJsonString(`[1, 2, 3]`)));
	assert(validateJson(scheme, parseJsonString(`[1, {}, 3]`)));
	assert(!validateJson(scheme, parseJsonString(`[1, 2, 3, 4]`)));
	assert(!validateJson(scheme, parseJsonString(`[1, 2, {}, 4]`)));
	assert(!validateJson(scheme, parseJsonString(`[1, 2, 3, 4, 5]`)));
}

unittest {
	Json scheme = parseJsonString(`
								  {
								  "type": "object",
								  "properties": {
								  "value": { "type": "integer", "minimum": -42, "maximum": 42 }
								  }
								  }
								  `);
	assert(validateJson(scheme, parseJsonString(`{"value": 0}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": -42}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": 42}`)));
	assert(!validateJson(scheme, parseJsonString(`{"value": -43}`)));
	assert(!validateJson(scheme, parseJsonString(`{"value": 43}`)));
}

unittest {
	Json scheme = parseJsonString(`
								  {
								  "type": "object",
								  "properties": {
								  "value": { "type": "number", "minimum": -0.5, "maximum": 0.5 }
								  }
								  }
								  `);
	assert(validateJson(scheme, parseJsonString(`{"value": 0}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": 0.4}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": -0.4}`)));
	assert(!validateJson(scheme, parseJsonString(`{"value": -0.6}`)));
	assert(!validateJson(scheme, parseJsonString(`{"value": 0.6}`)));
}

unittest {
	Json scheme = parseJsonString(`
								  {
								  "type": "object",
								  "properties": {
									  "value": { 
										"type": "integer", 
										"minimum": -42,
										"exclusiveMinimum": true, 
										"maximum": 42,
										"exclusiveMaximum": true
									  }
								  }
								  }
								  `);
	assert(validateJson(scheme, parseJsonString(`{"value": 0}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": -41}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": 41}`)));
	assert(!validateJson(scheme, parseJsonString(`{"value": -42}`)));
	assert(!validateJson(scheme, parseJsonString(`{"value": 42}`)));
}

unittest {
	Json scheme = parseJsonString(`
								  {
								  "type": "object",
								  "properties": {
								  "value": { "type": "integer" }
								  }
								  }
								  `);
	assert(validateJson(scheme, parseJsonString(`{"value": 0}`)));
	assert(!validateJson(scheme, parseJsonString(`{"value": 0.}`)));
	assert(!validateJson(scheme, parseJsonString(`{"value": 1.}`)));
	assert(!validateJson(scheme, parseJsonString(`{"value": 1.2}`)));
}

unittest {
	Json scheme = parseJsonString(`
								  {
								  "type": "object",
								  "properties": {
								  "value": { "type": "number" }
								  }
								  }
								  `);
	assert(validateJson(scheme, parseJsonString(`{"value": 0.}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": 1.}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": 1.2}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": -1.2}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": 0}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": 42}`)));
	assert(validateJson(scheme, parseJsonString(`{"value": -42}`)));
}
