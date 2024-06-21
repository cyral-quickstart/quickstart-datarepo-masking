CREATE OR ALTER FUNCTION ${SCHEMA}.mask_ccn(@unmasked_data NVARCHAR(MAX))
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
