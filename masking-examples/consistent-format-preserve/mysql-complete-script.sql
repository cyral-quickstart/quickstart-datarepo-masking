-- 1. Create a new user schema for storing the desired UDFs:
CREATE SCHEMA IF NOT EXISTS cyral;

-- 2. MySQL>=8.1 requires to enable log_bin_trust_function_creators to create functions:
SET GLOBAL log_bin_trust_function_creators = 1;

-- 3. Create the new function in the target schema:
DROP FUNCTION IF EXISTS cyral.consistent_mask;
DROP FUNCTION IF EXISTS cyral.consistent_mask_text;
DROP FUNCTION IF EXISTS cyral.consistent_mask_tinytext;
DROP FUNCTION IF EXISTS cyral.consistent_mask_char;
DROP FUNCTION IF EXISTS cyral.consistent_mask_varchar;
DROP FUNCTION IF EXISTS cyral.consistent_mask_int;
DROP FUNCTION IF EXISTS cyral.consistent_mask_int_unsigned;
DROP FUNCTION IF EXISTS cyral.consistent_mask_tinyint;
DROP FUNCTION IF EXISTS cyral.consistent_mask_tinyint_unsigned;
DROP FUNCTION IF EXISTS cyral.consistent_mask_smallint;
DROP FUNCTION IF EXISTS cyral.consistent_mask_smallint_unsigned;
DROP FUNCTION IF EXISTS cyral.consistent_mask_mediumint;
DROP FUNCTION IF EXISTS cyral.consistent_mask_mediumint_unsigned;
DROP FUNCTION IF EXISTS cyral.consistent_mask_bigint;
DROP FUNCTION IF EXISTS cyral.consistent_mask_bigint_unsigned;
DROP FUNCTION IF EXISTS cyral.consistent_mask_double;
DROP FUNCTION IF EXISTS cyral.consistent_mask_float;
DROP FUNCTION IF EXISTS cyral.consistent_mask_decimal;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask(mask_details JSON)
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
        IF REGEXP_LIKE(current_char, '[a-z]', 'c') THEN
            SET preserve_data = CONCAT(preserve_data, CHAR(CAST(RAND(seed+preserve_counter)*(122 -97)+97 AS UNSIGNED)));
        ELSEIF REGEXP_LIKE(current_char, '[A-Z]', 'c') THEN
            SET preserve_data = CONCAT(preserve_data, CHAR(CAST(RAND(seed+preserve_counter)*(90 - 65)+65 AS UNSIGNED)));
        ELSEIF REGEXP_LIKE(current_char, '[0-9]', 'c') THEN
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
CREATE FUNCTION cyral.consistent_mask_text(unmasked TEXT)
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
CREATE FUNCTION cyral.consistent_mask_tinytext(unmasked TINYTEXT)
RETURNS TINYTEXT
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN @masked;
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_char(unmasked CHAR(255))
RETURNS CHAR(255)
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN @masked;
END$
DELIMITER ;

-- Docs says max length is 65535, but it can be 16383 in case a VARCHAR column uses the utf8mb4 char set (4 bytes per character)
DELIMITER $
CREATE FUNCTION cyral.consistent_mask_varchar(unmasked VARCHAR(16383))
RETURNS VARCHAR(16383)
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, CHAR(16383));
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_int(unmasked INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, SIGNED);
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_int_unsigned(unmasked INT UNSIGNED)
RETURNS INT UNSIGNED
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, UNSIGNED);
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_tinyint(unmasked TINYINT)
RETURNS TINYINT
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, SIGNED);
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_tinyint_unsigned(unmasked TINYINT UNSIGNED)
RETURNS TINYINT UNSIGNED
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, UNSIGNED);
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_smallint(unmasked SMALLINT)
RETURNS SMALLINT
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, SIGNED);
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_smallint_unsigned(unmasked SMALLINT UNSIGNED)
RETURNS SMALLINT UNSIGNED
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, UNSIGNED);
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_mediumint(unmasked MEDIUMINT)
RETURNS MEDIUMINT
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, SIGNED);
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_mediumint_unsigned(unmasked MEDIUMINT UNSIGNED)
RETURNS MEDIUMINT UNSIGNED
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, UNSIGNED);
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_bigint(unmasked BIGINT)
RETURNS BIGINT
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, SIGNED);
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_bigint_unsigned(unmasked BIGINT UNSIGNED)
RETURNS BIGINT UNSIGNED
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, UNSIGNED);
END$
DELIMITER ;

-- https://dev.mysql.com/doc/refman/8.0/en/floating-point-types.html
-- real and double are the same thing
DELIMITER $
CREATE FUNCTION cyral.consistent_mask_double(unmasked DOUBLE)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, DECIMAL(65, 30));
END$
DELIMITER ;

DELIMITER $
CREATE FUNCTION cyral.consistent_mask_float(unmasked FLOAT)
RETURNS FLOAT
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, DECIMAL(65, 30));
END$
DELIMITER ;

-- https://dev.mysql.com/doc/refman/8.0/en/fixed-point-types.html
-- decimal and numeric are the same thing
DELIMITER $
CREATE FUNCTION cyral.consistent_mask_decimal(unmasked DECIMAL)
RETURNS DECIMAL
DETERMINISTIC
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RETURN NULL;
    END;
    SET @mask_result = cyral.consistent_mask(JSON_OBJECT('unMasked', unmasked));
    SET @masked = JSON_UNQUOTE(JSON_EXTRACT(@mask_result, '$.masked'));
    RETURN CONVERT(@masked, DECIMAL);
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