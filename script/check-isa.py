# -*- coding: utf-8 -*-

import subprocess
import sys
import isatools
from isatools.model import *
import io

### MAIN CODE

with open(sys.argv[1], 'r') as myfile:
  td = myfile.read()

x = isatools.isajson.validate(io.StringIO(td))

try:
  i = isatools.isajson.load(io.StringIO(td))
  y = True
except Exception as e:
  print('isatools error: '+ repr(e), file=sys.stderr)
  y = False

if x['errors'] or x['warnings'] or not y:
    print("Not OK")

exit()
