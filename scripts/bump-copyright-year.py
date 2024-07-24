#!/usr/bin/env python3

# bumps copyright year to current year in source/hrl files
# adds MPL2.0 license to each source file if missing

import re
import sys
import datetime
import os.path

def get_copyright(filename):
    with open(filename) as fd:
        ref = fd.read()
        found = re.findall('copyright.+2600Hz', ref)
        if len(found) == 1:
            [line] = found
            return (line, ref)
        else:
            return None

def replace_line(filename, new_contents):
    with open(filename, 'w') as fd:
        fd.write(new_contents)

def update_copyright(filename):
    found = get_copyright(filename)
    if found == None:
        return 0
    (line, contents) = found
    year = re.findall('20[0-9]{2}', line)[-1]
    new_line = line.replace(year, str(datetime.datetime.now().year))

    if line != new_line:
        new_contents = contents.replace(line, new_line)
        replace_line(filename, new_contents)
        return 1
    else:
        return 0

replaced = 0
sys.stdout.write("checking copyright: ")
for filename in sys.argv[1:]:
    if (not os.path.isfile(filename)):
        continue

    basename, ext = os.path.splitext(filename)
    if (ext != ".erl"):
        continue

    updated_c = update_copyright(filename)
    if updated_c == 1:
        sys.stdout.write("c")
    else:
        sys.stdout.write(".")

    replaced += updated_c

print(" done")
