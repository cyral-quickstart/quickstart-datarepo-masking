-- 1. Create a new database and schema for storing the desired UDFs:
CREATE DATABASE cyral;
GO
USE cyral;
GO
CREATE SCHEMA cyral;
GO

-- 2. Create the new function in the target schema:
CREATE OR ALTER FUNCTION cyral.mask_ccn(@unmasked_data NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
  IF @unmasked_data IS NULL
  BEGIN
    RETURN NULL
  END
  IF LEN(@unmasked_data) <= 4
  BEGIN
    RETURN @unmasked_data
  END
  RETURN CONCAT(TRANSLATE(LEFT(@unmasked_data, LEN(@unmasked_data) - 4), '0123456789', '**********'), RIGHT(@unmasked_data, 4))
END;
GO

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT CONNECT TO PUBLIC;
GRANT EXECUTE ON OBJECT::cyral.mask_ccn TO PUBLIC;
