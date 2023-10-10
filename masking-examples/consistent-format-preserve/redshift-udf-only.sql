CREATE OR REPLACE FUNCTION ${SCHEMA}.consistent_mask(input_string TEXT)
RETURNS TEXT
STABLE
AS
$$
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


def consistent_mask(input_string):
    random = Random(str(input_string))
    return "".join(generate_random_char(random, cur_char) for cur_char in input_string)


return consistent_mask(input_string)
$$ LANGUAGE plpythonu;