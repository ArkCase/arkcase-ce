#!/usr/bin/env python
import sys
import hashlib
passwd = sys.argv[1]
passwd.encode('utf-16le')
print hashlib.new('md4', passwd.encode('utf-16le')).hexdigest()