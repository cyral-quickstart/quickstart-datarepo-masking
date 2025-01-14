-- 1. Create a new user schema for storing the desired UDFs:
CREATE USER CYRAL identified by "<password>";

GRANT EXECUTE ON DBMS_CRYPTO TO PUBLIC;
GRANT EXECUTE ON UTL_RAW TO PUBLIC;

-- 2. Create the new function in the target package:
CREATE OR REPLACE PACKAGE CYRAL.CYRALCUSTOMPKG IS
  FUNCTION "redact"(
    data IN VARCHAR2,
    unmasked_prefix_len_in IN INT,
    unmasked_suffix_len_in IN INT,
    mask_char_in IN CHAR
  ) RETURN VARCHAR2;
END;
/

CREATE OR REPLACE PACKAGE BODY CYRAL.CYRALCUSTOMPKG AS
  FUNCTION "redact"(
    data IN VARCHAR2,
    unmasked_prefix_len_in IN INT,
    unmasked_suffix_len_in IN INT,
    mask_char_in IN CHAR
  ) RETURN VARCHAR2
  IS
    unmasked_prefix_len INT;
    unmasked_suffix_len INT;
    mask_char CHAR;
    prefix VARCHAR2(32767);
    middle VARCHAR2(32767);
    suffix VARCHAR2(32767);
  BEGIN
    -- Handle null or empty string case
    IF data IS NULL OR LENGTH(data) = 0 THEN
      -- Nothing to be masked
      RETURN data;
    END IF;

    -- Ensure prefix and suffix lengths are non-negative
    unmasked_prefix_len := GREATEST(COALESCE(unmasked_prefix_len_in, 0), 0);
    unmasked_suffix_len := GREATEST(COALESCE(unmasked_suffix_len_in, 0), 0);

    -- If the unmasked lengths cover the entire string, return the original data
    IF (unmasked_prefix_len + unmasked_suffix_len) >= LENGTH(data) THEN
      -- Nothing to be masked
      RETURN data;
    END IF;

    -- Set default mask character
    mask_char := mask_char_in;
    IF mask_char IS NULL OR mask_char = '' THEN
      mask_char := '*';
    END IF;

    -- Split prefix, middle and suffix
    prefix := SUBSTR(data, 1, unmasked_prefix_len);
    middle := SUBSTR(data, unmasked_prefix_len + 1, LENGTH(data) - unmasked_prefix_len - unmasked_suffix_len);
    suffix := SUBSTR(data, LENGTH(data) - unmasked_suffix_len + 1);

    -- Mask the middle part and concat all parts
    RETURN prefix || REGEXP_REPLACE(middle, '[a-zA-Z0-9]', mask_char) || suffix;
  END;
END;
/

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT EXECUTE ON CYRAL.CYRALCUSTOMPKG TO PUBLIC;
