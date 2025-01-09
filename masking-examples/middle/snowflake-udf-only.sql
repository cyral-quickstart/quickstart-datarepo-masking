CREATE OR REPLACE FUNCTION mask_middle(
  data STRING,
  unmasked_prefix_len INT,
       unmasked_suffix_len INT,
       mask_char STRING
) RETURNS STRING
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
