-- 1. Create a new user schema for storing the desired UDFs:
CREATE SCHEMA IF NOT EXISTS cyral;

-- 2. MySQL>=8.1 requires to enable log_bin_trust_function_creators to create functions:
SET GLOBAL log_bin_trust_function_creators = 1;

-- 3. Create the new function in the target schema:
DROP FUNCTION IF EXISTS cyral.mask_middle;

DELIMITER $
CREATE FUNCTION cyral.mask_middle(
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

-- 4. Grant execution privilege

-- 4.1. Create a masking Role:
CREATE ROLE IF NOT EXISTS CYRAL_MASKING_PERMISSIONS;
GRANT EXECUTE ON cyral.* TO CYRAL_MASKING_PERMISSIONS;

-- 4.2. Make CYRAL_MASKING_PERMISSIONS Role mandatory:
--      Only run the query below if SELECT INSTR(@@mandatory_roles, "CYRAL_MASKING_PERMISSIONS"); returns 0.
SET PERSIST mandatory_roles = CONCAT('CYRAL_MASKING_PERMISSIONS', COALESCE(CONCAT(',', NULLIF(TRIM(@@mandatory_roles), '')), ''));

-- 4.3. Enable CYRAL_MASKING_PERMISSIONS on login:
SET PERSIST activate_all_roles_on_login = 1;

SELECT "UDF has been installed successfully!" AS "Message";