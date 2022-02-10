import 'CutomUser.dart';

class Utils{
  static String getTime(DateTime? timestamp){
    var res = "";
    final td = getYesterdayToday(timestamp!);
    if(td!=null){
      res+=td+" ";
    }else{
      res+="${_parseTimestampEntity(timestamp.day)}/${_parseTimestampEntity(timestamp.month)}";
    }
    return res+" "+_parseTimestampEntity(timestamp.hour)+":"+_parseTimestampEntity(timestamp.minute);
  }

  static String getOnlyTime(DateTime timestamp){
    final ampm = timestamp.hour>12?"PM":"AM";
    return _parseTimestampEntity(timestamp.hour>12?timestamp.hour-12:timestamp.hour)+":"+_parseTimestampEntity(timestamp.minute)+" "+ampm;
  }

  static getYesterdayToday(DateTime? timestamp){
    final now = DateTime.now();
    if(now.month==timestamp!.month&&now.year==timestamp.year){
      if(now.day==timestamp.day){
        return "Today";
      }else if(now.day-timestamp.day==1){
        return "Yesterday";
      }
    }
    return null;
  }

  static debugPrint(text)=>print("[DEBUG]===$text");
  static errorPrint(text)=>print("[ERROR]===$text");
  static getName(CustomUser user)=>user.firstName!+" "+user.lastName!;

  static _parseTimestampEntity(int? value){
    if(value!>9)return value.toString();
    return "0"+value.toString();
  }

  static getChatTime(DateTime? timestamp)=>_parseTimestampEntity(timestamp!.hour)+":"+_parseTimestampEntity(timestamp.minute);
  static getDate(DateTime? timestamp)=>_parseTimestampEntity(timestamp!.day)+"/"+_parseTimestampEntity(timestamp.month)+"/"+_parseTimestampEntity(timestamp.year);

  static parseCount(int count){
    if(count>1000000){
      return (count/1000000).toString()+"M";
    }
    if(count>1000){
      return (count/1000).toString()+"k";
    }
    return count.toString();
  }
}
