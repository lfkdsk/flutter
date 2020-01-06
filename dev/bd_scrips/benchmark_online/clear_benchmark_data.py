import json

if __name__ == '__main__':
    benchmark_path = "./benchmark.json"
    benchmark_json = json.load(open(benchmark_path))
    if "Benchmarks" in benchmark_json:
        benchmark_data_json = benchmark_json["Benchmarks"]
        for obj in  benchmark_data_json:
            obj["Timeseries"]["Key"] = obj["Timeseries"]["Timeseries"]["ID"]
            obj["Values"] = []
    with open(benchmark_path, 'w') as outfile:
        json.dump(benchmark_json, outfile, indent=4)
        outfile.close()