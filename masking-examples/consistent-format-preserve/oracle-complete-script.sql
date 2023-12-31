-- 1. Create a new user schema for storing the desired UDFs:
CREATE USER CYRAL identified by "<password>";

GRANT EXECUTE ON DBMS_CRYPTO TO PUBLIC;

-- 2. Create the new function in the target package:
CREATE OR REPLACE PACKAGE CYRAL.CYRALCUSTOMPKG IS
    FUNCTION "consistent_mask"(data IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION "consistent_mask"(data IN NUMBER) RETURN NUMBER;
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
END;
/

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT EXECUTE ON CYRAL.CYRALCUSTOMPKG TO PUBLIC;

