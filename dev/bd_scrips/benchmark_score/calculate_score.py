#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import json
import sys
import argparse
import gen_weight_json

BASE_SCORE = 60.0
TOTAL_SCORE = 100.0
HTML_STR = '<html><head><metacharset="UTF-8"/><title></title><script src="http://apps.bdimg.com/libs/jquery/2.1.4/jquery.min.js"></script><script src="./jquery.min.js"></script><script src="http://code.highcharts.com/highcharts.js"></script><script src="./highcharts.js"></script><style>table{border:1px solid #888888;border-collapse:collapse;font-family:Arial,Helvetica,sans-serif;margin-top:20px;width:90%;}caption{font-size:20px;margin-bottom:10px;margin-top:20px;}th{background-color:#CCCCCC;border:1px solid#888888;padding:5px 15px 5px 5px;text-align:left;vertical-align:baseline;}td{background-color:#EFEFEF;border:1pxsolid#AAAAAA;padding:5px15px5px5px;}h1{align-self:center}</style></head><body><div align="center"style="margin-left:25%;margin-right:25%">'
HTML_STR_END = '</div><script>%s</script></body></html>'
SCRIPT_STR = "$(document).ready(function () {var series = [ { name: '得分', data: [%s] }, { name: '基准', data: [%s] } ]; var title = {text: '%s'}; var x = {categories: [%s]}; var json = {}; json.title = title; json.series = series; json.xAxis = x; $('#%s').highcharts(json);});"

URL_DICT = {
    "cull_opacity_perf_ios__timeline_summary": "https://bytedance.feishu.cn/space/doc/doccnuH4IzYzuKiNaSDV0a3p3th#K8Mcoq",
    "backdrop_filter_perf_ios__timeline_summary": "https://bytedance.feishu.cn/space/doc/doccnuH4IzYzuKiNaSDV0a3p3th#ctCrof",
    "tiles_scroll_perf_ios__timeline_summary": "https://bytedance.feishu.cn/space/doc/doccnuH4IzYzuKiNaSDV0a3p3th#38sg5j",
    "cubic_bezier_perf_ios__timeline_summary": "https://bytedance.feishu.cn/space/doc/doccnuH4IzYzuKiNaSDV0a3p3th#aa7pW0",
    "complex_layout_scroll_perf_ios__timeline_summary": "https://bytedance.feishu.cn/space/doc/doccnuH4IzYzuKiNaSDV0a3p3th#aVQQ33",
    "microbenchmarks_ios": "https://bytedance.feishu.cn/space/doc/doccnuH4IzYzuKiNaSDV0a3p3th#aWLZEY",
    "cull_opacity_perf__timeline_summary": "https://bytedance.feishu.cn/space/doc/doccnuH4IzYzuKiNaSDV0a3p3th#RAfjxC",
    "tiles_scroll_perf__timeline_summary": "https://bytedance.feishu.cn/docs/doccnuH4IzYzuKiNaSDV0a3p3th#I3PKAh",
    "cubic_bezier_perf__timeline_summary": "https://bytedance.feishu.cn/docs/doccnuH4IzYzuKiNaSDV0a3p3th#BqPUiv",
    "complex_layout_scroll_perf__timeline_summary": "https://bytedance.feishu.cn/space/doc/doccnuH4IzYzuKiNaSDV0a3p3th#RAfjxC",
    "microbenchmarks": "https://bytedance.feishu.cn/docs/doccnuH4IzYzuKiNaSDV0a3p3th#NJ9a3J",
    "complex_layout__start_up": "https://bytedance.feishu.cn/docs/doccnuH4IzYzuKiNaSDV0a3p3th#6cvboJ",
    "complex_layout_scroll_perf__memory": "https://bytedance.feishu.cn/docs/doccnuH4IzYzuKiNaSDV0a3p3th#YdIPE9",
    "home_scroll_perf__timeline_summary": "https://bytedance.feishu.cn/docs/doccnuH4IzYzuKiNaSDV0a3p3th#BNcVWC",
    "cull_opacity_perf__timeline_summary": "https://bytedance.feishu.cn/docs/doccnuH4IzYzuKiNaSDV0a3p3th#hHa58u",
}

TIMELINE_SUMMARY_KEY = [
    "90th_percentile_frame_build_time_millis",
    "99th_percentile_frame_build_time_millis",
    "worst_frame_build_time_millis",
    "average_frame_build_time_millis",
    "90th_percentile_frame_rasterizer_time_millis",
    "99th_percentile_frame_rasterizer_time_millis",
    "worst_frame_rasterizer_time_millis",
    "average_frame_rasterizer_time_millis",
    "frame_count",
    "missed_framevsync_count"
]

LIST_ORDER = [
    "velocity_tracker_bench",
    "sync_star_bench",
    "matrix_utils_transform_bench",
    "rrect_contains_bench",

    "flutter_gallery_start_up",
    "build_bench",
    "layout_bench",
    "complex_layout_semantics_perf",
    "gesture_detector_bench",
    "animation_bench",
    "complex_layout_scroll_perf_memory",
    "macrobenchmarks_backdrop_filter_perf",

    "scroll_view_page_round1",
    "scroll_view_page_round2",
    "tap_item_Video",
    "tap_item_Image",
    "tap_item_Audio",
    "complex_layout_scroll_perf",
    "tiles_scroll_perf",
    "macrobenchmarks_cull_opacity_perf",
    "macrobenchmarks_cubic_bezier_perf",
]

STR_DIC_EN_TO_CH = {
    "build_bench": "markNeedsBuild 后至 handleDrawFrame 返回耗时",
    "stock_build_iteration": "build 时间 (us)",

    "sync_star_bench": "Iterable 耗时",
    "traverseIterableGenerated_iteration": "Generated 形式耗时 (ns)",
    "traverseIterableList_iteration": "List 形式耗时 (ns)",
    "traverseIterableSyncStar_iteration": "Sync* 形式耗时 (ns)",

    "complex_layout_semantics_perf": "复杂布局 semantics 初始化树耗时",
    "initialSemanticsTreeCreation": "初始化 semantics 树 耗时 (ms)",

    "macrobenchmarks_backdrop_filter_perf": "filter 测试",

    "velocity_tracker_bench": "getVelocity 耗时",
    "velocity_tracker_iteration": "获取手势速度值耗时 (us)",

    "macrobenchmarks_cubic_bezier_perf": "复杂动画的 UI 及 GPU 线程性能",

    "gesture_detector_bench": "从点击到绘制完成时长",
    "gesture_detector_bench_value": "耗时 (us)",

    "tap_item_Video": "Playground Video Item 点击进入及退出的 UI 及 GPU 线程性能",
    "tap_item_Image": "Playground Image Item 点击进入及退出的 UI 及 GPU 线程性能",
    "tap_item_Audio": "Playground Audio Item 点击进入及退出的 UI 及 GPU 线程性能",

    "matrix_utils_transform_bench": "Point 及 Rect 的 Matrix 计算耗时",
    "MatrixUtils_persp_transformRect_iteration": "Rect 透视变换耗时 (ns)",
    "MatrixUtils_persp_transformPoint_iteration": "Point 透视变换耗时 (ns)",
    "MatrixUtils_affine_transformPoint_iteration": "Rect 仿射变换耗时 (ns)",
    "MatrixUtils_affine_transformRect_iteration": "Point 仿射变换耗时 (ns)",

    "layout_bench": "layout 时长",
    "stock_layout_iteration": "layout 耗时（us）",

    "macrobenchmarks_cull_opacity_perf": "滚动的带透明度的布局的 UI 及 GPU 线程性能",

    "animation_bench": "打开及关闭 Drawer 动画性能",
    "stock_animation_close_first_frame_average": "关闭首帧耗时 (us)",
    "stock_animation_open_first_frame_average": "打开首帧耗时 (us)",
    "stock_animation_total_run_time": "动画总耗时 (ms)",
    "stock_animation_subsequent_frame_average": "平均每帧耗时 (ms)",

    "tiles_scroll_perf": "复杂布局 Menu 列表上下滑动的 UI 及 GPU 线程性能",
    "complex_layout_scroll_perf": "复杂布局上下滑动的的 UI 及 GPU 线程性能",

    "scroll_view_page_round1": "Playgound 首页左右滑1 的 UI 及 GPU 线程性能",
    "scroll_view_page_round2": "Playgound 首页左右滑2 的 UI 及 GPU 线程性能",
    "rrect_contains_bench": "Rrect contains 函数执行耗时",
    "rrect_contains_iteration": "函数执行时间耗时（us）",
    "flutter_gallery_start_up": "启动时长",
    "timeToFirstFrameMicros": "启动时间 (ms)",

    "complex_layout_scroll_perf_memory": "内存占用",
    "start_mem": "初始内存 (Kb)",
    "end_mem": "结束内存 (Kb)",
    "diff_mem": "内存消耗 (Kb)",
}

def get_en_to_cn(key):
    # if key in STR_DIC_EN_TO_CH:
    #     return STR_DIC_EN_TO_CH[key]
    return key

def get_url(key):
    if key in URL_DICT:
        return URL_DICT[key]
    return ''

def getSumlizeTimeHtml(json, base_json):
    adjustJson = {}
    totalBuildScore = 0
    totalBuildMaxScore = 0
    totalRasterizerScore = 0
    totalRasterizerMaxScore = 0
    for key in json.keys():
        if key == 'head':
            adjustJson[key] = json[key]
        elif not str(json[key]).__contains__("#"):
            adjustJson[key] = json[key]
        else:
            strs = str(json[key]).split("#")
            if key.__contains__("build"):
                totalBuildScore = totalBuildScore + float(strs[1])
                totalBuildMaxScore = totalBuildMaxScore + float(strs[2])
                adjustJson[key] = "%.2f" % float(strs[0])
            elif key.__contains__("rasterizer"):
                totalRasterizerScore = totalRasterizerScore + float(strs[1])
                totalRasterizerMaxScore = totalRasterizerMaxScore + float(strs[2])
                adjustJson[key] = "%.2f" % float(strs[0])
    adjustJson['build_score'] = "%.2f" % float(totalBuildScore)
    adjustJson['build_n_score'] = "%.2f" % (float(totalBuildScore) / float(totalBuildMaxScore))
    adjustJson['rasterizer_score'] = "%.2f" % float(totalRasterizerScore)
    adjustJson['rasterizer_n_score'] = "%.2f" % (float(totalRasterizerScore) / float(totalRasterizerMaxScore))
    json = adjustJson

    result = '<tr><th></th><th>avg</th><th>90th</th><th>99th</th><th>worst</th><th>得分</th></tr>'
    result = '%s<tr><th>UI 线程耗时 (ms)</th><th>%s</th><th>%s</th><th>%s</th><th>%s</th><th>%.0f</th></tr>' % (
        result, json['average_frame_build_time_millis'],
        json['90th_percentile_frame_build_time_millis'],
        json['99th_percentile_frame_build_time_millis'],
        json['worst_frame_build_time_millis'],
        float(json['build_n_score']) * 100
    )
    result = '%s<tr><th>UI 线程(基准)耗时 (ms)</th><th>%.2f</th><th>%.2f</th><th>%.2f</th><th>%.2f</th><th>%.0f</th></tr>' % (
        result, float(base_json['average_frame_build_time_millis']),
        float(base_json['90th_percentile_frame_build_time_millis']),
        float(base_json['99th_percentile_frame_build_time_millis']),
        float(base_json['worst_frame_build_time_millis']),
        60
    )
    result = '%s<tr><th>GPU 线程耗时 (ms)</th><th>%s</th><th>%s</th><th>%s</th><th>%s</th><th>%.0f</th></tr>' % (
        result, json['average_frame_rasterizer_time_millis'],
        json['90th_percentile_frame_rasterizer_time_millis'],
        json['99th_percentile_frame_rasterizer_time_millis'],
        json['worst_frame_rasterizer_time_millis'],
        float(json['rasterizer_n_score']) * 100
    )
    result = '%s<tr><th>GPU 线程(基准)耗时 (ms)</th><th>%.2f</th><th>%.2f</th><th>%.2f</th><th>%.2f</th><th>%.0f</th></tr>' % (
        result, float(base_json['average_frame_rasterizer_time_millis']),
        float(base_json['90th_percentile_frame_rasterizer_time_millis']),
        float(base_json['99th_percentile_frame_rasterizer_time_millis']),
        float(base_json['worst_frame_rasterizer_time_millis']),
        60
    )
    if "base_frame_count" in json:
        result = '%s<tr><th>基准绘制帧数</th><th>总绘制 %s</th><th>掉帧 %s</th><th>掉帧率 %.4f%%</th><th></th><th></th></tr>' % (
            result,
            json['base_frame_count'],
            json['base_missed_framevsync_count'],
            float(json['base_missed_framevsync_count']) / float(json['base_frame_count']) * 100
        )
    if "frame_count" in json:
        result = '%s<tr><th>测试绘制帧数</th><th>总绘制 %s</th><th>掉帧 %s</th><th></th>掉帧率 %.4f%%<th></th><th></th></tr>' % (
            result,
            json['frame_count'],
            json['missed_framevsync_count'],
            float(json['base_missed_framevsync_count']) / float(json['base_frame_count']) * 100
        )
    result = '<table> <caption align="top">%s</caption>%s</table>' % (json["head"], result)
    return result


def getOtherHtml(json, base_json):
    result = '<tr><th>计分条目</th><th>原始值</th><th>基准值</th><th>得分</th></tr>'
    for key, value in json.items():
        if key != 'head':
            chTitle = get_en_to_cn(key)
            if key == 'gesture_detector_bench':
                chTitle = get_en_to_cn('gesture_detector_bench_value')
            strs = str(value).split("#")
            result = '%s<tr><th>%s</th><th>%.2f</th><th>%.2f</th><th>%.0f</th></tr>' % (
            result, chTitle, float(strs[0]), float(base_json[key]), (float(strs[1]) / float(strs[2]) * 100))
    result = '<table> <caption align="top">%s</caption>%s</table>' % (json["head"], result)
    return result


def justGetTotalScole(weightJson, baseJson, targetJson):
    totalWeight = 0
    totalScore = 0
    minDict = {}
    # 获取每个 case 总的 weight
    for key in weightJson.keys():
        if key in baseJson:
            minDict[key] = baseJson[key]
            sub_total_weight = 1.0
            if "weight_in_total" in weightJson[key]:
                sub_total_weight = weightJson[key]['weight_in_total']
            totalWeight = totalWeight + sub_total_weight
            if not (key in LIST_ORDER):
                LIST_ORDER.append(key)

    # 每个 weight 基准分
    eveWeightScore = BASE_SCORE / totalWeight
    # 每个 weight 最大分
    maxEveWeightScore = TOTAL_SCORE / totalWeight
    for key in LIST_ORDER:
        if key not in minDict:
            continue
        value = minDict[key]
        # case 内 子 weight 分
        subWeight = 0
        for subKey in weightJson[key].keys():
            if subKey != 'weight_in_total' and subKey != 'missed_frame_rasterizer_budget_count' and subKey != 'missed_frame_build_budget_count':
                subWeight = subWeight + float(weightJson[key][subKey])
        caseWeight = 1.0
        if "weight_in_total" in weightJson[key]:
            caseWeight = weightJson[key]['weight_in_total']
        subEveWeightScore = eveWeightScore / subWeight * caseWeight
        maxSubEveWeightScore = maxEveWeightScore / subWeight * caseWeight
        subScore = 0.0
        subKeys = value.keys()
        for subKey in subKeys:
            bValue = float(minDict[key][subKey])
            tValue = bValue
            if key in targetJson:
                tValue = float(targetJson[key][subKey])
            if not subKey in weightJson[key]:
                continue
            weight = float(weightJson[key][subKey])
            subBaseScore = subEveWeightScore * weight
            subSubScore = ((bValue - tValue) / bValue + 1.0) * subBaseScore
            subSubScore = max(min(subSubScore, maxSubEveWeightScore * weight), 0.0)
            subScore = subScore + subSubScore
        totalScore = totalScore + subScore
    return totalScore

def parse_args(args):
    args = args[1:]
    parser = argparse.ArgumentParser(description='A script run` benckmark test`.')
    parser.add_argument('-w', default='')
    parser.add_argument('-b', default='')
    parser.add_argument('-t', default='')
    parser.add_argument('--target-dir', default='')
    return parser.parse_args(args)

if __name__ == '__main__':
    reload(sys)
    sys.setdefaultencoding("utf-8")
    args = parse_args(sys.argv)
    # weightJsonFilePath = sys.argv[1]
    # baseJsonFilePath = sys.argv[2]
    # targetJsonFilePath = sys.argv[3]
    # targetJsonDir = ""
    # if len(sys.argv) >= 5:
    #     targetJsonDir = sys.argv[4]
    weightJsonFilePath = args.w
    baseJsonFilePath = args.b
    targetJsonFilePath = args.t
    targetJsonDir = args.target_dir
    if not os.path.exists(baseJsonFilePath):
        print("baseJson: %s not exit." % baseJsonFilePath)
        exit()
    elif not os.path.exists(targetJsonFilePath):
        print("baseJson: %s not exit." % targetJsonFilePath)
        exit()
    weightJson = {}
    if not os.path.exists(weightJsonFilePath):
        weightJson = gen_weight_json.gen_weight_json(baseJsonFilePath)
    else:
        weightJson = json.load(open(weightJsonFilePath, 'r'))
    targetJsonList = []
    adjustFiles = []
    if os.path.exists(targetJsonDir):
        files = os.listdir(targetJsonDir)
        for fileName in files:
            if fileName.endswith(".json") and fileName != "avgJson.json":
                adjustFiles.append(fileName)
        adjustFiles.sort(key=lambda x:int(x[:-5]))
        for filePath in adjustFiles:
            if filePath.endswith(".json") and filePath != "avgJson.json":
                print("file Name %s" % filePath)
                with open(os.path.join(targetJsonDir, filePath), 'r') as jsonFile:
                    targetJsonList.append(json.load(jsonFile))
    baseJson = json.load(open(baseJsonFilePath, 'r'))
    targetJson = json.load(open(targetJsonFilePath, 'r'))
    totalWeight = 0

    # for jsonStr in targetJsonList:
    #     print(justGetTotalScole(weightJson, baseJson, jsonStr))
    print(justGetTotalScole(weightJson, baseJson, targetJson))

    minDict = {}
    # 获取每个 case 总的 weight
    for key in weightJson.keys():
        if key in baseJson and key in targetJson:
            minDict[key] = baseJson[key]
            if "weight_in_total" in weightJson[key]:
                totalWeight = totalWeight + weightJson[key]['weight_in_total']
            totalWeight = totalWeight + 1

    # 每个 weight 基准分
    eveWeightScore = BASE_SCORE / totalWeight
    # 每个 weight 最大分
    maxEveWeightScore = TOTAL_SCORE / totalWeight

    htmlStr = ""
    summaryTableHtmlStr = "<tr><th>序号</th><th> 评分 Case</th><th> 得分 </th></tr>"
    totalScore = 0.0
    index = 0
    for key in LIST_ORDER:
        if key not in minDict:
            continue
        index = index + 1
        value = minDict[key]
        # case 内 子 weight 分
        subWeight = 0
        for subKey in weightJson[key].keys():
            if subKey != 'weight_in_total':
                subWeight = subWeight + float(weightJson[key][subKey])

        caseWeight = 1.0
        if "weight_in_total" in weightJson[key]:
            caseWeight = weightJson[key]['weight_in_total']
        subEveWeightScore = eveWeightScore / subWeight * caseWeight
        maxSubEveWeightScore = maxEveWeightScore / subWeight * caseWeight

        subScore = 0.0
        isSummaryTimeLine = False
        resultStr = ""
        subKeys = value.keys()
        if TIMELINE_SUMMARY_KEY[0] in subKeys:
            subKeys = TIMELINE_SUMMARY_KEY
            isSummaryTimeLine = True
        saveJsonForHtml = targetJson[key].copy()
        for subKey in subKeys:
            if not (subKey in targetJson[key]):
                continue
            if isSummaryTimeLine and (subKey == "missed_framevsync_count" or subKey == "frame_count"):
                saveJsonForHtml[subKey] = targetJson[key][subKey]
                saveJsonForHtml["base_%s" % subKey] = minDict[key][subKey]
                continue
            bValue = float(minDict[key][subKey])
            tValue = bValue
            if key in targetJson:
                tValue = float(targetJson[key][subKey])
            weight = float(weightJson[key][subKey])
            subBaseScore = subEveWeightScore * weight
            subSubScore = ((bValue - tValue) / tValue + 1.0) * subBaseScore
            subSubScore = max(min(subSubScore, maxSubEveWeightScore * weight), 0.0)
            subScore = subScore + subSubScore
            compareScore = subSubScore - subBaseScore
            targetSubValueListStr = ''
            saveJsonForHtml[subKey] = str(saveJsonForHtml[subKey]) + "#" + str(subSubScore) + "#" + str(maxSubEveWeightScore * weight)
            if len(targetJsonList) > 0:
                targetSubValueList = []
                for tmp in targetJsonList:
                    if (not key in tmp) or (not subKey in tmp[key]):
                        continue
                    targetSubValueList.append(float(tmp[key][subKey]))
                targetSubValueList.sort()
                targetSubValueListStr = '['
                for v in targetSubValueList:
                    targetSubValueListStr = targetSubValueListStr + ("%.2f" % v) + ', '
                targetSubValueListStr = targetSubValueListStr + ']'
            resultStr = resultStr + ("%s:" % subKey) + (" %s \n" %targetSubValueListStr)
            if compareScore >= 0:
                resultStr = resultStr + (
                            "  score: %.2f, baseScore: %.2f, compareSscore:\033[0;32m +%.2f \033[0m" % (
                        subSubScore, subBaseScore, compareScore)) + "\n"
            else:
                resultStr = resultStr + ("  score: %.2f, baseScore: %.2f, compareScore:\033[0;31m %.2f \033[0m" % (
                    subSubScore, subBaseScore, compareScore)) + "\n"
            resultStr = resultStr + (
                    "  value: %.2f, baseValue: %.2f" % (tValue, bValue)) + "\n"
        caseScore = eveWeightScore * caseWeight
        compareScore = subScore - caseScore
        if compareScore >= 0:
            resultStr = "\n>>>>>> test: [%s] \033[0;32m +%.2f \033[0m score:%.2f, baseScore:%.2f <<<<<<<<" % (
                key, compareScore, subScore, caseScore) + "\n" + resultStr
        else:
            resultStr = "\n>>>>>> test: [%s] \033[0;31m %.2f \033[0m score:%.2f, baseScore:%.2f <<<<<<<<" % (
                key, compareScore, subScore, caseScore) + "\n" + resultStr
        print(resultStr)
        saveJsonForHtml["head"] = "[" + str(index) + "]   " + get_en_to_cn(key) + (" -- 得分: %.0f" % (subScore / (maxEveWeightScore * caseWeight) * 100))
        if isSummaryTimeLine:
            htmlStr = htmlStr + getSumlizeTimeHtml(saveJsonForHtml, minDict[key])
        else:
            htmlStr = htmlStr + getOtherHtml(saveJsonForHtml, minDict[key])
        summaryTableHtmlStr = "%s<tr><th>%d</th><th><a href=\"%s\">%s</a></th><th>%.0f</th></tr>" \
                              % (summaryTableHtmlStr, index, get_url(key), get_en_to_cn(key), subScore / (maxEveWeightScore * caseWeight) * 100)
        totalScore = totalScore + subScore

    summaryTableHtmlStr = '<table>' + summaryTableHtmlStr + '</table>'
    htmlStr = summaryTableHtmlStr + htmlStr
    endHtml = HTML_STR_END
    if len(targetJsonList) > 0:
        htmlStr = '<div id="total_graph"></div>' + htmlStr
        dataStr = ''
        baseDataStr = ''
        x_list_str = ''
        tmp = 0
        index = 0
        for jsonStr in targetJsonList:
            dataStr = dataStr + ("%.2f," %justGetTotalScole(weightJson, baseJson, jsonStr))
            baseDataStr = baseDataStr + "60,"
            x_list_str = x_list_str + ("%s," %adjustFiles[index][:-5])
            index = index + 1
            # print(justGetTotalScole(weightJson, baseJson, jsonStr))
            tmp = justGetTotalScole(weightJson, baseJson, jsonStr) + tmp
        scripStr = SCRIPT_STR % (dataStr[0:-1], baseDataStr[0:-1], ("多次结果分数分布图, 平均分为 %.2f" % (tmp / len(targetJsonList))), x_list_str[0:-1], "total_graph")
        endHtml = endHtml % scripStr
        totalScore = tmp / len(targetJsonList)
    else:
        endHtml = endHtml % ""
    detScore = totalScore - BASE_SCORE
    htmlStr = HTML_STR + ("<h1>Total Score %.2f</h1>" %totalScore) + htmlStr + endHtml
    htmlFile = open("./result.html", 'w')
    htmlFile.write(htmlStr)
    htmlFile.close()
    if detScore >= 0:
        print("totalScore \033[0;31m %.2f\033[0m \033[0;32m +%.2f \033[0m" % (totalScore, detScore))
    else:
        print("totalScore \033[0;31m %.2f\033[0m \033[0;31m %.2f \033[0m" % (totalScore, detScore))
