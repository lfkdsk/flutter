/// BD ADD:
/// TODO(@kongshanshan): 补一下这里的注释
import 'package:crypto/crypto.dart';
import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';

String main(List<String> arg) {
  if (arg.length != 1) {
    throw '参数不对';
  }
  final List<File> lists = List();
  _recursiveDirectory(fs.directory(arg[0]), lists);
  final List<int> data = List();
  for (File file in lists) {
    data.addAll(file.readAsBytesSync());
  }
  final String result = md5.convert(data).toString();
  print('${result}');
  return result;
}

void _recursiveDirectory(Directory directory, List<File> list) {
  if (directory != null && directory.existsSync()) {
    final List<FileSystemEntity> lister = directory.listSync();
    for (FileSystemEntity entity in lister) {
      if (entity is File) {
        list.add(entity.absolute);
      } else if (entity is Directory) {
        _recursiveDirectory(entity, list);
      }
    }
  }
}
