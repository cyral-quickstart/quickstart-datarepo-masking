// 1. Create a new database for storing all your UDFs for custom masking
CREATE DATABASE IF NOT EXISTS CYRAL;

// 2. Allow everyone to access the new database
GRANT USAGE ON DATABASE CYRAL TO PUBLIC;

// 3. Create a new schema for holding the UDFs
CREATE SCHEMA IF NOT EXISTS CYRAL.CYRAL;

// 4. Allow everyone to access the new schema
GRANT USAGE ON SCHEMA CYRAL.CYRAL TO PUBLIC;

// 5. Create the new function in the target schema
CREATE OR REPLACE FUNCTION CYRAL.CYRAL."mask_string"(INPUT_STRING STRING)
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
GRANT USAGE ON FUNCTION CYRAL.CYRAL."mask_string"(STRING) TO PUBLIC;
