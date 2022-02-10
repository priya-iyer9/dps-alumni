import 'dart:convert';
import 'dart:io';

import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/DiscussionPost.dart';
import 'package:alumniapp/Service/JobPost.dart';
import 'package:alumniapp/Service/LocalDatabase.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/Service/Utils.dart';
import 'package:alumniapp/screens/Events.dart';
import 'package:alumniapp/screens/Messaging.dart';
import 'package:alumniapp/ui/CustomAvatar.dart';
import 'package:alumniapp/ui/InputField.dart';
import 'package:alumniapp/ui/actionbuttons.dart';
import 'package:alumniapp/ui/countrycodepicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Jobs.dart';
import 'discussions.dart';

class ProfilePage extends StatefulWidget {
  CustomUser? user;
  final Server server;
  ProfilePage({required this.user, required this.server});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late List<dynamic> posts;
  int selected = 0;
  final fields = ["Discussions", "Jobs", "Events"];
  bool loading = false;
  ScrollController scrollController = ScrollController(keepScrollOffset: true);

  @override
  void initState() {
    posts = [];
    getUser();
    getPosts();
    super.initState();
  }

  getUser() async {
    final res = await widget.server.getUserById(widget.user!.uid);
    setState(() {
      widget.user = res;
    });
  }

  changeSelectedIndex(index) async {
    setState(() {
      selected = index;
      loading = true;
    });
    switch (index) {
      case 0:
        await getPosts();
        break;
      case 1:
        await getJobs();
        break;
      case 2:
        await getEvents();
        break;
      default:
        break;
    }
    setState(() {
      loading = false;
    });
  }

  getPosts() async {
    final res = await widget.server.getPostsByUser(widget.user!.uid);
    setState(() {
      posts = res;
    });
  }

  getJobs() async {
    final res = await widget.server.getJobsByUser(widget.user!.uid);
    setState(() {
      posts = res;
    });
  }

  getEvents() async {
    final res = await widget.server.getEventsByUser(widget.user!.uid);
    setState(() {
      posts = res;
    });
  }

  Future<void> updateUser() async {
    final u = await widget.server.getUserById(widget.user!.uid);
    setState(() {
      widget.user = u;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: RefreshIndicator(
        onRefresh: updateUser,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.chevron_left_rounded, size: 28))),
              SizedBox(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                                widget.user!.firstName.toString() +
                                    " " +
                                    widget.user!.lastName.toString(),
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500))),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(widget.user!.collegeName.toString(),
                                style: TextStyle(color: Color(0xff808080)))),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                                "Dipsite " +
                                    widget.user!.passOutYear.toString(),
                                style: TextStyle(color: Color(0xff808080)))),
                      ],
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: CustomAvatar(
                          user: widget.user!,
                          server: widget.server,
                          radius: 40))
                ],
              ),
              SizedBox(height: 10),
              PrimaryButton(
                  text: "Edit Profile",
                  filled: false,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => UpdateProfile(
                          user: widget.user!, server: widget.server)))),
              SizedBox(height: 30),
              UserInfoWidget(
                  title: "Phone No.", value: widget.user!.phone.toString()),
              UserInfoWidget(
                  title: "Email", value: widget.user!.email.toString()),
              UserInfoWidget(
                  title: "Roll No.", value: widget.user!.rollno.toString()),
              UserInfoWidget(
                  title: "Email", value: widget.user!.email.toString()),
              UserInfoWidget(
                  title: "Current Address",
                  value: widget.user!.currentAddress.toString()),
              UserInfoWidget(
                  title: "Current Address",
                  value: widget.user!.permanentAddress.toString()),
              UserInfoWidget(
                  title: "International Alumni",
                  value: widget.user!.isInternational.toString() == "true"
                      ? "Yes"
                      : "No"),
              if (widget.user!.jobProfile != null &&
                  widget.user!.jobProfile != "")
                UserInfoWidget(
                    title: "Job Profile",
                    value: widget.user!.jobProfile.toString()),
              if (widget.user!.currentCompany != null &&
                  widget.user!.currentCompany != "")
                UserInfoWidget(
                    title: "Organization",
                    value: widget.user!.currentCompany.toString()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child:
                    Divider(thickness: 1, height: 30, color: Color(0xffA259FF)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: () => changeSelectedIndex(index),
                          child: FilterCookie(
                              text: fields[index].toString(),
                              selected: index == selected),
                        ),
                      );
                    },
                  ),
                ),
              ),
              loading
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
                        ),
                      ),
                    )
                  : posts.length > 0
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: posts.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              if (posts[0] is DiscussionPost) {
                                return DiscussionPostUI(
                                    post: posts[index],
                                    server: widget.server,
                                    user: widget.user,
                                    onTapEnabled: true);
                              }
                              if (posts[0] is JobPost) {
                                return JobPostTile(
                                    job: posts[index],
                                    server: widget.server,
                                    user: widget.user);
                              }
                              return EventPostTile(
                                  event: posts[index],
                                  server: widget.server,
                                  user: widget.user);
                            },
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                              child: Text("No Posts",
                                  style: TextStyle(color: Color(0xff707070)))))
            ],
          ),
        ),
      )),
    );
  }
}

class ViewProfile extends StatefulWidget {
  final CustomUser? target, user;
  final Server server;
  ViewProfile({required this.user, required this.target, required this.server});

  @override
  _ViewProfileState createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  late List<dynamic> posts;
  bool loading = false;
  int selected = 0;
  final fields = ["Discussions", "Jobs", "Events"];
  @override
  void initState() {
    posts = [];
    getPosts();
    super.initState();
  }

  changeSelectedIndex(index) async {
    setState(() {
      selected = index;
      loading = true;
    });
    switch (index) {
      case 0:
        await getPosts();
        break;
      case 1:
        await getJobs();
        break;
      case 2:
        await getEvents();
        break;
      default:
        break;
    }
    setState(() {
      loading = false;
    });
  }

  getPosts() async {
    final res = await widget.server.getPostsByUser(widget.target!.uid);
    setState(() {
      posts = res;
    });
  }

  getJobs() async {
    final res = await widget.server.getJobsByUser(widget.target!.uid);
    setState(() {
      posts = res;
    });
  }

  getEvents() async {
    final res = await widget.server.getEventsByUser(widget.target!.uid);
    setState(() {
      posts = res;
    });
  }

  message() async {
    final cht = await widget.server
        .getChatBetweenUsers(widget.user!.uid, widget.target!.uid);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChatScreen(
            chat: cht,
            user: widget.user,
            server: widget.server,
            target: widget.target)));
  }

  launchUrl(int index) async {
    switch (index) {
      case 0:
        if (await canLaunch(widget.target!.fbAccount.toString())) {
          await launch(widget.target!.fbAccount.toString());
        }
        break;
      case 1:
        if (await canLaunch(widget.target!.linkedinAccount.toString())) {
          await launch(widget.target!.linkedinAccount.toString());
        }
        break;
      case 2:
        if (await canLaunch(widget.target!.instaAccount.toString())) {
          await launch(widget.target!.instaAccount.toString());
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: SingleChildScrollView(
      physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.chevron_left_rounded, size: 28))),
          SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                            widget.target!.firstName.toString() +
                                " " +
                                widget.target!.lastName.toString(),
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w500))),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(widget.target!.collegeName.toString(),
                            style: TextStyle(color: Color(0xff808080)))),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                            "Dipsite " + widget.target!.passOutYear.toString(),
                            style: TextStyle(color: Color(0xff808080)))),
                  ],
                ),
              ),
              Column(
                children: [
                  PrimaryButton(text: "Message", filled: false, onTap: message),
                  Row(
                    children: [
                      if (widget.target!.fbAccount != null &&
                          widget.target!.fbAccount != "")
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: GestureDetector(
                              onTap: () => launchUrl(0),
                              child: Image.asset('assets/facebook.png',
                                  scale: 21)),
                        ),
                      if (widget.target!.linkedinAccount != null &&
                          widget.target!.linkedinAccount != "")
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: GestureDetector(
                              onTap: () => launchUrl(1),
                              child: Image.asset('assets/linkedin.png',
                                  scale: 21)),
                        ),
                      if (widget.target!.instaAccount != null &&
                          widget.target!.instaAccount != "")
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: GestureDetector(
                              onTap: () => launchUrl(2),
                              child: Image.asset('assets/instagram.png',
                                  scale: 21)),
                        ),
                    ],
                  )
                ],
              )
            ],
          ),
          UserInfoWidget(
              title: "Roll No.", value: widget.target!.rollno.toString()),
          UserInfoWidget(
              title: "International Alumni",
              value: widget.target!.isInternational == true ? "Yes" : "No"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UserInfoWidget(
                  title: "Email", value: widget.target!.email.toString()),
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
                                title: Text("Block User?"),
                                content: Text(
                                    "Are You Sure You Want To Block This User?"),
                                actions: [
                                  MaterialButton(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection("users")
                                            .doc(widget.target!.uid)
                                            .update({"blocked": true});
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    "${widget.target!.firstName.toString() + " " + widget.target!.lastName.toString()} Blocked")));
                                        Navigator.of(context).pop();
                                      },
                                      child: Text("Yes")),
                                  MaterialButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
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
            ],
          ),
          if (widget.target!.jobProfile != null &&
              widget.target!.jobProfile != "")
            UserInfoWidget(
                title: "Job Profile",
                value: widget.target!.jobProfile.toString()),
          if (widget.target!.currentCompany != null &&
              widget.target!.currentCompany != "")
            UserInfoWidget(
                title: "Organization",
                value: widget.target!.currentCompany.toString()),
          SizedBox(height: 30),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => changeSelectedIndex(index),
                      child: FilterCookie(
                          text: fields[index].toString(),
                          selected: index == selected),
                    ),
                  );
                },
              ),
            ),
          ),
          loading
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
                    ),
                  ),
                )
              : posts.length > 0
                  ? Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          if (posts[0] is DiscussionPost) {
                            return DiscussionPostUI(
                                post: posts[index],
                                server: widget.server,
                                user: widget.user,
                                onTapEnabled: true);
                          }
                          if (posts[0] is JobPost) {
                            return JobPostTile(
                                job: posts[index],
                                server: widget.server,
                                user: widget.user);
                          }
                          return EventPostTile(
                              event: posts[index],
                              server: widget.server,
                              user: widget.user);
                        },
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(
                          child: Text("No Posts",
                              style: TextStyle(color: Color(0xff707070)))))
        ],
      ),
    )));
  }
}

class UserInfoWidget extends StatelessWidget {
  final String title, value;
  UserInfoWidget({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff04009A))),
            Text(value,
                style: TextStyle(color: Color(0xff707070), fontSize: 16))
          ],
        ));
  }
}

class UpdateProfile extends StatefulWidget {
  final CustomUser user;
  final Server server;
  UpdateProfile({required this.user, required this.server});
  @override
  _UpdateProfileState createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  late TextEditingController firstNameController,
      lastNameController,
      phoneController,
      caController,
      paController,
      jobProfileController,
      companyController,
      rollnoController,
      collegeController,
      instaController,
      fbController,
      linkedinController;
  late bool loading,
      rollnoerror,
      instaerror,
      fberror,
      linkedinerror,
      international;
  File? uploadFile;
  ImageProvider? image;
  String? yopstr;
  late String countryCode;
  List<String?> colleges = [];
  List<String?> searchResult = [];

  @override
  void initState() {
    initColleges();
    international = widget.user.isInternational;
    countryCode = widget.user.phone!.split("-")[0];
    firstNameController = TextEditingController(text: widget.user.firstName);
    lastNameController = TextEditingController(text: widget.user.lastName);
    phoneController =
        TextEditingController(text: widget.user.phone!.split("-").last);
    caController = TextEditingController(text: widget.user.currentAddress);
    paController = TextEditingController(text: widget.user.permanentAddress);
    jobProfileController =
        TextEditingController(text: widget.user.jobProfile ?? "");
    companyController =
        TextEditingController(text: widget.user.currentCompany ?? "");
    rollnoController = TextEditingController(text: widget.user.rollno);
    collegeController = TextEditingController(text: widget.user.collegeName);
    instaController = TextEditingController(text: widget.user.instaAccount);
    fbController = TextEditingController(text: widget.user.fbAccount);
    linkedinController =
        TextEditingController(text: widget.user.linkedinAccount);
    loading = false;
    rollnoerror = false;
    instaerror = false;
    fberror = false;
    linkedinerror = false;
    yopstr = widget.user.passOutYear.toString();
    image = widget.user.profileImage != null
        ? MemoryImage(widget.user.profileImage!)
        : null;
    super.initState();
  }

  update() async {
    var bytes;
    if (uploadFile != null) {
      bytes = await uploadFile!.readAsBytes();
    }
    final rollnovalid = RegExp(r"^[a-zA-Z][0-9]{5}$")
        .hasMatch(rollnoController.value.text.trim());
    if (!rollnovalid) {
      setState(() {
        rollnoerror = true;
      });
      return;
    }
    if (instaController.value.text.trim() != "" &&
        !instaController.value.text
            .trim()
            .startsWith("https://instagram.com/")) {
      setState(() {
        instaerror = true;
      });
      return;
    }
    if (fbController.value.text.trim() != "" &&
        !fbController.value.text
            .trim()
            .startsWith("https://www.facebook.com/")) {
      setState(() {
        fberror = true;
      });
      return;
    }
    if (linkedinController.value.text.trim() != "" &&
        !linkedinController.value.text
            .trim()
            .startsWith("https://www.linkedin.com/")) {
      setState(() {
        linkedinerror = true;
      });
      return;
    }
    setState(() {
      loading = true;

      widget.user.firstName = firstNameController.value.text.trim() != ""
          ? firstNameController.value.text.trim()
          : widget.user.firstName;
      widget.user.lastName = lastNameController.value.text.trim() != ""
          ? lastNameController.value.text.trim()
          : widget.user.lastName;
      widget.user.phone = phoneController.value.text.trim() != ""
          ? phoneController.value.text.trim()
          : widget.user.phone;
      widget.user.currentAddress = caController.value.text.trim() != ""
          ? caController.value.text.trim()
          : widget.user.currentAddress;
      widget.user.permanentAddress = paController.value.text.trim() != ""
          ? paController.value.text.trim()
          : widget.user.permanentAddress;
      widget.user.jobProfile = jobProfileController.value.text.trim() != ""
          ? jobProfileController.value.text.trim()
          : widget.user.jobProfile;
      widget.user.currentCompany = companyController.value.text.trim() != ""
          ? companyController.value.text.trim()
          : widget.user.currentCompany;
      widget.user.rollno = rollnoController.value.text.trim() != ""
          ? rollnoController.value.text.trim()
          : widget.user.rollno;
      widget.user.collegeName = collegeController.value.text.trim() != ""
          ? collegeController.value.text.trim()
          : widget.user.collegeName;
      widget.user.passOutYear =
          yopstr != "" ? int.parse(yopstr!) : widget.user.passOutYear;
      widget.user.profileImage = bytes;
      widget.user.fbAccount = fbController.value.text.trim() != "" &&
              Uri.parse(fbController.value.text.trim()).isAbsolute
          ? fbController.value.text.trim()
          : widget.user.fbAccount;
      widget.user.instaAccount = instaController.value.text.trim() != "" &&
              Uri.parse(instaController.value.text.trim()).isAbsolute
          ? instaController.value.text.trim()
          : widget.user.instaAccount;
      widget.user.linkedinAccount =
          linkedinController.value.text.trim() != "" &&
                  Uri.parse(linkedinController.value.text.trim()).isAbsolute
              ? linkedinController.value.text.trim()
              : widget.user.linkedinAccount;
      widget.user.isInternational = international;
    });

    await UserDatabase.setUser(widget.user);
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.user.uid)
        .update({"isInternational": international.toString()});
    // await widget.server.updateInternational(international.toString());
    widget.server.updateUserRecord(widget.user).then((res) {
      setState(() {
        loading = false;
      });
      if (res.code == DbResponseCode.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Profile uploaded")));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Something went wrong :(")));
      }
    });
  }

  Future pickImage() async {
    await ImagePicker()
        .getImage(source: ImageSource.gallery, maxHeight: 512, maxWidth: 512)
        .then((img) async {
      File? croppedImage = await ImageCropper.cropImage(
          sourcePath: img!.path,
          aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1));
      if (croppedImage != null) {
        final file = await croppedImage.readAsBytes();
        setState(() {
          uploadFile = croppedImage;
          image = MemoryImage(file);
        });
      }
    });
  }

  removePicture() {
    setState(() {
      uploadFile = null;
      widget.user.profileImage = null;
    });
  }

  yearChanged(String? value) {
    setState(() {
      yopstr = value!;
    });
  }

  initColleges() async {
    final x = await rootBundle.loadString("assets/colleges.json");
    final clgs = jsonDecode(x);
    List<String> res = [];
    clgs.forEach((element) {
      res.add(element["college"]);
    });
    setState(() {
      colleges = res;
    });
  }

  collegeChanged(String query) {
    if (query != "") {
      List<String> x = [];
      colleges.forEach((element) {
        if (element!.toLowerCase().contains(query.toLowerCase())) {
          x.add(element);
        }
      });
      setState(() {
        searchResult = x;
      });
    } else {
      setState(() {
        searchResult = [];
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
            physics:
                BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.chevron_left_rounded, size: 28))),
              SizedBox(height: 10),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Stack(
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              width: 100,
                              height: 100,
                              child: CircleAvatar(
                                  backgroundColor: Color(0xff77ACF1),
                                  backgroundImage: image,
                                  child: widget.user.profileImage == null &&
                                          uploadFile == null
                                      ? Center(
                                          child: Text(widget.user.firstName![0],
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 28)))
                                      : Container(height: 0))),
                          Positioned(
                              bottom: 0,
                              right: 0,
                              child: Icon(Icons.camera_alt_sharp))
                        ],
                      ),
                    ),
                  )),
              SecondaryButton(text: "Remove Picture", onTap: removePicture),
              SizedBox(height: 30),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: InputField(
                        error: false,
                        hint: "First Name",
                        controller: firstNameController,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: InputField(
                        error: false,
                        hint: "Last Name",
                        controller: lastNameController,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: InputField(
                  error: false,
                  controller: TextEditingController(text: widget.user.email),
                  enabled: false,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  child: Row(
                    children: [
                      CountryCodePicker(
                        onChanged: (country) {
                          setState(() {
                            countryCode = country!.code;
                          });
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: InputField(
                            controller: phoneController,
                            hint: "Phone Number",
                            obscureText: false,
                            error: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: InputField(
                  error: rollnoerror,
                  hint: "Roll No.",
                  controller: rollnoController,
                  errorMessage: "Expected a letter followed by 5 numbers",
                  onChanged: (val) {
                    setState(() {
                      rollnoerror = false;
                    });
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: InputField(
                  enabled: false,
                  error: false,
                  hint: "passoutYear",
                  controller: TextEditingController(
                      text: widget.user.passOutYear.toString()),
                ),
              ),
              Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 5),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Color(0xfff0f0f0),
                        borderRadius: BorderRadius.circular(10)),
                    child: TypeAheadField(
                      hideOnEmpty: true,
                      hideSuggestionsOnKeyboardHide: true,
                      textFieldConfiguration: TextFieldConfiguration(
                          controller: collegeController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "College/Institute",
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 18),
                            hintStyle: TextStyle(
                                color: Color(0xffa4a4a4), fontSize: 13),
                          )),
                      itemBuilder: (BuildContext context, itemData) {
                        return ListTile(title: Text(itemData.toString()));
                      },
                      onSuggestionSelected: (Object? suggestion) {
                        setState(() {
                          collegeController.text = suggestion.toString();
                        });
                      },
                      suggestionsCallback: (String pattern) {
                        return colleges.where((element) => element!
                            .toLowerCase()
                            .contains(pattern.toLowerCase()));
                      },
                    ),
                  )),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                    padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
                    child: Container(
                      width: 250,
                      child: CheckboxListTile(
                        title: Text("International Student?",
                            style: TextStyle(fontSize: 13)),
                        value: international,
                        onChanged: (bool? value) {
                          setState(() {
                            international = value!;
                          });
                          print("international status: " +
                              international.toString());
                        },
                      ),
                    )),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: InputField(
                  error: false,
                  hint: "Current Address",
                  controller: caController,
                  maxLines: 3,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: InputField(
                  error: false,
                  hint: "Permanent Address",
                  controller: paController,
                  maxLines: 3,
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: InputField(
                  error: false,
                  hint: "Current Position",
                  controller: jobProfileController,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: InputField(
                  error: false,
                  hint: "Current Employer",
                  controller: companyController,
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: InputField(
                  error: linkedinerror,
                  errorMessage: "Invalid profile link",
                  hint: "LinkedIn profile link",
                  controller: linkedinController,
                  onChanged: (val) {
                    setState(() {
                      linkedinerror = false;
                    });
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: InputField(
                  error: fberror,
                  hint: "Facebook profile link",
                  controller: fbController,
                  errorMessage: "Invalid link",
                  onChanged: (val) {
                    setState(() {
                      fberror = false;
                    });
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: InputField(
                  error: instaerror,
                  hint: "Instagram profile link",
                  controller: instaController,
                  errorMessage: "Invalid link",
                  onChanged: (val) {
                    setState(() {
                      instaerror = false;
                    });
                  },
                ),
              ),
              SizedBox(height: 25),
              Center(
                child: PrimaryButton(text: "Update", onTap: update),
              )
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
