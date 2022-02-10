import 'dart:async';
import 'dart:io';
import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/DiscussionPost.dart';
import 'package:alumniapp/Service/Event.dart';
import 'package:alumniapp/Service/JobPost.dart';
import 'package:alumniapp/Service/Message.dart';
import 'package:alumniapp/Service/Utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum AuthResponseCode { success, failed }
enum DbResponseCode { success, failed }

class DbResponse {
  DbResponseCode? code;
  String? message, insertedId;
  DbResponse({this.code, this.message, this.insertedId});
}

class AuthResponse {
  AuthResponseCode? code;
  CustomUser? user;
  String? message;
  AuthResponse({this.code, this.user, this.message});
}

class CheckUserResponse {
  bool? found;
  CustomUser? user;
  CheckUserResponse({this.found, this.user});
}

class Server {
  FirebaseApp app;
  FirebaseFirestore? fstore;
  CustomUser? user;
  FirebaseAuth? fauth;
  final BuildContext context;
  FlutterLocalNotificationsPlugin? notificationsPlugin;
  late QueryDocumentSnapshot lastFetchedPost, lastFetchedJob, lastFetchedEvent;

  Server({required this.context, required this.app});

  createFstoreInstance() {
    fstore = FirebaseFirestore.instanceFor(app: app);
  }

  createFauthInstance() {
    fauth = FirebaseAuth.instanceFor(app: app);
  }

  setUser(CustomUser? u) {
    this.user = u;
  }

  setupNotifications(String? uid) async {
    notificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('launcher');
    var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {},
    );
    final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await notificationsPlugin!.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {});
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL_ID',
      'CHANNEL_NAME',
      "CHANNEL_DESCRIPTION",
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      styleInformation: DefaultStyleInformation(true, true),
    );
    var iosChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidChannelSpecifics, iOS: iosChannelSpecifics);
    if (user != null) {
      Timer.periodic(Duration(seconds: 3), (timer) async {
        final res = await fstore!
            .collection("users")
            .doc(user!.uid)
            .collection("notifications")
            .orderBy("timestamp", descending: true)
            .limit(50)
            .get();
        if (res.docs.length > 0) {
          res.docs.forEach((element) async {
            if (!element["sent"]) {
              await fstore!
                  .collection("users")
                  .doc(uid)
                  .collection("notifications")
                  .doc(element.id)
                  .set({"sent": true}, SetOptions(merge: true));
              final notif = CustomNotification.fromJson(element);
              notificationsPlugin!.show(notif.timestamp!.millisecond,
                  notif.title, notif.body, platformChannelSpecifics,
                  payload: notif.targetObjectName);
            }
          });
        }
      });
    }
  }

  Future<List<CustomNotification>> getUserNotifications(String? uid) async {
    List<CustomNotification> notifs = List.empty(growable: true);
    final res = await fstore!
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .orderBy("timestamp", descending: true)
        .limit(20)
        .get();
    if (res.docs.length > 0) {
      res.docs.forEach((element) {
        if (element["type"] != "chat") {
          notifs.add(CustomNotification.fromJson(element));
        }
      });
    }
    return notifs;
  }

  destroyNotificationChannel() {
    user = null;
    notificationsPlugin!.cancelAll();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications(String? uid) {
    return fstore!
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .where("type", isNotEqualTo: "chat")
        .where("seen", isEqualTo: false)
        .snapshots();
  }

  notificationSeen(String? uid, String? notifId) async {
    print("Deleting");
    await fstore!
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .doc(notifId)
        .set({"seen": true}, SetOptions(merge: true));
  }

  clearMessageNotifications(String? uid) async {
    await fstore!
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .where("type", isEqualTo: "chat")
        .get()
        .then((val) async {
      val.docs.forEach((element) {
        element.reference.delete();
      });
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUnseen(String? uid) {
    return fstore!
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .where("type", isEqualTo: "chat")
        .where("seen", isEqualTo: false)
        .snapshots();
  }

  allTextsSeen(String? uid) async {
    final res = await fstore!
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .where("type", isEqualTo: "chat")
        .get();
    res.docs.forEach((element) async {
      await fstore!
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .doc(element.id)
          .set({"seen": true}, SetOptions(merge: true));
    });
  }

  Future<JobPost?> getJobPost(String? postId) async {
    final res = await fstore!.collection("jobPosts").doc(postId).get();
    if (res.exists) {
      return JobPost.fromJson(res);
    }
    return null;
  }

  Future<Event?> getEvent(String? id) async {
    final res = await fstore!.collection("events").doc(id).get();
    if (res.exists) {
      return Event.fromJson(res);
    }
    return null;
  }

  Future<DiscussionPost?> getPost(String? id) async {
    final res = await fstore!.collection("discussionPosts").doc(id).get();
    if (res.exists) {
      return DiscussionPost.fromJson(res);
    }
    return null;
  }

  Future<Chat?> getChat(String? chatId) async {
    final res = await fstore!.collection("chats").doc(chatId).get();
    if (res.exists) {
      return Chat.fromJson(res.data());
    }
    return null;
  }

  deleteDiscussionPost(DiscussionPost post) async {
    await fstore!.collection("discussionPosts").doc(post.id).delete();
  }

  updatereportsfield(DiscussionPost post, post2) async {
    await fstore!
        .collection("discussionPosts")
        .doc(post.id)
        .update({"reports": post2});
  }

  deleteJobPost(JobPost post) async {
    await fstore!.collection("jobPosts").doc(post.id).delete();
  }

  deleteEvent(Event event) async {
    await fstore!.collection("events").doc(event.id).delete();
  }

  Future<AuthResponse> register(
      String email, String password, String firstName, String lastName) async {
    try {
      UserCredential res = await fauth!
          .createUserWithEmailAndPassword(email: email, password: password);
      if (res.user != null) {
        return AuthResponse(
            code: AuthResponseCode.success,
            user: CustomUser(
                uid: res.user!.uid,
                email: res.user!.email,
                firstName: firstName,
                lastName: lastName));
      } else {
        return AuthResponse(code: AuthResponseCode.failed, message: "Error");
      }
    } on FirebaseAuthException catch (e) {
      return AuthResponse(code: AuthResponseCode.failed, message: e.code);
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final res = await fauth!
          .signInWithEmailAndPassword(email: email, password: password);
      if (res.user != null) {
        final userinfo =
            await fstore!.collection("users").doc(res.user!.uid).get();
        if (userinfo.exists) {
          return AuthResponse(
              code: AuthResponseCode.success,
              user: CustomUser.fromJson(userinfo));
        }
      }
    } on FirebaseAuthException catch (e) {
      return AuthResponse(code: AuthResponseCode.failed, message: e.code);
    }
    return AuthResponse(code: AuthResponseCode.failed);
  }

  Future<AuthResponse> forgotPassword(String email) async {
    try {
      await FirebaseAuth.instanceFor(app: app)
          .sendPasswordResetEmail(email: email);
      return AuthResponse(code: AuthResponseCode.success);
    } on FirebaseException catch (e) {
      return AuthResponse(code: AuthResponseCode.failed, message: e.code);
    }
  }

  Future<CheckUserResponse> checkUser(String? uid) async {
    final res = await fstore!.collection("users").doc(uid).get();
    if (res.exists && res.data()!.isNotEmpty) {
      return CheckUserResponse(
          found: true, user: CustomUser.fromJson(res.data()));
    }
    return CheckUserResponse(found: false);
  }

  Future<CheckUserResponse> checkUserByEmail(String? email) async {
    final res = await fstore!
        .collection("users")
        .where("email", isEqualTo: email)
        .get();
    if (res.docs.isNotEmpty) {
      return CheckUserResponse(
          found: true, user: CustomUser.fromJson(res.docs.first));
    }
    return CheckUserResponse(found: false);
  }

  Future<DbResponse> createUserRecord(CustomUser? user) async {
    try {
      final r = await fstore!.collection('users').add(user!.toJson());
      await fstore!
          .collection('users')
          .doc(r.id)
          .set({"uid": r.id}, SetOptions(merge: true));
      return DbResponse(code: DbResponseCode.success, insertedId: r.id);
    } on Exception catch (e) {
      return DbResponse(code: DbResponseCode.failed, message: e.toString());
    }
  }

  Future<DbResponse> updateUserRecord(CustomUser? user) async {
    try {
      await fstore!
          .collection('users')
          .doc(user!.uid)
          .set(user.toJson(), SetOptions(merge: true));
      return DbResponse(code: DbResponseCode.success);
    } on Exception catch (e) {
      return DbResponse(code: DbResponseCode.failed, message: e.toString());
    }
  }

  Future<DbResponse> updateNotificationToken(String uid, String token) async {
    try {
      await fstore!
          .collection("users")
          .doc(uid)
          .set({"notificationToken": token}, SetOptions(merge: true));
      return DbResponse(code: DbResponseCode.success);
    } on Exception catch (e) {
      return DbResponse(code: DbResponseCode.failed, message: e.toString());
    }
  }

  //Discussion posts comments and replies

  Future<DbResponse> addDiscussionPost(DiscussionPost post, File? data) async {
    if (data != null) {
      final ref = FirebaseStorage.instanceFor(app: app).ref().child(data.path);
      await ref.putFile(data);
      post.media = await ref.getDownloadURL();
    }
    final res = await fstore!.collection('discussionPosts').add(post.toJson());
    final r = await fstore!.collection("users").get();
    CustomNotification notif = CustomNotification(
        title: "New Discussion",
        body: post.name! + " added a new discussion",
        type: "newdiscussionpost",
        targetObjectName: res.id);
    r.docs.forEach((element) async {
      if (element.id != post.uid) {
        await fstore!
            .collection("users")
            .doc(element.id)
            .collection("notifications")
            .add(notif.toJson());
      }
    });
    return DbResponse(code: DbResponseCode.success, insertedId: res.id);
  }

  Future<DbResponse> updatePost(DiscussionPost post, File? data) async {
    if (data != null) {
      final ref = FirebaseStorage.instanceFor(app: app).ref(post.media);
      await ref.putFile(data);
      post.media = await ref.getDownloadURL();
    }
    await fstore!
        .collection("discussionPosts")
        .doc(post.id)
        .set(post.toJson(), SetOptions(merge: true));
    return DbResponse(code: DbResponseCode.success);
  }

  Future<DbResponse> updateReports(DiscussionPost post, File? data) async {
    if (data != null) {
      final ref = FirebaseStorage.instanceFor(app: app).ref(post.media);
      await ref.putFile(data);
      post.media = await ref.getDownloadURL();
    }
    await fstore!
        .collection("discussionPosts")
        .doc(post.id)
        .update(post.toJson());
    return DbResponse(code: DbResponseCode.success);
  }

  Future<DbResponse> updateInternational(String newval) async {
    await fstore!
        .collection("users")
        .doc(user!.uid)
        .update({"isInternational": "$newval"});
    return DbResponse(code: DbResponseCode.success);
  }

  Future<DbResponse> updateEvent(Event post) async {
    await fstore!
        .collection("events")
        .doc(post.id)
        .set(post.toJson(), SetOptions(merge: true));
    return DbResponse(code: DbResponseCode.success);
  }

  Future<DbResponse> updateJob(JobPost post) async {
    await fstore!
        .collection("jobPosts")
        .doc(post.id)
        .set(post.toJson(), SetOptions(merge: true));
    return DbResponse(code: DbResponseCode.success);
  }

  Future<List<DiscussionPost>> getFirstDiscussionPosts() async {
    List<DiscussionPost> posts = [];
    final res = await fstore!
        .collection('discussionPosts')
        .orderBy("timestamp", descending: true)
        .limit(5)
        .get();
    if (res.docs.length > 0) {
      lastFetchedPost = res.docs.last;
      res.docs.forEach((element) {
        posts.add(DiscussionPost.fromJson(element));
      });
    }
    return posts;
  }

  Future<List<DiscussionPost>> getNextDiscussionPosts() async {
    List<DiscussionPost> posts = [];
    final res = await fstore!
        .collection('discussionPosts')
        .startAfterDocument(lastFetchedPost)
        .limit(5)
        .get();
    if (res.docs.length > 0) {
      lastFetchedPost = res.docs.last;
      res.docs.forEach((element) {
        posts.add(DiscussionPost.fromJson(element));
      });
    }
    return posts;
  }

  Future<List<JobPost>> getFirstJobPosts() async {
    List<JobPost> posts = [];
    final res = await fstore!.collection('jobPosts').limit(5).get();
    if (res.docs.length > 0) {
      lastFetchedJob = res.docs.last;
      res.docs.forEach((element) {
        Utils.debugPrint(element.id);
        posts.add(JobPost.fromJson(element));
      });
    }
    return posts;
  }

  Future<List<JobPost>> getNextJobPosts() async {
    List<JobPost> posts = [];
    final res = await fstore!
        .collection('jobPosts')
        .startAfterDocument(lastFetchedJob)
        .limit(5)
        .get();
    if (res.docs.length > 0) {
      lastFetchedJob = res.docs.last;
      res.docs.forEach((element) {
        posts.add(JobPost.fromJson(element));
      });
    }
    return posts;
  }

  Future<List<Event>> getFirstEventPosts() async {
    List<Event> posts = [];
    final res = await fstore!.collection('events').limit(5).get();
    if (res.docs.length > 0) {
      lastFetchedEvent = res.docs.last;
      res.docs.forEach((element) {
        posts.add(Event.fromJson(element));
      });
    }
    return posts;
  }

  Future<List<Event>> getNextEventPosts() async {
    List<Event> posts = [];
    final res = await fstore!
        .collection('events')
        .startAfterDocument(lastFetchedEvent)
        .limit(5)
        .get();
    if (res.docs.length > 0) {
      lastFetchedEvent = res.docs.last;
      res.docs.forEach((element) {
        posts.add(Event.fromJson(element));
      });
    }
    return posts;
  }

  Future<List<DiscussionComment>> getComments(String postId) async {
    List<DiscussionComment> cmnts = List.empty(growable: true);
    final res = await fstore!
        .collection("discussionPosts")
        .doc(postId)
        .collection("comments")
        .get();
    if (res.docs.isNotEmpty) {
      res.docs.forEach((element) {
        cmnts.add(DiscussionComment.fromJson(element));
      });
    }
    return cmnts;
  }

  Future<DbResponse> addComment(
      DiscussionPost post, DiscussionComment comment) async {
    final id = fstore!
        .collection("discussionPosts")
        .doc(post.id)
        .collection("comments")
        .doc()
        .id;
    comment.commentId = id;
    await fstore!
        .collection("discussionPosts")
        .doc(post.id)
        .collection("comments")
        .doc(id)
        .set(comment.toJson(), SetOptions(merge: true))
        .then((val) => print("[DEBUG] Done"))
        .onError((error, stackTrace) =>
            print("[ERROR Server.addComment]" + error.toString()));
    CustomNotification notification = CustomNotification(
        title: comment.commentBy! + " commented on your post: ${post.text}",
        body: comment.commentText,
        type: "discussioncomment",
        targetObjectName: post.id);
    if (post.uid != comment.commentUid) {
      await fstore!
          .collection("users")
          .doc(post.uid)
          .collection("notifications")
          .add(notification.toJson());
    }
    await fstore!.collection("discussionPosts").doc(post.id).set(
        {"commentCount": FieldValue.increment(1)}, SetOptions(merge: true));
    return DbResponse(code: DbResponseCode.success, insertedId: id);
  }

  Future<bool> likeComment(
      String postId, DiscussionComment comment, String uid) async {
    var res = false;
    final user = await getUserById(uid);
    await fstore!
        .collection("discussionPosts")
        .doc(postId)
        .collection("comments")
        .doc(comment.commentId)
        .set({
          "likedBy": FieldValue.arrayUnion([uid])
        }, SetOptions(merge: true))
        .whenComplete(() => res = true)
        .onError((error, stackTrace) => res = false);
    CustomNotification notif = CustomNotification(
        title: "New like",
        body:
            user.getFullName() + " liked your comment: ${comment.commentText}",
        type: "newlike",
        sent: true,
        targetObjectName: postId);
    await fstore!
        .collection("users")
        .doc(comment.commentUid)
        .collection("notifications")
        .add(notif.toJson());
    return res;
  }

  Future<bool> dislikeComment(
      String postId, String commentId, String uid) async {
    var res = false;
    await fstore!
        .collection("discussionPosts")
        .doc(postId)
        .collection("comments")
        .doc(commentId)
        .set({
          "likedBy": FieldValue.arrayRemove([uid])
        }, SetOptions(merge: true))
        .whenComplete(() => res = true)
        .onError((error, stackTrace) => res = false);
    return res;
  }

  Future<List<DiscussionPost>> getPostsByUser(String? uid) async {
    List<DiscussionPost> posts = [];
    final res = await fstore!
        .collection("discussionPosts")
        .where("uid", isEqualTo: uid)
        .orderBy("timestamp", descending: true)
        .get();
    if (res.docs.isNotEmpty) {
      res.docs.forEach((element) {
        posts.add(DiscussionPost.fromJson(element));
      });
    }
    return posts;
  }

  Future<List<JobPost>> getJobsByUser(String? uid) async {
    List<JobPost> posts = [];
    final res = await fstore!
        .collection("jobPosts")
        .where("postedBy", isEqualTo: uid)
        .orderBy("postedOn", descending: true)
        .get();
    if (res.docs.isNotEmpty) {
      res.docs.forEach((element) {
        posts.add(JobPost.fromJson(element));
      });
    }
    return posts;
  }

  Future<List<Event>> getEventsByUser(String? uid) async {
    List<Event> posts = [];
    final res = await fstore!
        .collection("events")
        .where("postedBy", isEqualTo: uid)
        .orderBy("postedOn", descending: true)
        .get();
    if (res.docs.isNotEmpty) {
      res.docs.forEach((element) {
        posts.add(Event.fromJson(element));
      });
    }
    return posts;
  }

  Future<List<JobPost>> getFirstJobs() async {
    List<JobPost> posts = [];
    final res = await fstore!
        .collection('discussionPosts')
        .orderBy("timestamp", descending: true)
        .limit(5)
        .get();
    if (res.docs.length > 0) {
      res.docs.forEach((element) {
        posts.add(JobPost.fromJson(element));
      });
    }
    return posts;
  }

  Future<DbResponse> dislikePost(DiscussionPost post, CustomUser? user) async {
    await fstore!.collection("discussionPosts").doc(post.id).set({
      "dislikedBy": FieldValue.arrayUnion([user!.uid]),
      "isDisliked": true,
    }, SetOptions(merge: true));
    CustomNotification notif = CustomNotification(
        title: "New dislike",
        body: user.getFullName() + " disliked your post:\n${post.text}",
        type: "newdislike",
        targetObjectName: post.id);
    await fstore!
        .collection("users")
        .doc(post.uid)
        .collection("notifications")
        .add(notif.toJson());
    return DbResponse(code: DbResponseCode.success);
  }

  Future<DbResponse> likePost(DiscussionPost post, CustomUser? user) async {
    await fstore!.collection("discussionPosts").doc(post.id).set({
      "likedBy": FieldValue.arrayUnion([user!.uid]),
      "isLiked": true,
    }, SetOptions(merge: true));
    CustomNotification notif = CustomNotification(
        title: "New like",
        body: user.getFullName() + " liked your post:\n${post.text}",
        type: "newlike",
        targetObjectName: post.id);
    await fstore!
        .collection("users")
        .doc(post.uid)
        .collection("notifications")
        .add(notif.toJson());
    return DbResponse(code: DbResponseCode.success);
  }

  Future<List<DiscussionPost>> searchPost(String? query) async {
    List<DiscussionPost> posts = [];
    final res = await fstore!.collection('discussionPosts').get();
    if (res.docs.isNotEmpty) {
      res.docs.forEach((element) {
        if (element["text"].toLowerCase().contains(query!.toLowerCase())) {
          posts.add(DiscussionPost.fromJson(element));
        }
      });
    }
    return posts;
  }

  Future<bool> addToArrayField(
      {required String collectionName,
      required String docId,
      required String fieldName,
      required dynamic object}) async {
    var res;
    await fstore!
        .collection(collectionName)
        .doc(docId)
        .set({
          fieldName: FieldValue.arrayUnion([object])
        }, SetOptions(merge: true))
        .whenComplete(() => res = true)
        .onError((error, stackTrace) => res = false);
    return res;
  }

  Future<bool> removeFromArrayField(
      {required String collectionName,
      required String docId,
      required String fieldName,
      required dynamic object}) async {
    var res;
    await fstore!
        .collection(collectionName)
        .doc(docId)
        .set({
          fieldName: FieldValue.arrayRemove([object])
        }, SetOptions(merge: true))
        .whenComplete(() => res = true)
        .onError((error, stackTrace) => res = false);
    return res;
  }

  Future<DbResponse> addJobPost(JobPost post) async {
    final val = await fstore!.collection('jobPosts').add(post.toJson());
    final res = await fstore!.collection("users").get();
    CustomNotification notif = CustomNotification(
        title: "New Job Post",
        body: post.company! + " is looking for " + post.role!,
        type: "newjob",
        targetObjectName: val.id);
    res.docs.forEach((element) async {
      if (element.id != post.postedBy) {
        await fstore!
            .collection("users")
            .doc(element.id)
            .collection("notifications")
            .add(notif.toJson());
      }
    });
    return DbResponse(code: DbResponseCode.success, insertedId: val.id);
  }

  Future<List<JobPost>> getJobPosts(CustomUser user) async {
    List<JobPost> posts = [];
    final res = await fstore!.collection('jobPosts').limit(10).get();
    if (res.docs.length > 0) {
      res.docs.forEach((element) {
        Utils.debugPrint(element.id);
        posts.add(JobPost.fromJson(element));
      });
    }
    return posts;
  }

  Future<DbResponse> applyToJob(JobPost job, String uid) async {
    final user = await getUserById(uid);
    await fstore!
        .collection('jobPosts')
        .doc(job.id)
        .update({"applicationCount": FieldValue.increment(1)});
    final res = await addToArrayField(
        collectionName: "jobPosts",
        docId: job.id!,
        fieldName: "applicants",
        object: uid);
    if (res) {
      CustomNotification notif = CustomNotification(
          title: "New job application",
          body: user.getFullName() +
              " applied to the job: ${job.role} at ${job.company}",
          type: "jobapplication",
          targetObjectName: uid);
      await fstore!
          .collection("users")
          .doc(job.postedBy)
          .collection("notifications")
          .add(notif.toJson());
      return DbResponse(code: DbResponseCode.success);
    }
    return DbResponse(code: DbResponseCode.failed);
  }

  Future<List<JobPost>> searchJobs(String? query, String? field) async {
    List<JobPost> posts = [];
    final res = await fstore!.collection('jobPosts').get();
    if (res.docs.isNotEmpty) {
      res.docs.forEach((element) {
        if (element[field!].toLowerCase().contains(query!.toLowerCase())) {
          posts.add(JobPost.fromJson(element));
        }
      });
    }
    return posts;
  }

  Future<DbResponse> addEvent(Event event) async {
    final val = await fstore!.collection('events').add(event.toJson());
    final res = await fstore!.collection("users").get();
    CustomNotification notif = CustomNotification(
        title: "New Event!",
        body: event.organizer! + " is organizing " + event.title!,
        type: "newevent",
        targetObjectName: val.id);
    res.docs.forEach((element) async {
      if (element.id != event.postedBy) {
        await fstore!
            .collection("users")
            .doc(element.id)
            .collection("notifications")
            .add(notif.toJson());
      }
    });
    return DbResponse(code: DbResponseCode.success, insertedId: val.id);
  }

  Future<DbResponse> attendEvent(Event event, String uid) async {
    final user = await getUserById(uid);
    await fstore!
        .collection('events')
        .doc(event.id)
        .update({"attendingCount": FieldValue.increment(1)});
    final res = await addToArrayField(
        collectionName: "events",
        docId: event.id!,
        fieldName: "attendees",
        object: uid);
    if (res) {
      CustomNotification notif = CustomNotification(
          title: "New attendee",
          body: user.getFullName() +
              " is attending the event you posted: ${event.title}",
          type: "eventattend",
          targetObjectName: event.id);
      await fstore!
          .collection("users")
          .doc(event.postedBy)
          .collection("notifications")
          .add(notif.toJson());
      return DbResponse(code: DbResponseCode.success);
    }
    return DbResponse(code: DbResponseCode.failed);
  }

  Future<List<Event>> searchEvent(String? query, String? field) async {
    List<Event> posts = [];
    final res = await fstore!.collection('events').get();
    if (res.docs.isNotEmpty) {
      res.docs.forEach((element) {
        if (element[field!].toLowerCase().contains(query!.toLowerCase())) {
          posts.add(Event.fromJson(element));
        }
      });
    }
    return posts;
  }

  Future<List<CustomUser>> searchPeopleByNameOnly(
      String query, CustomUser? user) async {
    List<CustomUser> results = [];
    final r = await fstore!
        .collection('users')
        .where("firstName",
            isGreaterThanOrEqualTo: query.toUpperCase(),
            isNotEqualTo: user!.firstName)
        .limit(10)
        .get();
    if (r.docs.length > 0) {
      r.docs.forEach((e) {
        if (e["firstName"].toLowerCase().contains(query.toLowerCase()) ||
            e["lastName"].toLowerCase().contains(query.toLowerCase())) {
          results.add(CustomUser.fromJson(e));
        }
      });
    }
    return results;
  }

  Future<List<CustomUser>> searchPeopleByNameAndYear(
      String query, CustomUser? user, int? year) async {
    List<CustomUser> results = [];
    final r = await fstore!
        .collection('users')
        .where("passoutYear", isEqualTo: year)
        .where("firstName",
            isEqualTo: query.toUpperCase(), isNotEqualTo: user!.firstName)
        .where("firstName",
            isEqualTo: query.toLowerCase(), isNotEqualTo: user.firstName)
        .where("lastName",
            isEqualTo: query.toUpperCase(), isNotEqualTo: user.lastName)
        .where("lastName",
            isEqualTo: query.toLowerCase(), isNotEqualTo: user.lastName)
        .limit(10)
        .get();
    if (r.docs.length > 0) {
      r.docs.forEach((e) {
        if (e["firstName"].toLowerCase().contains(query.toLowerCase()) ||
            e["lastName"].toLowerCase().contains(query.toLowerCase())) {
          results.add(CustomUser.fromJson(e));
        }
      });
    }
    return results;
  }

  Future<List<CustomUser>> searchPeopleByYearOnly(
      int? year, CustomUser? user) async {
    List<CustomUser> results = [];
    final r = await fstore!
        .collection('users')
        .where("passoutYear", isEqualTo: year)
        .where("uid", isNotEqualTo: user!.uid)
        .limit(10)
        .get();
    if (r.docs.length > 0) {
      r.docs.forEach((e) => results.add(CustomUser.fromJson(e)));
    }
    return results;
  }

  Future<List<CustomUser>> searchPeopleByIntYearOnly(
      int? year, CustomUser? user) async {
    List<CustomUser> results = [];
    final r = await fstore!
        .collection('users')
        .where("uid", isNotEqualTo: user!.uid)
        .where("passoutYear", isEqualTo: year)
        .where("isInternational", isEqualTo: true)
        // .limit(10)
        .get();
    if (r.docs.length > 0) {
      r.docs.forEach((e) => results.add(CustomUser.fromJson(e)));
    }
    return results;
  }

  Future<List<CustomUser>> searchPeopleByYearAndInternational(
      int? year, CustomUser? user) async {
    List<CustomUser> results = [];
    final r = await fstore!
        .collection('users')
        .where("passoutYear", isEqualTo: year)
        .where("isInternational", isEqualTo: true)
        .where("uid", isNotEqualTo: user!.uid)
        .limit(10)
        .get();
    if (r.docs.length > 0) {
      r.docs.forEach((e) => results.add(CustomUser.fromJson(e)));
    }
    return results;
  }

  Future<DbResponse> sendMessageInExistingChat(
      CustomMessage message, String? chatId) async {
    DbResponse res = DbResponse();
    await fstore!
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add(message.toJson())
        .then((val) async {
      res = DbResponse(code: DbResponseCode.success);
      await fstore!.collection("chats").doc(chatId).set(
          {"timestamp": message.timestamp!.millisecondsSinceEpoch},
          SetOptions(merge: true));
      final r = await fstore!.collection("users").doc(message.sentBy).get();
      CustomNotification notif = CustomNotification(
          title: r["firstName"] + " " + r["lastName"],
          body: message.text,
          type: "chat",
          targetObjectName: chatId);
      await fstore!
          .collection("users")
          .doc(message.to)
          .collection("notifications")
          .add(notif.toJson());
    }).onError((error, stackTrace) {
      res = DbResponse(code: DbResponseCode.failed, message: error.toString());
    });
    return res;
  }

  Future<DbResponse> sendMessageInNewChat(
      CustomMessage message, Chat chat) async {
    final res = await fstore!.collection("chats").add(chat.toJson());
    await fstore!.collection("chats").doc(res.id).set({
      "chatId": res.id,
      "timestamp": message.timestamp!.millisecondsSinceEpoch
    }, SetOptions(merge: true));
    await fstore!
        .collection("chats")
        .doc(res.id)
        .collection("messages")
        .add(message.toJson())
        .then((val) async {
      await fstore!.collection("chats").doc(chat.chatId).set(
          {"timestamp": message.timestamp!.millisecondsSinceEpoch},
          SetOptions(merge: true));
      final r = await fstore!.collection("users").doc(message.sentBy).get();
      CustomNotification notif = CustomNotification(
          title: r["firstName"] + " " + r["lastName"],
          body: message.text,
          type: "chat",
          targetObjectName: res.id);
      await fstore!
          .collection("users")
          .doc(message.to)
          .collection("notifications")
          .add(notif.toJson());
    });
    return DbResponse(code: DbResponseCode.success, insertedId: res.id);
  }

  Future<Chat> fetchMessages(
      Chat chat, CustomMessage? lastFetched, String? targetUid) async {
    if (lastFetched == null) {
      final res = await fstore!
          .collection("chats")
          .doc(chat.chatId)
          .collection("messages")
          .limit(10)
          .orderBy("timestamp")
          .get();
      if (res.docs.isNotEmpty) {
        res.docs.forEach((el) => chat.messages.add(CustomMessage.fromJson(el)));
        final docsToUpdate = await fstore!
            .collection("chats")
            .doc(chat.chatId)
            .collection("messages")
            .where("sentBy", isEqualTo: targetUid)
            .where("seen", isEqualTo: false)
            .get();
        if (docsToUpdate.docs.isNotEmpty) {
          docsToUpdate.docs.forEach((element) async {
            await fstore!
                .collection("chats")
                .doc(chat.chatId)
                .collection("messages")
                .doc(element.id)
                .set({"seen": true}, SetOptions(merge: true));
          });
        }
      } else {
        chat.messages.clear();
      }
      return chat;
    } else {
      final res = await fstore!
          .collection("chats")
          .doc(chat.chatId)
          .collection("messages")
          .startAfterDocument(lastFetched.toJson())
          .limit(10)
          .orderBy("timestamp")
          .get();
      if (res.docs.isNotEmpty) {
        res.docs.forEach((el) => chat.messages.add(CustomMessage.fromJson(el)));
      } else {
        chat.messages.clear();
      }
      return chat;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String? chatId) {
    return fstore!
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp")
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserChats(String? uid) {
    return fstore!
        .collection("chats")
        .where("users", arrayContains: uid)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  Future<Chat?> getChatBetweenUsers(String? uid, String? targetId) async {
    final res = await fstore!
        .collection("chats")
        .where("users", whereIn: [
          [uid, targetId],
          [targetId, uid]
        ])
        .limit(1)
        .get();
    if (res.docs.isNotEmpty) {
      return Chat.fromJson(res.docs.first);
    } else {
      return null;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamLastMessage(
      String? chatId) {
    return fstore!
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .limit(1)
        .snapshots();
  }

  Future<CustomUser> getUserById(String? uid) async {
    final r = await fstore!.collection("users").doc(uid).get();
    return CustomUser.fromJson(r);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUser(String? uid) {
    return fstore!.collection("users").doc(uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDiscussion(String? id) {
    return fstore!.collection("discussionPosts").doc(id).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamEvent(String? postId) {
    return fstore!.collection("events").doc(postId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamJob(String? postId) {
    return fstore!.collection("jobPosts").doc(postId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamNotif(
      String? uid, String? notifId) {
    return fstore!
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .doc(notifId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamDipsiteGroup(
      CustomUser? user) {
    return fstore!
        .collection("users")
        .where("passoutYear", isEqualTo: user!.passOutYear!)
        .where("uid", isNotEqualTo: user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamInternational(
      int? year, CustomUser? user) {
    return fstore!
        .collection("users")
        .where("isInternational", isEqualTo: true)
        .where("uid", isNotEqualTo: user!.uid)
        .where("passoutYear", isEqualTo: year)
        .snapshots();
  }
}
