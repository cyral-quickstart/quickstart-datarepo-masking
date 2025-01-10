-- 1. Create a new schema for storing the desired UDFs:
CREATE SCHEMA IF NOT EXISTS cyral;

-- 2. Create the new function in the target schema:
CREATE OR REPLACE FUNCTION cyral.mask_middle(
  TEXT, -- $1 data
  INT, -- $2 unmasked_prefix_len
  INT, -- $3 unmasked_suffix_len
  CHAR -- $4 mask_char
) RETURNS TEXT STABLE
AS
$$
SELECT CASE
  -- Handle null or empty string case
  WHEN $1 IS NULL OR LENGTH($1) = 0 THEN $1
  -- If the unmasked lengths cover the entire string, return the original data
  WHEN (GREATEST(COALESCE($2, 0), 0) + GREATEST(COALESCE($3, 0), 0)) >= LENGTH($1) THEN $1
  ELSE
    -- Prefix
    SUBSTRING($1, 1, GREATEST(COALESCE($2, 0), 0)) ||
    -- Mask middle
    REGEXP_REPLACE(
      SUBSTRING(
        $1,
        GREATEST(COALESCE($2, 0), 0) + 1, GREATEST(LENGTH($1) - GREATEST(COALESCE($2, 0), 0) - GREATEST(COALESCE($3, 0), 0), 0)
      ),
      '[a-zA-Z0-9]',
      CASE WHEN $4 IS NULL OR $4 = '' THEN '*' ELSE $4 END
    ) ||
    -- Suffix
    SUBSTRING($1, GREATEST(LENGTH($1) - GREATEST(COALESCE($3, 0), 0) + 1, 0))
END
$$ LANGUAGE SQL;

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT EXECUTE ON FUNCTION cyral.mask_middle(TEXT, INT, INT, CHAR) TO PUBLIC;
