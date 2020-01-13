#!/usr/bin/env python
import sys
import json
import ruamel.yaml as yaml
from yaml import load, dump

def find_descriptions(d) :
   for key, value in d.items():
        if (key == 'description') and isinstance(value, dict):
          if '$ref' in value:
            target = value['$ref']
            if target.endswith('.md'):
               md_string = '|\n' + open(target, "r").read()
               d[key] = yaml.load (md_string, Loader= yaml.RoundTripLoader)
        elif ((key == 'application/json') or (key == 'example'))and isinstance(value, dict):
          if '$ref' in value:
            target = value['$ref']
            if target.endswith('.yml'):
               with open(target, "r") as f:
                 d[key] = yaml.load(f, Loader=yaml.RoundTripLoader)
          
        elif isinstance(value, dict):
            find_descriptions(value)

        elif isinstance(value, list):
            for item in value:
                if isinstance(item, dict):
                    find_descriptions(item)

try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper

data = load(open(sys.argv[1]).read(), Loader=yaml.RoundTripLoader)

find_descriptions(data)

dump (data,
      open(sys.argv[2], 'w'),
            Dumper=yaml.RoundTripDumper)
