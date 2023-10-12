-- 1. Create a new database and schema for storing the desired UDFs:
CREATE DATABASE cyral;
GO
USE cyral;
GO
CREATE SCHEMA cyral;
GO

-- 2. Create the new function in the target schema:
CREATE OR ALTER FUNCTION cyral.consistent_mask(@unmasked_data SQL_VARIANT)
RETURNS SQL_VARIANT AS
BEGIN
  DECLARE @unmasked_data_len INT
  DECLARE @loop_counter INT = 1
  DECLARE @source_data NVARCHAR(MAX) = CAST(@unmasked_data AS NVARCHAR(MAX))
  SET @unmasked_data_len = LEN(@source_data)
  DECLARE @masked_output NVARCHAR(4000) = ''
  DECLARE @isNumeric BIT = (SELECT ISNUMERIC(@source_data))
  DECLARE @preserveExponent BIT = 0
  DECLARE @seed_value FLOAT

  WHILE @loop_counter <= @unmasked_data_len
  BEGIN
    SET @seed_value = (SELECT (ABS(CAST(CHECKSUM(HASHBYTES('md5', CONCAT(@source_data, @loop_counter))) AS FLOAT)))/2147483647.0 AS FLOAT)
    DECLARE @current_char NCHAR(1) = SUBSTRING(@source_data, @loop_counter, 1)
    IF @isNumeric = 1 AND (UNICODE(@current_char) BETWEEN 65 AND 90 or UNICODE(@current_char) BETWEEN 97 AND 122)
    BEGIN
      SET @preserveExponent = 1
    END
    SET @masked_output = @masked_output + (
      SELECT
      CASE
        WHEN @isNumeric = 0 AND UNICODE(@current_char) BETWEEN 97 AND 122 THEN
          CHAR(ROUND(((122 - 97 -1) * (@seed_value) + 97), 0))
        WHEN @isNumeric = 0 AND UNICODE(@current_char) BETWEEN 65 AND 90 THEN
          CHAR(ROUND(((90 - 65 -1) * (@seed_value) + 65), 0))
        WHEN @preserveExponent = 0 AND @current_char LIKE '[0-9]' THEN
          TRY_CONVERT(CHAR(1), TRY_CONVERT(INT, ROUND(((9 - 0 -1) * (@seed_value) + 0), 0)))
        ELSE @current_char
      END
    )
    SET @loop_counter = @loop_counter + 1
  END
  RETURN @masked_output
END;
GO

--CREATE OR ALTER FUNCTION cyral.consistent_mask(@unmasked_data VARCHAR(4000))
--RETURNS VARCHAR(4000) AS
--BEGIN
--  RETURN TRY_CONVERT(VARCHAR, cyral.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
--END;
--GO

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT CONNECT TO PUBLIC;
GRANT EXECUTE ON OBJECT::cyral.consistent_mask TO PUBLIC;
--GRANT EXECUTE ON OBJECT::cyral.consistent_mask_varchar TO PUBLIC;