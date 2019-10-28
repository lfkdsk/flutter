import os
from os.path import expanduser
import time
import parse_devicelab_result
import fcntl
from datetime import datetime
import subprocess
import avg_json
import sys
from threading import Timer
from subprocess import Popen, PIPE, STDOUT
import argparse


def kill(p):
    try:
        p.kill()
        print ("################## time out killed ##################")
    except OSError:
        pass  # ignore


def nonBlockRead(output):
    fd = output.fileno()
    fl = fcntl.fcntl(fd, fcntl.F_GETFL)
    fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
    try:
        return output.read()
    except:
        return ''


def run_devicelab(args, path, task_list, stage_name, result_log_file, log_path_dir):
    # get top cid
    home = expanduser("~")
    os.chdir(path)
    out_str = os.popen('git log').read().split('\n')
    cid = out_str[0][7:-1]
    print("cid: %s" % cid)

    # get timestamps
    timestamps = int(os.popen('git show -s --format="%ct000" ' + cid).read())

    # run benchmarks
    benchmark_log_dir = log_path_dir
    if not os.path.exists(benchmark_log_dir):
        os.makedirs(benchmark_log_dir)

    os.chdir("%s/dev/devicelab/" % path)
    log_path = os.path.join(log_path_dir, cid + \
               "_" + datetime.fromtimestamp(int(time.time())).strftime('%Y-%m-%d-%H-%M-%S') + ".log")
    print("log file path: %s" % log_path)
    log_file = open(log_path, 'w+')

    os.system('export PUB_HOSTED_URL=https://pub.dev/')

    is_all = False
    task_str = ''
    for name in task_list:
        if name == 'all':
            is_all = True
            break
        else:
            task_str = task_str + " -t " + name
    command = 'export LANG=en_US.UTF-8 && '
    if is_all:
        command = command + "../../bin/cache/dart-sdk/bin/dart bin/run.dart -a"
    else:
        command = command + "../../bin/cache/dart-sdk/bin/dart bin/run.dart %s" % task_str
    if len(stage_name) > 0:
        command = command + "../../bin/cache/dart-sdk/bin/dart bin/run.dart -s %s" % stage_name
    if args.local_engine_src_path != '' and args.local_engine != '':
        command = command + ' --local-engine-src-path=%s --local-engine=%s' % (
            args.local_engine_src_path, args.local_engine)
    command = command + " >> " + log_path
    print(command)
    # os.system(command)
    process = Popen([command], shell=True)
    t = Timer(int(args.timeout) * 60, kill, [process])
    t.start()
    try:
        process.wait()
    except KeyboardInterrupt:
        print("KeyboardInterrupt by User")
        try:
            process.terminate()
        except OSError:
            pass
    t.cancel()
    print("####################################")
    print("####            DONE            ####")
    print("####################################")
    parse_devicelab_result.parse_result_log(log_path, result_log_file)


def parse_args(args):
    args = args[1:]
    parser = argparse.ArgumentParser(description='A script run` benckmark test`.')
    parser.add_argument('--out-path', default='')
    parser.add_argument('--local-engine-src-path', default='')
    parser.add_argument('--local-engine', default='')
    parser.add_argument('--round-times', default=20)
    parser.add_argument('--timeout', default=60)
    parser.add_argument('--devicelab', type=str, choices=['all', 'devicelab', 'devicelab_ios'])
    parser.add_argument('--tasks-file', type=str, default='')
    return parser.parse_args(args)


if __name__ == '__main__':
    args = parse_args(sys.argv)
    input_path = ''
    if args.out_path != '':
        input_path = args.out_path
        print("input_path: %s" % input_path)
    path = os.getcwd() + "/../../.."

    task_list = []
    # if args.tasks_file == '':
    #     args.tasks_file = './tasks_file'
    if args.tasks_file != '' and os.path.exists(args.tasks_file):
        for task in open(args.tasks_file).readlines():
            if len(task) > 3:
                task_adjust = task.split(',')[0].split('\n')[0].split(';')[0]
                if not (task_adjust in task_list):
                    task_list.append(task_adjust)
    stage_name = ""
    if len(task_list) == 0:
        if args.devicelab == 'all':
            task_list = ['all']
        else:
            stage_name = args.devicelab

    result_out_path = input_path
    if len(result_out_path) == 0:
        result_out_path = os.getcwd() + "/flutter_benckmarks_%s" % str(
            datetime.fromtimestamp(int(time.time())).strftime('%Y-%m-%d-%H-%M-%S'))
    if not os.path.exists(result_out_path):
        os.mkdir(result_out_path)
    else:
        print result_out_path + " already exit. Do your want replace ? "
        input_result = raw_input(" y or n ? ")
        if input_result == 'y' or input_result == 'Y':
            pass
        else:
            print "benckmarks is exit, please input a new out dir."
            exit()
    log_path = os.path.join(result_out_path, 'log')
    log_path = os.path.abspath(log_path)
    round_times = int(args.round_times)
    for round in range(0, round_times):
        print("################## round = " + str(round + 1)
              + " cut_time = %s #################\n"
              % datetime.fromtimestamp(int(time.time())).strftime('%Y-%m-%d-%H-%M-%S'))
        subprocess.call(['ps | grep iproxy | grep -v grep | cut -c 1-5 | xargs kill'], shell=True)
        subprocess.call(['ps | grep idevicesyslog | grep -v grep | cut -c 1-5 | xargs kill'], shell=True)
        subprocess.call(['ps | grep "dart-sdk/bin/dart" | grep -v grep | cut -c 1-5 | xargs kill'], shell=True)
        subprocess.call(['ps | grep "ios-deploy" | grep -v grep | cut -c 1-5 | xargs kill'], shell=True)
        subprocess.call(['ps | grep "/Applications/Xcode.app/Contents/Developer/usr/bin/lldb" | grep -v grep | cut -c 1-5 | xargs kill'], shell=True)
        cur = time.time()
        os.chdir(result_out_path)
        result_out_path = os.getcwd()
        result_json_path = os.path.join(os.getcwd(), str(round) + ".json")
        if (not os.path.isfile(result_json_path)):
            file = open(result_json_path, 'w')
            file.write("{}")
            file.close()
        run_devicelab(args, path, task_list, stage_name, result_json_path, log_path)
        if round == 0:
            cost_time = int((time.time() - cur) / 60 * 1.2)
            set_timeout = args.timeout
            args.timeout = max(args.timeout, cost_time)
            if set_timeout != args.timeout:
                print("Set timeout is %d min, and adjust time to %d min" %(set_timeout, args.timeout))
        print("#### cost time: %d s" % (time.time() - cur))
        print("################## endround = " + str(round + 1)
              + " end_time = %s #################\n\n"
              % datetime.fromtimestamp(int(time.time())).strftime('%Y-%m-%d-%H-%M-%S'))

    avg_json.avg_json(result_out_path)
    print("##### result_dir= %s #####" % result_out_path)
