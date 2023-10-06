-- 1. Create a new user schema for storing the desired UDFs:
CREATE USER CYRAL identified by "<password>";

-- 2. Create the new function in the target schema:
CREATE OR REPLACE FUNCTION CYRAL."mask_string"(
  INPUT_STRING IN VARCHAR2
)
RETURN VARCHAR2
IS
    MASKED VARCHAR2(32767) := '';
    I NUMBER := 1;
BEGIN
    WHILE I <= LENGTH(INPUT_STRING) LOOP
        MASKED := MASKED || '*';
        I := I + 1;
    END LOOP;
    RETURN MASKED;
END;
/

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT ALL PRIVILEGES ON CYRAL."mask_string" TO PUBLIC;