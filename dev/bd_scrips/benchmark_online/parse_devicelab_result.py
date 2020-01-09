#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import re
import json
import tos_helper
import time
import copy

def inset_result_to_json(result_json, key, valueObj, need_replace):
    json_arrays = result_json['Benchmarks']
    insert_success = False
    last_obj = {}
    for obj in json_arrays:
        if obj['Timeseries']['Timeseries']['ID'] == key:
            if not need_replace:
                obj['Values'].insert(0, valueObj)
            else:
                obj['Values'][0] = valueObj
            insert_success = True
            break
        last_obj = obj
    if not insert_success:
        clone_obj = copy.deepcopy(last_obj)
        clone_obj["Values"] = []
        clone_obj['Values'].insert(0, valueObj)
        clone_obj['Timeseries']['Timeseries']['ID'] = key
        clone_obj['Timeseries']['Key'] = key
        clone_obj['Timeseries']['TaskName'] = key.split('.')[0]
        clone_obj['Timeseries']['Label'] = key.split('.')[1]
        json_arrays.append(clone_obj)

def flush_invalid_value(result_json, CreateTimestamp, Revision):
    valid_obj = {}
    valid_obj['CreateTimestamp'] = CreateTimestamp
    valid_obj['Revision'] = Revision
    valid_obj['TaskKey'] = Revision
    valid_obj['Value'] = 0
    valid_obj['DataMissing'] = True
    for obj in result_json['Benchmarks']:
        tmp_obj = copy.deepcopy(valid_obj)
        obj["Values"].insert(0, tmp_obj)


def parse_result_log(filePath, totalResultJsonFile, revision, timestamp):
    if not os.path.exists(filePath):
        print("log file is not exit")
    logFile = open(filePath)

    taskName = ''
    taskStart = False
    taskResultStart = False
    taskResultJsonStr = ''
    CreateTimestamp = timestamp
    Revision = revision
    TaskKey = revision
    DataMissing = False

    totalResultJson = json.load(open(totalResultJsonFile))
    # totalResultJson = tos_helper.get_benchmark_json(
    #     'http://tosv.byted.org/obj/ttclient-android-crashinfo/benchmark/benchmark.json')

    # insert invalid value in totalResultJson
    flush_invalid_value(totalResultJson, CreateTimestamp, Revision)

    for line in logFile.readlines():
        if line.__contains__('••• Running task '):
            taskStart = True
            taskResultJsonStr = ''
            print('line: %s' % line)
            taskName = re.findall(r'••• Running task "(.*?)" •••', line)[0]
            print('[task %s start]' % taskName)
        elif line.__contains__('••• Finished task "%s" •••' % taskName):
            taskStart = False
            taskResultStart = False
            print('[task %s end]' % taskName)
            json_string = json.loads(taskResultJsonStr)
            print(json_string)

            if json_string['success']:
                for benchmarkScoreKey in json_string['benchmarkScoreKeys']:
                    if benchmarkScoreKey in json_string['data'].keys():
                        value = json_string['data'][benchmarkScoreKey]
                        obj = {}
                        obj['CreateTimestamp'] = CreateTimestamp
                        obj['Revision'] = Revision
                        obj['TaskKey'] = TaskKey
                        if value > 0:
                            obj['Value'] = value
                            obj['DataMissing'] = False
                        else:
                            obj['Value'] = value
                            obj['DataMissing'] = True
                        inset_result_to_json(totalResultJson, taskName + "." + benchmarkScoreKey, obj, True)

        elif taskStart:
            if line.startswith("Task result:"):
                taskResultStart = True
                taskStart = False
        elif taskResultStart:
            taskResultJsonStr = taskResultJsonStr + line

    # print(totalResultJson)
    tos_helper.upload_file("ttclient-android-crashinfo",
                           "NTD082DDQDJZ2TTS38KS", "benchmark/benchmark_%s_%s.json"%(revision, str(int(time.time()))),
                           totalResultJson, "application/json")
    with open(totalResultJsonFile, 'w') as outfile:
        json.dump(totalResultJson, outfile, indent=4)
        outfile.close()


if __name__ == '__main__':
    filePath = '/Users/linxuebin/Desktop/ci-all-new.log'
