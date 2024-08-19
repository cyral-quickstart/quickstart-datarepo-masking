CREATE OR REPLACE PACKAGE ${USER_SCHEMA}.${PACKAGE} IS
    FUNCTION "consistent_mask"(data IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION "consistent_mask"(data IN NUMBER) RETURN NUMBER;
    FUNCTION "consistent_mask_hash"(data IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION "consistent_mask_hash"(data IN NUMBER) RETURN NUMBER;
END;
/

CREATE OR REPLACE PACKAGE BODY ${USER_SCHEMA}.${PACKAGE} AS
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
        hash_bytes RAW(32);
        rand       NUMBER;
        c          CHAR(1);
    BEGIN
        FOR i IN 1..LENGTH(data) LOOP
            c := SUBSTR(data, i, 1);
            IF c < '0' OR c > 'z' THEN -- not a digit or letter.
                resp := resp || c;
            ELSE
                hash_bytes := DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(TO_CHAR(i - 1) || data, 'AL32UTF8'), DBMS_CRYPTO.HASH_SH256);
                -- Use the first 4 bytes of the hash as a "random" number.
                rand := TO_NUMBER(RAWTOHEX(UTL_RAW.SUBSTR(hash_bytes, 1, 4)), 'XXXXXXXX');
                -- Explanation of the magic numbers below:
                -- 10 is the number of digits (0-9).
                -- 48 is the ASCII code for '0'.
                -- 26 is the number of letters in the ISO Latin alphabet.
                -- 65 is the ASCII code for 'A'.
                -- 97 is the ASCII code for 'a'.
                CASE
                    WHEN c BETWEEN '0' AND '9' THEN resp := resp || CHR(MOD(rand, 10) + 48);
                    WHEN c BETWEEN 'A' AND 'Z' THEN resp := resp || CHR(MOD(rand, 26) + 65);
                    WHEN c BETWEEN 'a' AND 'z' THEN resp := resp || CHR(MOD(rand, 26) + 97);
                END CASE;
            END IF;
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
