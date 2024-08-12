-- 1. Create a new user schema for storing the desired UDFs:
CREATE USER CYRAL identified by "<password>";

GRANT EXECUTE ON DBMS_CRYPTO TO PUBLIC;

-- 2. Create the new function in the target package:
CREATE OR REPLACE PACKAGE CYRAL.CYRALCUSTOMPKG IS
    FUNCTION "consistent_mask"(data IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION "consistent_mask"(data IN NUMBER) RETURN NUMBER;
    FUNCTION "consistent_mask_hash"(data IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION "consistent_mask_hash"(data IN NUMBER) RETURN NUMBER;
END;
/

CREATE OR REPLACE PACKAGE BODY CYRAL.CYRALCUSTOMPKG AS
    FUNCTION "consistent_mask"(data IN VARCHAR2) RETURN VARCHAR2
	IS
	    masked_data VARCHAR2(32767) := '';
	    hash RAW(32);
	BEGIN
	    hash := DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(data, 'AL32UTF8'), DBMS_CRYPTO.HASH_SH256);
	    DBMS_RANDOM.SEED(hash);
	    FOR i IN 1..LENGTH(data) LOOP
	       CASE
	           WHEN regexp_like(SUBSTR(data, i, 1), '[A-Z]') THEN
	               masked_data := CONCAT(masked_data, CHR(FLOOR(DBMS_RANDOM.VALUE()*(90-65+1))+65));
	           WHEN regexp_like(SUBSTR(data, i, 1), '[a-z]') THEN
	               masked_data := CONCAT(masked_data, CHR(FLOOR(DBMS_RANDOM.VALUE()*(122-97+1))+97));
	           WHEN regexp_like(SUBSTR(data, i, 1), '[0-9]') THEN
	               masked_data := CONCAT(masked_data, FLOOR(DBMS_RANDOM.VALUE()*(9-1+1))+1);
	           ELSE
	               masked_data := CONCAT(masked_data, SUBSTR(data, i, 1));
	       END CASE;
	    END LOOP;

	    RETURN masked_data;
	END;

    FUNCTION "consistent_mask"(data IN NUMBER) RETURN NUMBER
    IS
    BEGIN
        RETURN "consistent_mask"(TO_CHAR(data));
    END;

    FUNCTION "consistent_mask_hash"(data IN VARCHAR2) RETURN VARCHAR2
    IS
        resp       VARCHAR2(32767) := '';
        hash_hex   VARCHAR2(64);
        c          CHAR(1);
    BEGIN
        -- Oracle is mostly 1-based, but for consistency with other languages, we
        -- use 0-based indexing here. This requires adding 1 in a few spots below.
        FOR i IN 0..(LENGTH(data) - 1)
            LOOP
                c := SUBSTR(data, i + 1, 1);
                hash_hex := RAWTOHEX(DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(TO_CHAR(i) || data, 'AL32UTF8'), DBMS_CRYPTO.HASH_SH256));
                -- Explanation of some magic numbers below:
                -- 26 is the number of letters in the ISO Latin alphabet.
                -- 65 is the ASCII code for 'A'.
                -- 97 is the ASCII code for 'a'.
                -- 48 is the ASCII code for '0'.
                -- 10 is the number of digits (0-9).
                CASE
                    WHEN c BETWEEN 'A' AND 'Z' THEN
                        -- Oracle's strings are 1-based, so we need to add 1 when
                        -- passing the MOD'ed index to SUBSTR.
                        resp := resp || CHR(MOD(ASCII(c) - 65 + TO_NUMBER(SUBSTR(hash_hex, MOD(i, LENGTH(hash_hex)) + 1, 1), 'X'), 26) + 65);
                    WHEN c BETWEEN 'a' AND 'z' THEN
                        resp := resp || CHR(MOD(ASCII(c) - 97 + TO_NUMBER(SUBSTR(hash_hex, MOD(i, LENGTH(hash_hex)) + 1, 1), 'X'), 26) + 97);
                    WHEN c BETWEEN '0' AND '9' THEN
                        resp := resp || CHR(MOD(ASCII(c) - 48 + TO_NUMBER(SUBSTR(hash_hex, MOD(i, LENGTH(hash_hex)) + 1, 1), 'X'), 10) + 48);
                    ELSE
                        resp := resp || c;
                    END CASE;
            END LOOP;
        RETURN resp;
    END;

    FUNCTION "consistent_mask_hash"(data IN NUMBER) RETURN NUMBER
    IS
    BEGIN
        RETURN "consistent_mask_hash"(TO_CHAR(data));
    END;
END;
/

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT EXECUTE ON CYRAL.CYRALCUSTOMPKG TO PUBLIC;
