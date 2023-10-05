// 1. Create a new (optional) database for storing all your UDFs for custom masking
CREATE DATABASE IF NOT EXISTS cyral;

// 2. Allow everyone to access the new database
GRANT USAGE ON DATABASE cyral TO PUBLIC;

// 3. Create a new schema for holding the UDFs
CREATE SCHEMA IF NOT EXISTS cyral.cyral;

// 4. Allow everyone to access the new schema
GRANT USAGE ON SCHEMA cyral.cyral TO PUBLIC;

// 5. Create the new function in the target schema
CREATE OR REPLACE FUNCTION cyral.cyral.MASK_STRING(INPUT_STRING STRING)
  RETURNS STRING
  LANGUAGE JAVASCRIPT
AS
$$
function maskString(inputString) {
    var maskedString = '';
    for (var i = 0; i < inputString.length; i++) {
        maskedString += '*';
    }
    return maskedString;
}

return maskString(INPUT_STRING);
$$;


// 6. Grant the execution privilege to everyone, through the PUBLIC role
GRANT USAGE ON FUNCTION cyral.cyral.MASK_STRING(STRING) TO PUBLIC;
