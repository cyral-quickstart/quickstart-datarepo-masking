-- 1. Create a new user schema for storing the desired UDFs:
CREATE SCHEMA IF NOT EXISTS cyral;

-- 2. Create the new function in the target schema:
DROP FUNCTION IF EXISTS cyral.redact;
DELIMITER $
CREATE FUNCTION cyral.redact(
  data TEXT,
  unmasked_prefix_len INT,
  unmasked_suffix_len INT,
  mask_char CHAR
) RETURNS TEXT DETERMINISTIC
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
  IF mask_char IS NULL OR mask_char = '' THEN
    SET mask_char = '*';
  END IF;

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
END$
DELIMITER ;

-- 3. Grant execution privilege (Anonymous user permission)
DROP PROCEDURE IF EXISTS cyral.setup_permissions;
DELIMITER $
CREATE PROCEDURE cyral.setup_permissions(
  OUT result TEXT
)
BEGIN
  DECLARE anonymous_user_exists INT;
  DECLARE anonymous_user_exists_cursor CURSOR FOR SELECT 1 IN (SELECT 1 FROM mysql.user WHERE user = "" AND host = "%");

  OPEN anonymous_user_exists_cursor;
  FETCH anonymous_user_exists_cursor INTO anonymous_user_exists;
  CLOSE anonymous_user_exists_cursor;
  IF anonymous_user_exists THEN
    GRANT EXECUTE ON cyral.* TO ''@'%';
    FLUSH PRIVILEGES;
    SET result = "UDF has been installed successfully!";
  ELSE
    -- Requires anonymous user creation
    SET result = "UDF installation failed, anonymous user is missing. Follow the steps to fix: 1 - Run \"CREATE USER IF NOT EXISTS ''@'%' IDENTIFIED WITH mysql_native_password BY '<STRONG_PASSWORD>';\" 2 - Rerun this script";
  END IF;
END$
DELIMITER ;

SET @perm_result="";
CALL cyral.setup_permissions(@perm_result);
DROP PROCEDURE IF EXISTS cyral.setup_permissions;
SELECT @perm_result AS "Message";
