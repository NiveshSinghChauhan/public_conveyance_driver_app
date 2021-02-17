import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:public_transport_driver/screens/HomeScreen.dart';
import 'package:public_transport_driver/screens/LoginScreen.dart';
import 'package:public_transport_driver/screens/RegisterScreen.dart';
import 'package:public_transport_driver/screens/SetRouteScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loading = false;
  Widget Function() screen = () => LoginScreen();

  @override
  initState() {
    super.initState();
    initApplication();
  }

  Future initApplication() async {
    setState(() {
      loading = true;
    });

    // initializing firebase
    await Firebase.initializeApp();

    // checking if user is already loggedIn or not
    // and sending user to relavent screen according to loggedIn state
    await checkIfUserLoggedIn();

    if (this.mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  checkIfUserLoggedIn() async {
    FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    FirebaseFirestore _firestore = FirebaseFirestore.instance;

    User user = _firebaseAuth.currentUser;

    if (user != null) {
      var vehicle = await _firestore
          .collection('vehicles')
          .where('driver_id', isEqualTo: user.uid)
          .get()
          .then((value) => value.docs.first);

      if (vehicle.data()['route'] != null) {
        screen = () => HomeScreen();
      } else {
        screen = () => SetRouteScreen(
              vehicleId: vehicle.id,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: loading
          ? Scaffold(body: Center(child: CircularProgressIndicator()))
          : screen(),
    );
  }
}
