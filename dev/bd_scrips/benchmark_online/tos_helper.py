import json
import requests


def find_tos(server):
    url_str = ("http://10.8.124.82:2280/v1/lookup/name?name=%s" % server)
    resp = requests.get(url_str)
    if len(resp.content) > 0:
        array = json.loads(resp.content)
        if len(array) > 0:
            obj = array[0]
            if "Host" in obj and "Port" in obj:
                return "%s:%s" % (obj["Host"], obj["Port"])

    return ""


def upload_file(bucket, access, file, json_data, ctype):
    host = find_tos("toutiao.tos.tosapi")
    if len(host) == 0:
        host = "10.10.24.103:8789"
    url = "http://%s/%s/%s" % (host, bucket, file)
    headers = {'x-tos-access': access}
    if len(ctype) > 0:
        headers['content-type'] = ctype
    req = requests.put(url, data=json.dumps(json_data), headers=headers)
    print(req.content)


def get_benchmark_json(benchmark_file_url):
    req = requests.get(benchmark_file_url)
    # print(req.json())
    return req.json()


if __name__ == "__main__":
    # json_data = json.load(open('./benchmark.json'))
    # print(json_data)
    # upload_file("ttclient-android-crashinfo",
    #             "NTD082DDQDJZ2TTS38KS", "benchmark/benchmark.json",
    #             json.load(open('./benchmark.json')), "application/json")
    # get_benchmark_file('http://tosv.byted.org/obj/ttclient-android-crashinfo/benchmark/benchmark.json')
    pass
