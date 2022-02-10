import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class DiscussionPost {
  String? id, text, name, designation, uid, organization, reports;
  DateTime? timestamp;
  List<String>? likedBy;
  List<String>? dislikedBy;
  String? media;
  int commentCount;
  bool isliked, isdisliked = false;
  DiscussionPost(
      {this.id,
      this.name,
      this.designation,
      this.uid,
      this.text,
      this.reports,
      this.isliked = false,
      this.isdisliked = false,
      this.media = null,
      this.timestamp,
      this.organization,
      this.likedBy,
      this.dislikedBy,
      this.commentCount = 0});

  factory DiscussionPost.fromJson(json) {
    List<String> likedBy = [];
    if (json["likedBy"] != null) {
      json["likedBy"].forEach((e) => likedBy.add(e.toString()));
    }
    List<String> dislikedBy = [];
    if (json["dislikedBy"] != null) {
      json["dislikedBy"].forEach((e) => dislikedBy.add(e.toString()));
    }
    return DiscussionPost(
        id: json.id ?? json["id"],
        name: json["name"],
        designation: json["designation"],
        uid: json["uid"],
        text: json["text"],
        media: json["media"],
        reports: json["reports"],
        isliked: json["isLiked"],
        isdisliked: json["isDisliked"],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json["timestamp"]),
        organization: json["organization"],
        likedBy: likedBy,
        dislikedBy: dislikedBy,
        commentCount: json["commentCount"]);
  }

  toJson() {
    return {
      "name": name,
      "designation": designation,
      "uid": uid,
      "text": text,
      "media": media,
      "reports": reports,
      "timestamp": timestamp!.millisecondsSinceEpoch,
      "organization": organization,
      "likedBy": likedBy,
      "isLiked": isliked,
      "isDisliked": isdisliked,
      "dislikedBy": dislikedBy,
      "commentCount": commentCount
    };
  }

  parseText() {
    List<InlineSpan> textspans = List.empty(growable: true);
    text = text!.replaceAll("\n", " ");
    for (String t in text!.split(" ")) {
      if (t == "") continue;
      if (t[0] == "#") {
        textspans.add(TextSpan(
            text: t,
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black)));
      } else {
        textspans.add(TextSpan(text: t));
      }
      textspans.add(TextSpan(text: " "));
    }
    return textspans;
  }
}

class DiscussionComment {
  String? commentBy, commentText, commentId, commentUid;
  DateTime? timestamp;
  List<String>? likedBy;
  List<String>? dislikedBy;
  DiscussionComment(
      {this.commentId,
      required this.commentUid,
      this.commentBy,
      this.commentText,
      this.timestamp,
      this.likedBy = const [],
      this.dislikedBy = const []});
  factory DiscussionComment.fromJson(json) {
    List<String> likedBy = List.empty(growable: true);
    json["likedBy"].forEach((e) => likedBy.add(e));
    List<String> dislikedBy = List.empty(growable: true);
    json["dislikedBy"].forEach((e) => dislikedBy.add(e));
    return DiscussionComment(
        commentUid: json["commentUid"],
        commentId: json.id,
        commentBy: json["commentBy"],
        commentText: json["commentText"],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json["timestamp"]),
        likedBy: likedBy,
        dislikedBy: dislikedBy);
  }

  toJson() {
    return {
      "commentId": commentId,
      "commentBy": commentBy,
      "commentText": commentText,
      "timestamp": timestamp!.millisecondsSinceEpoch,
      "likedBy": likedBy,
      "dislikedBy": dislikedBy,
      "commentUid": commentUid
    };
  }
}
