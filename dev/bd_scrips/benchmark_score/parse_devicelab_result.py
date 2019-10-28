#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import re
import json
import time
import copy


def parse_result_log(filePath, totalResultJsonFile):
    if not os.path.exists(filePath):
        print("log file is not exit")
    logFile = open(filePath)

    taskName = ''
    taskStart = False
    taskResultStart = False
    taskResultJsonStr = ''
    DataMissing = False

    totalResultJson = json.load(open(totalResultJsonFile))


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
                result_obj = {}
                for benchmarkScoreKey in json_string['benchmarkScoreKeys']:
                    if benchmarkScoreKey in json_string['data'].keys():
                        value = json_string['data'][benchmarkScoreKey]
                        result_obj[benchmarkScoreKey] = value
                totalResultJson[taskName] = result_obj

        elif taskStart:
            if line.startswith("Task result:"):
                taskResultStart = True
                taskStart = False
        elif taskResultStart:
            taskResultJsonStr = taskResultJsonStr + line

    with open(totalResultJsonFile, 'w') as outfile:
        json.dump(totalResultJson, outfile, indent=4)
        outfile.close()


if __name__ == '__main__':
    filePath = '/Users/linxuebin/Desktop/ci-all-new.log'
