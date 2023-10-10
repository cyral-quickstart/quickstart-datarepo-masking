-- 1. Create a new schema for storing the desired UDFs:
CREATE SCHEMA IF NOT EXISTS cyral;

-- 2. Create the new function in the target schema:
CREATE OR REPLACE FUNCTION cyral.consistent_mask(data ANYELEMENT)
RETURNS ANYELEMENT
STABLE
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


return consistent_mask(data)
$$ LANGUAGE plpythonu;

-- 3. Grant the execution privilege to everyone, through the PUBLIC role
GRANT EXECUTE ON FUNCTION cyral.consistent_mask(data ANYELEMENT) TO PUBLIC;
