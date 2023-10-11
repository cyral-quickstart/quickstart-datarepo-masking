CREATE OR REPLACE FUNCTION ${SCHEMA}.consistent_mask(data TEXT)
RETURNS TEXT AS $$
DECLARE
  response TEXT;
  string_char CHAR(1);
  seed_base INT;
BEGIN
  -- Sets a seed within [-1, 1] interval
  -- HASHTEXT returns an int32 value: min_int32/2^31=-1 and max_int32/2^31=0.99999999953
  seed_base := HASHTEXT(data) / 2^31;
  PERFORM SETSEED(seed_base);

  seed_base := ABS(HASHTEXT(data));
  FOR i IN 1..LENGTH(data) LOOP
    string_char := SUBSTRING(data, i, 1);
    CASE
      WHEN string_char ~ '[A-Z]' THEN
        response := CONCAT(response, CHR(CAST(FLOOR(RANDOM()*(90-65+1))+65 AS INT)));
      WHEN string_char ~ '[a-z]' THEN
        response := CONCAT(response, CHR(CAST(FLOOR(RANDOM()*(122-97+1))+97 AS INT)));
      WHEN string_char ~ '[0-9]' THEN
        response := CONCAT(response, FLOOR(RANDOM()*(9-1+1))+1);
      ELSE
        response := CONCAT(response, SUBSTRING(data, i, 1));
    END CASE;
  END LOOP;
  RETURN response;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ${SCHEMA}.consistent_mask(data NUMERIC)
RETURNS NUMERIC
AS $$
DECLARE
  seed_base DOUBLE PRECISION;
BEGIN
  -- Sets a seed within [-1, 1] interval
  -- HASHTEXT returns an int32 value: min_int32/2^31=-1 and max_int32/2^31=0.99999999953
  seed_base := HASHTEXT(data::text) / 2^31;
  PERFORM SETSEED(seed_base);

  RETURN CAST(FLOOR(RANDOM()*(data-1+1))+1 AS NUMERIC);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ${SCHEMA}.consistent_mask(data DOUBLE PRECISION)
RETURNS DOUBLE PRECISION
AS $$
DECLARE
  seed_base DOUBLE PRECISION;
BEGIN
  -- Sets a seed within [-1, 1] interval
  -- HASHTEXT returns an int32 value: min_int32/2^31=-1 and max_int32/2^31=0.99999999953
  seed_base := HASHTEXT(data::text) / 2^31;
  PERFORM SETSEED(seed_base);

  RETURN CAST(FLOOR(RANDOM()*(data-1+1))+1 AS DOUBLE PRECISION);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ${SCHEMA}.consistent_mask(data INT)
RETURNS INT
AS $$
DECLARE
  seed_base DOUBLE PRECISION;
BEGIN
  -- Sets a seed within [-1, 1] interval
  -- HASHTEXT returns an int32 value: min_int32/2^31=-1 and max_int32/2^31=0.99999999953
  seed_base := HASHTEXT(data::text) / 2^31;
  PERFORM SETSEED(seed_base);

  RETURN CAST(FLOOR(RANDOM()*(data-1+1))+1 AS INT);
END;
$$ LANGUAGE plpgsql;