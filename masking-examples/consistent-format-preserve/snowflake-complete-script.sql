-- 1. Create a new database for storing all your UDFs for custom masking
CREATE DATABASE IF NOT EXISTS CYRAL;

-- 2. Allow everyone to access the new database
GRANT USAGE ON DATABASE CYRAL TO PUBLIC;

-- 3. Create a new schema for holding the UDFs
CREATE SCHEMA IF NOT EXISTS CYRAL.CYRAL;

-- 4. Allow everyone to access the new schema
GRANT USAGE ON SCHEMA CYRAL.CYRAL TO PUBLIC;

-- 5. Create the new function in the target schema
CREATE OR REPLACE FUNCTION CYRAL.CYRAL."consistent_mask"(field_value VARIANT)
    RETURNS VARIANT
    LANGUAGE python
    RUNTIME_VERSION = '3.8'
    HANDLER = 'consistent_mask'
AS
$$
import decimal
import re
import string
from random import Random


def generate_random_char(random, current_char):
    if re.search("[A-Z]", current_char):
        return random.choice(string.ascii_uppercase)

    if re.search("[a-z]", current_char):
        return random.choice(string.ascii_lowercase)

    if re.search("[0-9]", current_char):
        return str(random.randrange(10))

    return current_char


def consistent_mask(input_value):
    random = Random(str(input_value))

    # Boolean testing needs to come before int since boolean is a subclass of int
    if isinstance(input_value, bool):
        return random.choice((True, False))

    if isinstance(input_value, str):
        return "".join(generate_random_char(random, cur_char) for cur_char in input_value)

    if isinstance(input_value, (int, float, decimal.Decimal)):
        value_type = type(input_value)
        if int(input_value) <= 0:
            return value_type(random.randint(1, 10))
        return value_type(random.randrange(int(input_value)))

    # We have no idea what to do so we return NULL
    return None
$$;

CREATE OR REPLACE FUNCTION CYRAL.CYRAL."consistent_mask"(field_value BOOLEAN)
    RETURNS BOOLEAN
AS
$$
    CYRAL.CYRAL."consistent_mask"(TO_VARIANT(field_value))::BOOLEAN
$$;

CREATE OR REPLACE FUNCTION CYRAL.CYRAL."consistent_mask"(field_value FLOAT)
    RETURNS FLOAT
AS
$$
    CYRAL.CYRAL."consistent_mask"(TO_VARIANT(field_value))::FLOAT
$$;

CREATE OR REPLACE FUNCTION CYRAL.CYRAL."consistent_mask"(field_value INT)
    RETURNS INT
AS
$$
    CYRAL.CYRAL."consistent_mask"(TO_VARIANT(field_value))::INT
$$;

CREATE OR REPLACE FUNCTION CYRAL.CYRAL."consistent_mask"(field_value NUMBER)
    RETURNS NUMBER
AS
$$
    CYRAL.CYRAL."consistent_mask"(TO_VARIANT(field_value))::NUMBER
$$;

CREATE OR REPLACE FUNCTION CYRAL.CYRAL."consistent_mask"(field_value VARCHAR)
    RETURNS VARCHAR
AS
$$
    CYRAL.CYRAL."consistent_mask"(TO_VARIANT(field_value))::VARCHAR
$$;

-- 6. Grant the execution privilege to everyone, through the PUBLIC role
GRANT USAGE ON FUNCTION CYRAL.CYRAL."consistent_mask"(VARIANT) TO PUBLIC;
GRANT USAGE ON FUNCTION CYRAL.CYRAL."consistent_mask"(BOOLEAN) TO PUBLIC;
GRANT USAGE ON FUNCTION CYRAL.CYRAL."consistent_mask"(FLOAT) TO PUBLIC;
GRANT USAGE ON FUNCTION CYRAL.CYRAL."consistent_mask"(INT) TO PUBLIC;
GRANT USAGE ON FUNCTION CYRAL.CYRAL."consistent_mask"(NUMBER) TO PUBLIC;
GRANT USAGE ON FUNCTION CYRAL.CYRAL."consistent_mask"(VARCHAR) TO PUBLIC;
