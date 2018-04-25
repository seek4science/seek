#!/usr/bin/env python
import sys
import re
from os import listdir
from os.path import isfile, splitext
from shutil import copyfile


for o in ['Post', 'Patch']:
  onlyfiles = [f for f in listdir("../examples") if re.match(r'.*' + o + '\.yml', f)]

  print onlyfiles

  for f in onlyfiles:
    response = re.sub(o, 'Response', f)
    print response
    parts = response.split('_')
    response = ''.join(word[0].upper() + word[1:] for word in parts)
    print response
    response = response[0].lower() + response[1:]
    print response
    t = re.sub('Response', o + 'Response', response)
    if isfile('../examples/' + response):
      copyfile('../examples/' + response, '../examples/' + t)
