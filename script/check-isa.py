# -*- coding: utf-8 -*-

import subprocess
import sys

# import isatools

import isatools
from isatools.model import *
import io

### MAIN CODE

ofile = open('/tmp/check-isa-output', 'w')

with open(sys.argv[1], 'r') as myfile:
  td = myfile.read()

x = isatools.isajson.validate(io.StringIO(td))

try:
  i = isatools.isajson.load(io.StringIO(td))
  y = True
except:
    y = False

if not x['errors'] and not x['warnings'] and y:
    ofile.write('')
else:
    ofile.write('Not OK')

ofile.close()

exit()

