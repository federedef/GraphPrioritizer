#!/usr/bin/env python
import argparse
import json
import py_exp_calc.exp_calc as pxc

def load_json(json_path):
    with open(json_path, "r") as f:
        json_dic = json.load(f)
    return json_dic

def parse_value(value):
    value = value.strip()
    if value.startswith("[") and value.endswith("]"):
        value = value[1:-1]
        value = value.split(",")
    return value


parser = argparse.ArgumentParser(description="Add or modify new info on json")
parser.add_argument("-k","--key_id", dest = "key_id", type = lambda x: x.split(";"), help="Add keys separated by ;")
parser.add_argument("-jp", "--json_path", dest = "json_path", help = "Path for json to be modified")
parser.add_argument("-v","--value", dest = "value", type = lambda x: parse_value(x), help="the value to add, assuming [] being a list")
options = parser.parse_args()

json2modify = load_json(options.json_path)
final_key = options.key_id.pop()
final_dic = pxc.dig(json2modify, *options.key_id)
final_dic[final_key] = options.value
new_data = json.dumps(json2modify, indent =4)
with open(options.json_path, "w") as f:
    f.write(new_data)


