import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/DiscussionPost.dart';
import 'package:alumniapp/Service/Event.dart';
import 'package:alumniapp/Service/JobPost.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/Service/Utils.dart';
import 'package:alumniapp/screens/Events.dart';
import 'package:alumniapp/screens/Jobs.dart';
import 'package:alumniapp/screens/Messaging.dart';
import 'package:alumniapp/screens/ProfilePage.dart';
import 'package:alumniapp/screens/discussions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final CustomUser? user;
  final Server server;
  final String title;
  CustomAppBar(
      {this.scaffoldKey,
      required this.user,
      required this.server,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            GestureDetector(
                onTap: () => scaffoldKey!.currentState!.openDrawer(),
                child: Icon(Icons.sort, color: Color(0xff77ACF1), size: 27)),
            Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.black))),
            Expanded(child: Container()),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: server.getNotifications(user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    print(snapshot.data!.docs.length);
                    return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => Notifications(
                                    user: user!, server: server))),
                        child: Stack(
                          children: [
                            Icon(CupertinoIcons.bell_solid,
                                color: Color(0xff77ACF1), size: 23.0),
                            snapshot.data!.docs.length > 0
                                ? Positioned(
                                    right: 0,
                                    child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xffA259FF),
                                          borderRadius:
                                              BorderRadius.circular(7),
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 14,
                                          minHeight: 14,
                                        ),
                                        child: Center(
                                            child: Text(
                                                snapshot.data!.docs.length
                                                    .toString(),
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8)))))
                                : Container(height: 0)
                          ],
                        ));
                  } else {
                    return Icon(CupertinoIcons.bell_fill,
                        color: Color(0xff77ACF1), size: 23.0);
                  }
                }),
            SizedBox(width: 15),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      ProfilePage(user: user, server: server))),
              child: Icon(CupertinoIcons.person_solid,
                  color: Color(0xff77ACF1), size: 23.0),
            ),
            SizedBox(width: 15),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: server.getUnseen(user!.uid),
                builder: (context, snapshot) {
                  return GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              AllMessagesScreen(user: user, server: server))),
                      child: Stack(
                        children: [
                          Icon(CupertinoIcons.chat_bubble_2_fill,
                              color: Color(0xff77ACF1), size: 23.0),
                          snapshot.hasData
                              ? snapshot.data!.docs.length > 0
                                  ? Positioned(
                                      right: 0,
                                      child: Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xffA259FF),
                                            borderRadius:
                                                BorderRadius.circular(7),
                                          ),
                                          constraints: BoxConstraints(
                                            minWidth: 14,
                                            minHeight: 14,
                                          ),
                                          child: Center(
                                              child: Text(
                                                  snapshot.data!.docs.length
                                                      .toString(),
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8)))))
                                  : Container(height: 0)
                              : Container(height: 0)
                        ],
                      ));
                })
          ],
        ));
  }
}

class Notifications extends StatefulWidget {
  final CustomUser user;
  final Server server;
  Notifications({required this.user, required this.server});
  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  List<CustomNotification> notifications = List.empty(growable: true);

  @override
  void initState() {
    getNotifications();
    super.initState();
  }

  getNotifications() async {
    final res = await widget.server.getUserNotifications(widget.user.uid);
    if (res.length > 0) {
      setState(() {
        notifications = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: SingleChildScrollView(
                child: Container(
      height: MediaQuery.of(context).size.height,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.chevron_left_rounded, size: 28))),
            Expanded(child: Container()),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: GestureDetector(
                    onTap: getNotifications,
                    child: Icon(Icons.replay, size: 28))),
          ],
        ),
        Expanded(
            child: ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          shrinkWrap: true,
          itemBuilder: (context, index) => NotificationTile(
              server: widget.server,
              user: widget.user,
              notification: notifications[index]),
        ))
      ]),
    ))));
  }
}

class NotificationTile extends StatefulWidget {
  final CustomUser user;
  final Server server;
  final CustomNotification notification;
  NotificationTile(
      {required this.server, required this.user, required this.notification});
  @override
  _NotificationTileState createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  dynamic object;
  @override
  void initState() {
    super.initState();
    processNotification();
  }

  processNotification() async {
    switch (widget.notification.type) {
      case "newdiscussionpost":
        final p =
            await widget.server.getPost(widget.notification.targetObjectName);
        setState(() {
          object = p;
        });
        break;
      case "discussioncomment":
        final p =
            await widget.server.getPost(widget.notification.targetObjectName);
        setState(() {
          object = p;
        });
        break;
      case "newlike":
        Utils.debugPrint(widget.notification.targetObjectName);
        final p =
            await widget.server.getPost(widget.notification.targetObjectName);
        setState(() {
          object = p;
        });
        break;
      case "newjob":
        final p = await widget.server
            .getJobPost(widget.notification.targetObjectName);
        setState(() {
          object = p;
        });
        break;
      case "jobapplication":
        final p = await widget.server
            .getUserById(widget.notification.targetObjectName);
        setState(() {
          object = p;
        });
        break;
      case "newevent":
        final p =
            await widget.server.getEvent(widget.notification.targetObjectName);
        setState(() {
          object = p;
        });
        break;
      case "eventattend":
        Utils.debugPrint(widget.notification.targetObjectName);
        final p =
            await widget.server.getEvent(widget.notification.targetObjectName);
        setState(() {
          object = p;
        });
        break;
    }
  }

  redirect(BuildContext context) async {
    if (object is DiscussionPost) {
      await widget.server
          .notificationSeen(widget.user.uid, widget.notification.id);
      print("DiscussionPost");
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ViewPost(
              post: object,
              server: widget.server,
              user: widget.user,
              fromNotifs: true,
              notifId: widget.notification.id)));
    }
    if (object is Event) {
      await widget.server
          .notificationSeen(widget.user.uid, widget.notification.id);
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => EventDetailsScreen(
              event: object,
              user: widget.user,
              server: widget.server,
              fromNotifs: true,
              notifId: widget.notification.id)));
    }
    if (object is CustomUser) {
      await widget.server
          .notificationSeen(widget.user.uid, widget.notification.id);
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ViewProfile(
              user: widget.user, target: object, server: widget.server)));
    }
    if (object is JobPost) {
      await widget.server
          .notificationSeen(widget.user.uid, widget.notification.id);
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => JobDetailsScreen(
              job: object, user: widget.user, server: widget.server)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            widget.server.streamNotif(widget.user.uid, widget.notification.id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            try {
              final n = CustomNotification.fromJson(snapshot.data);

              return MaterialButton(
                onPressed: () => widget.server
                    .notificationSeen(widget.user.uid, widget.notification.id),
                // redirect(context),
                child: Container(
                  width: MediaQuery.of(context).size.width - 20,
                  color: n.seen ? Colors.transparent : Color(0xffE5E5E5),
                  child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title.toString()),
                          Text(n.body.toString(),
                              style: TextStyle(fontWeight: FontWeight.w300)),
                        ],
                      )),
                ),
              );
            } on Exception catch (e) {
              return Container(height: 0);
            }
          } else {
            return Container(height: 0);
          }
        });
  }
}
