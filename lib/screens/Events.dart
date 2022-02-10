import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/Event.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/Service/Utils.dart';
import 'package:alumniapp/ui/AppBar.dart';
import 'package:alumniapp/ui/Drawer.dart';
import 'package:alumniapp/ui/InputField.dart';
import 'package:alumniapp/ui/actionbuttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';

import 'ProfilePage.dart';

class EventScreen extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  EventScreen({required this.user, required this.server});
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late List<Event?> posts;
  bool loading = false;

  @override
  initState() {
    posts = [];
    getPosts();
    super.initState();
  }

  getPosts() async {
    setState(() {
      loading = true;
      posts = [];
    });
    final res = await widget.server.getFirstEventPosts();
    setState(() {
      posts = res;
      loading = false;
    });
  }

  loadMore() async {
    final res = await widget.server.getNextEventPosts();
    setState(() {
      posts += res;
      loading = false;
    });
  }

  postEvent() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          PostEventScreen(user: widget.user, server: widget.server),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              animation.drive(Tween(begin: Offset(0, 1), end: Offset.zero)),
          child: child,
        );
      },
    ));
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
                      child:
                          MyDrawer(user: widget.user, server: widget.server)))),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Colors.purpleAccent, Colors.deepPurpleAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              // backgroundColor: Color(0xffA259FF),
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: postEvent,
            ),
          ),
          body: Container(
              child: Column(children: [
            CustomAppBar(
                scaffoldKey: scaffoldKey,
                user: widget.user,
                server: widget.server,
                title: "Events"),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => SearchEvent(
                          user: widget.user!, server: widget.server))),
                  child: Container(
                      width: MediaQuery.of(context).size.width - 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Color(0xffE0E0E0),
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            Text("Search Events",
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13)),
                            Expanded(child: Container()),
                            Icon(Icons.search_rounded, color: Colors.grey[600])
                          ],
                        ),
                      ))),
            ),
            Expanded(
              child: Padding(
                  padding: EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: RefreshIndicator(
                    onRefresh: () => getPosts(),
                    child: loading
                        ? Center(
                            child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xffA259FF)),
                          ))
                        : posts.length == 0
                            ? Center(
                                child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("No Posts"),
                                  IconButton(
                                    icon: Icon(Icons.replay),
                                    onPressed: getPosts,
                                  )
                                ],
                              ))
                            : ListView.builder(
                                physics: BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                shrinkWrap: true,
                                itemCount: posts.length,
                                itemBuilder: (context, index) => EventPostTile(
                                    event: posts[index]!,
                                    server: widget.server,
                                    user: widget.user),
                              ),
                  )),
            ),
            if (posts.length == 5)
              MaterialButton(onPressed: loadMore, child: Text("Load More"))
          ]))),
    ));
  }
}

class EventPostTile extends StatelessWidget {
  final Event event;
  final CustomUser? user;
  final Server server;
  EventPostTile(
      {required this.event, required this.user, required this.server});

  deleteDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Delete Post?"),
            content: Text("Event once deleted cannot be retrieved.\nContinue?"),
            actions: [
              MaterialButton(
                  onPressed: () => deletePost(context), child: Text("Yes")),
              MaterialButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("No")),
            ],
          );
        });
  }

  deletePost(BuildContext context) async {
    await server.deleteEvent(event);
    Navigator.of(context).pop();
  }

  editPost(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            EditEvent(server: server, user: user!, event: event)));
  }

  details() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          EventDetailsScreen(event: event, server: server, user: user),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              animation.drive(Tween(begin: Offset(0, 1), end: Offset.zero)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: server.streamEvent(event.id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final ev = Event.fromJson(snapshot.data);
                return MaterialButton(
                  onPressed: () => Navigator.of(context).push(details()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ev.title.toString(),
                                  style: TextStyle(
                                      fontSize: 16, color: Color(0xff04009A)),
                                  overflow: TextOverflow.ellipsis),
                              Text(ev.organizer.toString(),
                                  style: TextStyle(
                                      color: Color(0xff77ACF1), fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                          Expanded(child: Container()),
                          if (ev.postedBy == user!.uid || user!.type == "admin")
                            IconButton(
                              icon: Icon(Icons.delete_outline),
                              onPressed: () => deleteDialog(context),
                            ),
                          if (ev.postedBy == user!.uid)
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => editPost(context),
                            )
                        ],
                      ),
                      SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(Utils.getDate(ev.datetime) +
                              "  " +
                              Utils.getOnlyTime(ev.datetime!)),
                          Expanded(child: Container()),
                          Text(ev.attendingCount.toString() + " attending",
                              style: TextStyle(
                                  color: Color(0xff727272), fontSize: 12),
                              overflow: TextOverflow.ellipsis)
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset("assets/location_pin.png", scale: 2.2),
                          Text(ev.venue.toString(),
                              style: TextStyle(
                                  color: Color(0xff727272), fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                          Expanded(child: Container()),
                          ev.entryCharges != 0
                              ? Text(
                                  "Entry charges: Rs.${ev.entryCharges.toString()}",
                                  style: TextStyle(
                                      color: Color(0xff727272), fontSize: 12),
                                  overflow: TextOverflow.ellipsis)
                              : Text("FREE",
                                  style: TextStyle(
                                      color: Color(0xff727272), fontSize: 12),
                                  overflow: TextOverflow.ellipsis)
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Divider(),
                      )
                    ],
                  ),
                );
              } else {
                return Container(height: 0);
              }
            }));
  }
}

class EventDetailsScreen extends StatefulWidget {
  final Event event;
  final CustomUser? user;
  final Server server;
  final bool fromNotifs;
  final String? notifId;
  EventDetailsScreen(
      {required this.event,
      required this.user,
      required this.server,
      this.fromNotifs = false,
      this.notifId});
  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late bool attending;
  CustomUser? postedBy;
  @override
  void initState() {
    attending = widget.event.attendees!.contains(widget.user!.uid);
    notifSeen();
    getUser();
    super.initState();
  }

  getUser() async {
    final res = await widget.server.getUserById(widget.event.postedBy);
    setState(() {
      postedBy = res;
    });
  }

  notifSeen() {
    if (widget.fromNotifs) {
      widget.server.notificationSeen(widget.user!.uid, widget.notifId);
    }
  }

  attend() async {
    if (!attending) {
      final res = await widget.server
          .attendEvent(widget.event, widget.user!.uid.toString());
      if (res.code == DbResponseCode.success) {
        setState(() {
          attending = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(Icons.chevron_left_rounded, size: 28))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    child: Text(widget.event.title.toString(),
                        style: TextStyle(fontSize: 20)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                    child: Row(
                      children: [
                        Text("Organized by:  ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.event.organizer.toString())
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                    child: Row(
                      children: [
                        Text("Venue:  ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.event.venue.toString())
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                    child: Row(
                      children: [
                        Text("Charges:  ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        widget.event.entryCharges == 0
                            ? Text("FREE", style: TextStyle(fontSize: 16))
                            : Text(
                                "Rs. " + widget.event.entryCharges.toString(),
                                style: TextStyle(fontSize: 16))
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    child: Text(
                        Utils.getDate(widget.event.datetime) +
                            "   " +
                            Utils.getOnlyTime(widget.event.datetime!),
                        style: TextStyle(fontSize: 14)),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      if (postedBy != null)
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 25, vertical: 10),
                          child: Row(
                            children: [
                              Text("Posted by: "),
                              GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) => ViewProfile(
                                              user: widget.user,
                                              target: postedBy,
                                              server: widget.server))),
                                  child: Text(postedBy!.getFullName(),
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25),
                        child: Text(
                            widget.event.attendingCount.toString() +
                                " attending",
                            style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  Divider(height: 30),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25),
                    child: Text(widget.event.description.toString(),
                        style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
              bottom: 3,
              left: 0,
              right: 0,
              child: Center(
                  child: !attending
                      ? PrimaryButton(
                          onTap: attend,
                          text: "Attend",
                          width: MediaQuery.of(context).size.width - 50)
                      : Container(
                          width: 120,
                          height: 40,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color.fromRGBO(3, 163, 99, 1),
                                    Color.fromRGBO(8, 199, 68, 1)
                                  ])),
                          child: Center(
                              child: Text("Attending!",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500))))))
        ],
      )),
    );
  }
}

class PostEventScreen extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  PostEventScreen({required this.user, required this.server});
  @override
  _PostEventScreenState createState() => _PostEventScreenState();
}

class _PostEventScreenState extends State<PostEventScreen> {
  late bool titleError,
      venueError,
      organizerError,
      openForError,
      descriptionError,
      loading,
      dateError;
  late TextEditingController titleController,
      venueController,
      organizerController,
      openForController,
      descriptionController,
      dateController,
      entryChargesController;
  DateTime? dateTime;
  late FocusNode venueNode,
      organizerNode,
      openForNode,
      descriptionNode,
      chargesNode;
  @override
  void initState() {
    super.initState();
    loading = false;
    titleError = false;
    venueError = false;
    organizerError = false;
    openForError = false;
    descriptionError = false;
    dateError = false;
    titleController = TextEditingController();
    venueController = TextEditingController();
    organizerController = TextEditingController();
    openForController = TextEditingController();
    descriptionController = TextEditingController();
    dateController = TextEditingController(text: "Select Date and Time");
    entryChargesController = TextEditingController();
    venueNode = FocusNode();
    organizerNode = FocusNode();
    openForNode = FocusNode();
    descriptionNode = FocusNode();
    chargesNode = FocusNode();
  }

  post() async {
    setState(() {
      loading = true;
      titleError = titleController.value.text.trim() == "";
      venueError = venueController.value.text.trim() == "";
      organizerError = organizerController.value.text.trim() == "";
      openForError = openForController.value.text.trim() == "";
      descriptionError = descriptionController.value.text.trim() == "";
      dateError = dateTime == null;
    });
    final isError = titleError ||
        venueError ||
        organizerError ||
        openForError ||
        descriptionError ||
        dateError;
    if (!isError) {
      final event = Event(
          title: titleController.value.text.trim(),
          venue: venueController.value.text.trim(),
          description: descriptionController.value.text.trim(),
          organizer: organizerController.value.text.trim(),
          openFor: openForController.value.text.trim(),
          entryCharges: int.parse(entryChargesController.value.text.trim()),
          attendingCount: 0,
          organization: widget.user!.collegeName,
          datetime: dateTime,
          postedBy: widget.user!.uid);
      final res = await widget.server.addEvent(event);
      if (res.code == DbResponseCode.success) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Event uploaded")));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Event upload failed :(")));
        setState(() {
          loading = false;
        });
      }
    }
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: Stack(
      children: [
        SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.chevron_left_rounded, size: 28))),
              SizedBox(height: 30),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Title",
                    error: titleError,
                    controller: titleController,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(venueNode),
                    errorMessage: "Please provide a title",
                    onChanged: (val) {
                      setState(() {
                        titleError = false;
                      });
                    },
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Venue",
                    focusNode: venueNode,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(organizerNode),
                    controller: venueController,
                    error: venueError,
                    errorMessage: "Venue cannot be empty",
                    onChanged: (val) {
                      setState(() {
                        venueError = false;
                      });
                    },
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Organized By",
                    controller: organizerController,
                    error: organizerError,
                    focusNode: organizerNode,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(chargesNode),
                    errorMessage: "Organizer cannot be empty",
                    onChanged: (val) {
                      setState(() {
                        organizerError = false;
                      });
                    },
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    controller: entryChargesController,
                    keyboardType: TextInputType.number,
                    hint: "Entry Charges (0 for FREE)",
                    error: false,
                    focusNode: chargesNode,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(openForNode),
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Open For",
                    maxLines: 4,
                    controller: openForController,
                    error: openForError,
                    errorMessage: "Please enter expected audience",
                    focusNode: openForNode,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(descriptionNode),
                    onChanged: (val) {
                      setState(() {
                        openForError = false;
                      });
                    },
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Description",
                    maxLines: 4,
                    controller: descriptionController,
                    error: descriptionError,
                    errorMessage: "Please provide a short description",
                    focusNode: descriptionNode,
                    onEditingComplete: () => FocusScope.of(context).unfocus(),
                    onChanged: (val) {
                      setState(() {
                        descriptionError = false;
                      });
                    },
                  )),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                child: Container(
                    color: dateError ? Color(0xffFFDBDB) : Color(0xfff0f0f0),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: DateTimePicker(
                        controller: dateController,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        type: DateTimePickerType.dateTime,
                        use24HourFormat: false,
                        decoration: InputDecoration(border: InputBorder.none),
                        onChanged: (val) {
                          setState(() {
                            dateError = false;
                            dateTime = DateTime.parse(val);
                          });
                        },
                      ),
                    )),
              ),
              SizedBox(height: 10),
              Center(child: PrimaryButton(text: "Post", onTap: post))
            ])),
        Container(
            height: loading ? MediaQuery.of(context).size.height : 0,
            color: Colors.black.withOpacity(0.8),
            child: Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
            )))
      ],
    )));
  }
}

class SearchEvent extends StatefulWidget {
  final CustomUser user;
  final Server server;
  SearchEvent({required this.server, required this.user});
  @override
  _SearchEventState createState() => _SearchEventState();
}

class _SearchEventState extends State<SearchEvent> {
  late TextEditingController searchController;
  late List<Event> searchResults;
  late int selected;
  FocusNode searchNode = FocusNode();
  final fields = [
    {"name": "Title", "value": "title"},
    {"name": "Location", "value": "venue"},
    {"name": "Organizer", "value": "organizer"}
  ];
  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchResults = List.empty(growable: true);
    searchNode.requestFocus();
    selected = 0;
  }

  search() async {
    setState(() {
      searchResults = [];
    });
    if (searchController.value.text != "") {
      final res = await widget.server
          .searchEvent(searchController.value.text, fields[selected]["value"]);
      setState(() {
        searchResults = res;
      });
    }
  }

  changeSelectedIndex(index) {
    setState(() {
      selected = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.chevron_left_rounded, size: 28))),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: InputField(
          error: false,
          hint: "Search Events",
          controller: searchController,
          focusNode: searchNode,
          suffixIcon: Icon(Icons.search, color: Color(0xffa4a4a4)),
          onChanged: (q) => search(),
        ),
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        height: 60,
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Search by: "),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => changeSelectedIndex(index),
                        child: FilterCookie(
                            text: fields[index]["name"].toString(),
                            selected: index == selected),
                      );
                    },
                  ),
                ),
              ],
            )),
      ),
      Expanded(
          child: searchController.value.text == ""
              ? Container(height: 0)
              : searchResults.length > 0
                  ? ListView.builder(
                      itemCount: searchResults.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) => EventPostTile(
                          event: searchResults[index],
                          server: widget.server,
                          user: widget.user))
                  : Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: Text("No Results"))))
    ])));
  }
}

class EditEvent extends StatefulWidget {
  final Server server;
  final CustomUser user;
  final Event event;
  EditEvent({required this.server, required this.user, required this.event});
  @override
  _EditEventState createState() => _EditEventState();
}

class _EditEventState extends State<EditEvent> {
  late bool titleError,
      venueError,
      organizerError,
      openForError,
      descriptionError,
      loading,
      dateError;
  late TextEditingController titleController,
      venueController,
      organizerController,
      openForController,
      descriptionController,
      dateController,
      entryChargesController;
  DateTime? dateTime;
  late FocusNode venueNode,
      organizerNode,
      openForNode,
      descriptionNode,
      chargesNode;
  @override
  void initState() {
    super.initState();
    loading = false;
    titleError = false;
    venueError = false;
    organizerError = false;
    openForError = false;
    descriptionError = false;
    dateError = false;
    titleController = TextEditingController(text: widget.event.title);
    venueController = TextEditingController(text: widget.event.venue);
    organizerController = TextEditingController(text: widget.event.organizer);
    openForController = TextEditingController(text: widget.event.openFor);
    descriptionController =
        TextEditingController(text: widget.event.description);
    dateController =
        TextEditingController(text: widget.event.datetime.toString());
    entryChargesController =
        TextEditingController(text: widget.event.entryCharges.toString());
    dateTime = widget.event.datetime;
    venueNode = FocusNode();
    organizerNode = FocusNode();
    openForNode = FocusNode();
    descriptionNode = FocusNode();
    chargesNode = FocusNode();
  }

  post() async {
    final event = Event(
        id: widget.event.id,
        title: titleController.value.text.trim() != ""
            ? titleController.value.text.trim()
            : widget.event.title,
        venue: venueController.value.text.trim() != ""
            ? venueController.value.text.trim()
            : widget.event.venue,
        description: descriptionController.value.text.trim() != ""
            ? descriptionController.value.text.trim()
            : widget.event.description,
        organizer: organizerController.value.text.trim() != ""
            ? organizerController.value.text.trim()
            : widget.event.organizer,
        openFor: openForController.value.text.trim() != ""
            ? openForController.value.text.trim()
            : widget.event.openFor,
        entryCharges: entryChargesController.value.text.trim() != ""
            ? int.parse(entryChargesController.value.text.trim())
            : widget.event.entryCharges,
        attendingCount: widget.event.attendingCount,
        organization: widget.user.collegeName,
        attendees: widget.event.attendees,
        datetime: dateTime,
        postedBy: widget.user.uid,
        postedOn: widget.event.postedOn);
    final res = await widget.server.updateEvent(event);
    if (res.code == DbResponseCode.success) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Event updated")));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Event update failed :(")));
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: Stack(
      children: [
        SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.chevron_left_rounded, size: 28))),
              SizedBox(height: 30),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Title",
                    error: titleError,
                    controller: titleController,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(venueNode),
                    errorMessage: "Please provide a title",
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                      hint: "Venue",
                      focusNode: venueNode,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(organizerNode),
                      controller: venueController,
                      error: venueError,
                      errorMessage: "Venue cannot be empty")),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                      hint: "Organized By",
                      controller: organizerController,
                      error: organizerError,
                      focusNode: organizerNode,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(chargesNode),
                      errorMessage: "Organizer cannot be empty")),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    controller: entryChargesController,
                    keyboardType: TextInputType.number,
                    hint: "Entry Charges (0 for FREE)",
                    error: false,
                    focusNode: chargesNode,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(openForNode),
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Open For",
                    maxLines: 4,
                    controller: openForController,
                    error: openForError,
                    errorMessage: "Please enter expected audience",
                    focusNode: openForNode,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(descriptionNode),
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Description",
                    maxLines: 4,
                    controller: descriptionController,
                    error: descriptionError,
                    errorMessage: "Please provide a short description",
                    focusNode: descriptionNode,
                    onEditingComplete: () => FocusScope.of(context).unfocus(),
                  )),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                child: Container(
                    color: dateError ? Color(0xffFFDBDB) : Color(0xfff0f0f0),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: DateTimePicker(
                        controller: dateController,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        type: DateTimePickerType.dateTime,
                        use24HourFormat: false,
                        decoration: InputDecoration(border: InputBorder.none),
                        onChanged: (val) {
                          setState(() {
                            dateTime = DateTime.parse(val);
                          });
                        },
                      ),
                    )),
              ),
              SizedBox(height: 10),
              Center(child: PrimaryButton(text: "Update", onTap: post))
            ])),
        Container(
            height: loading ? MediaQuery.of(context).size.height : 0,
            color: Colors.black.withOpacity(0.8),
            child: Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
            )))
      ],
    )));
  }
}
