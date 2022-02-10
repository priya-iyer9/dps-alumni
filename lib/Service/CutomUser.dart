import 'dart:convert';
import 'dart:typed_data';

class CustomUser {
  String? uid,
      email,
      firstName,
      lastName,
      phone,
      collegeName,
      jobProfile,
      notificationToken,
      currentAddress,
      permanentAddress,
      currentCompany,
      rollno,
      type,
      instaAccount,
      fbAccount,
      linkedinAccount;
  Uint8List? profileImage;
  int? passOutYear;
  bool isUptodate, isInternational, blocked;
  CustomUser(
      {this.uid,
      this.email,
      this.firstName,
      this.lastName,
      this.phone,
      this.collegeName,
      this.jobProfile,
      this.passOutYear,
      this.notificationToken,
      this.currentAddress,
      this.permanentAddress,
      this.currentCompany,
      this.isUptodate = false,
      this.profileImage,
      this.rollno,
      this.type,
      this.instaAccount,
      this.linkedinAccount,
      this.fbAccount,
      this.isInternational = false,
      this.blocked = false});

  getFullName() => firstName! + " " + lastName!;

  factory CustomUser.fromJson(json) {
    return CustomUser(
        uid: json["uid"] ?? json.id,
        email: json["email"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        phone: json["phone"],
        collegeName: json["collegeName"],
        jobProfile: json["jobProfile"],
        passOutYear: json["passoutYear"],
        notificationToken: json["notificationToken"],
        permanentAddress: json["permanentAddress"],
        currentAddress: json["currentAddress"],
        isUptodate: json["isUptodate"] ?? false,
        profileImage: json["profileImage"] != null
            ? base64Decode(json["profileImage"])
            : null,
        rollno: json["rollno"],
        type: json["type"],
        instaAccount: json["instaAccount"] ?? null,
        fbAccount: json["fbAccount"] ?? null,
        linkedinAccount: json["linkedinAccount"] ?? null,
        isInternational: json["isInternational"],
        blocked: json["blocked"]);
  }
  toJson() {
    return {
      "uid": uid,
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "passoutYear": passOutYear,
      "collegeName": collegeName,
      "jobProfile": jobProfile,
      "notificationToken": notificationToken,
      "isUptodate": isUptodate,
      "currentAddress": currentAddress,
      "permanentAddress": permanentAddress,
      "profileImage": profileImage != null ? base64Encode(profileImage!) : null,
      "rollno": rollno,
      "type": type ?? "user",
      "fbAccount": fbAccount,
      "instaAccount": instaAccount,
      "linkedinAccount": linkedinAccount,
      "isInternational": isInternational,
      "blocked": blocked,
    };
  }
}

class CustomNotification {
  String? id, title, body, type, targetObjectName;
  DateTime? timestamp;
  bool seen, sent;
  CustomNotification(
      {this.id,
      required this.title,
      required this.body,
      required this.type,
      required this.targetObjectName,
      this.timestamp,
      this.seen = false,
      this.sent = false});

  factory CustomNotification.fromJson(json) => CustomNotification(
      id: json.id ?? json["id"],
      title: json["title"],
      body: json["body"],
      type: json["type"],
      targetObjectName: json["targetObjectName"],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json["timestamp"]),
      seen: json["seen"],
      sent: json["sent"]);

  toJson() => {
        "id": id,
        "title": title,
        "body": body,
        "type": type,
        "targetObjectName": targetObjectName,
        "timestamp": timestamp ?? DateTime.now().millisecondsSinceEpoch,
        "seen": seen,
        "sent": sent
      };
}
