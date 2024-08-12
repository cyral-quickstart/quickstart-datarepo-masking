import hashlib
import random


# consistent_mask is a reference implementation of a masking function that
# preserves the format of the input data consistently, such that the same
# input will always produce the same output. It replaces each alphanumeric
# character with a random character of the same type (uppercase, lowercase,
# or digit), while leaving all other characters unchanged.
def consistent_mask(data):
    rand = random.Random(data)
    resp = []
    for char in data:
        if 'A' <= char <= 'Z':
            # 65 = ASCII code for 'A', 90 = ASCII code for 'Z'.
            resp.append(chr(rand.randint(65, 90)))
        elif 'a' <= char <= 'z':
            # 97 = ASCII code for 'a', 122 = ASCII code for 'z'.
            resp.append(chr(rand.randint(97, 122)))
        elif '0' <= char <= '9':
            # 48 = ASCII code for '0', 57 = ASCII code for '9'.
            resp.append(chr(rand.randint(48, 57)))
        else:
            resp.append(char)
    return "".join(resp)


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
    # Explanation of some magic numbers below:
    # 26 is the number of letters in the ISO Latin alphabet.
    # 65 is the ASCII code for 'A'.
    # 97 is the ASCII code for 'a'.
    # 48 is the ASCII code for '0'.
    # 10 is the number of digits (0-9).
    for i, char in enumerate(data):
        hash_hex = hashlib.sha256((str(i) + data).encode()).hexdigest()
        if 'A' <= char <= 'Z':
            resp.append(chr((ord(char) - 65 + int(hash_hex[i % len(hash_hex)], 16)) % 26 + 65))
        elif 'a' <= char <= 'z':
            resp.append(chr((ord(char) - 97 + int(hash_hex[i % len(hash_hex)], 16)) % 26 + 97))
        elif '0' <= char <= '9':
            resp.append(chr((ord(char) - 48 + int(hash_hex[i % len(hash_hex)], 16)) % 10 + 48))
        else:
            resp.append(char)
    return "".join(resp)
