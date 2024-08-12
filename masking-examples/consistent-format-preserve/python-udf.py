import hashlib
import random


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
