[![Build Status](https://travis-ci.org/vladimirgamalian/vibe.d.json.schema.svg?branch=master)](https://travis-ci.org/vladimirgamalian/vibe.d.json.schema)

### Add JSON Schema validation for vibe.d JSON

```
Json scheme = parseJsonString(`{
	"type": "object",
	"properties": {
		"foo": { "type": "integer" },
		"bar": { "type": "string" }
	}
}`);

Json json = parseJsonString(`{
	"fee": 42, 
	"bar": "baz"
}`);

bool valid = validateJson(scheme, json);
assert(valid);
```
