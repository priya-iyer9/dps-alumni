import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/screens/searchPeople.dart';
import 'package:alumniapp/ui/AppBar.dart';
import 'package:alumniapp/ui/Drawer.dart';
import 'package:alumniapp/ui/InputField.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'ProfilePage.dart';

class InternationalStudents extends StatefulWidget {
  final CustomUser user;
  final Server server;
  InternationalStudents({required this.user, required this.server});
  @override
  _InternationalStudentsState createState() => _InternationalStudentsState();
}

class _InternationalStudentsState extends State<InternationalStudents> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  late List<CustomUser> searchResults;
  late String yopstr;
  @override
  void initState() {
    super.initState();
    searchResults = List.empty(growable: true);
    yopstr = "";
  }

  yearChanged(String? val) async {
    setState(() {
      yopstr = val!;
    });
    final res = await widget.server
        .searchPeopleByIntYearOnly(int.parse(val!), widget.user);
    if (res.isNotEmpty) {
      setState(() {
        searchResults = res;
      });
    } else {
      setState(() {
        searchResults = [];
      });
    }
  }

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
          drawer: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(150),
              topRight: Radius.circular(150),
            ),
            child: SizedBox(
                child: Drawer(
                    child: MyDrawer(user: widget.user, server: widget.server))),
          ),
          body: Container(
              child: Column(children: [
            CustomAppBar(
                scaffoldKey: scaffoldKey,
                user: widget.user,
                server: widget.server,
                title: "International Connect"),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: CustomDropDown(
                        items: [
                          for (var i = 1990; i < 2030; i += 1) i.toString()
                        ],
                        onChanged: yearChanged,
                        text: yopstr == "" ? null : yopstr,
                        error: false,
                        hint: "Filter by year of passing"),
                  ),
                  SizedBox(width: 5),
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          yopstr = "";
                        });
                      },
                      child: Text(
                        "CLEAR",
                        style: TextStyle(
                            color: Color(0xff77ACF1),
                            fontWeight: FontWeight.w500),
                      ))
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
                child: yopstr == ""
                    ? Container(height: 0)
                    : searchResults.length > 0
                        ? ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) => PeopleSearchResult(
                                  searchResult: searchResults[index],
                                  server: widget.server,
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) => ViewProfile(
                                              server: widget.server,
                                              user: widget.user,
                                              target: searchResults[index]))),
                                ))
                        : Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: Text("No Results"))))
          ])),
          // Expanded(
          //     child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          //   stream: widget.server
          //       .streamInternational(int.parse(yopstr), widget.user),
          //   builder: (context, snapshot) {
          //     if (snapshot.hasData) {
          //       if (snapshot.data!.docs.length > 0) {
          //         return ListView.builder(
          //           itemCount: snapshot.data!.docs.length,
          //           shrinkWrap: true,
          //           itemBuilder: (context, index) {
          //             final target =
          //                 CustomUser.fromJson(snapshot.data!.docs[index]);
          //             return PeopleSearchResult(
          //                 searchResult: target,
          //                 onTap: () => Navigator.of(context).push(
          //                     MaterialPageRoute(
          //                         builder: (context) => ViewProfile(
          //                             server: widget.server,
          //                             user: widget.user,
          //                             target: target))),
          //                 server: widget.server);
          //           },
          //         );
          //       } else {
          //         return Center(
          //             child: Text("Empty dipsite group\n:(",
          //                 textAlign: TextAlign.center));
          //       }
          //     } else {
          //       return Center(
          //           child: CircularProgressIndicator(
          //         valueColor:
          //             AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
          //       ));
          //     }
          //   },
          // ))
          //     ],
          //   ),
          // ),
        ),
      ),
    );
  }
}
