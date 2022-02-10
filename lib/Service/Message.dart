import 'package:encrypt/encrypt.dart' as en;

class CustomMessage{
  final String ?sentBy,text,to;
  bool ?sent;
  bool seen;
  final DateTime ?timestamp;
  CustomMessage({this.sentBy,this.text,this.seen=false,this.timestamp,this.sent=false,required this.to});

  factory CustomMessage.fromJson(json)=>CustomMessage(
    sentBy:json["sentBy"],
    text:Encryption.decrypt(json["text"]),
    seen:json["seen"],
    timestamp:DateTime.fromMillisecondsSinceEpoch(json["timestamp"]),
    sent:true,
    to:json["to"]
  );

  toJson()=>{
    "sentBy":sentBy,
    "text":Encryption.encrypt(text!),
    "seen":seen,
    "timestamp":timestamp!.millisecondsSinceEpoch,
    "to":to
  };
}

class Chat{
  final List<String?>? users;
  String ?chatId;
  DateTime ?timestamp;
  final List<CustomMessage> messages;

  Chat({this.chatId,this.users,this.messages=const[],this.timestamp});

  factory Chat.fromJson(json){
    List<String> users = [];
    json["users"].forEach((el)=>users.add(el.toString()));
    return Chat(
      chatId:json.id,
      users:users,
      timestamp:json["timestamp"]!=null?DateTime.fromMillisecondsSinceEpoch(json["timestamp"]):null
    );
  }

  toJson(){
    return {
      "chatId":chatId,
      "users":users,
      "timestamp":timestamp??DateTime.now().millisecondsSinceEpoch
    };
  }

  onNewMessage(CustomMessage message)=>messages.add(message);
}

class Encryption{
  static encrypt(String data)=>en.Encrypter(en.AES(en.Key.fromUtf8("2OmuvKIRKlVHf@4wGXAS61cyl&32hB!e"))).encrypt(data,iv:en.IV.fromUtf8("krlmZF1ljSty@N@c")).base64;
  static decrypt(String data)=>en.Encrypter(en.AES(en.Key.fromUtf8("2OmuvKIRKlVHf@4wGXAS61cyl&32hB!e"))).decrypt64(data,iv:en.IV.fromUtf8("krlmZF1ljSty@N@c"));
}