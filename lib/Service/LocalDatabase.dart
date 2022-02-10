import 'dart:convert';

import 'package:alumniapp/Service/CutomUser.dart';
import 'package:get_storage/get_storage.dart';

class LocalDbResponse{
  final String ?message;
  final ResponseCode ?code;
  final dynamic data;
  LocalDbResponse({this.code,this.message,this.data});
}

enum ResponseCode{success,failed}

class UserDatabase{
  static final box = GetStorage();

  static Future<LocalDbResponse> setUser(CustomUser? user) async {
    await box.write("user",jsonEncode(user!.toJson()));
    return LocalDbResponse(code:ResponseCode.success);
  }

  static bool checkUser() {
    return box.hasData("user");
  }

  static Future<LocalDbResponse> getUser() async {
    final user = CustomUser.fromJson(jsonDecode(box.read("user")));
    return LocalDbResponse(code:ResponseCode.success,data:user);
  }

  static clear() async {
    await box.erase();
  }
}

/*
class UserDatabase{
  static Future<LocalDbResponse> setUser(CustomUser? user) async {
    try{
      final prefs = await SharedPreferences.getInstance();
      if(await prefs.setString("user",jsonEncode(user!.toJson())))
        return LocalDbResponse(code:ResponseCode.success);
      return LocalDbResponse(code:ResponseCode.failed);
    }on Exception catch(error){
      return LocalDbResponse(code:ResponseCode.failed,message:error.toString());
    }
  }

  static Future<bool> checkUser() async {
    try{
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey("user");
    }on Exception catch(e){
      print(e.toString());
      return false;
    }
  }

  static Future<LocalDbResponse> getUser() async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final user = CustomUser.fromJson(jsonDecode(prefs.getString("user").toString()));
      return LocalDbResponse(code:ResponseCode.success,data:user);
    }on Exception catch(error){
      return LocalDbResponse(code:ResponseCode.failed,message:error.toString());
    }
  }

  static Future<LocalDbResponse> clear() async{
    try{
      final prefs = await SharedPreferences.getInstance();
      if(await prefs.clear())
        return LocalDbResponse(code:ResponseCode.success);
      return LocalDbResponse(code:ResponseCode.failed);  
    }on Exception catch(error){
      return LocalDbResponse(code:ResponseCode.failed,message:error.toString());
    }
  }
}
*/

