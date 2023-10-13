# 1. Create a new schema for storing the desired UDFs:

CREATE SCHEMA IF NOT EXISTS cyral;


# 2. Create the new function in the target schema:

CREATE OR REPLACE FUNCTION cyral.mask_string(input_string text)
RETURNS text AS
$$
DECLARE
    masked_string text := '';
    i integer := 1;
BEGIN
    -- Iterate through each character of the input string and replace with '*'
    WHILE i <= length(input_string) LOOP
        masked_string := masked_string || '*';
        i := i + 1;
    END LOOP;
    
    -- Return the masked string
    RETURN masked_string;
END;
$$
LANGUAGE PLPGSQL;


# 3. Grant the execution privilege to everyone, through the PUBLIC role

GRANT EXECUTE ON FUNCTION cyral.mask_string(text) TO PUBLIC;