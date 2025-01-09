CREATE OR REPLACE PACKAGE sys.cyral_pkg IS
    FUNCTION "mask_middle"(data IN VARCHAR2, unmasked_prefix_len_in IN INT, unmasked_suffix_len_in IN INT, mask_char_in IN CHAR) RETURN VARCHAR2;
END;

CREATE OR REPLACE PACKAGE BODY sys.cyral_pkg AS
  FUNCTION "mask_middle"(data IN VARCHAR2, unmasked_prefix_len_in IN INT, unmasked_suffix_len_in IN INT, mask_char_in IN CHAR) RETURN VARCHAR2
  IS
    unmasked_prefix_len INT;
    unmasked_suffix_len INT;
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

    -- Split prefix, middle and suffix
    prefix := SUBSTR(data, 1, unmasked_prefix_len);
    middle := SUBSTR(data, unmasked_prefix_len + 1, LENGTH(data) - unmasked_prefix_len - unmasked_suffix_len);
    suffix := SUBSTR(data, LENGTH(data) - unmasked_suffix_len + 1);

    -- Mask the middle part and concat all parts
    RETURN prefix || REGEXP_REPLACE(middle, '[a-zA-Z0-9]', COALESCE(mask_char_in, '*')) || suffix;
  END;
END;