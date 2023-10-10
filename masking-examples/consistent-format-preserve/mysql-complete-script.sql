-- 1. Create a new user schema for storing the desired UDFs:
CREATE SCHEMA IF NOT EXISTS cyral;

-- 2. MySQL>=8.1 requires to enable log_bin_trust_function_creators to create functions:
SET GLOBAL log_bin_trust_function_creators = 1;

-- 3. Create the new function in the target schema:

DROP FUNCTION IF EXISTS cyral.regexp;
DROP FUNCTION IF EXISTS cyral.consistent_mask;
DROP FUNCTION IF EXISTS cyral.consistent_mask_text;
DROP FUNCTION IF EXISTS cyral.consistent_mask_int;

DELIMITER $
CREATE FUNCTION cyral.regexp(expr TEXT, pat TEXT)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN REGEXP_LIKE(expr, pat, 'c');
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask(
    mask_details JSON
)
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE unmasked_length INT;
    DECLARE preserve_counter INT DEFAULT 1;
    DECLARE preserve_data TEXT;
    DECLARE unmasked_data TEXT;
    DECLARE current_char CHAR(1);
    DECLARE seed BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN JSON_OBJECT('masked', NULL);
    END;

    -- First check to make sure the data fits inside a varchar
    SET unmasked_length = LENGTH(JSON_UNQUOTE(JSON_EXTRACT(mask_details, "$.unMasked")));
    -- We're 16383-2=16381 on the check because strings are quoted and we're checking the size of the unquoted version
    -- Docs says max length is 65535, but it can be 16383 in case a VARCHAR column uses the utf8mb4 char set (4 bytes per character)
    IF unmasked_length > 16381 THEN
        RETURN JSON_OBJECT('masked', NULL);
    END IF;

    SET preserve_data = "";
    SET unmasked_data = JSON_UNQUOTE(JSON_EXTRACT(mask_details, "$.unMasked"));
    SET seed = crc32(unmasked_data);
    WHILE
    preserve_counter <= unmasked_length DO
        SET current_char = SUBSTRING(unmasked_data,preserve_counter, 1);
        IF cyral.regexp(current_char, '[a-z]') THEN
            SET preserve_data = CONCAT(preserve_data, CHAR(CAST(RAND(seed+preserve_counter)*(122 -97)+97 AS UNSIGNED)));
        ELSEIF cyral.regexp(current_char, '[A-Z]') THEN
            SET preserve_data = CONCAT(preserve_data, CHAR(CAST(RAND(seed+preserve_counter)*(90 - 65)+65 AS UNSIGNED)));
        ELSEIF cyral.regexp(current_char, '[0-9]') THEN
            SET preserve_data = CONCAT(preserve_data, CAST(CAST(RAND(seed+preserve_counter)*(9-0)+0 as UNSIGNED) as CHAR(1)));
        ELSE
            SET preserve_data = CONCAT(preserve_data, current_char);
        END IF;
        SET preserve_counter = preserve_counter + 1;
    END WHILE;

    RETURN JSON_OBJECT('masked', preserve_data);
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_text(
    unmasked TEXT
)
RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;

    SET @mask_details = JSON_OBJECT('unMasked', unmasked);
    SET @mask_result = cyral.consistent_mask(@mask_details);
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN @masked;
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_int(
    unmasked INT
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;

    SET @mask_details = JSON_OBJECT('unMasked', unmasked);
    SET @mask_result = cyral.consistent_mask(@mask_details);
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, SIGNED);
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