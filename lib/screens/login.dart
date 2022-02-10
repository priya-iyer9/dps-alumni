import 'dart:io';

import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/LocalDatabase.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/screens/ResetPassword.dart';
import 'package:alumniapp/screens/discussions.dart';
import 'package:alumniapp/screens/filldetails.dart';
import 'package:alumniapp/screens/register.dart';
import 'package:alumniapp/ui/InputField.dart';
import 'package:alumniapp/ui/actionbuttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linkedin_login/linkedin_login.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginPage extends StatefulWidget {
  final Server server;
  LoginPage({required this.server});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController emailController,
      passwordController,
      resetEmailController;
  late bool emailError, passwordError, loading, resetEmailError, resetEmailSent;
  late String emailErrorText, passwordErrorText, resetEmailErrorText;
  late FocusNode passwordNode;
  double widget1Opacity = 0.0;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();

    emailController = TextEditingController();
    passwordController = TextEditingController();
    resetEmailController = TextEditingController();
    emailError = false;
    passwordError = false;
    loading = false;
    resetEmailSent = false;
    resetEmailError = false;
    emailErrorText = "Email is required";
    passwordErrorText = "Password is required";
    resetEmailErrorText = "Email is required";
    passwordNode = FocusNode();
    initApp();
  }

  initApp() async {
    final a = await Firebase.initializeApp();
    setState(() {
      widget.server.app = a;
    });
    widget.server.createFstoreInstance();
    widget.server.createFauthInstance();
    // Future.delayed(Duration(milliseconds: 300), () {
    widget1Opacity = 1;
    // });
  }

  toEmailVerification(CustomUser user) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          CheckOTP(user: user, server: widget.server),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              animation.drive(Tween(begin: Offset(0, 1), end: Offset.zero)),
          child: child,
        );
      },
    ));
  }

  toFillDetails(CustomUser user) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => FillDetails(user: user, server: widget.server)));
  }

  login() async {
    setState(() {
      loading = true;
      emailError = emailController.value.text.trim() == "";
      passwordError = emailController.value.text.trim().length < 6;
    });
    final res = await widget.server.login(emailController.value.text.trim(),
        passwordController.value.text.trim());
    if (res.code == AuthResponseCode.success) {
      // ignore: unrelated_type_equality_checks
      if (widget.server.fauth!.currentUser!.emailVerified &&
          res.user!.blocked == false) {
        if (widget.server.fauth!.currentUser!.emailVerified) {
          if (res.user!.isUptodate) {
            toHome(res, widget.server);
          } else {
            toFillDetails(res.user!);
          }
        } else {
          toEmailVerification(res.user!);
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Access Blocked")));
        _areyousuredialog(context);
      }
    } else {
      switch (res.message) {
        case 'user-not-found':
          setState(() {
            emailError = true;
            emailErrorText = "Account not found. Please register first";
          });
          break;
        case 'wrong-password':
          setState(() {
            passwordError = true;
            passwordErrorText = "Incorrect password";
          });
          break;
      }
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> _areyousuredialog(context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        double width = MediaQuery.of(context).size.width;
        double height = MediaQuery.of(context).size.height;
        return CupertinoAlertDialog(
          title: Column(
            children: [
              Center(
                child: Text(
                  'Accrss Blocked',
                  style: TextStyle(
                    color: Color(0xff032d3c),
                    fontWeight: FontWeight.w600,
                    fontSize: height * 0.018,
                  ),
                ),
              ),
              SizedBox(
                height: height * 0.01,
              ),
              Divider(
                color: Color(0xff032d3c),
                thickness: 1.0,
              ),
            ],
          ),
          content: Column(
            children: [
              Container(
                // margin: EdgeInsets.only(top: height * 0.02),
                height: height * 0.15,
                width: width * 0.6,
                color: Colors.transparent,
                child: Center(
                  child: Text(
                    'Your Account Has Been Blocked \n Contact Us',
                    style: TextStyle(
                      color: Color(0xff032d3c),
                      fontWeight: FontWeight.w400,
                      fontSize: height * 0.016,
                    ),
                  ),
                ),
              ),
              // SizedBox(height: height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: _cancelbutton(height, width, "Cancel")),
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        // Navigator.pushReplacement(
                        //   context,
                        //   CupertinoPageRoute<Null>(
                        //     builder: (context) => HomePageWidget(),
                        //   ),
                        // );
                      },
                      child: _submitbutton(height, width, "Help")),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cancelbutton(height, width, text) {
    return Container(
      // margin: EdgeInsets.only(left: width * 0.18, right: width * 0.18),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Color(0xff032d3c),
            fontWeight: FontWeight.w600,
            fontSize: height * 0.016,
          ),
        ),
      ),
      height: height * 0.035,
      width: width * 0.2,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(50.0))),
    );
  }

  Widget _submitbutton(height, width, text) {
    return Container(
      // margin: EdgeInsets.only(left: width * 0.18, right: width * 0.18),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: height * 0.016,
          ),
        ),
      ),
      height: height * 0.035,
      width: width * 0.2,
      decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.white, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(50.0))),
    );
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
      final name = cred.user!.displayName!.split(" ");
      final CustomUser user = CustomUser(
          firstName: name.first, lastName: name.last, email: cred.user!.email);
      final r = await widget.server.createUserRecord(user);
      if (r.code == DbResponseCode.success) {
        user.uid = r.insertedId;
        await UserDatabase.setUser(user);
        setState(() {
          loading = false;
        });
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

  forgotPassword() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ResetPassword(server: widget.server)));
  }

  register() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => Register(server: widget.server)));
  }

  toHome(AuthResponse res, Server server) async {
    await UserDatabase.setUser(res.user);
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          DiscussionsPage(user: res.user, server: server),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              animation.drive(Tween(begin: Offset(0, 1), end: Offset.zero)),
          child: child,
        );
      },
    ));
  }

  Future<bool> onWillPop() async {
    exit(0);
  }

  void _togglePass() {
    setState(() {
      _obscurePass = !_obscurePass;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: onWillPop,
      child: DecoratedBox(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/bg1.jpg"), fit: BoxFit.cover)),
        child: Scaffold(
            backgroundColor: Colors.white.withOpacity(0.8),
            body: Center(
                child: Stack(
              children: [
                SingleChildScrollView(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: widget1Opacity,
                      duration: Duration(seconds: 4),
                      child: Container(
                          height: 300,
                          width: 300,
                          child: Image.asset('assets/login.png')),
                    ),
                    AnimatedOpacity(
                      opacity: widget1Opacity,
                      duration: Duration(seconds: 4),
                      child: Text("DPS RKPURAM ALUMNI APP",
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 26,
                              color: Color(0xff04009A))),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: 25, right: 25, top: 20, bottom: 10),
                      child: InputField(
                        controller: emailController,
                        hint: "Email",
                        obscureText: false,
                        error: emailError,
                        errorMessage: emailErrorText,
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
                        suffixIcon: InkWell(
                          onTap: _togglePass,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                0.0, height * 0.02, width * 0.06, 0.0),
                            child: Text(
                              _obscurePass ? "Show" : "Hide",
                              style: TextStyle(
                                  color: Color(0xff04009A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),
                        controller: passwordController,
                        hint: "Password",
                        maxLines: 1,
                        obscureText: _obscurePass,
                        error: passwordError,
                        errorMessage: passwordErrorText,
                        focusNode: passwordNode,
                        onEditingComplete: () => passwordNode.unfocus(),
                        onChanged: (val) {
                          setState(() {
                            passwordError = false;
                          });
                        },
                      ),
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          child: GestureDetector(
                            onTap: forgotPassword,
                            child: Text("Forgot Password?",
                                style: TextStyle(
                                    color: Color(0xff04009A), fontSize: 11)),
                          ),
                        )),
                    SizedBox(height: 15.0),
                    PrimaryButton(
                        text: "Login",
                        onTap: login,
                        padding: EdgeInsets.only(top: 20, bottom: 20)),
                    SocialButtonArea(
                        facebookAction: facebook, linkedinAction: linkedin),
                    SecondaryButton(
                        text: "Don't Have An Account?",
                        onTap: register,
                        padding: EdgeInsets.only(top: 20, bottom: 10)),
                  ],
                )),
                Container(
                    height: loading ? MediaQuery.of(context).size.height : 0,
                    color: Colors.black.withOpacity(0.8),
                    child: Center(
                        child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
                    )))
              ],
            ))),
      ),
    );
  }
}
