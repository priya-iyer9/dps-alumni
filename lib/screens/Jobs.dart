import 'dart:io';
import 'dart:typed_data';
import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/JobPost.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/Service/Utils.dart';
import 'package:alumniapp/screens/ProfilePage.dart';
import 'package:alumniapp/ui/AppBar.dart';
import 'package:alumniapp/ui/Drawer.dart';
import 'package:alumniapp/ui/InputField.dart';
import 'package:alumniapp/ui/actionbuttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class JobScreen extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  JobScreen({required this.user, required this.server});
  @override
  _JobScreenState createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late List<JobPost?> posts;
  bool loading = false;

  @override
  initState() {
    posts = [];
    getPosts();
    super.initState();
  }

  postJob() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          PostJobScreen(user: widget.user, server: widget.server),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              animation.drive(Tween(begin: Offset(0, 1), end: Offset.zero)),
          child: child,
        );
      },
    ));
  }

  getPosts() async {
    setState(() {
      loading = true;
      posts = [];
    });
    final res = await widget.server.getFirstJobPosts();
    setState(() {
      posts = res;
      loading = false;
    });
  }

  loadMore() async {
    final res = await widget.server.getNextJobPosts();
    setState(() {
      posts = res;
    });
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
          drawer:
             ClipRRect(
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
          floatingActionButton: FloatingActionButton(
            backgroundColor: Color(0xffA259FF),
            child: Icon(Icons.add),
            onPressed: postJob,
          ),
          body: Container(
              child: Column(children: [
            CustomAppBar(
                scaffoldKey: scaffoldKey,
                user: widget.user,
                server: widget.server,
                title: "Jobs/Internships"),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Hero(
                tag: "searchbar",
                child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SearchJobs(
                            user: widget.user, server: widget.server))),
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
                              Text("Search Jobs",
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13)),
                              Expanded(child: Container()),
                              Icon(
                                Icons.search_rounded,
                                color: Colors.grey[600],
                              )
                            ],
                          ),
                        ))),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 5),
                child: loading
                    ? Center(
                        child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
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
                              physics: BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              shrinkWrap: true,
                              itemCount: posts.length,
                              itemBuilder: (context, index) => JobPostTile(
                                  job: posts[index]!,
                                  server: widget.server,
                                  user: widget.user),
                            ),
                          ),
              ),
            ),
            if (posts.length == 5)
              MaterialButton(onPressed: loadMore, child: Text("Load More"))
          ]))),
    ));
  }
}

class JobPostTile extends StatelessWidget {
  final JobPost job;
  final CustomUser? user;
  final Server server;
  JobPostTile({required this.job, required this.user, required this.server});

  details() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          JobDetailsScreen(job: job, user: user, server: server),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              animation.drive(Tween(begin: Offset(0, 1), end: Offset.zero)),
          child: child,
        );
      },
    );
  }

  deleteDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Delete Post?"),
            content:
                Text("Job post once deleted cannot be retrieved.\nContinue?"),
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
    await server.deleteJobPost(job);
    Navigator.of(context).pop();
  }

  editPost(BuildContext context, JobPost j) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => EditJob(server: server, user: user!, job: j)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: server.streamJob(job.id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final j = JobPost.fromJson(snapshot.data);
            return Padding(
                padding: EdgeInsets.symmetric(vertical: 19),
                child: MaterialButton(
                  onPressed: () => Navigator.of(context).push(details()),
                  child: Row(
                    children: [
                      Container(
                          width: 70, height: 70, child: job.getImage(scale: 4)),
                      SizedBox(width: 30),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(j.role.toString(),
                                        style: TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis),
                                    Text(j.company.toString(),
                                        style: TextStyle(
                                            color: Color(0xff727272),
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                                Expanded(child: Container()),
                                if (j.postedBy == user!.uid ||
                                    user!.type == "admin")
                                  IconButton(
                                    icon: Icon(Icons.delete_outline),
                                    onPressed: () => deleteDialog(context),
                                  ),
                                if (j.postedBy == user!.uid)
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () => editPost(context, j),
                                  )
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Image.asset("assets/location_pin.png",
                                    scale: 2.2),
                                Text(j.location.toString(),
                                    style: TextStyle(
                                        color: Color(0xff727272), fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                                Expanded(child: Container()),
                                Text("₹ ${j.stipend}",
                                    style: TextStyle(
                                        color: Color(0xff727272), fontSize: 12),
                                    overflow: TextOverflow.ellipsis)
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ));
          } else {
            return Container(height: 0);
          }
        });
  }
}

class JobDetailsScreen extends StatefulWidget {
  final JobPost job;
  final CustomUser? user;
  final Server server;
  final bool fromNotifs;
  final String? notifId;
  JobDetailsScreen(
      {required this.job,
      required this.user,
      required this.server,
      this.fromNotifs = false,
      this.notifId});
  @override
  _JobDetailsScreenState createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late bool bookmarked, applied;
  CustomUser? postedBy;
  @override
  void initState() {
    bookmarked = false;
    applied = widget.job.applicants!.contains(widget.user!.uid);
    Utils.debugPrint(widget.job.applicants);
    notifSeen();
    getPostedBy();
    super.initState();
  }

  notifSeen() {
    if (widget.fromNotifs) {
      widget.server.notificationSeen(widget.user!.uid, widget.notifId);
    }
  }

  apply() async {
    if (!applied) {
      final res = await widget.server
          .applyToJob(widget.job, widget.user!.uid.toString());
      if (res.code == DbResponseCode.success) {
        setState(() {
          applied = true;
        });
        if (await canLaunch(widget.job.hireLink.toString())) {
          await launch(widget.job.hireLink.toString());
        }
      }
    }
  }

  getPostedBy() async {
    final res = await widget.server.getUserById(widget.job.postedBy);
    setState(() {
      postedBy = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: widget.server.streamJob(widget.job.id),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final job = JobPost.fromJson(snapshot.data);
                  return SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 50),
                              child: Container(
                                  width: 100,
                                  height: 100,
                                  child: job.getImage())),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 25, vertical: 10),
                          child: Text(job.role.toString(),
                              style: TextStyle(fontSize: 20)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          child: Text(job.company.toString(),
                              style: TextStyle(fontSize: 14)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          child: Text(job.location.toString(),
                              style: TextStyle(fontSize: 14)),
                        ),
                        Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 25, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Rs " + job.stipend.toString(),
                                    style: TextStyle(fontSize: 16)),
                                FilterCookie(
                                    text: job.type.toString(), selected: true)
                              ],
                            )),
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
                              job.applicationCount.toString() + " applications",
                              style: TextStyle(fontSize: 11)),
                        ),
                        SizedBox(height: 30),
                        Divider(height: 60),
                        Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: BulletedListWidget(
                                title: "Resposibilities",
                                items: job.parseResps())),
                        Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: BulletedListWidget(
                                title: "Qualifications",
                                items: job.parseQualifs())),
                        SizedBox(height: 60)
                      ],
                    ),
                  );
                } else {
                  return Center(child: Text(""));
                }
              }),
          Positioned(
            top: 0,
            left: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.chevron_left_rounded, size: 28)),
            ),
          ),
          Positioned(
              bottom: 3,
              left: 0,
              right: 0,
              child: Center(
                  child: !applied
                      ? PrimaryButton(
                          onTap: apply,
                          text: "Apply Now",
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
                              child: Text("Applied!",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500))))))
        ],
      )),
    );
  }
}

class BulletedListWidget extends StatelessWidget {
  final String title;
  final List items;
  BulletedListWidget({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child:
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600))),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Text("\u2022"),
                            ),
                            Expanded(child: Text(items[index])),
                          ],
                        ));
                  },
                )),
          ],
        ));
  }
}

class PostJobScreen extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  PostJobScreen({required this.user, required this.server});
  @override
  _PostJobScreenState createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  String? type;
  late bool titleError,
      nameError,
      respsError,
      qualifsError,
      typeError,
      hireLinkError,
      stipendStartError,
      locationError,
      loading;
  late TextEditingController titleController,
      nameController,
      respsController,
      qualifsController,
      hireLinkController,
      stipendStartController,
      stipendEndController,
      locationController;
  File? uploadFile;
  late FocusNode nameNode,
      salFromNode,
      salToNode,
      locationNode,
      respNode,
      qualifNode,
      linkNode;
  @override
  void initState() {
    super.initState();
    titleError = false;
    nameError = false;
    respsError = false;
    qualifsError = false;
    typeError = false;
    hireLinkError = false;
    stipendStartError = false;
    locationError = false;
    loading = false;
    titleController = TextEditingController();
    nameController = TextEditingController();
    respsController = TextEditingController();
    qualifsController = TextEditingController();
    hireLinkController = TextEditingController();
    stipendStartController = TextEditingController();
    stipendEndController = TextEditingController();
    locationController = TextEditingController();
    nameNode = FocusNode();
    salFromNode = FocusNode();
    salToNode = FocusNode();
    locationNode = FocusNode();
    respNode = FocusNode();
    qualifNode = FocusNode();
    linkNode = FocusNode();
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

  typeSelect(String? val) {
    setState(() {
      typeError = false;
      type = val!;
    });
  }

  postJob() async {
    setState(() {
      loading = true;
      titleError = titleController.value.text.trim() == "";
      nameError = nameController.value.text.trim() == "";
      typeError = type == null;
      respsError = respsController.value.text.trim() == "";
      qualifsError = qualifsController.value.text.trim() == "";
      stipendStartError = stipendStartController.value.text.trim() == "";
      locationError = locationController.value.text.trim() == "";
      hireLinkError = hireLinkController.value.text.trim() == "" ||
          Uri.tryParse(hireLinkController.value.text.trim())!.hasAbsolutePath;
    });
    final Uint8List? upload;
    upload = await uploadFile!.readAsBytes();
    final isError = titleError ||
        nameError ||
        typeError ||
        respsError ||
        qualifsError ||
        hireLinkError ||
        stipendStartError ||
        locationError;
    if (!isError) {
      final post = JobPost(
          company: nameController.value.text.trim(),
          role: titleController.value.text.trim(),
          logo: upload,
          stipend: stipendEndController.value.text.trim() != ""
              ? stipendStartController.value.text.trim() +
                  "-" +
                  stipendEndController.value.text.trim()
              : stipendStartController.value.text.trim(),
          type: type,
          location: locationController.value.text.trim(),
          resps: respsController.value.text.trim(),
          qualifs: qualifsController.value.text.trim(),
          organization: widget.user!.collegeName,
          applicationCount: 0,
          hireLink: hireLinkController.value.text.trim(),
          postedBy: widget.user!.uid);
      final res = await widget.server.addJobPost(post);
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
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50)),
                            width: 100,
                            height: 100,
                            child: uploadFile == null
                                ? Image.asset("assets/org-logo.png")
                                : Image.file(uploadFile!),
                          ),
                          Positioned(
                              bottom: 0,
                              right: 0,
                              child: Icon(Icons.camera_alt_sharp))
                        ],
                      ),
                    ),
                  )),
              SizedBox(height: 30),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Post Title",
                    controller: titleController,
                    error: titleError,
                    errorMessage: "Title is mandatory",
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(nameNode),
                    onChanged: (val) {
                      setState(() {
                        titleError = false;
                      });
                    },
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Company Name",
                    controller: nameController,
                    error: nameError,
                    errorMessage: "Please provide organization name.",
                    focusNode: nameNode,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(salFromNode),
                    onChanged: (val) {
                      setState(() {
                        nameError = false;
                      });
                    },
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: CustomDropDown(
                    items: [
                      "Internship",
                      "Entry Level",
                      "Associate",
                      "Mid-Senior Level",
                      "Director",
                      "Executive"
                    ],
                    onChanged: typeSelect,
                    text: type,
                    hint: "Job Type",
                    error: typeError,
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: Row(children: [
                    Expanded(
                      child: InputField(
                        hint: "Stipend/Salary from",
                        keyboardType: TextInputType.number,
                        controller: stipendStartController,
                        error: stipendStartError,
                        errorMessage: "Please provide value.",
                        focusNode: salFromNode,
                        onEditingComplete: () =>
                            FocusScope.of(context).requestFocus(salToNode),
                        onChanged: (val) {
                          setState(() {
                            stipendStartError = false;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: InputField(
                        hint: "Stipend/Salary to",
                        keyboardType: TextInputType.number,
                        controller: stipendEndController,
                        error: false,
                        errorMessage: "Please provide value.",
                        focusNode: salToNode,
                        onEditingComplete: () =>
                            FocusScope.of(context).requestFocus(locationNode),
                      ),
                    )
                  ])),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Location",
                    controller: locationController,
                    error: locationError,
                    errorMessage: "Location is mandatory",
                    focusNode: locationNode,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(respNode),
                    onChanged: (val) {
                      setState(() {
                        locationError = false;
                      });
                    },
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Responsibilities",
                    controller: respsController,
                    error: respsError,
                    keyboardType: TextInputType.multiline,
                    errorMessage: "Please enter responsibilities",
                    focusNode: respNode,
                    onChanged: (val) {
                      setState(() {
                        respsError = false;
                      });
                    },
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Qualifications",
                    textInputAction: TextInputAction.newline,
                    controller: qualifsController,
                    error: qualifsError,
                    keyboardType: TextInputType.multiline,
                    errorMessage: "Please enter qualifications required",
                    focusNode: qualifNode,
                    onChanged: (val) {
                      setState(() {
                        qualifsError = false;
                      });
                    },
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Link to hiring portal",
                    controller: hireLinkController,
                    error: hireLinkError,
                    errorMessage: "Please provide organization name.",
                    focusNode: linkNode,
                    onEditingComplete: () => FocusScope.of(context).unfocus(),
                    onChanged: (val) {
                      setState(() {
                        hireLinkError = false;
                      });
                    },
                  )),
              SizedBox(height: 10),
              Center(child: PrimaryButton(text: "Post", onTap: postJob))
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

class SearchJobs extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  SearchJobs({required this.user, required this.server});
  @override
  _SearchJobsState createState() => _SearchJobsState();
}

class _SearchJobsState extends State<SearchJobs> {
  late TextEditingController searchController;
  late List<JobPost> searchResults;
  late int selected;
  FocusNode searchNode = FocusNode();
  final fields = [
    {"name": "Company", "value": "company"},
    {"name": "Role", "value": "role"},
    {"name": "Job Type", "value": "type"}
  ];
  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchResults = List.empty(growable: true);
    selected = 0;
    searchNode.requestFocus();
  }

  search() async {
    setState(() {
      searchResults = [];
    });
    if (searchController.value.text != "") {
      final res = await widget.server
          .searchJobs(searchController.value.text, fields[selected]["value"]);
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
          hint: "Search Jobs/Internships",
          controller: searchController,
          suffixIcon: Icon(Icons.search, color: Color(0xffa4a4a4)),
          onChanged: (q) => search(),
          focusNode: searchNode,
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
                      itemBuilder: (context, index) => JobPostTile(
                          job: searchResults[index],
                          server: widget.server,
                          user: widget.user))
                  : Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: Text("No Results"))))
    ])));
  }
}

class EditJob extends StatefulWidget {
  final Server server;
  final CustomUser user;
  final JobPost job;
  EditJob({required this.server, required this.user, required this.job});
  @override
  _EditJobState createState() => _EditJobState();
}

class _EditJobState extends State<EditJob> {
  String? type;
  late bool titleError,
      nameError,
      respsError,
      qualifsError,
      typeError,
      hireLinkError,
      stipendStartError,
      locationError,
      loading;
  late TextEditingController titleController,
      nameController,
      respsController,
      qualifsController,
      hireLinkController,
      stipendStartController,
      stipendEndController,
      locationController;
  File? uploadFile;
  @override
  void initState() {
    super.initState();
    Utils.debugPrint(widget.job.id);
    titleError = false;
    nameError = false;
    respsError = false;
    qualifsError = false;
    typeError = false;
    hireLinkError = false;
    stipendStartError = false;
    locationError = false;
    loading = false;
    type = widget.job.type;
    titleController = TextEditingController(text: widget.job.role);
    nameController = TextEditingController(text: widget.job.company);
    respsController = TextEditingController(text: widget.job.resps);
    qualifsController = TextEditingController(text: widget.job.qualifs);
    hireLinkController = TextEditingController(text: widget.job.hireLink);
    stipendStartController =
        TextEditingController(text: widget.job.stipend!.split("-")[0]);
    stipendEndController = TextEditingController(
        text: widget.job.stipend!.split("-").length > 1
            ? widget.job.stipend!.split("-")[1]
            : "");
    locationController = TextEditingController(text: widget.job.location);
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

  typeSelect(String? val) {
    setState(() {
      type = val!;
    });
  }

  postJob() async {
    setState(() {
      loading = true;
    });
    Uint8List? upload;
    upload = uploadFile != null ? await uploadFile!.readAsBytes() : null;
    final isError = titleError ||
        nameError ||
        typeError ||
        respsError ||
        qualifsError ||
        hireLinkError ||
        stipendStartError ||
        locationError;
    var stipend = stipendStartController.value.text.trim();
    if (stipendEndController.value.text.trim() != "") {
      stipend += "-" + stipendEndController.value.text.trim();
    }
    if (!isError) {
      final post = JobPost(
          id: widget.job.id,
          company: nameController.value.text.trim(),
          role: titleController.value.text.trim(),
          logo: upload ?? widget.job.logo,
          stipend: stipend,
          type: type,
          location: locationController.value.text.trim(),
          resps: respsController.value.text.trim(),
          qualifs: qualifsController.value.text.trim(),
          organization: widget.user.collegeName,
          applicationCount: 0,
          hireLink: hireLinkController.value.text.trim(),
          postedBy: widget.user.uid);
      final res = await widget.server.updateJob(post);
      if (res.code == DbResponseCode.success) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Post updated")));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Post update failed :(")));
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
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50)),
                            width: 100,
                            height: 100,
                            child: uploadFile == null
                                ? widget.job.logo != null
                                    ? Image.memory(widget.job.logo!)
                                    : Image.asset("assets/org-logo.png")
                                : Image.file(uploadFile!),
                          ),
                          Positioned(
                              bottom: 0,
                              right: 0,
                              child: Icon(Icons.camera_alt_sharp))
                        ],
                      ),
                    ),
                  )),
              SizedBox(height: 30),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Post Title",
                    controller: titleController,
                    error: titleError,
                    errorMessage: "Title is mandatory",
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Company Name",
                    controller: nameController,
                    error: nameError,
                    errorMessage: "Please provide organization name.",
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: CustomDropDown(
                    items: [
                      "Internship",
                      "Entry Level",
                      "Associate",
                      "Mid-Senior Level",
                      "Director",
                      "Executive"
                    ],
                    onChanged: typeSelect,
                    text: type,
                    hint: "Job Type",
                    error: typeError,
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: Row(children: [
                    Expanded(
                      child: InputField(
                        hint: "Stipend/Salary from",
                        keyboardType: TextInputType.number,
                        controller: stipendStartController,
                        error: stipendStartError,
                        errorMessage: "Please provide value.",
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: InputField(
                        hint: "Stipend/Salary to",
                        keyboardType: TextInputType.number,
                        controller: stipendEndController,
                        error: false,
                        errorMessage: "Please provide value.",
                      ),
                    )
                  ])),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Location",
                    controller: locationController,
                    error: locationError,
                    errorMessage: "Location is mandatory",
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Responsibilities",
                    controller: respsController,
                    error: respsError,
                    keyboardType: TextInputType.multiline,
                    errorMessage: "Please enter responsibilities",
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Qualifications",
                    textInputAction: TextInputAction.newline,
                    controller: qualifsController,
                    error: qualifsError,
                    keyboardType: TextInputType.multiline,
                    errorMessage: "Please enter qualifications required",
                  )),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: InputField(
                    hint: "Link to hiring portal",
                    controller: hireLinkController,
                    error: hireLinkError,
                    errorMessage: "Please provide organization name.",
                    onEditingComplete: () => FocusScope.of(context).unfocus(),
                  )),
              SizedBox(height: 10),
              Center(child: PrimaryButton(text: "Update", onTap: postJob))
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
