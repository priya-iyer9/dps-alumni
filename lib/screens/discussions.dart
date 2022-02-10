// ignore_for_file: must_be_immutable

import 'dart:io';
import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/DiscussionPost.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/Service/Utils.dart';
import 'package:alumniapp/ui/AppBar.dart';
import 'package:alumniapp/ui/CustomAvatar.dart';
import 'package:alumniapp/ui/Drawer.dart';
import 'package:alumniapp/ui/InputField.dart';
import 'package:alumniapp/ui/actionbuttons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ProfilePage.dart';

class DiscussionsPage extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  DiscussionsPage({required this.user, required this.server});
  @override
  _DiscussionsPageState createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage> {
  late TextEditingController searchController;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late bool loading;
  late List<DiscussionPost?> posts;

  @override
  void initState() {
    super.initState();
    posts = [];
    checkPermissions();
    widget.server.setUser(widget.user);
    widget.server.setupNotifications(widget.user!.uid);
    getPosts();
  }

  checkPermissions() async {
    var status = await Permission.camera.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.camera.request();
      if (status == PermissionStatus.denied) {
        exit(0);
      }
    }
    status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.storage.request();
      if (status == PermissionStatus.denied) {
        exit(0);
      }
    }
    status = await Permission.notification.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.notification.request();
      if (status == PermissionStatus.denied) {
        exit(0);
      }
    }
  }

  getPosts() async {
    setState(() {
      loading = true;
      posts = [];
    });
    final res = await widget.server.getFirstDiscussionPosts();
    setState(() {
      posts = res;
      loading = false;
    });
  }

  loadMore() async {
    final res = await widget.server.getNextDiscussionPosts();
    setState(() {
      posts += res;
      loading = false;
    });
  }

  willPop() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Exit app?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("No")),
              TextButton(onPressed: () => exit(0), child: Text("Yes"))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () => willPop(),
        child: DecoratedBox(
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/bg1.jpg"), fit: BoxFit.cover)),
          child: Scaffold(
              backgroundColor: Colors.white.withOpacity(0.8),
              key: scaffoldKey,
              drawer: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(150),
                  topRight: Radius.circular(150),
                ),
                child: SizedBox(
                  child: Drawer(
                      child:
                          MyDrawer(user: widget.user, server: widget.server)),
                ),
              ),
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
                  child: Icon(Icons.post_add_outlined),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AddDiscussionPost(
                          user: widget.user, server: widget.server))),
                ),
              ),
              body: Container(
                  child: Column(
                children: [
                  CustomAppBar(
                      scaffoldKey: scaffoldKey,
                      user: widget.user,
                      server: widget.server,
                      title: "Discussions"),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => SearchDiscussion(
                                    server: widget.server,
                                    user: widget.user!))),
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
                                  Text("Search Discussions",
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13)),
                                  Expanded(child: Container()),
                                  Icon(Icons.search_rounded,
                                      color: Colors.grey[600])
                                ],
                              ),
                            ))),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20, left: 20, right: 20),
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
                              : RefreshIndicator(
                                  onRefresh: () => getPosts(),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: posts.length,
                                    itemBuilder: (context, index) =>
                                        DiscussionPostUI(
                                            post: posts[index],
                                            server: widget.server,
                                            user: widget.user,
                                            onTapEnabled: true),
                                  ),
                                ),
                    ),
                  ),
                  if (posts.length == 5)
                    MaterialButton(
                        onPressed: loadMore,
                        child: Icon(CupertinoIcons.hand_draw,
                            color: Color(0xff77ACF1), size: 23.0))
                ],
              ))),
        ),
      ),
    );
  }
}

bool ifLiked = false;
bool ifDisliked = false;

class DiscussionPostUI extends StatefulWidget {
  final DiscussionPost? post;
  final CustomUser? user;
  final Server server;
  final bool onTapEnabled;
  DiscussionPostUI(
      {required this.post,
      required this.server,
      required this.user,
      required this.onTapEnabled});
  @override
  _DiscussionPostUIState createState() => _DiscussionPostUIState();
}

class _DiscussionPostUIState extends State<DiscussionPostUI> {
  late bool liked;
  late bool disliked;
  late String reports;
  late int _reports;
  CustomUser? user;
  @override
  void initState() {
    getPostingUser();
    liked = widget.post!.likedBy!.contains(widget.user!.uid);
    disliked = widget.post!.dislikedBy!.contains(widget.user!.uid);
    reports = widget.post!.reports!;
    super.initState();
  }

  gotoprofile() async {
    if (widget.post!.uid == widget.user!.uid) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              ProfilePage(user: widget.user, server: widget.server)));
    } else {
      final target = await widget.server.getUserById(widget.post!.uid);
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ViewProfile(
              user: widget.user, target: target, server: widget.server)));
    }
  }

  getPostingUser() async {
    final res = await widget.server.getUserById(widget.post!.uid);
    setState(() {
      user = res;
    });
  }

  deleteDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Delete Post?"),
            content:
                Text("Discussion once deleted cannot be retrieved.\nContinue?"),
            actions: [
              MaterialButton(onPressed: deletePost, child: Text("Yes")),
              MaterialButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("No")),
            ],
          );
        });
  }

  deletePost() async {
    await widget.server.deleteDiscussionPost(widget.post!);
    Navigator.of(context).pop();
  }

  editPost() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => EditPost(
            server: widget.server, user: widget.user!, post: widget.post!)));
  }

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: widget.server.streamDiscussion(widget.post!.id),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final post = DiscussionPost.fromJson(snapshot.data);
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: GestureDetector(
                  onTap: widget.onTapEnabled
                      ? () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ViewPost(
                              post: post,
                              user: widget.user,
                              server: widget.server)))
                      : null,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    elevation: 2.0,
                    child: Center(
                      child: Container(
                          margin: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: gotoprofile,
                                    child: Row(
                                      children: [
                                        CustomAvatar(
                                            user: user!,
                                            server: widget.server,
                                            radius: 25),
                                        SizedBox(width: 20),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                "Dipsite " +
                                                    user!.passOutYear
                                                        .toString(),
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xff6A6A6A))),
                                            if (post.designation != "")
                                              Text(post.designation.toString(),
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Color(0xff6A6A6A))),
                                            Text(
                                                Utils.getDate(post.timestamp!) +
                                                    "   " +
                                                    Utils.getOnlyTime(
                                                        post.timestamp!),
                                                style: TextStyle(
                                                    fontSize: 9,
                                                    color: Color(0xff6A6A6A)))
                                          ],
                                        ),
                                        SizedBox(width: 60.0),
                                        Container(
                                          height: 30,
                                          width: 83,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Color(0xff3EDBF0),
                                                  Color(0xff77ACF1)
                                                ]),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(20.0),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(post.name.toString(),
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w400)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Expanded(child: Container()),
                                  // if (widget.user!.type == "admin")
                                  //   IconButton(
                                  //     icon: Icon(Icons.delete_outline),
                                  //     onPressed: deleteDialog,
                                  //   ),
                                  // if (post.uid == widget.user!.uid) SizedBox(),
                                  // IconButton(
                                  //   icon: Icon(Icons.edit),
                                  //   onPressed: editPost,
                                  // )
                                ],
                              ),

                              post.text != null && post.text != ""
                                  ? Padding(
                                      padding: EdgeInsets.only(
                                          top: 22, bottom: 6, left: 5),
                                      child: RichText(
                                        text: TextSpan(
                                            style: TextStyle(
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                                fontSize: 15,
                                                fontFamily: 'Mulish'),
                                            children: post.parseText()),
                                      ))
                                  : Container(height: 0),
                              post.media == null
                                  ? Container(height: 0)
                                  : Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: CachedNetworkImage(
                                            imageUrl: post.media!,
                                            progressIndicatorBuilder:
                                                (context, name, progress) {
                                              return Container(
                                                  height: 100,
                                                  width: 100,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Color(
                                                                  0xffA259FF)),
                                                      value: progress.progress,
                                                    ),
                                                  ));
                                            },
                                          ))),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    LikeWidget(
                                        liked: liked,
                                        server: widget.server,
                                        post: post,
                                        user: widget.user!),
                                    // SizedBox(width: 5),
                                    Padding(
                                      padding: EdgeInsets.only(left: 7),
                                      child: GestureDetector(
                                        onTap: null,
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          child: Icon(
                                              CupertinoIcons.chat_bubble_2,
                                              color: Color(0xff77ACF1)),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 7),
                                    DisLikeWidget(
                                        disliked: disliked,
                                        server: widget.server,
                                        user: widget.user!,
                                        post: post),
                                    // SizedBox(width: 2),
                                    if (post.commentCount > 0)
                                      Text(Utils.parseCount(post.commentCount),
                                          style: TextStyle(
                                              color: Color(0xffA6A6A6),
                                              fontWeight: FontWeight.w500)),
                                    Flexible(
                                      child: Container(),
                                    ),

                                    widget.user!.type == "admin"
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.cancel_outlined,
                                              color: Color(0xff77ACF1),
                                              size: 20,
                                            ),
                                            onPressed: () async {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title:
                                                          Text("Remove Post?"),
                                                      content: Text(
                                                          "Are You Sure You Want To Remove This Post?"),
                                                      actions: [
                                                        MaterialButton(
                                                            onPressed: () {
                                                              widget.server
                                                                  .deleteDiscussionPost(
                                                                      widget
                                                                          .post!);
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      SnackBar(
                                                                          content:
                                                                              Text("Post Removed")));
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: Text("Yes")),
                                                        MaterialButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(),
                                                            child: Text("No")),
                                                      ],
                                                    );
                                                  });
                                              //                                        await FirebaseFirestore.instance
                                              // .collection("users")
                                              // .doc(widget.user!.uid)
                                              // .update({"blocked": international.toString()});
                                            },
                                          )
                                        : SizedBox(),
                                    SizedBox(width: 2.5),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text("Report Post?"),
                                                content: Text(
                                                    "Are You Sure You Want To Report This Post?"),
                                                actions: [
                                                  MaterialButton(
                                                      onPressed: () {
                                                        if (post.reports ==
                                                            "3") {
                                                          widget.server
                                                              .deleteDiscussionPost(
                                                                  widget.post!);
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(SnackBar(
                                                                  content: Text(
                                                                      "Post deleted")));
                                                          Navigator.of(context)
                                                              .pop();
                                                        } else {
                                                          setState(() {
                                                            _reports =
                                                                int.parse(
                                                                    "$reports");
                                                            print("_reports: " +
                                                                _reports
                                                                    .toString());
                                                            _reports++;
                                                            reports = _reports
                                                                .toString();
                                                          });
                                                          widget.server
                                                              .updatereportsfield(
                                                                  widget.post!,
                                                                  reports
                                                                      .toString());
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(SnackBar(
                                                                  content: Text(
                                                                      "Post report: $reports")));
                                                          // widget.server
                                                          //     .updatereportsDiscussionPost(
                                                          //   widget.post!,
                                                          //   widget.post!.reports
                                                          //       .toString(),
                                                          // );
                                                        }

                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text("Yes")),
                                                  MaterialButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                      child: Text("No")),
                                                ],
                                              );
                                            });
                                      },
                                      child: Icon(
                                        CupertinoIcons.exclamationmark_circle,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 7),
                                  ],
                                ),
                              ),
                              // Divider(height: 30)
                            ],
                          )),
                    ),
                  ),
                ),
              );
            } else {
              return Container(height: 0);
            }
          });
    } else {
      return Container(height: 0);
    }
  }

  // reportsDialog() {
  //   showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: Text("Report Post?"),
  //           content:
  //               Text("Are You Sure You Want To Report This Post? \nContinue?"),
  //           actions: [
  //             MaterialButton(
  //                 onPressed: () async {
  //                   setState(() {
  //                     reports = reports++;
  //                   });
  //                   if (reports == 3) {
  //                     deletereportedPost();
  //                   }
  //                   await widget.server.updatereportsDiscussionPost(
  //                       widget.post!,
  //                       DiscussionPost(reports: reports.toString()));
  //                 },
  //                 child: Text("Yes")),
  //             MaterialButton(
  //                 onPressed: () => Navigator.of(context).pop(),
  //                 child: Text("No")),
  //           ],
  //         );
  //       });
  // }

  deletereportedPost() async {
    await widget.server.deleteDiscussionPost(widget.post!);
    Navigator.of(context).pop();
  }
}

// reportDialog(BuildContext context) {
//   // set up the button
//   Widget okButton = TextButton(
//     child: Text("Report"),
//     onPressed: () async{
//       setState(() {
//         reports++;

//       });
//        DiscussionPost post = DiscussionPost(
//       name: widget.user!.firstName.toString() +
//           " " +
//           widget.user!.lastName.toString(),
//       reports: reports.toString());
//   final res = await widget.server.updateReports(post);
//   if (res.code == DbResponseCode.success) {

// ScaffoldMessenger.of(context)
//     .showSnackBar(SnackBar(content: Text("Post uploaded")));
//     Navigator.of(context).pop();
//   } else {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text("Post upload failed :(")));

//   }

//     },
//   );

//   // set up the AlertDialog
//   AlertDialog alert = AlertDialog(
//     title: Center(child: Text("Report Post")),
//     content: Center(child: Text("Are You Sure You Want To \nReport Post?")),
//     actions: [
//       PrimaryButton(
//           text: "Yes",
//           onTap: () {
//             Navigator.of(context).pop();
//           },
//           padding: EdgeInsets.only(top: 20, bottom: 20)),
//     ],
//   );

// show the dialog
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return alert;
//       },
//     );
//   }
// }

class AddDiscussionPost extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  AddDiscussionPost({required this.user, required this.server});
  @override
  _AddDiscussionPostState createState() => _AddDiscussionPostState();
}

class _AddDiscussionPostState extends State<AddDiscussionPost> {
  File? uploadFile;
  late TextEditingController textEditingController;
  late bool error, loading;
  late int reports = 0;

  @override
  initState() {
    super.initState();
    textEditingController = TextEditingController();

    error = false;
    loading = false;
  }

  Future pickImage() async {
    await ImagePicker().getImage(source: ImageSource.gallery).then((img) async {
      File? croppedImage = await ImageCropper.cropImage(sourcePath: img!.path);
      if (croppedImage != null) {
        setState(() {
          uploadFile = croppedImage;
        });
      }
    });
  }

  Future captureImage() async {
    await ImagePicker().getImage(source: ImageSource.camera).then((img) async {
      File? croppedImage = await ImageCropper.cropImage(sourcePath: img!.path);
      if (croppedImage != null) {
        setState(() {
          uploadFile = croppedImage;
        });
      }
    });
  }

  post() async {
    setState(() {
      loading = true;
    });
    DiscussionPost post = DiscussionPost(
        name: widget.user!.firstName.toString() +
            " " +
            widget.user!.lastName.toString(),
        designation: widget.user!.jobProfile,
        uid: widget.user!.uid,
        reports: reports.toString(),
        text: textEditingController.value.text.trim(),
        timestamp: DateTime.now(),
        organization: widget.user!.collegeName,
        likedBy: [],
        dislikedBy: []);
    final res = await widget.server.addDiscussionPost(post, uploadFile);
    if (res.code == DbResponseCode.success) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Post uploaded")));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Post upload failed :(")));
      setState(() {
        error = true;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.chevron_left_rounded, size: 28))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Text("Start a Discussion",
                      style: TextStyle(fontSize: 20))),
              uploadFile == null
                  ? Container(height: 0)
                  : Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 60),
                      child: Container(child: Image.file(uploadFile!))),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: InputField(
                      error: false,
                      hint: "Write Something",
                      obscureText: false,
                      maxLines: 6,
                      controller: textEditingController)),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: captureImage,
                        child:
                            Icon(Icons.camera_alt_sharp, color: Colors.black38),
                      ),
                      SizedBox(width: 20),
                      GestureDetector(
                        onTap: pickImage,
                        child: Icon(Icons.collections_sharp,
                            color: Colors.black38),
                      ),
                      Expanded(child: Container()),
                      PrimaryButton(text: "Post", onTap: post, width: 70)
                    ],
                  )),
              error
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 150),
                      child: Center(
                          child: Column(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(height: 10),
                          Text("Upload failed. Please try again...",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.redAccent)),
                        ],
                      )))
                  : Container(height: 0)
            ],
          ),
        ),
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

class ViewPost extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  DiscussionPost? post;
  final bool fromNotifs;
  final String? notifId;
  ViewPost(
      {required this.post,
      required this.user,
      required this.server,
      this.fromNotifs = false,
      this.notifId});
  @override
  _ViewPostState createState() => _ViewPostState();
}

class _ViewPostState extends State<ViewPost> {
  late TextEditingController commentController;
  late List<DiscussionComment> comments;
  @override
  void initState() {
    super.initState();
    notifSeen();
    comments = List.empty(growable: true);
    commentController = TextEditingController();
    getComments();
  }

  notifSeen() {
    if (widget.fromNotifs) {
      widget.server.notificationSeen(widget.user!.uid, widget.notifId);
    }
  }

  getComments() async {
    final res = await widget.server.getComments(widget.post!.id.toString());
    if (res.isNotEmpty) {
      setState(() {
        comments.addAll(res);
      });
    }
  }

  addComment() async {
    if (commentController.value.text != "") {
      final comment = DiscussionComment(
          commentUid: widget.user!.uid,
          commentBy: widget.user!.firstName.toString() +
              " " +
              widget.user!.lastName.toString(),
          commentText: commentController.value.text,
          timestamp: DateTime.now());
      await widget.server.addComment(widget.post!, comment).then((val) {
        setState(() {
          commentController.clear();
          comments.add(comment);
        });
      }).onError((error, stackTrace) {
        print("[ERROR ViewPost.addComment] ${error.toString()}");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to comment :(")));
      });
    }
  }

  Future<void> onRefresh() async {
    final r = await widget.server.getPost(widget.post!.id);
    setState(() {
      widget.post = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: Container(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.chevron_left_rounded, size: 28))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DiscussionPostUI(
                    post: widget.post,
                    server: widget.server,
                    user: widget.user,
                    onTapEnabled: false),
              ),
              Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: InputField(
                          error: false,
                          hint: "Leave a comment",
                          controller: commentController,
                        ),
                      ),
                      PrimaryButton(text: "Post", onTap: addComment, width: 50)
                    ],
                  )),
              SizedBox(height: 15),
              RefreshIndicator(
                  onRefresh: () async => getComments(),
                  child: comments.length == 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 40, horizontal: 20),
                          child:
                              Center(child: Text("Be the first to comment :)")))
                      : ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          reverse: true,
                          itemCount: comments.length,
                          itemBuilder: (context, index) => CommentUI(
                              postId: widget.post!.id.toString(),
                              comment: comments[index],
                              server: widget.server,
                              user: widget.user)))
            ],
          ),
        ),
      ),
    )));
  }
}

class CommentUI extends StatefulWidget {
  final String postId;
  final DiscussionComment comment;
  final CustomUser? user;
  final Server server;
  CommentUI(
      {required this.postId,
      required this.comment,
      required this.user,
      required this.server});
  @override
  CommentUIState createState() => CommentUIState();
}

class CommentUIState extends State<CommentUI> {
  late bool liked;

  @override
  initState() {
    super.initState();
    liked = widget.comment.likedBy!.contains(widget.user!.uid);
  }

  toggleLike() {
    final likedtemp = liked;
    setState(() {
      liked = !liked;
    });
    if (!likedtemp) {
      widget.server
          .likeComment(
              widget.postId, widget.comment, widget.user!.uid.toString())
          .then((val) {
        setState(() {
          liked = val;
          widget.comment.likedBy!.add(widget.user!.uid!);
        });
      });
    } else {
      widget.server
          .dislikeComment(widget.postId, widget.comment.commentId.toString(),
              widget.user!.uid.toString())
          .then((val) {
        setState(() {
          liked = !val;
          widget.comment.likedBy!.remove(widget.user!.uid!);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 35, vertical: 7),
      child: Container(
          decoration: BoxDecoration(
              color: Color(0xffF0F0F0),
              borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.comment.commentBy.toString()),
                    SizedBox(width: 10),
                    Text(Utils.getTime(widget.comment.timestamp),
                        style:
                            TextStyle(fontSize: 11, color: Color(0xff949494))),
                  ],
                ),
                SizedBox(height: 6),
                Text(widget.comment.commentText.toString()),
                SizedBox(height: 15),
                Row(
                  children: [
                    GestureDetector(
                        onTap: toggleLike,
                        child: liked
                            ? Icon(Icons.favorite_sharp,
                                color: Colors.red, size: 17)
                            : Icon(Icons.favorite_border,
                                color: Color(0xffA6A6A6), size: 17)),
                    SizedBox(width: 8),
                    widget.comment.likedBy!.length > 0
                        ? Text(Utils.parseCount(widget.comment.likedBy!.length),
                            style: TextStyle(color: Color(0xff909090)))
                        : Container(width: 0)
                  ],
                )
              ],
            ),
          )),
    );
  }
}

class SearchDiscussion extends StatefulWidget {
  final Server server;
  final CustomUser user;
  SearchDiscussion({required this.server, required this.user});
  @override
  _SearchDiscussionState createState() => _SearchDiscussionState();
}

class _SearchDiscussionState extends State<SearchDiscussion> {
  late TextEditingController searchController;
  late List<DiscussionPost> searchResults;
  FocusNode searchNode = FocusNode();
  @override
  void initState() {
    searchController = TextEditingController();
    searchResults = List.empty(growable: true);
    searchNode.requestFocus();
    super.initState();
  }

  search() async {
    setState(() {
      searchResults = [];
    });
    if (searchController.value.text.trim() != "") {
      final res =
          await widget.server.searchPost(searchController.value.text.trim());
      if (res.isNotEmpty) {
        setState(() {
          searchResults = res;
        });
      }
    }
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
          hint: "Search Discussions",
          focusNode: searchNode,
          controller: searchController,
          suffixIcon: Icon(Icons.search, color: Color(0xffa4a4a4)),
          onChanged: (q) => search(),
        ),
      ),
      SizedBox(height: 20),
      Expanded(
          child: searchController.value.text == ""
              ? Container(height: 0)
              : searchResults.length > 0
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) => DiscussionPostUI(
                              post: searchResults[index],
                              server: widget.server,
                              user: widget.user,
                              onTapEnabled: true)),
                    )
                  : Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: Text("No Results"))))
    ])));
  }
}

// ignore: must_be_immutable
class LikeWidget extends StatefulWidget {
  bool liked;
  final Server server;
  final CustomUser user;
  final DiscussionPost post;
  double? size;
  LikeWidget(
      {required this.liked,
      required this.server,
      required this.user,
      required this.post,
      this.size});
  @override
  _LikeWidgetState createState() => _LikeWidgetState();
}

class _LikeWidgetState extends State<LikeWidget> {
  like() async {
    FirebaseFirestore.instance
        .collection("discussionPosts")
        .doc(widget.post.id.toString())
        .update({"isLiked": true});
    await widget.server.likePost(widget.post, widget.user);
    setState(() {
      widget.post.likedBy!.add(widget.user.uid!);
    });
    // }
  }

  disLike() async {
    FirebaseFirestore.instance
        .collection("discussionPosts")
        .doc(widget.post.id.toString())
        .update({"isLiked": false});
    widget.server
        .removeFromArrayField(
            collectionName: "discussionPosts",
            docId: widget.post.id.toString(),
            fieldName: "likedBy",
            object: widget.user.uid)
        .then((val) {
      setState(() {
        widget.post.likedBy!.remove(widget.user.uid!);
        widget.liked = !val;
      });
    });

    // }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DiscussionPost?>(
        stream: widget.server.getPost(widget.post.id).asStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.likedBy!.contains(widget.user.uid)) {
              return Row(
                children: [
                  GestureDetector(
                      onTap: disLike,
                      child: Icon(CupertinoIcons.hand_thumbsup_fill,
                          color: Color(0xff77ACF1), size: widget.size ?? 23)),
                  SizedBox(width: 7),
                  if (snapshot.data!.likedBy!.length > 0)
                    Text(Utils.parseCount(snapshot.data!.likedBy!.length),
                        style: TextStyle(
                            color: Color(0xffA6A6A6),
                            fontWeight: FontWeight.w500)),
                ],
              );
            } else if (snapshot.data!.isliked == false &&
                snapshot.data!.isdisliked == true) {
              return Row(
                children: [
                  GestureDetector(
                      onTap: () {},
                      child: Icon(CupertinoIcons.hand_thumbsup,
                          color: Color(0xff77ACF1), size: widget.size ?? 20)),
                  SizedBox(width: 7),
                  if (snapshot.data!.likedBy!.length > 0)
                    Text(Utils.parseCount(snapshot.data!.likedBy!.length),
                        style: TextStyle(
                            color: Color(0xffA6A6A6),
                            fontWeight: FontWeight.w500)),
                ],
              );
            } else if (snapshot.data!.isdisliked == true) {
              return Row(
                children: [
                  GestureDetector(
                      onTap: () {
                        // if (snapshot.data!.isliked == false) {
                        //   like();
                        // }
                      },
                      child: Icon(CupertinoIcons.hand_thumbsup,
                          color: Color(0xff77ACF1), size: widget.size ?? 20)),
                  SizedBox(width: 7),
                  if (snapshot.data!.likedBy!.length > 0)
                    Text(Utils.parseCount(snapshot.data!.likedBy!.length),
                        style: TextStyle(
                            color: Color(0xffA6A6A6),
                            fontWeight: FontWeight.w500)),
                ],
              );
            } else {
              return Row(
                children: [
                  GestureDetector(
                      onTap: like,
                      child: Icon(CupertinoIcons.hand_thumbsup,
                          color: Color(0xff77ACF1), size: widget.size ?? 20)),
                  SizedBox(width: 7),
                  if (snapshot.data!.likedBy!.length > 0)
                    Text(Utils.parseCount(snapshot.data!.likedBy!.length),
                        style: TextStyle(
                            color: Color(0xffA6A6A6),
                            fontWeight: FontWeight.w500)),
                ],
              );
            }
          } else {
            return Container(width: 0);
          }
        });
  }
}

class DisLikeWidget extends StatefulWidget {
  bool disliked;
  final Server server;
  final CustomUser user;
  final DiscussionPost post;
  double? size;
  DisLikeWidget(
      {required this.disliked,
      required this.server,
      required this.user,
      required this.post,
      this.size});
  @override
  _DisLikeWidgetState createState() => _DisLikeWidgetState();
}

class _DisLikeWidgetState extends State<DisLikeWidget> {
  like() async {
    FirebaseFirestore.instance
        .collection("discussionPosts")
        .doc(widget.post.id.toString())
        .update({"isDisliked": true});
    await widget.server.dislikePost(widget.post, widget.user);
    setState(() {
      widget.post.dislikedBy!.add(widget.user.uid!);
    });
  }

  disLike() async {
    await FirebaseFirestore.instance
        .collection("discussionPosts")
        .doc(widget.post.id.toString())
        .update({"isDisliked": false});

    widget.server
        .removeFromArrayField(
            collectionName: "discussionPosts",
            docId: widget.post.id.toString(),
            fieldName: "dislikedBy",
            object: widget.user.uid)
        .then((val) {
      setState(() {
        widget.post.dislikedBy!.remove(widget.user.uid!);
        widget.disliked = !val;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DiscussionPost?>(
        stream: widget.server.getPost(widget.post.id).asStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.dislikedBy!.contains(widget.user.uid)) {
              return Row(
                children: [
                  GestureDetector(
                      onTap: disLike,
                      child: Icon(CupertinoIcons.hand_thumbsdown_fill,
                          color: Color(0xff77ACF1), size: widget.size ?? 23)),
                  SizedBox(width: 7),
                  if (snapshot.data!.dislikedBy!.length > 0)
                    Text(Utils.parseCount(snapshot.data!.dislikedBy!.length),
                        style: TextStyle(
                            color: Color(0xffA6A6A6),
                            fontWeight: FontWeight.w500)),
                ],
              );
            } else if (snapshot.data!.isliked == true &&
                snapshot.data!.isdisliked == false) {
              return Row(
                children: [
                  GestureDetector(
                      onTap: () {
                        // if (snapshot.data!.isdisliked == true) {
                        //   like();
                        // } else {}
                      },
                      child: Icon(CupertinoIcons.hand_thumbsdown,
                          color: Color(0xff77ACF1), size: widget.size ?? 20)),
                  SizedBox(width: 7),
                  if (snapshot.data!.dislikedBy!.length > 0)
                    Text(Utils.parseCount(snapshot.data!.dislikedBy!.length),
                        style: TextStyle(
                            color: Color(0xffA6A6A6),
                            fontWeight: FontWeight.w500)),
                ],
              );
            } else if (snapshot.data!.isliked == true) {
              return Row(
                children: [
                  GestureDetector(
                      onTap: () {},
                      child: Icon(CupertinoIcons.hand_thumbsdown,
                          color: Color(0xff77ACF1), size: widget.size ?? 20)),
                  SizedBox(width: 7),
                  if (snapshot.data!.dislikedBy!.length > 0)
                    Text(Utils.parseCount(snapshot.data!.dislikedBy!.length),
                        style: TextStyle(
                            color: Color(0xffA6A6A6),
                            fontWeight: FontWeight.w500)),
                ],
              );
            } else {
              return Row(
                children: [
                  GestureDetector(
                      onTap: like,
                      child: Icon(CupertinoIcons.hand_thumbsdown,
                          color: Color(0xff77ACF1), size: widget.size ?? 20)),
                  SizedBox(width: 7),
                  if (snapshot.data!.dislikedBy!.length > 0)
                    Text(Utils.parseCount(snapshot.data!.dislikedBy!.length),
                        style: TextStyle(
                            color: Color(0xffA6A6A6),
                            fontWeight: FontWeight.w500)),
                ],
              );
            }
          } else {
            return Container(width: 0);
          }
        });
  }
}

class EditPost extends StatefulWidget {
  final Server server;
  final CustomUser user;
  final DiscussionPost post;
  EditPost({required this.server, required this.user, required this.post});
  @override
  _EditPostState createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  late TextEditingController textController;
  File? uploadFile;
  bool loading = false;
  bool error = false;
  CachedNetworkImage? image;
  @override
  initState() {
    super.initState();
    textController = TextEditingController(text: widget.post.text);
    image = widget.post.media != null
        ? CachedNetworkImage(
            imageUrl: widget.post.media!,
            progressIndicatorBuilder: (context, name, progress) {
              return Container(
                  height: 100,
                  width: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
                      value: progress.progress,
                    ),
                  ));
            },
          )
        : null;
  }

  Future pickImage() async {
    await ImagePicker().getImage(source: ImageSource.gallery).then((img) async {
      File? croppedImage = await ImageCropper.cropImage(sourcePath: img!.path);
      if (croppedImage != null) {
        setState(() {
          uploadFile = croppedImage;
        });
      }
    });
  }

  Future captureImage() async {
    await ImagePicker().getImage(source: ImageSource.camera).then((img) async {
      File? croppedImage = await ImageCropper.cropImage(sourcePath: img!.path);
      if (croppedImage != null) {
        setState(() {
          uploadFile = croppedImage;
        });
      }
    });
  }

  post() async {
    setState(() {
      loading = true;
    });
    var post = widget.post;
    post.text = textController.value.text.trim();
    await widget.server.updatePost(post, uploadFile);
    setState(() {
      loading = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.chevron_left_rounded, size: 28))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child:
                      Text("Edit Discussion", style: TextStyle(fontSize: 20))),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: uploadFile != null
                      ? Image.file(uploadFile!)
                      : image != null
                          ? image
                          : Container(height: 0)),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: InputField(
                      error: false,
                      hint: "Write Something",
                      obscureText: false,
                      maxLines: 6,
                      controller: textController)),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: captureImage,
                        child:
                            Icon(Icons.camera_alt_sharp, color: Colors.black38),
                      ),
                      SizedBox(width: 20),
                      GestureDetector(
                        onTap: pickImage,
                        child: Icon(Icons.collections_sharp,
                            color: Colors.black38),
                      ),
                      Expanded(child: Container()),
                      PrimaryButton(text: "Update", onTap: post, width: 70)
                    ],
                  )),
              error
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 150),
                      child: Center(
                          child: Column(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(height: 10),
                          Text("Upload failed. Please try again...",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.redAccent)),
                        ],
                      )))
                  : Container(height: 0)
            ],
          ),
        ),
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
