-- 1. Create a new schema for storing the desired UDFs:
CREATE SCHEMA IF NOT EXISTS cyral;

-- 2. Create the new function in the target schema:
CREATE OR REPLACE FUNCTION cyral.mask_string(input_string TEXT)
RETURNS TEXT
STABLE
AS
$$
  return '*' * len(input_string)
$$ LANGUAGE plpythonu;

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT EXECUTE ON FUNCTION cyral.mask_string(input_string TEXT) TO PUBLIC;
