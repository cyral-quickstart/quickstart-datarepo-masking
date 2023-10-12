CREATE OR REPLACE FUNCTION ${DB}.${SCHEMA}."consistent_mask"(field_value VARIANT)
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

CREATE OR REPLACE FUNCTION ${DB}.${SCHEMA}."consistent_mask"(field_value BOOLEAN)
    RETURNS BOOLEAN
AS
$$
    ${DB}.${SCHEMA}."consistent_mask"(TO_VARIANT(field_value))::BOOLEAN
$$;

CREATE OR REPLACE FUNCTION ${DB}.${SCHEMA}."consistent_mask"(field_value FLOAT)
    RETURNS FLOAT
AS
$$
    ${DB}.${SCHEMA}."consistent_mask"(TO_VARIANT(field_value))::FLOAT
$$;

CREATE OR REPLACE FUNCTION ${DB}.${SCHEMA}."consistent_mask"(field_value INT)
    RETURNS INT
AS
$$
    ${DB}.${SCHEMA}."consistent_mask"(TO_VARIANT(field_value))::INT
$$;

CREATE OR REPLACE FUNCTION ${DB}.${SCHEMA}."consistent_mask"(field_value NUMBER)
    RETURNS NUMBER
AS
$$
    ${DB}.${SCHEMA}."consistent_mask"(TO_VARIANT(field_value))::NUMBER
$$;

CREATE OR REPLACE FUNCTION ${DB}.${SCHEMA}."consistent_mask"(field_value VARCHAR)
    RETURNS VARCHAR
AS
$$
    ${DB}.${SCHEMA}."consistent_mask"(TO_VARIANT(field_value))::VARCHAR
$$;
