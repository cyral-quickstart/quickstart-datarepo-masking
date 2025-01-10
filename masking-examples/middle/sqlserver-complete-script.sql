-- 1. Create a new database and schema for storing the desired UDFs:
CREATE DATABASE cyral;
GO
USE cyral;
GO
CREATE SCHEMA cyral;
GO

-- 2. Create the new function in the target schema:
CREATE OR ALTER FUNCTION cyral.mask_middle(
  @data NVARCHAR(MAX),
  @unmasked_prefix_len INT,
  @unmasked_suffix_len INT,
  @mask_char CHAR
) RETURNS NVARCHAR(MAX)
AS
BEGIN
  -- Handle null or empty string case
  IF @data IS NULL OR LEN(@data) = 0
  BEGIN
    -- Nothing to be masked
    RETURN @data
  END

  -- Ensure prefix and suffix lengths are non-negative
  IF @unmasked_prefix_len IS NULL OR @unmasked_prefix_len < 0
  BEGIN
    SET @unmasked_prefix_len = 0
  END
  IF @unmasked_suffix_len IS NULL OR @unmasked_suffix_len < 0
  BEGIN
    SET @unmasked_suffix_len = 0
  END

  -- If the unmasked lengths cover the entire string, return the original data
  IF (@unmasked_prefix_len + @unmasked_suffix_len) >= LEN(@data)
  BEGIN
    -- Nothing to be masked
    RETURN @data
  END

  -- Set default mask character
  IF @mask_char IS NULL OR @mask_char = ''
  BEGIN
    SET @mask_char = '*'
  END

  -- Init translations (note, sql server has no support for regex)
  DECLARE @digits_letters CHAR(62) = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  DECLARE @translations CHAR(62) = REPLICATE(COALESCE(@mask_char, '*'), LEN(@digits_letters))

  -- Split prefix, middle and suffix
  DECLARE @prefix NVARCHAR(MAX) = LEFT(@data, @unmasked_prefix_len)
  DECLARE @middle NVARCHAR(MAX) = SUBSTRING(@data, @unmasked_prefix_len + 1, LEN(@data) - @unmasked_prefix_len - @unmasked_suffix_len)
  DECLARE @suffix NVARCHAR(MAX) = RIGHT(@data, @unmasked_suffix_len)

  -- Mask the middle part and concat all parts
  RETURN CONCAT(@prefix, TRANSLATE(@middle, @digits_letters, @translations), @suffix)
END;
GO

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT CONNECT TO PUBLIC;
GRANT EXECUTE ON OBJECT::cyral.mask_middle TO PUBLIC;
