CREATE OR REPLACE FUNCTION mask_middle(
  data TEXT,
  unmasked_prefix_len INT,
  unmasked_suffix_len INT,
  mask_char CHAR
) RETURNS TEXT
AS
$$
DECLARE
  prefix TEXT;
  middle TEXT;
  suffix TEXT;
BEGIN
  -- Handle null or empty string case
  IF data IS NULL OR LENGTH(data) = 0 THEN
    -- Nothing to be masked
    RETURN data;
  END IF;

  -- Ensure prefix and suffix lengths are non-negative
  unmasked_prefix_len = GREATEST(COALESCE(unmasked_prefix_len, 0), 0);
  unmasked_suffix_len = GREATEST(COALESCE(unmasked_suffix_len, 0), 0);

  -- If the unmasked lengths cover the entire string, return the original data
  IF (unmasked_prefix_len + unmasked_suffix_len) >= LENGTH(data) THEN
    -- Nothing to be masked
    RETURN data;
  END IF;

  -- Split prefix, middle and suffix
  prefix = SUBSTRING(data FROM 1 FOR unmasked_prefix_len);
  middle = SUBSTRING(data FROM unmasked_prefix_len + 1 FOR LENGTH(data) - unmasked_prefix_len - unmasked_suffix_len);
  suffix = SUBSTRING(data FROM LENGTH(data) - unmasked_suffix_len + 1);

  -- Mask the middle part and concat all parts
  RETURN prefix || REGEXP_REPLACE(middle, '[a-zA-Z0-9]', COALESCE(mask_char, '*'), 'g') || suffix;
END;
$$ LANGUAGE PLPGSQL;
