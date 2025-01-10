-- 1. Create a new database for storing all your UDFs for custom masking
CREATE DATABASE IF NOT EXISTS CYRAL;

-- 2. Allow everyone to access the new database
GRANT USAGE ON DATABASE CYRAL TO PUBLIC;

-- 3. Create a new schema for holding the UDFs
CREATE SCHEMA IF NOT EXISTS CYRAL.CYRAL;

-- 4. Allow everyone to access the new schema
GRANT USAGE ON SCHEMA CYRAL.CYRAL TO PUBLIC;

-- 5. Create the new function in the target schema
CREATE OR REPLACE FUNCTION CYRAL.CYRAL."mask_middle"(
  data VARCHAR,
  unmasked_prefix_len INT,
  unmasked_suffix_len INT,
  mask_char CHAR
) RETURNS VARCHAR
AS
$$
CASE
  -- Handle null or empty string case
  WHEN data IS NULL OR LENGTH(data) = 0 THEN data
  -- If the unmasked lengths cover the entire string, return the original data
  WHEN (GREATEST(COALESCE(unmasked_prefix_len, 0), 0) + GREATEST(COALESCE(unmasked_suffix_len, 0), 0)) >= LENGTH(data) THEN data
  ELSE
    -- Prefix
    SUBSTR(data, 1, GREATEST(COALESCE(unmasked_prefix_len, 0), 0)) ||
    -- Mask middle
    REGEXP_REPLACE(
      SUBSTR(
        data,
        GREATEST(COALESCE(unmasked_prefix_len, 0), 0) + 1, GREATEST(LENGTH(data) - GREATEST(COALESCE(unmasked_prefix_len, 0), 0) - GREATEST(COALESCE(unmasked_suffix_len, 0), 0), 0)
      ),
      '[a-zA-Z0-9]',
      CASE WHEN mask_char IS NULL OR mask_char = '' THEN '*' ELSE mask_char END
    ) ||
    -- Suffix
    SUBSTR(data, GREATEST(LENGTH(data) - GREATEST(COALESCE(unmasked_suffix_len, 0), 0) + 1, 0))
END
$$;

-- 6. Grant the execution privilege to everyone, through the PUBLIC role
GRANT USAGE ON FUNCTION CYRAL.CYRAL."mask_middle"(VARCHAR, INT, INT, CHAR) TO PUBLIC;
