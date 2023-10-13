-- 1. Create a new user schema for storing the desired UDFs:
-- NOTE: Replace <password>
CREATE USER CYRAL identified by "<password>";

-- 2. Create the new function in the target package:
CREATE OR REPLACE PACKAGE CYRAL.CYRALCUSTOMPKG IS
    FUNCTION "mask_string"(input_string IN VARCHAR2) RETURN VARCHAR2;
END;
/

CREATE OR REPLACE PACKAGE BODY CYRAL.CYRALCUSTOMPKG AS
    FUNCTION "mask_string"(
      input_string IN VARCHAR2
    )
    RETURN VARCHAR2
    IS
        masked VARCHAR2(32767) := '';
        i NUMBER := 1;
    BEGIN
        WHILE i <= LENGTH(input_string) LOOP
            masked := masked || '*';
            i := i + 1;
        END LOOP;
        RETURN masked;
    END;
END;
/

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT EXECUTE ON CYRAL.CYRALCUSTOMPKG TO PUBLIC;