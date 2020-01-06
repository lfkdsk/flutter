import os
import sys
import json
import time
from datetime import datetime

average_list = [
    'average_frame_build_time_millis',
    'average_frame_rasterizer_time_millis'
]
exclusion_list = [
    'missed_frame_build_budget_count',
    'missed_frame_rasterizer_budget_count',
    'missed_transition_count'
]
def gen_weight_json(path):
    if not os.path.exists(path):
        print("path %s not exit." % path)
        return {}
    json_data = json.load(open(path))
    weight_json = {}
    for key, value in json_data.items():
        subJsonObj = {}
        has_data = False
        for subKey in value.keys():
            if subKey in average_list:
                subJsonObj[subKey] = 3
                has_data = True
            elif not subKey in exclusion_list:
                subJsonObj[subKey] = 1
                has_data = True
        if has_data:
            weight_json[key] = subJsonObj
    return weight_json


if __name__ == '__main__':
    path = sys.argv[1]
    weight_json = gen_weight_json(path)
    weight_json_path = "weight.json"
    if os.path.exists(weight_json_path):
        weight_json_path = "weight_%s.json" % str(datetime.utcfromtimestamp(int(time.time())).strftime('%Y-%m-%d-%H-%M-%S'))
    print("weight josn path: %s" %weight_json_path)
    with open(weight_json_path, 'w') as outFile:
        json.dump(weight_json, outFile, indent=4)
        outFile.close()