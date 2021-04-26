#!/usr/bin/env python3

import bcrypt
import sys

passwd = sys.argv[1]
b = passwd.encode('utf-8')
hashed = bcrypt.hashpw(b, bcrypt.gensalt(rounds=10)).decode('utf-8')
print(hashed.replace("$2b$","$2a$"))