/// The Flutter reflection framework.
///
/// To use, import `package:flutter/reflection.dart`.
///
/// zhaoxuyang.6@bytedance.com
///

import 'dart:ui' as engine;

@pragma("vm:entry-point")
dynamic reflectClass(String libraryUrl, String className) {
  return engine.reflectClass(libraryUrl, className);
}

@pragma("vm:entry-point")
dynamic reflectLibrary(String libraryUrl) {
  return engine.reflectLibrary(libraryUrl);
}

/// 解包 invocation
class _UnpackInvocation{

  final String functionName;

  final int invokeType;

  final List<dynamic> arguments;

  final List<String> names;

  _UnpackInvocation(this.functionName, this.invokeType, this.arguments, this.names);

  static _UnpackInvocation unpack(Invocation invocation, {bool isClass:false}){
    var positionalArguments = invocation.positionalArguments;
    var namedArguments = invocation.namedArguments;
    int numNamedArguments = namedArguments != null ? namedArguments.length : 0;
    var allArguments = <dynamic>[];
    var allNames = <String>[];
    if(positionalArguments.isNotEmpty){
      positionalArguments.forEach((dynamic element) {
        allArguments.add(element);
      });
    }
    if (numNamedArguments > 0) {
      namedArguments.forEach((key, dynamic value) {
        allArguments.add(value);
        String name = key.toString();
        name = name.substring(8);
        name = name.substring(0,name.length-2);
        allNames.add(name);
      });
    }

    String functionName = invocation.memberName.toString();
    functionName = functionName.substring(8);
    functionName = functionName.substring(0,functionName.length-2);
    if(isClass && functionName=="call"){
      functionName = "";
    }
    int invokeType = 0;
    if(invocation.isGetter){
      invokeType = 1;
    }else if(invocation.isSetter){
      invokeType = 2;
      functionName = functionName.substring(0,functionName.length-1);
    }

    return _UnpackInvocation(functionName,invokeType,allArguments,allNames);
  }

  String toString(){
   var str =  "functionName:${functionName}, invokeType:${invokeType}, names:${names}\n";
   if(arguments.isNotEmpty){
     for(var i=0;i<arguments.length;i++ ){
       str +="arg:${i}:${arguments[i]},${arguments[i].runtimeType}\n";
     }
   }
   if(names.isNotEmpty){
     for(var i=0;i<names.length;i++ ){
       str +="name:${i}:${names[i]}\n";
     }
   }
   return str;
  }

}

@pragma("vm:entry-point")
class _ObjectMirror {

  final dynamic _reflectee;

  _ObjectMirror._(this._reflectee);

  dynamic get reflectee{
    return _reflectee;
  }
}

@pragma("vm:entry-point")
class _InstanceMirror extends _ObjectMirror {

  @pragma("vm:entry-point")
  _InstanceMirror._(dynamic reflectee) : super._(reflectee);

  /// 处理实例方法调用
  @override
  dynamic noSuchMethod(Invocation invocation) {
    var res = _UnpackInvocation.unpack(invocation);
    return engine.instanceInvoke(reflectee, res.invokeType, res.functionName, res.arguments, res.names);
  }
}

@pragma("vm:entry-point")
class _LibraryMirror extends _ObjectMirror {

  @pragma("vm:entry-point")
  _LibraryMirror._(dynamic reflectee) : super._(reflectee);

  /// 处理 library 级别的方法调用
  @override
  @pragma("vm:entry-point")
  dynamic noSuchMethod(Invocation invocation) {
    var res = _UnpackInvocation.unpack(invocation);
    return engine.libraryInvoke(reflectee, res.invokeType, res.functionName, res.arguments, res.names);
  }
}

@pragma("vm:entry-point")
class _ClassMirror extends _ObjectMirror {

  @pragma("vm:entry-point")
  _ClassMirror._(dynamic reflectee) : super._(reflectee);

  /// 处理类的静态方法,构造方法
  @override
  @pragma("vm:entry-point")
  dynamic noSuchMethod(Invocation invocation) {
    var res = _UnpackInvocation.unpack(invocation, isClass: true);
    return engine.classInvoke(reflectee, res.invokeType, res.functionName, res.arguments, res.names);
  }
}

