import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

class JobPost{
  final String ?id,company,role,location,stipend,type,resps,qualifs,organization,hireLink,postedBy;
  final Uint8List ?logo;
  final int ?applicationCount;
  final List<String> ?applicants;
  DateTime? postedOn;
  JobPost({this.id,this.company,this.logo,this.role,this.location,this.stipend,this.type,this.resps,this.qualifs,this.applicationCount,this.organization,this.hireLink,this.applicants=const [],this.postedBy,this.postedOn});

  factory JobPost.fromJson(json){
    List<String> ap = [];
    if(json["applicants"]!=null){
      json["applicants"].forEach((el)=>ap.add(el.toString()));
    }
    return JobPost(
      id:json.id??json["id"],
      company:json["company"],
      role:json["role"],
      location:json["location"],
      stipend:json["stipend"],
      type:json["type"],
      resps:json["resps"],
      qualifs:json["qualifs"],
      logo:json["logo"]==null?null:base64Decode(json["logo"]),
      applicationCount:json["applicationCount"],
      organization:json["organization"],
      hireLink:json["hireLink"],
      applicants:ap,
      postedBy:json["postedBy"],
      postedOn:DateTime.fromMillisecondsSinceEpoch(json["postedOn"])
    );
  }

  toJson()=>{
    "company":company,
    "role":role,
    "location":location,
    "stipend":stipend,
    "type":type,
    "resps":resps,
    "qualifs":qualifs,
    "logo":base64Encode(logo!),
    "applicationCount":applicationCount,
    "organization":organization,
    "hireLink":hireLink,
    "applicants":applicants,
    "postedBy":postedBy,
    "postedOn":postedOn!=null?postedOn!.millisecondsSinceEpoch:DateTime.now().millisecondsSinceEpoch
  };

  parseResps(){
    var temp = resps!.split("\n").toList();
    if(temp.isNotEmpty){
      return temp;
    }
    return ["Not mentioned by the employer."];
  }
  parseQualifs(){
    var temp = qualifs!.split("\n").toList();
    if(temp.isNotEmpty){
      return temp;
    }
    return ["Not mentioned by the employer."];
  }

  Image getImage({double? scale}){
    return Image.memory(logo!,scale:scale??1);
  }

}
