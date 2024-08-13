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


# consistent_mask_hash is a reference implementation of a masking function that
# preserves the format of the input data consistently, such that the same
# input will always produce the same output. It replaces each alphanumeric
# character with a character of the same type (uppercase, lowercase, or digit),
# while leaving all other characters unchanged. The main difference from
# consistent_mask is that it uses the SHA-256 hash function to generate the
# "random" characters, as opposed to a PRNG. This makes it portable across
# systems, as it does not rely on the system's random number generator
# implementation.
def consistent_mask_hash(data):
    resp = []
    if isinstance(data, int):
        ummasked = str(data)
    elif isinstance(data, str):
        unmasked = data
    else:
        return None
    # Explanation of the magic numbers below:
    # 10 is the number of digits (0-9).
    # 48 is the ASCII code for '0'.
    # 26 is the number of letters in the ISO Latin alphabet.
    # 65 is the ASCII code for 'A'.
    # 97 is the ASCII code for 'a'.
    for i, char in enumerate(unmasked):
        if char < '0' or char > 'z':
            resp.append(char)
        else:
            hash_bytes = hashlib.sha256((str(i) + data).encode()).digest()
            # Use the first 4 bytes of the hash as a "random" number.
            rand = int.from_bytes(hash_bytes[:4])
            if '0' <= char <= '9':
                resp.append(chr(rand % 10 + 48))
            if 'A' <= char <= 'Z':
                resp.append(chr(rand % 26 + 65))
            elif 'a' <= char <= 'z':
                resp.append(chr(rand % 26 + 97))
    masked = "".join(resp)
    return masked if isinstance(data, str) else int(masked)


return consistent_mask_hash(data)
$$ LANGUAGE plpythonu;
