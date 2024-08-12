CREATE OR REPLACE FUNCTION ${SCHEMA}.consistent_mask(data ANYELEMENT)
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

CREATE OR REPLACE FUNCTION ${SCHEMA}.consistent_mask_hash(data ANYELEMENT)
    RETURNS ANYELEMENT
    STABLE
AS
$$
import hashlib


def consistent_mask_hash(data):
    resp = []
    for i, char in enumerate(data):
        hash_hex = hashlib.sha256((str(i) + data).encode()).hexdigest()
        if 'A' <= char <= 'Z':
            # 65 = ASCII code for 'A', mod 26 to wrap around.
            resp.append(chr((ord(char) - 65 + int(hash_hex[i % len(hash_hex)], 16)) % 26 + 65))
        elif 'a' <= char <= 'z':
            # 97 = ASCII code for 'a', mod 26 to wrap around.
            resp.append(chr((ord(char) - 97 + int(hash_hex[i % len(hash_hex)], 16)) % 26 + 97))
        elif '0' <= char <= '9':
            # 48 = ASCII code for '0', mod 10 to wrap around.
            resp.append(chr((ord(char) - 48 + int(hash_hex[i % len(hash_hex)], 16)) % 10 + 48))
        else:
            resp.append(char)
    return "".join(resp)


return consistent_mask_hash(data)
$$ LANGUAGE plpythonu;
