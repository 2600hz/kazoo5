#!/usr/bin/env python3

# print 'Usage: ' + sys.argv[0] + ' file.json+'

import os
import sys
import json


if len(sys.argv) < 2:
    pass

json.encoder.FLOAT_REPR = str
for fn in sys.argv[1:]:
    fn2 = fn + '~'
    with open(fn) as fd:
        try:
            data = json.load(fd)
            data2 = json.dumps(data, sort_keys=True, indent=4, separators=(",", ": "))
        except ValueError as e:
            print(fn + ": " + str(e))
            exit(1)

        with open(fn2, 'w') as fd2:
            written = fd2.write(data2 + '\n')
            fd2.close()

        fd.close()

        os.replace(fn2, fn)
