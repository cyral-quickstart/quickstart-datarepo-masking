CREATE FUNCTION mask_middle(data TEXT, unmasked_prefix_len INT, unmasked_suffix_len INT, mask_char CHAR)
RETURNS TEXT
DETERMINISTIC
BEGIN
  DECLARE prefix TEXT;
  DECLARE middle TEXT;
  DECLARE suffix TEXT;
  DECLARE i INT DEFAULT 1;

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
  SET mask_char = COALESCE(mask_char, '*');

  -- Split prefix, middle and suffix
  SET prefix = SUBSTRING(data FROM 1 FOR unmasked_prefix_len);
  SET middle = SUBSTRING(data FROM unmasked_prefix_len + 1 FOR LENGTH(data) - unmasked_prefix_len - unmasked_suffix_len);
  SET suffix = SUBSTRING(data FROM LENGTH(data) - unmasked_suffix_len + 1);

  -- Mask the middle part
  WHILE i <= LENGTH(middle) DO
    IF SUBSTRING(middle, i, 1) REGEXP '[a-zA-Z0-9]' THEN
      SET middle = INSERT(middle, i, 1, mask_char);
    END IF;
    SET i = i + 1;
  END WHILE;

  -- Concatenate all parts
  RETURN CONCAT(prefix, middle, suffix);
END