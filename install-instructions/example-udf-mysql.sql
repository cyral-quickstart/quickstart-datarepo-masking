-- 1. Create a new user schema for storing the desired UDFs:
CREATE SCHEMA IF NOT EXISTS cyral;

-- 2. MySQL>=8.1 requires to enable log_bin_trust_function_creators to create functions:
SET GLOBAL log_bin_trust_function_creators = 1;

-- 3. Create the new function in the target schema:
DROP FUNCTION IF EXISTS cyral.mask_string;

DELIMITER $
CREATE FUNCTION cyral.mask_string(input_string TEXT)
RETURNS TEXT
BEGIN
    DECLARE masked_string TEXT DEFAULT '';
    DECLARE i INT DEFAULT 1;
    DECLARE input_length INT;

    SET input_length = CHAR_LENGTH(input_string);

    -- Iterate through each character of the input string and replace with '*'
    WHILE i <= input_length DO
        SET masked_string = CONCAT(masked_string, '*');
        SET i = i + 1;
    END WHILE;

    -- Return the masked string
    RETURN masked_string;
END $
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
