class Event{
  final String ?title,venue,description,organizer,openFor,organization,id,postedBy;
  final int ?entryCharges,attendingCount;
  List<String> ?attendees;
  DateTime? datetime,postedOn;
  Event({this.id,this.title,this.venue,this.description,this.organizer,this.openFor,this.entryCharges,this.attendingCount,this.organization,this.attendees=const[],this.postedBy,required this.datetime,this.postedOn});

  factory Event.fromJson(json){
    List<String> ad = [];
    if(json["attendees"]!=null){
      json["attendees"].forEach((el)=>ad.add(el.toString()));
    }
    return Event(
      id:json.id??json["id"],
      title:json["title"],
      venue:json["venue"],
      description:json["description"],
      organizer:json["organizer"],
      openFor:json["openFor"],
      entryCharges:json["entryCharges"]??0,
      attendingCount:json["attendingCount"]??0,
      organization:json["organization"],
      attendees:ad,
      postedBy:json["postedBy"],
      datetime:DateTime.fromMillisecondsSinceEpoch(json["datetime"]),
      postedOn:DateTime.fromMillisecondsSinceEpoch(json["postedOn"])
    );
  }

  toJson()=>{
    "title":title,
    "venue":venue,
    "description":description,
    "organizer":organizer,
    "openFor":openFor,
    "entryCharges":entryCharges,
    "attendingCount":attendingCount,
    "organization":organization,
    "attendees":attendees,
    "postedBy":postedBy,
    "datetime":datetime!.millisecondsSinceEpoch,
    "postedOn":postedOn!=null?postedOn!.millisecondsSinceEpoch:DateTime.now().millisecondsSinceEpoch
  };
}

