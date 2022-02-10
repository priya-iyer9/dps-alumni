import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/ui/CustomAvatar.dart';
import 'package:alumniapp/ui/InputField.dart';
import 'package:flutter/material.dart';

import 'ProfilePage.dart';

class SearchPeople extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  SearchPeople({required this.user, required this.server});
  @override
  _SearchPeopleState createState() => _SearchPeopleState();
}

class _SearchPeopleState extends State<SearchPeople> {
  late TextEditingController searchController;
  late List<CustomUser> searchResults;
  late String yopstr;
  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchResults = List.empty(growable: true);
    yopstr = "";
  }

  search() async {
    setState(() {
      searchResults = [];
    });
    if (searchController.value.text.trim() != "" && yopstr != "") {
      final res = await widget.server.searchPeopleByNameAndYear(
          searchController.value.text.trim(), widget.user, int.parse(yopstr));
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
    if (searchController.value.text.trim() == "" && yopstr != "") {
      print("Searching by year only");
      final res = await widget.server
          .searchPeopleByYearOnly(int.parse(yopstr), widget.user);
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
    if (searchController.value.text.trim() != "" && yopstr == "") {
      final res = await widget.server.searchPeopleByNameOnly(
          searchController.value.text.trim(), widget.user);
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
  }

  yearChanged(String? val) async {
    setState(() {
      yopstr = val!;
    });
    final res = await widget.server
        .searchPeopleByYearOnly(int.parse(val!), widget.user);
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
          appBar: AppBar(
            leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 28,
                  color: Color(0xff77ACF1),
                )),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            title: Text(
              "Search",
              style: TextStyle(
                  color: Color(0xff77ACF1), fontWeight: FontWeight.w500),
            ),
            centerTitle: true,
          ),
          body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Padding(
            //     padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            //     child: GestureDetector(
            //         onTap: () => Navigator.of(context).pop(),
            //         child: Icon(Icons.chevron_left_rounded, size: 28))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: InputField(
                error: false,
                hint: "Search People",
                controller: searchController,
                suffixIcon: Icon(Icons.search, color: Colors.grey[600]),
                onChanged: (q) => search(),
              ),
            ),
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
                          searchController.text = "";
                          searchResults = [];
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
                child: searchController.value.text == "" && yopstr == ""
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
    ));
  }
}

class PeopleSearchResult extends StatelessWidget {
  final CustomUser searchResult;
  final void Function() onTap;
  final Server server;
  PeopleSearchResult(
      {required this.searchResult, required this.onTap, required this.server});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 26),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomAvatar(user: searchResult, server: server, radius: 30),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  searchResult.firstName.toString() +
                      " " +
                      searchResult.lastName.toString(),
                  style: TextStyle(
                      color: Color(0xff77ACF1), fontWeight: FontWeight.w600),
                ),
                Container(
                    width: 200,
                    child: Text(searchResult.collegeName.toString(),
                        style: TextStyle(color: Colors.black54)))
              ],
            ),
          ],
        ),
      )),
    );
  }
}
