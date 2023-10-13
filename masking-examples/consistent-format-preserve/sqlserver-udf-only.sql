CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask(@unmasked_data SQL_VARIANT)
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

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_int(@unmasked_data INT)
RETURNS INT AS
BEGIN
  RETURN TRY_CONVERT(INT, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_varchar(@unmasked_data VARCHAR(4000))
RETURNS VARCHAR(4000) AS
BEGIN
  RETURN TRY_CONVERT(VARCHAR(4000), ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_nvarchar(@unmasked_data NVARCHAR(4000))
RETURNS NVARCHAR(4000) AS
BEGIN
  RETURN TRY_CONVERT(NVARCHAR(4000), ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_char(@unmasked_data CHAR)
RETURNS CHAR AS
BEGIN
  RETURN TRY_CONVERT(CHAR, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_nchar(@unmasked_data NCHAR(4000))
RETURNS NCHAR(4000) AS
BEGIN
  RETURN TRY_CONVERT(NCHAR(4000), ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_bigint(@unmasked_data BIGINT)
RETURNS BIGINT AS
BEGIN
  RETURN TRY_CONVERT(BIGINT, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_numeric(@unmasked_data NUMERIC)
RETURNS NUMERIC AS
BEGIN
  RETURN TRY_CONVERT(NUMERIC, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_bit(@unmasked_data BIT)
RETURNS BIT AS
BEGIN
  RETURN TRY_CONVERT(BIT, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_smallint(@unmasked_data SMALLINT)
RETURNS SMALLINT AS
BEGIN
  RETURN TRY_CONVERT(SMALLINT, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_decimal(@unmasked_data DECIMAL)
RETURNS DECIMAL AS
BEGIN
  RETURN TRY_CONVERT(DECIMAL, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_tinyint(@unmasked_data TINYINT)
RETURNS TINYINT AS
BEGIN
  RETURN TRY_CONVERT(TINYINT, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_float(@unmasked_data FLOAT)
RETURNS FLOAT AS
BEGIN
  RETURN TRY_CONVERT(FLOAT, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_real(@unmasked_data REAL)
RETURNS REAL AS
BEGIN
  RETURN TRY_CONVERT(REAL, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_money(@unmasked_data MONEY)
RETURNS MONEY AS
BEGIN
  RETURN TRY_CONVERT(MONEY, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO

CREATE OR ALTER FUNCTION ${SCHEMA}.consistent_mask_smallmoney(@unmasked_data SMALLMONEY)
RETURNS SMALLMONEY AS
BEGIN
  RETURN TRY_CONVERT(SMALLMONEY, ${SCHEMA}.consistent_mask(CONVERT(SQL_VARIANT, @unmasked_data)))
END;
GO
