import os
from os.path import expanduser
from subprocess import Popen, PIPE, STDOUT
import time
import parse_devicelab_result
import fcntl
from threading import Timer

def kill(p):
    try:
        p.kill()
        print ("################## time out killed ##################")
    except OSError:
        pass # ignore

def nonBlockRead(output):
    fd = output.fileno()
    fl = fcntl.fcntl(fd, fcntl.F_GETFL)
    fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
    try:
        return output.read()
    except:
        return ''

if __name__ == '__main__':
    # get top cid
    home = expanduser("~")
    path = os.path.split(os.path.realpath(__file__))[0] + "/../../../"
    os.chdir(path)
    out_str = os.popen('git log').read().split('\n')
    cid = out_str[0][7:-1]
    print("cid: %s" % cid)

    last_cid_file_path = os.path.split(os.path.realpath(__file__))[0] + "/last_cid.log"
    if not os.path.exists(last_cid_file_path):
        cid_file = open(last_cid_file_path, w)
        cid_file.close()
        print("Create file %s" %last_cid_file_path)
    last_cid = open(last_cid_file_path).readline()
    if last_cid == cid:
        print("cid %s already has data" %last_cid)
        sys.exit(0)
    # get timestamps
    timestamps = int(os.popen('git show -s --format="%ct000" ' + cid).read())

    # run benchmarks
    benchmark_log_dir = "%s/MyProject/benchmark_log/" % home
    if not os.path.exists(benchmark_log_dir):
        os.makedirs(benchmark_log_dir)

    os.chdir("%s/dev/devicelab/" % path)
    log_path = benchmark_log_dir + cid + ".log"
    if os.path.exists(log_path):
        log_path = benchmark_log_dir + cid + "_" + str(int(time.time())) + ".log"
    print("log file path: %s" % log_path)
    log_file = open(log_path, 'w+')

    command = "../../bin/cache/dart-sdk/bin/dart bin/run.dart -a"

    command = command + " >> %s" %log_path
    process = Popen([command], shell=True)
    t = Timer(60 * 60, kill, [process])
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
    parse_devicelab_result.parse_result_log(log_path, "/Library/WebServer/Documents/benchmarks.json", cid, timestamps)
