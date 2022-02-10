import 'package:alumniapp/Service/LocalDatabase.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/Service/Utils.dart';
import 'package:alumniapp/screens/discussions.dart';
import 'package:alumniapp/screens/filldetails.dart';
import 'package:alumniapp/screens/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static final navigatorKey = new GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {"/login": (BuildContext context) => SplashScreen()},
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    checkUser();
    super.initState();
  }

  checkUser() async {
    final isloggedin = UserDatabase.checkUser();
    final server =
        Server(app: await Firebase.initializeApp(), context: context);
    Utils.debugPrint(isloggedin);
    if (isloggedin) {
      final user = (await UserDatabase.getUser()).data;
      Utils.debugPrint("user: " + user.toString());
      server.createFstoreInstance();
      if (user.isUptodate) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => DiscussionsPage(user: user, server: server)));
      } else {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FillDetails(user: user, server: server)));
      }
    } else {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => LoginPage(server: server)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            child: Center(
                child: Container(
                    height: 120, child: Image.asset("assets/launcher.png")))));
  }
}
