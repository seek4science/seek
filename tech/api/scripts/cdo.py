#!/usr/bin/env python
import sys
from os import listdir
from os.path import isfile, splitext
import inflection

onlyfiles = [splitext(f)[0].capitalize() for f in listdir("../descriptions") if isfile("../descriptions/" + f)]

allOperations = []
for f in onlyfiles:
    allOperations+= ["list"+ f];
    s = inflection.singularize(f)
    allOperations+= ["create"+ s];
    allOperations+= ["read"+ s];
    allOperations+= ["update"+ s];
    allOperations+= ["delete"+ s];

print allOperations

for f in allOperations:
    fh = open("../descriptions/" + f + ".md", "w")
    fh.write("This is a " + f + " description")
    fh.close()
