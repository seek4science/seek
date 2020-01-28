#! /bin/bash
for i in *.yml
do
    f="$(basename -- $i .yml)"
    echo $f.json
python -c 'import json, sys, yaml ; y=yaml.safe_load(sys.stdin.read()) ; json.dump(y, sys.stdout, indent=4)' < $i > $f.json
done

