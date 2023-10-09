-- 1. Create a new schema for storing the desired UDFs:
CREATE SCHEMA IF NOT EXISTS cyral;

-- 2. Create the new function in the target schema:
CREATE OR REPLACE FUNCTION cyral.consistent_format_preserve(input_string TEXT)
RETURNS TEXT AS $$
DECLARE
  response TEXT;
  string_char CHAR(1);
  seed_base INT;
BEGIN
  seed_base := ABS(HASHTEXT(input_string));
  FOR i IN 1..LENGTH(input_string) LOOP
    string_char := SUBSTRING(input_string, i, 1);
    CASE
      WHEN string_char ~ '[A-Z]' THEN
        response := CONCAT(response, SETSEED((seed_base+i)/10000000000::DECIMAL), CHR(CAST(FLOOR(RANDOM()*(90-65+1))+65 AS INT)));
      WHEN string_char ~ '[a-z]' THEN
        response := CONCAT(response, SETSEED((seed_base+i)/10000000000::DECIMAL), CHR(CAST(FLOOR(RANDOM()*(122-97+1))+97 AS INT)));
      WHEN string_char ~ '[0-9]' THEN
        response := CONCAT(response, SETSEED((seed_base+i)/10000000000::DECIMAL), FLOOR(RANDOM()*(9-1+1))+1);
      ELSE
        response := CONCAT(response, SUBSTRING(input_string, i, 1));
    END CASE;
  END LOOP;
  RETURN response;
END;
$$ LANGUAGE plpgsql;

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT EXECUTE ON FUNCTION cyral.consistent_format_preserve(text) TO PUBLIC;