[![Build Status](https://travis-ci.org/vladimirgamalian/vibe.d.json.schema.svg?branch=master)](https://travis-ci.org/vladimirgamalian/vibe.d.json.schema)

### [JSON Schema](http://json-schema.org/) validation for [vibe.d](http://vibed.org/) [JSON](http://vibed.org/api/vibe.data.json/)

```D
Json scheme = parseJsonString(`{
	"type": "object",
	"properties": {
		"foo": { 
			"type": "integer",
			"minimum": 0
		},
		"bar": { 
			"type": "string",
			"maxLength": 255
		}
	}
}`);

Json json = parseJsonString(`{
	"foo": 42, 
	"bar": "baz"
}`);

bool valid = validateJson(scheme, json);
assert(valid);
```

### Not supported yet
* GENERAL
  * enum
  * anyOf
  * allOf
  * oneOf
  * not
  * definitions
  * $ref
* NUMBER, INTEGER
  * multipleOf
* STRING
  * pattern
  * format
* OBJECT
  * minProperties
  * maxProperties
  * dependencies
  * patternProperties
  * additionalProperties  as object
* ARRAY
  * additionalItems
  * uniqueItems
  * items as array
  