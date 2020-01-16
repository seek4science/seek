#!/usr/bin/env python

import requests
import sys
import json
import ruamel
from ruamel.yaml import load, dump, CLoader as Loader, CDumper as Dumper
from pprint import pprint
from collections import OrderedDict
import jsonschema
import os
import zipfile, io

definitions_json_file = open('../definitions/definitions.json', 'r', encoding='utf-8')
definitions_json = definitions_json_file.read()
definitions_json_file.close()

# Convert to yaml

payload = {'q' : definitions_json}
r = requests.post('https://www.json2yaml.com/api/j2y', data=payload)
r.raise_for_status()
definitions_yaml = r.text


def walk_tree(base):
    if isinstance(base, dict):
        for k in base.keys():
          v = base[k]
          if (k == 'oneOf') :
            if ('type' in v[1]) : 
              base['allOf'] = [v[0]]

              base['x-nullable'] = True
            else:
              base['x-oneOf'] = v
            del base['oneOf']
          else:
            walk_tree(v)
          if (k.endswith('Post') or k.endswith('Patch')):
            v['example'] = {'$ref' : "../examples/{0}.yml".format(k)}
    elif isinstance(base, list):
        for idx, elem in enumerate(base):
            walk_tree(elem)

operations = load(open('../definitions/operations.yml').read(), Loader=ruamel.yaml.RoundTripLoader)

new_definitions = load(definitions_yaml, Loader=ruamel.yaml.RoundTripLoader)

walk_tree (new_definitions['definitions'])

operations['definitions'] = new_definitions['definitions']

def find_descriptions(d) :
   for key, value in d.items():
        if (key == 'description') and isinstance(value, dict):
          if '$ref' in value:
            target = value['$ref']
            if target.endswith('.md'):
               md_string = '|\n' + open(target, "r").read()
               d[key] = ruamel.yaml.load (md_string, Loader= ruamel.yaml.RoundTripLoader)
        elif ((key == 'application/json') or (key == 'example'))and isinstance(value, dict):
          if '$ref' in value:
            target = value['$ref']
            if target.endswith('.yml'):
               with open(target, "r") as f:
                 d[key] = ruamel.yaml.load(f, Loader=ruamel.yaml.RoundTripLoader)
          
        elif isinstance(value, dict):
            find_descriptions(value)

        elif isinstance(value, list):
            for item in value:
                if isinstance(item, dict):
                    find_descriptions(item)

full_data = operations

find_descriptions(full_data)

dump (full_data,
      open('../definitions/swaggerSeek.yml', 'w'),
            Dumper=ruamel.yaml.RoundTripDumper)
