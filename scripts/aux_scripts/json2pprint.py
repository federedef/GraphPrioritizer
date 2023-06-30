#!/usr/bin/env python

import json

with open("net2json","r") as f:
    print(type(f))
    h = json.load(f)

print(json.dumps(h, indent="\t"))
