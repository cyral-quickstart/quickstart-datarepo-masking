-- 1. Create a new database and schema for storing the desired UDFs:
CREATE DATABASE cyral;
GO
USE cyral;
GO
CREATE SCHEMA cyral;
GO

-- 2. Create the new function in the target schema:
CREATE OR ALTER FUNCTION cyral.mask_string(@input_string NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @masked_string NVARCHAR(MAX) = '';
    DECLARE @i INT = 1;

    -- Iterate through each character of the input string and replace with '*'
    WHILE @i <= LEN(@input_string)
    BEGIN
        SET @masked_string = @masked_string + '*';
        SET @i = @i + 1;
    END;

    -- Return the masked string
    RETURN @masked_string;
END;
GO

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT CONNECT TO PUBLIC;
GRANT EXECUTE ON OBJECT::cyral.mask_string TO PUBLIC;