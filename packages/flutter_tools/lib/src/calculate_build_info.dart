import 'dart:convert';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:intl/intl.dart';
import 'cache.dart';
import 'version.dart';

// ignore: avoid_classes_with_only_static_members
class FlutterBuildInfo {
  FlutterBuildInfo._internal();

  static const String _kAccess = 'MGT9E8E1FCFBPGO1CVYO';
  static const String _kHost = '10.10.24.103:8789';
  static const String _kBucket = 'flutter';
  static const String _kTosPre = 'who_use_engine';
  static const String _kContentType = 'application/json';
  static const String _indexUrl =
      'http://tosv.byted.org/obj/flutter/who_use_engine/index';

  static FlutterBuildInfo get instance => _getInstance();
  static FlutterBuildInfo _instance;

  static FlutterBuildInfo _getInstance() {
    _instance ??= FlutterBuildInfo._internal();
    return _instance;
  }

  String pkgName = '';
  String versionCode = '';
  String appName = '';
  String projectDir = ''; // project dir
  String projectGitUrl = ''; // project url
  String projectCid = ''; // project cid
  String ip = ''; // machine ip
  String userName = '';
  String userEmail = '';
  String engineCid = '';
  String frameworkVersion = '';
  String frameworkCid = '';
  String platform = 'android';
  bool needReport = false;
  bool isAot = false;
  bool isLite = false;
  bool useCompressSize = false;
  List<Plugin> depList = List<Plugin>();
  String reportTime = '';

  void extractBuildInfo() {
    // get ip
    String result;
    result = runSafeCmd(<String>['ip', 'addr', 'show', 'eth0']);
    if (result != null && result.isNotEmpty) {
      ip = extractIpFromString(result);
    }

    if (ip == null || ip.isEmpty || ip == '') {
      result = runSafeCmd(<String>['ifconfig', 'en0']);
      if (result != null && result.isNotEmpty) {
        ip = extractIpFromString(result);
      }
    }

    // get dirs
    projectDir = runSafeCmd(<String>['pwd']);

    // get projectGitUrl
    projectGitUrl =
        runSafeCmd(<String>['git', 'config', '--get', 'remote.origin.url']);
    if (projectGitUrl != null && projectGitUrl.contains('git@')) {
      projectGitUrl = projectGitUrl.split('git@')[1];
    }

    // get projectCid
    projectCid = runSafeCmd(<String>['git', 'rev-parse', 'HEAD']);

    // get user name and email
    userName = runSafeCmd(<String>['git', 'config', 'user.name']);
    userEmail = runSafeCmd(<String>['git', 'config', 'user.email']);

    frameworkCid = _runGit('git log -n 1 --pretty=format:%H');
    if (frameworkCid != null) {
      frameworkVersion =
          BDGitTagVersion.determine(processUtils).frameworkVersionFor(frameworkCid);
      if (frameworkVersion != null && frameworkVersion == '0.0.0-unknown') {
        frameworkVersion = GitTagVersion.determine(processUtils).frameworkVersionFor(frameworkCid);
      }
    }
    engineCid = runSafeCmd(
        <String>['cat', '${Cache.flutterRoot}/bin/internal/ttengine.version']);
  }

  String extractIpFromString(String result) {
    final RegExp reg = RegExp(
        '((2(5[0-5]|[0-4]\\d))|[0-1]?\\d{1,2})(\\.((2(5[0-5]|[0-4]\\d))|[0-1]?\\d{1,2})){3}');
    final Iterable<Match> matches = reg.allMatches(result);
    for (Match match in matches) {
      if (!match.group(0).endsWith('.255')) {
        return match.group(0);
      }
    }
    return null;
  }

  static String runSafeCmd(List<String> cmd) {
    try {
      return processUtils.runSync(cmd).stdout.trim();
    } on Error {
      return null;
    }
  }

  static String _runGit(String command) {
    try {
      return processUtils.runSync(command.split(' '), workingDirectory: Cache.flutterRoot).stdout.trim();
    } on Error {
      return null;
    }
  }

  void extractApkPkgNameAndVersion(String apkPath) {
    if (!needReport) {
      return;
    }
    String text;
    final String aaptPath = getAaptPath();
    if (aaptPath != null) {
      text = runSafeCmd(<String>[aaptPath, 'dump', 'badging', apkPath]);
    }
    final List<String> manifestList = text.split('\n');
    for (String line in manifestList) {
      line = line.trim();
      if (line.startsWith('package: name=')) {
        // 包名提取
        final RegExp reg =
            RegExp("package: name='(.+?)' versionCode='(.+?)' .+");
        final Iterable<Match> matches = reg.allMatches(line);
        for (Match m in matches) {
          pkgName = m.group(1);
          versionCode = m.group(2);
        }
      }

      if (line.startsWith('application: label=')) {
        // 包名提取
        final RegExp reg = RegExp("application: label='(.+?)' .+");
        final Iterable<Match> matches = reg.allMatches(line);
        for (Match m in matches) {
          appName = m.group(1);
        }
        if (appName != null) {
          break;
        }
      }
    }
  }

  Future<void> reportInfo() async {
    if (!needReport) {
      return;
    }
    await initializeDateFormatting();
    final DateTime now = DateTime.now();
    final DateFormat inputFormat = DateFormat('yyyy-MM-dd-HH:mm:ss');
    reportTime = inputFormat.format(now);
    extractBuildInfo();
    final String result = buildReportJson();
    final String newReportTime =
        reportTime.replaceAll(':', '_').replaceAll('-', '_');
    String newIp = 'unkonwn_ip';
    if (ip != null && ip.isNotEmpty) {
      newIp = ip.replaceAll('\.', '_');
    }
    final String newFrameworkVersion =
    frameworkVersion.replaceAll('\.', '_').replaceAll('-', '_').replaceAll('+', '_');
    await findIndexAndUploadResult(
        result, 'v_${newFrameworkVersion}_ip_${newIp}_t_$newReportTime.json');
  }

  Future<void> reportInfoWhenAot() async {
    if (needReport && isAot) {
      await reportInfo();
    }
  }

  String buildReportJson() {
    List<Map<String, String>> list = new List();
    for (Plugin plugin in depList) {
      final Map<String, String> map = new Map<String, String>();
      map['name'] = plugin.name;
      map['path'] = plugin.path;
      if (plugin.platforms != null) {
        plugin.platforms.values.forEach((pv){
          if (pv is AndroidPlugin) {
            map['androidPackage'] = pv.package;
            map['pluginClass'] = pv.pluginClass;
          } else if (pv is IOSPlugin ) {
            map['iosPrefix'] = pv.classPrefix;
            map['pluginClass'] = pv.pluginClass;
          }
        });
      }
      list.add(map);
    }

    final Map<String, dynamic> map = Map<String, dynamic>();
    map['pkgName'] = pkgName;
    map['versionCode'] = versionCode;
    map['appName'] = appName;
    map['projectDir'] = projectDir;
    map['projectGitUrl'] = projectGitUrl;
    map['projectCid'] = projectCid;
    map['ip'] = ip;
    map['userName'] = userName;
    map['userEmail'] = userEmail;
    map['engineCid'] = engineCid;
    map['frameworkVersion'] = frameworkVersion;
    map['frameworkCid'] = frameworkCid;
    map['platform'] = platform;
    map['depList'] = list;
    map['isAot'] = isAot;
    map['isLite'] = isLite;
    map['useCompressSize'] = useCompressSize;
    map['reportTime'] = reportTime;
    return json.encode(map).toString();
  }

  Future<void> findIndexAndUploadResult(String jsonResult,
      String fileName) async {
    // get index file
    final http.Response responseSearchTOS = await http.get(_indexUrl)
        .catchError((Object error) {
      return null;
    });
    if (responseSearchTOS?.body?.isNotEmpty == true) {
      String indexStr = responseSearchTOS.body;
      indexStr += '$fileName\n';

      // search tos upload ip
      const String findTosUrl =
          'http://10.224.28.10:2280/v1/lookup/name?name=toutiao.tos.tosapi';
      String tosHost = _kHost;
      final http.Response findTosResp = await http.get(findTosUrl).timeout(
          Duration(seconds: 30)).catchError((Object error) {
        return null;
      });
      try {
        if (findTosResp?.body?.isNotEmpty == true) {
          final List list = json.decode(findTosResp.body) as List;
          if (list?.isNotEmpty == true) {
            final Map<String, dynamic> map = list[0] as Map<String, dynamic>;
            if (map != null && map.containsKey('Host') &&
                map.containsKey('Port')) {
              tosHost = '${map['Host']}:${map['Port']}';
            }
          }
        }
      } on Exception catch (_) {
        // ignore
      }

      // upload index
      http.Response resp = await _uploadJson(tosHost, indexStr, 'index', 'application/text');
      if (resp != null && resp.body != null && resp.body.contains('error')) {
        tosHost = _kHost;
        await _uploadJson(tosHost, indexStr, 'index', 'application/text');
      }
      // upload result json
      await _uploadJson(tosHost, jsonResult, fileName, 'application/json');
    }
  }

  Future<http.Response> _uploadJson(String host, String jsonResult,
      String fileName, String contextType) {
    final Map<String, String> headers = Map();
    headers['x-tos-access'] = _kAccess;
    headers['content-type'] = contextType;
    final String url = 'http://$host/$_kBucket/$_kTosPre/$fileName';
    return http
        .put(url, headers: headers, body: jsonResult)
        .timeout(Duration(seconds: 30))
        .catchError((Object error) {
      return null;
    });
  }
}
