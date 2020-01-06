import os
import sys
import json

def avg_json(path):
    if not os.path.exists(path):
        print("path %s not exit." % path)
    else:
        jsonList = []
        for filePath in os.listdir(path):
            if filePath.endswith(".json") and filePath != "avgJson.json":
                print("file Name %s" % filePath)
                with open(os.path.join(path, filePath), 'r') as jsonFile:
                    jsonList.append(json.load(jsonFile))
        jsonLen = len(jsonList)
        avgJson = {}
        for_index = 0
        max_len = 0
        for index in range(0, jsonLen):
            if len(jsonList[index].keys()) > max_len:
                for_index = index
                max_len = len(jsonList[index].items())
        for key, value in jsonList[for_index].items():
            subJsonObj = {}
            for subKey in value.keys():
                v1 = 0
                index = 0
                for jsonObj in jsonList:
                    if key in jsonObj and subKey in jsonObj[key]:
                        subValue = float(jsonObj[key][subKey])
                        v1 = v1 + subValue
                        index = index + 1
                subJsonObj[subKey] = round(v1 / index, 5)
            avgJson[key] = subJsonObj
        with open(os.path.join(path, "avgJson.json"), 'w') as outFile:
            json.dump(avgJson, outFile)
            outFile.close()

if __name__ == '__main__':
    path = sys.argv[1]
    avg_json(path)