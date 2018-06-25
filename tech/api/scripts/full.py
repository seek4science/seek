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

master_definitions_url = 'https://raw.githubusercontent.com/seek4science/seek/master/public/2010/json/rest/definitions.json'

headers = {"Accept-Charset": "ISO-8859-1"}

session = requests.Session()
session.headers.update(headers)

r = session.get(master_definitions_url)
r.raise_for_status()
definitions_json = r.text.replace('\r', '')


definitions_json_file = open('definitions.json', 'w', encoding='utf-8')
definitions_json_file.write(definitions_json)
definitions_json_file.close()

# Check examples against schema

v = json.loads(definitions_json)
x = v['definitions']
y = x['assayPatch']
validator = jsonschema.Draft4Validator(y)
print (type(y))

directory = os.fsencode('../examples')

for file in os.listdir(directory):
    filename = os.fsdecode(file)
    if filename.endswith("Patch.yml"):
        print (filename)
        print (filename[:-4])
        example = load(open(os.path.join(directory, file)).read(), Loader=ruamel.yaml.RoundTripLoader)

        validator.validate(example, y)
        continue
    else:
        continue

# Convert to yaml

payload = {'q' : definitions_json}
r = requests.post('https://www.json2yaml.com/api/j2y', data=payload)
r.raise_for_status()
definitions_yaml = r.text

definitions_yaml_file = open('definitions.yml', 'w', encoding='utf-8')
definitions_yaml_file.write(definitions_yaml)
definitions_yaml_file.close()

def walk_tree(base):
    if isinstance(base, dict):
        for k in base.keys():
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

operations = load(open('..\definitions\operations.yml').read(), Loader=ruamel.yaml.RoundTripLoader)

new_definitions = load(open('definitions.yml').read(), Loader=ruamel.yaml.RoundTripLoader)

walk_tree (new_definitions['definitions'])

operations['definitions'] = new_definitions['definitions']

redocSeekFile = open('redocSeek.yml', 'w')
dump (operations,
      redocSeekFile,
            Dumper=ruamel.yaml.RoundTripDumper)
redocSeekFile.close()

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

full_data = load(open('redocSeek.yml').read(), Loader=ruamel.yaml.RoundTripLoader)

find_descriptions(full_data)

dump (full_data,
      open('swaggerSeek.yml', 'w'),
            Dumper=ruamel.yaml.RoundTripDumper)
