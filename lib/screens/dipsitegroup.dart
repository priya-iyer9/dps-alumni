import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/screens/searchPeople.dart';
import 'package:alumniapp/ui/AppBar.dart';
import 'package:alumniapp/ui/Drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'ProfilePage.dart';

class DipsiteGroup extends StatefulWidget {
  final CustomUser user;
  final Server server;
  DipsiteGroup({required this.user, required this.server});
  @override
  _DipsiteGroupState createState() => _DipsiteGroupState();
}

class _DipsiteGroupState extends State<DipsiteGroup> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/bg2.jpeg"), fit: BoxFit.cover)),
        child: Scaffold(
          backgroundColor: Colors.white.withOpacity(0.9),
          key: scaffoldKey,
          drawer:
              Drawer(child: MyDrawer(user: widget.user, server: widget.server)),
          body: Container(
            child: Column(
              children: [
                CustomAppBar(
                    scaffoldKey: scaffoldKey,
                    user: widget.user,
                    server: widget.server,
                    title: "Dipsite Group"),
                Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: widget.server.streamDipsiteGroup(widget.user),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!.docs.length > 0) {
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final target =
                                CustomUser.fromJson(snapshot.data!.docs[index]);
                            return PeopleSearchResult(
                                searchResult: target,
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => ViewProfile(
                                            server: widget.server,
                                            user: widget.user,
                                            target: target))),
                                server: widget.server);
                          },
                        );
                      } else {
                        return Center(
                            child: Text("Empty dipsite group\n:(",
                                textAlign: TextAlign.center));
                      }
                    } else {
                      return Center(
                          child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
                      ));
                    }
                  },
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
