#!/usr/bin/env python
import sys
import json
import ruamel.yaml as yaml
from yaml import load, dump

def walk_tree(base):
    if isinstance(base, dict):
        for k in base:
          v = base[k]
          if (k == 'oneOf') :
            base['allOf'] = [v[0]]
            del base['oneOf']
            base['x-nullable'] = True
          else:
            walk_tree(v)
          if (k.endswith('Post') or k.endswith('Patch')):
            v['example'] = {'$ref' : "../examples/{0}.yml".format(k)}
    elif isinstance(base, list):
        for idx, elem in enumerate(base):
            walk_tree(elem)

try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper

data = load(open(sys.argv[1]).read(), Loader=yaml.RoundTripLoader)

new_data = load(open(sys.argv[2]).read(), Loader=yaml.RoundTripLoader)

walk_tree (new_data['definitions'])

data['definitions'] = new_data['definitions']

dump (data,
      sys.stdout,
            Dumper=yaml.RoundTripDumper)
