# Benchmark 运行说明

## 一、benchmarks.py
该脚本为总的跑分入口，内部的跑分 Case 位于 flutter/dev/devicelab 内。
运行参数说明：
```
--out-path: 结果输出文件夹，如果不设定，会在程序运行目录下，进行 flutter_benchmark_日期 的目录
--timeout: 运行过程中，为了避免程序卡死，可设置超时时间，默认为 60 分钟
--devicelab: case 选择：
      all 运行所有的 case
      devicelab 运行 Android Case
      devicelab_ios 运行 IOS Case
--round-times: 运行的次数，默认为 20次
--tasks-file: 运行指定的 Case，将 case 名写到当前的文件中，详情看 flutter/dev/devicelab/manifest.yaml 文件
--local-engine-src-path:
--local-engine: 用于指定本地引擎
```

例子：
```
python benchmarks.py --out-path=./flutter_benchmark_base --round-times=100 --timeout=60 --devicelab=devicelab_ios --local-engine-src-path=/Users/linxuebin/MyProject/bdEngine/src --local-engine=ios_profile
```

## 二、IOS 环境配置
由于 IOS 需要配置签名等信息。

```
// 参数说明
--hash: 签名的 hash 值
--team: 签名的 组 信息 
python auto_configuration_sign.py --hash xxxxx --team xxxx
```

## 三、结果统计

```
// 参数说明
-w: weight json 路径，可以使用 gen_weight_json.py 生成，默认会跟进 base 生成。
-b: base json 路径
-t: 目标 json 路径
-target_dir: 目标json 文件夹路径

python calculate_score.py -b flutter_benchmark_base/avgJson.json -t flutter_benchmark_target/avgJson.json 
```
在当前目录下生成一个 result.html 的结果文件
