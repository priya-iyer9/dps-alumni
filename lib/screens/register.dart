import 'dart:async';

import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/LocalDatabase.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/screens/discussions.dart';
import 'package:alumniapp/screens/filldetails.dart';
import 'package:alumniapp/screens/login.dart';
import 'package:alumniapp/ui/InputField.dart';
import 'package:alumniapp/ui/actionbuttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:linkedin_login/linkedin_login.dart';

class Register extends StatefulWidget {
  final Server server;
  Register({required this.server});
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  late TextEditingController firstNameController,
      lastNameController,
      emailController,
      passwordController,
      confirmController;
  late bool firstNameError,
      lastNameError,
      emailError,
      passwordError,
      confirmError,
      loading,
      equalError;
  late String emailErrorText;
  late FocusNode lastNameNode, emailNode, passwordNode, confirmNode;
  double widget1Opacity = 0.0;
  @override
  void initState() {
    super.initState();
    // Future.delayed(Duration(milliseconds: 300), () {
    //   widget1Opacity = 1;
    // });
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmController = TextEditingController();
    firstNameError = false;
    lastNameError = false;
    emailError = false;
    passwordError = false;
    confirmError = false;
    loading = false;
    equalError = false;
    lastNameNode = FocusNode();
    emailNode = FocusNode();
    passwordNode = FocusNode();
    confirmNode = FocusNode();
    emailErrorText = "Email is mandatory";
    initApp();
  }

  initApp() async {
    final a = await Firebase.initializeApp();
    setState(() {
      widget.server.app = a;
    });
    widget.server.createFstoreInstance();
  }

  emailCheckDialog() {
    setState(() {
      loading = true;
      equalError = passwordController.value.text.trim() !=
          confirmController.value.text.trim();
      firstNameError = firstNameController.value.text.trim() == "";
      lastNameError = lastNameController.value.text.trim() == "";
      emailError = emailController.value.text.trim() == "";
      passwordError = passwordController.value.text.trim() == "" ||
          equalError ||
          passwordController.value.text.trim().length < 6;
      confirmError = confirmController.value.text.trim() == "" || equalError;
    });
    final isError = firstNameError ||
        lastNameError ||
        emailError ||
        passwordError ||
        confirmError ||
        equalError;
    if (!isError) {
      register();
    }
    setState(() {
      loading = false;
    });
  }

  register() async {
    final res = await widget.server.register(
        emailController.value.text.trim(),
        passwordController.value.text.trim(),
        firstNameController.value.text.trim(),
        lastNameController.value.text.trim());
    if (res.code == AuthResponseCode.success) {
      toHome(res, widget.server);
    } else {
      setState(() {
        emailError = true;
        emailErrorText = "Email already registered";
      });
    }
    setState(() {
      loading = false;
    });
  }

  facebook() async {
    setState(() {
      loading = true;
    });
    final LoginResult loginResult = await FacebookAuth.instance.login();
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.token);
    final cred = await FirebaseAuth.instance
        .signInWithCredential(facebookAuthCredential);
    final emailExists = await widget.server.checkUserByEmail(cred.user!.email);
    if (emailExists.found!) {
      if (!emailExists.user!.isUptodate) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                FillDetails(user: emailExists.user, server: widget.server)));
      } else {
        await UserDatabase.setUser(emailExists.user);
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => DiscussionsPage(
                user: emailExists.user, server: widget.server)));
      }
    } else {
      final CustomUser user = CustomUser(
          firstName: cred.user!.displayName!.split(" ").first,
          lastName: cred.user!.displayName!.split(" ").last,
          email: cred.user!.email);
      final r = await widget.server.createUserRecord(user);
      if (r.code == DbResponseCode.success) {
        user.uid = r.insertedId;
        setState(() {
          loading = false;
        });
        await UserDatabase.setUser(user);
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                FillDetails(user: user, server: widget.server)));
      }
    }
    setState(() {
      loading = false;
    });
  }

  linkedin() {
    final clientId = "77cqtg8yef1u4f";
    final clientSecret = "ucDIpJItc2TvjT07";
    final redirectUrl = "https://alumniapp-b9b35.firebaseapp.com/";
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LinkedInUserWidget(
            onGetUserProfile: onGetUserProfile,
            redirectUrl: redirectUrl,
            clientId: clientId,
            clientSecret: clientSecret)));
  }

  onGetUserProfile(UserSucceededAction? action) async {
    if (action != null) {
      final emailExists = await widget.server.checkUserByEmail(
          action.user.email!.elements![0].handleDeep!.emailAddress);
      if (emailExists.found!) {
        await UserDatabase.setUser(emailExists.user);
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => DiscussionsPage(
                user: emailExists.user, server: widget.server)));
      } else {
        final CustomUser user = CustomUser(
            firstName: action.user.localizedFirstName,
            lastName: action.user.localizedLastName,
            email: action.user.email!.elements![0].handleDeep!.emailAddress);
        final r = await widget.server.createUserRecord(user);
        if (r.code == DbResponseCode.success) {
          user.uid = r.insertedId;
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  FillDetails(user: user, server: widget.server)));
        }
      }
    }
  }

  login() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LoginPage(server: widget.server)));
  }

  toHome(AuthResponse res, Server server) async {
    await widget.server.setUser(res.user);
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          CheckOTP(user: res.user, server: server),
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
    return Scaffold(
        body: Center(
            child: Stack(
      children: [
        SingleChildScrollView(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/register.png', scale: 2),
            SizedBox(height: 20),
            Text("Register here",
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 28)),
            Padding(
              padding:
                  EdgeInsets.only(left: 25, right: 25, bottom: 10, top: 30),
              child: Container(
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: InputField(
                        controller: firstNameController,
                        hint: "First Name",
                        obscureText: false,
                        error: firstNameError,
                        onEditingComplete: () =>
                            FocusScope.of(context).requestFocus(lastNameNode),
                        onChanged: (val) {
                          setState(() {
                            firstNameError = false;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: InputField(
                        controller: lastNameController,
                        hint: "Last Name",
                        obscureText: false,
                        error: lastNameError,
                        focusNode: lastNameNode,
                        onEditingComplete: () =>
                            FocusScope.of(context).requestFocus(emailNode),
                        onChanged: (val) {
                          setState(() {
                            lastNameError = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
              child: InputField(
                controller: emailController,
                hint: "Email",
                obscureText: false,
                error: emailError,
                errorMessage: emailErrorText,
                focusNode: emailNode,
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(passwordNode),
                onChanged: (val) {
                  setState(() {
                    emailError = false;
                  });
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
              child: InputField(
                controller: passwordController,
                hint: "Password",
                obscureText: true,
                maxLines: 1,
                error: passwordError,
                errorMessage: equalError
                    ? "Passwords don't match"
                    : "Password is mandatory",
                focusNode: passwordNode,
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(confirmNode),
                onChanged: (val) {
                  setState(() {
                    passwordError = false;
                  });
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 25, right: 25, bottom: 10),
              child: InputField(
                controller: confirmController,
                hint: "Confirm Password",
                obscureText: true,
                maxLines: 1,
                error: confirmError,
                errorMessage: equalError
                    ? "Passwords don't match"
                    : "Password is mandatory",
                focusNode: confirmNode,
                onEditingComplete: () => confirmNode.unfocus(),
                onChanged: (val) {
                  setState(() {
                    confirmError = false;
                  });
                },
              ),
            ),
            PrimaryButton(
                text: "Register",
                onTap: emailCheckDialog,
                padding: EdgeInsets.only(top: 20)),
            SecondaryButton(
                text: "Login",
                onTap: login,
                padding: EdgeInsets.only(top: 20, bottom: 30)),
            SocialButtonArea(facebookAction: facebook, linkedinAction: linkedin)
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
    )));
  }
}

class CheckOTP extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  CheckOTP({required this.user, required this.server});
  @override
  _CheckOTPState createState() => _CheckOTPState();
}

class _CheckOTPState extends State<CheckOTP> {
  double widget1Opacity = 0.0;

  @override
  initState() {
    Future.delayed(Duration(milliseconds: 300), () {
      widget1Opacity = 1;
    });
    sendEmail();
    Timer.periodic(Duration(seconds: 2), (timer) {
      checkVerified(timer);
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  checkVerified(Timer timer) async {
    await widget.server.fauth!.currentUser!.reload();
    if (widget.server.fauth!.currentUser!.emailVerified) {
      timer.cancel();
      toFillDetails();
    }
  }

  sendEmail() async {
    await widget.server.fauth!.currentUser!.sendEmailVerification();
  }

  toFillDetails() async {
    await UserDatabase.setUser(widget.user);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            FillDetails(user: widget.user, server: widget.server)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          body: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
                  ),
                  SizedBox(height: 40),
                  Text(
                    "A verification email has been sent to ${widget.user!.email}.\n\nPlease do not close the app.",
                    textAlign: TextAlign.center,
                  )
                ],
              )))),
    ));
  }
}
