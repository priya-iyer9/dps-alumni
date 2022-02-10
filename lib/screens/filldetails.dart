import 'dart:convert';
import 'dart:io';

import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/LocalDatabase.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/screens/discussions.dart';
import 'package:alumniapp/ui/InputField.dart';
import 'package:alumniapp/ui/actionbuttons.dart';
import 'package:alumniapp/ui/countrycodepicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class FillDetails extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  FillDetails({required this.user, required this.server});
  @override
  _FillDetailsState createState() => _FillDetailsState();
}

class _FillDetailsState extends State<FillDetails> {
  double widget1Opacity = 0.0;
  late TextEditingController phoneController,
      rollnoController,
      caController,
      paController,
      collegeController,
      jobProfileController,
      companyController,
      fbController,
      instaController,
      linkedinController;
  late String? yopstr, college, rollnoerrortext;
  late String phnerror;
  late FocusNode node;
  late bool phoneError,
      collegeError,
      yearError,
      loading,
      caError,
      paError,
      rollnoError,
      fberror,
      instaerror,
      linkedinerror,
      international;
  late List<String> colleges, searchResult;
  late FocusNode rollnoNode,
      collegeNode,
      caNode,
      paNode,
      companyNode,
      jobprofileNode;
  File? uploadFile;
  String countryCode = "+91";
  @override
  void initState() {
    phoneController = TextEditingController();
    companyController = TextEditingController();
    jobProfileController = TextEditingController();
    collegeController = TextEditingController();
    caController = TextEditingController();
    paController = TextEditingController();
    rollnoController = TextEditingController();
    linkedinController = TextEditingController();
    fbController = TextEditingController();
    instaController = TextEditingController();
    phoneError = false;
    collegeError = false;
    paError = false;
    caError = false;
    phnerror = "";
    yearError = false;
    loading = false;
    rollnoError = false;
    fberror = false;
    instaerror = false;
    linkedinerror = false;
    international = false;
    node = FocusNode();
    searchResult = [];
    colleges = [];
    yopstr = "Year of Passing";
    rollnoerrortext = "";
    rollnoNode = FocusNode();
    collegeNode = FocusNode();
    caNode = FocusNode();
    paNode = FocusNode();
    companyNode = FocusNode();
    jobprofileNode = FocusNode();
    initColleges();
    super.initState();
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

  yearChanged(String? value) {
    setState(() {
      yopstr = value!;
    });
  }

  proceed() async {
    setState(() {
      loading = true;
      rollnoError = rollnoController.value.text.trim() == "" ||
          !RegExp(r"^[a-zA-Z][0-9]{5}$")
              .hasMatch(rollnoController.value.text.trim());
      phoneError = phoneController.value.text.trim().length < 10;
      collegeError = collegeController.value.text.trim() == "";
      caError = caController.value.text.trim() == "";
      paError = paController.value.text.trim() == "";
      fberror = fbController.value.text.trim() != ""
          ? Uri.parse(fbController.value.text.trim()).isAbsolute
              ? false
              : true
          : false;
      instaerror = instaController.value.text.trim() != ""
          ? Uri.parse(instaController.value.text.trim()).isAbsolute
              ? false
              : true
          : false;
      linkedinerror = linkedinController.value.text.trim() != ""
          ? Uri.parse(linkedinController.value.text.trim()).isAbsolute
              ? false
              : true
          : false;
    });
    final isError = phoneError ||
        collegeError ||
        caError ||
        paError ||
        rollnoError ||
        (yopstr == null) ||
        (yopstr == "Year of Passing") ||
        fberror ||
        instaerror ||
        linkedinerror;
    if (!isError) {
      setState(() {
        widget.user!.phone =
            countryCode + "-" + phoneController.value.text.trim();
        widget.user!.collegeName = collegeController.value.text.trim();
        widget.user!.passOutYear = int.parse(yopstr!);
        widget.user!.jobProfile = jobProfileController.value.text.trim();
        widget.user!.currentCompany = companyController.value.text.trim();
        widget.user!.currentAddress = caController.value.text.trim();
        widget.user!.permanentAddress = paController.value.text.trim();
        widget.user!.isUptodate = true;
        widget.user!.rollno = rollnoController.value.text.trim();
        widget.user!.fbAccount = fbController.value.text.trim();
        widget.user!.instaAccount = instaController.value.text.trim();
        widget.user!.linkedinAccount = linkedinController.value.text.trim();
        widget.user!.isInternational = international;
      });
      await UserDatabase.setUser(widget.user);
      final res = await widget.server.updateUserRecord(widget.user);
      if (res.code == DbResponseCode.success) {
        await UserDatabase.setUser(widget.user);
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              DiscussionsPage(user: widget.user, server: widget.server),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  animation.drive(Tween(begin: Offset(0, 1), end: Offset.zero)),
              child: child,
            );
          },
        ));
      }
    } else {
      if (rollnoError) {
        if (rollnoController.value.text.trim() == "") {
          setState(() {
            rollnoerrortext = "Roll no. is required";
          });
        } else {
          setState(() {
            rollnoerrortext = "Expected a letter followed by 5 numbers";
          });
        }
      }
    }
    setState(() {
      loading = false;
    });
  }

  collegeChanged(String query) {
    if (query != "") {
      List<String> x = [];
      colleges.forEach((element) {
        if (element.toLowerCase().contains(query.toLowerCase())) {
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

  Future pickImage() async {
    await ImagePicker().getImage(source: ImageSource.gallery).then((img) async {
      File? croppedImage = await ImageCropper.cropImage(
          sourcePath: img!.path,
          aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1));
      if (croppedImage != null) {
        setState(() {
          uploadFile = croppedImage;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
        child: Center(
            child: Stack(
          children: [
            SingleChildScrollView(
                child: Column(
              children: [
                SizedBox(height: 50),
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
                                  color: uploadFile == null
                                      ? Color(0xffA259FF)
                                      : null),
                              width: 100,
                              height: 100,
                              child: uploadFile == null
                                  ? Center(
                                      child: Text(widget.user!.firstName![0],
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 28)))
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
                Padding(
                  padding:
                      EdgeInsets.only(left: 25, right: 25, bottom: 10, top: 40),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 50,
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
                              error: phoneError,
                              errorMessage: phnerror,
                              onEditingComplete: () => FocusScope.of(context)
                                  .requestFocus(rollnoNode),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
                    child: InputField(
                      controller: rollnoController,
                      hint: "Roll No",
                      obscureText: false,
                      error: rollnoError,
                      focusNode: rollnoNode,
                      errorMessage: rollnoerrortext,
                      onEditingComplete: () => FocusScope.of(context).unfocus(),
                    )),
                Padding(
                  padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
                  child: CustomDropDown(
                      items: [
                        for (var i = 1972; i < 2030; i += 1) i.toString()
                      ],
                      onChanged: yearChanged,
                      text: yopstr,
                      hint: "Year of Passing",
                      error: yearError),
                ),
                Padding(
                    padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                          color: collegeError
                              ? Color(0xffFFDBDB)
                              : Color(0xfff0f0f0),
                          borderRadius: BorderRadius.circular(10)),
                      child: TypeAheadField(
                        hideOnEmpty: true,
                        hideSuggestionsOnKeyboardHide: true,
                        textFieldConfiguration: TextFieldConfiguration(
                            focusNode: collegeNode,
                            onEditingComplete: () =>
                                FocusScope.of(context).requestFocus(caNode),
                            controller: collegeController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "College/Institute",
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 18),
                              hintStyle: TextStyle(
                                  color: collegeError
                                      ? Colors.red
                                      : Color(0xffa4a4a4),
                                  fontSize: 13),
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
                          return colleges.where((element) => element
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
                          },
                        ),
                      )),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
                  child: InputField(
                    controller: caController,
                    hint: "Current Address",
                    obscureText: false,
                    error: caError,
                    errorMessage: "Please enter your current address",
                    maxLines: 3,
                    focusNode: caNode,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(paNode),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
                  child: InputField(
                    controller: paController,
                    hint: "Permanent Address",
                    obscureText: false,
                    error: paError,
                    errorMessage: "Please enter your permanent address",
                    maxLines: 3,
                    focusNode: paNode,
                    onEditingComplete: () =>
                        FocusScope.of(context).requestFocus(jobprofileNode),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
                    child: InputField(
                      controller: jobProfileController,
                      hint: "Current Position (Optional)",
                      obscureText: false,
                      error: false,
                      focusNode: jobprofileNode,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(companyNode),
                    )),
                Padding(
                    padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
                    child: InputField(
                      controller: companyController,
                      hint: "Current Organization (Optional)",
                      obscureText: false,
                      error: false,
                      focusNode: companyNode,
                      onEditingComplete: () => FocusScope.of(context).unfocus(),
                    )),
                Padding(
                    padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
                    child: InputField(
                      controller: linkedinController,
                      hint: "Linkedin profile link (Optional)",
                      obscureText: false,
                      error: linkedinerror,
                    )),
                Padding(
                    padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
                    child: InputField(
                      controller: instaController,
                      hint: "Instagram profile link (Optional)",
                      obscureText: false,
                      error: instaerror,
                    )),
                Padding(
                    padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
                    child: InputField(
                      controller: fbController,
                      hint: "Facebook profile link (Optional)",
                      obscureText: false,
                      error: fberror,
                    )),
                PrimaryButton(
                  text: "Continue",
                  onTap: proceed,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ],
            )),
            Container(
                height: loading ? MediaQuery.of(context).size.height : 0,
                color: Colors.black.withOpacity(0.8),
                child: Center(
                    child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
                )))
          ],
        )),
      ),
    ));
  }
}
