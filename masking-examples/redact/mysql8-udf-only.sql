DELIMITER $
CREATE FUNCTION ${SCHEMA}.redact(
  data TEXT,
  unmasked_prefix_len INT,
  unmasked_suffix_len INT,
  mask_char CHAR
) RETURNS TEXT DETERMINISTIC
BEGIN
  DECLARE prefix TEXT;
  DECLARE middle TEXT;
  DECLARE suffix TEXT;

  -- Handle null or empty string case
  IF data IS NULL OR LENGTH(data) = 0 THEN
    -- Nothing to mask
    RETURN data;
  END IF;

  -- Ensure prefix and suffix lengths are non-negative
  SET unmasked_prefix_len = GREATEST(COALESCE(unmasked_prefix_len, 0), 0);
  SET unmasked_suffix_len = GREATEST(COALESCE(unmasked_suffix_len, 0), 0);

  -- If the unmasked lengths cover the entire string, return the original data
  IF (unmasked_prefix_len + unmasked_suffix_len) >= LENGTH(data) THEN
    -- nothing to mask
    RETURN data;
  END IF;

  -- Set default mask character
  IF mask_char IS NULL OR mask_char = '' THEN
    SET mask_char = '*';
  END IF;

  -- Split prefix, middle and suffix
  SET prefix = SUBSTRING(data FROM 1 FOR unmasked_prefix_len);
  SET middle = SUBSTRING(data FROM unmasked_prefix_len + 1 FOR LENGTH(data) - unmasked_prefix_len - unmasked_suffix_len);
  SET suffix = SUBSTRING(data FROM LENGTH(data) - unmasked_suffix_len + 1);

  -- Mask the middle part and concat all parts
  RETURN CONCAT(prefix, REGEXP_REPLACE(middle, '[a-zA-Z0-9]', mask_char), suffix);
END$
DELIMITER ;
