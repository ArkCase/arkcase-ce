#!/usr/bin/env python3

import bcrypt
import sys

passwd = sys.argv[1]
salt = bcrypt.gensalt(rounds=10)
hashed = bcrypt.hashpw(passwd, salt)
print(hashed.replace("$2b$","$2a$"))